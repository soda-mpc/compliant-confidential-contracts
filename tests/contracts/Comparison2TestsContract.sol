// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "MpcCore.sol";
import "../../lib/onchain/contracts/DecryptionCaller.sol";

contract Comparison2TestsContract is DecryptionCaller {

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

    bool eqDecrypted;
    bool neDecrypted;
    
    bool eqResult;
    bool neResult;

    function isEqDecrypted() public view returns (bool) {
        return eqDecrypted;
    }

    function isNeDecrypted() public view returns (bool) {
        return neDecrypted;
    }

    function getEqResult() public view returns (bool) {
        return eqResult;
    }

    function getNeResult() public view returns (bool) {
        return neResult;
    }

    function resetStates() public {
        eqDecrypted = false;
        neDecrypted = false;
    }

    function eqTest(uint8 a, uint8 b) public returns (uint256) {
        AllGTCastingValues memory castingValues;
        setPublicValues(castingValues, a, b);
        
        // Cumpute all operations and put the result handles in an array
        uint256[] memory arrToDecrypt = new uint256[](48);

        // gtUint8 operations
        arrToDecrypt[0] = gtBool.unwrap(MpcCore.eq(castingValues.a8_s, castingValues.b8_s));

        // gtUint16 operations
        arrToDecrypt[1] = gtBool.unwrap(MpcCore.eq(castingValues.a16_s, castingValues.b16_s));
        arrToDecrypt[2] = gtBool.unwrap(MpcCore.eq(castingValues.a8_s, castingValues.b16_s));
        arrToDecrypt[3] = gtBool.unwrap(MpcCore.eq(castingValues.a16_s, castingValues.b8_s));

        // gtUint32 operations
        arrToDecrypt[4] = gtBool.unwrap(MpcCore.eq(castingValues.a32_s, castingValues.b32_s));
        arrToDecrypt[5] = gtBool.unwrap(MpcCore.eq(castingValues.a8_s, castingValues.b32_s));
        arrToDecrypt[6] = gtBool.unwrap(MpcCore.eq(castingValues.a32_s, castingValues.b8_s));
        arrToDecrypt[7] = gtBool.unwrap(MpcCore.eq(castingValues.a16_s, castingValues.b32_s));
        arrToDecrypt[8] = gtBool.unwrap(MpcCore.eq(castingValues.a32_s, castingValues.b16_s));

        // gtUint64 operations
        arrToDecrypt[9] = gtBool.unwrap(MpcCore.eq(castingValues.a64_s, castingValues.b64_s));
        arrToDecrypt[10] = gtBool.unwrap(MpcCore.eq(castingValues.a8_s, castingValues.b64_s));
        arrToDecrypt[11] = gtBool.unwrap(MpcCore.eq(castingValues.a64_s, castingValues.b8_s));
        arrToDecrypt[12] = gtBool.unwrap(MpcCore.eq(castingValues.a16_s, castingValues.b64_s));
        arrToDecrypt[13] = gtBool.unwrap(MpcCore.eq(castingValues.a64_s, castingValues.b16_s));
        arrToDecrypt[14] = gtBool.unwrap(MpcCore.eq(castingValues.a32_s, castingValues.b64_s));
        arrToDecrypt[15] = gtBool.unwrap(MpcCore.eq(castingValues.a64_s, castingValues.b32_s));

        // gtUint128
        arrToDecrypt[16] =  gtBool.unwrap(MpcCore.eq(castingValues.a128_s, castingValues.b128_s));
        arrToDecrypt[17] = gtBool.unwrap(MpcCore.eq(castingValues.a8_s, castingValues.b128_s));
        arrToDecrypt[18] = gtBool.unwrap(MpcCore.eq(castingValues.a128_s, castingValues.b8_s));
        arrToDecrypt[19] = gtBool.unwrap(MpcCore.eq(castingValues.a16_s, castingValues.b128_s));
        arrToDecrypt[20] = gtBool.unwrap(MpcCore.eq(castingValues.a128_s, castingValues.b16_s));
        arrToDecrypt[21] = gtBool.unwrap(MpcCore.eq(castingValues.a32_s, castingValues.b128_s));
        arrToDecrypt[22] = gtBool.unwrap(MpcCore.eq(castingValues.a128_s, castingValues.b32_s));
        arrToDecrypt[23] = gtBool.unwrap(MpcCore.eq(castingValues.a64_s, castingValues.b128_s));
        arrToDecrypt[24] = gtBool.unwrap(MpcCore.eq(castingValues.a128_s, castingValues.b64_s));
        
        // gtUint256
        arrToDecrypt[25] = gtBool.unwrap(MpcCore.eq(castingValues.a256_s, castingValues.b256_s));
        arrToDecrypt[26] = gtBool.unwrap(MpcCore.eq(castingValues.a8_s, castingValues.b256_s));
        arrToDecrypt[27] = gtBool.unwrap(MpcCore.eq(castingValues.a256_s, castingValues.b8_s));
        arrToDecrypt[28] = gtBool.unwrap(MpcCore.eq(castingValues.a16_s, castingValues.b256_s));
        arrToDecrypt[29] = gtBool.unwrap(MpcCore.eq(castingValues.a256_s, castingValues.b16_s));
        arrToDecrypt[30] = gtBool.unwrap(MpcCore.eq(castingValues.a32_s, castingValues.b256_s));
        arrToDecrypt[31] = gtBool.unwrap(MpcCore.eq(castingValues.a256_s, castingValues.b32_s));
        arrToDecrypt[32] = gtBool.unwrap(MpcCore.eq(castingValues.a64_s, castingValues.b256_s));
        arrToDecrypt[33] = gtBool.unwrap(MpcCore.eq(castingValues.a256_s, castingValues.b64_s));
        arrToDecrypt[34] = gtBool.unwrap(MpcCore.eq(castingValues.a128_s, castingValues.b256_s));
        arrToDecrypt[35] = gtBool.unwrap(MpcCore.eq(castingValues.a256_s, castingValues.b128_s));
        
        // eq with scalar
        arrToDecrypt[36] = gtBool.unwrap(MpcCore.eq(a, castingValues.b8_s));
        arrToDecrypt[37] = gtBool.unwrap(MpcCore.eq(castingValues.a8_s, b));
        arrToDecrypt[38] = gtBool.unwrap(MpcCore.eq(a, castingValues.b16_s));
        arrToDecrypt[39] = gtBool.unwrap(MpcCore.eq(castingValues.a16_s, b));
        arrToDecrypt[40] = gtBool.unwrap(MpcCore.eq(a, castingValues.b32_s));
        arrToDecrypt[41] = gtBool.unwrap(MpcCore.eq(castingValues.a32_s, b));
        arrToDecrypt[42] = gtBool.unwrap(MpcCore.eq(a, castingValues.b64_s));
        arrToDecrypt[43] = gtBool.unwrap(MpcCore.eq(castingValues.a64_s, b));
        arrToDecrypt[44] = gtBool.unwrap(MpcCore.eq(a, castingValues.b128_s));
        arrToDecrypt[45] = gtBool.unwrap(MpcCore.eq(castingValues.a128_s, b));
        arrToDecrypt[46] = gtBool.unwrap(MpcCore.eq(a, castingValues.b256_s));
        arrToDecrypt[47] = gtBool.unwrap(MpcCore.eq(castingValues.a256_s, b));

        return requestDecryption(arrToDecrypt, this.checkEqResults.selector);
    }

    function checkEqResults(uint256 decryptID, bytes[] calldata output, bytes[] calldata signatures) public verifyCallback(decryptID, output, signatures){
        bool firstResult = abi.decode(output[0], (bool));
        for (uint256 i = 1; i < output.length; i++) {
            bool result = abi.decode(output[i], (bool));
            require(result == firstResult, "checkEqResults: Invalid output");
        }

        eqDecrypted = true;
        eqResult = firstResult;
    }

    function neTest(uint8 a, uint8 b) public returns (uint256) {
        AllGTCastingValues memory castingValues;
        setPublicValues(castingValues, a, b);
        
        // Cumpute all operations and put the result handles in an array
        uint256[] memory arrToDecrypt = new uint256[](48);

        // gtUint8 operations
        arrToDecrypt[0] = gtBool.unwrap(MpcCore.ne(castingValues.a8_s, castingValues.b8_s));

        // gtUint16 operations
        arrToDecrypt[1] = gtBool.unwrap(MpcCore.ne(castingValues.a16_s, castingValues.b16_s));
        arrToDecrypt[2] = gtBool.unwrap(MpcCore.ne(castingValues.a8_s, castingValues.b16_s));
        arrToDecrypt[3] = gtBool.unwrap(MpcCore.ne(castingValues.a16_s, castingValues.b8_s));

        // gtUint32 operations
        arrToDecrypt[4] = gtBool.unwrap(MpcCore.ne(castingValues.a32_s, castingValues.b32_s));
        arrToDecrypt[5] = gtBool.unwrap(MpcCore.ne(castingValues.a8_s, castingValues.b32_s));
        arrToDecrypt[6] = gtBool.unwrap(MpcCore.ne(castingValues.a32_s, castingValues.b8_s));
        arrToDecrypt[7] = gtBool.unwrap(MpcCore.ne(castingValues.a16_s, castingValues.b32_s));
        arrToDecrypt[8] = gtBool.unwrap(MpcCore.ne(castingValues.a32_s, castingValues.b16_s));

        // gtUint64 operations
        arrToDecrypt[9] = gtBool.unwrap(MpcCore.ne(castingValues.a64_s, castingValues.b64_s));
        arrToDecrypt[10] = gtBool.unwrap(MpcCore.ne(castingValues.a8_s, castingValues.b64_s));
        arrToDecrypt[11] = gtBool.unwrap(MpcCore.ne(castingValues.a64_s, castingValues.b8_s));
        arrToDecrypt[12] = gtBool.unwrap(MpcCore.ne(castingValues.a16_s, castingValues.b64_s));
        arrToDecrypt[13] = gtBool.unwrap(MpcCore.ne(castingValues.a64_s, castingValues.b16_s));
        arrToDecrypt[14] = gtBool.unwrap(MpcCore.ne(castingValues.a32_s, castingValues.b64_s));
        arrToDecrypt[15] = gtBool.unwrap(MpcCore.ne(castingValues.a64_s, castingValues.b32_s));

        // gtUint128
        arrToDecrypt[16] =  gtBool.unwrap(MpcCore.ne(castingValues.a128_s, castingValues.b128_s));
        arrToDecrypt[17] = gtBool.unwrap(MpcCore.ne(castingValues.a8_s, castingValues.b128_s));
        arrToDecrypt[18] = gtBool.unwrap(MpcCore.ne(castingValues.a128_s, castingValues.b8_s));
        arrToDecrypt[19] = gtBool.unwrap(MpcCore.ne(castingValues.a16_s, castingValues.b128_s));
        arrToDecrypt[20] = gtBool.unwrap(MpcCore.ne(castingValues.a128_s, castingValues.b16_s));
        arrToDecrypt[21] = gtBool.unwrap(MpcCore.ne(castingValues.a32_s, castingValues.b128_s));
        arrToDecrypt[22] = gtBool.unwrap(MpcCore.ne(castingValues.a128_s, castingValues.b32_s));
        arrToDecrypt[23] = gtBool.unwrap(MpcCore.ne(castingValues.a64_s, castingValues.b128_s));
        arrToDecrypt[24] = gtBool.unwrap(MpcCore.ne(castingValues.a128_s, castingValues.b64_s));
        
        // gtUint256
        arrToDecrypt[25] = gtBool.unwrap(MpcCore.ne(castingValues.a256_s, castingValues.b256_s));
        arrToDecrypt[26] = gtBool.unwrap(MpcCore.ne(castingValues.a8_s, castingValues.b256_s));
        arrToDecrypt[27] = gtBool.unwrap(MpcCore.ne(castingValues.a256_s, castingValues.b8_s));
        arrToDecrypt[28] = gtBool.unwrap(MpcCore.ne(castingValues.a16_s, castingValues.b256_s));
        arrToDecrypt[29] = gtBool.unwrap(MpcCore.ne(castingValues.a256_s, castingValues.b16_s));
        arrToDecrypt[30] = gtBool.unwrap(MpcCore.ne(castingValues.a32_s, castingValues.b256_s));
        arrToDecrypt[31] = gtBool.unwrap(MpcCore.ne(castingValues.a256_s, castingValues.b32_s));
        arrToDecrypt[32] = gtBool.unwrap(MpcCore.ne(castingValues.a64_s, castingValues.b256_s));
        arrToDecrypt[33] = gtBool.unwrap(MpcCore.ne(castingValues.a256_s, castingValues.b64_s));
        arrToDecrypt[34] = gtBool.unwrap(MpcCore.ne(castingValues.a128_s, castingValues.b256_s));
        arrToDecrypt[35] = gtBool.unwrap(MpcCore.ne(castingValues.a256_s, castingValues.b128_s));
        
        // ne with scalar
        arrToDecrypt[36] = gtBool.unwrap(MpcCore.ne(a, castingValues.b8_s));
        arrToDecrypt[37] = gtBool.unwrap(MpcCore.ne(castingValues.a8_s, b));
        arrToDecrypt[38] = gtBool.unwrap(MpcCore.ne(a, castingValues.b16_s));
        arrToDecrypt[39] = gtBool.unwrap(MpcCore.ne(castingValues.a16_s, b));
        arrToDecrypt[40] = gtBool.unwrap(MpcCore.ne(a, castingValues.b32_s));
        arrToDecrypt[41] = gtBool.unwrap(MpcCore.ne(castingValues.a32_s, b));
        arrToDecrypt[42] = gtBool.unwrap(MpcCore.ne(a, castingValues.b64_s));
        arrToDecrypt[43] = gtBool.unwrap(MpcCore.ne(castingValues.a64_s, b));
        arrToDecrypt[44] = gtBool.unwrap(MpcCore.ne(a, castingValues.b128_s));
        arrToDecrypt[45] = gtBool.unwrap(MpcCore.ne(castingValues.a128_s, b));
        arrToDecrypt[46] = gtBool.unwrap(MpcCore.ne(a, castingValues.b256_s));
        arrToDecrypt[47] = gtBool.unwrap(MpcCore.ne(castingValues.a256_s, b));

        return requestDecryption(arrToDecrypt, this.checkNeResults.selector);
    }

    function checkNeResults(uint256 decryptID, bytes[] calldata output, bytes[] calldata signatures) public verifyCallback(decryptID, output, signatures){
        bool firstResult = abi.decode(output[0], (bool));
        for (uint256 i = 1; i < output.length; i++) {
            bool result = abi.decode(output[i], (bool));
            require(result == firstResult, "checkNeResults: Invalid output");
        }

        neDecrypted = true;
        neResult = firstResult;
    }
}