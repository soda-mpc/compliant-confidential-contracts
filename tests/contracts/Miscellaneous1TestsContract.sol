// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "MpcCore.sol";
import "../../lib/onchain/contracts/DecryptionCaller.sol";

contract Miscellaneous1TestsContract is DecryptionCaller {

    bool booleanDecrypted;
    bool validateCiphertextDecrypted;
    bool validateCiphertextEip191Decrypted;
    bool validateCiphertext256Decrypted;
    bool validateCiphertext256Eip191Decrypted;
    bool randomDecrypted;
    bool randomBoundedDecrypted;

    uint64 random = 0;
    bool[] checkBool;
    uint256[] checkUint8;
    uint256[] checkUint16;
    uint256[] checkUint32;
    uint256[] checkUint64;
    uint256[] checkUint128;
    uint256[] checkUint256;
    uint64 randomBounded = 0;
    uint8 private numRoundedBits = 0;
    bool[] checkBoolBounded;
    uint256[] checkUint8Bounded;
    uint256[] checkUint16Bounded;
    uint256[] checkUint32Bounded;
    uint256[] checkUint64Bounded;
    uint256[] checkUint128Bounded;
    uint256[] checkUint256Bounded;

    bool andRes;
    bool orRes;
    bool xorRes;
    bool notRes;
    bool eqRes;
    bool neRes;
    bool muxRes;

    uint8 validateCiphertextRes;
    uint8 validateCiphertextEip191Res;

    uint256 validateCiphertext256Res;
    uint256 validateCiphertext256Eip191Res;

    function isBooleanDecrypted() public view returns (bool) {
        return booleanDecrypted;
    }

    function isValidateCiphertextDecrypted() public view returns (bool) {
        return validateCiphertextDecrypted;
    }

    function isValidateCiphertextEip191Decrypted() public view returns (bool) {
        return validateCiphertextEip191Decrypted;
    }

    function isValidateCiphertext256Decrypted() public view returns (bool) {
        return validateCiphertext256Decrypted;
    }

    function isValidateCiphertext256Eip191Decrypted() public view returns (bool) {
        return validateCiphertext256Eip191Decrypted;
    }

    function isRandomDecrypted() public view returns (bool) {
        return randomDecrypted;
    }

    function isRandomBoundedDecrypted() public view returns (bool) {
        return randomBoundedDecrypted;
    }

    function getRandom() public view returns (uint256) {
        checkNotAllEqual(checkUint8, MAX_SIZE_8_BITS);
        checkNotAllEqual(checkUint16, MAX_SIZE_16_BITS);
        checkNotAllEqual(checkUint32, MAX_SIZE_32_BITS);
        checkNotAllEqual(checkUint64, MAX_SIZE_64_BITS);
        checkNotAllEqual(checkUint128, MAX_SIZE_64_BITS);
        checkNotAllEqual(checkUint256, MAX_SIZE_64_BITS);

        bool firstValidateCiphertextRes = checkBool[0];
        uint numEqual = 0;
        for (uint i = 1; i < MAX_BOOL_SIZE; i++) {
            bool res = checkBool[i];
            if (res == firstValidateCiphertextRes) {
                numEqual++;
            }
        }
        require(numEqual < MAX_BOOL_SIZE, "validateCiphertextTest: Invalid output");
        
        return checkUint256[0];
    }

    function getRandomBounded() public view returns (uint256) {
        checkNotAllEqual(checkUint8Bounded, MAX_SIZE_8_BITS);
        checkNotAllEqual(checkUint16Bounded, MAX_SIZE_8_BITS);
        checkNotAllEqual(checkUint32Bounded, MAX_SIZE_8_BITS);
        checkNotAllEqual(checkUint64Bounded, MAX_SIZE_8_BITS);
        checkNotAllEqual(checkUint128Bounded, MAX_SIZE_8_BITS);
        checkNotAllEqual(checkUint256Bounded, MAX_SIZE_8_BITS);

        checkBound(checkUint8Bounded, MAX_SIZE_8_BITS, numRoundedBits);
        checkBound(checkUint16Bounded, MAX_SIZE_8_BITS, numRoundedBits);
        checkBound(checkUint32Bounded, MAX_SIZE_8_BITS, numRoundedBits);
        checkBound(checkUint64Bounded, MAX_SIZE_8_BITS, numRoundedBits);
        checkBound(checkUint128Bounded, MAX_SIZE_8_BITS, numRoundedBits);
        checkBound(checkUint256Bounded, MAX_SIZE_8_BITS, numRoundedBits);

        bool firstValidateCiphertextRes = checkBoolBounded[0];
        uint numEqual = 0;
        for (uint i = 1; i < MAX_BOOL_SIZE; i++) {
            bool res = checkBoolBounded[i];
            if (res == firstValidateCiphertextRes) {
                numEqual++;
            }
        }
        require(numEqual < MAX_BOOL_SIZE, "validateCiphertextEip191Test: Invalid output");

        return checkUint256Bounded[0];
    }

    function getAndResult() public view returns (bool) {
        return andRes;
    }

    function getOrResult() public view returns (bool) {
        return orRes;
    }

    function getXorResult() public view returns (bool) {
        return xorRes;
    }

    function getNotResult() public view returns (bool) {
        return notRes;
    }

    function getEqResult() public view returns (bool) {
        return eqRes;
    }

    function getNeResult() public view returns (bool) {
        return neRes;
    }

    function getMuxResult() public view returns (bool) {
        return muxRes;
    }

    function getValidateCiphertextResult() public view returns (uint8) {
        return validateCiphertextRes;
    }

    function getValidateCiphertextEip191Result() public view returns (uint8) {
        return validateCiphertextEip191Res;
    }

    function getValidateCiphertext256Result() public view returns (uint256) {
        return validateCiphertext256Res;
    }

    function getValidateCiphertext256Eip191Result() public view returns (uint256) {
        return validateCiphertext256Eip191Res;
    }

    function resetStates() public {
        booleanDecrypted = false;
        validateCiphertextDecrypted = false;
        randomDecrypted = false;
        randomBoundedDecrypted = false;
        validateCiphertextEip191Decrypted = false;
        validateCiphertext256Decrypted = false;
        validateCiphertext256Eip191Decrypted = false;
    }

    uint constant MAX_SIZE_8_BITS = 10; 
    uint constant MAX_SIZE_16_BITS = 3; 
    uint constant MAX_SIZE_32_BITS = 3; 
    uint constant MAX_SIZE_64_BITS = 2; 
    uint constant MAX_BOOL_SIZE = 40; 

    function checkNotAllEqual(uint256[] memory randoms, uint size) private view {
        // Count how many randoms are equal
        uint numEqual = 1;
        for (uint i = 1; i < size; i++) {
            if (randoms[0] == randoms[i]){
                numEqual++;
            }
        }
        require(numEqual != size, "randomTest: random failed, all values are the same");
    }

    function randomTest() public returns (uint256) {
        return randTest_(false, 0);
    }

    function checkBound(uint256[] memory randoms, uint size, uint8 numBits) public view {
        for (uint i = 0; i < size; i++) {
            require(randoms[i] < (1 << numBits), "randomTest: random failed, out of bounds");
        }
    }

    function randomBoundedTest(uint8 numBits) public returns (uint256) {
        numRoundedBits = numBits;
        return randTest_(true, numBits); 
    }

    function randTest_(bool isBounded, uint8 numBits) public returns (uint256) {
        uint256[] memory arrToDecrypt;
        if (isBounded) {
            arrToDecrypt = new uint256[](6 * MAX_SIZE_8_BITS + MAX_BOOL_SIZE);
        } else {
            arrToDecrypt = new uint256[](MAX_SIZE_8_BITS + MAX_SIZE_16_BITS + MAX_SIZE_32_BITS + 3 * MAX_SIZE_64_BITS + MAX_BOOL_SIZE);
        }

        uint size = MAX_SIZE_8_BITS;
        // Generate gtUint8 randoms
        for (uint i = 0; i < size; i++) {
            if(!isBounded){
                arrToDecrypt[i] = gtUint8.unwrap(MpcCore.rand8());
            } else {
                arrToDecrypt[i] = gtUint8.unwrap(MpcCore.randBoundedBits8(numBits));
            }
        }

        // In case of bounded random, the bit size does not matter because the bounded bits can be small. 
        // So the max size remain as in 8 bits.
        // In case of unbounded random, max size can be reduced.
        uint startIndex = MAX_SIZE_8_BITS;
        if (!isBounded){ 
            size = MAX_SIZE_16_BITS;
        }
        // Generate gtUint16 randoms
        for (uint i = 0; i < size; i++) {
            if(!isBounded){
                arrToDecrypt[startIndex + i] = gtUint16.unwrap(MpcCore.rand16());
            } else {
                arrToDecrypt[startIndex + i] = gtUint16.unwrap(MpcCore.randBoundedBits16(numBits));
            }
        }

        // Generate gtUint32 randoms
        startIndex += size;
        if (!isBounded){ 
            size = MAX_SIZE_32_BITS;
        }
        for (uint i = 0; i < size; i++) {
            if(!isBounded){
                arrToDecrypt[startIndex + i] = gtUint32.unwrap(MpcCore.rand32());
            } else {
                arrToDecrypt[startIndex + i] = gtUint32.unwrap(MpcCore.randBoundedBits32(numBits));
            }
        }

        // Generate gtUint64 randoms
        startIndex += size;
        if (!isBounded){ 
            size = MAX_SIZE_64_BITS;
        }
        for (uint i = 0; i < size; i++) {
            if(!isBounded){
                arrToDecrypt[startIndex + i] = gtUint64.unwrap(MpcCore.rand64());
            } else {
                arrToDecrypt[startIndex + i] = gtUint64.unwrap(MpcCore.randBoundedBits64(numBits));
            }
        }

        // Generate gtUint128 randoms
        startIndex += size;
        for (uint i = 0; i < size; i++) {
            if(!isBounded){
                arrToDecrypt[startIndex + i] = gtUint128.unwrap(MpcCore.rand128());
            } else {
                arrToDecrypt[startIndex + i] = gtUint128.unwrap(MpcCore.randBoundedBits128(numBits));
            }
        }

        // Generate gtUint256 randoms
        startIndex += size;
        for (uint i = 0; i < size; i++) {
            if(!isBounded){
                arrToDecrypt[startIndex + i] = gtUint256.unwrap(MpcCore.rand256());
            } else {
                arrToDecrypt[startIndex + i] = gtUint256.unwrap(MpcCore.randBoundedBits256(numBits));
            }
        }

        startIndex += size;
        for (uint i = 0; i < MAX_BOOL_SIZE; i++) {
            arrToDecrypt[startIndex + i] = gtBool.unwrap(MpcCore.rand());
        }
        
        if (isBounded) {
            return requestDecryption(arrToDecrypt, this.checkRandomBoundedResults.selector); 
        } else {
            return requestDecryption(arrToDecrypt, this.checkRandomResults.selector); 
        }
    }

    function checkRandomResults(uint256 decryptID, bytes[] calldata output, bytes calldata signature) public {
        require(checkCallbackHandles(decryptID, output.length), "checkRandomResults: Invalid callback parameters");

        checkUint8 = new uint256[](MAX_SIZE_8_BITS);
        for (uint i = 0; i < MAX_SIZE_8_BITS; i++) {
            checkUint8[i] = abi.decode(output[i], (uint8));
        }

        uint startIndex = MAX_SIZE_8_BITS;

        checkUint16 = new uint256[](MAX_SIZE_16_BITS);
        for (uint i = 0; i < MAX_SIZE_16_BITS; i++) {
            checkUint16[i] = abi.decode(output[startIndex + i], (uint16));
        }

        startIndex += MAX_SIZE_16_BITS;
        checkUint32 = new uint256[](MAX_SIZE_32_BITS);
        for (uint i = 0; i < MAX_SIZE_32_BITS; i++) {
            checkUint32[i] = abi.decode(output[startIndex + i], (uint32));
        }

        startIndex += MAX_SIZE_32_BITS;
        checkUint64 = new uint256[](MAX_SIZE_64_BITS);
        for (uint i = 0; i < MAX_SIZE_64_BITS; i++) {
            checkUint64[i] = abi.decode(output[startIndex + i], (uint64));
        }

        startIndex += MAX_SIZE_64_BITS;
        checkUint128 = new uint256[](MAX_SIZE_64_BITS);
        for (uint i = 0; i < MAX_SIZE_64_BITS; i++) {
            checkUint128[i] = abi.decode(output[startIndex + i], (uint128));
        }

        startIndex += MAX_SIZE_64_BITS;
        checkUint256 = new uint256[](MAX_SIZE_64_BITS);
        for (uint i = 0; i < MAX_SIZE_64_BITS; i++) {
            checkUint256[i] = abi.decode(output[startIndex + i], (uint256));
        }

        startIndex += MAX_SIZE_64_BITS;
        checkBool = new bool[](MAX_BOOL_SIZE);
        for (uint i = 0; i < MAX_BOOL_SIZE; i++) {
            checkBool[i] = abi.decode(output[startIndex + i], (bool));
        }

        randomDecrypted = true;
    }

    function checkRandomBoundedResults(uint256 decryptID, bytes[] calldata output, bytes calldata signature) public {
        require(checkCallbackHandles(decryptID, output.length), "checkRandomBoundedResults: Invalid callback parameters");

        checkUint8Bounded = new uint8[](MAX_SIZE_8_BITS);
        for (uint i = 0; i < MAX_SIZE_8_BITS; i++) {
            checkUint8Bounded[i] = abi.decode(output[i], (uint8));
        }

        uint startIndex = MAX_SIZE_8_BITS;
        checkUint16Bounded = new uint256[](MAX_SIZE_8_BITS);
        for (uint i = 0; i < MAX_SIZE_8_BITS; i++) {
            checkUint16Bounded[i] = abi.decode(output[startIndex + i], (uint16));
        }

        startIndex += MAX_SIZE_8_BITS;
        checkUint32Bounded = new uint256[](MAX_SIZE_8_BITS);
        for (uint i = 0; i < MAX_SIZE_8_BITS; i++) {
            checkUint32Bounded[i] = abi.decode(output[startIndex + i], (uint32));
        }

        startIndex += MAX_SIZE_8_BITS;
        checkUint64Bounded = new uint256[](MAX_SIZE_8_BITS);
        for (uint i = 0; i < MAX_SIZE_8_BITS; i++) {
            checkUint64Bounded[i] = abi.decode(output[startIndex + i], (uint64));
        }

        startIndex += MAX_SIZE_8_BITS;
        checkUint128Bounded = new uint256[](MAX_SIZE_8_BITS);
        for (uint i = 0; i < MAX_SIZE_8_BITS; i++) {
            checkUint128Bounded[i] = abi.decode(output[startIndex + i], (uint128));
        }

        startIndex += MAX_SIZE_8_BITS;
        checkUint256Bounded = new uint256[](MAX_SIZE_8_BITS);
        for (uint i = 0; i < MAX_SIZE_8_BITS; i++) {
            checkUint256Bounded[i] = abi.decode(output[startIndex + i], (uint256));
        }

        startIndex += MAX_SIZE_8_BITS;
        checkBoolBounded = new bool[](MAX_BOOL_SIZE);
        for (uint i = 0; i < MAX_BOOL_SIZE; i++) {
            checkBoolBounded[i] = abi.decode(output[startIndex + i], (bool));
        }

        randomBoundedDecrypted = true;
    }

    function booleanTest(bool a, bool b, bool bit) public returns (uint256) {
        gtBool aGT = MpcCore.setPublic(a);
        gtBool bGT = MpcCore.setPublic(b);
        gtBool bitGT = MpcCore.setPublic(bit);

        // Compute all operations and put the result handles in an array
        uint256[] memory arrToDecrypt = new uint256[](7);

        arrToDecrypt[0] = gtBool.unwrap(MpcCore.and(aGT, bGT));
        arrToDecrypt[1] = gtBool.unwrap(MpcCore.or(aGT, bGT));
        arrToDecrypt[2] = gtBool.unwrap(MpcCore.xor(aGT, bGT));
        arrToDecrypt[3] = gtBool.unwrap(MpcCore.not(aGT));
        arrToDecrypt[4] = gtBool.unwrap(MpcCore.eq(aGT, bGT));
        arrToDecrypt[5] = gtBool.unwrap(MpcCore.ne(aGT, bGT));
        arrToDecrypt[6] = gtBool.unwrap(MpcCore.mux(bitGT, aGT, bGT));

        return requestDecryption(arrToDecrypt, this.checkBooleanResults.selector);
    }

    function checkBooleanResults(uint256 decryptID, bytes[] calldata output, bytes calldata signature) public {
        require(checkCallbackHandles(decryptID, output.length), "checkBooleanResults: Invalid callback parameters");
        
        andRes = abi.decode(output[0], (bool));
        orRes = abi.decode(output[1], (bool));
        xorRes = abi.decode(output[2], (bool));
        notRes = abi.decode(output[3], (bool));
        eqRes = abi.decode(output[4], (bool));
        neRes = abi.decode(output[5], (bool));
        muxRes = abi.decode(output[6], (bool));

        booleanDecrypted = true;
    }

    // When invoking this test function, all ciphertexts share the same value but are 
    // cast to four different types: ctUint8, ctUint16, ctUint32, and ctUint64. 
    // Consequently, there is a single signature covering all these ciphertexts.
    function validateCiphertextTest(ctUint8 ct8, ctUint16 ct16, ctUint32 ct32, ctUint64 ct64, ctUint128 ct128, bytes calldata signature) public returns (uint256){
        // Create ITs from ciphertext and signature
        itUint8 memory it8;
        it8.ciphertext = ct8;
        it8.signature = signature;

        itUint16 memory it16;
        it16.ciphertext = ct16;
        it16.signature = signature;

        itUint32 memory it32;
        it32.ciphertext = ct32;
        it32.signature = signature;

        itUint64 memory it64;
        it64.ciphertext = ct64;
        it64.signature = signature;

        itUint128 memory it128;
        it128.ciphertext = ct128;
        it128.signature = signature;

        // Compute all operations and put the result handles in an array
        uint256[] memory arrToDecrypt = new uint256[](5);

        arrToDecrypt[0] = gtUint8.unwrap(MpcCore.validateCiphertext(it8));
        arrToDecrypt[1] = gtUint16.unwrap(MpcCore.validateCiphertext(it16));
        arrToDecrypt[2] = gtUint32.unwrap(MpcCore.validateCiphertext(it32));
        arrToDecrypt[3] = gtUint64.unwrap(MpcCore.validateCiphertext(it64));
        arrToDecrypt[4] = gtUint128.unwrap(MpcCore.validateCiphertext(it128));

        return requestDecryption(arrToDecrypt, this.checkValidateCiphertextResults.selector);
    }

    function checkValidateCiphertextResults(uint256 decryptID, bytes[] calldata output, bytes calldata signature) public {
        require(checkCallbackHandles(decryptID, output.length), "checkValidateCiphertextResults: Invalid callback parameters");
        
        uint8 firstRes = abi.decode(output[0], (uint8));
        for (uint256 i = 1; i < output.length; i++) {
            uint8 res = abi.decode(output[i], (uint8));
            require(res == firstRes, "checkValidateCiphertextResults: Invalid output");
        }

        validateCiphertextDecrypted = true;
        validateCiphertextRes = firstRes;
    }

    // When invoking this test function, all ciphertexts share the same value but are 
    // cast to four different types: ctUint8, ctUint16, ctUint32, and ctUint64. 
    // Consequently, there is a single signature covering all these ciphertexts.
    function validateCiphertextEip191Test(ctUint8 ct8, ctUint16 ct16, ctUint32 ct32, ctUint64 ct64, ctUint128 ct128, bytes calldata signature) public returns (uint256){
        // Create ITs from ciphertext and signature
        itUint8 memory it8;
        it8.ciphertext = ct8;
        it8.signature = signature;

        itUint16 memory it16;
        it16.ciphertext = ct16;
        it16.signature = signature;

        itUint32 memory it32;
        it32.ciphertext = ct32;
        it32.signature = signature;

        itUint64 memory it64;
        it64.ciphertext = ct64;
        it64.signature = signature;

        itUint128 memory it128;
        it128.ciphertext = ct128;
        it128.signature = signature;

        // Compute all operations and put the result handles in an array
        uint256[] memory arrToDecrypt = new uint256[](5);

        arrToDecrypt[0] = gtUint8.unwrap(MpcCore.validateCiphertext(it8));
        arrToDecrypt[1] = gtUint16.unwrap(MpcCore.validateCiphertext(it16));
        arrToDecrypt[2] = gtUint32.unwrap(MpcCore.validateCiphertext(it32));
        arrToDecrypt[3] = gtUint64.unwrap(MpcCore.validateCiphertext(it64));
        arrToDecrypt[4] = gtUint128.unwrap(MpcCore.validateCiphertext(it128));

        return requestDecryption(arrToDecrypt, this.checkValidateCiphertextEip191Results.selector);
    }

    function checkValidateCiphertextEip191Results(uint256 decryptID, bytes[] calldata output, bytes calldata signature) public {
        require(checkCallbackHandles(decryptID, output.length), "checkValidateCiphertextEip191Results: Invalid callback parameters");
        
        uint8 firstRes = abi.decode(output[0], (uint8));
        for (uint256 i = 1; i < output.length; i++) {
            uint8 res = abi.decode(output[i], (uint8));
            require(res == firstRes, "checkValidateCiphertextEip191Results: Invalid output");
        }

        validateCiphertextEip191Decrypted = true;
        validateCiphertextEip191Res = firstRes;
    }

    function validateCiphertext256Test(itUint256 calldata it256) public returns (uint256){

        uint256[] memory arrToDecrypt = new uint256[](1);

        arrToDecrypt[0] = gtUint256.unwrap(MpcCore.validateCiphertext(it256));

        return requestDecryption(arrToDecrypt, this.checkValidateCiphertext256Results.selector);
    }

    function checkValidateCiphertext256Results(uint256 decryptID, bytes[] calldata output, bytes calldata signature) public {
        require(checkCallbackHandles(decryptID, output.length), "checkValidateCiphertext256Results: Invalid callback parameters");
        
        validateCiphertext256Res = abi.decode(output[0], (uint256));
        validateCiphertext256Decrypted = true;
    }

    function validateCiphertext256Eip191Test(itUint256 calldata it256) public returns (uint256){
        uint256[] memory arrToDecrypt = new uint256[](1);

        arrToDecrypt[0] = gtUint256.unwrap(MpcCore.validateCiphertext(it256));

        return requestDecryption(arrToDecrypt, this.checkValidateCiphertext256Eip191Results.selector);
    }

    function checkValidateCiphertext256Eip191Results(uint256 decryptID, bytes[] calldata output, bytes calldata signature) public {
        require(checkCallbackHandles(decryptID, output.length), "checkValidateCiphertext256Eip191Results: Invalid callback parameters");
        
        validateCiphertext256Eip191Res = abi.decode(output[0], (uint256));
        validateCiphertext256Eip191Decrypted = true;
    }



}