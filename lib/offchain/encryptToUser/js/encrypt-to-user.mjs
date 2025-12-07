import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import { BLOCK_SIZE, decrypt, sign, verifySignatures } from 'soda-bubble-sdk';
import { createUserInteractorClient } from '../../../onchain/scripts/js/soda-web3-helper.mjs';

const NUM_EVALUATORS = 2;

export async function getEncryptedValues(client, handlesToEncrypt, signingKey, chain_id, signers){
    
    // Convert handle (BigInt or number) to 32-byte Buffer
    let handlesBytes = [];
    for (let i = 0; i < handlesToEncrypt.length; i++){
        let handle = handlesToEncrypt[i];
        if (typeof handle === 'bigint') {
            const hexString = handle.toString(16).padStart(64, '0'); // 32 bytes = 64 hex chars
            handlesBytes.push(Buffer.from(hexString, 'hex'));
        } else {
            const hexString = BigInt(handle).toString(16).padStart(64, '0');
            handlesBytes.push(Buffer.from(hexString, 'hex'));
        }    
    }
    // Concatenate all handles into a single buffer for signing
    const handlesToSign = Buffer.concat(handlesBytes);

    // Sign the handles
    const signature = sign(handlesToSign, signingKey);

    // Create gRPC request
    const request = {
        handles: handlesBytes,
        chain_id: parseInt(chain_id),
        user_signature: signature
    };

    return callEncryptToUser(client, request, handlesBytes, handlesToEncrypt, signers);
}

export async function getEncryptedValuesOnBehalf(client, handlesToEncrypt, owner, signingKey, chain_id, signers){

    // Convert handle (BigInt or number) to 32-byte Buffer
    let handlesBytes = [];
    for (let i = 0; i < handlesToEncrypt.length; i++){
        let handle = handlesToEncrypt[i];
        if (typeof handle === 'bigint') {
            const hexString = handle.toString(16).padStart(64, '0'); // 32 bytes = 64 hex chars
            handlesBytes.push(Buffer.from(hexString, 'hex'));
        } else {
            const hexString = BigInt(handle).toString(16).padStart(64, '0');
            handlesBytes.push(Buffer.from(hexString, 'hex'));
        }    
    }
    // Concatenate all handles into a single buffer for signing
    const handlesToSign = Buffer.concat(handlesBytes);
    
    let ownerBytes;
    if (typeof owner === 'string') {
        ownerBytes = Buffer.from(owner, 'hex');
    } else if (owner.options && owner.options.address) {
        // It's a web3 contract object
        const address = owner.options.address;
        ownerBytes = Buffer.from(address.slice(2), 'hex'); // Remove '0x' prefix
    } else if (owner.address) {
        // It's an account object with address property
        const address = typeof owner.address === 'string' ? owner.address : owner.address.toString('hex');
        ownerBytes = Buffer.from(address.replace('0x', ''), 'hex');
    } else {
        throw new TypeError(`Owner must be a string, contract object, or account object. Got: ${typeof owner}`);
    }
    const messageToSign = Buffer.concat([handlesToSign, ownerBytes]);
    const signature = sign(messageToSign, signingKey);

    const request = {
        handles: handlesBytes,
        chain_id: parseInt(chain_id),
        owner: ownerBytes,
        user_signature: signature
    };

    return callEncryptToUser(client, request, handlesBytes, handlesToEncrypt, signers);
}

async function callEncryptToUser(client, request, handlesBytes, handlesToEncrypt, signers){

    // Call the gRPC service
    const response = await new Promise((resolve, reject) => {
        client.EncryptToUser(request, (err, res) => {
            if (err) {
                reject(err);
            } else {
                resolve(res);
            }
        });
    });

    if (!response.mpc_signatures || !response.outputs){
        throw new Error("Invalid response: mpc_signatures and outputs are required");
    }

    if (response.outputs.length !== handlesToEncrypt.length){
        throw new Error(`Invalid response size: ${response.outputs.length}, should be ${handlesToEncrypt.length}`);
    }
    for (let i = 0; i < handlesToEncrypt.length; i++){
        if (response.outputs[i].length !== BLOCK_SIZE * 4){
            throw new Error(`Invalid response size: ${response.outputs[i].length}, should be ${BLOCK_SIZE * 4}`);
        }
    }
    
    if (response.mpc_signatures.length !== NUM_EVALUATORS){
        throw new Error(`Invalid number of signatures: ${response.mpc_signatures.length}`);
    }
    
    // Validate signatures 
    if (!validateSignatures(response.mpc_signatures, handlesBytes, response.outputs, signers)){
        throw new Error("Invalid signatures");
    }
    
    return response.outputs;
}

function validateSignatures(signatures, handles, outputs, signers){
    // Validate that the number of handles and outputs is the same and not empty
    if (handles.length !== outputs.length){
        throw new RangeError("handles and outputs must have the same length");
    }
    
    if (handles.length === 0){
        throw new RangeError("handles and outputs must be non-empty");
    }

    // Concatenate all handles and outputs into a single buffer for verification
    let allHandles = Buffer.concat(handles);
    let allOutputs = Buffer.concat(outputs);

    const message = Buffer.concat([allHandles, allOutputs]);

    // Verify the signatures
    return verifySignatures(message, signatures, signers); // returns true if the signatures are valid, false otherwise
}

function uint8ArrayToBigInt(uint8Array) {
    let value = BigInt(0);
    for (let i = 0; i < uint8Array.length; i++) {
        value = (value << 8n) | BigInt(uint8Array[i]);
    }
    return value;

export function decryptValue(ctValue, userKey) {
    if (ctValue.length !== BLOCK_SIZE * 2 && ctValue.length !== BLOCK_SIZE * 4) {
        throw new Error(`Invalid ciphertext size: ${ctValue.length}`);
    }

    let decryptedMessage;
    if (ctValue.length === BLOCK_SIZE * 2) {
        // Split ct into two 128-bit arrays r and cipher
        const cipher = ctValue.slice(0, BLOCK_SIZE);
        const r = ctValue.slice(BLOCK_SIZE, 2 * BLOCK_SIZE);

        // Decrypt the cipher
        decryptedMessage = decrypt(userKey, r, cipher);
    } else {
        // Split ct into four 128-bit arrays rHigh, cipherHigh, rLow and cipherLow
        const cipherHigh = ctValue.slice(0, BLOCK_SIZE);
        const rHigh = ctValue.slice(BLOCK_SIZE, 2 * BLOCK_SIZE);
        const cipherLow = ctValue.slice(2 * BLOCK_SIZE, 3 * BLOCK_SIZE);
        const rLow = ctValue.slice(3 * BLOCK_SIZE, 4 * BLOCK_SIZE);

        // Decrypt the cipher
        decryptedMessage = decrypt(userKey, rHigh, cipherHigh, rLow, cipherLow);
    }

    return Number(uint8ArrayToBigInt(decryptedMessage));
}

export async function main(handle, toDecrypt) {
    if (handle === null || handle === undefined) {
        throw new Error("Handle is required");
    }

    if (toDecrypt === null || toDecrypt === undefined) {
        toDecrypt = false;
    }

    const signingKey = process.env.SIGNING_KEY;
    if (!signingKey) {
        throw new Error("SIGNING_KEY environment variable not set");
    }

    const chainId = process.env.REMOTE_CHAIN_ID;
    if (!chainId) {
        throw new Error("REMOTE_CHAIN_ID environment variable not set");
    }

    const userInteractorUrl = process.env.USER_INTERACTOR_URL;
    if (!userInteractorUrl) {
        throw new Error("USER_INTERACTOR_URL environment variable not set");
    }

    // Create a gRPC channel
    const client = createUserInteractorClient(userInteractorUrl);

    const signers = await getSignersAddresses();

    console.log("Encrypting value to user");
    
    // Get encrypted value
    const signingKeyBuffer = Buffer.from(signingKey.slice(2), 'hex');
    const encrypted_values = await getEncryptedValues(client, [handle], signingKeyBuffer, chainId, signers);
    const encrypted_value = encrypted_values[0];

    if (toDecrypt) {
        console.log("Decrypting value");

        const user_key_hex = process.env.USER_KEY;
        if (!user_key_hex) {
            throw new Error("USER_KEY environment variable not set");
        }
        const user_key = Buffer.from(user_key_hex, 'hex');

        const decrypted_value = decryptValue(encrypted_value, user_key);
        console.log(`Decrypted value: ${decrypted_value.toString()}`);

        return decrypted_value;
    } else {
        console.log(`Encrypted value: ${encrypted_value.toString('hex')}`);
        return encrypted_value;
    }
}

// Only run command line parsing if this script is executed directly
// In ES modules, we check if this file is being run directly
const isMainModule = process.argv[1] && import.meta.url.endsWith(process.argv[1]);

if (isMainModule) {
    // Parse command line arguments
    const argv = yargs(hideBin(process.argv))
        .option('handle', {
            alias: 'h',
            type: 'string',
            description: 'Handle to encrypt',
            demandOption: true
        })
        .option('decrypt', {
            alias: 'd',
            type: 'boolean',
            description: 'Decrypt the value',
            default: false
        })
        .help()
        .parseSync();

    main(argv.handle, argv.decrypt)
        .then(() => {
            process.exit(0);
        })
        .catch(error => {
            console.error('Error:', error.message);
            console.error(error);
            process.exit(1);
        });
}

