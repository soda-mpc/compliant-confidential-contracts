import os
import time
from eth_account import Account
import sys
sys.path.append('lib/soda-sdk')
from python.soda_python_sdk.crypto import prepare_IT_256
from lib.onchain.scripts.python.soda_web3_helper import SodaWeb3Helper, LOCAL_PROVIDER_URL, REMOTE_HTTP_PROVIDER_URL
from web3.exceptions import TransactionNotFound
from time import sleep
import logging
import argparse
import grpc
from core.proto import userInteractor_pb2 as pb
from core.proto import userInteractor_pb2_grpc as pb_grpc
from lib.offchain.encryptToUser.python.encrypt_to_user import get_encrypted_values, get_encrypted_values_on_behalf, decrypt_value
from lib.onchain.scripts.python.get_signers import get_signers_addresses, extract_address_from_sol_file
from lib.onchain.scripts.python.transfer_native_coins import transfer_to_account

FILE_NAME = 'PrivateERC20Contract.sol'
FILE_PATH = 'examples/contracts/'
INITIAL_BALANCE = 500000000
NONCE = 0

def execute_transaction(soda_helper, function):
    global NONCE
    tx_hash = soda_helper.call_contract_function_transaction_async("private_erc20", function, NONCE)
    NONCE += 1
    return tx_hash

def check_value(name, user_key, encrypted_value, expected_value):
    try:
        my_balance = decrypt_value(encrypted_value, user_key)
        check_expected_result(name, expected_value, my_balance)
    except Exception as e:
        print(f"Error checking {name}: {e}")
        raise

def check_expected_result(name, expected_result, result):
    if result == expected_result:
        print(f'Test {name} succeeded: {result}')
    else:
        raise ValueError(f'Test {name} failed. Expected: {expected_result}, Actual: {result}')

def setup_acl_contract(soda_helper):
    print(f"Compiling GCACL contract")
    success = soda_helper.setup_contract("core/contracts/GCACL.sol", "acl", mpc_core_path="")
    if not success:
        raise Exception("Failed to set up the ACL contract")

    # Get address file path 
    address_file_chain = f"lib/onchain/contracts/GCACLAddress.sol"
    acl_address = None
    if os.path.exists(address_file_chain):
        acl_address = extract_address_from_sol_file(address_file_chain)
    else:
        raise FileNotFoundError(f"Address file not found. Checked:\n  - {address_file_chain}")
    print(f"ACL address: {acl_address}")
    # Set the ACL contract address so we can call functions on it
    soda_helper.set_contract_address("acl", acl_address)

def permitOnBehalf(soda_helper, permitter, permittee, permission_type):
    
    # Get current block timestamp and add 2 hours (7200 seconds)
    latest_block = soda_helper.web3.eth.get_block('latest')
    block_timestamp = latest_block['timestamp']
    expiration_time = block_timestamp + (2 * 60 * 60)  # 2 hours in seconds
    
    function = None
    if permission_type == "view":
        function = "permitFullViewAccess"
    elif permission_type == "insert":
        function = "permitFullInsertAccess"
    else:
        raise ValueError(f"Invalid permission type: {permission_type}")

    # Execute transaction from Alice's account using SodaWeb3Helper
    receipt = soda_helper.call_contract_transaction(
        "acl",
        function,
        func_args=[permittee.address, expiration_time],
        account=permitter,
        priority="low"
    )
    
    if receipt is None:
        raise Exception("Failed to execute permitFullViewAccess transaction")
    if receipt.status != 1:
        raise Exception(f"Transaction failed with receipt: {receipt}")
    
    print(f"Permit transaction successful. Receipt: {receipt.transactionHash.hex()}")
    
    # Get the ACL contract and process AccountPermitted events
    acl_contract = soda_helper.get_contract("acl")
    account_permitted_events = acl_contract.events.AccountPermitted().process_receipt(receipt)
    
    if account_permitted_events:
        print("AccountPermitted event(s):")
        for event in account_permitted_events:
            print(f"  Caller: {event['args']['caller']}")
            print(f"  Permittee: {event['args']['permittee']}")
            print(f"  PermissionType: {event['args']['permissionType']}")
            print(f"  PermitCounter: {event['args']['permitCounter']}")
            print(f"  OldExpirationDate: {event['args']['oldExpirationDate']}")
            print(f"  NewExpirationDate: {event['args']['newExpirationDate']}")
            print(f"  BlockNumber: {event['blockNumber']}")
            print(f"  TransactionHash: {event['transactionHash'].hex()}")
    else:
        print("No AccountPermitted event found in receipt")

def main(provider_url: str, use_eip191_signature: bool):
    # Get the account private key from the environment variable
    private_key = os.environ.get('SIGNING_KEY')
    account = Account.from_key(private_key)

    chain_id = os.environ.get('REMOTE_CHAIN_ID')

    signers = get_signers_addresses()

    soda_helper = SodaWeb3Helper(private_key, provider_url, chain_id=int(chain_id))

    setup_acl_contract(soda_helper)

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

    # Compile the contract
    success = soda_helper.setup_contract(FILE_PATH + "SA.sol", "sa")
    if not success:
        raise Exception("Failed to set up the contract")

    # Deploy the contract
    receipt = soda_helper.deploy_contract("sa", constructor_args=[account.address, contract.address, soda_helper.get_contract_address("acl")])
    if receipt is None:
        raise Exception("Failed to deploy the contract")
    print("Contract deployed at address: ", receipt.contractAddress)

    sa_contract = soda_helper.get_contract("sa")
    
    print("************* Permit the SA contract to insert on behalf *************")
    permitOnBehalf(soda_helper, account, sa_contract, "insert")
    
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
    tx_hashes.append(execute_transaction(soda_helper, function))

    print("************* Transfer IT ", plaintext_integer, " to Alice *************")
    # Prepare the input text for the function
    it = prepare_IT_256(plaintext_integer, user_key, account.address)
    # Create the real function using the prepared IT
    function = contract.functions.transfer(alice_address.address, it)
    # Transfer 5 SOD to Alice
    tx_hashes.append(execute_transaction(soda_helper, function))

    print("************* Transfer clear ", plaintext_integer, " from my account to Alice without allowance *************")
    # Trying to transfer 5 SOD to Alice. There is no allowance, transfer should fail
    function = contract.functions.transferFrom(account.address, alice_address.address, plaintext_integer)
    tx_hashes.append(execute_transaction(soda_helper, function))

    print("************* Approve ", plaintext_integer*10, " to my address *************")
    # Set allowance for this account
    function = contract.functions.approve(account.address, plaintext_integer*10)
    soda_helper.call_contract_function_transaction_async("private_erc20", function, NONCE)
    NONCE += 1

    print("************* Transfer clear ", plaintext_integer, " from my account to Alice *************")
    # Transfer 5 SOD to Alice
    function = contract.functions.transferFrom(account.address, alice_address.address, plaintext_integer)
    tx_hashes.append(execute_transaction(soda_helper, function))

    print("************* Transfer IT ", plaintext_integer, " from my account to Alice *************")
    # Transfer 5 SOD to Alice
    # Create the real function using the prepared IT
    function = contract.functions.transferFrom(account.address, alice_address.address, it)
    tx_hashes.append(execute_transaction(soda_helper, function))

    print("************* Permit account to view on behalf of SA contract *************")
    function = sa_contract.functions.permitViewAccess(account.address)
    tx_hashes.append(execute_transaction(soda_helper, function))
    
    print("************* Transfer clear ", plaintext_integer, " to SA contract *************")
    # Transfer 5 SOD to SA
    function = contract.functions.transfer(sa_contract.address, plaintext_integer)
    tx_hashes.append(execute_transaction(soda_helper, function))

    print("************* Transfer IT from SA contract to Alice *************")
    # Transfer 5 SOD to Alice
    function = sa_contract.functions.transfer(alice_address.address, it)
    tx_hashes.append(execute_transaction(soda_helper, function))

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

    tx_hashes = []
    sleep(30)

    # Get the handles to encrypt (balance and allowance)
    balance_handle = contract.functions.balanceOf().call({'from': account.address})
    allowance_handle = contract.functions.allowance(account.address, account.address).call()

    print("Balance handle:", balance_handle)
    print("Allowance handle:", allowance_handle)

    # Ask the user interactor for the encrypted balance
    encrypted_values = get_encrypted_values(client, [balance_handle, allowance_handle], account, chain_id, signers)

    print("************* Check my balance *************")
    check_value("balance", user_key, encrypted_values[0], INITIAL_BALANCE - 5*plaintext_integer)

    print("************* Check my allowance *************")
    check_value("allowance", user_key, encrypted_values[1], plaintext_integer*8)

    print("************* Check SA contract balance *************")
    sa_handle = sa_contract.functions.getBalance().call({'from': account.address})
    encrypted_values = get_encrypted_values_on_behalf(client, [sa_handle], sa_contract, account, chain_id, signers)
    check_value("balance_using_sa", user_key, encrypted_values[0], 0)

    print("************* Transfer native currency to Alice *************")
    faucet_key = os.environ.get('REMOTE_FAUCET_ADDRESS')
    if not faucet_key:
        raise ValueError("REMOTE_FAUCET_ADDRESS environment variable not set")
    transfer_to_account(faucet_key, alice_address, provider_url, 10)

    print("************* Permit this account to view on behalf of Alice *************")
    permitOnBehalf(soda_helper, alice_address, account, "view")

    print("************* Check Alice's balance on behalf *************")
    alice_handle = contract.functions.balanceOf().call({'from': alice_address.address})
    encrypted_values = get_encrypted_values_on_behalf(client, [alice_handle], alice_address, account, chain_id, signers)
    check_value("alice_balance", user_key, encrypted_values[0], 5*plaintext_integer)

    

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
