import argparse
import logging
import os
import time
from eth_account import Account
from lib.onchain.scripts.python.soda_web3_helper import SodaWeb3Helper, parse_url_parameter
import sys
sys.path.append('lib/soda-sdk')
from python.soda_python_sdk.crypto import generate_rsa_keypair, sign, prepare_IT, prepare_IT_256
import grpc
from core.proto import userInteractor_pb2 as pb
from core.proto import userInteractor_pb2_grpc as pb_grpc
from time import sleep
from datetime import datetime
from web3.exceptions import TransactionNotFound

NONCE = 0
SIGNATURE_SIZE = 65
MAX_SLEEP_TIME = 600

SOLIDITY_FILES = ['Miscellaneous1TestsContract.sol',
                  'MalformedInputs.sol']

def print_with_timestamp(message):
    print(f'{datetime.now().strftime("%Y-%m-%d %H:%M:%S")} - {message}')

def get_user_key_shares(account, contract, receipt):
    """
    This function retrieves the key shares of a user from a transaction receipt. It processes the receipt 
    to get the UserKey events, then iterates through these events to find the ones that match the provided 
    account address. If it finds matching events, it extracts the key shares from these events. If it doesn't 
    find any matching events, it prints an error message.

    @param {object} account - The account object, which includes the user's address.
    @param {object} contract - The contract object, which includes the contract's events.
    @param {object} receipt - The transaction receipt to process.

    @return {tuple} A tuple containing the two key shares, or (None, None) if no matching events were found.
    """
    user_key_events = contract.events.UserKey().process_receipt(receipt)

    key_0_share = None
    key_1_share = None
    # Filter events for the specific address
    for event in user_key_events:
        if event['args']['_owner'].lower() == account.address.lower():
            key_0_share = event['args']['_keyShare0']
            key_1_share = event['args']['_keyShare1']
    
    if key_0_share is None or key_1_share is None:
        print_with_timestamp("Failed to find the key shares of the account address in the transaction receipt.")

    return key_0_share, key_1_share

def generate_RSA_keys_and_signature(signing_key):
    # Generate new RSA key pair
    private_key, public_key = generate_rsa_keypair()
    account = Account.from_key(signing_key)
    address = bytes.fromhex(account.address[2:])  # Remove '0x' prefix and convert to bytes
    message = public_key + address

    # Sign the public key
    signature = sign(message, bytes.fromhex(signing_key[2:]))

    return private_key, public_key, address, signature

def run_test_async(soda_helper, contract_str, function_str, func_args=[]):
    global NONCE
    tx_hash = soda_helper.call_contract_transaction_async(contract_str, function_str, NONCE, func_args=func_args)
    NONCE += 1
    return tx_hash

def check_all_tests_reverted(tx_hashes, soda_helper):
    start_time = time.time()  
    tx_receipts = set()
    print_with_timestamp(f"Wait for transaction receipts...")
    while len(tx_receipts) < len(tx_hashes) and (time.time() - start_time) < MAX_SLEEP_TIME:
        for h, function_str in tx_hashes.items():
            if h in tx_receipts:
                continue
            try:
                receipt = soda_helper.web3.eth.get_transaction_receipt(h.hex())
                if receipt is not None:
                    if receipt.status == 0:
                        print_with_timestamp(f'Test {function_str} reverted as expected')
                    else:
                        print_with_timestamp(f'Receipt: {receipt}')
                        raise ValueError(f'Test {function_str} did not revert')
                tx_receipts.add(h)
                
            except TransactionNotFound as e:
                pass
        sleep(1)

    if len(tx_receipts) < len(tx_hashes):
        raise Exception(f'Not all transactions were mined after {MAX_SLEEP_TIME} seconds.')


def is_chain_progressing(soda_helper):
    print_with_timestamp(f"Checking if the chain is progressing...")
    run_test_async(soda_helper, 'MalformedInputs.sol', "init")
    
    tx_hash = run_test_async(soda_helper, 'MalformedInputs.sol', "checkProgress")
    if tx_hash is None:
        raise Exception("Failed to call the transaction function")
    
    current_sleep_time = 0
    print_with_timestamp(f"Wait for checkProgress transaction receipts...")
    transaction_mined = False
    
    while current_sleep_time < MAX_SLEEP_TIME:
        try:
            r = soda_helper.web3.eth.get_transaction_receipt(tx_hash.hex())
            if r is not None:
                if r.status == 0:
                    raise Exception(f'CheckProgress reverted.')
                else:
                    transaction_mined = True
                    break
        except TransactionNotFound as e:
            pass
        current_sleep_time += 1
        sleep(1)

    if not transaction_mined:
        print_with_timestamp(f"ERROR: Transaction {tx_hash.hex()} was not mined after {MAX_SLEEP_TIME} seconds")
        print_with_timestamp("This could be due to low gas price or network congestion")
        raise Exception(f"Transaction {tx_hash.hex()} was not mined after {MAX_SLEEP_TIME} seconds")

    print_with_timestamp(f"CheckProgress transaction completed successfully")

    res = soda_helper.call_contract_view('MalformedInputs.sol', "getRes")
    timeout_counter = 0  
    while res == 0 and timeout_counter < MAX_SLEEP_TIME:
        sleep(1)
        timeout_counter += 1
        res = soda_helper.call_contract_view('MalformedInputs.sol', "getRes")
        
    if timeout_counter >= MAX_SLEEP_TIME:
        raise Exception(f"Timeout waiting for result after {MAX_SLEEP_TIME} seconds")
    
    if res != 20:
        raise Exception("Chain did not progress as expected, there is a test that failed")
    else:
        return True

def call_onboard_user(client, rsa_public_key, address, signature):
    try:
        # Call the gRPC service
        request = pb.OnboardUserRequest(
            rsa_public_key=rsa_public_key,
            address=address,
            user_signature=signature
        )
        client.OnboardUser(request)
        return None
    except grpc.RpcError as e:
        return e.details()

def call_encrypt_to_user(chain_id, client, handle, signature):
    try:
        # Call the gRPC service
        request = pb.EncryptToUserRequest(
            handle=handle,
            chain_id=int(chain_id),
            user_signature=signature
        )
        client.EncryptToUser(request)
        return None
    except grpc.RpcError as e:
        return e.details()

def check_error_in_response(response, expected_error_message):
    if response is None:
        raise Exception(f"OnboardUser returned no error")
    
    if expected_error_message not in response:
        raise Exception(f"OnboardUser returned error message '{response}' which does not contain expected '{expected_error_message}'")

def error_verifying_signature_onboard_user_test(signing_key, client):
    # Generate new RSA key pair and signature on the public key
    _, public_key, address, signature = generate_RSA_keys_and_signature(signing_key)

    # change the signature first 10 bytes of the signature
    wrong_signature = b'\x10' * 10 + signature[10:]
    # Call the getUserKey function
    response = call_onboard_user(client, public_key, address, wrong_signature)
    check_error_in_response(response, "user is not permitted to make this operation")

    # Call the getUserKey function with malformed address
    malformed_address = b'\x10' * 20
    response = call_onboard_user(client, public_key, malformed_address, signature)
    check_error_in_response(response, "user is not permitted to make this operation")

    # Call the getUserKey function with malformed public key
    malformed_public_key = b'\x10' * 20 + public_key[20:]
    response = call_onboard_user(client, malformed_public_key, address, signature)
    check_error_in_response(response, "user is not permitted to make this operation")

def malformed_input_onboard_user_test(signing_key, client):
    # Generate new RSA key pair and signature on the public key
    _, public_key, address, signature = generate_RSA_keys_and_signature(signing_key)

    # change the signature first 10 bytes of the signature
    malformed_signature = signature + b'\x10' * 10
    # Call the getUserKey function
    response = call_onboard_user(client, public_key, address, malformed_signature)
    check_error_in_response(response, "invalid request format")

    # Call the getUserKey function with malformed address
    malformed_address = address + b'\x10' * 10
    response = call_onboard_user(client, public_key, malformed_address, signature)
    check_error_in_response(response, "invalid request format")

    # Call the getUserKey function with malformed public key
    malformed_public_key = public_key + b'\x10' * 10
    response = call_onboard_user(client, malformed_public_key, address, signature)
    check_error_in_response(response, "user is not permitted to make this operation")

    # Call the getUserKey function with not an ethereum address
    malformed_address = bytearray(address)
    malformed_address[0] = ord("P")
    response = call_onboard_user(client, public_key, bytes(malformed_address), signature)
    check_error_in_response(response, "user is not permitted to make this operation")

def error_empty_input_onboard_user_test(signing_key, client):
    # Generate new RSA key pair and signature on the public key
    _, public_key, address, signature = generate_RSA_keys_and_signature(signing_key)

    # Create an empty input
    empty = bytes(0)

    # Call the getUserKey function with empty signature
    response = call_onboard_user(client, public_key, address, empty)
    check_error_in_response(response, "invalid request format")
    
    # Call the getUserKey function with empty public key and valid signature on valid address
    response = call_onboard_user(client, empty, address, signature)
    check_error_in_response(response, "invalid request format")

    # Call the getUserKey function with empty public key and valid signature on invalid address
    response = call_onboard_user(client, public_key, empty, signature)
    check_error_in_response(response, "invalid request format")

    # Call the getUserKey function with empty public key and signature on valid address
    response = call_onboard_user(client, empty, address, empty)
    check_error_in_response(response, "invalid request format")
    
    # Call the getUserKey function with empty address and signature on valid public key
    response = call_onboard_user(client, public_key, empty, empty)
    check_error_in_response(response, "invalid request format")

    # Call the getUserKey function with empty public key and address and valid signature
    response = call_onboard_user(client, empty, empty, signature)
    check_error_in_response(response, "invalid request format")

def non_existing_handle_encrypt_to_user_test(signing_key, chain_id, client):
    # create a non existing handle
    non_existing_handle = 10

    # Sign the handle
    signature = sign(non_existing_handle, bytes.fromhex(signing_key[2:]))

    # Call the encryptToUser function
    response = call_encrypt_to_user(chain_id, client, non_existing_handle.to_bytes(32, byteorder='big'), signature)
    check_error_in_response(response, "user is not permitted to make this operation")

def not_permitted_handle_encrypt_to_user_test(signing_key, chain_id, client, handle):
    handle_bytes = handle.to_bytes(32, byteorder='big')
    # Sign the handle
    signature = sign(handle_bytes, bytes.fromhex(signing_key[2:]))

    # Call the encryptToUser function
    response = call_encrypt_to_user(chain_id, client, handle_bytes, signature)
    check_error_in_response(response, "user is not permitted to make this operation")

def error_verifying_signature_encrypt_to_user_test(signing_key, chain_id, client):
    # create a handle
    handle = 10
    handle_bytes = handle.to_bytes(32, byteorder='big')

    # Sign the handle
    signature = sign(handle_bytes, bytes.fromhex(signing_key[2:]))

    # change the signature first 10 bytes of the signature
    wrong_signature = b'\x10' * 10 + signature[10:]

    # Call the getUserKey function
    response = call_encrypt_to_user(chain_id, client, handle_bytes, wrong_signature)
    check_error_in_response(response, "user is not permitted to make this operation")

def malformed_input_encrypt_to_user_test(signing_key, chain_id, client):
    # create a handle
    handle = 10
    handle_bytes = handle.to_bytes(32, byteorder='big')
    
    # Sign the handle
    signature = sign(handle_bytes, bytes.fromhex(signing_key[2:]))

    # change the signature first 10 bytes of the signature
    malformed_signature = signature + b'\x10' * 10

    # Call the getUserKey function
    response = call_encrypt_to_user(chain_id, client, handle_bytes, malformed_signature)
    check_error_in_response(response, "invalid request format")

    malformed_handle = handle_bytes + b'\x10' * 10
    response = call_encrypt_to_user(chain_id, client, malformed_handle, signature)
    check_error_in_response(response, "invalid request format")

def error_empty_input_encrypt_to_user_test(signing_key, chain_id, client):
    # create a handle
    handle = 10
    handle_bytes = handle.to_bytes(32, byteorder='big')

    # Sign the handle
    signature = sign(handle_bytes, bytes.fromhex(signing_key[2:]))

    # Create an empty input
    empty = bytes(0)

    # Call the encryptToUser function with empty signature
    response = call_encrypt_to_user(chain_id, client, handle_bytes, empty)
    check_error_in_response(response, "invalid request format")
    
    # Call the encryptToUser function with empty ct and signature
    response = call_encrypt_to_user(chain_id, client, empty, empty)
    check_error_in_response(response, "invalid request format")
    
    # Call the encryptToUser function with empty ct and valid signature
    response = call_encrypt_to_user(chain_id, client, empty, signature)
    check_error_in_response(response, "invalid request format")
    
def invalid_signature_test(signing_key, soda_helper, contract_str, revert_tx_hashes):
    user_key_hex = os.environ.get('USER_KEY')
    user_aes_key = bytes.fromhex(user_key_hex)  
    
    contract = soda_helper.get_contract(contract_str)
    
    # Prepare the input text for the function
    ct, signature = prepare_IT(5, user_aes_key, Account.from_key(signing_key), contract, bytes.fromhex(signing_key[2:]))
    
    # change the signature first 10 bytes of the signature
    wrong_signature = b'\x10' * 10 + signature[10:]

    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertextTest", func_args=[ct, ct, ct, ct, ct, wrong_signature])
    revert_tx_hashes[tx_hash] = "validateCiphertextTest wrong signature"

    # Sign on different contract
    diff_contract = soda_helper.get_contract('MalformedInputs.sol')
    ct, signature = prepare_IT(5, user_aes_key, Account.from_key(signing_key), diff_contract, bytes.fromhex(signing_key[2:])) 
    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertextTest", func_args=[ct, ct, ct, ct, ct, signature])
    revert_tx_hashes[tx_hash] = "validateCiphertextTest different contract"

    # Sign on different user address
    diff_user = Account.create()
    ct, signature = prepare_IT(5, user_aes_key, diff_user, contract, bytes.fromhex(signing_key[2:])) 
    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertextTest", func_args=[ct, ct, ct, ct, ct, signature])
    revert_tx_hashes[tx_hash] = "validateCiphertextTest different user address"

    # Sign using different signing key
    diff_signing_key = Account.create().key
    ct, signature = prepare_IT(5, user_aes_key, Account.from_key(signing_key), contract, diff_signing_key) 
    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertextTest", func_args=[ct, ct, ct, ct, ct, signature])
    revert_tx_hashes[tx_hash] = "validateCiphertextTest different signing key"

    # Sign on correct values but use the previous ct
    diff_signing_key = Account.create().key
    ct_new, signature_new = prepare_IT(5, user_aes_key, Account.from_key(signing_key), contract, bytes.fromhex(signing_key[2:])) 
    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertextTest", func_args=[ct, ct, ct, ct, ct, signature_new])
    revert_tx_hashes[tx_hash] = "validateCiphertextTest malformed ct"
    # Use the previous signature
    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertextTest", func_args=[ct_new, ct_new, ct_new, ct_new, ct_new, signature])
    revert_tx_hashes[tx_hash] = "validateCiphertextTest malformed signature"

def invalid_signature_test_256_bit(signing_key, soda_helper, contract_str, revert_tx_hashes):
    user_key_hex = os.environ.get('USER_KEY')
    user_aes_key = bytes.fromhex(user_key_hex)  

    contract = soda_helper.get_contract(contract_str)

    # Prepare the input text for the function
    it = prepare_IT_256(5, user_aes_key, Account.from_key(signing_key), contract, bytes.fromhex(signing_key[2:]))

    # change the signature first 10 bytes of the signature
    wrong_signature = b'\x10' * 10 + it[1][10:]
    wrong_it = (it[0], wrong_signature)

    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertext256Test", func_args=[wrong_it])
    revert_tx_hashes[tx_hash] = "validateCiphertext256Test wrong signature"

    # Sign on different contract
    diff_contract = soda_helper.get_contract('MalformedInputs.sol')
    it = prepare_IT_256(5, user_aes_key, Account.from_key(signing_key), diff_contract, bytes.fromhex(signing_key[2:])) 
    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertext256Test", func_args=[it])
    revert_tx_hashes[tx_hash] = "validateCiphertext256Test different contract"

    # Sign on different user address
    diff_user = Account.create()
    it = prepare_IT_256(5, user_aes_key, diff_user, contract, bytes.fromhex(signing_key[2:])) 
    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertext256Test", func_args=[it])
    revert_tx_hashes[tx_hash] = "validateCiphertext256Test different user address"

    # Sign using different signing key
    diff_signing_key = Account.create().key
    it = prepare_IT_256(5, user_aes_key, Account.from_key(signing_key), contract, diff_signing_key) 
    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertext256Test", func_args=[it])
    revert_tx_hashes[tx_hash] = "validateCiphertext256Test different signing key"

    # Sign on correct values but use the previous ct
    diff_signing_key = Account.create().key
    it_new = prepare_IT_256(5, user_aes_key, Account.from_key(signing_key), contract, bytes.fromhex(signing_key[2:])) 
    malformed_it = (it[0], it_new[1])
    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertext256Test", func_args=[malformed_it])
    revert_tx_hashes[tx_hash] = "validateCiphertext256Test malformed ct"
    # Use the previous signature
    malformed_it = (it_new[0], it[1])
    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertext256Test", func_args=[malformed_it])
    revert_tx_hashes[tx_hash] = "validateCiphertext256Test malformed signature"

def empty_input_validate_ciphertext_test(signing_key, soda_helper, contract_str, revert_tx_hashes):
    user_key_hex = os.environ.get('USER_KEY')
    user_aes_key = bytes.fromhex(user_key_hex)  
    
    contract = soda_helper.get_contract(contract_str)
    # Prepare the input text for the function
    ct, signature = prepare_IT(5, user_aes_key, Account.from_key(signing_key), contract, bytes.fromhex(signing_key[2:]))
    
    # Create an empty signature
    empty_signature = bytes(0)

    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertextTest", func_args=[ct, ct, ct, ct, ct, empty_signature])
    revert_tx_hashes[tx_hash] = "validateCiphertextTest empty signature"
    
    # Create an empty ct
    empty_ct = int(0)

    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertextTest", func_args=[empty_ct, empty_ct, empty_ct, empty_ct, empty_ct, empty_signature])
    revert_tx_hashes[tx_hash] = "validateCiphertextTest empty signature and ct"

    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertextTest", func_args=[empty_ct, empty_ct, empty_ct, empty_ct, empty_ct, signature])
    revert_tx_hashes[tx_hash] = "validateCiphertextTest empty ct"

def empty_input_validate_ciphertext_test_256_bit(signing_key, soda_helper, contract_str, revert_tx_hashes):
    user_key_hex = os.environ.get('USER_KEY')
    user_aes_key = bytes.fromhex(user_key_hex)  

    contract = soda_helper.get_contract(contract_str)
    
    # Prepare the input text for the function
    it = prepare_IT_256(5, user_aes_key, Account.from_key(signing_key), contract, bytes.fromhex(signing_key[2:]))

    # Create an empty signature
    empty_signature = bytes(0)
    malformed_it = (it[0], empty_signature)

    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertext256Test", func_args=[malformed_it])
    revert_tx_hashes[tx_hash] = "validateCiphertextTest empty signature"

    # Create an empty ct
    empty_ct = int(0)
    malformed_it = ((empty_ct, empty_ct), empty_signature)

    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertext256Test", func_args=[malformed_it])
    revert_tx_hashes[tx_hash] = "validateCiphertext256Test empty signature and ct"

    malformed_it = ((empty_ct, empty_ct), it[1])
    tx_hash = run_test_async(soda_helper, contract_str, "validateCiphertext256Test", func_args=[malformed_it])
    revert_tx_hashes[tx_hash] = "validateCiphertext256Test empty ct"

def malformed_handles_test(soda_helper, conrtact_str, revert_tx_hashes):
    tx_hash = run_test_async(soda_helper, conrtact_str, "handleNotExisting")
    revert_tx_hashes[tx_hash] = "handleNotExisting"

    tx_hash = run_test_async(soda_helper, conrtact_str, "handleNotPermitted_create")

    tx_hash = run_test_async(soda_helper, conrtact_str, "handleNotPermitted_use")
    revert_tx_hashes[tx_hash] = "handleNotPermitted"

def malformed_metadata_test(soda_helper, contract_str, revert_tx_hashes):
    # Check revert on bit size contains both boolean and int size
    tx_hash = run_test_async(soda_helper, contract_str, "addMixBitSize")
    revert_tx_hashes[tx_hash] = "addMixBitSize"

    # Check revert on invalid type value
    tx_hash = run_test_async(soda_helper, contract_str, "addWrongType")
    revert_tx_hashes[tx_hash] = "addWrongType"

    # Check revert on invalid bit size value in the first operand
    tx_hash = run_test_async(soda_helper, contract_str, "transferWrongBalance0BitSize")
    revert_tx_hashes[tx_hash] = "transferWrongBalance0BitSize"

    # Check revert on invalid bit size value in the second operand
    tx_hash = run_test_async(soda_helper, contract_str, "transferWrongBalance1BitSize")
    revert_tx_hashes[tx_hash] = "transferWrongBalance1BitSize"

    # Check revert on invalid bit size value in the third operand
    tx_hash = run_test_async(soda_helper, contract_str, "transferWrongAmountBitSize")
    revert_tx_hashes[tx_hash] = "transferWrongAmountBitSize"

    # Check revert on invalid bit size value in the fourth operand
    tx_hash = run_test_async(soda_helper, contract_str, "transferWrongAllowanceBitSize")
    revert_tx_hashes[tx_hash] = "transferWrongAllowanceBitSize"

    # Check revert on invalid type value in shift operation
    tx_hash = run_test_async(soda_helper, contract_str, "shlWrongType")
    revert_tx_hashes[tx_hash] = "shlWrongType"

def malformed_scalar_test(soda_helper, contract_str, revert_tx_hashes):
    # Check revert on invalid scalar value in the right operand
    tx_hash = run_test_async(soda_helper, contract_str, "addMalformedScalarR")
    revert_tx_hashes[tx_hash] = "addMalformedScalarR"

    # Check revert on invalid scalar value in the right operand
    tx_hash = run_test_async(soda_helper, contract_str, "addMalformedScalarL")
    revert_tx_hashes[tx_hash] = "addMalformedScalarL"

    # Check revert on invalid scalar value in the right operand of the mux operation
    tx_hash = run_test_async(soda_helper, contract_str, "muxMalformedScalarR")
    revert_tx_hashes[tx_hash] = "muxMalformedScalarR"

    # Check revert on invalid scalar value in the right operand of the mux operation
    tx_hash = run_test_async(soda_helper, contract_str, "muxMalformedScalarL")
    revert_tx_hashes[tx_hash] = "muxMalformedScalarL"

    # Check revert on invalid scalar value in transfer amount
    tx_hash = run_test_async(soda_helper, contract_str, "transferMalformedScalar")
    revert_tx_hashes[tx_hash] = "transferMalformedScalar"

    # Check revert on setPublic with gt value 
    tx_hash = run_test_async(soda_helper, contract_str, "setPublicWithGTValue")
    revert_tx_hashes[tx_hash] = "setPublicWithGTValue"

def unsupported_operation_test(soda_helper, contract_str, revert_tx_hashes):
    # Check revert on add with boolean parameters
    tx_hash = run_test_async(soda_helper, contract_str, "addWithBoolean")
    revert_tx_hashes[tx_hash] = "addWithBoolean"

    # Check revert on not with int parameters
    tx_hash = run_test_async(soda_helper, contract_str, "notWithInt")
    revert_tx_hashes[tx_hash] = "notWithInt"

def check_malformed_transfer(soda_helper):
    # Check that the transfer returned the correct results
    new_a = soda_helper.call_contract_view('MalformedInputs.sol', "getNewA")
    while new_a == 0:
        sleep(1)
        new_a = soda_helper.call_contract_view('MalformedInputs.sol', "getNewA")

    new_b = soda_helper.call_contract_view('MalformedInputs.sol', "getNewB")
    while new_b == 0:
        sleep(1)
        new_b = soda_helper.call_contract_view('MalformedInputs.sol', "getNewB")
        
    res_transfer = soda_helper.call_contract_view('MalformedInputs.sol', "getResTransfer")
    if new_a != 10 or new_b != 10 or res_transfer != False:
        raise Exception("Transfer returned the wrong results")
    
    print_with_timestamp("Malformed transfer returned the expected results")
    
def main(provider_url: str, user_interactor_url: str):

    signing_key = os.environ.get('SIGNING_KEY')
    if not signing_key:
        raise ValueError("SIGNING_KEY environment variable not set")

    chain_id = os.environ.get('REMOTE_CHAIN_ID')
    print(f"Chain ID: {chain_id}")

    print(f"Provider URL: {provider_url}")
    print(f"User interactor URL: {user_interactor_url}")

    soda_helper = SodaWeb3Helper(signing_key, provider_url, chain_id=int(chain_id))

    # Compile the contracts
    for file_name in SOLIDITY_FILES:
        success = soda_helper.setup_contract("tests/contracts/" + file_name, file_name)
        if not success:
            raise Exception("Failed to set up the contract")

    # Deploy the contract
    receipts = soda_helper.deploy_multi_contracts(SOLIDITY_FILES, constructor_args=[])
    
    if len(receipts) != len(SOLIDITY_FILES):
        raise Exception("Failed to deploy the contracts")

    global NONCE
    NONCE = soda_helper.get_current_nonce()

    # Create a gRPC channel
    channel = grpc.insecure_channel(user_interactor_url)
    client = pb_grpc.UserInteractorServiceStub(channel)

    revert_tx_hashes = {}

    # There are three types of unhappy flow tests:
    # 1. Revert tests: These tests are expected to revert and we check if they revert as expected. 
    #    The returned tx hashes are stored in revert_tx_hashes and at the end of the tests, we check if all the tests are reverted.
    # 2. System progression tests: These tests are expected to not revert but also not cause the system to stuck.
    #    The system progression check is done at the end of the tests after all the tests are executed.
    # 3. User interactor tests: These tests are connecting the user interactor and not the chain, and expected to get an error on the result.

    # Revert tests
    # Check revert on 'invalid signature' error in validateCiphertext function
    invalid_signature_test(signing_key, soda_helper, SOLIDITY_FILES[0], revert_tx_hashes)

    # Check revert on 'invalid signature' error in validateCiphertext256 function
    invalid_signature_test_256_bit(signing_key, soda_helper, SOLIDITY_FILES[0], revert_tx_hashes)

    # Check revert on empty signature or ct in validateCiphertext function
    empty_input_validate_ciphertext_test(signing_key, soda_helper, SOLIDITY_FILES[0], revert_tx_hashes)

    # Check revert on empty signature or ct in validateCiphertext256 function
    empty_input_validate_ciphertext_test_256_bit(signing_key, soda_helper, SOLIDITY_FILES[0], revert_tx_hashes)

    # Check revert on malformed handles (not existing handle and not permitted handle)
    malformed_handles_test(soda_helper, 'MalformedInputs.sol', revert_tx_hashes)
    
    # Check malformed scalar value
    malformed_scalar_test(soda_helper, 'MalformedInputs.sol', revert_tx_hashes)

    # Check unsupported operation
    unsupported_operation_test(soda_helper, 'MalformedInputs.sol', revert_tx_hashes)
    
    # Check malformed metadata
    malformed_metadata_test(soda_helper, 'MalformedInputs.sol', revert_tx_hashes)
    
    # Check malformed GT
    tx_hash = run_test_async(soda_helper, 'MalformedInputs.sol', "nonExistingGTValue")
    revert_tx_hashes[tx_hash] = "nonExistingGTValue"

    # System progression tests

    # Check wrong input size
    tx_hash = run_test_async(soda_helper, 'MalformedInputs.sol', "malformedInput")


    # Check division by zero
    run_test_async(soda_helper, 'MalformedInputs.sol', "divisionByZero")

    # Check malformed transfer
    run_test_async(soda_helper, 'MalformedInputs.sol', "amountBiggerThanBalance")

    # Check that all revert tests are reverted
    check_all_tests_reverted(revert_tx_hashes, soda_helper) 

    # Check that the transfer returned the correct results
    check_malformed_transfer(soda_helper)

    print_with_timestamp("After check transfer")

    if not is_chain_progressing(soda_helper):
        raise ValueError("Bubble system did not progress as expected, some test has failed")
    else:
        print_with_timestamp("All tests passed successfully, no test caused the bubble system to stuck")


    # Get an existing handle
    handle = soda_helper.call_contract_view('MalformedInputs.sol', "getHandle")

    # Check user interactor error on invalid signature in onboard user function
    error_verifying_signature_onboard_user_test(signing_key, client)

    # Check user interactor error on malformed input in onboard user function
    malformed_input_onboard_user_test(signing_key, client)

    # Check user interactor error on empty signature or ct in onboard user function
    error_empty_input_onboard_user_test(signing_key, client)

    non_existing_handle_encrypt_to_user_test(signing_key, chain_id, client)

    not_permitted_handle_encrypt_to_user_test(signing_key, chain_id, client, handle)

    error_verifying_signature_encrypt_to_user_test(signing_key, chain_id, client)

    # Check user interactor error on malformed input in encrypt to user function
    malformed_input_encrypt_to_user_test(signing_key, chain_id, client)

    error_empty_input_encrypt_to_user_test(signing_key, chain_id, client)

    print_with_timestamp("All tests passed successfully, user interactor returned the correct errors")


def parse_url_parameter():
    parser = argparse.ArgumentParser(description='Get URL')
    parser.add_argument('provider_url', type=str, help='The provider url')
    parser.add_argument("--user_interactor_url", help="The url of the user interactor", default="0.0.0.0:50060")

    args = parser.parse_args()
    print(f'Provider URL: {args.provider_url}')

    return args.provider_url, args.user_interactor_url

if __name__ == "__main__":
    url, user_interactor_url = parse_url_parameter()
    if (url is not None):
        try:
            main(url, user_interactor_url)
        except Exception as e:
            logging.error("An error occurred: %s", e)
            raise e
            
