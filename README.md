# Compliant Confidential Contracts

A general interface for confidential contracts built on SodaLabs' bubble network, providing privacy-preserving smart contract functionality through Multi-Party Computation (MPC).

## About SodaLabs

[SodaLabs](https://www.sodalabs.xyz/) is a pioneering company in confidential computing and privacy-preserving blockchain technology. They specialize in developing infrastructure that enables secure, private computations on blockchain networks while maintaining regulatory compliance.

### Key SodaLabs Resources:
- **Website**: [sodalabs.xyz](https://www.sodalabs.xyz/)
- **GitHub**: [github.com/soda-mpc](https://github.com/soda-mpc)

## The Bubble Network

The **Bubble Network** is SodaLabs' proprietary confidential computing infrastructure that enables privacy-preserving smart contracts. It provides:

- **Confidential Computing**: All sensitive data is encrypted and processed in the bubble network
- **Multi-Party Computation (based on Garbled Circuits)**: Cryptographic protocols that allow multiple parties to jointly compute functions while keeping their inputs private
- **Regulatory Compliance**: Built-in mechanisms to ensure compliance with financial regulations

### Bubble Network Architecture:
- **Encrypted State**: All sensitive contract state is encrypted using MPC protocols
- **Access Control**: Granular permission system for encrypted data access
- **Decryption Oracle**: Secure decryption service for authorized operations
- **Event Emission**: Privacy-preserving event system for blockchain transparency

## Library Overview

This library provides a comprehensive framework for building confidential smart contracts with the following key components:

### Core Contracts

#### 1. **MpcCore.sol** - MPC Operations Library
The central library providing Multi-Party Computation operations:
- **Encrypted Data Types**: `gtBool`, `gtUint8`, `gtUint16`, `gtUint32`, `gtUint64`
- **Arithmetic Operations**: Addition, subtraction, multiplication, division with overflow checking
- **Logical Operations**: AND, OR, XOR, NOT, comparison operations
- **Random Number Generation**: Cryptographically secure random number generation
- **Transfer Operations**: Secure token transfer with allowance management

#### 2. **GCHandler.sol** - Event Handler
Manages and emits events for all MPC operations:
- **Operation Events**: Tracks all cryptographic operations for audit trails
- **Access Control**: Enforces permissions for encrypted data access
- **Decryption Requests**: Handles secure decryption requests
- **Signature Validation**: Validates cryptographic signatures for data integrity

#### 3. **GCACL.sol** - Access Control List
Manages permissions for encrypted data:
- **Persistent Permissions**: Long-term access grants
- **Transient Permissions**: Temporary access for single transactions
- **Permission Checking**: Validates access rights before operations
- **Permission Management**: Grant and revoke access to encrypted handles

#### 4. **DecryptionCaller.sol** - Decryption Interface
Abstract contract for handling decryption requests:
- **Decryption Requests**: Initiates secure decryption operations
- **Callback Handling**: Processes decryption results
- **Error Management**: Handles decryption failures gracefully
- **Request Tracking**: Maintains state of pending decryptions

### Application Contracts

#### 5. **PrivateERC20Contract.sol** - Confidential ERC20 Token
Full-featured ERC20 token with privacy enhancements:
- **Encrypted Balances**: Token balances stored as encrypted handles
- **Private Transfers**: Transfer tokens without revealing amounts
- **Shield/Unshield**: Convert between public and private tokens
- **Allowance Management**: Encrypted approval system
- **Compliance Features**: Built-in regulatory compliance mechanisms

#### 6. **PrivateERC20Factory.sol** - Token Factory
Factory contract for deploying new private tokens:
- **Token Creation**: Deploy new PrivateERC20 instances
- **Parameter Validation**: Ensure valid token parameters
- **Registry Management**: Track deployed tokens
- **Event Emission**: Notify of new token deployments

#### 7. **TUSDC.sol** - Test USDC Token
Simple ERC20 token for testing purposes:
- **Standard ERC20**: Basic token functionality
- **Mint/Burn**: Token supply management
- **Configurable Decimals**: Adjustable precision
- **Testing Support**: Designed for development and testing

### Interface Contracts

#### 8. **MpcInterface.sol** - MPC Interface Definitions
Defines the interfaces for MPC operations:
- **GCExtendedOperations**: Core MPC operation interface
- **GCACL**: Access control interface
- **Operation Signatures**: Complete function signatures for all MPC operations

#### 9. **Address Contracts** - Contract Address Management
- **GCHandlerAddress.sol**: Address of the GCHandler contract
- **GCACLAddress.sol**: Address of the GCACL contract



## Key Features

### Privacy-Preserving Operations
- **Encrypted Arithmetic**: All mathematical operations performed on encrypted data
- **Private Comparisons**: Compare values without revealing them
- **Secure Randomness**: Cryptographically secure random number generation
- **Confidential Transfers**: Transfer tokens without revealing amounts

### Access Control
- **Granular Permissions**: Fine-grained access control for encrypted data
- **Temporary Access**: Short-term permissions for single operations
- **Persistent Access**: Long-term access grants for trusted parties
- **Permission Validation**: Automatic permission checking before operations

### Compliance & Audit
- **Event Emission**: All operations emit events for audit trails
- **Signature Validation**: Cryptographic signatures ensure data integrity
- **Decryption Tracking**: Complete audit trail of decryption requests
- **Regulatory Compliance**: Built-in mechanisms for financial regulations

## Security Considerations

- **Encrypted State**: All sensitive data is encrypted using MPC protocols
- **Access Control**: Strict permission system prevents unauthorized access
- **Signature Validation**: All encrypted data requires valid signatures
- **Decryption Oracle**: Secure decryption service with proper authorization
- **Audit Trails**: Complete event emission for transparency and compliance

## License

This project is licensed under the MIT License - see the LICENSE file for details.

