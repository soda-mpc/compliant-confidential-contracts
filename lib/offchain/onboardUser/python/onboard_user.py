import os
import grpc
from eth_account import Account
from eth_utils import to_bytes
import logging
from proto import userInteractor_pb2 as pb
from proto import userInteractor_pb2_grpc as pb_grpc
from soda_python_sdk import generate_rsa_keypair, decrypt_rsa, sign_eip191, verify_signatures
from lib.onchain.scripts.python.get_signers import get_signers_addresses

RSA_CIPHERTEXT_SIZE = 256  # 2048-bit RSA key size in bytes
NUM_EVALUATORS = 2

def onboard_user(client, signing_private_key):

	signers = get_signers_addresses()

	# Create RSA key pair
	rsa_private_key, rsa_public_key = generate_rsa_keypair()
	
	# Get the Ethereum address from private key
	account = Account.from_key(signing_private_key)
	user_address = to_bytes(hexstr=account.address)

	print(f"User address: {user_address.hex()}")

	message = rsa_public_key + user_address
	
	# Sign the rsa public key
	signature = sign_eip191(message, bytes.fromhex(signing_private_key[2:]))
	
	print(f"Onboarding user with address: {account.address}")
	
	# Call the gRPC service
	request = pb.OnboardUserRequest(
		rsa_public_key=rsa_public_key,
		address=user_address,
		user_signature=signature
	)
	response = client.OnboardUser(request)
	
	logging.info(f"OnboardUser returned {len(response.rsa_ciphertexts)} bytes")
	
	if len(response.rsa_ciphertexts) != 2 * RSA_CIPHERTEXT_SIZE:
		raise ValueError(f"Invalid response size: {len(response.rsa_ciphertexts)}")

	if len(response.mpc_signatures) != NUM_EVALUATORS:
		raise ValueError(f"Invalid number of signatures: {len(response.mpc_signatures)}")

    # Verify the signatures
	if not verify_signatures(response.rsa_ciphertexts, response.mpc_signatures, signers): # returns true if the signatures are valid, false otherwise
		raise ValueError(f"Signatures verification failed")
	
	# Split the response into two ciphers
	cipher0 = response.rsa_ciphertexts[:RSA_CIPHERTEXT_SIZE]
	cipher1 = response.rsa_ciphertexts[RSA_CIPHERTEXT_SIZE:]
	
	# Decrypt the ciphers
	share0 = decrypt_rsa(rsa_private_key, cipher0)
	share1 = decrypt_rsa(rsa_private_key, cipher1)
	
	# XOR the key shares to get the user AES key
	user_aes_key = bytes(a ^ b for a, b in zip(share0, share1))
	
	return user_aes_key

def updateUserKeyInFile(user_key):
	# Update or append USER_KEY in the .env file  
	env_path = '.env_user'  
	key_name = "export USER_KEY"  
	new_line = f"{key_name}='{user_key.hex()}'\n"  

	# Read existing content  
	if os.path.exists(env_path):  
		with open(env_path, 'r') as f:  
			lines = f.readlines()  
		
		# Check if key exists and update it  
		updated = False  
		for i, line in enumerate(lines):  
			if line.startswith(key_name):  
				lines[i] = new_line  
				updated = True  
				break  
		
		# Write back the file  
		with open(env_path, 'w') as f:  
			f.writelines(lines)  
			if not updated:  
				f.write(new_line)  
	else:  
		# Create new file  
		with open(env_path, 'w') as f:  
			f.write(new_line)  

def main():
	signing_key = os.environ.get('SIGNING_KEY')
	if not signing_key:
		raise ValueError("SIGNING_KEY environment variable not set")

	user_interactor_url = os.environ.get('USER_INTERACTOR_URL')
	if not user_interactor_url:
		raise ValueError("USER_INTERACTOR_URL environment variable not set")

	print(f"User interactor URL: {user_interactor_url}")

	# Create a gRPC channel
	channel = grpc.insecure_channel(user_interactor_url)
	client = pb_grpc.UserInteractorServiceStub(channel)

	try:
		print("onboarding user")
		# Create a grpc call for onboarding a user
		user_key = onboard_user(client, signing_key)

		# Write the user key to the .env file
		updateUserKeyInFile(user_key)
	finally:
		channel.close()

if __name__ == "__main__":
	main()
