import { SodaWeb3Helper } from './soda-web3-helper.mjs';

const DEFAULT_GAS_PRICE = 1; // in gwei
const MAX_GAS_PRICE = 1000;
const INCREASE_PERCENT = 1.15;

/**
 * Transfers native currency from a sender account to a receiver account
 * @param {string} senderAccountKey - Private key of the sender account
 * @param {Object} receiverAccount - Account object with address property
 * @param {string} providerUrl - RPC provider URL
 * @param {number} amountToTransfer - Amount to transfer in ether (default: 3000)
 */
export async function transferToAccount(senderAccountKey, receiverAccount, providerUrl, amountToTransfer = 3000) {
    const chainId = process.env.REMOTE_CHAIN_ID;
    console.log(`Chain ID: ${chainId}`);
    
    const sodaHelper = new SodaWeb3Helper(senderAccountKey, providerUrl, chainId ? parseInt(chainId) : undefined);
    
    const senderBalance = await sodaHelper.web3.eth.getBalance(sodaHelper.account.address);
    const originalReceiverBalance = await sodaHelper.web3.eth.getBalance(receiverAccount.address);
    
    console.log(`Balance of the sender account: ${senderBalance}`);
    if (senderBalance === null || senderBalance === undefined) {
        console.log("Failed to get the balance of the account");
    }
    
    let gasPrice = DEFAULT_GAS_PRICE;
    let receipt = null;
    
    // Attempt the transaction with retry logic
    while (gasPrice <= MAX_GAS_PRICE) {
        try {
            receipt = await transferNativeCurrency(sodaHelper, receiverAccount.address, amountToTransfer, gasPrice);
            console.log(`Transaction successful with gas price: ${gasPrice} gwei`);
            break;
        } catch (error) {
            const errorMessage = error.message || error.toString();
            console.log(`Transaction failed with gas price: ${gasPrice} gwei. Error: ${errorMessage}`);
            
            if (errorMessage.includes('replacement transaction underpriced') || 
                errorMessage.includes('is not in the chain after') ||
                errorMessage.includes('TransactionNotFound') ||
                errorMessage.includes('nonce too low')) {
                gasPrice = Math.floor(gasPrice * INCREASE_PERCENT); // Increase gas price by 15%
            } else {
                console.log(`Unexpected error: ${errorMessage}`);
                break;
            }
        }
    }
    
    if (!receipt) {
        console.log("Transaction failed after reaching the maximum gas price.");
        throw new Error("Transaction failed after reaching the maximum gas price.");
    }
    
    // Check the balance of the accounts after the transfer is complete
    const receiverBalance = await sodaHelper.web3.eth.getBalance(receiverAccount.address);
    const amountInWei = sodaHelper.web3.utils.toWei(amountToTransfer.toString(), 'ether');
    const expectedBalance = BigInt(originalReceiverBalance) + BigInt(amountInWei);
    
    if (BigInt(receiverBalance) !== expectedBalance) {
        throw new Error(`Balance mismatch. Expected: ${expectedBalance}, Actual: ${receiverBalance}`);
    }
    
    console.log(`Balance of the receiver account: ${receiverBalance}`);
}

/**
 * Helper function to transfer native currency
 * @param {SodaWeb3Helper} sodaHelper - SodaWeb3Helper instance
 * @param {string} toAddress - Recipient address
 * @param {number} amount - Amount to transfer in ether
 * @param {number} gasPrice - Gas price in gwei
 */
async function transferNativeCurrency(sodaHelper, toAddress, amount, gasPrice) {
    const nonce = await sodaHelper.web3.eth.getTransactionCount(sodaHelper.account.address);
    
    const transaction = {
        to: toAddress,
        value: sodaHelper.web3.utils.toWei(amount.toString(), 'ether'),
        gas: 21000,
        gasPrice: sodaHelper.web3.utils.toWei(gasPrice.toString(), 'gwei'),
        nonce: nonce,
        chainId: sodaHelper.chainId
    };
    
    const receipt = await sodaHelper.signAndSendTransaction(transaction);
    
    if (receipt) {
        console.log(`Transfer successful. Gas used: ${receipt.gasUsed}, Gas price: ${gasPrice} gwei`);
    }
    
    return receipt;
}

