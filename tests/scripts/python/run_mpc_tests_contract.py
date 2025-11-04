import argparse
from datetime import datetime
import logging
import os
import random
import sys
from time import sleep
import time
import grpc
from core.proto import userInteractor_pb2 as pb
from core.proto import userInteractor_pb2_grpc as pb_grpc
sys.path.append('lib/soda-sdk')
from python.soda_python_sdk.crypto import generate_aes_key, write_aes_key, generate_rsa_keypair, recover_user_key, sign, decrypt, prepare_IT, prepare_IT_256
from lib.onchain.scripts.python.soda_web3_helper import SodaWeb3Helper, LOCAL_PROVIDER_URL, REMOTE_HTTP_PROVIDER_URL
from lib.offchain.onboardUser.python.onboard_user import onboard_user
from web3.exceptions import TransactionNotFound
from eth_account import Account
import hashlib
import re

# Path to the Solidity files
SOLIDITY_FILES = ['ArythmeticTestsContract.sol',
                  'Arythmetic2TestsContract.sol',
                  'BitwiseTestsContract.sol', 
                  'Bitwise2TestsContract.sol', 
                  'Comparison2TestsContract.sol', 
                  'Comparison3TestsContract.sol', 
                  'MiscellaneousTestsContract.sol',
                  'Miscellaneous1TestsContract.sol',
                  'DivRemTestsContract.sol',
                  'TransferTestsContract.sol', 
                  'Transfer256TestsContract.sol', 
                  'TransferAllowanceTestsContract.sol', 
                  'TransferAllowance64TestsContract.sol', 
                  'TransferAllowance128TestsContract.sol', 
                  'TransferAllowance256TestsContract.sol', 
                  'TransferAllowanceScalarTestsContract.sol', 
                  'TransferAllowanceScalar128TestsContract.sol', 
                  'TransferAllowanceScalar256TestsContract.sol', 
                  'TransferScalarTestsContract.sol', 
                  'MinMaxTestsContract.sol', 
                  'ShiftTestsContract.sol', 
                  'Comparison1TestsContract.sol',
                  'CheckedWithOverflowFuncsTestsContract.sol', 
                  'CheckedWithOverflowFuncs1TestsContract.sol']
NONCE = 0
MAX_SLEEP_TIME = 600
MAX_UINT_8 = 255
MAX_UINT_16 = 65535
MAX_UINT_32 = 4294967295
MAX_UINT_64 = 18446744073709551615
MAX_UINT_128 = 340282366920938463463374607431768211455
MAX_UINT_256 = 115792089237316195423570985008687907853269984665640564039457584007913129639935

AES_CIPHERTEXT_SIZE = 16  # 128 bits = 16 bytes

timestamp = datetime.now().strftime('%Y-%m-%d_%H:%M:%S')
OUTPUT_FILE = f'mpc_test_output.txt'

transaction_log_file = f'logs/transactions_log.txt'


def setup(provider_url: str, user_interactor_url: str):
    signing_key = os.environ.get('SIGNING_KEY')
    if not signing_key:
        raise ValueError("SIGNING_KEY environment variable not set")
    
    chain_id = os.environ.get('REMOTE_CHAIN_ID')
    print(f"Chain ID: {chain_id}")

    soda_helper = SodaWeb3Helper(signing_key, provider_url, chain_id=int(chain_id))

    # Compile the contracts
    for file_name in SOLIDITY_FILES:
        success = soda_helper.setup_contract("tests/contracts/" + file_name, file_name)
        if not success:
            print_error_to_file(f'Failed to set up the contract {file_name}')
            raise Exception("Failed to set up the contract")

    try:
        # Deploy the contract
        receipts = soda_helper.deploy_multi_contracts(SOLIDITY_FILES, constructor_args=[])
    except Exception as e:
        print_error_to_file(f'Failed to deploy the contracts')
        raise Exception("Failed to deploy the contracts")
    
    if len(receipts) != len(SOLIDITY_FILES):
        print_error_to_file(f'Failed to deploy the contracts')
        raise Exception("Failed to deploy the contracts")
    
    for receipt in receipts:
        message = f'Deploy contract resulted in transaction hash {receipt.transactionHash.hex()}'
        with open(transaction_log_file, "a") as output_file:
            print(f'{datetime.now().strftime("%Y-%m-%d %H:%M:%S")} - {message}', file=output_file, flush=True)

    global NONCE
    NONCE = soda_helper.get_current_nonce()

    # Create a gRPC channel
    channel = grpc.insecure_channel(user_interactor_url)

    client = pb_grpc.UserInteractorServiceStub(channel)
    
    try:
        print("onboarding user")
		# Create a grpc call for onboarding a user
        user_key = onboard_user(client, signing_key)
        print(f"User key: {user_key.hex()}")

    except Exception as e:
        print_error_to_file(f'Failed to onboard user')
        raise Exception("Failed to onboard user")

    return soda_helper, signing_key, client, channel, user_key


def print_with_timestamp(message):
    print(f'{datetime.now().strftime("%Y-%m-%d %H:%M:%S")} - {message}')

def print_error_to_file(message):
    with open(OUTPUT_FILE, "a") as output_file:
        print(f'{datetime.now().strftime("%Y-%m-%d %H:%M:%S")} - {message}', file=output_file, flush=True)

def execute_transaction_with_gas_estimation(name, soda_helper, contract, func_name, func_args=None):
    if func_args is None:
        func_args = []
    gas_estimate = soda_helper.estimate_gas(contract, func_name, func_args=func_args)
    print_with_timestamp(f'Estimated Gas: {gas_estimate}')
    global NONCE
    tx_hash = soda_helper.call_contract_transaction_async(contract, func_name, NONCE, func_args=func_args)
    NONCE += 1
    return tx_hash

def execute_transaction(name, soda_helper, contract, func_name, func_args=None):
    if func_args is None:
        func_args = []
    global NONCE
    tx_hash = soda_helper.call_contract_transaction_async(contract, func_name, NONCE, func_args=func_args)
    NONCE += 1
    return tx_hash

def check_expected_result(soda_helper, contractName, checkDecryptedFunctionName, functionName, name, expected_result):
    result = get_result(soda_helper, contractName, checkDecryptedFunctionName, functionName, name)
    
    if result == expected_result:
        print_with_timestamp(f'Test {name} succeeded: {result}')
    else:
        print_error_to_file(f'Test {name} failed. Expected: {expected_result}, Actual: {result}')
        raise ValueError(f'Test {name} failed. Expected: {expected_result}, Actual: {result}')

def get_result(soda_helper, contractName, checkDecryptedFunctionName, functionName, name):
    print_with_timestamp(f'Checking expected result for {name}...')
    is_decyrpted = soda_helper.call_contract_view(contractName, checkDecryptedFunctionName)
    while is_decyrpted == 0:
        time.sleep(1)
        is_decyrpted = soda_helper.call_contract_view(contractName, checkDecryptedFunctionName)
        if is_decyrpted is None:
            raise Exception("Failed to call the is decrypted view function")
            
    result = soda_helper.call_contract_view(contractName, functionName)
    if result is None:
        raise Exception("Failed to call the result view function")
    return result

def check_offboard_result(soda_helper, signing_key, grpc_client, user_key, expected_result):
    result = soda_helper.call_contract_view("MiscellaneousTestsContract.sol", "getOffboardHandle")
    if result is None:
        raise Exception("Failed to call the result view function")

    chain_id = os.environ.get('REMOTE_CHAIN_ID')
    if not chain_id or not chain_id.strip():  
        raise ValueError("REMOTE_CHAIN_ID environment variable not set or empty")  

    handle_bytes = result.to_bytes(32, byteorder='big')
    # Sign the handle
    signature = sign(handle_bytes, bytes.fromhex(signing_key[2:]))

    # Call the gRPC service to get the encrypted balance of this handle
    request = pb.EncryptToUserRequest(
		handle=handle_bytes,
        chain_id=int(chain_id),
        user_signature=signature
	)
    response = grpc_client.EncryptToUser(request)
    
    logging.info(f"EncryptToUser returned {len(response.output)} bytes")
    
    if len(response.output) != AES_CIPHERTEXT_SIZE*2:
        raise ValueError(f"Invalid response size: {len(response.output)}")

    checkCt(response.output, user_key, expected_result)

# Test functions
def test_addition(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("addition", soda_helper, contract, "addTest", func_args=[a, b])

def test_checked_addition(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("checked addition", soda_helper, contract, "checkedAddTest", func_args=[a, b])

def test_checked_addition_with_overflow_bit(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("checked addition with overflow bit", soda_helper, contract, "checkedAddWithOverflowBitTest", func_args=[a, b])

# Test Checked Addition that should overflow
def test_checked_addition_overflow(soda_helper, contract, a, b, a16, b16, a32, b32, a64, b64, a128, b128, a256, b256):
    return execute_transaction_with_gas_estimation("checked addition overflow", soda_helper, contract, "checkedAddOverflowTest", func_args=[a, b, a16, b16, a32, b32, a64, b64, a128, b128, a256, b256])

def test_subtraction(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("subtraction", soda_helper, contract, "subTest", func_args=[a, b])

def test_checked_subtraction(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("checked subtraction", soda_helper, contract, "checkedSubTest", func_args=[a, b])

def test_checked_subtraction_with_overflow_bit(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("checked subtraction with overflow bit", soda_helper, contract, "checkedSubWithOverflowBitTest", func_args=[a, b])

# Test Checked Subtraction that should overflow
def test_checked_subtraction_overflow(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("checked subtraction overflow", soda_helper, contract, "checkedSubOverflowTest", func_args=[a, b])

def test_multiplication(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("multiplication", soda_helper, contract, "mulTest", func_args=[a, b])

def test_checked_multiplication(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("checked multiplication", soda_helper, contract, "checkedMulTest", func_args=[a, b])

def test_checked_multiplication_with_overflow_bit(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("checked multiplication with overflow bit", soda_helper, contract, "checkedMulWithOverflowBitTest", func_args=[a, b])

# Test Checked Multiplication that should overflow
def test_checked_multiplication_overflow(soda_helper, contract, a, b, a16, b16, a32, b32, a64, b64, a128, b128, a256, b256):
    return execute_transaction_with_gas_estimation("checked multiplication overflow", soda_helper, contract, "checkedMulOverflowTest", func_args=[a, b, a16, b16, a32, b32, a64, b64, a128, b128, a256, b256])

def test_division(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("division", soda_helper, contract, "divTest", func_args=[a, b])

def test_remainder(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("reminder", soda_helper, contract, "remTest", func_args=[a, b])

def test_bitwise_and(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("bitwise and", soda_helper, contract, "andTest", func_args=[a, b])

def test_bitwise_or(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("bitwise or", soda_helper, contract, "orTest", func_args=[a, b])

def test_bitwise_xor(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("bitwise xor", soda_helper, contract, "xorTest", func_args=[a, b])

def test_bitwise_shift_left(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("bitwise shift left", soda_helper, contract, "shlTest", func_args=[a, b])

def test_bitwise_shift_right(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("bitwise shift right", soda_helper, contract, "shrTest", func_args=[a, b])

def test_min(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("min", soda_helper, contract, "minTest", func_args=[a, b])

def test_max(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("max", soda_helper, contract, "maxTest", func_args=[a, b])

def test_eq(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("equality", soda_helper, contract, "eqTest", func_args=[a, b])

def test_ne(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("not equal", soda_helper, contract, "neTest", func_args=[a, b])

def test_ge(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("greater than or equal", soda_helper, contract, "geTest", func_args=[a, b])

def test_gt(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("greater than", soda_helper, contract, "gtTest", func_args=[a, b])

def test_le(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("less than or equal", soda_helper, contract, "leTest", func_args=[a, b])

def test_lt(soda_helper, contract, a, b):
    return execute_transaction_with_gas_estimation("less than", soda_helper, contract, "ltTest", func_args=[a, b])

def test_mux(soda_helper, contract, selectionBit, a, b):
    return execute_transaction_with_gas_estimation("mux", soda_helper, contract, "muxTest", func_args=[selectionBit, a, b])

def test_transfer(soda_helper, contract, a, b, amount):
    return execute_transaction_with_gas_estimation("transfer", soda_helper, contract, "transferTest", func_args=[a, b, amount])

def test_transfer_allowance(soda_helper, contract, a, b, amount, allowance):
    return execute_transaction_with_gas_estimation("transfer with allowance", soda_helper, contract, "transferWithAllowanceTest", func_args=[a, b, amount, allowance])

def prepare_offboard(soda_helper, contract, a):
    return execute_transaction_with_gas_estimation("prepare offboard handle", soda_helper, contract, "offboardToUserHandle", func_args=[a])

def test_not(soda_helper, contract, bit):
    return execute_transaction_with_gas_estimation("not", soda_helper, contract, "notTest", func_args=[bit])
    
 
def checkCt(ct_bytes, decrypted_aes_key, expected_result):
    
    # Split ct into two 128-bit arrays r and cipher
    cipher = ct_bytes[:16]
    r = ct_bytes[16:]

    # Decrypt the cipher
    decrypted_message = decrypt(decrypted_aes_key, r, cipher)

    # Print the decrypted cipher
    x = int.from_bytes(decrypted_message, 'big')
    
    if x == expected_result:
        print_with_timestamp(f'Test offboard succeeded: {x}')
    else:
        print_error_to_file(f'Test offboard failed. Expected: {expected_result}, Actual: {x}')
        raise ValueError(f'Test offboard failed. Expected: {expected_result}, Actual: {x}')

def print_tx_data(tx_hash, test_name, contract_name, func_name):
    message = f'Transaction hash {tx_hash.hex()} resulted from test "{test_name}" using function "{func_name}" on contract "{contract_name}"'
    with open(transaction_log_file, "a") as output_file:
        print(f'{datetime.now().strftime("%Y-%m-%d %H:%M:%S")} - {message}', file=output_file, flush=True)
    

last_random_result = 0
last_random_bounded_result = 0

def test_random(soda_helper, contract):
    return execute_transaction("random", soda_helper, contract, "randomTest")

def test_randomBoundedBits(soda_helper, contract, numBits):
    return execute_transaction("random bounded", soda_helper, contract, "randomBoundedTest", func_args=[numBits])

def test_boolean(soda_helper, contract, bool_a, bool_b, bit):
    return execute_transaction_with_gas_estimation("boolean tests", soda_helper, contract, "booleanTest", func_args=[bool_a, bool_b, bit])

def get_function_signature(function_abi):
    # Extract the input types from the ABI
    input_types = ','.join([param['type'] for param in function_abi.get('inputs', [])])

    # Generate the function signature
    return f"{function_abi['name']}({input_types})"

def test_validate_ciphertext(soda_helper, signing_key, user_key, contract_str, a):
    contract = soda_helper.get_contract(contract_str)
    # Prepare the input text for the function
    ct, signature = prepare_IT(a, user_key, Account.from_key(signing_key), contract, bytes.fromhex(signing_key[2:]))
    return execute_transaction_with_gas_estimation("validate ciphertext", soda_helper, contract_str, "validateCiphertextTest", func_args=[ct, ct, ct, ct, ct, signature])


def test_validate_ciphertext_eip191(soda_helper, signing_key, user_key, contract_str, a):
    contract = soda_helper.get_contract(contract_str)
    # Prepare the input text for the function
    ct, signature = prepare_IT(a, user_key, Account.from_key(signing_key), contract, bytes.fromhex(signing_key[2:]), eip191=True)
    return execute_transaction_with_gas_estimation("validate ciphertext eip191", soda_helper, contract_str, "validateCiphertextEip191Test", func_args=[ct, ct, ct, ct, ct, signature])

def test_validate_ciphertext_256(soda_helper, signing_key, user_key, contract_str, a):
    contract = soda_helper.get_contract(contract_str)
    # Prepare the input text for the function
    it = prepare_IT_256(a, user_key, Account.from_key(signing_key), contract, bytes.fromhex(signing_key[2:]))
    return execute_transaction_with_gas_estimation("validate ciphertext 256", soda_helper, contract_str, "validateCiphertext256Test", func_args=[it])

def test_validate_ciphertext_256_eip191(soda_helper, signing_key, user_key, contract_str, a):
    contract = soda_helper.get_contract(contract_str)
    # Prepare the input text for the function
    it = prepare_IT_256(a, user_key, Account.from_key(signing_key), contract, bytes.fromhex(signing_key[2:]), eip191=True)
    return execute_transaction_with_gas_estimation("validate ciphertext 256 eip191", soda_helper, contract_str, "validateCiphertext256Eip191Test", func_args=[it])



def checkResults(soda_helper, signing_key, expected_results, grpc_client, user_key):

    print("Start to check results...")
    
    # Regular add
    check_expected_result(soda_helper, 'ArythmeticTestsContract.sol', "isAddDecrypted", "getAddResult", "addition", expected_results["addition"])

    # Add with overflow bit
    check_expected_result(soda_helper, 'CheckedWithOverflowFuncsTestsContract.sol', "isAddDecrypted", "getAddResult", "checked_addition_with_overflow_bit", expected_results["checked_addition_overflow_res"])
    check_expected_result(soda_helper, 'CheckedWithOverflowFuncsTestsContract.sol', "isAddDecrypted", "getAddOverflowBit", "checked_addition_with_overflow_bit", expected_results["checked_addition_overflow_bit"])

    # Add that should overflow
    check_expected_result(soda_helper, 'CheckedWithOverflowFuncsTestsContract.sol', "isAddOverflowDecrypted", "getAddOverflow", "checked_addition_overflow", expected_results["checked_addition_overflow"])

    # Regular subtract
    check_expected_result(soda_helper, 'ArythmeticTestsContract.sol', "isSubDecrypted", "getSubResult", "subtract", expected_results["subtract"])

    # Subtract with overflow bit
    check_expected_result(soda_helper, 'CheckedWithOverflowFuncsTestsContract.sol', "isSubDecrypted", "getSubResult", "checked_subtract_with_overflow_res", expected_results["checked_subtract_overflow_res"])
    check_expected_result(soda_helper, 'CheckedWithOverflowFuncsTestsContract.sol', "isSubDecrypted", "getSubOverflowBit", "checked_subtract_with_overflow_bit", expected_results["checked_subtract_overflow_bit"])

    # Subtract that should overflow
    check_expected_result(soda_helper, 'CheckedWithOverflowFuncsTestsContract.sol', "isSubOverflowDecrypted", "getSubResultShouldOverflow", "checked_subtract_should_overflow_res", expected_results["checked_subtract_with_overflow_res"])
    check_expected_result(soda_helper, 'CheckedWithOverflowFuncsTestsContract.sol', "isSubOverflowDecrypted", "getSubOverflow", "checked_subtract_should_overflow_bit", expected_results["checked_subtract_with_overflow_bit"])

    # Regular multiplication
    check_expected_result(soda_helper, 'Arythmetic2TestsContract.sol', "isMulDecrypted", "getMulResult", "multiplication", expected_results["multiplication"])

    # Multiplication with overflow bit
    check_expected_result(soda_helper, 'CheckedWithOverflowFuncs1TestsContract.sol', "isMulDecrypted", "getMulResult", "checked_multiplication_with_overflow_bit", expected_results["checked_multiplication_overflow_res"])
    check_expected_result(soda_helper, 'CheckedWithOverflowFuncs1TestsContract.sol', "isMulDecrypted", "getMulOverflowBit", "checked_multiplication_with_overflow_bit", expected_results["checked_multiplication_overflow_bit"])

    # Multiplication that should overflow
    check_expected_result(soda_helper, 'CheckedWithOverflowFuncs1TestsContract.sol', "isMulOverflowDecrypted", "getMulOverflow", "checked_multiplication_overflow", expected_results["checked_multiplication_overflow"])

    # Division
    check_expected_result(soda_helper, 'DivRemTestsContract.sol', "isDivDecrypted", "getDivResult", "division", expected_results["division"])

    # Reminder
    check_expected_result(soda_helper, 'DivRemTestsContract.sol', "isRemDecrypted", "getRemResult", "reminder", expected_results["reminder"])

    # Mux
    check_expected_result(soda_helper, 'MiscellaneousTestsContract.sol', "isMuxDecrypted", "getMuxResult", "mux", expected_results["mux"])

    # Not
    check_expected_result(soda_helper, 'MiscellaneousTestsContract.sol', "isNotDecrypted", "getBoolResult", "not", expected_results["not"])

    # And
    check_expected_result(soda_helper, 'BitwiseTestsContract.sol', "isAndDecrypted", "getAndResult", "and", expected_results["and"])

    # Or
    check_expected_result(soda_helper, 'BitwiseTestsContract.sol', "isOrDecrypted", "getOrResult", "or", expected_results["or"])

    # Xor
    check_expected_result(soda_helper, 'Bitwise2TestsContract.sol', "isXorDecrypted", "getXorResult", "xor", expected_results["xor"])

    # Shift left
    check_expected_result(soda_helper, 'ShiftTestsContract.sol', "isShlDecrypted", "getSHLResultUint8", "bitwise shift left 8", expected_results["shift_left8"])
    check_expected_result(soda_helper, 'ShiftTestsContract.sol', "isShlDecrypted", "getSHLResultUint16", "bitwise shift left 16", expected_results["shift_left16"])
    check_expected_result(soda_helper, 'ShiftTestsContract.sol', "isShlDecrypted", "getSHLResultUint32", "bitwise shift left 32", expected_results["shift_left32"])
    check_expected_result(soda_helper, 'ShiftTestsContract.sol', "isShlDecrypted", "getSHLResultUint64", "bitwise shift left 64", expected_results["shift_left64"])
    check_expected_result(soda_helper, 'ShiftTestsContract.sol', "isShlDecrypted", "getSHLResultUint128", "bitwise shift left 128", expected_results["shift_left128"])
    check_expected_result(soda_helper, 'ShiftTestsContract.sol', "isShlDecrypted", "getSHLResultUint256", "bitwise shift left 256", expected_results["shift_left256"])

    # Shift right
    check_expected_result(soda_helper, 'ShiftTestsContract.sol', "isShrDecrypted", "getSHRResult", "bitwise shift right", expected_results["shift_right"])

    # Min   
    check_expected_result(soda_helper, 'MinMaxTestsContract.sol', "isMinDecrypted", "getMinResult", "min", expected_results["min"])

    # Max
    check_expected_result(soda_helper, 'MinMaxTestsContract.sol', "isMaxDecrypted", "getMaxResult", "max", expected_results["max"])

    # Eq
    check_expected_result(soda_helper, 'Comparison2TestsContract.sol', "isEqDecrypted", "getEqResult", "eq", expected_results["eq"])

    # Ne
    check_expected_result(soda_helper, 'Comparison2TestsContract.sol', "isNeDecrypted", "getNeResult", "ne", expected_results["ne"])

    # Ge
    check_expected_result(soda_helper, 'Comparison3TestsContract.sol', "isGeDecrypted", "getGeResult", "ge", expected_results["ge"])

    # Gt
    check_expected_result(soda_helper, 'Comparison3TestsContract.sol', "isGtDecrypted", "getGtResult", "gt", expected_results["gt"])

    # Le
    check_expected_result(soda_helper, 'Comparison1TestsContract.sol', "isLeDecrypted", "getLeResult", "le", expected_results["le"])

    # Lt
    check_expected_result(soda_helper, 'Comparison1TestsContract.sol', "isLtDecrypted", "getLtResult", "lt", expected_results["lt"])
    
    # Transfer
    check_expected_result(soda_helper, 'TransferTestsContract.sol', "isTransferDecrypted", "getNewA", "transfer_a", expected_results["transfer_a"])
    check_expected_result(soda_helper, 'TransferTestsContract.sol', "isTransferDecrypted", "getNewB", "transfer_b", expected_results["transfer_b"])
    check_expected_result(soda_helper, 'TransferTestsContract.sol', "isTransferDecrypted", "getResult", "transfer_res", True)

    # Transfer 256
    check_expected_result(soda_helper, 'Transfer256TestsContract.sol', "isTransferDecrypted", "getNewA", "transfer_a", expected_results["transfer_a"])
    check_expected_result(soda_helper, 'Transfer256TestsContract.sol', "isTransferDecrypted", "getNewB", "transfer_b", expected_results["transfer_b"])
    check_expected_result(soda_helper, 'Transfer256TestsContract.sol', "isTransferDecrypted", "getResult", "transfer_res", True)
    
    # Transfer scalar
    check_expected_result(soda_helper, 'TransferScalarTestsContract.sol', "isTransferDecrypted", "getNewA", "transfer_a", expected_results["transfer_a"])
    check_expected_result(soda_helper, 'TransferScalarTestsContract.sol', "isTransferDecrypted", "getNewB", "transfer_b", expected_results["transfer_b"])
    check_expected_result(soda_helper, 'TransferScalarTestsContract.sol', "isTransferDecrypted", "getResult", "transfer_res", True)

    # Transfer with allowance
    check_expected_result(soda_helper, 'TransferAllowanceTestsContract.sol', "isTransferDecrypted", "getNewA", "transfer_allowance_a", expected_results["transfer_a"])
    check_expected_result(soda_helper, 'TransferAllowanceTestsContract.sol', "isTransferDecrypted", "getNewB", "transfer_allowance_b", expected_results["transfer_b"])
    check_expected_result(soda_helper, 'TransferAllowanceTestsContract.sol', "isTransferDecrypted", "getResult", "transfer_allowance_res", True)
    check_expected_result(soda_helper, 'TransferAllowanceTestsContract.sol', "isTransferDecrypted", "getNewAllowance", "transfer_allowance_allowance", expected_results["transfer_allowance"])

    # Transfer with allowance 64 bit
    check_expected_result(soda_helper, 'TransferAllowance64TestsContract.sol', "isTransferDecrypted", "getNewA", "transfer_allowance_a", expected_results["transfer_a"])
    check_expected_result(soda_helper, 'TransferAllowance64TestsContract.sol', "isTransferDecrypted", "getNewB", "transfer_allowance_b", expected_results["transfer_b"])
    check_expected_result(soda_helper, 'TransferAllowance64TestsContract.sol', "isTransferDecrypted", "getResult", "transfer_allowance_res", True)
    check_expected_result(soda_helper, 'TransferAllowance64TestsContract.sol', "isTransferDecrypted", "getNewAllowance", "transfer_allowance_allowance", expected_results["transfer_allowance"])

    # Transfer with allowance 128 bit
    check_expected_result(soda_helper, 'TransferAllowance128TestsContract.sol', "isTransferDecrypted", "getNewA", "transfer_allowance_a", expected_results["transfer_a"])
    check_expected_result(soda_helper, 'TransferAllowance128TestsContract.sol', "isTransferDecrypted", "getNewB", "transfer_allowance_b", expected_results["transfer_b"])
    check_expected_result(soda_helper, 'TransferAllowance128TestsContract.sol', "isTransferDecrypted", "getResult", "transfer_allowance_res", True)
    check_expected_result(soda_helper, 'TransferAllowance128TestsContract.sol', "isTransferDecrypted", "getNewAllowance", "transfer_allowance_allowance", expected_results["transfer_allowance"])

    # Transfer with allowance 256 bit
    check_expected_result(soda_helper, 'TransferAllowance256TestsContract.sol', "isTransferDecrypted", "getNewA", "transfer_allowance_a", expected_results["transfer_a"])
    check_expected_result(soda_helper, 'TransferAllowance256TestsContract.sol', "isTransferDecrypted", "getNewB", "transfer_allowance_b", expected_results["transfer_b"])
    check_expected_result(soda_helper, 'TransferAllowance256TestsContract.sol', "isTransferDecrypted", "getResult", "transfer_allowance_res", True)
    check_expected_result(soda_helper, 'TransferAllowance256TestsContract.sol', "isTransferDecrypted", "getNewAllowance", "transfer_allowance_allowance", expected_results["transfer_allowance"])

    # Transfer with allowance scalar
    check_expected_result(soda_helper, 'TransferAllowanceScalarTestsContract.sol', "isTransferDecrypted", "getNewA", "transfer_allowance_scalar_a", expected_results["transfer_a"])
    check_expected_result(soda_helper, 'TransferAllowanceScalarTestsContract.sol', "isTransferDecrypted", "getNewB", "transfer_allowance_scalar_b", expected_results["transfer_b"])
    check_expected_result(soda_helper, 'TransferAllowanceScalarTestsContract.sol', "isTransferDecrypted", "getResult", "transfer_allowance_scalar_res", True)
    check_expected_result(soda_helper, 'TransferAllowanceScalarTestsContract.sol', "isTransferDecrypted", "getNewAllowance", "transfer_allowance_scalar_allowance", expected_results["transfer_allowance"])

    # Transfer with allowance scalar 128
    check_expected_result(soda_helper, 'TransferAllowanceScalar128TestsContract.sol', "isTransferDecrypted", "getNewA", "transfer_allowance_scalar_a", expected_results["transfer_a"])
    check_expected_result(soda_helper, 'TransferAllowanceScalar128TestsContract.sol', "isTransferDecrypted", "getNewB", "transfer_allowance_scalar_b", expected_results["transfer_b"])
    check_expected_result(soda_helper, 'TransferAllowanceScalar128TestsContract.sol', "isTransferDecrypted", "getResult", "transfer_allowance_scalar_res", True)
    check_expected_result(soda_helper, 'TransferAllowanceScalar128TestsContract.sol', "isTransferDecrypted", "getNewAllowance", "transfer_allowance_scalar_allowance", expected_results["transfer_allowance"])

    # Transfer with allowance scalar 256
    check_expected_result(soda_helper, 'TransferAllowanceScalar256TestsContract.sol', "isTransferDecrypted", "getNewA", "transfer_allowance_scalar_a", expected_results["transfer_a"])
    check_expected_result(soda_helper, 'TransferAllowanceScalar256TestsContract.sol', "isTransferDecrypted", "getNewB", "transfer_allowance_scalar_b", expected_results["transfer_b"])
    check_expected_result(soda_helper, 'TransferAllowanceScalar256TestsContract.sol', "isTransferDecrypted", "getResult", "transfer_allowance_scalar_res", True)
    check_expected_result(soda_helper, 'TransferAllowanceScalar256TestsContract.sol', "isTransferDecrypted", "getNewAllowance", "transfer_allowance_scalar_allowance", expected_results["transfer_allowance"])

    # Boolean operations
    check_expected_result(soda_helper, 'Miscellaneous1TestsContract.sol', "isBooleanDecrypted", "getAndResult", "boolean_and", expected_results["boolean_and"])
    check_expected_result(soda_helper, 'Miscellaneous1TestsContract.sol', "isBooleanDecrypted", "getOrResult", "boolean_or", expected_results["boolean_or"])
    check_expected_result(soda_helper, 'Miscellaneous1TestsContract.sol', "isBooleanDecrypted", "getXorResult", "boolean_xor", expected_results["boolean_xor"])
    check_expected_result(soda_helper, 'Miscellaneous1TestsContract.sol', "isBooleanDecrypted", "getNotResult", "boolean_not", expected_results["boolean_not"])
    check_expected_result(soda_helper, 'Miscellaneous1TestsContract.sol', "isBooleanDecrypted", "getEqResult", "boolean_equal", expected_results["boolean_equal"])
    check_expected_result(soda_helper, 'Miscellaneous1TestsContract.sol', "isBooleanDecrypted", "getNeResult", "boolean_notEqual", expected_results["boolean_notEqual"])
    check_expected_result(soda_helper, 'Miscellaneous1TestsContract.sol', "isBooleanDecrypted", "getMuxResult", "boolean_mux", expected_results["boolean_mux"])

    # Random
    global last_random_result  # Use the global keyword to use and modify the global variable
    result = get_result(soda_helper, "Miscellaneous1TestsContract.sol", "isRandomDecrypted", "getRandom", "random")
    if result != last_random_result:
        print_with_timestamp(f'Test Random succeeded: {result}')
        last_random_result = result
    else:
        print_error_to_file(f'Test Random failed. {result}')
        raise Exception(f'Test Random failed. {result}')

    # # Random Bounded Bits
    # global last_random_bounded_result
    # result = get_result(soda_helper, "Miscellaneous1TestsContract.sol", "isRandomBoundedDecrypted", "getRandomBounded", "random_bounded")
    # if result != last_random_bounded_result:
    #     print_with_timestamp(f'Test RandomBoundedBits succeeded: {result}')
    #     last_random_bounded_result = result
    # else:
    #     print_error_to_file(f'Test RandomBoundedBits failed. {result}')
    #     raise Exception(f'Test RandomBoundedBits failed. {result}')

    #  Validate Ciphertext
    check_expected_result(soda_helper, "Miscellaneous1TestsContract.sol", "isValidateCiphertextDecrypted", "getValidateCiphertextResult", "validate_ciphertext", expected_results["validate_ciphertext"])

    check_expected_result(soda_helper, "Miscellaneous1TestsContract.sol", "isValidateCiphertextEip191Decrypted", "getValidateCiphertextEip191Result", "validate_ciphertext_eip191", expected_results["validate_ciphertext_eip191"])

    check_expected_result(soda_helper, "Miscellaneous1TestsContract.sol", "isValidateCiphertext256Decrypted", "getValidateCiphertext256Result", "validate_ciphertext_256", expected_results["validate_ciphertext_256"])

    check_expected_result(soda_helper, "Miscellaneous1TestsContract.sol", "isValidateCiphertext256Eip191Decrypted", "getValidateCiphertext256Eip191Result", "validate_ciphertext_256_eip191", expected_results["validate_ciphertext_256_eip191"])

    check_offboard_result(soda_helper, signing_key, grpc_client, user_key, expected_results["offboard_handle"])

# Main test function
def run_tests(soda_helper, signing_key, a, b, shift, bit, numBits, bool_a, bool_b, allowance, check_results, grpc_client, user_key):
    expected_results = {}
    tx_hashes = {}

    # Test Addition
    print_with_timestamp("Run addition test...")
    tx_hash = test_addition(soda_helper, 'ArythmeticTestsContract.sol', a, b)
    print_tx_data(tx_hash, "addition", 'ArythmeticTestsContract.sol', "addTest")
    tx_hashes[tx_hash] = "addition"
    expected_results["addition"] = a+b

    # Test Checked Addition with Overflow Bit
    print_with_timestamp("Run checked addition with overflow bit test...")
    tx_hash = test_checked_addition_with_overflow_bit(soda_helper, 'CheckedWithOverflowFuncsTestsContract.sol', a, b)
    print_tx_data(tx_hash, "checked_addition_with_overflow_bit", 'CheckedWithOverflowFuncsTestsContract.sol', "checkedAddWithOverflowBitTest")
    tx_hashes[tx_hash] = "checked_addition_with_overflow_bit"
    expected_results["checked_addition_overflow_res"] = a+b
    expected_results["checked_addition_overflow_bit"] = True if a+b < a else False

    # Test Checked Addition that should overflow
    print_with_timestamp("Run overflow addition test ...")
    tx_hash = test_checked_addition_overflow(soda_helper, 'CheckedWithOverflowFuncsTestsContract.sol', MAX_UINT_8, a, MAX_UINT_16, b, MAX_UINT_32, a, MAX_UINT_64, b, MAX_UINT_128, a, MAX_UINT_256, a)
    print_tx_data(tx_hash, "checked_addition_overflow", 'CheckedWithOverflowFuncsTestsContract.sol', "checkedAddOverflowTest")
    tx_hashes[tx_hash] = "checked_addition_overflow"
    expected_results["checked_addition_overflow"] = True
    
    # Test Subtraction
    print_with_timestamp("Run subtraction test...")
    tx_hash = test_subtraction(soda_helper, 'ArythmeticTestsContract.sol', a, b)
    print_tx_data(tx_hash, "subtract", 'ArythmeticTestsContract.sol', "subTest")
    tx_hashes[tx_hash] = "subtract"
    expected_results["subtract"] = a-b

    # Test Checked Subtraction with Overflow Bit
    print_with_timestamp("Run checked subtraction with overflow bit test...")
    tx_hash = test_checked_subtraction_with_overflow_bit(soda_helper, 'CheckedWithOverflowFuncsTestsContract.sol', a, b)
    print_tx_data(tx_hash, "checked_subtract_with_overflow_bit", 'CheckedWithOverflowFuncsTestsContract.sol', "checkedSubWithOverflowBitTest")
    tx_hashes[tx_hash] = "checked_subtract_with_overflow_bit"
    expected_results["checked_subtract_overflow_res"] = a-b
    expected_results["checked_subtract_overflow_bit"] = True if a-b > a else False

    # Test Checked Subtraction that should overflow
    print_with_timestamp("Run overflow subtraction test ...")
    tx_hash = test_checked_subtraction_overflow(soda_helper, 'CheckedWithOverflowFuncsTestsContract.sol', a, MAX_UINT_8)
    print_tx_data(tx_hash, "checked_subtraction_overflow", 'CheckedWithOverflowFuncsTestsContract.sol', "checkedSubOverflowTest")
    tx_hashes[tx_hash] = "checked_subtraction_overflow"
    expected_results["checked_subtract_with_overflow_res"] = a
    expected_results["checked_subtract_with_overflow_bit"] = True

    # Test Multiplication
    print_with_timestamp("Run multiplication test...")
    tx_hash = test_multiplication(soda_helper, 'Arythmetic2TestsContract.sol', a, b)
    print_tx_data(tx_hash, "multiplication", 'Arythmetic2TestsContract.sol', "mulTest")
    tx_hashes[tx_hash] = "multiplication"
    expected_results["multiplication"] = a*b

    # Test checked Multiplication
    print_with_timestamp("Run checked multiplication with overflow bit test...")
    tx_hash = test_checked_multiplication_with_overflow_bit(soda_helper, 'CheckedWithOverflowFuncs1TestsContract.sol', a, b)
    print_tx_data(tx_hash, "checked_multiplication_overflow_res", 'CheckedWithOverflowFuncs1TestsContract.sol', "checkedMulWithOverflowBitTest")
    tx_hashes[tx_hash] = "checked_multiplication_overflow_res"
    expected_results["checked_multiplication_overflow_res"] = a*b
    expected_results["checked_multiplication_overflow_bit"] = True if a*b < a else False

    # # Test Checked Multiplication that should overflow
    print_with_timestamp("Run overflow multiplication test ...")
    tx_hash = test_checked_multiplication_overflow(soda_helper, 'CheckedWithOverflowFuncs1TestsContract.sol', MAX_UINT_8, a, MAX_UINT_16, b, MAX_UINT_32, a, MAX_UINT_64, b, MAX_UINT_128, a, MAX_UINT_256, a)
    print_tx_data(tx_hash, "checked_multiplication_overflow", 'CheckedWithOverflowFuncs1TestsContract.sol', "checkedMulOverflowTest")
    tx_hashes[tx_hash] = "checked_multiplication_overflow"
    expected_results["checked_multiplication_overflow"] = True

    # Test Division
    print_with_timestamp("Run division test...")
    tx_hash = test_division(soda_helper, 'DivRemTestsContract.sol', a, b)
    print_tx_data(tx_hash, "division", 'DivRemTestsContract.sol', "divTest")
    tx_hashes[tx_hash] = "division"
    expected_results["division"] = a//b

    # Test Remainder
    print_with_timestamp("Run remainder test...")
    tx_hash = test_remainder(soda_helper, 'DivRemTestsContract.sol', a, b)
    print_tx_data(tx_hash, "reminder", 'DivRemTestsContract.sol', "remTest")
    tx_hashes[tx_hash] = "reminder"
    expected_results["reminder"] = a%b

    # Test Mux
    print_with_timestamp("Run mux test...")
    tx_hash = test_mux(soda_helper, 'MiscellaneousTestsContract.sol', bit, a, b)
    print_tx_data(tx_hash, "mux", 'MiscellaneousTestsContract.sol', "muxTest")
    tx_hashes[tx_hash] = "mux"
    expected_results["mux"] = a if bit == 0 else b

    # test Not
    print_with_timestamp("Run not test...")
    tx_hash = test_not(soda_helper, 'MiscellaneousTestsContract.sol', bit)
    print_tx_data(tx_hash, "not", 'MiscellaneousTestsContract.sol', "notTest")
    tx_hashes[tx_hash] = "not"
    expected_results["not"] = not bit

    # Test Bitwise AND
    print_with_timestamp("Run and test...")
    tx_hash = test_bitwise_and(soda_helper, 'BitwiseTestsContract.sol', a, b)
    print_tx_data(tx_hash, "and", 'BitwiseTestsContract.sol', "andTest")
    tx_hashes[tx_hash] = "and"
    expected_results["and"] = a & b

    # Test Bitwise OR
    print_with_timestamp("Run or test...")
    tx_hash = test_bitwise_or(soda_helper, 'BitwiseTestsContract.sol', a, b)
    print_tx_data(tx_hash, "or", 'BitwiseTestsContract.sol', "orTest")
    tx_hashes[tx_hash] = "or"
    expected_results["or"] = a | b

    # Test Bitwise XOR
    print_with_timestamp("Run xor test...")
    tx_hash = test_bitwise_xor(soda_helper, 'Bitwise2TestsContract.sol', a, b)
    print_tx_data(tx_hash, "xor", 'Bitwise2TestsContract.sol', "xorTest")
    tx_hashes[tx_hash] = "xor"
    expected_results["xor"] = a ^ b

    # Test Bitwise Shift Left
    print_with_timestamp("Run shift left test...")
    tx_hash = test_bitwise_shift_left(soda_helper, 'ShiftTestsContract.sol', a, shift) 
    print_tx_data(tx_hash, "shl", 'ShiftTestsContract.sol', "shlTest")
    tx_hashes[tx_hash] = "shl"
    # Calculate the result in 8, 16, 32, and 64 bit
    expected_results["shift_left8"] = (a << shift) & 0xFF
    expected_results["shift_left16"] = (a << shift) & 0xFFFF
    expected_results["shift_left32"] = (a << shift) & 0xFFFFFFFF
    expected_results["shift_left64"] = (a << shift) & 0xFFFFFFFFFFFFFFFF
    expected_results["shift_left128"] = (a << shift) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    expected_results["shift_left256"] = (a << shift) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

    # Test Bitwise Shift Right
    print_with_timestamp("Run shift right test...")
    tx_hash = test_bitwise_shift_right(soda_helper, 'ShiftTestsContract.sol', a, shift)
    print_tx_data(tx_hash, "shr", 'ShiftTestsContract.sol', "shrTest")
    tx_hashes[tx_hash] = "shr"
    expected_results["shift_right"] = a >> shift

    # Test Min
    print_with_timestamp("Run min test...")
    tx_hash = test_min(soda_helper, 'MinMaxTestsContract.sol', a, b)
    print_tx_data(tx_hash, "min", 'MinMaxTestsContract.sol', "minTest")
    tx_hashes[tx_hash] = "min"
    expected_results["min"] = min(a, b)

    # Test Max
    print_with_timestamp("Run max test...")
    tx_hash = test_max(soda_helper, 'MinMaxTestsContract.sol', a, b)
    print_tx_data(tx_hash, "max", 'MinMaxTestsContract.sol', "maxTest")
    tx_hashes[tx_hash] = "max"
    expected_results["max"] = max(a, b)

    # Test Equality
    print_with_timestamp("Run equality test...")
    tx_hash = test_eq(soda_helper, 'Comparison2TestsContract.sol', a, b)
    print_tx_data(tx_hash, "eq", 'Comparison2TestsContract.sol', "eqTest")
    tx_hashes[tx_hash] = "eq"
    expected_results["eq"] = (a == b)

    # Test Not Equal
    print_with_timestamp("Run not equal test...")
    tx_hash = test_ne(soda_helper, 'Comparison2TestsContract.sol', a, b)
    print_tx_data(tx_hash, "ne", 'Comparison2TestsContract.sol', "neTest")
    tx_hashes[tx_hash] = "ne"
    expected_results["ne"] = (a != b)

    # Test Greater Than or Equal
    print_with_timestamp("Run greater than or equal test...")
    tx_hash = test_ge(soda_helper, 'Comparison3TestsContract.sol', a, b)
    print_tx_data(tx_hash, "ge", 'Comparison3TestsContract.sol', "geTest")
    tx_hashes[tx_hash] = "ge"
    expected_results["ge"] = (a >= b)

    # Test Greater Than
    print_with_timestamp("Run greater than test...")
    tx_hash = test_gt(soda_helper, 'Comparison3TestsContract.sol', a, b)
    print_tx_data(tx_hash, "gt", 'Comparison3TestsContract.sol', "gtTest")
    tx_hashes[tx_hash] = "gt"
    expected_results["gt"] = (a > b)

    # Test Less Than or Equal
    print_with_timestamp("Run less than or equal test...")
    tx_hash = test_le(soda_helper, 'Comparison1TestsContract.sol', a, b)
    print_tx_data(tx_hash, "le", 'Comparison1TestsContract.sol', "leTest")
    tx_hashes[tx_hash] = "le"
    expected_results["le"] = (a <= b)

    # Test Less Than
    print_with_timestamp("Run less than test...")
    tx_hash = test_lt(soda_helper, 'Comparison1TestsContract.sol', a, b)
    print_tx_data(tx_hash, "lt", 'Comparison1TestsContract.sol', "ltTest")
    tx_hashes[tx_hash] = "lt"
    expected_results["lt"] = (a < b)

    # Test Transfer
    print_with_timestamp("Run transfer test...")
    tx_hash = test_transfer(soda_helper, 'TransferTestsContract.sol', a, b, b)
    print_tx_data(tx_hash, "transfer", 'TransferTestsContract.sol', "transferTest")
    tx_hashes[tx_hash] = "transfer"
    expected_results["transfer_a"] = a - b
    expected_results["transfer_b"] = b + b

    # Test Transfer 256
    print_with_timestamp("Run transfer 256test...")
    tx_hash = test_transfer(soda_helper, 'Transfer256TestsContract.sol', a, b, b)
    print_tx_data(tx_hash, "transfer_256", 'Transfer256TestsContract.sol', "transferTest")
    tx_hashes[tx_hash] = "transfer_256"
    
    # Test Transfer scalar
    print_with_timestamp("Run transfer scalar test...")
    tx_hash = test_transfer(soda_helper, 'TransferScalarTestsContract.sol', a, b, b)
    print_tx_data(tx_hash, "transfer_scalar", 'TransferScalarTestsContract.sol', "transferTest")
    tx_hashes[tx_hash] = "transfer_scalar"

    # Test Transfer with allowance
    print_with_timestamp("Run transfer with allowance test...")
    tx_hash = test_transfer_allowance(soda_helper, 'TransferAllowanceTestsContract.sol', a, b, b, allowance)
    print_tx_data(tx_hash, "transfer_allowance", 'TransferAllowanceTestsContract.sol', "transferWithAllowanceTest")
    tx_hashes[tx_hash] = "transfer_allowance"
    expected_results["transfer_allowance"] = allowance - b

    # Test Transfer with allowance 64 bit
    print_with_timestamp("Run transfer with allowance 64 bit test...")
    tx_hash = test_transfer_allowance(soda_helper, 'TransferAllowance64TestsContract.sol', a, b, b, allowance)
    print_tx_data(tx_hash, "transfer_allowance_64", 'TransferAllowance64TestsContract.sol', "transferWithAllowanceTest")
    tx_hashes[tx_hash] = "transfer_allowance_64"

    # Test Transfer with allowance 128 bit
    print_with_timestamp("Run transfer with allowance 128 bit test...")
    tx_hash = test_transfer_allowance(soda_helper, 'TransferAllowance128TestsContract.sol', a, b, b, allowance)
    print_tx_data(tx_hash, "transfer_allowance_128", 'TransferAllowance128TestsContract.sol', "transferWithAllowanceTest")
    tx_hashes[tx_hash] = "transfer_allowance_128"

    # Test Transfer with allowance 256 bit
    print_with_timestamp("Run transfer with allowance 256 bit test...")
    tx_hash = test_transfer_allowance(soda_helper, 'TransferAllowance256TestsContract.sol', a, b, b, allowance)
    print_tx_data(tx_hash, "transfer_allowance_256", 'TransferAllowance256TestsContract.sol', "transferWithAllowanceTest")
    tx_hashes[tx_hash] = "transfer_allowance_256"

    # Test Transfer with allowance scalar
    print_with_timestamp("Run transfer with allowance scalar test...")
    tx_hash = test_transfer_allowance(soda_helper, 'TransferAllowanceScalarTestsContract.sol', a, b, b, allowance)
    print_tx_data(tx_hash, "transfer_allowance_scalar", 'TransferAllowanceScalarTestsContract.sol', "transferWithAllowanceTest")
    tx_hashes[tx_hash] = "transfer_allowance_scalar"

    # Test Transfer with allowance scalar 128 bit size
    print_with_timestamp("Run transfer with allowance scalar 128 bit size test...")
    tx_hash = test_transfer_allowance(soda_helper, 'TransferAllowanceScalar128TestsContract.sol', a, b, b, allowance)
    print_tx_data(tx_hash, "transfer_allowance_scalar_128", 'TransferAllowanceScalar128TestsContract.sol', "transferWithAllowanceTest")
    tx_hashes[tx_hash] = "transfer_allowance_scalar_128"

    # Test Transfer with allowance scalar 256 bit size
    print_with_timestamp("Run transfer with allowance scalar 256 bit size test...")
    tx_hash = test_transfer_allowance(soda_helper, 'TransferAllowanceScalar256TestsContract.sol', a, b, b, allowance)
    print_tx_data(tx_hash, "transfer_allowance_scalar_256", 'TransferAllowanceScalar256TestsContract.sol', "transferWithAllowanceTest")
    tx_hashes[tx_hash] = "transfer_allowance_scalar_256"

    # Test boolean functions
    print_with_timestamp("Run Boolean functions test...")
    tx_hash = test_boolean(soda_helper, 'Miscellaneous1TestsContract.sol', bool_a, bool_b, bit)
    print_tx_data(tx_hash, "boolean", 'Miscellaneous1TestsContract.sol', "booleanTest")
    tx_hashes[tx_hash] = "boolean"
    expected_results["boolean_and"] = bool_a and bool_b
    expected_results["boolean_or"] = bool_a or bool_b
    expected_results["boolean_xor"] = bool_a ^ bool_b
    expected_results["boolean_not"] = not bool_a
    expected_results["boolean_equal"] = bool_a == bool_b
    expected_results["boolean_notEqual"] = bool_a != bool_b
    expected_results["boolean_mux"] = bool_b if bit else bool_a
    expected_results["boolean_onboard_offboard"] = bool_a

    # Test Validate Ciphertext
    print_with_timestamp("Run validate ciphertext test...")
    tx_hash = test_validate_ciphertext(soda_helper, signing_key, user_key, 'Miscellaneous1TestsContract.sol', a)
    print_tx_data(tx_hash, "validate_ciphertext", 'Miscellaneous1TestsContract.sol', "validateCiphertextTest")
    tx_hashes[tx_hash] = "validate_ciphertext"
    expected_results["validate_ciphertext"] = a

    # Test Validate Ciphertext with EIP191
    print_with_timestamp("Run validate ciphertext eip191 test...")
    tx_hash = test_validate_ciphertext_eip191(soda_helper, signing_key, user_key, 'Miscellaneous1TestsContract.sol', a)
    print_tx_data(tx_hash, "validate_ciphertext_eip191", 'Miscellaneous1TestsContract.sol', "validateCiphertextEip191Test")
    tx_hashes[tx_hash] = "validate_ciphertext_eip191"
    expected_results["validate_ciphertext_eip191"] = a

    # Test Validate Ciphertext 256
    print_with_timestamp("Run validate ciphertext 256 test...")
    tx_hash = test_validate_ciphertext_256(soda_helper, signing_key, user_key, 'Miscellaneous1TestsContract.sol', a)
    print_tx_data(tx_hash, "validate_ciphertext_256", 'Miscellaneous1TestsContract.sol', "validateCiphertext256Test")
    tx_hashes[tx_hash] = "validate_ciphertext_256"
    expected_results["validate_ciphertext_256"] = a
    
    # Test Validate Ciphertext 256 with EIP191
    print_with_timestamp("Run validate ciphertext 256 eip191 test...")
    tx_hash = test_validate_ciphertext_256_eip191(soda_helper, signing_key, user_key, 'Miscellaneous1TestsContract.sol', a)
    print_tx_data(tx_hash, "validate_ciphertext_256_eip191", 'Miscellaneous1TestsContract.sol', "validateCiphertext256Eip191Test")
    tx_hashes[tx_hash] = "validate_ciphertext_256_eip191"
    expected_results["validate_ciphertext_256_eip191"] = a

    # test random
    print_with_timestamp("Run random test...")
    tx_hash = test_random(soda_helper, 'Miscellaneous1TestsContract.sol')
    print_tx_data(tx_hash, "random", 'Miscellaneous1TestsContract.sol', "randomTest")
    tx_hashes[tx_hash] = "random"

    # test random bounded bits
    # print_with_timestamp("Run random Bounded Bits test...")
    # tx_hash = test_randomBoundedBits(soda_helper, 'Miscellaneous1TestsContract.sol', numBits)
    # print_tx_data(tx_hash, "random_bounded", 'Miscellaneous1TestsContract.sol', "randomBoundedTest")
    # tx_hashes[tx_hash] = "random_bounded"
    
    print_with_timestamp("Prepare handle for offboard...")
    tx_hash = prepare_offboard(soda_helper, 'MiscellaneousTestsContract.sol', a)
    print_tx_data(tx_hash, "offboard_handle", 'OffboardToUserKeyTestContract.sol', "offboardToUserHandle")
    tx_hashes[tx_hash] = "offboard"
    expected_results["offboard_handle"] = a
    
    if not check_results:
        return
    
    current_sleep_time = 0
    tx_receipts = set()
    print_with_timestamp(f"Wait for tests transaction receipts...")
    while len(tx_receipts) < len(tx_hashes) and current_sleep_time < MAX_SLEEP_TIME:
        for h, name in tx_hashes.items():
            if h in tx_receipts:
                continue
            try:
                r = soda_helper.web3.eth.get_transaction_receipt(h.hex())
                if r is not None:
                    if r.status == 0:
                        print_error_to_file(f'Transaction {name} reverted. receipt = {r}')
                        raise Exception(f'Transaction {name} reverted. receipt = {r}')
                tx_receipts.add(h)
                print(f"Got {len(tx_receipts)} out of {len(tx_hashes)} receipts")
            except TransactionNotFound as e:
                pass
        current_sleep_time += 1
        sleep(1)

    if len(tx_receipts) < len(tx_hashes):
        print_error_to_file(f'Not all transactions were mined after {MAX_SLEEP_TIME} seconds.')
        raise Exception(f'Not all transactions were mined after {MAX_SLEEP_TIME} seconds.')

    checkResults(soda_helper, signing_key, expected_results, grpc_client, user_key)

def reset_contract_states(soda_helper, contract_name, tx_hashes):
    global NONCE
    tx_hash = soda_helper.call_contract_transaction_async(contract_name, "resetStates", NONCE, func_args=[])
    tx_hashes[tx_hash] = contract_name
    NONCE += 1

def resetStates(soda_helper):
    tx_hashes = {}

    for file in SOLIDITY_FILES:
        reset_contract_states(soda_helper, file, tx_hashes)

    tx_receipts = set()
    current_sleep_time = 0
    print_with_timestamp(f"Wait for reset states transaction receipts...")
    while len(tx_receipts) < len(tx_hashes) and current_sleep_time < MAX_SLEEP_TIME:
        for h, name in tx_hashes.items():
            if h in tx_receipts:
                continue
            try:
                r = soda_helper.web3.eth.get_transaction_receipt(h.hex())
                if r is not None:
                    if r.status == 0:
                        print_error_to_file(f'Reset states {name} reverted.')
                        raise Exception(f'Reset states {name} reverted.')
                tx_receipts.add(h)
                print(f"Got {len(tx_receipts)} out of {len(tx_hashes)} receipts")
            except TransactionNotFound as e:
                pass
        current_sleep_time += 1
        sleep(1)

    if len(tx_receipts) < len(tx_hashes):
        print_error_to_file(f'Not all transactions were mined after {MAX_SLEEP_TIME} seconds.')
        raise Exception(f'Not all transactions were mined after {MAX_SLEEP_TIME} seconds.')



def main(provider_url: str, check_results: bool, user_interactor_url: str):

    print_with_timestamp("Running tests...")
    soda_helper, signing_key, client, channel, user_key = setup(provider_url, user_interactor_url)

    # Choose random values
    # a = random.randint(2, 15)
    # b = random.randint(1, a-1)
    # shift = random.randint(0, 7)
    # bit = random.randint(0, 1)
    # numBits = random.randint(0, 7)
    # bool_a = random.randint(0, 1)
    # bool_b = random.randint(0, 1)
    # allowance = random.randint(0, b)

    # boolean_bit = True if bit == 1 else False
    # boolean_bool_a = True if bool_a == 1 else False
    # boolean_bool_b = True if bool_b == 1 else False

    a = 10
    b = 5
    shift = 2
    boolean_bit = False
    numBits = 7
    boolean_bool_a = True
    boolean_bool_b = False
    allowance = 7

    print_with_timestamp(f"Test values: a: {a}, b: {b}, shift: {shift}, bit: {boolean_bit}, numBits: {numBits}, bool_a: {boolean_bool_a}, bool_b: {boolean_bool_b}, allowance: {allowance}")

    # Run the tests
    run_tests(soda_helper, signing_key, a, b, shift, boolean_bit, numBits, boolean_bool_a, boolean_bool_b, allowance, check_results, client, user_key)

    resetStates(soda_helper)

    channel.close()

def parse_url_parameter():
    parser = argparse.ArgumentParser(description='Get URL')
    parser.add_argument('provider_url', type=str, help='The provider url')
    parser.add_argument("--output_file", help="The output file to write the results to", default="mpc_test_output.txt")
    parser.add_argument("--check_results", help="Indicates whether to check the results", default="True")
    parser.add_argument("--user_interactor_url", help="The url of the user interactor", default="0.0.0.0:50060")

    args = parser.parse_args()
    print(f'Provider URL: {args.provider_url}')
    if args.check_results == "False":  
        check_results = False
    else:
        check_results = True
    print(f'Check results: {check_results}')


    global OUTPUT_FILE
    OUTPUT_FILE = f'logs/{args.output_file}'
    global transaction_log_file

    # Ensure logs directory exists
    os.makedirs('logs', exist_ok=True)

    match = re.search(r"(\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2})", args.output_file)

    if match:
        timestamp = match.group(1)
        transaction_log_file = f'logs/{timestamp}-transactions_log.txt'

    print(f'Output file: {OUTPUT_FILE}')    
    print(f'Transaction log file: {transaction_log_file}')

    if not args.provider_url:
        raise Exception("No URL provided")
    if args.provider_url == "Local":
        return LOCAL_PROVIDER_URL, check_results, args.user_interactor_url
    elif args.provider_url == "Remote":
        return REMOTE_HTTP_PROVIDER_URL, check_results, args.user_interactor_url
    else:
        return args.provider_url, check_results, args.user_interactor_url
    
if __name__ == "__main__":
    url, check_results, user_interactor_url = parse_url_parameter()
    if (url is not None):
        try:
            main(url, check_results, user_interactor_url)
        except Exception as e:
            logging.error("An error occurred: %s", e)
            raise e
