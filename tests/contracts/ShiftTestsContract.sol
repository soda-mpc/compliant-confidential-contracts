// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "MpcCore.sol";   
import "../../lib/onchain/contracts/DecryptionCaller.sol";

contract ShiftTestsContract is DecryptionCaller {

    struct AllGTCastingValues {
        gtUint8 a8_s;
        gtUint8 b8_s;
        gtUint16 a16_s;
        gtUint16 b16_s;
        gtUint32 a32_s;
        gtUint32 b32_s;
        gtUint64 a64_s;
        gtUint64 b64_s;
        gtUint128 a128_s;
        gtUint128 b128_s;
        gtUint256 a256_s;
        gtUint256 b256_s;
    }

    bool shlDecrypted;
    bool shrDecrypted;

    uint8 result;
    uint8 result8;
    uint16 result16;
    uint32 result32;
    uint64 result64;
    uint128 result128;
    uint256 result256;

    function isShlDecrypted() public view returns (bool) {
        return shlDecrypted;
    }

    function isShrDecrypted() public view returns (bool) {
        return shrDecrypted;
    }

    function getSHRResult() public view returns (uint8) {
        return result;
    }

    function getSHLResultUint8() public view returns (uint8) {
        return result8;
    }

    function getSHLResultUint16() public view returns (uint16) {
        return result16;
    }

    function getSHLResultUint32() public view returns (uint32) {
        return result32;
    }

    function getSHLResultUint64() public view returns (uint64) {
        return result64;
    }

    function getSHLResultUint128() public view returns (uint128) {
        return result128;
    }

    function getSHLResultUint256() public view returns (uint256) {
        return result256;
    }

    function resetStates() public {
        shlDecrypted = false;
        shrDecrypted = false;
    }

    function setPublicValues(AllGTCastingValues memory castingValues, uint8 a, uint8 b) public{
        castingValues.a8_s = MpcCore.setPublic8(a);
        castingValues.b8_s = MpcCore.setPublic8(b);
        castingValues.a16_s =  MpcCore.setPublic16(a);
        castingValues.b16_s =  MpcCore.setPublic16(b);
        castingValues.a32_s =  MpcCore.setPublic32(a);
        castingValues.b32_s =  MpcCore.setPublic32(b);
        castingValues.a64_s =  MpcCore.setPublic64(a);
        castingValues.b64_s =  MpcCore.setPublic64(b);
        castingValues.a128_s =  MpcCore.setPublic128(a);
        castingValues.b128_s =  MpcCore.setPublic128(b);
        castingValues.a256_s =  MpcCore.setPublic256(a);
        castingValues.b256_s =  MpcCore.setPublic256(b);
    }

    function shlTest(uint8 a, uint8 b) public returns (uint256) {
        AllGTCastingValues memory castingValues;
        setPublicValues(castingValues, a, b);

        // Compute all operations and put the result handles in an array
        uint256[] memory arrToDecrypt = new uint256[](6);

        // Calculate the result with casting to 8
        arrToDecrypt[0] = gtUint8.unwrap(MpcCore.shl(castingValues.a8_s, b));
        arrToDecrypt[1] = gtUint16.unwrap(MpcCore.shl(castingValues.a16_s, b));
        arrToDecrypt[2] = gtUint32.unwrap(MpcCore.shl(castingValues.a32_s, b));
        arrToDecrypt[3] = gtUint64.unwrap(MpcCore.shl(castingValues.a64_s, b));
        arrToDecrypt[4] = gtUint128.unwrap(MpcCore.shl(castingValues.a128_s, b));
        arrToDecrypt[5] = gtUint256.unwrap(MpcCore.shl(castingValues.a256_s, b));

        return requestDecryption(arrToDecrypt, this.checkShlResults.selector); 
    } 

    function checkShlResults(uint256 decryptID, bytes[] calldata output, bytes calldata signature) public {
        require(checkCallbackHandles(decryptID, output.length), "checkShlResults: Invalid callback parameters");
        
        result8 = abi.decode(output[0], (uint8));
        result16 = abi.decode(output[1], (uint16));
        result32 = abi.decode(output[2], (uint32));
        result64 = abi.decode(output[3], (uint64));
        result128 = abi.decode(output[4], (uint128));
        result256 = abi.decode(output[5], (uint256));

        shlDecrypted = true;
    }

    function shrTest(uint8 a, uint8 b) public returns (uint256) {
        AllGTCastingValues memory castingValues;
        setPublicValues(castingValues, a, b);

        // Compute all operations and put the result handles in an array
        uint256[] memory arrToDecrypt = new uint256[](6);

        // Calculate the result with casting to 8
        arrToDecrypt[0] = gtUint8.unwrap(MpcCore.shr(castingValues.a8_s, b));
        arrToDecrypt[1] = gtUint16.unwrap(MpcCore.shr(castingValues.a16_s, b));
        arrToDecrypt[2] = gtUint32.unwrap(MpcCore.shr(castingValues.a32_s, b));
        arrToDecrypt[3] = gtUint64.unwrap(MpcCore.shr(castingValues.a64_s, b));
        arrToDecrypt[4] = gtUint128.unwrap(MpcCore.shr(castingValues.a128_s, b));
        arrToDecrypt[5] = gtUint256.unwrap(MpcCore.shr(castingValues.a256_s, b));
        
        return requestDecryption(arrToDecrypt, this.checkShrResults.selector); 
    } 

    function checkShrResults(uint256 decryptID, bytes[] calldata output, bytes calldata signature) public {
        require(checkCallbackHandles(decryptID, output.length), "checkShrResults: Invalid callback parameters");
        
        uint8 firstResult = abi.decode(output[0], (uint8));
        for (uint256 i = 1; i < output.length; i++) {
            uint8 result = abi.decode(output[i], (uint8));
            require(result == firstResult, "checkShrResults: Invalid output");
        }

        shrDecrypted = true;
        result = firstResult;
    } 

}