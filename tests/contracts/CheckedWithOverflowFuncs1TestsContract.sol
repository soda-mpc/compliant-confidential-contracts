// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "MpcCore.sol";
import "../../lib/onchain/contracts/DecryptionCaller.sol";

contract CheckedWithOverflowFuncs1TestsContract is DecryptionCaller {

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

    bool mulDecrypted;
    bool mulOverflowDecrypted;

    uint8 mulResult;
    bool mulOverflowBit;
    bool mulOverflow;

    function isMulDecrypted() public view returns (bool) {
        return mulDecrypted;
    }
    function isMulOverflowDecrypted() public view returns (bool) {
        return mulOverflowDecrypted;
    }

    function resetStates() public {
        mulDecrypted = false;
        mulOverflowDecrypted = false;
    }

    function getMulResult() public view returns (uint8) {
        return mulResult;
    }

    function getMulOverflowBit() public view returns (bool) {
        return mulOverflowBit;
    }

    function getMulOverflow() public view returns (bool) {
        return mulOverflow;
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

    function checkedMulWithOverflowBitTest(uint8 a, uint8 b) public returns (uint256) {
        AllGTCastingValues memory castingValues;
        setPublicValues(castingValues, a, b);

        // Cumpute all multiplication operations and put the result handles in an array
        uint256[] memory arrToDecrypt = new uint256[](96);
        
        // Compute uint8 operations
        (gtBool overflowBit, gtUint8 res) = MpcCore.checkedMulWithOverflowBit(castingValues.a8_s, castingValues.b8_s);
        arrToDecrypt[0] = gtBool.unwrap(overflowBit);
        arrToDecrypt[1] = gtUint8.unwrap(res);
    
        // Compute uint16 operations
        gtUint16 res16;
        (overflowBit, res16) = MpcCore.checkedMulWithOverflowBit(castingValues.a16_s, castingValues.b16_s);
        arrToDecrypt[2] = gtBool.unwrap(overflowBit);
        arrToDecrypt[3] = gtUint16.unwrap(res16);
        (overflowBit, res16) = MpcCore.checkedMulWithOverflowBit(castingValues.a8_s, castingValues.b16_s);
        arrToDecrypt[4] = gtBool.unwrap(overflowBit);
        arrToDecrypt[5] = gtUint16.unwrap(res16);
        (overflowBit, res16) = MpcCore.checkedMulWithOverflowBit(castingValues.a16_s, castingValues.b8_s);
        arrToDecrypt[6] = gtBool.unwrap(overflowBit);
        arrToDecrypt[7] = gtUint16.unwrap(res16);

        // Compute uint32 operations
        gtUint32 res32;
        (overflowBit, res32) = MpcCore.checkedMulWithOverflowBit(castingValues.a32_s, castingValues.b32_s);
        arrToDecrypt[8] = gtBool.unwrap(overflowBit);
        arrToDecrypt[9] = gtUint32.unwrap(res32);
        (overflowBit, res32) = MpcCore.checkedMulWithOverflowBit(castingValues.a8_s, castingValues.b32_s);
        arrToDecrypt[10] = gtBool.unwrap(overflowBit);
        arrToDecrypt[11] = gtUint32.unwrap(res32);
        (overflowBit, res32) = MpcCore.checkedMulWithOverflowBit(castingValues.a32_s, castingValues.b8_s);
        arrToDecrypt[12] = gtBool.unwrap(overflowBit);
        arrToDecrypt[13] = gtUint32.unwrap(res32);
        (overflowBit, res32) = MpcCore.checkedMulWithOverflowBit(castingValues.a32_s, castingValues.b16_s);
        arrToDecrypt[14] = gtBool.unwrap(overflowBit);
        arrToDecrypt[15] = gtUint32.unwrap(res32);
        (overflowBit, res32) = MpcCore.checkedMulWithOverflowBit(castingValues.a16_s, castingValues.b32_s);
        arrToDecrypt[16] = gtBool.unwrap(overflowBit);
        arrToDecrypt[17] = gtUint32.unwrap(res32);

        // Compute uint64 operations
        gtUint64 res64;
        (overflowBit, res64) = MpcCore.checkedMulWithOverflowBit(castingValues.a64_s, castingValues.b64_s);
        arrToDecrypt[18] = gtBool.unwrap(overflowBit);
        arrToDecrypt[19] = gtUint64.unwrap(res64);
        (overflowBit, res64) = MpcCore.checkedMulWithOverflowBit(castingValues.a8_s, castingValues.b64_s);
        arrToDecrypt[20] = gtBool.unwrap(overflowBit);
        arrToDecrypt[21] = gtUint64.unwrap(res64);
        (overflowBit, res64) = MpcCore.checkedMulWithOverflowBit(castingValues.a64_s, castingValues.b8_s);
        arrToDecrypt[22] = gtBool.unwrap(overflowBit);
        arrToDecrypt[23] = gtUint64.unwrap(res64);
        (overflowBit, res64) = MpcCore.checkedMulWithOverflowBit(castingValues.a64_s, castingValues.b16_s);
        arrToDecrypt[24] = gtBool.unwrap(overflowBit);
        arrToDecrypt[25] = gtUint64.unwrap(res64);
        (overflowBit, res64) = MpcCore.checkedMulWithOverflowBit(castingValues.a16_s, castingValues.b64_s);
        arrToDecrypt[26] = gtBool.unwrap(overflowBit);
        arrToDecrypt[27] = gtUint64.unwrap(res64);
        (overflowBit, res64) = MpcCore.checkedMulWithOverflowBit(castingValues.a64_s, castingValues.b32_s);
        arrToDecrypt[28] = gtBool.unwrap(overflowBit);  
        arrToDecrypt[29] = gtUint64.unwrap(res64);
        (overflowBit, res64) = MpcCore.checkedMulWithOverflowBit(castingValues.a32_s, castingValues.b64_s);
        arrToDecrypt[30] = gtBool.unwrap(overflowBit);
        arrToDecrypt[31] = gtUint64.unwrap(res64);

        // Compute uint128 operations
        gtUint128 res128;
        (overflowBit, res128) = MpcCore.checkedMulWithOverflowBit(castingValues.a128_s, castingValues.b128_s);
        arrToDecrypt[32] = gtBool.unwrap(overflowBit);
        arrToDecrypt[33] = gtUint128.unwrap(res128);
        (overflowBit, res128) = MpcCore.checkedMulWithOverflowBit(castingValues.a8_s, castingValues.b128_s);
        arrToDecrypt[34] = gtBool.unwrap(overflowBit);
        arrToDecrypt[35] = gtUint128.unwrap(res128);
        (overflowBit, res128) = MpcCore.checkedMulWithOverflowBit(castingValues.a128_s, castingValues.b8_s);
        arrToDecrypt[36] = gtBool.unwrap(overflowBit);
        arrToDecrypt[37] = gtUint128.unwrap(res128);
        (overflowBit, res128) = MpcCore.checkedMulWithOverflowBit(castingValues.a128_s, castingValues.b16_s);
        arrToDecrypt[38] = gtBool.unwrap(overflowBit);
        arrToDecrypt[39] = gtUint128.unwrap(res128);
        (overflowBit, res128) = MpcCore.checkedMulWithOverflowBit(castingValues.a16_s, castingValues.b128_s);
        arrToDecrypt[40] = gtBool.unwrap(overflowBit);
        arrToDecrypt[41] = gtUint128.unwrap(res128);
        (overflowBit, res128) = MpcCore.checkedMulWithOverflowBit(castingValues.a128_s, castingValues.b32_s);
        arrToDecrypt[42] = gtBool.unwrap(overflowBit);  
        arrToDecrypt[43] = gtUint128.unwrap(res128);
        (overflowBit, res128) = MpcCore.checkedMulWithOverflowBit(castingValues.a32_s, castingValues.b128_s);
        arrToDecrypt[44] = gtBool.unwrap(overflowBit);
        arrToDecrypt[45] = gtUint128.unwrap(res128);
        (overflowBit, res128) = MpcCore.checkedMulWithOverflowBit(castingValues.a128_s, castingValues.b64_s);
        arrToDecrypt[46] = gtBool.unwrap(overflowBit);  
        arrToDecrypt[47] = gtUint128.unwrap(res128);
        (overflowBit, res128) = MpcCore.checkedMulWithOverflowBit(castingValues.a64_s, castingValues.b128_s);
        arrToDecrypt[48] = gtBool.unwrap(overflowBit);
        arrToDecrypt[49] = gtUint128.unwrap(res128);

        // Compute uint256 operations   
        gtUint256 res256;
        (overflowBit, res256) = MpcCore.checkedMulWithOverflowBit(castingValues.a256_s, castingValues.b256_s);
        arrToDecrypt[50] = gtBool.unwrap(overflowBit);
        arrToDecrypt[51] = gtUint256.unwrap(res256);
        (overflowBit, res256) = MpcCore.checkedMulWithOverflowBit(castingValues.a8_s, castingValues.b256_s);
        arrToDecrypt[52] = gtBool.unwrap(overflowBit);
        arrToDecrypt[53] = gtUint256.unwrap(res256);
        (overflowBit, res256) = MpcCore.checkedMulWithOverflowBit(castingValues.a256_s, castingValues.b8_s);
        arrToDecrypt[54] = gtBool.unwrap(overflowBit);
        arrToDecrypt[55] = gtUint256.unwrap(res256);
        (overflowBit, res256) = MpcCore.checkedMulWithOverflowBit(castingValues.a16_s, castingValues.b256_s);
        arrToDecrypt[56] = gtBool.unwrap(overflowBit);
        arrToDecrypt[57] = gtUint256.unwrap(res256);
        (overflowBit, res256) = MpcCore.checkedMulWithOverflowBit(castingValues.a256_s, castingValues.b16_s);
        arrToDecrypt[58] = gtBool.unwrap(overflowBit);
        arrToDecrypt[59] = gtUint256.unwrap(res256);
        (overflowBit, res256) = MpcCore.checkedMulWithOverflowBit(castingValues.a32_s, castingValues.b256_s);
        arrToDecrypt[60] = gtBool.unwrap(overflowBit);
        arrToDecrypt[61] = gtUint256.unwrap(res256);
        (overflowBit, res256) = MpcCore.checkedMulWithOverflowBit(castingValues.a256_s, castingValues.b32_s);
        arrToDecrypt[62] = gtBool.unwrap(overflowBit);
        arrToDecrypt[63] = gtUint256.unwrap(res256);
        (overflowBit, res256) = MpcCore.checkedMulWithOverflowBit(castingValues.a64_s, castingValues.b256_s);
        arrToDecrypt[64] = gtBool.unwrap(overflowBit);
        arrToDecrypt[65] = gtUint256.unwrap(res256);
        (overflowBit, res256) = MpcCore.checkedMulWithOverflowBit(castingValues.a256_s, castingValues.b64_s);
        arrToDecrypt[66] = gtBool.unwrap(overflowBit);
        arrToDecrypt[67] = gtUint256.unwrap(res256);
        (overflowBit, res256) = MpcCore.checkedMulWithOverflowBit(castingValues.a128_s, castingValues.b256_s);
        arrToDecrypt[68] = gtBool.unwrap(overflowBit);
        arrToDecrypt[69] = gtUint256.unwrap(res256);
        (overflowBit, res256) = MpcCore.checkedMulWithOverflowBit(castingValues.a256_s, castingValues.b128_s);
        arrToDecrypt[70] = gtBool.unwrap(overflowBit);
        arrToDecrypt[71] = gtUint256.unwrap(res256);

        // Compute operations with scalar
        (overflowBit, res) = MpcCore.checkedMulWithOverflowBit(a, castingValues.b8_s);
        arrToDecrypt[72] = gtBool.unwrap(overflowBit);
        arrToDecrypt[73] = gtUint8.unwrap(res);
        (overflowBit, res) = MpcCore.checkedMulWithOverflowBit(castingValues.a8_s, b);
        arrToDecrypt[74] = gtBool.unwrap(overflowBit);
        arrToDecrypt[75] = gtUint8.unwrap(res);
        (overflowBit, res16) = MpcCore.checkedMulWithOverflowBit(a, castingValues.b16_s);
        arrToDecrypt[76] = gtBool.unwrap(overflowBit);
        arrToDecrypt[77] = gtUint16.unwrap(res16);
        (overflowBit, res16) = MpcCore.checkedMulWithOverflowBit(castingValues.a16_s, b);
        arrToDecrypt[78] = gtBool.unwrap(overflowBit);
        arrToDecrypt[79] = gtUint16.unwrap(res16);
        (overflowBit, res32) = MpcCore.checkedMulWithOverflowBit(a, castingValues.b32_s);
        arrToDecrypt[80] = gtBool.unwrap(overflowBit);
        arrToDecrypt[81] = gtUint32.unwrap(res32);
        (overflowBit, res32) = MpcCore.checkedMulWithOverflowBit(castingValues.a32_s, b);
        arrToDecrypt[82] = gtBool.unwrap(overflowBit);
        arrToDecrypt[83] = gtUint32.unwrap(res32);
        (overflowBit, res64) = MpcCore.checkedMulWithOverflowBit(a, castingValues.b64_s);
        arrToDecrypt[84] = gtBool.unwrap(overflowBit);
        arrToDecrypt[85] = gtUint64.unwrap(res64);
        (overflowBit, res64) = MpcCore.checkedMulWithOverflowBit(castingValues.a64_s, b);
        arrToDecrypt[86] = gtBool.unwrap(overflowBit);
        arrToDecrypt[87] = gtUint64.unwrap(res64);
        (overflowBit, res128) = MpcCore.checkedMulWithOverflowBit(castingValues.a128_s, b);
        arrToDecrypt[88] = gtBool.unwrap(overflowBit);
        arrToDecrypt[89] = gtUint128.unwrap(res128);
        (overflowBit, res128) = MpcCore.checkedMulWithOverflowBit(a, castingValues.b128_s);
        arrToDecrypt[90] = gtBool.unwrap(overflowBit);
        arrToDecrypt[91] = gtUint128.unwrap(res128);
        (overflowBit, res256) = MpcCore.checkedMulWithOverflowBit(castingValues.a256_s, b);
        arrToDecrypt[92] = gtBool.unwrap(overflowBit);
        arrToDecrypt[93] = gtUint256.unwrap(res256);
        (overflowBit, res256) = MpcCore.checkedMulWithOverflowBit(a, castingValues.b256_s);
        arrToDecrypt[94] = gtBool.unwrap(overflowBit);
        arrToDecrypt[95] = gtUint256.unwrap(res256);

        return requestDecryption(arrToDecrypt, this.checkMulResults.selector);
    }

    function checkMulResults(uint256 decryptID, bytes[] calldata output, bytes[] calldata signatures) public verifyCallback(decryptID, output, signatures){
        bool firstOverflowBit = abi.decode(output[0], (bool));
        uint8 firstResult = abi.decode(output[1], (uint8));
        for (uint256 i = 2; i < output.length; i+=2) {
            bool overflowBit = abi.decode(output[i], (bool));
            uint8 result = abi.decode(output[i+1], (uint8));

            require(overflowBit == firstOverflowBit, "checkMulResults: Invalid overflow bit");
            require(result == firstResult, "checkMulResults: Invalid output");
        }

        mulDecrypted = true;
        mulResult = firstResult;
        mulOverflowBit = firstOverflowBit;
    }

    // This test is used to check cases where the multiplication of two numbers will overflow
    function checkedMulOverflowTest(uint8 a, uint8 b, uint16 a16, uint16 b16, uint32 a32, uint32 b32, uint64 a64, uint64 b64, uint128 a128, uint128 b128, uint256 a256, uint256 b256) public returns (uint256) {
        gtUint8 a_s = MpcCore.setPublic8(a);
        gtUint8 b_s = MpcCore.setPublic8(b);

        gtUint16 a_s16 = MpcCore.setPublic16(a16);
        gtUint16 b_s16 = MpcCore.setPublic16(b16);

        gtUint32 a_s32 = MpcCore.setPublic32(a32);
        gtUint32 b_s32 = MpcCore.setPublic32(b32);

        gtUint64 a_s64 = MpcCore.setPublic64(a64);
        gtUint64 b_s64 = MpcCore.setPublic64(b64);

        gtUint128 a_s128 = MpcCore.setPublic128(a128);
        gtUint128 b_s128 = MpcCore.setPublic128(b128);

        gtUint256 a_s256 = MpcCore.setPublic256(a256);
        gtUint256 b_s256 = MpcCore.setPublic256(b256);
        
        // Calculate addition with overflow for all sizes
        (gtBool overflowBit8, gtUint8 res) = MpcCore.checkedMulWithOverflowBit(a_s, b_s);
        (gtBool overflowBit16, gtUint16 res16) = MpcCore.checkedMulWithOverflowBit(a_s16, b_s16);
        (gtBool overflowBit32, gtUint32 res32) = MpcCore.checkedMulWithOverflowBit(a_s32, b_s32);
        (gtBool overflowBit64, gtUint64 res64) = MpcCore.checkedMulWithOverflowBit(a_s64, b_s64);
        (gtBool overflowBit128, gtUint128 res128) = MpcCore.checkedMulWithOverflowBit(a_s128, b_s128);
        (gtBool overflowBit256, gtUint256 res256) = MpcCore.checkedMulWithOverflowBit(a_s256, b_s256);

        // Put the result handles in an array
        uint256[] memory arrToDecrypt = new uint256[](6);
        arrToDecrypt[0] = gtBool.unwrap(overflowBit8);
        arrToDecrypt[1] = gtBool.unwrap(overflowBit16);
        arrToDecrypt[2] = gtBool.unwrap(overflowBit32);
        arrToDecrypt[3] = gtBool.unwrap(overflowBit64);
        arrToDecrypt[4] = gtBool.unwrap(overflowBit128);
        arrToDecrypt[5] = gtBool.unwrap(overflowBit256);

        return requestDecryption(arrToDecrypt, this.checkMulOverflowResults.selector);
    }

    function checkMulOverflowResults(uint256 decryptID, bytes[] calldata output, bytes[] calldata signatures) public verifyCallback(decryptID, output, signatures){
        bool firstOverflowBit = abi.decode(output[0], (bool));
        for (uint256 i = 1; i < output.length; i++) {
            bool overflowBit = abi.decode(output[i], (bool));
            require(overflowBit == firstOverflowBit, "checkMulOverflowResults: Invalid overflow bit");
        }

        mulOverflowDecrypted = true;
        mulOverflow = firstOverflowBit;
    }
}