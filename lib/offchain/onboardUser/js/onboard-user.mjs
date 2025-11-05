import fs from 'fs';
import pkg from 'soda-bubble-sdk';
const { generateRSAKeyPair, decryptRSA, sign } = pkg;
import { privateToAddress } from 'ethereumjs-util';
import { createUserInteractorClient } from '../../../onchain/scripts/js/soda-web3-helper.mjs';

const RSA_CIPHERTEXT_SIZE = 256; // 2048-bit RSA key size in bytes

function removeUserKeyFromFile(filename) {
    // Read the original file and filter out the line containing "USER_KEY"
    const fileContent = fs.readFileSync(filename, 'utf-8');
    const lines = fileContent.split('\n');
    const tempLines = lines.filter(line => !line.includes("USER_KEY"));
    
    // Write the modified content back to the same file
    fs.writeFileSync(filename, tempLines.join('\n'), 'utf-8');
}

async function onboard_user(client, signingKey) {
    // Generate RSA keys and sign the public key
    const { publicKey, privateKey } = generateRSAKeyPair();
    
    // Get the Ethereum address from private key
    const signingKeyBuffer = Buffer.from(signingKey.slice(2), 'hex');
    const userAddress = privateToAddress(signingKeyBuffer);
    
    console.log(`User address: ${userAddress.toString('hex')}`);
    
    // Create message: rsa_public_key + user_address
    const message = Buffer.concat([publicKey, userAddress]);
    
    // Sign the message using EIP-191
    const signature = sign(message, signingKeyBuffer);
    
    console.log(`Onboarding user with address: 0x${userAddress.toString('hex')}`);
    
    // Create the gRPC request
    const request = {
        rsa_public_key: publicKey,
        address: userAddress,
        user_signature: signature
    };
    
    // Call the OnboardUser function
    const response = await new Promise((resolve, reject) => {
        client.OnboardUser(request, (err, res) => {
            if (err) {
                reject(err);
            } else {
                resolve(res);
            }
        });
    });

    console.log(`OnboardUser returned ${response.rsa_ciphertexts.length} bytes`);

    if (response.rsa_ciphertexts.length !== 2 * RSA_CIPHERTEXT_SIZE) {
        throw new Error(`Invalid response size: ${response.rsa_ciphertexts.length}`);
    }

    // Split the response into two ciphers
    const cipher0 = response.rsa_ciphertexts.slice(0, RSA_CIPHERTEXT_SIZE);
    const cipher1 = response.rsa_ciphertexts.slice(RSA_CIPHERTEXT_SIZE);
    
    // Convert Buffers to hex strings for decryptRSA (which expects hex strings)
    const cipher0Hex = Buffer.isBuffer(cipher0) ? cipher0.toString('hex') : Buffer.from(cipher0).toString('hex');
    const cipher1Hex = Buffer.isBuffer(cipher1) ? cipher1.toString('hex') : Buffer.from(cipher1).toString('hex');
    
    // Decrypt the AES key using the RSA private key
    const share0 = decryptRSA(privateKey, cipher0Hex);
    const share1 = decryptRSA(privateKey, cipher1Hex);
    
    // XOR the key shares to get the user AES key
    const userAesKey = Buffer.alloc(share0.length);
    for (let i = 0; i < share0.length; i++) {
        userAesKey[i] = share0[i] ^ share1[i];
    }
    
    return userAesKey;
}

async function main() {    
    // Get the private key from the environment variable
    const signingKey = process.env.SIGNING_KEY;
    if (!signingKey) {
        throw new Error("SIGNING_KEY environment variable not set");
    }

    const userInteractorUrl = process.env.USER_INTERACTOR_URL;
    if (!userInteractorUrl) {
        throw new Error("USER_INTERACTOR_URL environment variable not set");
    }

    const client = createUserInteractorClient(userInteractorUrl);
    
    const user_key = await onboard_user(client, signingKey);

    removeUserKeyFromFile('.env_user'); // Remove the old USER_KEY from the .env file
    // Write the new AES key to the .env file
    fs.appendFileSync('.env_user', `export USER_KEY='${user_key.toString('hex')}'\n`);
    console.log("User key has been successfully onboarded and saved to the env file.");
    
}

main()
  .catch(error => {
    console.error(error)
  });
