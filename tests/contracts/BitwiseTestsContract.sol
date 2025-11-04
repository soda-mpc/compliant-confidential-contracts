// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "MpcCore.sol";
import "../../lib/onchain/contracts/DecryptionCaller.sol";

contract BitwiseTestsContract is DecryptionCaller {

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

    bool andDecrypted;
    bool orDecrypted;
    
    uint8 andResult;
    uint8 orResult;
    
    function isAndDecrypted() public view returns (bool) {
        return andDecrypted;
    }
    function isOrDecrypted() public view returns (bool) {
        return orDecrypted;
    }
    

    function getAndResult() public view returns (uint8) {
        return andResult;
    }
    function getOrResult() public view returns (uint8) {
        return orResult;
    }
    
    function resetStates() public {
        andDecrypted = false;
        orDecrypted = false;
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

    function andTest(uint8 a, uint8 b) public returns (uint256) {
        AllGTCastingValues memory castingValues;
        setPublicValues(castingValues, a, b);

        // Cumpute all operations and put the result handles in an array
        uint256[] memory arrToDecrypt = new uint256[](48);

        // gtUint8
        arrToDecrypt[0] = gtUint8.unwrap(MpcCore.and(castingValues.a8_s, castingValues.b8_s));

        // gtUint16
        arrToDecrypt[1] = gtUint16.unwrap(MpcCore.and(castingValues.a16_s, castingValues.b16_s));
        arrToDecrypt[2] = gtUint16.unwrap(MpcCore.and(castingValues.a8_s, castingValues.b16_s));
        arrToDecrypt[3] = gtUint16.unwrap(MpcCore.and(castingValues.a16_s, castingValues.b8_s));

        // gtUint32
        arrToDecrypt[4] = gtUint32.unwrap(MpcCore.and(castingValues.a32_s, castingValues.b32_s));
        arrToDecrypt[5] = gtUint32.unwrap(MpcCore.and(castingValues.a8_s, castingValues.b32_s));
        arrToDecrypt[6] = gtUint32.unwrap(MpcCore.and(castingValues.a32_s, castingValues.b8_s));
        arrToDecrypt[7] = gtUint32.unwrap(MpcCore.and(castingValues.a16_s, castingValues.b32_s));
        arrToDecrypt[8] = gtUint32.unwrap(MpcCore.and(castingValues.a32_s, castingValues.b16_s));

        // gtUint64
        arrToDecrypt[9] = gtUint64.unwrap(MpcCore.and(castingValues.a64_s, castingValues.b64_s));
        arrToDecrypt[10] = gtUint64.unwrap(MpcCore.and(castingValues.a8_s, castingValues.b64_s));
        arrToDecrypt[11] = gtUint64.unwrap(MpcCore.and(castingValues.a64_s, castingValues.b8_s));
        arrToDecrypt[12] = gtUint64.unwrap(MpcCore.and(castingValues.a16_s, castingValues.b64_s));
        arrToDecrypt[13] = gtUint64.unwrap(MpcCore.and(castingValues.a64_s, castingValues.b16_s));
        arrToDecrypt[14] = gtUint64.unwrap(MpcCore.and(castingValues.a32_s, castingValues.b64_s));
        arrToDecrypt[15] = gtUint64.unwrap(MpcCore.and(castingValues.a64_s, castingValues.b32_s));

        // gtUint128
        arrToDecrypt[16] = gtUint128.unwrap(MpcCore.and(castingValues.a128_s, castingValues.b128_s));
        arrToDecrypt[17] = gtUint128.unwrap(MpcCore.and(castingValues.a8_s, castingValues.b128_s));
        arrToDecrypt[18] = gtUint128.unwrap(MpcCore.and(castingValues.a128_s, castingValues.b8_s));
        arrToDecrypt[19] = gtUint128.unwrap(MpcCore.and(castingValues.a16_s, castingValues.b128_s));
        arrToDecrypt[20] = gtUint128.unwrap(MpcCore.and(castingValues.a128_s, castingValues.b16_s));
        arrToDecrypt[21] = gtUint128.unwrap(MpcCore.and(castingValues.a32_s, castingValues.b128_s));
        arrToDecrypt[22] = gtUint128.unwrap(MpcCore.and(castingValues.a128_s, castingValues.b32_s));
        arrToDecrypt[23] = gtUint128.unwrap(MpcCore.and(castingValues.a64_s, castingValues.b128_s));
        arrToDecrypt[24] = gtUint128.unwrap(MpcCore.and(castingValues.a128_s, castingValues.b64_s));
        
        // gtUint256
        arrToDecrypt[25] = gtUint256.unwrap(MpcCore.and(castingValues.a256_s, castingValues.b256_s));
        arrToDecrypt[26] = gtUint256.unwrap(MpcCore.and(castingValues.a8_s, castingValues.b256_s));
        arrToDecrypt[27] = gtUint256.unwrap(MpcCore.and(castingValues.a256_s, castingValues.b8_s));
        arrToDecrypt[28] = gtUint256.unwrap(MpcCore.and(castingValues.a16_s, castingValues.b256_s));
        arrToDecrypt[29] = gtUint256.unwrap(MpcCore.and(castingValues.a256_s, castingValues.b16_s));
        arrToDecrypt[30] = gtUint256.unwrap(MpcCore.and(castingValues.a32_s, castingValues.b256_s));
        arrToDecrypt[31] = gtUint256.unwrap(MpcCore.and(castingValues.a256_s, castingValues.b32_s));
        arrToDecrypt[32] = gtUint256.unwrap(MpcCore.and(castingValues.a64_s, castingValues.b256_s));
        arrToDecrypt[33] = gtUint256.unwrap(MpcCore.and(castingValues.a256_s, castingValues.b64_s));
        arrToDecrypt[34] = gtUint256.unwrap(MpcCore.and(castingValues.a128_s, castingValues.b256_s));
        arrToDecrypt[35] = gtUint256.unwrap(MpcCore.and(castingValues.a256_s, castingValues.b128_s));
       
        // And with scalar
        arrToDecrypt[36] = gtUint8.unwrap(MpcCore.and(a, castingValues.b8_s));
        arrToDecrypt[37] = gtUint8.unwrap(MpcCore.and(castingValues.a8_s, b));
        arrToDecrypt[38] = gtUint16.unwrap(MpcCore.and(a, castingValues.b16_s));
        arrToDecrypt[39] = gtUint16.unwrap(MpcCore.and(castingValues.a16_s, b));
        arrToDecrypt[40] = gtUint32.unwrap(MpcCore.and(a, castingValues.b32_s));
        arrToDecrypt[41] = gtUint32.unwrap(MpcCore.and(castingValues.a32_s, b));
        arrToDecrypt[42] = gtUint64.unwrap(MpcCore.and(a, castingValues.b64_s));
        arrToDecrypt[43] = gtUint64.unwrap(MpcCore.and(castingValues.a64_s, b));
        arrToDecrypt[44] = gtUint128.unwrap(MpcCore.and(a, castingValues.b128_s));
        arrToDecrypt[45] = gtUint128.unwrap(MpcCore.and(castingValues.a128_s, b));
        arrToDecrypt[46] = gtUint256.unwrap(MpcCore.and(a, castingValues.b256_s));
        arrToDecrypt[47] = gtUint256.unwrap(MpcCore.and(castingValues.a256_s, b));


        return requestDecryption(arrToDecrypt, this.checkAndResults.selector);
    }

    function checkAndResults(uint256 decryptID, bytes[] calldata output, bytes calldata signature) public {
        require(checkCallbackHandles(decryptID, output.length), "checkAndResults: Invalid callback parameters");
        
        uint8 firstResult = abi.decode(output[0], (uint8));
        for (uint256 i = 1; i < output.length; i++) {
            uint8 result = abi.decode(output[i], (uint8));
            require(result == firstResult, "checkAndResults: Invalid output");
        }

        andDecrypted = true;
        andResult = firstResult;
    }

    function orTest(uint8 a, uint8 b) public returns (uint256) {
        AllGTCastingValues memory castingValues;
        setPublicValues(castingValues, a, b);
        
        // Cumpute all operations and put the result handles in an array
        uint256[] memory arrToDecrypt = new uint256[](48);

        // gtUint8
        arrToDecrypt[0] = gtUint8.unwrap(MpcCore.or(castingValues.a8_s, castingValues.b8_s));

        // gtUint16
        arrToDecrypt[1] = gtUint16.unwrap(MpcCore.or(castingValues.a16_s, castingValues.b16_s));
        arrToDecrypt[2] = gtUint16.unwrap(MpcCore.or(castingValues.a8_s, castingValues.b16_s));
        arrToDecrypt[3] = gtUint16.unwrap(MpcCore.or(castingValues.a16_s, castingValues.b8_s));

        // gtUint32
        arrToDecrypt[4] = gtUint32.unwrap(MpcCore.or(castingValues.a32_s, castingValues.b32_s));
        arrToDecrypt[5] = gtUint32.unwrap(MpcCore.or(castingValues.a8_s, castingValues.b32_s));
        arrToDecrypt[6] = gtUint32.unwrap(MpcCore.or(castingValues.a32_s, castingValues.b8_s));
        arrToDecrypt[7] = gtUint32.unwrap(MpcCore.or(castingValues.a16_s, castingValues.b32_s));    
        arrToDecrypt[8] = gtUint32.unwrap(MpcCore.or(castingValues.a32_s, castingValues.b16_s));

        // gtUint64
        arrToDecrypt[9] = gtUint64.unwrap(MpcCore.or(castingValues.a64_s, castingValues.b64_s));
        arrToDecrypt[10] = gtUint64.unwrap(MpcCore.or(castingValues.a8_s, castingValues.b64_s));
        arrToDecrypt[11] = gtUint64.unwrap(MpcCore.or(castingValues.a64_s, castingValues.b8_s));
        arrToDecrypt[12] = gtUint64.unwrap(MpcCore.or(castingValues.a16_s, castingValues.b64_s));
        arrToDecrypt[13] = gtUint64.unwrap(MpcCore.or(castingValues.a64_s, castingValues.b16_s));
        arrToDecrypt[14] = gtUint64.unwrap(MpcCore.or(castingValues.a32_s, castingValues.b64_s));
        arrToDecrypt[15] = gtUint64.unwrap(MpcCore.or(castingValues.a64_s, castingValues.b32_s));

        // gtUint128
        arrToDecrypt[16] = gtUint128.unwrap(MpcCore.or(castingValues.a128_s, castingValues.b128_s));
        arrToDecrypt[17] = gtUint128.unwrap(MpcCore.or(castingValues.a8_s, castingValues.b128_s));
        arrToDecrypt[18] = gtUint128.unwrap(MpcCore.or(castingValues.a128_s, castingValues.b8_s));
        arrToDecrypt[19] = gtUint128.unwrap(MpcCore.or(castingValues.a16_s, castingValues.b128_s));
        arrToDecrypt[20] = gtUint128.unwrap(MpcCore.or(castingValues.a128_s, castingValues.b16_s));
        arrToDecrypt[21] = gtUint128.unwrap(MpcCore.or(castingValues.a32_s, castingValues.b128_s));
        arrToDecrypt[22] = gtUint128.unwrap(MpcCore.or(castingValues.a128_s, castingValues.b32_s));
        arrToDecrypt[23] = gtUint128.unwrap(MpcCore.or(castingValues.a64_s, castingValues.b128_s));
        arrToDecrypt[24] = gtUint128.unwrap(MpcCore.or(castingValues.a128_s, castingValues.b64_s));
        
        // gtUint256
        arrToDecrypt[25] = gtUint256.unwrap(MpcCore.or(castingValues.a256_s, castingValues.b256_s));
        arrToDecrypt[26] = gtUint256.unwrap(MpcCore.or(castingValues.a8_s, castingValues.b256_s));
        arrToDecrypt[27] = gtUint256.unwrap(MpcCore.or(castingValues.a256_s, castingValues.b8_s));
        arrToDecrypt[28] = gtUint256.unwrap(MpcCore.or(castingValues.a16_s, castingValues.b256_s));
        arrToDecrypt[29] = gtUint256.unwrap(MpcCore.or(castingValues.a256_s, castingValues.b16_s));
        arrToDecrypt[30] = gtUint256.unwrap(MpcCore.or(castingValues.a32_s, castingValues.b256_s));
        arrToDecrypt[31] = gtUint256.unwrap(MpcCore.or(castingValues.a256_s, castingValues.b32_s));
        arrToDecrypt[32] = gtUint256.unwrap(MpcCore.or(castingValues.a64_s, castingValues.b256_s));
        arrToDecrypt[33] = gtUint256.unwrap(MpcCore.or(castingValues.a256_s, castingValues.b64_s));
        arrToDecrypt[34] = gtUint256.unwrap(MpcCore.or(castingValues.a128_s, castingValues.b256_s));
        arrToDecrypt[35] = gtUint256.unwrap(MpcCore.or(castingValues.a256_s, castingValues.b128_s));

        // or with scalar
        arrToDecrypt[36] = gtUint8.unwrap(MpcCore.or(a, castingValues.b8_s));
        arrToDecrypt[37] = gtUint8.unwrap(MpcCore.or(castingValues.a8_s, b));
        arrToDecrypt[38] = gtUint16.unwrap(MpcCore.or(a, castingValues.b16_s));
        arrToDecrypt[39] = gtUint16.unwrap(MpcCore.or(castingValues.a16_s, b));
        arrToDecrypt[40] = gtUint32.unwrap(MpcCore.or(a, castingValues.b32_s));
        arrToDecrypt[41] = gtUint32.unwrap(MpcCore.or(castingValues.a32_s, b));
        arrToDecrypt[42] = gtUint64.unwrap(MpcCore.or(a, castingValues.b64_s));
        arrToDecrypt[43] = gtUint64.unwrap(MpcCore.or(castingValues.a64_s, b));
        arrToDecrypt[44] = gtUint128.unwrap(MpcCore.or(a, castingValues.b128_s));
        arrToDecrypt[45] = gtUint128.unwrap(MpcCore.or(castingValues.a128_s, b));
        arrToDecrypt[46] = gtUint256.unwrap(MpcCore.or(a, castingValues.b256_s));
        arrToDecrypt[47] = gtUint256.unwrap(MpcCore.or(castingValues.a256_s, b));

        return requestDecryption(arrToDecrypt, this.checkOrResults.selector);
    }

    function checkOrResults(uint256 decryptID, bytes[] calldata output, bytes calldata signature) public {
        require(checkCallbackHandles(decryptID, output.length), "checkOrResults: Invalid callback parameters");
        
        uint8 firstResult = abi.decode(output[0], (uint8));
        for (uint256 i = 1; i < output.length; i++) {
            uint8 result = abi.decode(output[i], (uint8));
            require(result == firstResult, "checkOrResults: Invalid output");
        }

        orDecrypted = true;
        orResult = firstResult;

    }
}