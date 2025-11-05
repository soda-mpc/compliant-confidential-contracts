from eth_account import Account
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('env_file_name', help='Name of the env file')
args = parser.parse_args()

account = Account.create()

print("Account address: ", account.address)

# Clear the .env file and write the new signing key to the .env file
if args.env_file_name:
    with open(args.env_file_name, 'w') as f:
        f.write(f"export SIGNING_KEY='{account._private_key.hex()}'\n")
else:
    with open('.env', 'w') as f:
        f.write(f"export SIGNING_KEY='{account._private_key.hex()}'\n")