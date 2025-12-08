#!/usr/bin/env python3
"""
Get signers from GCDecryptionVerifier contract.
Reads the contract address from GCDecryptionVerifierAddress.sol and calls getSigners().
Writes the signers to a file.
"""
import os
import sys
import re
from web3 import Web3
from lib.onchain.scripts.python.soda_web3_helper import SodaWeb3Helper

def extract_address_from_sol_file(file_path):
    """Extract the address constant from a Solidity file."""
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Match: address constant GCDecryptionVerifierAddress = 0x...;
        pattern = r'address\s+constant\s+\w+\s*=\s*(0x[a-fA-F0-9]+);'
        match = re.search(pattern, content)
        
        if match:
            address = match.group(1)
            return Web3.to_checksum_address(address)
        else:
            raise ValueError(f"Could not find address constant in {file_path}")
    except FileNotFoundError:
        raise FileNotFoundError(f"Address file not found: {file_path}")

def get_signers_from_contract(soda_helper, contract_address):
    """Get signers from the GCDecryptionVerifier contract."""
    # Setup the contract (compile to get ABI)
    contract_path = "contracts/GCDecryptionVerifier.sol"
    success = soda_helper.setup_contract(
        contract_path, 
        "decryption_verifier",
        mpc_inst_path="",
        mpc_core_path="",
        address_path=""
    )
    
    if not success:
        raise Exception("Failed to set up the contract")
    
    # Set the contract address
    soda_helper.set_contract_address("decryption_verifier", contract_address)
    
    # Call getSigners() view function
    signers = soda_helper.call_contract_view("decryption_verifier", "getSigners", [])
    
    return signers

def write_signers_to_file(signers, output_file):
    """Write signers to a file."""
    os.makedirs(os.path.dirname(output_file) if os.path.dirname(output_file) else '.', exist_ok=True)
    
    with open(output_file, 'w') as f:
        f.write("# Signers from GCDecryptionVerifier contract\n")
        f.write(f"# Total signers: {len(signers)}\n\n")
        for i, signer in enumerate(signers, 1):
            f.write(f"{i}. {signer}\n")
    
    print(f"Signers written to {output_file}")

def get_signers_addresses():
    """Main function."""
    # Get environment variables
    signing_key = os.environ.get('SIGNING_KEY')
    if not signing_key:
        raise ValueError("SIGNING_KEY environment variable not set")
    
    provider_url = os.environ.get('REMOTE_RPC_URL')
    if not provider_url:
        raise ValueError("REMOTE_RPC_URL environment variable not set")
    
    chain_id = os.environ.get('REMOTE_CHAIN_ID')
    if not chain_id:
        raise ValueError("REMOTE_CHAIN_ID environment variable not set")

    chain_name = os.environ.get('CHAIN_NAME')
    if not chain_name:
        raise ValueError("CHAIN_NAME environment variable not set")
    chain_name = chain_name.upper()
    
    # Get address file path 
    address_file_chain = f"contracts/GCDecryptionVerifierAddress.sol"
    contract_address = None
    if os.path.exists(address_file_chain):
        contract_address = extract_address_from_sol_file(address_file_chain)
    else:
        raise FileNotFoundError(f"Address file not found. Checked:\n  - {address_file_chain}")
    
    # Initialize SodaWeb3Helper
    soda_helper = SodaWeb3Helper(signing_key, provider_url, chain_id=int(chain_id))
    
    # Get signers
    signers = get_signers_from_contract(soda_helper, contract_address)
    
    return signers

if __name__ == "__main__":
    try:
        signers = get_signers_addresses()
        print(f"\nSuccessfully retrieved {len(signers)} signer(s)")
        sys.exit(0)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)

