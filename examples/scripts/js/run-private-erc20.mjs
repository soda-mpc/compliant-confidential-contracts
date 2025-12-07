import { prepareIT256} from 'soda-bubble-sdk';
import {
    SodaWeb3Helper,
    createUserInteractorClient,
    LOCAL_PROVIDER_URL,
    REMOTE_HTTP_PROVIDER_URL
} from '../../../lib/onchain/scripts/js/soda-web3-helper.mjs';
import yargs from "yargs";
import {hideBin} from "yargs/helpers";
import { getEncryptedValues, getEncryptedValuesOnBehalf, decryptValue} from '../../../lib/offchain/encryptToUser/js/encrypt-to-user.mjs';
import { getSignersAddresses, extractAddressFromSolFile } from '../../../lib/onchain/scripts/js/get_signers.mjs';
import { transferToAccount } from '../../../lib/onchain/scripts/js/transfer-native-coins.mjs';
import fs from 'fs';

const FILE_NAME = 'PrivateERC20Contract.sol';
const FILE_PATH = 'examples/contracts/';
const INITIAL_BALANCE = 500000000;
let nonce;

function checkExpectedResult(name, expectedResult, result) {
    if (result === expectedResult) {
        console.log(`Test ${name} succeeded: ${result}`);
    } else {
        throw new Error(`Test ${name} failed. Expected: ${expectedResult}, Actual: ${result}`);
    }
}

async function execute_transaction(sodaHelper, func){
    const tx_hash = sodaHelper.callContractFunctionTransactionAsync(func, nonce);
    nonce++;
    return tx_hash;
}

function checkValue(name, user_key, encrypted_value, expected_value){
    const my_value = decryptValue(encrypted_value, user_key);
    checkExpectedResult(name, expected_value, my_value);
}

async function setupACLContract(sodaHelper){
    const success = await sodaHelper.setupContract("core/contracts/", "GCACL.sol", "acl", false, undefined, "");
    if (!success){
        throw new Error("Failed to set up the ACL contract")
    }

    const address_file_chain = "lib/onchain/contracts/GCACLAddress.sol"
    let acl_address = null;
    if (fs.existsSync(address_file_chain)){
        acl_address = extractAddressFromSolFile(address_file_chain);
    } else {
        throw new Error(`Address file not found. Checked:\n  - ${address_file_chain}`)
    }
    console.log(`ACL address: ${acl_address}`);
    sodaHelper.setContractAddress("acl", acl_address);
}

async function permitOnBehalf(sodaHelper, permitter, permittee, permission_type){
    // Get current block timestamp and add 2 hours (7200 seconds)
    const latest_block = await sodaHelper.web3.eth.getBlock('latest');
    const block_timestamp = Number(latest_block.timestamp);
    const expiration_time = block_timestamp + (2 * 60 * 60); // 2 hours in seconds

    let func_name = null;
    if (permission_type == "view"){
        func_name = "permitFullViewAccess";
    } else if (permission_type == "insert"){
        func_name = "permitFullInsertAccess";
    } else {
        throw new Error(`Invalid permission type: ${permission_type}`);
    }
    
    // Get permittee address - handle both contract objects and account objects
    let permittee_address;
    if (permittee.options && permittee.options.address) {
        // It's a contract object
        permittee_address = permittee.options.address;
    } else if (permittee.address) {
        // It's an account object
        permittee_address = permittee.address;
    } else {
        throw new Error("permittee must be either a contract or account object with an address");
    }
    
    // Execute transaction using callContractTransaction
    const receipt = await sodaHelper.callContractTransaction("acl", func_name, [permittee_address, expiration_time], permitter);
    if (!receipt){
        throw new Error("Failed to execute permitFullViewAccess transaction")
    }
    if (receipt.status != 1){
        throw new Error(`Transaction failed with receipt: ${receipt}`)
    }
    
    console.log(`Permit transaction successful. Receipt: ${receipt.transactionHash}`);
}

async function main() {
    const argv = yargs(hideBin(process.argv))
      .usage('Usage: node $0 <provider_url> [options]')
      .demandCommand(1, 'You must provide the provider_url as a positional argument.')
      .option('use_eip191_signature', {
          alias: 'eip191',
          type: 'boolean',
          default: false,
          describe: 'To use EIP191 signature',
      })
      .help('h')
      .alias('h', 'help')
      .parseSync();

    let providerURL = argv._[0];

    switch (argv._[0]) {
        case 'Local':
            providerURL = LOCAL_PROVIDER_URL;
            break;
        case 'Remote':
            providerURL = REMOTE_HTTP_PROVIDER_URL;
            break;
    }

    console.log("Use EIP191 Signature:", argv["use_eip191_signature"]);
    const useEIP191 = argv["use_eip191_signature"]

    // Get the private key from the environment variable
    const signingKey = process.env.SIGNING_KEY;
    if (!signingKey){
        throw new Error("SIGNING_KEY environment variable not set");
    }

    // Get the chain id from the environment variable
    const chain_id = process.env.REMOTE_CHAIN_ID;
    if (!chain_id){
        throw new Error("REMOTE_CHAIN_ID environment variable not set");
    }
    console.log(`Chain ID: ${chain_id}`);

    const signers = await getSignersAddresses();

    // Create helper function using the private key
    const sodaHelper = new SodaWeb3Helper(signingKey, providerURL, chain_id);

    const account = sodaHelper.getAccount();

    await setupACLContract(sodaHelper);

    // compile the onboard solidity contract
    let success = await sodaHelper.setupContract(FILE_PATH, FILE_NAME, "private_erc20");
    if (!success){
        throw new Error("Failed to set up the contract")
    }

    // Deploy the contract
    let receipt = await sodaHelper.deployContract("private_erc20", ["Soda", "SOD", INITIAL_BALANCE]);
    if (!receipt){
        throw new Error("Failed to deploy the contract")
    }
    const contract = sodaHelper.getContract("private_erc20")

    // compile the SA contract
    success = await sodaHelper.setupContract(FILE_PATH, "SA.sol", "sa");
    if (!success){
        throw new Error("Failed to set up the contract")
    }

    // Deploy the contract
    receipt = await sodaHelper.deployContract("sa", [account.address, contract.options.address, sodaHelper.getContractAddress("acl")]);
    if (!receipt){
        throw new Error("Failed to deploy the contract")
    }
    const sa_contract = sodaHelper.getContract("sa");

    console.log("************* Permit the SA contract to insert on behalf *************")
    await permitOnBehalf(sodaHelper, account, sa_contract, "insert");

    const user_key_hex = process.env.USER_KEY;
    const user_key = Buffer.from(user_key_hex, 'hex');

    const user_interactor_url = process.env.USER_INTERACTOR_URL;
    if (!user_interactor_url){
        throw new Error("USER_INTERACTOR_URL environment variable not set");
    }
    console.log(`User interactor URL: ${user_interactor_url}`);
    
    const client = createUserInteractorClient(user_interactor_url);

    // Generate a new account for Alice
    const alice_address = sodaHelper.generateRandomAccount();
    
    const plaintext_integer = 5;

    nonce = await sodaHelper.getCurrentNonce();


    console.log("************* Transfer clear ", plaintext_integer, " to Alice *************");
    // Transfer 5 SOD to Alice
    let func = contract.methods.transfer(alice_address.address, plaintext_integer);
    await execute_transaction(sodaHelper, func);

    console.log("************* Transfer IT ", plaintext_integer, " to Alice *************")
    // Prepare the input test for the function
    const it = prepareIT256(plaintext_integer, user_key, account.address);
    // Create the real function using the prepared IT
    func = contract.methods.transfer(alice_address.address, it);
    // Transfer 5 SOD to Alice
    await execute_transaction(sodaHelper, func)

    console.log("************* Transfer clear ", plaintext_integer, " from my account to Alice without allowance *************")
    // Trying to transfer 5 SOD to Alice. There is no allowance, transfer should fail
    func = contract.methods.transferFrom(account.address, alice_address.address, plaintext_integer);
    // There is no allowance, balance should remain the same
    await execute_transaction(sodaHelper, func);

    console.log("************* Approve ", plaintext_integer*10, " to my address *************")
    // Set allowance for this account
    func = contract.methods.approve(account.address, plaintext_integer*10);
    await sodaHelper.callContractFunctionTransactionAsync(func, nonce);
    nonce++;

    console.log("************* Transfer clear ", plaintext_integer, " from my account to Alice *************")
    // Transfer 5 SOD to Alice
    func = contract.methods.transferFrom(account.address, alice_address.address, plaintext_integer);
    await execute_transaction(sodaHelper, func);

    console.log("************* Transfer IT ", plaintext_integer, " from my account to Alice *************");
    // Transfer 5 SOD to Alice
    func = contract.methods.transferFrom(account.address, alice_address.address, it);
    await execute_transaction(sodaHelper, func)

    console.log("************* Permit account to view on behalf of SA contract *************")
    func = sa_contract.methods.permitViewAccess(account.address);
    await execute_transaction(sodaHelper, func);

    console.log("************* Transfer clear ", plaintext_integer, " to SA contract *************")
    // Transfer 5 SOD to SA
    func = contract.methods.transfer(sa_contract.options.address, plaintext_integer);
    await execute_transaction(sodaHelper, func);

    console.log("************* Transfer IT from SA contract to Alice *************")
    // Transfer 5 SOD to Alice
    func = sa_contract.methods.transfer(alice_address.address, it);
    const tx_hash = await execute_transaction(sodaHelper, func);

    await sodaHelper.waitForTransactionReceipt(tx_hash);

    // Wait 30 seconds
    await new Promise(resolve => setTimeout(resolve, 30000));

    // Get the handles of the balance and allowance
    const balance_handle = await contract.methods.balanceOf().call({'from': account.address});
    console.log(`Balance handle: ${balance_handle}`);
    const allowance_handle = await contract.methods.allowance(account.address, account.address).call({'from': account.address});
    console.log(`Allowance handle: ${allowance_handle}`);
    
    // Get the encrypted balance and allowance
    const encrypted_values = await getEncryptedValues(client, [balance_handle, allowance_handle], Buffer.from(account.privateKey.slice(2), 'hex'), chain_id, signers);

    console.log("************* Check my balance *************")
    checkValue('balance', user_key, encrypted_values[0], INITIAL_BALANCE - 5*plaintext_integer);
    
    console.log("************* Check my allowance *************")
    checkValue('allowance', user_key, encrypted_values[1], plaintext_integer*8);

    console.log("************* Check SA contract balance *************")
    const sa_handle = await sa_contract.methods.getBalance().call({'from': account.address});
    const encrypted_values_sa = await getEncryptedValuesOnBehalf(client, [sa_handle], sa_contract, Buffer.from(account.privateKey.slice(2), 'hex'), chain_id, signers);
    checkValue('balance_using_sa', user_key, encrypted_values_sa[0], 0);

    console.log("************* Transfer native currency to Alice *************")
    const faucet_key = process.env.REMOTE_FAUCET_ADDRESS;
    if (!faucet_key){
        throw new Error("REMOTE_FAUCET_ADDRESS environment variable not set");
    }
    await transferToAccount(faucet_key, alice_address, providerURL, 10);

    console.log("************* Permit this account to view on behalf of Alice *************")
    await permitOnBehalf(sodaHelper, alice_address, account, "view");

    console.log("************* Check Alice's balance on behalf *************")
    const alice_handle = await contract.methods.balanceOf().call({'from': alice_address.address});
    const encrypted_values_alice = await getEncryptedValuesOnBehalf(client, [alice_handle], alice_address, Buffer.from(account.privateKey.slice(2), 'hex'), chain_id, signers);
    checkValue('alice_balance', user_key, encrypted_values_alice[0], 5*plaintext_integer);

}

main()
  .then(() => {
    process.exit(0);
  })
  .catch(error => {
    console.error('Error:', error.message);
    console.error(error);
    process.exit(1);
  });

