// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title   DecryptionVerifier.
 * @notice  DecryptionVerifier is a contract that allows the management of signers and provides
 *          signature verification functions.
 */
contract GCDecryptionVerifier is UUPSUpgradeable, Ownable2StepUpgradeable {
    /// @notice Returned if the signer to add is already a signer.
    error AlreadySigner();

    /// @notice Returned if the recovered signer is not a valid signer.
    /// @param invalidSigner Address of the invalid signer.
    error InvalidSigner(address invalidSigner);

    /// @notice Returned if the signer to add is the null address.
    error NullSigner();

    /// @notice Returned if the number of signatures is not equal to the number of evaluators.
    error InvalidSignaturesCount();

    /// @notice Returned if the signers set is empty.
    error SignersSetIsEmpty();

    /// @notice Emitted when a new signers set is set.
    /// @param newSignersSet   The set of new signers.
    event NewSignersSet(address[] newSignersSet);

    /**
     * @param handlesList       List of handles.
     * @param decryptedResult   Decrypted result.
     */
    struct PublicDecryptionResult {
        uint256[] handlesList;
        bytes[] decryptedResult;
    }

    /// @custom:storage-location erc7201:fhevm.storage.KMSVerifier
    struct VerifierStorage {
        mapping(address => bool) isSigner; /// @notice Mapping to keep track of addresses that are signers
        address[] signers; /// @notice Array to keep track of all signers
    }

    /// The storage location of the GCVerifierStorage struct.
    /// Calculated using the formula: keccak256(abi.encode(uint256(keccak256("bubble.storage.GCVerifierStorageLocation")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant GCVerifierStorageLocation = 0xd4d8f795341f1aa5ae6d9c26ff003eec59d02cbce97f028cfb5ccc38ca5f2200;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice  Re-initializes the contract.
     * @param initialSigners The list of initial signers, should be non-empty and contain unique addresses, otherwise initialization will fail.
     */
    function reinitialize(
        address[] calldata initialSigners
    ) public reinitializer(2) {
        setSigners(initialSigners);
    }

    /**
     * @notice          Sets a new cset of unique signers.
     * @dev             Only the owner can set a new context.
     * @param newSignersSet   The new set of signers to be set. This array should not be empty and without duplicates nor null values.
     */
    function setSigners(address[] memory newSignersSet) public virtual onlyOwner {
        uint256 newSignersLen = newSignersSet.length;
        if (newSignersLen == 0) {
            revert SignersSetIsEmpty();
        }

        /// @dev First, we remove the old signers set
        VerifierStorage storage $ = _getGCVerifierStorage();
        address[] memory oldSignersSet = $.signers;
        uint256 oldSignersLen = oldSignersSet.length;
        for (uint256 i = 0; i < oldSignersLen; i++) {
            $.isSigner[oldSignersSet[i]] = false;
            $.signers.pop();
        }

        /// @dev Next, we add the new set of signers.
        for (uint256 i = 0; i < newSignersLen; i++) {
            address signer = newSignersSet[i];
            if (signer == address(0)) {
                revert NullSigner();
            }
            if ($.isSigner[signer]) {
                revert AlreadySigner();
            }
            $.isSigner[signer] = true;
            $.signers.push(signer);
        }
        emit NewSignersSet(newSignersSet);
    }

    /**
     * @notice                  Verifies multiple signatures for a given handlesList and a given decryptedResult.
     * @dev                     Calls verifySignaturesDigest internally.
     * @param handlesList       The list of handles, which where requested to be decrypted.
     * @param decryptedResult   A list of decrypted values.
     * @param signatures        A list of signatures to verify.
     * @return isVerified       true if the provided signatures are valid, false otherwise.
     */
    function verifyDecryptionSignatures(
        uint256[] memory handlesList,
        bytes[] memory decryptedResult,
        bytes[] memory signatures
    ) public virtual returns (bool) {
        PublicDecryptionResult memory decRes;
        decRes.handlesList = handlesList;
        decRes.decryptedResult = decryptedResult;
        bytes32 digest = _hashDecryptionResult(decRes);
        return _verifySignaturesDigest(digest, signatures);
    }

    /**
     * @notice          Returns the list of signers.
     * @dev             If there are too many signers, it could be out-of-gas.
     * @return signers  List of signers.
     */
    function getSigners() public view virtual returns (address[] memory) {
        VerifierStorage storage $ = _getGCVerifierStorage();
        return $.signers;
    }

    /**
     * @notice              Returns whether the account address is a valid signer.
     * @param account       Account address.
     * @return isSigner     Whether the account is a valid signer.
     */
    function isSigner(address account) public view virtual returns (bool) {
        VerifierStorage storage $ = _getGCVerifierStorage();
        return $.isSigner[account];
    }

    /**
     * @notice          Cleans a hashmap in transient storage.
     * @dev             This is important to keep composability in the context of account abstraction.
     * @param keys      An array of keys to cleanup from transient storage.
     * @param maxIndex  The biggest index to take into account from the array - assumed to be less or equal to keys.length.
     */
    function _cleanTransientHashMap(address[] memory keys, uint256 maxIndex) internal virtual {
        for (uint256 j = 0; j < maxIndex; j++) {
            _tstore(keys[j], 0);
        }
    }

    /**
     * @notice          Writes to transient storage.
     * @dev             Uses inline assembly to access the Transient Storage's _tstore operation.
     * @param location  The address used as key where transient storage of the contract is written at.
     * @param value     An uint256 stored at location key in transient storage of the contract.
     */
    function _tstore(address location, uint256 value) internal virtual {
        assembly {
            tstore(location, value)
        }
    }

    /**
     * @notice              Verifies multiple signatures for a given message at a certain threshold.
     * @dev                 Calls verifySignature internally.
     * @param digest        The hash of the message that was signed by all signers.
     * @param signatures    An array of signatures to verify.
     * @return isVerified   true if enough provided signatures are valid, false otherwise.
     */
    function _verifySignaturesDigest(bytes32 digest, bytes[] memory signatures) internal virtual returns (bool) {
        uint256 numSignatures = signatures.length;

        VerifierStorage storage $ = _getGCVerifierStorage();
        uint256 signersCount = $.signers.length;

        if (numSignatures != signersCount) {
            revert InvalidSignaturesCount();
        }

        address[] memory recoveredSigners = new address[](numSignatures);
        uint256 uniqueValidCount = 0;
        for (uint256 i = 0; i < numSignatures; i++) {
            address signerRecovered = _recoverSigner(digest, signatures[i]);
            if (!isSigner(signerRecovered)) {
                revert InvalidSigner(signerRecovered);
            }
            if (!_tload(signerRecovered)) {
                recoveredSigners[uniqueValidCount] = signerRecovered;
                uniqueValidCount++;
                _tstore(signerRecovered, 1);
            }
            if (uniqueValidCount == signersCount) { // All signatures are valid
                _cleanTransientHashMap(recoveredSigners, uniqueValidCount);
                return true;
            }
        }
        _cleanTransientHashMap(recoveredSigners, uniqueValidCount);
        return false;
    }

    /**
     * @notice                  Hashes the decryption result.
     * @param decRes            Decryption result.
     * @return hashTypedData    Hash typed data.
     */
    function _hashDecryptionResult(PublicDecryptionResult memory decRes) internal pure returns (bytes32) {
        // Concatenate all bytes elements without length prefixes
        bytes memory concatenatedDecryptedResult;
        for (uint256 i = 0; i < decRes.decryptedResult.length; i++) {
            concatenatedDecryptedResult = abi.encodePacked(concatenatedDecryptedResult, decRes.decryptedResult[i]);
        }
        
        return 
            keccak256(abi.encodePacked(abi.encodePacked(decRes.handlesList), concatenatedDecryptedResult));
    }

    /**
     * @notice           Reads transient storage.
     * @dev              Uses inline assembly to access the Transient Storage's tload operation.
     * @param location   The address used as key where transient storage of the contract is read at.
     * @return value     true if value stored at the given location is non-null, false otherwise.
     */
    function _tload(address location) internal view virtual returns (bool value) {
        assembly {
            value := tload(location)
        }
    }


    /**
     * @notice          Recovers the signer's address from a `signature` and a `messageHash` digest.
     * @dev             It utilizes ECDSA for actual address recovery. It does not support contract signature (EIP-1271).
     * @param messageHash   The hash of the message that was signed.
     * @param signature The signature to verify.
     * @return signer   The address that supposedly signed the message.
     */
    function _recoverSigner(bytes32 messageHash, bytes memory signature) internal pure virtual returns (address) {
        // Check signature length
        require(signature.length == 65, "Invalid signature length");
        
        uint8 v = uint8(signature[64]); 
        if (v < 27) {
            v += 27; // Need to adjust v to be 27/28
        }
        
        // Extract r and s from signature (bytes memory doesn't support slicing)
        bytes32 r;
        bytes32 s;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
        }
        
        // Recover the address from the message hash
        return ecrecover(messageHash, v, r, s);
    }

    /**
     * @dev Returns the GCVerifierStorage storage location.
     */
    function _getGCVerifierStorage() internal pure returns (VerifierStorage storage $) {
        assembly {
            $.slot := GCVerifierStorageLocation
        }
    }

    /**
     * @dev Should revert when `msg.sender` is not authorized to upgrade the contract.
     */
    function _authorizeUpgrade(address _newImplementation) internal virtual override onlyOwner {}
}
