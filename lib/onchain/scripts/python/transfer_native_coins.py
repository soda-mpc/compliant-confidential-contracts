import os
from eth_account import Account
from lib.onchain.scripts.python.soda_web3_helper import SodaWeb3Helper, DEFAULT_GAS_PRICE, LOCAL_PROVIDER_URL, REMOTE_HTTP_PROVIDER_URL
import argparse
from web3.exceptions import TransactionNotFound, ContractLogicError

MAX_GAS_PRICE = 1000
INCREASE_PERCENT = 1.15

def transfer_to_account(sender_account_key, receiver_account, provider_url, amount_to_transfer=3000):
    print(f"Sender account key: {sender_account_key}")
    chain_id = os.environ.get('REMOTE_CHAIN_ID')
    print(f"Chain ID: {chain_id}")
    soda_helper = SodaWeb3Helper(sender_account_key, provider_url, chain_id=int(chain_id))
    sender_balance = soda_helper.get_native_currency_balance(soda_helper.account.address)
    original_receiver_balance = soda_helper.get_native_currency_balance(receiver_account.address)
    print(f"Balance of the sender account: {sender_balance}")
    if sender_balance is None:
        print("Failed to get the balance of the account")
    
    gas_price = DEFAULT_GAS_PRICE

    # Attempt the transaction
    while gas_price <= MAX_GAS_PRICE:
        try:
            soda_helper.transfer_native_currency(receiver_account.address, amount_to_transfer, gas_price=gas_price)
            print(f"Transaction successful with gas price: {gas_price} wei")
            break
        except (TransactionNotFound, ContractLogicError) as e:
            print(f"Transaction failed with gas price: {gas_price} wei. Error: {str(e)}")
            gas_price = int(gas_price * INCREASE_PERCENT)  # Increase gas price by 15%
        except Exception as e:
            if len(e.args) > 0 and 'replacement transaction underpriced' in str(e.args[0]):
                print(f"Transaction underpriced with gas price: {gas_price} wei. Retrying...")
                gas_price = int(gas_price * INCREASE_PERCENT)  # Increase gas price by 15%
            elif len(e.args) > 0 and 'is not in the chain after 120 seconds' in str(e.args[0]):
                print(f"Transaction is not in the chain after 120 seconds. Retrying...")
                gas_price = int(gas_price * INCREASE_PERCENT)  # Increase gas price by 15%
            else:
                print(f"Unexpected ValueError: {str(e)}")
                break
    else:
        print("Transaction failed after reaching the maximum gas price.")


    # We check the balance of the accounts after the transfer is complete
    receiver_balance = soda_helper.get_native_currency_balance(receiver_account.address)
    assert receiver_balance == original_receiver_balance + soda_helper.convert_sod_to_wei(amount_to_transfer)
    print(f"Balance of the receiver account: {receiver_balance}")
    

def main(sender_account_key, provider_url, amount_to_transfer=30):
    signing_key = os.environ.get('SIGNING_KEY')
    receiver_account = Account.from_key(signing_key)
    print(f"Receiver account address: {receiver_account.address}")
    transfer_to_account(sender_account_key, receiver_account, provider_url, amount_to_transfer)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('sender_account_key', type=str, help='The private key of the sender account')
    parser.add_argument('provider_url', type=str, help='The node url')
    parser.add_argument('--amount_to_transfer', type=int, default=30, help='The amount to transfer')
    args = parser.parse_args()
    print(f'Provider URL: {args.provider_url}')
    if not args.provider_url:
        raise ValueError("Please provide the provider url")
    if args.provider_url == "Local":
        main(args.sender_account_key, LOCAL_PROVIDER_URL)
    elif args.provider_url == "Remote":
        main(args.sender_account_key, REMOTE_HTTP_PROVIDER_URL)
    else:
        main(args.sender_account_key, args.provider_url, args.amount_to_transfer)
