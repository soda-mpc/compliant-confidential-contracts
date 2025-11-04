import os
from eth_account import Account
from soda_python_sdk import prepare_IT_256, read_public_key_from_pem
from lib.onchain.scripts.python.soda_web3_helper import SodaWeb3Helper, LOCAL_PROVIDER_URL, REMOTE_HTTP_PROVIDER_URL
from web3.exceptions import TransactionNotFound
from time import sleep
import logging
import argparse
import grpc
from proto import userInteractor_pb2_grpc as pb_grpc
from lib.offchain.encryptToUser.python.encrypt_to_user import get_encrypted_value, decrypt_value

FILE_NAME = 'PrivateERC20Contract.sol'
FILE_PATH = 'examples/contracts/'
INITIAL_BALANCE = 500000000
NONCE = 0

def execute_transaction(soda_helper, account, contract, function):
    global NONCE
    tx_hash = soda_helper.call_contract_function_transaction_async("private_erc20", function, NONCE)
    NONCE += 1
    return tx_hash

def check_balance(client, contract, account, user_key, expected_balance, chain_id, public_keys):
    try:
        # Get the handle of the balance
        handle = contract.functions.balanceOf().call({'from': account.address})
        print("Balance handle:", handle.to_bytes(32, byteorder='big'))

        # Ask the user interactor for the encrypted balance, decrypt it and check if it matches the expected value
        my_CTBalance = get_encrypted_value(client, handle, account, chain_id, public_keys)
        my_balance = decrypt_value(my_CTBalance, user_key)
        check_expected_result("balanceOf", expected_balance, my_balance)
    except Exception as e:
        print(f"Error checking balance: {e}")
        raise

def check_allowance(client, contract, account, user_key, expected_allowance, chain_id, public_keys):
    try:
        # Get the handle of the allowance
        handle = contract.functions.allowance(account.address, account.address).call()
        print("Allowance handle:", handle)
        
    # Ask the user interactor for the encrypted allowance, decrypt it and check if it matches the expected value
        my_CTAllowance = get_encrypted_value(client, handle, account, chain_id, public_keys)
        allowance = decrypt_value(my_CTAllowance, user_key)
        check_expected_result('allowance', expected_allowance, allowance)
    except Exception as e:
        print(f"Error checking allowance: {e}")
        raise

def check_expected_result(name, expected_result, result):
    if result == expected_result:
        print(f'Test {name} succeeded: {result}')
    else:
        raise ValueError(f'Test {name} failed. Expected: {expected_result}, Actual: {result}')

def main(provider_url: str, use_eip191_signature: bool):
    # Get the account private key from the environment variable
    private_key = os.environ.get('SIGNING_KEY')
    account = Account.from_key(private_key)

    chain_id = os.environ.get('REMOTE_CHAIN_ID')

    soda_helper = SodaWeb3Helper(private_key, provider_url, chain_id=int(chain_id))

    # Compile the contract
    success = soda_helper.setup_contract(FILE_PATH + FILE_NAME, "private_erc20")
    if not success:
        raise Exception("Failed to set up the contract")

    # Deploy the contract
    receipt = soda_helper.deploy_contract("private_erc20", constructor_args=["Soda", "SOD", INITIAL_BALANCE])
    if receipt is None:
        raise Exception("Failed to deploy the contract")
    print("Contract deployed at address: ", receipt.contractAddress)

    contract = soda_helper.get_contract("private_erc20")

    soda_helper.wait_for_nonce_confirmation()   

    global NONCE
    NONCE = soda_helper.get_current_nonce()

    print("************* View functions *************")
    name = contract.functions.name().call({'from': account.address})
    print("Function call result name:", name)

    symbol = contract.functions.symbol().call({'from': account.address})
    print("Function call result symbol:", symbol)

    decimals = contract.functions.decimals().call({'from': account.address})
    print("Function call result decimals:", decimals)

    totalSupply = contract.functions.totalSupply().call({'from': account.address})
    print("Function call result totalSupply:", totalSupply)

    user_key_hex = os.environ.get('USER_KEY')
    user_key = bytes.fromhex(user_key_hex)

    user_interactor_url = os.environ.get('USER_INTERACTOR_URL')
    if not user_interactor_url:
        raise ValueError("USER_INTERACTOR_URL environment variable not set")

    print(f"User interactor URL: {user_interactor_url}")
    # Create a gRPC channel
    channel = grpc.insecure_channel(user_interactor_url)
    client = pb_grpc.UserInteractorServiceStub(channel)

    # Generate a new Ethereum account for Alice
    alice_address = Account.create()

    plaintext_integer = 5

    tx_hashes = []
    print("************* Transfer clear ", plaintext_integer, " to Alice *************")
    # Transfer 5 SOD to Alice
    function = contract.functions.transfer(alice_address.address, plaintext_integer)
    tx_hashes.append(execute_transaction(soda_helper, account, contract, function))

    print("************* Transfer IT ", plaintext_integer, " to Alice *************")
    # Prepare the input text for the function
    it = prepare_IT_256(plaintext_integer, user_key, account, contract, bytes.fromhex(private_key[2:]), use_eip191_signature)
    # Create the real function using the prepared IT
    function = contract.functions.transfer(alice_address.address, it)
    # Transfer 5 SOD to Alice
    tx_hashes.append(execute_transaction(soda_helper, account, contract, function))

    print("************* Transfer clear ", plaintext_integer, " from my account to Alice without allowance *************")
    # Trying to transfer 5 SOD to Alice. There is no allowance, transfer should fail
    function = contract.functions.transferFrom(account.address, alice_address.address, plaintext_integer)
    tx_hashes.append(execute_transaction(soda_helper, account, contract, function))

    print("************* Approve ", plaintext_integer*10, " to my address *************")
    # Set allowance for this account
    function = contract.functions.approve(account.address, plaintext_integer*10)
    soda_helper.call_contract_function_transaction_async("private_erc20", function, NONCE)
    NONCE += 1

    print("************* Transfer clear ", plaintext_integer, " from my account to Alice *************")
    # Transfer 5 SOD to Alice
    function = contract.functions.transferFrom(account.address, alice_address.address, plaintext_integer)
    tx_hashes.append(execute_transaction(soda_helper, account, contract, function))

    print("************* Transfer IT ", plaintext_integer, " from my account to Alice *************")
    # Transfer 5 SOD to Alice
    # Create the real function using the prepared IT
    function = contract.functions.transferFrom(account.address, alice_address.address, it)
    tx_hashes.append(execute_transaction(soda_helper, account, contract, function))
    
    # Wait for the last transaction to be mined
    for tx_hash in tx_hashes:
        tx_receipt = None
        attempts = 0  
        max_attempts = 60  # Wait for a maximum of 60 seconds  
    
        while tx_receipt is None and attempts < max_attempts:
            try:
                tx_receipt = soda_helper.web3.eth.get_transaction_receipt(tx_hash.hex())
                if tx_receipt.status != 1:
                    raise Exception(f"Transaction {tx_hash.hex()} failed")
                print(f"Transaction {tx_hash.hex()} mined")
            except TransactionNotFound as e:
                attempts += 1  
                sleep(1)

    sleep(30)

    public_keys_path = os.environ.get('PUBLIC_KEYS_PATH')

    public_keys = []
    public_keys.append(read_public_key_from_pem(public_keys_path + "evaluator0PublicKey.pem"))
    public_keys.append(read_public_key_from_pem(public_keys_path + "evaluator1PublicKey.pem"))


    print("************* Check my balance *************")
    check_balance(client, contract, account, user_key, INITIAL_BALANCE - 4*plaintext_integer, chain_id, public_keys)

    print("************* Check my allowance *************")
    # Check that the allowance has changed to 50 SOD
    check_allowance(client, contract, account, user_key, plaintext_integer*8, chain_id, public_keys)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='onboard user parameters')
    parser.add_argument('provider_url', type=str, help='The provider url')
    parser.add_argument('--use_eip191_signature', type=bool, default=False, help='To use EIP191 signature')
    args = parser.parse_args()

    url = args.provider_url
    if args.provider_url == "Local":
        url = LOCAL_PROVIDER_URL
    elif args.provider_url == "Remote":
        url = REMOTE_HTTP_PROVIDER_URL

    try:
        main(url, args.use_eip191_signature)
    except Exception as e:
        logging.error("An error occurred: %s", e)
        raise e
