// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "MpcCore.sol";
import "../../lib/onchain/contracts/DecryptionCaller.sol";

contract MalformedInputs is DecryptionCaller {

    uint8 res;
    gtUint8 handle;
    uint8 new_a;
    uint8 new_b;
    bool res_transfer;

    function getRes() public view returns (uint8) {
        return res;
    }

    function getHandle() public view returns (gtUint8) {
        return handle;
    }

    function getResTransfer() public view returns (bool) {
        return res_transfer;
    }

    function getNewA() public view returns (uint8) {
        return new_a;
    }

    function getNewB() public view returns (uint8) {
        return new_b;
    }

    function init() public {
        res = 0;
        new_a = 0;
        new_b = 0;
        res_transfer = false;
    }

    function combineEnumsToBytes3(MpcCore.MPC_TYPE mpcType1, MpcCore.MPC_TYPE mpcType2, uint8 argsType) internal pure returns (bytes3) {
        return bytes3(uint24(mpcType1) << 16 | uint16(mpcType2) << 8 | argsType);
    }

    function combineEnumsToBytes5(uint8 mpcType1, MpcCore.MPC_TYPE mpcType2, MpcCore.MPC_TYPE mpcType3, MpcCore.MPC_TYPE mpcType4, MpcCore.ARGS argsType) internal pure returns (bytes5) {
        return bytes5(uint40(mpcType1) << 32 | uint32(mpcType2) << 24 | uint24(mpcType3) << 16 | uint16(mpcType4) << 8 | uint8(argsType));
    }

    function combineEnumsToBytes5(MpcCore.MPC_TYPE mpcType1, uint8 mpcType2, MpcCore.MPC_TYPE mpcType3, MpcCore.MPC_TYPE mpcType4, MpcCore.ARGS argsType) internal pure returns (bytes5) {
        return bytes5(uint40(mpcType1) << 32 | uint32(mpcType2) << 24 | uint24(mpcType3) << 16 | uint16(mpcType4) << 8 | uint8(argsType));
    }

    function combineEnumsToBytes5(MpcCore.MPC_TYPE mpcType1, MpcCore.MPC_TYPE mpcType2, uint8 mpcType3, MpcCore.MPC_TYPE mpcType4, MpcCore.ARGS argsType) internal pure returns (bytes5) {
        return bytes5(uint40(mpcType1) << 32 | uint32(mpcType2) << 24 | uint24(mpcType3) << 16 | uint16(mpcType4) << 8 | uint8(argsType));
    }

    function combineEnumsToBytes5(MpcCore.MPC_TYPE mpcType1, MpcCore.MPC_TYPE mpcType2, MpcCore.MPC_TYPE mpcType3, uint8 mpcType4, MpcCore.ARGS argsType) internal pure returns (bytes5) {
        return bytes5(uint40(mpcType1) << 32 | uint32(mpcType2) << 24 | uint24(mpcType3) << 16 | uint16(mpcType4) << 8 | uint8(argsType));
    }

    function setPublic8_return16(uint8 pt) internal returns (gtUint16) {
          return gtUint16.wrap(GCExtendedOperations(address(GCExtendedOperationsAddress)).
            SetPublic(bytes1(uint8(MpcCore.MPC_TYPE.SUINT8_T)), uint256(pt)));
    }

    function setPublic16_return8(uint16 pt) internal returns (gtUint8) {
          return gtUint8.wrap(GCExtendedOperations(address(GCExtendedOperationsAddress)).
            SetPublic(bytes1(uint8(MpcCore.MPC_TYPE.SUINT16_T)), uint256(pt)));
    }

    function addMixBitSize() public returns (gtUint8) {
        // This function tests malformed input size for the add function - bool instead of uint8 in the second metadata argument
        
        // Add with boolean and uint8 bit sizes
        gtUint8 a = MpcCore.setPublic8(10);
        gtUint8 b = MpcCore.setPublic8(10);
        return gtUint8.wrap(GCExtendedOperations(address(GCExtendedOperationsAddress)).
            Add(MpcCore.combineEnumsToBytes3(MpcCore.MPC_TYPE.SUINT8_T, MpcCore.MPC_TYPE.SBOOL_T, MpcCore.ARGS.BOTH_SECRET), gtUint8.unwrap(a), gtUint8.unwrap(b)));
    }

    function malformedInput() public {
        // This function tests malformed input size for the add function - input of wrong size (8 bits instead of 16 bits)
        uint16 a = 5;
        gtUint8 gtA = setPublic16_return8(a);
        gtUint8 res = MpcCore.add(gtA, gtA);
    }

    function addWrongType() public returns (gtUint8) {
        // Add with invalid type
        gtUint8 a = MpcCore.setPublic8(10);
        gtUint8 b = MpcCore.setPublic8(10);
        return gtUint8.wrap(GCExtendedOperations(address(GCExtendedOperationsAddress)).
            Add(combineEnumsToBytes3(MpcCore.MPC_TYPE.SUINT8_T, MpcCore.MPC_TYPE.SUINT8_T, 6), gtUint8.unwrap(a), gtUint8.unwrap(b)));
    }

    function transferWrongBalance0BitSize() public {
        // Transfer with wrong bit size in the first balance
        gtUint8 a = MpcCore.setPublic8(10);
        gtUint8 b = MpcCore.setPublic8(10);
        gtUint8 amount = MpcCore.setPublic8(2);
        gtUint8 allowance = MpcCore.setPublic8(10);
        (uint256 new_a, uint256 new_b, uint256 res, uint256 new_allowance) = GCExtendedOperations(address(GCExtendedOperationsAddress)).
            TransferWithAllowance(combineEnumsToBytes5(17, MpcCore.MPC_TYPE.SUINT8_T, MpcCore.MPC_TYPE.SUINT8_T, MpcCore.MPC_TYPE.SUINT8_T, 
            MpcCore.ARGS.BOTH_SECRET), gtUint8.unwrap(a), gtUint8.unwrap(b), gtUint8.unwrap(amount), gtUint8.unwrap(allowance));
    }

    function transferWrongBalance1BitSize() public {
        // Transfer with wrong bit size in the second balance
        gtUint8 a = MpcCore.setPublic8(10);
        gtUint8 b = MpcCore.setPublic8(10);
        gtUint8 amount = MpcCore.setPublic8(2);
        gtUint8 allowance = MpcCore.setPublic8(10);
        (uint256 new_a, uint256 new_b, uint256 res, uint256 new_allowance) = GCExtendedOperations(address(GCExtendedOperationsAddress)).
            TransferWithAllowance(combineEnumsToBytes5(MpcCore.MPC_TYPE.SUINT8_T, 10, MpcCore.MPC_TYPE.SUINT8_T, MpcCore.MPC_TYPE.SUINT8_T, 
            MpcCore.ARGS.BOTH_SECRET), gtUint8.unwrap(a), gtUint8.unwrap(b), gtUint8.unwrap(amount), gtUint8.unwrap(allowance));
    }

    function transferWrongAmountBitSize() public {
        // Transfer with wrong bit size in the amount
        gtUint8 a = MpcCore.setPublic8(10);
        gtUint8 b = MpcCore.setPublic8(10);
        gtUint8 amount = MpcCore.setPublic8(2);
        gtUint8 allowance = MpcCore.setPublic8(10);
        (uint256 new_a, uint256 new_b, uint256 res, uint256 new_allowance) =  GCExtendedOperations(address(GCExtendedOperationsAddress)).
            TransferWithAllowance(combineEnumsToBytes5(MpcCore.MPC_TYPE.SUINT8_T, MpcCore.MPC_TYPE.SUINT8_T, 20, MpcCore.MPC_TYPE.SUINT8_T, 
            MpcCore.ARGS.BOTH_SECRET), gtUint8.unwrap(a), gtUint8.unwrap(b), gtUint8.unwrap(amount), gtUint8.unwrap(allowance));
    }

    function transferWrongAllowanceBitSize() public {
        // Transfer with wrong bit size in the allowance
        gtUint8 a = MpcCore.setPublic8(10);
        gtUint8 b = MpcCore.setPublic8(10);
        gtUint8 amount = MpcCore.setPublic8(2);
        gtUint8 allowance = MpcCore.setPublic8(10);
        (uint256 new_a, uint256 new_b, uint256 res, uint256 new_allowance) = GCExtendedOperations(address(GCExtendedOperationsAddress)).
            TransferWithAllowance(combineEnumsToBytes5(MpcCore.MPC_TYPE.SUINT8_T, MpcCore.MPC_TYPE.SUINT8_T, MpcCore.MPC_TYPE.SUINT8_T, 
            50, MpcCore.ARGS.BOTH_SECRET), gtUint8.unwrap(a), gtUint8.unwrap(b), gtUint8.unwrap(amount), gtUint8.unwrap(allowance));
    }

    function shlWrongType() public returns (gtUint8) {
        // Shift left with invalid type (should be RHS_PUBLIC)
        gtUint8 a = MpcCore.setPublic8(10);
        uint8 b = 2;
        return gtUint8.wrap(GCExtendedOperations(address(GCExtendedOperationsAddress)).
            Shl(MpcCore.combineEnumsToBytes3(MpcCore.MPC_TYPE.SUINT8_T, MpcCore.MPC_TYPE.SUINT8_T, MpcCore.ARGS.BOTH_SECRET), gtUint8.unwrap(a), uint256(b)));
    }

    function addMalformedScalarR() public returns (gtUint8) {
        // Add with scalar value bigger than 255 (should be uint8) in the second argument
        gtUint8 a = MpcCore.setPublic8(10);
        return gtUint8.wrap(GCExtendedOperations(address(GCExtendedOperationsAddress)).
            Add(MpcCore.combineEnumsToBytes3(MpcCore.MPC_TYPE.SUINT8_T, MpcCore.MPC_TYPE.SUINT8_T, MpcCore.ARGS.RHS_PUBLIC), gtUint8.unwrap(a), uint256(500)));
    }

    function addMalformedScalarL() public returns (gtUint8) {
        // Add with scalar value bigger than 255 (should be uint8) in the first argument
        gtUint8 a = MpcCore.setPublic8(10);
        return gtUint8.wrap(GCExtendedOperations(address(GCExtendedOperationsAddress)).
            Add(MpcCore.combineEnumsToBytes3(MpcCore.MPC_TYPE.SUINT8_T, MpcCore.MPC_TYPE.SUINT8_T, MpcCore.ARGS.LHS_PUBLIC), uint256(500), gtUint8.unwrap(a)));
    }

    function muxMalformedScalarR() public returns (gtUint8) {
        // Mux with scalar value bigger than 255 (should be uint8) in the third argument
        gtUint8 a = MpcCore.setPublic8(10);
        gtBool bit = MpcCore.setPublic(true);
        return gtUint8.wrap(GCExtendedOperations(address(GCExtendedOperationsAddress)).
            Mux(MpcCore.combineEnumsToBytes3(MpcCore.MPC_TYPE.SUINT8_T, MpcCore.MPC_TYPE.SUINT8_T, MpcCore.ARGS.RHS_PUBLIC), gtBool.unwrap(bit), gtUint8.unwrap(a), uint256(500)));
    }

    function muxMalformedScalarL() public returns (gtUint8) {
        // Mux with scalar value bigger than 255 (should be uint8) in the second argument
        gtUint8 a = MpcCore.setPublic8(10);
        gtBool bit = MpcCore.setPublic(true);
        return gtUint8.wrap(GCExtendedOperations(address(GCExtendedOperationsAddress)).
            Mux(MpcCore.combineEnumsToBytes3(MpcCore.MPC_TYPE.SUINT8_T, MpcCore.MPC_TYPE.SUINT8_T, MpcCore.ARGS.LHS_PUBLIC), gtBool.unwrap(bit), uint256(500), gtUint8.unwrap(a)));
    }

    function transferMalformedScalar() public  {
        // Transfer with scalar value bigger than 255 (should be uint8) in the amount
        gtUint8 a = MpcCore.setPublic8(10);
        gtUint8 b = MpcCore.setPublic8(10);
        (uint256 new_a, uint256 new_b, uint256 res) = GCExtendedOperations(address(GCExtendedOperationsAddress)).
            Transfer(MpcCore.combineEnumsToBytes4(MpcCore.MPC_TYPE.SUINT8_T, MpcCore.MPC_TYPE.SUINT8_T, MpcCore.MPC_TYPE.SUINT8_T, MpcCore.ARGS.LHS_PUBLIC), gtUint8.unwrap(a), gtUint8.unwrap(b), uint256(500));
    }

    function setPublicWithGTValue() public {
        // Set public with GT value (should be uint8)
        gtUint8 a = MpcCore.setPublic8(10);
        gtUint8.wrap(GCExtendedOperations(address(GCExtendedOperationsAddress)).
            SetPublic(bytes1(uint8(MpcCore.MPC_TYPE.SUINT8_T)), gtUint8.unwrap(a)));
    }

    function addWithBoolean() public returns (gtUint8) {
        // Add with boolean values (no such circuit)
        gtBool a = MpcCore.setPublic(true);
        gtBool b = MpcCore.setPublic(true);
        return gtUint8.wrap(GCExtendedOperations(address(GCExtendedOperationsAddress)).
            Add(MpcCore.combineEnumsToBytes3(MpcCore.MPC_TYPE.SBOOL_T, MpcCore.MPC_TYPE.SBOOL_T, MpcCore.ARGS.BOTH_SECRET), gtBool.unwrap(a), gtBool.unwrap(b)));
    }

    function notWithInt() public returns (gtBool) {
        // Not with int value (no such circuit)
        gtUint8 a = MpcCore.setPublic8(10);
        return gtBool.wrap(GCExtendedOperations(address(GCExtendedOperationsAddress)).
            Not(bytes1(uint8(MpcCore.MPC_TYPE.SUINT8_T)), gtUint8.unwrap(a)));
    }

    function nonExistingGTValue() public returns (gtBool) {
        // Call not function with non-existing GT value
        return gtBool.wrap(GCExtendedOperations(address(GCExtendedOperationsAddress)).
            Not(bytes1(uint8(MpcCore.MPC_TYPE.SBOOL_T)), uint256(500)));
    }

    function divisionByZero() public returns (gtUint8) {
        // Call Division by zero
        gtUint8 a = MpcCore.setPublic8(10);
        gtUint8 b = MpcCore.setPublic8(0);
        gtUint8 res = gtUint8.wrap(GCExtendedOperations(address(GCExtendedOperationsAddress)).
            Div(MpcCore.combineEnumsToBytes3(MpcCore.MPC_TYPE.SUINT8_T, MpcCore.MPC_TYPE.SUINT8_T, MpcCore.ARGS.BOTH_SECRET), gtUint8.unwrap(a), gtUint8.unwrap(b)));

        return res;
    }

    function amountBiggerThanBalance() public  {
        // Call Transfer with amount bigger than balance
        gtUint8 a = MpcCore.setPublic8(10);
        gtUint8 b = MpcCore.setPublic8(10);
        gtUint8 amount = MpcCore.setPublic8(11);
        (gtUint8 new_a, gtUint8 new_b, gtBool res_transfer) = MpcCore.transfer(a, b, amount);

        uint256[] memory arr = new uint256[](3);
        arr[0] = gtUint8.unwrap(new_a);
        arr[1] = gtUint8.unwrap(new_b);
        arr[2] = gtBool.unwrap(res_transfer);

        requestDecryption(arr, this.callbackTransfer.selector);
    }

    function callbackTransfer(uint256 decryptID, bytes[] calldata output, bytes calldata signature) public {
        // Handle the callback from the MPC core
        if (checkCallbackHandles(decryptID, output.length)) {
            new_a = abi.decode(output[0], (uint8)); 
            new_b = abi.decode(output[1], (uint8)); 
            res_transfer = abi.decode(output[2], (bool)); 
        } 
    }

    function handleNotExisting() public {
        // This function tests malformed input handle for the add function - non-existing handle
        uint256 temp = 10;
        gtUint8 handle = gtUint8.wrap(temp);
        gtUint8 res = MpcCore.add(handle, handle);
    }

    function handleNotPermitted_create() public {
        // This function creates an handle but not permit it
        handle = MpcCore.setPublic8(22);
    }

    function handleNotPermitted_use() public {
        // This function tests malformed input handle for the add function - handle not permitted
        gtUint8 res = MpcCore.add(handle, handle);
    }

    function checkProgress() public {
        // This function used to check if the chain is progressing - if there is a callback from the MPC core it means that the chain is progressing
        gtUint8 a = MpcCore.setPublic8(10);
        gtUint8 b = MpcCore.setPublic8(10);
        gtUint8 add = MpcCore.add(a, b);

        uint256[] memory arr = new uint256[](1);
        arr[0] = gtUint8.unwrap(add);

        requestDecryption(arr, this.callback.selector);
    }

    function callback(uint256 decryptID, bytes[] calldata output, bytes calldata signature) public {
        // Handle the callback from the MPC core
        if (checkCallbackHandles(decryptID, output.length)) {
            res = abi.decode(output[0], (uint8)); 
        } 
    }
    
}