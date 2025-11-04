// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "MpcCore.sol";
import "../../lib/onchain/contracts/DecryptionCaller.sol";

contract MinMaxTestsContract is DecryptionCaller {

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

    bool minDecrypted;
    bool maxDecrypted;

    uint8 minResult;
    uint8 maxResult;

    function isMinDecrypted() public view returns (bool) {
        return minDecrypted;
    }
    function isMaxDecrypted() public view returns (bool) {
        return maxDecrypted;
    }
    
    function getMinResult() public view returns (uint8) {
        return minResult;
    }
    function getMaxResult() public view returns (uint8) {
        return maxResult;
    }

    function resetStates() public {
        minDecrypted = false;
        maxDecrypted = false;
    }

    function minTest(uint8 a, uint8 b) public returns (uint256) {
        AllGTCastingValues memory castingValues;
        setPublicValues(castingValues, a, b);

        // Cumpute all operations and put the result handles in an array
        uint256[] memory arrToDecrypt = new uint256[](48);
        
        // gtUint8 operations
        arrToDecrypt[0] = gtUint8.unwrap(MpcCore.min(castingValues.a8_s, castingValues.b8_s));
        arrToDecrypt[1] = gtUint16.unwrap(MpcCore.min(castingValues.a16_s, castingValues.b16_s));
        arrToDecrypt[2] = gtUint16.unwrap(MpcCore.min(castingValues.a8_s, castingValues.b16_s));
        arrToDecrypt[3] = gtUint16.unwrap(MpcCore.min(castingValues.a16_s, castingValues.b8_s));

        // gtUint32 operations
        arrToDecrypt[4] = gtUint32.unwrap(MpcCore.min(castingValues.a32_s, castingValues.b32_s));
        arrToDecrypt[5] = gtUint32.unwrap(MpcCore.min(castingValues.a8_s, castingValues.b32_s));
        arrToDecrypt[6] = gtUint32.unwrap(MpcCore.min(castingValues.a32_s, castingValues.b8_s));
        arrToDecrypt[7] = gtUint32.unwrap(MpcCore.min(castingValues.a16_s, castingValues.b32_s));
        arrToDecrypt[8] = gtUint32.unwrap(MpcCore.min(castingValues.a32_s, castingValues.b16_s));

        // gtUint64 operations
        arrToDecrypt[9] = gtUint64.unwrap(MpcCore.min(castingValues.a64_s, castingValues.b64_s));
        arrToDecrypt[10] = gtUint64.unwrap(MpcCore.min(castingValues.a8_s, castingValues.b64_s));
        arrToDecrypt[11] = gtUint64.unwrap(MpcCore.min(castingValues.a64_s, castingValues.b8_s));
        arrToDecrypt[12] = gtUint64.unwrap(MpcCore.min(castingValues.a16_s, castingValues.b64_s));
        arrToDecrypt[13] = gtUint64.unwrap(MpcCore.min(castingValues.a64_s, castingValues.b16_s));
        arrToDecrypt[14] = gtUint64.unwrap(MpcCore.min(castingValues.a32_s, castingValues.b64_s));
        arrToDecrypt[15] = gtUint64.unwrap(MpcCore.min(castingValues.a64_s, castingValues.b32_s));

        // gtUint128
        arrToDecrypt[16] =  gtUint128.unwrap(MpcCore.min(castingValues.a128_s, castingValues.b128_s));
        arrToDecrypt[17] = gtUint128.unwrap(MpcCore.min(castingValues.a8_s, castingValues.b128_s));
        arrToDecrypt[18] = gtUint128.unwrap(MpcCore.min(castingValues.a128_s, castingValues.b8_s));
        arrToDecrypt[19] = gtUint128.unwrap(MpcCore.min(castingValues.a16_s, castingValues.b128_s));
        arrToDecrypt[20] = gtUint128.unwrap(MpcCore.min(castingValues.a128_s, castingValues.b16_s));
        arrToDecrypt[21] = gtUint128.unwrap(MpcCore.min(castingValues.a32_s, castingValues.b128_s));
        arrToDecrypt[22] = gtUint128.unwrap(MpcCore.min(castingValues.a128_s, castingValues.b32_s));
        arrToDecrypt[23] = gtUint128.unwrap(MpcCore.min(castingValues.a64_s, castingValues.b128_s));
        arrToDecrypt[24] = gtUint128.unwrap(MpcCore.min(castingValues.a128_s, castingValues.b64_s));
        
        // gtUint256
        arrToDecrypt[25] = gtUint256.unwrap(MpcCore.min(castingValues.a256_s, castingValues.b256_s));
        arrToDecrypt[26] = gtUint256.unwrap(MpcCore.min(castingValues.a8_s, castingValues.b256_s));
        arrToDecrypt[27] = gtUint256.unwrap(MpcCore.min(castingValues.a256_s, castingValues.b8_s));
        arrToDecrypt[28] = gtUint256.unwrap(MpcCore.min(castingValues.a16_s, castingValues.b256_s));
        arrToDecrypt[29] = gtUint256.unwrap(MpcCore.min(castingValues.a256_s, castingValues.b16_s));
        arrToDecrypt[30] = gtUint256.unwrap(MpcCore.min(castingValues.a32_s, castingValues.b256_s));
        arrToDecrypt[31] = gtUint256.unwrap(MpcCore.min(castingValues.a256_s, castingValues.b32_s));
        arrToDecrypt[32] = gtUint256.unwrap(MpcCore.min(castingValues.a64_s, castingValues.b256_s));
        arrToDecrypt[33] = gtUint256.unwrap(MpcCore.min(castingValues.a256_s, castingValues.b64_s));
        arrToDecrypt[34] = gtUint256.unwrap(MpcCore.min(castingValues.a128_s, castingValues.b256_s));
        arrToDecrypt[35] = gtUint256.unwrap(MpcCore.min(castingValues.a256_s, castingValues.b128_s));
        
        // min with scalar
        arrToDecrypt[36] = gtUint8.unwrap(MpcCore.min(a, castingValues.b8_s));
        arrToDecrypt[37] = gtUint8.unwrap(MpcCore.min(castingValues.a8_s, b));
        arrToDecrypt[38] = gtUint16.unwrap(MpcCore.min(a, castingValues.b16_s));
        arrToDecrypt[39] = gtUint16.unwrap(MpcCore.min(castingValues.a16_s, b));
        arrToDecrypt[40] = gtUint32.unwrap(MpcCore.min(a, castingValues.b32_s));
        arrToDecrypt[41] = gtUint32.unwrap(MpcCore.min(castingValues.a32_s, b));
        arrToDecrypt[42] = gtUint64.unwrap(MpcCore.min(a, castingValues.b64_s));
        arrToDecrypt[43] = gtUint64.unwrap(MpcCore.min(castingValues.a64_s, b));
        arrToDecrypt[44] = gtUint128.unwrap(MpcCore.min(a, castingValues.b128_s));
        arrToDecrypt[45] = gtUint128.unwrap(MpcCore.min(castingValues.a128_s, b));
        arrToDecrypt[46] = gtUint256.unwrap(MpcCore.min(a, castingValues.b256_s));
        arrToDecrypt[47] = gtUint256.unwrap(MpcCore.min(castingValues.a256_s, b));

        return requestDecryption(arrToDecrypt, this.checkMinResults.selector);
    }

    function checkMinResults(uint256 decryptID, bytes[] calldata output, bytes calldata signature) public {
        require(checkCallbackHandles(decryptID, output.length), "checkMinResults: Invalid callback parameters");
        
        uint8 firstResult = abi.decode(output[0], (uint8));
        for (uint256 i = 1; i < output.length; i++) {
            uint8 result = abi.decode(output[i], (uint8));
            require(result == firstResult, "checkMinResults: Invalid output");
        }

        minDecrypted = true;
        minResult = firstResult;
    }

    function maxTest(uint8 a, uint8 b) public returns (uint256) {
        AllGTCastingValues memory castingValues;
        setPublicValues(castingValues, a, b);
        
        // Cumpute all operations and put the result handles in an array
        uint256[] memory arrToDecrypt = new uint256[](48);
        
        // gtUint8 operations
        arrToDecrypt[0] = gtUint8.unwrap(MpcCore.max(castingValues.a8_s, castingValues.b8_s));

        // gtUint16 operations
        arrToDecrypt[1] = gtUint16.unwrap(MpcCore.max(castingValues.a16_s, castingValues.b16_s));
        arrToDecrypt[2] = gtUint16.unwrap(MpcCore.max(castingValues.a8_s, castingValues.b16_s));
        arrToDecrypt[3] = gtUint16.unwrap(MpcCore.max(castingValues.a16_s, castingValues.b8_s));

        // gtUint32 operations
        arrToDecrypt[4] = gtUint32.unwrap(MpcCore.max(castingValues.a32_s, castingValues.b32_s));
        arrToDecrypt[5] = gtUint32.unwrap(MpcCore.max(castingValues.a8_s, castingValues.b32_s));
        arrToDecrypt[6] = gtUint32.unwrap(MpcCore.max(castingValues.a32_s, castingValues.b8_s));
        arrToDecrypt[7] = gtUint32.unwrap(MpcCore.max(castingValues.a16_s, castingValues.b32_s));
        arrToDecrypt[8] = gtUint32.unwrap(MpcCore.max(castingValues.a32_s, castingValues.b16_s));

        // gtUint64 operations
        arrToDecrypt[9] = gtUint64.unwrap(MpcCore.max(castingValues.a64_s, castingValues.b64_s));
        arrToDecrypt[10] = gtUint64.unwrap(MpcCore.max(castingValues.a8_s, castingValues.b64_s));
        arrToDecrypt[11] = gtUint64.unwrap(MpcCore.max(castingValues.a64_s, castingValues.b8_s));
        arrToDecrypt[12] = gtUint64.unwrap(MpcCore.max(castingValues.a16_s, castingValues.b64_s));
        arrToDecrypt[13] = gtUint64.unwrap(MpcCore.max(castingValues.a64_s, castingValues.b16_s));
        arrToDecrypt[14] = gtUint64.unwrap(MpcCore.max(castingValues.a32_s, castingValues.b64_s));
        arrToDecrypt[15] = gtUint64.unwrap(MpcCore.max(castingValues.a64_s, castingValues.b32_s));

        // gtUint128
        arrToDecrypt[16] =  gtUint128.unwrap(MpcCore.max(castingValues.a128_s, castingValues.b128_s));
        arrToDecrypt[17] = gtUint128.unwrap(MpcCore.max(castingValues.a8_s, castingValues.b128_s));
        arrToDecrypt[18] = gtUint128.unwrap(MpcCore.max(castingValues.a128_s, castingValues.b8_s));
        arrToDecrypt[19] = gtUint128.unwrap(MpcCore.max(castingValues.a16_s, castingValues.b128_s));
        arrToDecrypt[20] = gtUint128.unwrap(MpcCore.max(castingValues.a128_s, castingValues.b16_s));
        arrToDecrypt[21] = gtUint128.unwrap(MpcCore.max(castingValues.a32_s, castingValues.b128_s));
        arrToDecrypt[22] = gtUint128.unwrap(MpcCore.max(castingValues.a128_s, castingValues.b32_s));
        arrToDecrypt[23] = gtUint128.unwrap(MpcCore.max(castingValues.a64_s, castingValues.b128_s));
        arrToDecrypt[24] = gtUint128.unwrap(MpcCore.max(castingValues.a128_s, castingValues.b64_s));
        
        // gtUint256
        arrToDecrypt[25] = gtUint256.unwrap(MpcCore.max(castingValues.a256_s, castingValues.b256_s));
        arrToDecrypt[26] = gtUint256.unwrap(MpcCore.max(castingValues.a8_s, castingValues.b256_s));
        arrToDecrypt[27] = gtUint256.unwrap(MpcCore.max(castingValues.a256_s, castingValues.b8_s));
        arrToDecrypt[28] = gtUint256.unwrap(MpcCore.max(castingValues.a16_s, castingValues.b256_s));
        arrToDecrypt[29] = gtUint256.unwrap(MpcCore.max(castingValues.a256_s, castingValues.b16_s));
        arrToDecrypt[30] = gtUint256.unwrap(MpcCore.max(castingValues.a32_s, castingValues.b256_s));
        arrToDecrypt[31] = gtUint256.unwrap(MpcCore.max(castingValues.a256_s, castingValues.b32_s));
        arrToDecrypt[32] = gtUint256.unwrap(MpcCore.max(castingValues.a64_s, castingValues.b256_s));
        arrToDecrypt[33] = gtUint256.unwrap(MpcCore.max(castingValues.a256_s, castingValues.b64_s));
        arrToDecrypt[34] = gtUint256.unwrap(MpcCore.max(castingValues.a128_s, castingValues.b256_s));
        arrToDecrypt[35] = gtUint256.unwrap(MpcCore.max(castingValues.a256_s, castingValues.b128_s));
        
        // max with scalar
        arrToDecrypt[36] = gtUint8.unwrap(MpcCore.max(a, castingValues.b8_s));
        arrToDecrypt[37] = gtUint8.unwrap(MpcCore.max(castingValues.a8_s, b));
        arrToDecrypt[38] = gtUint16.unwrap(MpcCore.max(a, castingValues.b16_s));
        arrToDecrypt[39] = gtUint16.unwrap(MpcCore.max(castingValues.a16_s, b));
        arrToDecrypt[40] = gtUint32.unwrap(MpcCore.max(a, castingValues.b32_s));
        arrToDecrypt[41] = gtUint32.unwrap(MpcCore.max(castingValues.a32_s, b));
        arrToDecrypt[42] = gtUint64.unwrap(MpcCore.max(a, castingValues.b64_s));
        arrToDecrypt[43] = gtUint64.unwrap(MpcCore.max(castingValues.a64_s, b));
        arrToDecrypt[44] = gtUint128.unwrap(MpcCore.max(a, castingValues.b128_s));
        arrToDecrypt[45] = gtUint128.unwrap(MpcCore.max(castingValues.a128_s, b));
        arrToDecrypt[46] = gtUint256.unwrap(MpcCore.max(a, castingValues.b256_s));
        arrToDecrypt[47] = gtUint256.unwrap(MpcCore.max(castingValues.a256_s, b));
        
        return requestDecryption(arrToDecrypt, this.checkMaxResults.selector);
    }

    function checkMaxResults(uint256 decryptID, bytes[] calldata output, bytes calldata signature) public {
        require(checkCallbackHandles(decryptID, output.length), "checkMaxResults: Invalid callback parameters");
        
        uint8 firstResult = abi.decode(output[0], (uint8));
        for (uint256 i = 1; i < output.length; i++) {
            uint8 result = abi.decode(output[i], (uint8));
            require(result == firstResult, "checkMaxResults: Invalid output");
        }

        maxDecrypted = true;
        maxResult = firstResult;
    }
}