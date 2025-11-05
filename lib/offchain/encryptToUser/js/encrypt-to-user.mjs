import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import pkg from 'soda-bubble-sdk';
const { BLOCK_SIZE, decrypt, sign, verifySignature, readPublicKeyFromPem } = pkg;
import { createUserInteractorClient } from '../../../onchain/scripts/js/soda-web3-helper.mjs';

const NUM_EVALUATORS = 2;

export async function getEncryptedValue(client, handle, signingKey, chain_id, public_keys){
    
    // Convert handle (BigInt or number) to 32-byte Buffer
    let handle_bytes;
    if (typeof handle === 'bigint') {
        const hexString = handle.toString(16).padStart(64, '0'); // 32 bytes = 64 hex chars
        handle_bytes = Buffer.from(hexString, 'hex');
    } else {
        const hexString = BigInt(handle).toString(16).padStart(64, '0');
        handle_bytes = Buffer.from(hexString, 'hex');
    }

    // Sign the handle
    const signature = sign(handle_bytes, signingKey);

    // Create gRPC request
    const request = {
        handle: handle_bytes,
        chain_id: parseInt(chain_id),
        user_signature: signature
    };

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

    if (response.output.length !== BLOCK_SIZE * 4){
        throw new Error(`Invalid response size: ${response.output.length}`);
    }
    if (response.mpc_signatures && response.mpc_signatures.length !== NUM_EVALUATORS){
        throw new Error(`Invalid number of signatures: ${response.mpc_signatures.length}`);
    }
    
    // Validate signatures 
    if (response.mpc_signatures && !validate_signatures(response.mpc_signatures, handle_bytes, response.output, public_keys)){
        throw new Error("Invalid signatures");
    }
    
    return response.output;
}

function validate_signatures(signatures, handle_bytes, output, public_keys){
    for (let i = 0; i < signatures.length; i++){
        if (!verifySignature(public_keys[i], handle_bytes, output, signatures[i])){
            console.log(`Verification failed for evaluator ${i}`);
            return false;
        }
    }
    return true;
}

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

    return parseInt(decryptedMessage.toString('hex'), BLOCK_SIZE);
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

    const public_keys_path = process.env.PUBLIC_KEYS_PATH;
    if (!public_keys_path) {
        throw new Error("PUBLIC_KEYS_PATH environment variable not set");
    }

    const publicKeys = [];
    publicKeys.push(readPublicKeyFromPem(public_keys_path + "evaluator0PublicKey.pem"));
    publicKeys.push(readPublicKeyFromPem(public_keys_path + "evaluator1PublicKey.pem"));

    console.log("Encrypting value to user");
    
    // Get encrypted value
    const signingKeyBuffer = Buffer.from(signingKey.slice(2), 'hex');
    const encrypted_value = await getEncryptedValue(client, handle, signingKeyBuffer, chainId, publicKeys);

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

