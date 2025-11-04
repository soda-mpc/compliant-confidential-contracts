// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "MpcCore.sol";
import "../../lib/onchain/contracts/DecryptionCaller.sol";

contract TransferScalarTestsContract is DecryptionCaller {

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

    bool transferDecrypted;

    uint8 newA;
    uint8 newB;
    bool result;

    function isTransferDecrypted() public view returns (bool) {
        return transferDecrypted;
    }

    function getNewA() public view returns (uint8) {
        return newA;
    }

    function getNewB() public view returns (uint8) {
        return newB;
    }
    
    function getResult() public view returns (bool) {
        return result;
    }

    function resetStates() public {
        transferDecrypted = false;
    }

    function computeAndCheckTransfer16(AllGTCastingValues memory allGTCastingValues, uint8 amount, uint256[] memory arrToDecrypt) public {
        
        // Check all options for casting to 16 while amount is scalar
        (gtUint16 newA_s, gtUint16 newB_s, gtBool res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b16_s, amount);
        arrToDecrypt[3] = gtUint16.unwrap(newA_s);
        arrToDecrypt[4] = gtUint16.unwrap(newB_s);
        arrToDecrypt[5] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b16_s, amount);
        arrToDecrypt[6] = gtUint16.unwrap(newA_s);
        arrToDecrypt[7] = gtUint16.unwrap(newB_s);
        arrToDecrypt[8] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b8_s, amount);
        arrToDecrypt[9] = gtUint16.unwrap(newA_s);
        arrToDecrypt[10] = gtUint16.unwrap(newB_s);
        arrToDecrypt[11] = gtBool.unwrap(res_s);
    }

    function computeAndCheckTransfer32(AllGTCastingValues memory allGTCastingValues, uint8 amount, uint256[] memory arrToDecrypt) public {

        // Check all options for casting to 32 while amount is scalar
        (gtUint32 newA_s, gtUint32 newB_s, gtBool res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b32_s, amount);
        arrToDecrypt[12] = gtUint32.unwrap(newA_s);
        arrToDecrypt[13] = gtUint32.unwrap(newB_s);
        arrToDecrypt[14] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b32_s, amount);
        arrToDecrypt[15] = gtUint32.unwrap(newA_s);
        arrToDecrypt[16] = gtUint32.unwrap(newB_s);
        arrToDecrypt[17] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b8_s, amount);
        arrToDecrypt[18] = gtUint32.unwrap(newA_s);
        arrToDecrypt[19] = gtUint32.unwrap(newB_s);
        arrToDecrypt[20] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b32_s, amount);
        arrToDecrypt[21] = gtUint32.unwrap(newA_s);
        arrToDecrypt[22] = gtUint32.unwrap(newB_s);
        arrToDecrypt[23] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b16_s, amount);
        arrToDecrypt[24] = gtUint32.unwrap(newA_s);
        arrToDecrypt[25] = gtUint32.unwrap(newB_s);
        arrToDecrypt[26] = gtBool.unwrap(res_s);
    }

    function computeAndCheckTransfer64(AllGTCastingValues memory allGTCastingValues, uint8 amount, uint256[] memory arrToDecrypt) public {

        // Check all options for casting to 64 while amount is scalar
        (gtUint64 newA_s, gtUint64 newB_s, gtBool res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b64_s, amount);
        arrToDecrypt[27] = gtUint64.unwrap(newA_s);
        arrToDecrypt[28] = gtUint64.unwrap(newB_s);
        arrToDecrypt[29] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b64_s, amount);
        arrToDecrypt[30] = gtUint64.unwrap(newA_s);
        arrToDecrypt[31] = gtUint64.unwrap(newB_s);
        arrToDecrypt[32] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b8_s, amount);
        arrToDecrypt[33] = gtUint64.unwrap(newA_s);
        arrToDecrypt[34] = gtUint64.unwrap(newB_s);
        arrToDecrypt[35] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b64_s, amount);
        arrToDecrypt[36] = gtUint64.unwrap(newA_s);
        arrToDecrypt[37] = gtUint64.unwrap(newB_s);
        arrToDecrypt[38] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b16_s, amount);
        arrToDecrypt[39] = gtUint64.unwrap(newA_s);
        arrToDecrypt[40] = gtUint64.unwrap(newB_s);
        arrToDecrypt[41] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b64_s, amount);
        arrToDecrypt[42] = gtUint64.unwrap(newA_s);
        arrToDecrypt[43] = gtUint64.unwrap(newB_s);
        arrToDecrypt[44] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b32_s, amount);
        arrToDecrypt[45] = gtUint64.unwrap(newA_s);
        arrToDecrypt[46] = gtUint64.unwrap(newB_s);
        arrToDecrypt[47] = gtBool.unwrap(res_s);
    }

    function computeAndCheckTransfer128(AllGTCastingValues memory allGTCastingValues, uint8 amount, uint256[] memory arrToDecrypt) public {

        // Check all options for casting to 64 while amount is scalar
        (gtUint128 newA_s, gtUint128 newB_s, gtBool res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b128_s, amount);
        arrToDecrypt[48] = gtUint128.unwrap(newA_s);
        arrToDecrypt[49] = gtUint128.unwrap(newB_s);
        arrToDecrypt[50] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b128_s, amount);
        arrToDecrypt[51] = gtUint128.unwrap(newA_s);
        arrToDecrypt[52] = gtUint128.unwrap(newB_s);
        arrToDecrypt[53] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b8_s, amount);
        arrToDecrypt[54] = gtUint128.unwrap(newA_s);
        arrToDecrypt[55] = gtUint128.unwrap(newB_s);
        arrToDecrypt[56] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b128_s, amount);
        arrToDecrypt[57] = gtUint128.unwrap(newA_s);
        arrToDecrypt[58] = gtUint128.unwrap(newB_s);
        arrToDecrypt[59] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b16_s, amount);
        arrToDecrypt[60] = gtUint128.unwrap(newA_s);
        arrToDecrypt[61] = gtUint128.unwrap(newB_s);
        arrToDecrypt[62] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b128_s, amount);
        arrToDecrypt[63] = gtUint128.unwrap(newA_s);
        arrToDecrypt[64] = gtUint128.unwrap(newB_s);
        arrToDecrypt[65] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b32_s, amount);
        arrToDecrypt[66] = gtUint128.unwrap(newA_s);
        arrToDecrypt[67] = gtUint128.unwrap(newB_s);
        arrToDecrypt[68] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b128_s, amount);
        arrToDecrypt[69] = gtUint128.unwrap(newA_s);
        arrToDecrypt[70] = gtUint128.unwrap(newB_s);
        arrToDecrypt[71] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b64_s, amount);
        arrToDecrypt[72] = gtUint128.unwrap(newA_s);
        arrToDecrypt[73] = gtUint128.unwrap(newB_s);
        arrToDecrypt[74] = gtBool.unwrap(res_s);
    }

    function computeAndCheckTransfer256(AllGTCastingValues memory allGTCastingValues, uint8 amount, uint256[] memory arrToDecrypt) public {

        // Check all options for casting to 64 while amount is scalar
        (gtUint256 newA_s, gtUint256 newB_s, gtBool res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b256_s, amount);
        arrToDecrypt[75] = gtUint256.unwrap(newA_s);
        arrToDecrypt[76] = gtUint256.unwrap(newB_s);
        arrToDecrypt[77] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b256_s, amount);
        arrToDecrypt[78] = gtUint256.unwrap(newA_s);
        arrToDecrypt[79] = gtUint256.unwrap(newB_s);
        arrToDecrypt[80] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b8_s, amount);
        arrToDecrypt[81] = gtUint256.unwrap(newA_s);
        arrToDecrypt[82] = gtUint256.unwrap(newB_s);
        arrToDecrypt[83] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b256_s, amount);
        arrToDecrypt[84] = gtUint256.unwrap(newA_s);
        arrToDecrypt[85] = gtUint256.unwrap(newB_s);
        arrToDecrypt[86] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b16_s, amount);
        arrToDecrypt[87] = gtUint256.unwrap(newA_s);
        arrToDecrypt[88] = gtUint256.unwrap(newB_s);
        arrToDecrypt[89] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b256_s, amount);
        arrToDecrypt[90] = gtUint256.unwrap(newA_s);
        arrToDecrypt[91] = gtUint256.unwrap(newB_s);
        arrToDecrypt[92] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b32_s, amount);
        arrToDecrypt[93] = gtUint256.unwrap(newA_s);
        arrToDecrypt[94] = gtUint256.unwrap(newB_s);
        arrToDecrypt[95] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b256_s, amount);
        arrToDecrypt[96] = gtUint256.unwrap(newA_s);
        arrToDecrypt[97] = gtUint256.unwrap(newB_s);
        arrToDecrypt[98] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b64_s, amount);
        arrToDecrypt[99] = gtUint256.unwrap(newA_s);
        arrToDecrypt[100] = gtUint256.unwrap(newB_s);
        arrToDecrypt[101] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b256_s, amount);
        arrToDecrypt[102] = gtUint256.unwrap(newA_s);
        arrToDecrypt[103] = gtUint256.unwrap(newB_s);
        arrToDecrypt[104] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b128_s, amount);
        arrToDecrypt[105] = gtUint256.unwrap(newA_s);
        arrToDecrypt[106] = gtUint256.unwrap(newB_s);
        arrToDecrypt[107] = gtBool.unwrap(res_s);
    }


    function transferTest(uint8 a, uint8 b, uint8 amount) public returns (uint256) {
        AllGTCastingValues memory allGTCastingValues;
        allGTCastingValues.a8_s = MpcCore.setPublic8(a);
        allGTCastingValues.b8_s = MpcCore.setPublic8(b);
        allGTCastingValues.a16_s =  MpcCore.setPublic16(a);
        allGTCastingValues.b16_s =  MpcCore.setPublic16(b);
        allGTCastingValues.a32_s =  MpcCore.setPublic32(a);
        allGTCastingValues.b32_s =  MpcCore.setPublic32(b);
        allGTCastingValues.a64_s =  MpcCore.setPublic64(a);
        allGTCastingValues.b64_s =  MpcCore.setPublic64(b);
        allGTCastingValues.a128_s =  MpcCore.setPublic128(a);
        allGTCastingValues.b128_s =  MpcCore.setPublic128(b);
        allGTCastingValues.a256_s =  MpcCore.setPublic256(a);
        allGTCastingValues.b256_s =  MpcCore.setPublic256(b);
        
        // Compute all operations and put the result handles in an array
        uint256[] memory arrToDecrypt = new uint256[](108);

        // Calculate the expected result 
        (gtUint8 newA_s, gtUint8 newB_s, gtBool res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b8_s, amount);
        arrToDecrypt[0] = gtUint8.unwrap(newA_s);
        arrToDecrypt[1] = gtUint8.unwrap(newB_s);
        arrToDecrypt[2] = gtBool.unwrap(res_s);

        // Calculate the result with casting to 16
        computeAndCheckTransfer16(allGTCastingValues, amount, arrToDecrypt);

        // Calculate the result with casting to 32
        computeAndCheckTransfer32(allGTCastingValues, amount, arrToDecrypt);

        // Calculate the result with casting to 64
        computeAndCheckTransfer64(allGTCastingValues, amount, arrToDecrypt);

        // Calculate the result with casting to 128
        computeAndCheckTransfer128(allGTCastingValues, amount, arrToDecrypt);

        // Calculate the result with casting to 256
        computeAndCheckTransfer256(allGTCastingValues, amount, arrToDecrypt);
    
        return requestDecryption(arrToDecrypt, this.checkTransferResults.selector); 
    }

    function checkTransferResults(uint256 decryptID, bytes[] calldata output, bytes calldata signature) public {
        require(checkCallbackHandles(decryptID, output.length), "checkTransferResults: Invalid callback parameters");
        
        uint8 firstNewA = abi.decode(output[0], (uint8));
        uint8 firstNewB = abi.decode(output[1], (uint8));
        bool firstRes = abi.decode(output[2], (bool));
        
        for (uint256 i = 3; i < output.length; i+=3) {
            uint8 newA = abi.decode(output[i], (uint8));
            uint8 newB = abi.decode(output[i+1], (uint8));
            bool res = abi.decode(output[i+2], (bool));
            require(newA == firstNewA && newB == firstNewB && res == firstRes, "checkTransferResults: Invalid output");
        }

        transferDecrypted = true;
        newA = firstNewA;
        newB = firstNewB;
        result = firstRes;
    }
}