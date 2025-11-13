import argparse
import os
import grpc
import logging

from web3 import Account
from proto import userInteractor_pb2 as pb
from proto import userInteractor_pb2_grpc as pb_grpc
from soda_python_sdk import sign, BLOCK_SIZE, verify_signatures, decrypt
from lib.onchain.scripts.python.get_signers import get_signers_addresses

NUM_EVALUATORS = 2

def get_encrypted_values(client, handles_to_encrypt, account, chain_id, signers):
    
    # Concatenate the handles to encrypt into a single bytes array
    handles_bytes = []
    handles_bytes_to_sign = bytes()
    for handle in handles_to_encrypt:
        if (isinstance(handle, int)):
            handle_bytes = handle.to_bytes(32, byteorder='big')
        else:
            handle_bytes = handle
        handles_bytes.append(handle_bytes)
        handles_bytes_to_sign += handle_bytes

    # Sign the handles
    signature = sign(handles_bytes_to_sign, account.key)

    # Call the gRPC service to get the encrypted balance of this handle
    request = pb.EncryptToUserRequest(
		handles=handles_bytes,
        chain_id=int(chain_id),
        user_signature=signature
	)
    response = client.EncryptToUser(request)
    
    logging.info(f"EncryptToUser returned {len(response.outputs)} bytes")

    if not response.outputs or not response.mpc_signatures:
        raise ValueError("Invalid response: outputs and mpc_signatures are required")
    
    if len(response.outputs) != len(handles_to_encrypt):
        raise ValueError(f"Invalid response size: {len(response.output)}, should be {len(handles_to_encrypt)}")

    for i in range(len(handles_to_encrypt)):
        if len(response.outputs[i]) != BLOCK_SIZE*4:
            raise ValueError(f"Invalid response size: {len(response.outputs[i])}, should be {BLOCK_SIZE*4}")

    if len(response.mpc_signatures) != NUM_EVALUATORS:
        raise ValueError(f"Invalid number of signatures: {len(response.mpc_signatures)}")

    if not validate_signatures(response.mpc_signatures, handles_bytes, response.outputs, signers):
        raise ValueError(f"Invalid signatures: {response.mpc_signatures}")

    return response.outputs 

def validate_signatures(signatures, handles_bytes, outputs_bytes, signers):
    # Validate that the number of handles and outputs is the same and not empty
    if (len(handles_bytes) != len(outputs_bytes)):
        raise ValueError("handles and outputs must have the same length")

    if len(handles_bytes) == 0:  
        raise ValueError("handles and outputs must be non-empty") 

    # Concatenate all handles and outputs into a single buffer for verification
    all_handles = bytes()
    for handle in handles_bytes:
        all_handles += handle

    all_outputs = bytes()
    for output in outputs_bytes:
        all_outputs += output

    # Create the message to verify
    message = all_handles + all_outputs

    # Verify the signatures
    if not verify_signatures(message, signatures, signers): # returns true if the signatures are valid, false otherwise
        print(f"Signatures verification failed")
        return False

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
    
    signers = get_signers_addresses()

    print("Encrypting value to user")
    # Create a grpc call for onboarding a user
    encrypted_values = get_encrypted_values(client, [int(handle)], account, chain_id, signers)
    encrypted_value = encrypted_values[0]

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
