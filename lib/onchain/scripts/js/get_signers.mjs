#!/usr/bin/env node
/**
 * Get signers from GCDecryptionVerifier contract.
 * Reads the contract address from GCDecryptionVerifierAddress.sol and calls getSigners().
 * Writes the signers to a file.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import Web3 from 'web3';
import { SodaWeb3Helper } from './soda-web3-helper.mjs';

function extractAddressFromSolFile(filePath) {
    try {
        const content = fs.readFileSync(filePath, 'utf8');
        
        // Match: address constant GCDecryptionVerifierAddress = 0x...;
        const pattern = /address\s+constant\s+\w+\s*=\s*(0x[a-fA-F0-9]+);/;
        const match = content.match(pattern);
        
        if (match) {
            const address = match[1];
            return Web3.utils.toChecksumAddress(address);
        } else {
            throw new Error(`Could not find address constant in ${filePath}`);
        }
    } catch (error) {
        if (error.code === 'ENOENT') {
            throw new Error(`Address file not found: ${filePath}`);
        }
        throw error;
    }
}

async function getSignersFromContract(sodaHelper, contractAddress) {
    // Setup the contract (compile to get ABI)
    const contractPath = "core/contracts/";
    
    const success = await sodaHelper.setupContract(
        contractPath,
        "GCDecryptionVerifier.sol",
        "decryption_verifier",
        false, // overwrite
        "", // MpcInterfacePath
        "", // mpcCorePath
        "" // address_path
    );
    
    if (!success) {
        throw new Error("Failed to set up the contract");
    }
    
    // Set the contract address
    const contract = sodaHelper.getContract("decryption_verifier");
    if (!contract) {
        throw new Error("Contract not found after setup");
    }
    contract.options.address = contractAddress;
    
    // Call getSigners() view function
    const signers = await sodaHelper.callContractView("decryption_verifier", "getSigners", []);
    
    if (!signers) {
        throw new Error("Failed to call getSigners()");
    }
    
    return signers;
}

function writeSignersToFile(signers, outputFile) {
    // Create directory if it doesn't exist
    const dir = path.dirname(outputFile);
    if (dir && dir !== '.') {
        fs.mkdirSync(dir, { recursive: true });
    }
    
    let content = "# Signers from GCDecryptionVerifier contract\n";
    content += `# Total signers: ${signers.length}\n\n`;
    
    signers.forEach((signer, index) => {
        content += `${index + 1}. ${signer}\n`;
    });
    
    fs.writeFileSync(outputFile, content, 'utf8');
    console.log(`Signers written to ${outputFile}`);
}

export async function getSignersAddresses() {
    // Get environment variables
    const signingKey = process.env.SIGNING_KEY;
    if (!signingKey) {
        throw new Error("SIGNING_KEY environment variable not set");
    }
    
    const providerUrl = process.env.REMOTE_RPC_URL;
    if (!providerUrl) {
        throw new Error("REMOTE_RPC_URL environment variable not set");
    }
    
    const chainId = process.env.REMOTE_CHAIN_ID;
    if (!chainId) {
        throw new Error("REMOTE_CHAIN_ID environment variable not set");
    }
    
    let chainName = process.env.CHAIN_NAME;
    if (!chainName) {
        throw new Error("CHAIN_NAME environment variable not set");
    }
    // Convert to uppercase to match Python script behavior
    chainName = chainName.toUpperCase();
    
    // Get address file path
    const addressFileChain = `lib/onchain/contracts/${chainName}/GCDecryptionVerifierAddress.sol`;
    let contractAddress = null;
    
    if (fs.existsSync(addressFileChain)) {
        contractAddress = extractAddressFromSolFile(addressFileChain);
    } else {
        throw new Error(`Address file not found. Checked:\n  - ${addressFileChain}`);
    }
    
    // Initialize SodaWeb3Helper
    const sodaHelper = new SodaWeb3Helper(signingKey, providerUrl, parseInt(chainId));
    
    // Get signers
    const signers = await getSignersFromContract(sodaHelper, contractAddress);
    
    return signers;
}

// Main execution - run if this file is executed directly
// Check if this is the main module by comparing the file path
const mainModulePath = process.argv[1];
const currentModulePath = fileURLToPath(import.meta.url);

if (mainModulePath && (mainModulePath === currentModulePath || mainModulePath.endsWith('get_signers.mjs'))) {
    (async () => {
        try {
            const signers = await getSignersAddresses();
            console.log(`\nSuccessfully retrieved ${signers.length} signer(s)`);
            process.exit(0);
        } catch (error) {
            console.error(`Error: ${error.message}`);
            console.error(error.stack);
            process.exit(1);
        }
    })();
}

