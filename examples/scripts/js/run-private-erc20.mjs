import { prepareIT256} from 'soda-bubble-sdk';
import {
    SodaWeb3Helper,
    createUserInteractorClient,
    LOCAL_PROVIDER_URL,
    REMOTE_HTTP_PROVIDER_URL
} from '../../../lib/onchain/scripts/js/soda-web3-helper.mjs';
import yargs from "yargs";
import {hideBin} from "yargs/helpers";
import { getEncryptedValues, decryptValue} from '../../../lib/offchain/encryptToUser/js/encrypt-to-user.mjs';
import { getSignersAddresses } from '../../../lib/onchain/scripts/js/get_signers.mjs';

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
    console.log("Provider URL:", providerURL);
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

    // compile the onboard solidity contract
    const success = await sodaHelper.setupContract(FILE_PATH, FILE_NAME, "private_erc20");
    if (!success){
        throw new Error("Failed to set up the contract")
    }

    // Deploy the contract
    let receipt = await sodaHelper.deployContract("private_erc20", ["Soda", "SOD", INITIAL_BALANCE]);
    if (!receipt){
        throw new Error("Failed to deploy the contract")
    }

    await new Promise(resolve => setTimeout(resolve, 10000));

    console.log("************* View functions *************");
    const contractName = await sodaHelper.callContractView("private_erc20", "name")
    console.log("Function call result name:", contractName);

    const symbol = await sodaHelper.callContractView("private_erc20", "symbol")
    console.log("Function call result symbol:", symbol);

    const decimals = await sodaHelper.callContractView("private_erc20", "decimals")
    console.log("Function call result decimals:", decimals);

    const totalSupply = await sodaHelper.callContractView("private_erc20", "totalSupply")
    console.log("Function call result totalSupply:", totalSupply);

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
    
    const contract = sodaHelper.getContract("private_erc20")
    const account = sodaHelper.getAccount();
    
    const plaintext_integer = 5;

    nonce = await sodaHelper.getCurrentNonce();


    console.log("************* Transfer clear ", plaintext_integer, " to Alice *************");
    // Transfer 5 SOD to Alice
    let func = contract.methods.transfer(alice_address.address, plaintext_integer);
    await execute_transaction(sodaHelper, func);

    console.log("************* Transfer IT ", plaintext_integer, " to Alice *************")
    // Prepare the input test for the function
    let it = prepareIT256(
        plaintext_integer, 
        user_key, 
        Buffer.from(account.address.toString().slice(2), 'hex'),
        Buffer.from(contract.options.address.toString().slice(2), 'hex'),
        Buffer.from(signingKey.slice(2), 'hex'), useEIP191);
    // Create the real function using the prepared IT
    func = contract.methods.transfer(alice_address.address, it);
    // Transfer 5 SOD to Alice
    await execute_transaction(sodaHelper, func, contract)

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
    await execute_transaction(sodaHelper, func, contract);

    console.log("************* Transfer IT ", plaintext_integer, " from my account to Alice *************");
    // Transfer 5 SOD to Alice
    it = prepareIT256(
        plaintext_integer, 
        user_key, 
        Buffer.from(account.address.toString().slice(2), 'hex'),
        Buffer.from(contract.options.address.toString().slice(2), 'hex'),
        Buffer.from(signingKey.slice(2), 'hex'), useEIP191);
    // Create the real function using the prepared IT output
    func = contract.methods.transferFrom(account.address, alice_address.address, it);
    const tx_hash = await execute_transaction(sodaHelper, func, contract)

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
    checkValue('balance', user_key, encrypted_values[0], INITIAL_BALANCE - 4*plaintext_integer);
    
    console.log("************* Check my allowance *************")
    checkValue('allowance', user_key, encrypted_values[1], plaintext_integer*8);
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

