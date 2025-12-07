// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "MpcCore.sol";
import "GCDecryptionVerifierAddress.sol";

interface GCDecryptionVerifier {
    function verifyDecryptionSignatures(
        uint256[] memory handlesList,
        bytes[] memory decryptedResult,
        bytes[] memory signatures
    ) external returns (bool);
}

abstract contract DecryptionCaller {

    /// @notice Emitted when the decryption fails
    /// @param expected The expected size
    /// @param received The received size
    error InvalidDecryptSize(uint256 expected, uint256 received);

    /// @notice Emitted when the decryption is successful
    /// @param decryptID The ID of the decryption
    event SuccessDecryption(uint256 decryptID);

    /// @notice Emitted when the decryption ID already exists
    /// @param decryptID The ID of the decryption
    error DecryptionIDAlreadyExists(uint256 decryptID);

    /// @notice Emitted when the decryption ID does not exist
    /// @param decryptID The ID of the decryption
    error DecryptionIDDoesNotExist(uint256 decryptID);

    /// @notice Emitted when the signatures are invalid
    /// @param decryptID The ID of the decryption
    error InvalidSignatures(uint256 decryptID);

    /// @notice The counter of the decryption for this contract
    uint256 decryptCounter;

    /// @notice The mapping of the handles of the decryption corresponding to the decryptID
    mapping(uint256 => uint256[]) decryptHandles;

    /// @notice Request the decryption of the handles
    /// @param handles The handles to decrypt
    /// @param callbackSelector The callback selector
    /// @return decryptID The ID of the decryption
    function requestDecryption(
        uint256[] memory handles,
        bytes4 callbackSelector
    ) internal returns (uint256 decryptID) {
        decryptID = decryptCounter;
        saveDecryptHandles(decryptID, handles);
        MpcCore.requestDecryption(decryptID, handles, callbackSelector);
        decryptCounter++;
    }

    /// @notice Save the handles to the mapping of the handles of the decryption corresponding to the decryptID
    /// @param decryptID The ID of the decryption
    /// @param handles The handles to save
    function saveDecryptHandles(uint256 decryptID, uint256[] memory handles) internal {
        require(handles.length > 0, "Handles array cannot be empty");  
        
        if (decryptHandles[decryptID].length > 0) {
            revert DecryptionIDAlreadyExists(decryptID);
        }
        decryptHandles[decryptID]= handles;  
    }

    /// @notice Get the handles of the decryption corresponding to the decryptID
    /// @param decryptID The ID of the decryption
    /// @return The handles of the decryption
    function getDecryptHandles(uint256 decryptID) internal view returns (uint256[] memory) {
        if (decryptHandles[decryptID].length == 0) {
            revert DecryptionIDDoesNotExist(decryptID);
        }
        return decryptHandles[decryptID];
    }

    /// @notice Verify the signatures of the decryption
    /// @param decryptID The ID of the decryption
    /// @param outputs The output of the decryption
    /// @param signatures The signatures of the decryption
    modifier verifyCallback(uint256 decryptID, bytes[] memory outputs, bytes[] memory signatures) {
        uint256[] memory handles = getDecryptHandles(decryptID);
        if (handles.length != outputs.length) {
            revert InvalidDecryptSize(handles.length, outputs.length);
        }
        if (!verifySignatures(handles, outputs, signatures)) {
            revert InvalidSignatures(decryptID);
        }
        _;
        emit SuccessDecryption(decryptID);
    }

    /// @notice Verify the signatures of the decryption
    /// @param handles The handles of the decryption
    /// @param outputs The output of the decryption
    /// @param signatures The signatures of the decryption
    /// @return True if the signatures are valid, false otherwise
    function verifySignatures(uint256[] memory handles, bytes[] memory outputs, bytes[] memory signatures) internal returns (bool) {
        return GCDecryptionVerifier(address(GCDecryptionVerifierAddress)).verifyDecryptionSignatures(handles, outputs, signatures);
    }


}