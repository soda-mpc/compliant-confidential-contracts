// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "MpcInterface.sol";
import {GCACLAddress} from "GCACLAddress.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title    GCHandler
/// @notice   This contract emits events for all GC operations.
/// @dev      This contract is deployed using an UUPS proxy.
contract GCHandler is UUPSUpgradeable, Ownable2StepUpgradeable{
    
    uint256 constant MPC_SIZES_LENGTH = 7;
    enum METADATA_INDICES {ZERO, ONE, TWO, THREE, FOUR}
    enum InputTypes {BOTH_SECRET, LHS_PUBLIC, RHS_PUBLIC}

    uint8 constant SBOOL_T = 1;
    uint8 constant SUINT8_T = 8;
    uint8 constant SUINT16_T = 16;
    uint8 constant SUINT32_T = 32;
    uint8 constant SUINT64_T = 64;
    uint8 constant SUINT128_T = 128;
    uint16 constant SUINT256_T = 256;

    string constant MESSAGE_PREFIX = "Ethereum Signed Message:\n";

    /// @custom:storage-location erc7201:bubble.storage.GCHandler
    struct GCCounterStorage {
        uint256 counter; // tracks the number of decryption requests, and used to compute the requestID by hashing it with the dApp address
    }

    /// keccak256(abi.encode(uint256(keccak256("bubble.storage.GCHandlerDecryptionStorageLocation")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant GCHandlerDecryptionStorageLocation = 0xd440951dcf626c3463253e61fb3d166b15c59bf4deaf2fe3001afee4b00bce00;

    /// keccak256(abi.encode(uint256(keccak256("bubble.storage.GCHandlerRandStorageLocation")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant GCHandlerRandStorageLocation = 0xdbeaee257380a3f0b8afb068c92c56a0ac9ad7bd42758fcf50b0034902ee3e00;

    /// keccak256(abi.encode(uint256(keccak256("bubble.storage.GCHandlerOprfStorageLocation")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant GCHandlerOprfStorageLocation = 0xd8f5e17ab37a053a554cebc4310f5ddd7d02997caa29c1f83b5caf58673d7800;

    GCACL constant acl = GCACL(address(GCACLAddress));

    /// @notice         Returned if the signature is invalid.
    error InvalidSignature();

    /// @notice         Returned if the caller is not permitted to access the handle.
    /// @param handle   Handle.
    /// @param sender   Sender address.
    error ACLNotPermitted(uint256 handle, address sender);

    /// @notice         Returned if the public parameter is invalid.
    /// @param param    Parameter.
    error InvalidPublicParameter(uint256 param);

    /// @notice         Returned if the bit size is invalid.
    /// @param bitSize  Bit size.
    error InvalidBitSize(uint16 bitSize);

    /// @notice         Returned if the parameter is invalid.
    /// @param param  Parameter.
    error InvalidParameter(uint256 param);

    /// @notice         Returned if the input type is invalid.
    /// @param inputType Input type.
    error InvalidInputType(bytes1 inputType);

    event GCBinaryOperation(string opName, uint16 lhsBitSize, uint16 rhsBitSize, bytes1 inputTypes, uint256 lhsParameter, uint256 rhsParameter, uint256 resultHandle);
    event GCOnboard(uint16 bitSize, uint256 ct, address userAddress, uint256 resultHandle);
    event GCOnboard256(uint16 bitSize, uint256 ctHigh, uint256 ctLow, address userAddress, uint256 resultHandle);
    event GCCheckedBinaryOperation(string opName, uint16 lhsBitSize, uint16 rhsBitSize, bytes1 inputTypes, uint256 lhsParameter, uint256 rhsParameter, uint256 overflowHandle, uint256 resultHandle);
    event GCTransfer(uint16 fromBitSize, uint16 toBitSize, uint16 amountBitSize, bytes1 amountType, uint256 from, uint256 to, uint256 amount, uint256 newFromHandle, uint256 newToHandle, uint256 resultHandle);
    event GCTransferWithAllowance(uint16 fromBitSize, uint16 toBitSize, uint16 amountBitSize, uint16 allowanceBitSize, bytes1 amountType, uint256 from, uint256 to, uint256 amount, uint256 allowance, uint256 newFromHandle, uint256 newToHandle, uint256 newAllowanceHandle, uint256 resultHandle);
    event GCMux(uint16 lhsBitSize, uint16 rhsBitSize, bytes1 inputTypes, uint256 bitParameter, uint256 lhsParameter, uint256 rhsParameter, uint256 resultHandle);
    event GCRand(uint16 bitSize, uint256 resultHandle);
    event GCUnaryOperation(string opName, uint16 parameterBitSize, uint256 parameter, uint256 resultHandle);
    event GCDecryptionRequest(uint256 indexed counter, uint256 decryptID, uint256[] handles, address contractCaller, bytes4 callbackSelector);
    event GCOprfMint(uint256 key, uint256 q, uint256 x, uint256 y);
    event GCOprfBurn(uint256 key, uint256 x, uint256 q, uint256 y, uint256 qBurned);
    event GCOprfSplit(uint256 key, uint256 x, uint256 q, uint256 y, uint256 qSplit, uint256 xrRemainder, uint256 qRemainder, uint256 yRemainder, uint256 xrPay, uint256 qPay, uint256 yPay);
    event GCOprfMerge(uint256 key, uint256 x1, uint256 q1, uint256 y1, uint256 x2, uint256 q2, uint256 y2, uint256 xr, uint256 qMerged, uint256 yMerged);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function getSize(bytes1 size) internal pure returns (uint16) {
        // simple bounds check
        uint256 idx = uint8(size);
        require(idx < MPC_SIZES_LENGTH, "Invalid size index");
        if (idx == 0) return 1;
        if (idx == 1) return 8;
        if (idx == 2) return 16;
        if (idx == 3) return 32;
        if (idx == 4) return 64;
        if (idx == 5) return 128;
        if (idx == 6) return 256;
        revert("Invalid size index");
    }

    function checkPublicParameter(uint256 param, uint16 bitSize) internal view returns (bool) {
        if (bitSize == uint16(SBOOL_T)) {
            if (param != 0 && param != 1) return false;
            return true;
        }
        if (bitSize == SUINT8_T) return param <= type(uint8).max;
        if (bitSize == SUINT16_T) return param <= type(uint16).max;
        if (bitSize == SUINT32_T) return param <= type(uint32).max;
        if (bitSize == SUINT64_T) return param <= type(uint64).max;
        if (bitSize == SUINT128_T) return param <= type(uint128).max;
        if (bitSize == SUINT256_T) return param <= type(uint256).max;
        return false;
    }

    function checkACL(uint256 handle) internal view returns (bool) {
        return acl.isPermitted(handle, msg.sender);
    }

    function validateBitSize(uint16 bitSize) internal view returns (bool) {
        if (bitSize == SBOOL_T || bitSize == SUINT8_T || bitSize == SUINT16_T || bitSize == SUINT32_T || bitSize == SUINT64_T || bitSize == SUINT128_T || bitSize == SUINT256_T) return true;
        return false;
    }

    function validateInputTypes(bytes1 inputTypes) internal view returns (bool) {
        if (inputTypes == bytes1(uint8(InputTypes.BOTH_SECRET)) || inputTypes == bytes1(uint8(InputTypes.LHS_PUBLIC)) || inputTypes == bytes1(uint8(InputTypes.RHS_PUBLIC))) return true;
        return false;
    }

    function validateBinaryParams(uint256 lhsParam, uint256 rhsParam, uint16 lhsBitSize, uint16 rhsBitSize, bytes1 inputTypes) internal view {
        if (lhsBitSize == SBOOL_T && rhsBitSize != SBOOL_T) revert InvalidBitSize(lhsBitSize);
        if (rhsBitSize == SBOOL_T && lhsBitSize != SBOOL_T) revert InvalidBitSize(rhsBitSize);
        if (!validateBitSize(lhsBitSize)) revert InvalidBitSize(lhsBitSize);
        if (!validateBitSize(rhsBitSize)) revert InvalidBitSize(rhsBitSize);

        if (inputTypes == bytes1(uint8(InputTypes.BOTH_SECRET))) { // both parameters are handles
            if (!checkACL(lhsParam)) revert ACLNotPermitted(lhsParam, msg.sender);
            if (!checkACL(rhsParam)) revert ACLNotPermitted(rhsParam, msg.sender);
        } else if (inputTypes == bytes1(uint8(InputTypes.LHS_PUBLIC))) { // lhsParam is a public, rhsParam is a handle
            if (!checkACL(rhsParam)) revert ACLNotPermitted(rhsParam, msg.sender);
            if (!checkPublicParameter(lhsParam, lhsBitSize)) revert InvalidPublicParameter(lhsParam);
        } else if (inputTypes == bytes1(uint8(InputTypes.RHS_PUBLIC))) { // rhsParam is a public, lhsParam is a handle
            if (!checkACL(lhsParam)) revert ACLNotPermitted(lhsParam, msg.sender);
            if (!checkPublicParameter(rhsParam, rhsBitSize)) revert InvalidPublicParameter(rhsParam);
        } else {
            revert InvalidInputType(inputTypes);
        }
    }

    function validateBinaryParamsNoBoolean(uint256 lhsParam, uint256 rhsParam, uint16 lhsBitSize, uint16 rhsBitSize, bytes1 inputTypes) internal view {
        validateBinaryParams(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);
        if (lhsBitSize == SBOOL_T || rhsBitSize == SBOOL_T) revert InvalidBitSize(lhsBitSize);
    }

    function validateUnaryParams(uint256 param, uint16 bitSize, bytes1 inputType) internal view {
        if (!validateBitSize(bitSize)) revert InvalidBitSize(bitSize);
        
        if (!validateInputTypes(inputType)) revert InvalidInputType(inputType);
        if (inputType == bytes1(uint8(InputTypes.BOTH_SECRET))) { // parameter is a handle
            if (!checkACL(param)) revert ACLNotPermitted(param, msg.sender);       
        } else {
            if (!checkPublicParameter(param, bitSize)) revert InvalidPublicParameter(param);
        } 
    }

    /// @notice              Computes Add operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle.
    function Add(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("Add", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("ADD", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }

    /// @notice                Computes Checked Add operation.
    /// @param metadata        Meta data.
    /// @param lhsParam        LHS parameter.
    /// @param rhsParam        RHS parameter.
    /// @return overflowHandle Overflow handle.
    /// @return resultHandle   Result handle.
    function CheckedAdd(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 overflowHandle, uint256 resultHandle) {

        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("CheckedAdd", lhsParam, rhsParam, metadata)));
        overflowHandle = uint256(keccak256(abi.encodePacked("CheckedAddOverflow", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result and overflow handles
        acl.permitTransient(resultHandle, msg.sender);
        acl.permitTransient(overflowHandle, msg.sender);

        emit GCCheckedBinaryOperation("ADDWITHOVERFLOWBIT", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, overflowHandle, resultHandle);
    }

    /// @notice              Computes Sub operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle.
    function Sub(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("Sub", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("SUB", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }

    /// @notice                Computes Checked Sub operation.
    /// @param metadata        Meta data.
    /// @param lhsParam        LHS parameter.
    /// @param rhsParam        RHS parameter.
    /// @return overflowHandle Overflow handle.
    /// @return resultHandle   Result handle.
    function CheckedSub(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 overflowHandle, uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("CheckedSub", lhsParam, rhsParam, metadata)));
        overflowHandle = uint256(keccak256(abi.encodePacked("CheckedSubOverflow", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result and overflow handles
        acl.permitTransient(resultHandle, msg.sender);
        acl.permitTransient(overflowHandle, msg.sender);

        emit GCCheckedBinaryOperation("SUBWITHOVERFLOWBIT", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, overflowHandle, resultHandle);
    }

    /// @notice              Computes Mul operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle.
    function Mul(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("Mul", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("MUL", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }

    
    /// @notice                Computes Checked Mul operation.
    /// @param metadata        Meta data.
    /// @param lhsParam        LHS parameter.
    /// @param rhsParam        RHS parameter.
    /// @return overflowHandle Overflow handle.
    /// @return resultHandle   Result handle.
    function CheckedMul(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 overflowHandle, uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("CheckedMul", lhsParam, rhsParam, metadata)));
        overflowHandle = uint256(keccak256(abi.encodePacked("CheckedMulOverflow", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);
        acl.permitTransient(overflowHandle, msg.sender);

        emit GCCheckedBinaryOperation("MULWITHOVERFLOWBIT", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, overflowHandle, resultHandle);
    }
  
    /// @notice              Computes Le (Less than or Equal) operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle. 
    function Le(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("Le", lhsParam, rhsParam, metadata)));
        // 
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("LE", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }
 
    /// @notice              Computes Lt (Less than) operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle.
    function Lt(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("Lt", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("LT", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }
   
    /// @notice              Computes Ge (Greater than or Equal) operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle.
    function Ge(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("Ge", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("GE", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }
    
    /// @notice              Computes Gt (Greater than) operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle.
    function Gt(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("Gt", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("GT", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }

    /// @notice              Computes Eq (Equal) operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle. 
    function Eq(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParams(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("Eq", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("EQ", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }
    
    /// @notice              Computes Ne (Not Equal) operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle.  
    function Ne(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParams(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("Ne", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("NE", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }
    
    /// @notice              Computes Min operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle.
    function Min(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("Min", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("MIN", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }
    
    /// @notice              Computes Max operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle.
    function Max(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("Max", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("MAX", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }
    
    /// @notice              Computes Div operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle.
    function Div(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("Div", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("DIV", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }
    
    /// @notice              Computes Rem (Remainder) operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle.
    function Rem(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("Rem", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("REM", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }
    
    /// @notice              Computes And operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle.
    function And(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParams(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("And", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("AND", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }
    
    /// @notice              Computes Or operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle.
    function Or(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParams(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("Or", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("OR", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }

    /// @notice              Computes Xor operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle.
    function Xor(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParams(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("Xor", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("XOR", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }

    /// @notice              Computes Shift Left operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle.
    function Shl(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        if (inputTypes != bytes1(uint8(InputTypes.RHS_PUBLIC))) revert InvalidInputType(inputTypes); // inputTypes must be RhsPublic

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("Shl", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("SHL", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }
    
    /// @notice              Computes Shift Right operation.
    /// @param metadata      Meta data.
    /// @param lhsParam      LHS parameter.
    /// @param rhsParam      RHS parameter.
    /// @return resultHandle Result handle.
    function Shr(bytes3 metadata, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        if (inputTypes != bytes1(uint8(InputTypes.RHS_PUBLIC))) revert InvalidInputType(inputTypes); // inputTypes must be RhsPublic

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        resultHandle = uint256(keccak256(abi.encodePacked("Shr", lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCBinaryOperation("SHR", lhsBitSize, rhsBitSize, inputTypes, lhsParam, rhsParam, resultHandle);
    }
    
    /// @notice              Computes Transfer operation.
    /// @param metadata      Meta data.
    /// @param from          From parameter.
    /// @param to            To parameter.
    /// @param amount        Amount parameter.
    /// @return newFromHandle Result from handle.
    /// @return newToHandle   Result to handle.
    /// @return resultHandle  Result handle.
    function Transfer(bytes4 metadata, uint256 from, uint256 to, uint256 amount) public virtual returns (uint256 newFromHandle, uint256 newToHandle, uint256 resultHandle) {
        uint16 fromBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 toBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        uint16 amountBitSize = getSize(metadata[uint8(METADATA_INDICES.TWO)]);
        bytes1 amountType = metadata[uint8(METADATA_INDICES.THREE)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(from, to, fromBitSize, toBitSize, bytes1(0)); // In transfer both from and to are handles
        validateUnaryParams(amount, amountBitSize, amountType);

        newFromHandle = uint256(keccak256(abi.encodePacked("TransferFrom", from, to, amount, metadata)));
        newToHandle = uint256(keccak256(abi.encodePacked("TransferTo", from, to, amount, metadata)));
        resultHandle = uint256(keccak256(abi.encodePacked("TransferRes", from, to, amount, metadata)));
        // Permit the calling contract to access the result handles
        acl.permitTransient(newFromHandle, msg.sender);
        acl.permitTransient(newToHandle, msg.sender);
        acl.permitTransient(resultHandle, msg.sender);

        emit GCTransfer(fromBitSize, toBitSize, amountBitSize, amountType, from, to, amount, newFromHandle, newToHandle, resultHandle);
    }
    
    /// @notice              Computes TransferWithAllowance operation.
    /// @param metadata      Meta data.
    /// @param from          From parameter.
    /// @param to            To parameter.
    /// @param amount        Amount parameter.
    /// @param allowance     Allowance parameter.
    /// @return newFromHandle Result from handle.
    /// @return newToHandle   Result to handle.
    /// @return resultHandle  Result handle.
    /// @return newAllowanceHandle Result allowance handle.
    function TransferWithAllowance(bytes5 metadata, uint256 from, uint256 to, uint256 amount, uint256 allowance) public virtual returns (uint256 newFromHandle, uint256 newToHandle, uint256 resultHandle, uint256 newAllowanceHandle) {
        uint16 fromBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 toBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        uint16 amountBitSize = getSize(metadata[uint8(METADATA_INDICES.TWO)]);
        uint16 allowanceBitSize = getSize(metadata[uint8(METADATA_INDICES.THREE)]);
        bytes1 amountType = metadata[uint8(METADATA_INDICES.FOUR)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParamsNoBoolean(from, to, fromBitSize, toBitSize, bytes1(0)); // In transfer both from and to are handles
        validateUnaryParams(amount, amountBitSize, amountType);

        // Check that the caller is permitted to access the allowance
        validateUnaryParams(allowance, allowanceBitSize, bytes1(0));
        
        newFromHandle = uint256(keccak256(abi.encodePacked("TransferAllowanceFrom", from, to, amount, allowance, metadata)));
        newToHandle = uint256(keccak256(abi.encodePacked("TransferAllowanceTo", from, to, amount, allowance, metadata)));
        resultHandle = uint256(keccak256(abi.encodePacked("TransferAllowanceRes", from, to, amount, allowance, metadata)));
        newAllowanceHandle = uint256(keccak256(abi.encodePacked("TransferAllowanceAllowance", from, to, amount, allowance, metadata)));
        // Permit the calling contract to access the result handles
        acl.permitTransient(newFromHandle, msg.sender);
        acl.permitTransient(newToHandle, msg.sender);
        acl.permitTransient(resultHandle, msg.sender);
        acl.permitTransient(newAllowanceHandle, msg.sender);

        emit GCTransferWithAllowance(fromBitSize, toBitSize, amountBitSize, allowanceBitSize, amountType, from, to, amount, allowance, newFromHandle, newToHandle, resultHandle, newAllowanceHandle);
    }

    /// @notice              Computes Mux operation.
    /// @param metadata      Meta data.
    /// @param bitParam  Bit parameter.
    /// @param lhsParam  LHS parameter.
    /// @param rhsParam  RHS parameter.
    /// @return resultHandle Result handle.
    function Mux(bytes3 metadata, uint256 bitParam, uint256 lhsParam, uint256 rhsParam) public virtual returns (uint256 resultHandle) {
        uint16 lhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        uint16 rhsBitSize = getSize(metadata[uint8(METADATA_INDICES.ONE)]);
        bytes1 inputTypes = metadata[uint8(METADATA_INDICES.TWO)];

        // Check that the caller is permitted to access the parameters
        validateBinaryParams(lhsParam, rhsParam, lhsBitSize, rhsBitSize, inputTypes);

        if (!checkACL(bitParam)) revert ACLNotPermitted(bitParam, msg.sender);

        resultHandle = uint256(keccak256(abi.encodePacked("Mux", bitParam, lhsParam, rhsParam, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(resultHandle, msg.sender);

        emit GCMux(lhsBitSize, rhsBitSize, inputTypes, bitParam, lhsParam, rhsParam, resultHandle);
    }

    /// @notice              Computes SetPublic operation.
    /// @param metadata      Meta data.
    /// @param param         Parameter.
    /// @return result       Result handle.
    function SetPublic(bytes1 metadata, uint256 param) public virtual returns (uint256 result){
        uint16 bitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);

        if (!checkPublicParameter(param, bitSize)) revert InvalidPublicParameter(param);

        result = uint256(keccak256(abi.encodePacked("SetPublic", param, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(result, msg.sender);

        emit GCUnaryOperation("SETPUBLIC", bitSize, param, result);
    }

    /// @notice              Computes Not operation.
    /// @param metadata      Meta data.
    /// @param param         Parameter.
    /// @return result       Result handle.
    function Not(bytes1 metadata, uint256 param) public virtual returns (uint256 result){
        // Check that the caller is permitted to access the parameter
        if (!checkACL(param)) revert ACLNotPermitted(param, msg.sender);

        uint16 bitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        if (bitSize != 1) revert InvalidParameter(bitSize);

        result = uint256(keccak256(abi.encodePacked("Not", param, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(result, msg.sender);

        emit GCUnaryOperation("NOT", bitSize, param, result);
    }

    /// @notice                 Computes RequestDecryption operation.
    /// @param decryptID        Decrypt ID.
    /// @param handles          Handles to decrypt.
    /// @param callbackSelector Callback selector.
    function RequestDecryption(uint256 decryptID, uint256[] calldata handles, bytes4 callbackSelector) public virtual {
        // Check that the caller is permitted to access the parameter
        for (uint256 i = 0; i < handles.length; i++) {
            if (!checkACL(handles[i])) revert ACLNotPermitted(handles[i], msg.sender);
        }

        GCCounterStorage storage $ = _getGCHandlerDecryptionStorage();
        emit GCDecryptionRequest($.counter, decryptID, handles, msg.sender, callbackSelector);
        $.counter++;
    }

    function verifySignature(bytes memory message, bytes calldata signature) internal {
        bytes32 messageHash = keccak256(message);

        uint8 v = uint8(signature[64]); 
        if ( v < 27) {
            v += 27; // Need to adjust v to be 27/28
        }
        
        // Recover the address from the message hash
        address recoveredAddress = ecrecover(messageHash, v, bytes32(signature[:32]), bytes32(signature[32:64]));
 
        // check if the recovered address is the same as the tx origin
        if (recoveredAddress != tx.origin) {
            // Failed to validate the signature, Try to recover with eip191
            
            // Update the message to include the eip 191 prefix, message length, and the message
            bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(message);
            
            // Recover the address from the prefixed hash
            recoveredAddress = ecrecover(ethSignedMessageHash, v, bytes32(signature[:32]), bytes32(signature[32:64]));

            // check if the recovered address is the same as the tx origin
            if (recoveredAddress != tx.origin) {
                // Failed to validate the signature, revert
                revert InvalidSignature();
            }
        }
    }

    /// @notice              Computes ValidateCiphertext operation.
    /// @param metadata      Meta data.
    /// @param ciphertext    Ciphertext to validate.
    /// @param signature     Signature of the ciphertext.
    /// @return result       Result handle.
    function ValidateCiphertext(bytes1 metadata, uint256 ciphertext, bytes calldata signature) public virtual returns (uint256 result){
        // check if the signature is valid
        if (signature.length != 65) {
            revert InvalidSignature();
        }

        // Create message of the signature: user address + contract address + ciphertext
        bytes memory message = abi.encodePacked(tx.origin, msg.sender, ciphertext);
        verifySignature(message, signature);

        // Signer is valid, onboard the ct
        uint16 bitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        result = uint256(keccak256(abi.encodePacked("Onboard", ciphertext, tx.origin, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(result, msg.sender);

        emit GCOnboard(bitSize, ciphertext, tx.origin, result);
    }

    /// @notice                 Computes ValidateCiphertext256 operation.
    /// @param metadata         Meta data.
    /// @param ciphertextHigh   Left half of the ciphertext.
    /// @param ciphertextLow    Right half of the ciphertext.
    /// @param signature        Signature of the ciphertext.
    /// @return result          Result handle.
    function ValidateCiphertext(bytes1 metadata, uint256 ciphertextHigh, uint256 ciphertextLow, bytes calldata signature) public virtual returns (uint256 result){
        // check if the signature is valid
        if (signature.length != 65) {
            revert InvalidSignature();
        }

        // Create message of the signature: user address + contract address + ciphertextHigh + ciphertextLow
        bytes memory message = abi.encodePacked(tx.origin, msg.sender, ciphertextHigh, ciphertextLow);
        verifySignature(message, signature);

        // Signer is valid, onboard the ct
        uint16 bitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        if (bitSize != 256) revert InvalidBitSize(bitSize);

        result = uint256(keccak256(abi.encodePacked("Onboard", ciphertextHigh, ciphertextLow, tx.origin, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(result, msg.sender);

        emit GCOnboard256(bitSize, ciphertextHigh, ciphertextLow, tx.origin, result);
    }

    /// @notice              Computes Rand operation.
    /// @param metadata      Meta data.
    /// @return result       Result handle.
    function Rand(bytes1 metadata) public virtual returns (uint256 result){

        uint16 bitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        if (!validateBitSize(bitSize)) revert InvalidParameter(bitSize);

        // The randStorage.counter is used to avoid collisions in the result handles
        GCCounterStorage storage $ = _getGCHandlerRandStorage();
        // when there are multiple calls to the Rand function.
        result = uint256(keccak256(abi.encodePacked("Rand", $.counter, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(result, msg.sender);

        emit GCRand(bitSize, result);
        $.counter++;
    }

    /// @notice              Computes RandBoundedBits operation.
    /// @param metadata      Meta data.
    /// @param numBits       Number of bits to generate.
    /// @return result       Result handle.
    function RandBoundedBits(bytes1 metadata, uint8 numBits) public virtual returns (uint256 result){

        uint16 bitSize = getSize(metadata[uint8(METADATA_INDICES.ZERO)]);
        if (!validateBitSize(bitSize)) revert InvalidParameter(bitSize);
        if (numBits > bitSize) revert InvalidParameter(numBits);

        // The randStorage.counter is used to avoid collisions in the result handles
        GCCounterStorage storage $ = _getGCHandlerRandStorage();
        // when there are multiple calls to the Rand function.
        result = uint256(keccak256(abi.encodePacked("RandBoundedBits", $.counter, numBits, metadata)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(result, msg.sender);

        emit GCUnaryOperation("RAND", bitSize, numBits, result);
        $.counter++;
    }

    /// @notice              Computes OprfMint operation.
    /// The OPRF function is used to generate a random anonymous token.
    /// The OPRF function is defined as:
    /// OPRF(k, x) = CBC-MAC(k, x|q)
    /// where k is the key, x is the input, and q is the quantity.
    /// The x value is chosen randomly by bubble, and the user only provides key and q values.
    /// @param key           Key for the OPRF function.
    /// @param q             Quantity for the token.
    /// @return x            X value of the token.
    /// @return y            Y value of the token.
    function OprfMint(uint256 key, uint256 q) public virtual returns (uint256 x, uint256 y){
        
        GCCounterStorage storage $ = _getGCHandlerOprfStorage();
        x = uint256(keccak256(abi.encodePacked("OprfMintX", $.counter, key, q)));
        y = uint256(keccak256(abi.encodePacked("OprfMintY", $.counter, key, q)));
        // Permit the calling contract to access the result handle
        acl.permitTransient(x, msg.sender);
        acl.permitTransient(y, msg.sender);

        emit GCOprfMint(key, q, x, y);

        $.counter++;
    }

    /// @notice              Computes OprfBurn operation.
    /// The OPRFBurn function is used to burn an anonymous token.
    /// @param key           Key for the OPRF function.
    /// @param x             X value of the token.
    /// @param q             Quantity value of the token.
    /// @param y             Y value of the token.
    /// @return qBurned      Result handle of Q value of the burned token.
    function OprfBurn(uint256 key, uint256 x, uint256 q, uint256 y) public virtual returns (uint256 qBurned){
        GCCounterStorage storage $ = _getGCHandlerOprfStorage();
        qBurned = uint256(keccak256(abi.encodePacked("OprfBurnQBurned", $.counter, key, x, q, y)));
        
        acl.permitTransient(qBurned, msg.sender);
        
        emit GCOprfBurn(key, x, q, y, qBurned);
        
        $.counter++;
    }

    /// @notice              Computes OprfSplit operation.
    /// The OPRFSplit function is used to split an anonymous token into two new tokens..
    /// @param key           Key for the OPRF function.
    /// @param x             X of the original token.
    /// @param q             Quantity of the original token.
    /// @param y             Y of the original token.
    /// @param qSplit        Requested quantity for the new token.
    /// @return xrRemainder  Result handle of X value of the remainder token.
    /// @return qRemainder   Result handle of Q value of the remainder token. Qremainder should be q - qSplit is all validations are successful, otherwise it should be equal to q.
    /// @return yRemainder   Result handle of Y value of the remainder token.
    /// @return xrPay        Result handle of X value of the pay token.
    /// @return qPay         Result handle of Q value of the pay token. Qpay should be qSplit if all validations are successful, otherwise it should be equal to 0.
    /// @return yPay         Result handle of Y value of the pay token.
    function OprfSplit(uint256 key, uint256 x, uint256 q, uint256 y, uint256 qSplit) public virtual returns (uint256 xrRemainder, uint256 qRemainder, uint256 yRemainder, uint256 xrPay, uint256 qPay, uint256 yPay){
        GCCounterStorage storage $ = _getGCHandlerOprfStorage();
        xrRemainder = uint256(keccak256(abi.encodePacked("OprfSplitXrRemainder", $.counter, key, x, q, y, qSplit)));
        qRemainder = uint256(keccak256(abi.encodePacked("OprfSplitQRemainder", $.counter, key, x, q, y, qSplit)));
        yRemainder = uint256(keccak256(abi.encodePacked("OprfSplitYRemainder", $.counter, key, x, q, y, qSplit)));
        xrPay = uint256(keccak256(abi.encodePacked("OprfSplitXrPay", $.counter, key, x, q, y, qSplit)));
        qPay = uint256(keccak256(abi.encodePacked("OprfSplitQPay", $.counter, key, x, q, y, qSplit)));
        yPay = uint256(keccak256(abi.encodePacked("OprfSplitYPay", $.counter, key, x, q, y, qSplit)));

        acl.permitTransient(xrRemainder, msg.sender);
        acl.permitTransient(qRemainder, msg.sender);
        acl.permitTransient(yRemainder, msg.sender);
        acl.permitTransient(xrPay, msg.sender);
        acl.permitTransient(qPay, msg.sender);
        acl.permitTransient(yPay, msg.sender);

        emit GCOprfSplit(key, x, q, y, qSplit, xrRemainder, qRemainder, yRemainder, xrPay, qPay, yPay);

        $.counter++;
    }

    /// @notice              Computes OprfMerge operation.
    /// The OPRFMerge function is used to merge two anonymous tokens into one new token.
    /// @param key           Key for the OPRF function.
    /// @param x1            X value of the first token.
    /// @param q1            Quantity value of the first token.
    /// @param y1            Y value of the first token.
    /// @param x2            X value of the second token.
    /// @param q2            Quantity value of the second token.
    /// @param y2            Y value of the second token.
    /// @return xr           Result handle of X value of the merged token.
    /// @return qMerged      Result handle of Q value of the merged token. Qmerged should be qRemainder + qPay if all validations are successful.
    /// @return yMerged      Result handle of Y value of the merged token.
    function OprfMerge(uint256 key, uint256 x1, uint256 q1, uint256 y1, uint256 x2, uint256 q2, uint256 y2) public virtual returns (uint256 xr, uint256 qMerged, uint256 yMerged){
        
        GCCounterStorage storage $ = _getGCHandlerOprfStorage();
        xr = uint256(keccak256(abi.encodePacked("OprfMergeXr", $.counter, key, x1, q1, y1, x2, q2, y2)));
        qMerged = uint256(keccak256(abi.encodePacked("OprfMergeQMerged", $.counter, key, x1, q1, y1, x2, q2, y2)));
        yMerged = uint256(keccak256(abi.encodePacked("OprfMergeYMerged", $.counter, key, x1, q1, y1, x2, q2, y2)));

        acl.permitTransient(xr, msg.sender);
        acl.permitTransient(qMerged, msg.sender);
        acl.permitTransient(yMerged, msg.sender);

        emit GCOprfMerge(key, x1, q1, y1, x2, q2, y2, xr, qMerged, yMerged);

        $.counter++;
    }

    /**
     * @dev Returns the GCHandlerDecryptionStorage storage location.
     */
    function _getGCHandlerDecryptionStorage() internal pure returns (GCCounterStorage storage $) {
        assembly {
            $.slot := GCHandlerDecryptionStorageLocation
        }
    }

    /**
     * @dev Returns the GCHandlerRandStorage storage location.
     */
    function _getGCHandlerRandStorage() internal pure returns (GCCounterStorage storage $) {
        assembly {
            $.slot := GCHandlerRandStorageLocation
        }
    }

    /**
     * @dev Returns the GCHandlerOprfStorage storage location.
     */
    function _getGCHandlerOprfStorage() internal pure returns (GCCounterStorage storage $) {
        assembly {
            $.slot := GCHandlerOprfStorageLocation
        }
    }

    /**
     * @dev Should revert when `msg.sender` is not authorized to upgrade the contract.
     */
    function _authorizeUpgrade(address _newImplementation) internal virtual override onlyOwner {}
        
}
