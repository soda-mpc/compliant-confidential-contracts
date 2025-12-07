import os
import json
import time
from web3.middleware import geth_poa_middleware
from eth_account import Account
from web3 import Web3
from web3.exceptions import TransactionNotFound
from solcx import compile_standard, install_solc, get_installed_solc_versions, set_solc_version
import argparse
from time import sleep
from eth_abi import encode
from eth_utils import keccak

LOCAL_PROVIDER_URL = 'http://localhost:7001'
REMOTE_HTTP_PROVIDER_URL = os.environ.get('REMOTE_RPC_URL')
SOLC_VERSION = '0.8.24'
DEFAULT_GAS_PRICE = 1
DEFAULT_GAS_LIMIT = 10000000
DEFAULT_CHAIN_ID = 50505050
MAX_SLEEP_TIME = 600
MAX_GAS_PRICE = 100
INCREASE_PERCENT = 1.15

MPC_INTERFACE_PATH = "lib/onchain/contracts/MpcInterface.sol"
MPC_CORE_PATH = "lib/onchain/contracts/MpcCore.sol"
CONTRACTS_ADDRESS_PATH = "contracts/"

def parse_url_parameter():
    parser = argparse.ArgumentParser(description='Get URL')
    parser.add_argument('provider_url', type=str, help='The provider url')
    args = parser.parse_args()
    
    if not args.provider_url:
        raise Exception("No URL provided")
    if args.provider_url == "Local":
        return LOCAL_PROVIDER_URL
    elif args.provider_url == "Remote":
        return REMOTE_HTTP_PROVIDER_URL
    else:
        return args.provider_url

class SodaWeb3Helper:
    def __init__(self, private_key_string, http_provider_url, chain_id=DEFAULT_CHAIN_ID):
        self.private_key = private_key_string
        self.account = Account.from_key(private_key_string)
        print(f'Account address is {self.account.address}')
        
        self.web3 = Web3(Web3.HTTPProvider(http_provider_url))
        self.web3.eth.default_account = self.account.address
        self.web3.middleware_onion.inject(geth_poa_middleware, layer=0) 
        if not self.web3.is_connected():
            raise Exception("Failed to connect to the node.")
        print(f'Connected to the node at {http_provider_url}')

        self.chain_id = chain_id
        print(f"Chain ID: {self.chain_id}")

        self.contracts = {}
        print('SodaWeb3Helper initialized')
        
    def setup_contract(self, contract_path, contract_id, overwrite=False, 
                       mpc_inst_path=MPC_INTERFACE_PATH, 
                       mpc_core_path=MPC_CORE_PATH, 
                       address_path=CONTRACTS_ADDRESS_PATH,
                       node_modules_path=""):
        
        if contract_id in self.contracts and not overwrite:
            raise Exception(f"Contract with id {contract_id} already exists. Use the 'overwrite' parameter to overwrite it.")
        
        print(f"Contract path: {contract_path}")
        try:
            contract_bytecode, contract_abi = compile_contract(contract_path, mpc_inst_path, mpc_core_path, address_path, node_modules_path)
        except Exception as e:
            raise Exception(f"Failed to compile the contract: {e}")
        
        self.contracts[contract_id] = self.web3.eth.contract(abi=contract_abi, bytecode=contract_bytecode)
        return True

    def get_contract(self, contract_id):
        if contract_id not in self.contracts:
            raise Exception(f"Contract with id {contract_id} does not exist. Use the 'setup_contract' method to set it up.")
        return self.contracts[contract_id]

    def get_contract_abi(self, contract_id):
        if contract_id not in self.contracts:
            raise Exception(f"Contract with id {contract_id} does not exist. Use the 'setup_contract' method to set it up.")
        return self.contracts[contract_id].abi

    def get_account(self):
        return self.account

    def estimate_deploy_gas(self, contract_id, constructor_args):
        if not constructor_args:
            return self.contracts[contract_id].constructor().estimate_gas({'from': self.account.address})
        else:
            return self.contracts[contract_id].constructor(*constructor_args).estimate_gas({'from': self.account.address})
    
    def deploy_contract(self, 
                        contract_id, 
                        gas_limit=None, 
                        gas_price=None, 
                        constructor_args=[],
                        account=None,
                        priority='low',
                        use_eip1559=False):

        if account is None:
            account = self.account

        # Use optimal gas estimation if not provided
        if gas_limit is None:
            gas_limit = self.estimate_optimal_gas_limit(contract_id, constructor_args)
        
        # Use optimal gas price if not provided
        if gas_price is None:
            gas_price = self.get_optimal_gas_price(priority)

        func_to_call = self.contracts[contract_id].constructor
        construct_txn = self._build_transaction(func_to_call, gas_limit, gas_price, constructor_args, account, use_eip1559=use_eip1559, priority=priority)
        receipt = self._sign_and_send_transaction(construct_txn, account)
        if receipt is not None:
            self.contracts[contract_id] = self.web3.eth.contract(
                address=receipt.contractAddress, 
                abi=self.contracts[contract_id].abi,
                bytecode=self.contracts[contract_id].bytecode)
            print(f"Contract deployed successfully at address: {receipt.contractAddress}. Gas used: {receipt.gasUsed}, Gas price: {gas_price} gwei")
        return receipt

    def deploy_multi_contracts(self, 
                        contracts_id, 
                        gas_limit=None, 
                        gas_price=None, 
                        constructor_args=[],
                        account=None,
                        priority='low',
                        use_eip1559=False):
        """
        This function deploys multiple contracts to the Ethereum blockchain with cost optimization.

        Args:
            contracts_id (list): List of contract identifiers to be deployed.
            gas_limit (int, optional): The maximum gas that can be used for transaction, defaults to estimated optimal.
            gas_price (int, optional): The price of gas in gwei for this transaction, defaults to optimal price.
            constructor_args (list, optional): Arguments for the contract constructor, defaults to an empty list.
            account (str, optional): The account from which to deploy the contracts, defaults to the current account.
            priority (str, optional): Priority level for gas pricing ('low', 'medium', 'high'), defaults to 'low'.
            use_eip1559 (bool, optional): Whether to use EIP-1559 gas pricing, defaults to False.

        Returns:
            list: A list of transaction receipts for the deployed contracts.
        """

        if account is None:
            account = self.account
        
        # Use optimal gas price if not provided
        if gas_price is None:
            gas_price = self.get_optimal_gas_price(priority)
            print(f"Using optimal gas price: {gas_price} gwei")
        
        tx_hashes = []
        nonce = self.web3.eth.get_transaction_count(account.address)
        
        for contract_id in contracts_id:
            func_to_call = self.contracts[contract_id].constructor
            
            # Use optimal gas estimation if not provided
            current_gas_limit = gas_limit
            if current_gas_limit is None:
                current_gas_limit = self.estimate_optimal_gas_limit(contract_id, constructor_args)
                print(f"Estimated gas limit for {contract_id}: {current_gas_limit}")
            
            current_gas_price = gas_price
            # Attempt the transaction with gas price optimization
            while current_gas_price <= MAX_GAS_PRICE:
                try:
                    construct_txn = self._build_transaction(func_to_call, current_gas_limit, current_gas_price, constructor_args, account, nonce, use_eip1559=use_eip1559, priority=priority)
                    tx_hashes.append(self._sign_and_send_transaction(construct_txn, account, is_async=True))
                    nonce += 1
                    print(f"Deployment transaction sent for {contract_id} with gas price: {current_gas_price} gwei")
                    break
                except Exception as e:
                    print(f"Transaction failed with gas price: {current_gas_price} gwei. Error: {str(e)}. Retrying...")
                    current_gas_price = int(current_gas_price * INCREASE_PERCENT)  # Increase gas price by 15%
            else:
                print(f"Transaction failed after reaching the maximum gas price for {contract_id}.")

            
        if any([h is None for h in tx_hashes]):
            raise Exception("Failed to deploy contracts.")

        tx_receipts = [None]*len(tx_hashes)
        print(f"Wait for transaction receipts...")
                    
        current_sleep_time = 0
        # Wait for transaction receipts for all contracts hashes
        while not all(tx_receipts) and current_sleep_time < MAX_SLEEP_TIME:
            for i, tx_hash in enumerate(tx_hashes):
                if tx_receipts[i] is not None:
                    continue
                try:
                    tx_receipts[i] = self.web3.eth.get_transaction_receipt(tx_hash.hex())
                    # print the number of receipts we got
                    print(f"Got receipt {i+1} out of {len(tx_hashes)}")
                    if tx_receipts[i].status == 0:
                        print("Deploy contract failed, receipt = ", tx_receipts[i])
                        raise Exception(f"Deploy contract failed, receipt = {tx_receipts[i]}")
                except TransactionNotFound as e:
                    pass
            current_sleep_time += 1
            sleep(1)

        if current_sleep_time == MAX_SLEEP_TIME and not all(tx_receipts):
            raise Exception("Failed to get transaction receipts.")

        for i, contract_id in enumerate(contracts_id):
            print(f"Contract {contract_id} deployed at address: {tx_receipts[i].contractAddress}")
            print(f"Gas used: {tx_receipts[i].gasUsed}, Gas price: {gas_price} gwei")
            self.contracts[contract_id] = self.web3.eth.contract(
                address=tx_receipts[i].contractAddress, 
                abi=self.contracts[contract_id].abi,
                bytecode=self.contracts[contract_id].bytecode)
        return tx_receipts

    def set_contract_address(self, contract_id, contract_address):

        if contract_id not in self.contracts:
            raise Exception(f"Contract with id {contract_id} does not exist. Use the 'setup_contract' method to set it up.")
        
        self.contracts[contract_id] = self.web3.eth.contract(
                                      address=contract_address, 
                                      abi=self.contracts[contract_id].abi,
                                      bytecode=self.contracts[contract_id].bytecode)


    def get_contract_address(self, contract_id):
        if contract_id not in self.contracts:
            raise Exception(f"Contract with id {contract_id} does not exist. Use the 'setup_contract' method to set it up.")
        return self.contracts[contract_id].address

    def initialize_proxy(self, 
                     implementation_contract_id,
                     proxy_contract_id,
                     initializer_name='initialize',
                     initializer_args=[],
                     gas_limit=None,
                     gas_price=None,
                     account=None,
                     priority='low',
                     use_eip1559=False):
        """
        Deploy a UUPS proxy using OpenZeppelin's pattern and initialize it.
        
        This method:
        1. Deploys an ERC1967Proxy that points to the implementation
        2. Sets the address of the proxy contract in the SodaWeb3Helper object
        3. Calls initialize() on the proxy during deployment
        
        Args:
            contract_id: The contract identifier (implementation must be set up first)
            initializer_name: Name of the initializer function (default: 'initialize')
            initializer_args: Arguments for the initializer function
            gas_limit: Gas limit for the transaction
            gas_price: Gas price in gwei
            account: Account to deploy from
            priority: Priority level for gas pricing
            use_eip1559: Whether to use EIP-1559 gas pricing
            
        Returns:
            Proxy address
        """
        if account is None:
            account = self.account
        
        if implementation_contract_id not in self.contracts:
            raise Exception(f"Contract {implementation_contract_id} not found. Use setup_contract first to set up the implementation.")
        
        # Step 1: Compile ERC1967Proxy contract
        try:
            current_dir = os.path.dirname(os.path.abspath(__file__))
            # Go up from: bubble/lib/onchain/scripts/python -> bubble/
            project_root = os.path.abspath(os.path.join(current_dir, '../../../..'))
            node_modules_path = os.path.join(project_root, 'node_modules')
            
            if not os.path.exists(node_modules_path):
                raise Exception(f"node_modules not found at {node_modules_path}")
            
            erc1967_proxy_path = os.path.join(node_modules_path, '@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol')
            if not os.path.exists(erc1967_proxy_path):
                raise Exception(f"ERC1967Proxy.sol not found at {erc1967_proxy_path}")
            self.setup_contract(erc1967_proxy_path, proxy_contract_id, overwrite=True, mpc_inst_path="", mpc_core_path="", address_path="", node_modules_path=node_modules_path)
        except Exception as e:
            raise Exception(f"Failed to compile ERC1967Proxy: {e}")
        
        # Step 2: Encode the initialize function call
        implementation_contract = self.contracts[implementation_contract_id]
        if not hasattr(implementation_contract.functions, initializer_name):
            raise Exception(f"Initializer function '{initializer_name}' not found in contract {implementation_contract_id}")
        
        try:
            init_func = getattr(implementation_contract.functions, initializer_name)
            call_data = init_func(*initializer_args).encodeABI()
        except Exception as e:
            # Fallback: manually encode
            func_abi = None
            for item in implementation_contract.abi:
                if item.get('type') == 'function' and item.get('name') == initializer_name:
                    func_abi = item
                    break
            
            if func_abi is None:
                raise Exception(f"Could not find {initializer_name} in ABI")
            
            input_types = [inp['type'] for inp in func_abi['inputs']]
            func_sig = f"{initializer_name}({','.join(input_types)})"
            selector = keccak(text=func_sig)[:4]
            
            if initializer_args:
                encoded_args = encode(input_types, initializer_args)
            else:
                encoded_args = b''
            
            call_data = selector + encoded_args
        
        # Convert call_data to bytes if needed
        if isinstance(call_data, str):
            if call_data.startswith('0x'):
                call_data = bytes.fromhex(call_data[2:])
            else:
                call_data = bytes.fromhex(call_data)
        elif not isinstance(call_data, bytes):
            call_data = bytes(call_data)
        
        # Step 3: Deploy ERC1967Proxy with implementation address and call_data
        proxy_contract = self.contracts[proxy_contract_id]
        # ERC1967Proxy constructor: constructor(address implementation, bytes memory _data)
        constructor_args = [self.get_contract_address(implementation_contract_id), call_data]
        
        # Estimate gas
        if gas_limit is None:
            try:
                construct_txn = proxy_contract.constructor(*constructor_args).build_transaction({
                    'from': account.address,
                    'nonce': self.web3.eth.get_transaction_count(account.address),
                })
                gas_limit = self.web3.eth.estimate_gas(construct_txn)
            except Exception as e:
                print(f"Gas estimation failed: {e}, using default")
                gas_limit = DEFAULT_GAS_LIMIT
        
        if gas_price is None:
            gas_price = self.get_optimal_gas_price(priority)
        
        # Build and send transaction
        construct_txn = self._build_transaction(
            proxy_contract.constructor,
            gas_limit,
            gas_price,
            constructor_args,
            account,
            use_eip1559=use_eip1559,
            priority=priority
        )
        
        proxy_receipt = self._sign_and_send_transaction(construct_txn, account)
        
        if proxy_receipt is None or proxy_receipt.status != 1:
            raise Exception(f"Failed to deploy proxy. Receipt: {proxy_receipt}")
        
        proxy_address = proxy_receipt.contractAddress
        
        # Step 5: Set up the proxy contract instance with implementation ABI
        self.contracts[proxy_contract_id] = self.web3.eth.contract(
            address=proxy_address,
            abi=implementation_contract.abi,
            bytecode=implementation_contract.bytecode
        )
        
        print(f"Proxy deployment complete. Proxy address: {proxy_address}, Implementation: {implementation_contract_id}")
        return proxy_address

    def setup_existing_proxy(self, proxy_contract_id, proxy_address, implementation_contract_id):
        """Setup an existing proxy contract.
        Args:
            proxy_address: The address of the proxy contract
            proxy_contract_id: The contract ID of the proxy contract
            implementation_contract_id: The contract ID of the implementation contract
            account: The account to use for the transaction
        """
        # Set up the implementation contract 
        implementation_contract = self.contracts[implementation_contract_id]
        
        # Set up the proxy contract with the implementation's ABI
        # The proxy delegates all calls to the implementation, so we use the implementation's ABI
        self.contracts[proxy_contract_id] = self.web3.eth.contract(
            address=proxy_address,
            abi=implementation_contract.abi,
            bytecode=implementation_contract.bytecode
        )
        print(f"Proxy contract {proxy_contract_id} setup successfully")
    
    def upgrade_proxy(self, contract_id, new_implementation_address, gas_limit=None, gas_price=None, account=None, priority='low', use_eip1559=False):

        if account is None:
            account = self.account

        if contract_id not in self.contracts:
            raise Exception(f"Contract with id {contract_id} does not exist. Use the 'setup_contract' method to set it up.")

        # Check if contract has an address set
        proxy_contract = self.contracts[contract_id]
        if not hasattr(proxy_contract, 'address') or proxy_contract.address is None:
            raise Exception(f"Contract {contract_id} does not have an address set. Make sure the proxy was deployed and the address is set.")

        # Get the upgrade function
        try:
            func_to_call = getattr(proxy_contract.functions, 'upgradeToAndCall')
            # upgradeToAndCall(address newImplementation, bytes memory data)
            # Pass empty bytes for data to match upgradeTo behavior
            upgrade_args = [new_implementation_address, b'']
        except AttributeError:
            # Check the ABI directly to see what functions are available
            abi = proxy_contract.abi
            available_functions = [item.get('name') for item in abi if item.get('type') == 'function']
            raise Exception(
                f"Contract {contract_id} ABI does not include 'upgradeTo' or 'upgradeToAndCall' function. "
                f"The proxy contract must have the UUPSUpgradeable interface. "
                f"Available functions: {available_functions}. "
                f"Make sure the proxy contract (EmptyUUPSProxy) was set up correctly with its ABI. "
                f"The proxy should be deployed with EmptyUUPSProxy.sol which inherits from UUPSUpgradeable."
            )

        # Use optimal gas estimation if not provided
        if gas_limit is None:
            try:
                # Estimate gas directly using the function object
                estimated_gas = func_to_call(*upgrade_args).estimate_gas({'from': account.address})
                gas_limit = int(estimated_gas * 1.1)  # Add 10% buffer for safety
            except Exception as e:
                print(f"Failed to estimate gas: {e}, using default")
                gas_limit = DEFAULT_GAS_LIMIT
        
        # Use optimal gas price if not provided
        if gas_price is None:
            gas_price = self.get_optimal_gas_price(priority)

        construct_txn = self._build_transaction(func_to_call, gas_limit, gas_price, upgrade_args, account, use_eip1559=use_eip1559, priority=priority)
        receipt = self._sign_and_send_transaction(construct_txn, account)
        if receipt is not None and receipt.status == 1:
            # Get the implementation contract ABI and bytecode
            implementation_id = contract_id + "Implementation"
            if implementation_id not in self.contracts:
                raise Exception(f"Implementation contract '{implementation_id}' not found. Make sure to deploy the implementation contract first using setup_contract.")
            
            # Update the proxy contract instance with the new implementation's ABI
            # The proxy address stays the same, but the ABI reflects the new implementation
            self.contracts[contract_id] = self.web3.eth.contract(
                address=self.contracts[contract_id].address,
                abi=self.contracts[implementation_id].abi,
                bytecode=self.contracts[implementation_id].bytecode)
            print(f"Proxy upgraded successfully. Gas used: {receipt.gasUsed}, Gas price: {gas_price} gwei")
        else:
            print(f"Receipt: {receipt}")
            raise Exception(f"Failed to upgrade proxy.")
        return receipt
    
    
    def call_contract_view(self, contract_id, func_name, func_args=[]):
        if contract_id not in self.contracts:
            raise Exception(f"Contract with id {contract_id} does not exist. Use the 'setup_contract' method to set it up.")
        
        contract = self.contracts[contract_id]
        func = getattr(contract.functions, func_name)
        return func(*func_args).call()

    def get_current_nonce(self, account=None):
        if account is None:
            account = self.account
            
        return self.web3.eth.get_transaction_count(account.address)
    
    def get_pending_nonce(self, account=None):
        """Get the nonce including pending transactions"""
        if account is None:
            account = self.account
            
        # Get the latest nonce including pending transactions
        return self.web3.eth.get_transaction_count(account.address, 'pending')
    
    def wait_for_nonce_confirmation(self, account=None, timeout=60):
        """Wait for the current nonce to be confirmed before proceeding"""
        if account is None:
            account = self.account
        
        current_nonce = self.get_current_nonce(account)
        pending_nonce = self.get_pending_nonce(account)
    
        if pending_nonce > current_nonce:
            print(f"Waiting for {pending_nonce - current_nonce} pending transactions to be confirmed...")
            start_time = time.time()
            while time.time() - start_time < timeout:
                if self.get_current_nonce(account) >= pending_nonce:
                    print("All pending transactions confirmed")
                    return True
                time.sleep(2)
            else:
                raise Exception(f"Timeout waiting for nonce confirmation after {timeout} seconds")
        else:
            return True
    
    def estimate_gas(self, 
                    contract_id, 
                    func_name, 
                    func_args=[], 
                    account=None):
        if account is None:
            account = self.account

        if contract_id not in self.contracts:
            raise Exception(f"Contract with id {contract_id} does not exist. Use the 'setup_contract' method to set it up.")

        try:
            if not hasattr(self.contracts[contract_id].functions, func_name):  
                raise Exception(f"Function {func_name} does not exist in contract {contract_id}.")  
            func_to_call = getattr(self.contracts[contract_id].functions, func_name)  
            return func_to_call(*func_args).estimate_gas({
                'from': account.address,
            })  
        except Exception as e:
            raise Exception(f"Error estimating gas: {e}")
    
    def call_contract_transaction(self, 
                                  contract_id, 
                                  func_name, 
                                  gas_limit=None, 
                                  gas_price=None, 
                                  func_args=[], 
                                  account=None,
                                  priority='low',
                                  use_eip1559=False):
        if account is None:
            account = self.account

        if contract_id not in self.contracts:
            raise Exception(f"Contract with id {contract_id} does not exist. Use the 'setup_contract' method to set it up.")
        
        # Wait for any pending transactions to be confirmed
        self.wait_for_nonce_confirmation(account)
        
        # Use optimal gas estimation if not provided
        if gas_limit is None:
            try:
                estimated_gas = self.estimate_gas(contract_id, func_name, func_args, account)
                gas_limit = int(estimated_gas * 1.1)  # Add 10% buffer for safety
            except Exception as e:
                print(f"Failed to estimate gas: {e}, using default")
                gas_limit = DEFAULT_GAS_LIMIT
        
        # Use optimal gas price if not provided
        if gas_price is None:
            gas_price = self.get_optimal_gas_price(priority)
        
        func_to_call = getattr(self.contracts[contract_id].functions, func_name)
        transaction = self._build_transaction(func_to_call, gas_limit, gas_price, func_args, account, use_eip1559=use_eip1559, priority=priority)
        
        receipt = self._sign_and_send_transaction(transaction, account)
        if receipt is not None:
            print(f"Transaction successful. Gas used: {receipt.gasUsed}, Gas price: {gas_price} gwei")
            # Add a small delay to prevent nonce conflicts
            time.sleep(1)
        return receipt

    def call_contract_transaction_async(self, 
                                  contract_id, 
                                  func_name, 
                                  nonce,
                                  gas_limit=DEFAULT_GAS_LIMIT, 
                                  gas_price=DEFAULT_GAS_PRICE, 
                                  func_args=[], 
                                  account=None,
                                  use_eip1559=False,
                                  priority='low'):
        if account is None:
            account = self.account

        if contract_id not in self.contracts:
            raise Exception(f"Contract with id {contract_id} does not exist. Use the 'setup_contract' method to set it up.")

         
        func_to_call = getattr(self.contracts[contract_id].functions, func_name)
        transaction = self._build_transaction(func_to_call, gas_limit, gas_price, func_args, account, nonce, use_eip1559=use_eip1559, priority=priority)
        
        return self._sign_and_send_transaction(transaction, account, is_async=True)

    def call_contract_function_transaction(self, 
                                  contract_id, 
                                  func, 
                                  gas_limit=DEFAULT_GAS_LIMIT, 
                                  gas_price=DEFAULT_GAS_PRICE, 
                                  account=None,
                                  use_eip1559=False,
                                  priority='low'):
        if account is None:
            account = self.account
        
        if contract_id not in self.contracts:
            raise Exception(f"Contract with id {contract_id} does not exist. Use the 'setup_contract' method to set it up.")
        
        # transaction = self._build_function_transaction(func, func.estimate_gas({'from': self.account.address}), gas_price, chain_id, account)
        transaction = self._build_function_transaction(func, gas_limit, gas_price, account, use_eip1559=use_eip1559, priority=priority)
        
        return self._sign_and_send_transaction(transaction, account)

    def call_contract_function_transaction_async(self, 
                                  contract_id, 
                                  func, 
                                  nonce, 
                                  gas_limit=DEFAULT_GAS_LIMIT, 
                                  gas_price=DEFAULT_GAS_PRICE, 
                                  account=None,
                                  use_eip1559=False,
                                  priority='low'):
        if account is None:
            account = self.account
        
        if contract_id not in self.contracts:
            raise Exception(f"Contract with id {contract_id} does not exist. Use the 'setup_contract' method to set it up.")
        
        transaction = self._build_function_transaction(func, gas_limit, gas_price, account, nonce, use_eip1559=use_eip1559, priority=priority)
        
        return self._sign_and_send_transaction(transaction, account, is_async=True)
    
    def generate_random_account(self):
        return Account.create()
    
    def get_native_currency_balance(self, address):
        if not self.validate_address(address)['valid']:
            raise Exception(f"Invalid address: {address}")
        
        return self.web3.eth.get_balance(address)
    
    def validate_address(self, address):
        return {'valid': Web3.is_address(address), 'safe': Web3.to_checksum_address(address)}  
    
    def transfer_native_currency(self, 
                                 to_address, 
                                 amount, 
                                 gas_limit=21000, 
                                 gas_price=None, 
                                 account=None,
                                 priority='low'):

        if account is None:
            account = self.account
        
        if not self.validate_address(to_address)['safe']:
            raise Exception(f"Invalid address: {to_address}")
        
        # Use optimal gas price if not provided
        if gas_price is None:
            gas_price = self.get_optimal_gas_price(priority)
            print(f"Optimal gas price for transfer: {gas_price} gwei")
        
        transaction = {
            'to': to_address,
            'value': self.web3.to_wei(amount, 'ether'),
            'gas': gas_limit,
            'gasPrice': self.web3.to_wei(gas_price, 'gwei'),
            'nonce': self.web3.eth.get_transaction_count(account.address),
            'chainId': self.chain_id
        }
        receipt = self._sign_and_send_transaction(transaction, account)
        if receipt is not None:
            print(f"Transfer successful. Gas used: {receipt.gasUsed}, Gas price: {gas_price} gwei")
        return receipt
    
    def convert_sod_to_wei(self, amount):
        return self.web3.to_wei(amount, 'ether')
    
    def convert_gwei_to_wei(self, amount):
        return self.web3.to_wei(amount, 'gwei')
    
    def wei_to_sod(self, amount):
        return self.web3.from_wei(amount, 'ether')
    
    def _build_transaction(self, func, gas, gas_price, tx_args=[], account=None, nonce=None, use_eip1559=False, priority='low'):
        if account is None:
            account = self.account

        if nonce is None:
            nonce = self.web3.eth.get_transaction_count(account.address)

        # Build transaction parameters
        tx_params = {
            'from': account.address,
            'chainId': self.chain_id,
            'nonce': nonce,
            'gas': gas,
        }
        
        # Use EIP-1559 gas pricing if requested and supported
        if use_eip1559:
            try:
                eip1559_params = self.get_optimal_eip1559_gas_params(priority)
                if 'maxFeePerGas' in eip1559_params and 'maxPriorityFeePerGas' in eip1559_params:
                    tx_params['maxFeePerGas'] = eip1559_params['maxFeePerGas']
                    tx_params['maxPriorityFeePerGas'] = eip1559_params['maxPriorityFeePerGas']
                    print(f"Using EIP-1559 gas pricing: maxFeePerGas={self.web3.from_wei(eip1559_params['maxFeePerGas'], 'gwei')} gwei, maxPriorityFeePerGas={self.web3.from_wei(eip1559_params['maxPriorityFeePerGas'], 'gwei')} gwei")
                else:
                    # Fallback to legacy gas pricing
                    tx_params['gasPrice'] = eip1559_params['gasPrice']
                    print(f"EIP-1559 not supported, using legacy gas pricing: {self.web3.from_wei(eip1559_params['gasPrice'], 'gwei')} gwei")
            except Exception as e:
                print(f"Failed to get EIP-1559 gas params: {e}, falling back to legacy pricing")
                tx_params['gasPrice'] = self.web3.to_wei(gas_price, 'gwei')
        else:
            # Use legacy gas pricing
            tx_params['gasPrice'] = self.web3.to_wei(gas_price, 'gwei')

        return func(*tx_args).build_transaction(tx_params)
    
    def _build_function_transaction(self, func, gas, gas_price, account=None, nonce=None, use_eip1559=False, priority='low'):
        if account is None:
            account = self.account

        if nonce is None:
            nonce = self.web3.eth.get_transaction_count(account.address)

        # Build transaction parameters
        tx_params = {
            'from': account.address,
            'chainId': self.chain_id,
            'nonce': nonce,
            'gas': gas,
        }
        
        # Use EIP-1559 gas pricing if requested and supported
        if use_eip1559:
            try:
                eip1559_params = self.get_optimal_eip1559_gas_params(priority)
                if 'maxFeePerGas' in eip1559_params and 'maxPriorityFeePerGas' in eip1559_params:
                    tx_params['maxFeePerGas'] = eip1559_params['maxFeePerGas']
                    tx_params['maxPriorityFeePerGas'] = eip1559_params['maxPriorityFeePerGas']
                    print(f"Using EIP-1559 gas pricing: maxFeePerGas={self.web3.from_wei(eip1559_params['maxFeePerGas'], 'gwei')} gwei, maxPriorityFeePerGas={self.web3.from_wei(eip1559_params['maxPriorityFeePerGas'], 'gwei')} gwei")
                else:
                    # Fallback to legacy gas pricing
                    tx_params['gasPrice'] = eip1559_params['gasPrice']
                    print(f"EIP-1559 not supported, using legacy gas pricing: {self.web3.from_wei(eip1559_params['gasPrice'], 'gwei')} gwei")
            except Exception as e:
                print(f"Failed to get EIP-1559 gas params: {e}, falling back to legacy pricing")
                tx_params['gasPrice'] = self.web3.to_wei(gas_price, 'gwei')
        else:
            # Use legacy gas pricing
            tx_params['gasPrice'] = self.web3.to_wei(gas_price, 'gwei')

        return func.build_transaction(tx_params)
    
    def _sign_and_send_transaction(self, transaction, account, is_async=False):
        if account is None:
            account = self.account
        
        # Add retry logic for replacement transaction underpriced errors
        max_retries = 3
        retry_count = 0
        current_transaction = transaction.copy()  # Create a copy to avoid modifying original
    
        while retry_count < max_retries:
            try:
                signed_txn = self.web3.eth.account.sign_transaction(current_transaction, account._private_key)
            except Exception as e:
                raise Exception(f"Failed to sign the transaction: {e}")

            try:
                tx_hash = self.web3.eth.send_raw_transaction(signed_txn.rawTransaction)
                break  # Success, exit retry loop
            except Exception as e:
                error_str = str(e)
                if 'replacement transaction underpriced' in error_str and retry_count < max_retries - 1:
                    # Increase gas price and retry
                    current_gas_price = current_transaction.get('gasPrice', 0)
                    new_gas_price = int(current_gas_price * 1.2)  # Increase by 20%
                    current_transaction['gasPrice'] = new_gas_price
                    print(f"Retrying with higher gas price: {self.web3.from_wei(new_gas_price, 'gwei')} gwei")
                    retry_count += 1
                    continue
                else:
                    raise Exception(f"Failed to send the transaction: {e}")
        
        if is_async:
            return tx_hash
        
        try:
            tx_receipt = self.web3.eth.wait_for_transaction_receipt(tx_hash)
        except Exception as e:
            raise Exception(f"Failed to wait for the transaction receipt: {e}")

        return tx_receipt
    
    def send_signed_tx(self, raw_tx):
        try:
            return self.web3.eth.send_raw_transaction(raw_tx)
        except Exception as e:
            raise Exception(f"Failed to send the transaction: {e}")

    def get_block(self):
        return self.web3.eth.get_block('latest', full_transactions=False)
    
    def get_current_gas_price(self):
        """Get the current gas price from the network"""
        try:
            return self.web3.eth.gas_price
        except Exception as e:
            print(f"Failed to get current gas price: {e}, using default")
            return self.web3.to_wei(DEFAULT_GAS_PRICE, 'gwei')
    
    def get_eip1559_fee_history(self):
        """Get EIP-1559 fee history for optimal gas pricing"""
        try:
            # Get the latest block number
            latest_block = self.web3.eth.block_number
            
            # Get fee history for the last 4 blocks
            fee_history = self.web3.eth.fee_history(4, latest_block, [25, 75])
            
            # Calculate base fee for the next block (estimate)
            base_fee_per_gas = fee_history['baseFeePerGas'][-1]
            
            # Get priority fees (tip) from recent blocks
            priority_fees = []
            for i in range(len(fee_history['reward'])):
                if fee_history['reward'][i]:
                    priority_fees.extend(fee_history['reward'][i])
            
            # Calculate median priority fee
            if priority_fees:
                priority_fees.sort()
                median_priority_fee = priority_fees[len(priority_fees) // 2]
            else:
                median_priority_fee = self.web3.to_wei(1.5, 'gwei')  # Default tip
            
            return {
                'baseFeePerGas': base_fee_per_gas,
                'medianPriorityFee': median_priority_fee,
                'feeHistory': fee_history
            }
        except Exception as e:
            print(f"Failed to get EIP-1559 fee history: {e}, using fallback")
            # Fallback to legacy gas pricing
            current_gas_price = self.get_current_gas_price()
            return {
                'baseFeePerGas': current_gas_price,
                'medianPriorityFee': self.web3.to_wei(1.5, 'gwei'),
                'feeHistory': None
            }
    
    def get_optimal_eip1559_gas_params(self, priority='low'):
        """Get optimal EIP-1559 gas parameters (maxFeePerGas and maxPriorityFeePerGas)"""
        try:
            fee_data = self.get_eip1559_fee_history()
            base_fee = fee_data['baseFeePerGas']
            median_priority_fee = fee_data['medianPriorityFee']
            
            # Convert to gwei for easier calculations
            base_fee_gwei = float(self.web3.from_wei(base_fee, 'gwei'))
            median_priority_fee_gwei = float(self.web3.from_wei(median_priority_fee, 'gwei'))
            
            # Calculate max priority fee (tip) based on priority
            if priority == 'low':
                max_priority_fee_gwei = median_priority_fee_gwei * 0.8
            elif priority == 'medium':
                max_priority_fee_gwei = median_priority_fee_gwei
            else:  # high priority
                max_priority_fee_gwei = median_priority_fee_gwei * 1.5
            
            # Calculate max fee per gas
            # maxFeePerGas = baseFeePerGas + maxPriorityFeePerGas + buffer
            buffer_gwei = 2.0  # 2 gwei buffer
            max_fee_per_gas_gwei = base_fee_gwei + max_priority_fee_gwei + buffer_gwei
            
            # Ensure minimum values
            max_priority_fee_gwei = max(max_priority_fee_gwei, 1.0)
            max_fee_per_gas_gwei = max(max_fee_per_gas_gwei, 2.0)
            
            return {
                'maxFeePerGas': self.web3.to_wei(int(max_fee_per_gas_gwei), 'gwei'),
                'maxPriorityFeePerGas': self.web3.to_wei(int(max_priority_fee_gwei), 'gwei')
            }
        except Exception as e:
            print(f"Failed to get optimal EIP-1559 gas params: {e}, using legacy pricing")
            # Fallback to legacy gas pricing
            gas_price = self.get_optimal_gas_price(priority)
            return {
                'gasPrice': self.web3.to_wei(gas_price, 'gwei')
            }
    
    def get_optimal_gas_price(self, priority='low'):
        """Get optimal gas price based on priority (low, medium, high)"""

        valid_priorities = ['low', 'medium', 'high']  
        if priority not in valid_priorities:  
            raise ValueError(f"Invalid priority '{priority}'. Must be one of: {valid_priorities}")
        
        current_price = self.get_current_gas_price()
        current_price_gwei = float(self.web3.from_wei(current_price, 'gwei'))
        
        if priority == 'low':
            # Use 80% of current gas price for low priority
            optimal_price = int(current_price_gwei * 0.8)
        elif priority == 'medium':
            # Use current gas price for medium priority
            optimal_price = int(current_price_gwei)
        else:  # high priority
            # Use 120% of current gas price for high priority
            optimal_price = int(current_price_gwei * 1.2)
        
        # Ensure minimum gas price
        optimal_price = max(optimal_price, 1)
        return optimal_price
    
    def increase_gas_price(self, current_gas_price, increase_percent=20):
        """Increase gas price by a percentage"""
        return int(current_gas_price * (1 + increase_percent / 100))

    def estimate_optimal_gas_limit(self, contract_id, constructor_args=[]):
        """Estimate optimal gas limit for contract deployment"""
        try:
            estimated_gas = self.estimate_deploy_gas(contract_id, constructor_args)
            # Add 20% buffer for safety
            optimal_gas = int(estimated_gas * 1.2)
            # Ensure minimum gas limit
            optimal_gas = max(optimal_gas, 21000)
            # Cap at reasonable maximum
            optimal_gas = min(optimal_gas, DEFAULT_GAS_LIMIT)
            return optimal_gas
        except Exception as e:
            print(f"Failed to estimate gas: {e}, using default")
            return DEFAULT_GAS_LIMIT

def load_contract(file_path):
    # Ensure the file path is valid
    if not os.path.exists(file_path):
        raise Exception(f"The file {file_path} does not exist")

    # Read the Solidity source code from the file
    with open(file_path, 'r') as file:
        return file.read()

def compile_contract(file_path, 
                     mpc_inst_path=MPC_INTERFACE_PATH, 
                     mpc_core_path=MPC_CORE_PATH, 
                     address_path=CONTRACTS_ADDRESS_PATH,
                     node_modules_path=""):
    if SOLC_VERSION not in get_installed_solc_versions():
        install_solc(SOLC_VERSION)
    set_solc_version(SOLC_VERSION)
    from solcx import get_solc_version
    
    contract_name = os.path.basename(file_path).split('.')[0]
    
    solidity_code = load_contract(file_path)

    # Create sources for the compiler
    sources = {
        file_path: {"content": solidity_code},
    }

    if mpc_inst_path != "":
        sources["MpcInterface.sol"] = {"urls": [mpc_inst_path]}
    if mpc_core_path != "":
        sources["MpcCore.sol"] = {"urls": [mpc_core_path]}
    if address_path != "":
        sources["GCHandlerAddress.sol"] = {"urls": [address_path + "GCHandlerAddress.sol"]}
        sources["GCACLAddress.sol"] = {"urls": [address_path + "GCACLAddress.sol"]}

    # Get the absolute path to node_modules in the bubble directory
    if node_modules_path == "":
        print("node_modules_path: ", os.path.abspath(os.path.join(os.path.dirname(file_path), "../node_modules")))
        node_modules_path = os.path.abspath(os.path.join(os.path.dirname(file_path), "../node_modules"))
        # Check if node_modules directory exists  
        if not os.path.exists(node_modules_path):  
            raise FileNotFoundError(f"node_modules directory not found at {node_modules_path}. Run 'npm install' first.")  
    
    # Add remappings for OpenZeppelin imports
    remappings = [
        f"@openzeppelin/={node_modules_path}/@openzeppelin/"
    ]

    compiled_sol = compile_standard({
        "language": "Solidity",
        "sources": sources,
        "settings": {
            "viaIR": True,
            "evmVersion": "cancun",
            "optimizer": {
                "enabled": True,
                "runs": 200
            },
            "outputSelection": {
                "*": {
                    "*": ["metadata", "evm.bytecode", "evm.bytecode.sourceMap"]
                }
            },
            "remappings": remappings
        },
    },
    solc_version=SOLC_VERSION,
    allow_paths=[mpc_inst_path, mpc_core_path, file_path, node_modules_path]
    )
    
    bytecode = compiled_sol['contracts'][file_path][contract_name]['evm']['bytecode']['object']
    contract_abi = json.loads(compiled_sol['contracts'][file_path][contract_name]['metadata'])['output']['abi']
    contract_bytecode = f'0x{bytecode}'
    
    return contract_bytecode, contract_abi
