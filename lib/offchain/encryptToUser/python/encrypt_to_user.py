import argparse
import os
import grpc
import logging

from web3 import Account
from core.proto import userInteractor_pb2 as pb
from core.proto import userInteractor_pb2_grpc as pb_grpc
import sys
sys.path.append('lib/soda-sdk')
from python.soda_python_sdk.crypto import sign, BLOCK_SIZE, verify_signature, decrypt, read_public_key_from_pem

NUM_EVALUATORS = 2

def get_encrypted_value(client, handle, account, chain_id, public_keys):
    
    handle_bytes = handle.to_bytes(32, byteorder='big')
    # Sign the handle
    signature = sign(handle_bytes, account.key)

    # Call the gRPC service to get the encrypted balance of this handle
    request = pb.EncryptToUserRequest(
		handle=handle_bytes,
        chain_id=int(chain_id),
        user_signature=signature
	)
    response = client.EncryptToUser(request)
    
    logging.info(f"EncryptToUser returned {len(response.output)} bytes")
    
    if len(response.output) != BLOCK_SIZE*4:
        raise ValueError(f"Invalid response size: {len(response.output)}")

    if len(response.mpc_signatures) != NUM_EVALUATORS:
        raise ValueError(f"Invalid number of signatures: {len(response.mpc_signatures)}")

    if not validate_signatures(response.mpc_signatures, handle_bytes, response.output, public_keys):
        raise ValueError(f"Invalid signatures: {response.mpc_signatures}")

    return response.output 

def validate_signatures(signatures, handle_bytes, output, public_keys): 
    evaluator_index = 0
    for signature in signatures:
        if not verify_signature(public_keys[evaluator_index], handle_bytes, output, signature):
            print(f"Verification failed for evaluator {evaluator_index}")
            return False
        evaluator_index += 1
    return True

def decrypt_value(ct_value, user_key):

    if len(ct_value) != BLOCK_SIZE*2 and len(ct_value) != BLOCK_SIZE*4:
        raise ValueError(f"Invalid ciphertext size: {len(ct_value)}")
    
    decrypted_message = None
    if len(ct_value) == BLOCK_SIZE*2:
        # Split ct into two 128-bit arrays r and cipher
        cipher = ct_value[:BLOCK_SIZE]
        r = ct_value[BLOCK_SIZE:2*BLOCK_SIZE]

        # Decrypt the cipher
        decrypted_message = decrypt(user_key, r, cipher)
    
    else:
        # Split ct into four 128-bit arrays rHigh, cipherHigh, rLow and cipherLow
        cipherHigh = ct_value[:BLOCK_SIZE]
        rHigh = ct_value[BLOCK_SIZE:2*BLOCK_SIZE]
        cipherLow = ct_value[2*BLOCK_SIZE:3*BLOCK_SIZE]
        rLow = ct_value[3*BLOCK_SIZE:4*BLOCK_SIZE]

        # Decrypt the cipher
        decrypted_message = decrypt(user_key, rHigh, cipherHigh, rLow, cipherLow)

    # Print the decrypted cipher
    decrypted_value = int.from_bytes(decrypted_message, 'big')

    return decrypted_value


def main(handle, to_decrypt):

    if handle is None:
        raise ValueError("Handle is required")

    if to_decrypt is None:
        to_decrypt = False

    signing_key = os.environ.get('SIGNING_KEY')
    if not signing_key:
        raise ValueError("SIGNING_KEY environment variable not set")
    
    account = Account.from_key(signing_key)
    
    chain_id = os.environ.get('REMOTE_CHAIN_ID')
    if not chain_id:
        raise ValueError("REMOTE_CHAIN_ID environment variable not set")

    user_interactor_url = os.environ.get('USER_INTERACTOR_URL')
    if not user_interactor_url:
        raise ValueError("USER_INTERACTOR_URL environment variable not set")

    # Create a gRPC channel
    channel = grpc.insecure_channel(user_interactor_url)
    client = pb_grpc.UserInteractorServiceStub(channel)
    

    public_keys_path = os.environ.get('PUBLIC_KEYS_PATH')
    public_keys = []
    public_keys.append(read_public_key_from_pem(public_keys_path + "evaluator0PublicKey.pem"))
    public_keys.append(read_public_key_from_pem(public_keys_path + "evaluator1PublicKey.pem"))

    print("Encrypting value to user")
    # Create a grpc call for onboarding a user
    encrypted_value = get_encrypted_value(client, int(handle), account, chain_id, public_keys)

    channel.close()

    if to_decrypt:
        print("Decrypting value")

        user_key_hex = os.environ.get('USER_KEY')
        if not user_key_hex:
            raise ValueError("USER_KEY environment variable not set")
        user_key = bytes.fromhex(user_key_hex)

        decrypted_value = decrypt_value(encrypted_value, user_key)
        print(f"Decrypted value: {decrypted_value}")
        
        return decrypted_value
    else:
        print(f"Encrypted value: {encrypted_value}")
        return encrypted_value

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--handle', help='Handle to encrypt')
    parser.add_argument('--decrypt', action='store_true', help='Decrypt the value')
    args = parser.parse_args()
    main(args.handle, args.decrypt)
