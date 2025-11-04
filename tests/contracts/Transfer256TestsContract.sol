// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "MpcCore.sol";
import "../../lib/onchain/contracts/DecryptionCaller.sol";

contract Transfer256TestsContract is DecryptionCaller {

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

    struct AllAmountValues {
        gtUint8 amount8_s;
        gtUint16 amount16_s;
        gtUint32 amount32_s;
        gtUint64 amount64_s;
        gtUint128 amount128_s;
        gtUint256 amount256_s;
        uint8 amount;
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

    function computeAndCheckTransfer256(AllGTCastingValues memory allGTCastingValues, AllAmountValues memory allAmountValues, uint256[] memory arrToDecrypt) public {

        // Check all options for casting to 256 while amount is 256
        (gtUint256 newA_s, gtUint256 newB_s, gtBool res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b256_s, allAmountValues.amount256_s);
        arrToDecrypt[0] = gtUint256.unwrap(newA_s);
        arrToDecrypt[1] = gtUint256.unwrap(newB_s);
        arrToDecrypt[2] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b256_s, allAmountValues.amount256_s);
        arrToDecrypt[3] = gtUint256.unwrap(newA_s);
        arrToDecrypt[4] = gtUint256.unwrap(newB_s);
        arrToDecrypt[5] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b8_s, allAmountValues.amount256_s);
        arrToDecrypt[6] = gtUint256.unwrap(newA_s);
        arrToDecrypt[7] = gtUint256.unwrap(newB_s);
        arrToDecrypt[8] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b256_s, allAmountValues.amount256_s);
        arrToDecrypt[9] = gtUint256.unwrap(newA_s);
        arrToDecrypt[10] = gtUint256.unwrap(newB_s);
        arrToDecrypt[11] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b16_s, allAmountValues.amount256_s);
        arrToDecrypt[12] = gtUint256.unwrap(newA_s);
        arrToDecrypt[13] = gtUint256.unwrap(newB_s);
        arrToDecrypt[14] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b256_s, allAmountValues.amount256_s);
        arrToDecrypt[15] = gtUint256.unwrap(newA_s);
        arrToDecrypt[16] = gtUint256.unwrap(newB_s);
        arrToDecrypt[17] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b32_s, allAmountValues.amount256_s);
        arrToDecrypt[18] = gtUint256.unwrap(newA_s);
        arrToDecrypt[19] = gtUint256.unwrap(newB_s);
        arrToDecrypt[20] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b256_s, allAmountValues.amount256_s);
        arrToDecrypt[21] = gtUint256.unwrap(newA_s);
        arrToDecrypt[22] = gtUint256.unwrap(newB_s);
        arrToDecrypt[23] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b64_s, allAmountValues.amount256_s);
        arrToDecrypt[24] = gtUint256.unwrap(newA_s);
        arrToDecrypt[25] = gtUint256.unwrap(newB_s);
        arrToDecrypt[26] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b256_s, allAmountValues.amount256_s);
        arrToDecrypt[27] = gtUint256.unwrap(newA_s);
        arrToDecrypt[28] = gtUint256.unwrap(newB_s);
        arrToDecrypt[29] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b128_s, allAmountValues.amount256_s);
        arrToDecrypt[30] = gtUint256.unwrap(newA_s);
        arrToDecrypt[31] = gtUint256.unwrap(newB_s);
        arrToDecrypt[32] = gtBool.unwrap(res_s);

        // Check all options for casting to 256 while amount is 128
        ( newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b256_s, allAmountValues.amount128_s);
        arrToDecrypt[33] = gtUint256.unwrap(newA_s);
        arrToDecrypt[34] = gtUint256.unwrap(newB_s);
        arrToDecrypt[35] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b256_s, allAmountValues.amount128_s);
        arrToDecrypt[36] = gtUint256.unwrap(newA_s);
        arrToDecrypt[37] = gtUint256.unwrap(newB_s);
        arrToDecrypt[38] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b8_s, allAmountValues.amount128_s);
        arrToDecrypt[39] = gtUint256.unwrap(newA_s);
        arrToDecrypt[40] = gtUint256.unwrap(newB_s);
        arrToDecrypt[41] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b256_s, allAmountValues.amount128_s);
        arrToDecrypt[42] = gtUint256.unwrap(newA_s);
        arrToDecrypt[43] = gtUint256.unwrap(newB_s);
        arrToDecrypt[44] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b16_s, allAmountValues.amount128_s);
        arrToDecrypt[45] = gtUint256.unwrap(newA_s);
        arrToDecrypt[46] = gtUint256.unwrap(newB_s);
        arrToDecrypt[47] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b256_s, allAmountValues.amount128_s);
        arrToDecrypt[48] = gtUint256.unwrap(newA_s);
        arrToDecrypt[49] = gtUint256.unwrap(newB_s);
        arrToDecrypt[50] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b32_s, allAmountValues.amount128_s);
        arrToDecrypt[51] = gtUint256.unwrap(newA_s);
        arrToDecrypt[52] = gtUint256.unwrap(newB_s);
        arrToDecrypt[53] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b256_s, allAmountValues.amount128_s);
        arrToDecrypt[54] = gtUint256.unwrap(newA_s);
        arrToDecrypt[55] = gtUint256.unwrap(newB_s);
        arrToDecrypt[56] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b64_s, allAmountValues.amount128_s);
        arrToDecrypt[57] = gtUint256.unwrap(newA_s);
        arrToDecrypt[58] = gtUint256.unwrap(newB_s);
        arrToDecrypt[59] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b256_s, allAmountValues.amount128_s);
        arrToDecrypt[60] = gtUint256.unwrap(newA_s);
        arrToDecrypt[61] = gtUint256.unwrap(newB_s);
        arrToDecrypt[62] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b128_s, allAmountValues.amount128_s);
        arrToDecrypt[63] = gtUint256.unwrap(newA_s);
        arrToDecrypt[64] = gtUint256.unwrap(newB_s);
        arrToDecrypt[65] = gtBool.unwrap(res_s);

        // Check all options for casting to 256 while amount is 64
        ( newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b256_s, allAmountValues.amount64_s);
        arrToDecrypt[66] = gtUint256.unwrap(newA_s);
        arrToDecrypt[67] = gtUint256.unwrap(newB_s);
        arrToDecrypt[68] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b256_s, allAmountValues.amount64_s);
        arrToDecrypt[69] = gtUint256.unwrap(newA_s);
        arrToDecrypt[70] = gtUint256.unwrap(newB_s);
        arrToDecrypt[71] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b8_s, allAmountValues.amount64_s);
        arrToDecrypt[72] = gtUint256.unwrap(newA_s);
        arrToDecrypt[73] = gtUint256.unwrap(newB_s);
        arrToDecrypt[74] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b256_s, allAmountValues.amount64_s);
        arrToDecrypt[75] = gtUint256.unwrap(newA_s);
        arrToDecrypt[76] = gtUint256.unwrap(newB_s);
        arrToDecrypt[77] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b16_s, allAmountValues.amount64_s);
        arrToDecrypt[78] = gtUint256.unwrap(newA_s);
        arrToDecrypt[79] = gtUint256.unwrap(newB_s);
        arrToDecrypt[80] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b256_s, allAmountValues.amount64_s);
        arrToDecrypt[81] = gtUint256.unwrap(newA_s);
        arrToDecrypt[82] = gtUint256.unwrap(newB_s);
        arrToDecrypt[83] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b32_s, allAmountValues.amount64_s);
        arrToDecrypt[84] = gtUint256.unwrap(newA_s);
        arrToDecrypt[85] = gtUint256.unwrap(newB_s);
        arrToDecrypt[86] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b256_s, allAmountValues.amount64_s);
        arrToDecrypt[87] = gtUint256.unwrap(newA_s);
        arrToDecrypt[88] = gtUint256.unwrap(newB_s);
        arrToDecrypt[89] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b64_s, allAmountValues.amount64_s);
        arrToDecrypt[90] = gtUint256.unwrap(newA_s);
        arrToDecrypt[91] = gtUint256.unwrap(newB_s);
        arrToDecrypt[92] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b256_s, allAmountValues.amount64_s);
        arrToDecrypt[93] = gtUint256.unwrap(newA_s);
        arrToDecrypt[94] = gtUint256.unwrap(newB_s);
        arrToDecrypt[95] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b128_s, allAmountValues.amount64_s);
        arrToDecrypt[96] = gtUint256.unwrap(newA_s);
        arrToDecrypt[97] = gtUint256.unwrap(newB_s);
        arrToDecrypt[98] = gtBool.unwrap(res_s);

        // Check all options for casting to 256 while amount is 32
        ( newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b256_s, allAmountValues.amount32_s);
        arrToDecrypt[99] = gtUint256.unwrap(newA_s);
        arrToDecrypt[100] = gtUint256.unwrap(newB_s);
        arrToDecrypt[101] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b256_s, allAmountValues.amount32_s);
        arrToDecrypt[102] = gtUint256.unwrap(newA_s);
        arrToDecrypt[103] = gtUint256.unwrap(newB_s);
        arrToDecrypt[104] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b8_s, allAmountValues.amount32_s);
        arrToDecrypt[105] = gtUint256.unwrap(newA_s);
        arrToDecrypt[106] = gtUint256.unwrap(newB_s);
        arrToDecrypt[107] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b256_s, allAmountValues.amount32_s);
        arrToDecrypt[108] = gtUint256.unwrap(newA_s);
        arrToDecrypt[109] = gtUint256.unwrap(newB_s);
        arrToDecrypt[110] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b16_s, allAmountValues.amount32_s);
        arrToDecrypt[111] = gtUint256.unwrap(newA_s);
        arrToDecrypt[112] = gtUint256.unwrap(newB_s);
        arrToDecrypt[113] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b256_s, allAmountValues.amount32_s);
        arrToDecrypt[114] = gtUint256.unwrap(newA_s);
        arrToDecrypt[115] = gtUint256.unwrap(newB_s);
        arrToDecrypt[116] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b32_s, allAmountValues.amount32_s);
        arrToDecrypt[117] = gtUint256.unwrap(newA_s);
        arrToDecrypt[118] = gtUint256.unwrap(newB_s);
        arrToDecrypt[119] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b256_s, allAmountValues.amount32_s);
        arrToDecrypt[120] = gtUint256.unwrap(newA_s);
        arrToDecrypt[121] = gtUint256.unwrap(newB_s);
        arrToDecrypt[122] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b64_s, allAmountValues.amount32_s);
        arrToDecrypt[123] = gtUint256.unwrap(newA_s);
        arrToDecrypt[124] = gtUint256.unwrap(newB_s);
        arrToDecrypt[125] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b256_s, allAmountValues.amount32_s);
        arrToDecrypt[126] = gtUint256.unwrap(newA_s);
        arrToDecrypt[127] = gtUint256.unwrap(newB_s);
        arrToDecrypt[128] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b128_s, allAmountValues.amount32_s);
        arrToDecrypt[129] = gtUint256.unwrap(newA_s);
        arrToDecrypt[130] = gtUint256.unwrap(newB_s);
        arrToDecrypt[131] = gtBool.unwrap(res_s);

        // Check all options for casting to 256 while amount is 16
        ( newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b256_s, allAmountValues.amount16_s);
        arrToDecrypt[132] = gtUint256.unwrap(newA_s);
        arrToDecrypt[133] = gtUint256.unwrap(newB_s);
        arrToDecrypt[134] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b256_s, allAmountValues.amount16_s);
        arrToDecrypt[135] = gtUint256.unwrap(newA_s);
        arrToDecrypt[136] = gtUint256.unwrap(newB_s);
        arrToDecrypt[137] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b8_s, allAmountValues.amount16_s);
        arrToDecrypt[138] = gtUint256.unwrap(newA_s);
        arrToDecrypt[139] = gtUint256.unwrap(newB_s);
        arrToDecrypt[140] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b256_s, allAmountValues.amount16_s);
        arrToDecrypt[141] = gtUint256.unwrap(newA_s);
        arrToDecrypt[142] = gtUint256.unwrap(newB_s);
        arrToDecrypt[143] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b16_s, allAmountValues.amount16_s);
        arrToDecrypt[144] = gtUint256.unwrap(newA_s);
        arrToDecrypt[145] = gtUint256.unwrap(newB_s);
        arrToDecrypt[146] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b256_s, allAmountValues.amount16_s);
        arrToDecrypt[147] = gtUint256.unwrap(newA_s);
        arrToDecrypt[148] = gtUint256.unwrap(newB_s);
        arrToDecrypt[149] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b32_s, allAmountValues.amount16_s);
        arrToDecrypt[150] = gtUint256.unwrap(newA_s);
        arrToDecrypt[151] = gtUint256.unwrap(newB_s);
        arrToDecrypt[152] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b256_s, allAmountValues.amount16_s);
        arrToDecrypt[153] = gtUint256.unwrap(newA_s);
        arrToDecrypt[154] = gtUint256.unwrap(newB_s);
        arrToDecrypt[155] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b64_s, allAmountValues.amount16_s);
        arrToDecrypt[156] = gtUint256.unwrap(newA_s);
        arrToDecrypt[157] = gtUint256.unwrap(newB_s);
        arrToDecrypt[158] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b256_s, allAmountValues.amount16_s);
        arrToDecrypt[159] = gtUint256.unwrap(newA_s);
        arrToDecrypt[160] = gtUint256.unwrap(newB_s);
        arrToDecrypt[161] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b128_s, allAmountValues.amount16_s);
        arrToDecrypt[162] = gtUint256.unwrap(newA_s);
        arrToDecrypt[163] = gtUint256.unwrap(newB_s);
        arrToDecrypt[164] = gtBool.unwrap(res_s);

        // Check all options for casting to 256 while amount is 8
        ( newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b256_s, allAmountValues.amount8_s);
        arrToDecrypt[165] = gtUint256.unwrap(newA_s);
        arrToDecrypt[166] = gtUint256.unwrap(newB_s);
        arrToDecrypt[167] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b256_s, allAmountValues.amount8_s);
        arrToDecrypt[168] = gtUint256.unwrap(newA_s);
        arrToDecrypt[169] = gtUint256.unwrap(newB_s);
        arrToDecrypt[170] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b8_s, allAmountValues.amount8_s);
        arrToDecrypt[171] = gtUint256.unwrap(newA_s);
        arrToDecrypt[172] = gtUint256.unwrap(newB_s);
        arrToDecrypt[173] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b256_s, allAmountValues.amount8_s);
        arrToDecrypt[174] = gtUint256.unwrap(newA_s);
        arrToDecrypt[175] = gtUint256.unwrap(newB_s);
        arrToDecrypt[176] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b16_s, allAmountValues.amount8_s);
        arrToDecrypt[177] = gtUint256.unwrap(newA_s);
        arrToDecrypt[178] = gtUint256.unwrap(newB_s);
        arrToDecrypt[179] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b256_s, allAmountValues.amount8_s);
        arrToDecrypt[180] = gtUint256.unwrap(newA_s);
        arrToDecrypt[181] = gtUint256.unwrap(newB_s);
        arrToDecrypt[182] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b32_s, allAmountValues.amount8_s);
        arrToDecrypt[183] = gtUint256.unwrap(newA_s);
        arrToDecrypt[184] = gtUint256.unwrap(newB_s);
        arrToDecrypt[185] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b256_s, allAmountValues.amount8_s);
        arrToDecrypt[186] = gtUint256.unwrap(newA_s);
        arrToDecrypt[187] = gtUint256.unwrap(newB_s);
        arrToDecrypt[188] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b64_s, allAmountValues.amount8_s);
        arrToDecrypt[189] = gtUint256.unwrap(newA_s);
        arrToDecrypt[190] = gtUint256.unwrap(newB_s);
        arrToDecrypt[191] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b256_s, allAmountValues.amount8_s);
        arrToDecrypt[192] = gtUint256.unwrap(newA_s);
        arrToDecrypt[193] = gtUint256.unwrap(newB_s);
        arrToDecrypt[194] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a256_s, allGTCastingValues.b128_s, allAmountValues.amount8_s);
        arrToDecrypt[195] = gtUint256.unwrap(newA_s);
        arrToDecrypt[196] = gtUint256.unwrap(newB_s);
        arrToDecrypt[197] = gtBool.unwrap(res_s);
    }


    function transferTest(uint8 a, uint8 b, uint8 amount) public returns (uint256) {
        AllGTCastingValues memory allGTCastingValues;
        AllAmountValues memory allAmountValues;
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
        allAmountValues.amount8_s = MpcCore.setPublic8(amount);
        allAmountValues.amount16_s = MpcCore.setPublic16(amount);
        allAmountValues.amount32_s = MpcCore.setPublic32(amount);
        allAmountValues.amount64_s = MpcCore.setPublic64(amount);
        allAmountValues.amount128_s = MpcCore.setPublic128(amount);
        allAmountValues.amount256_s = MpcCore.setPublic256(amount);
        allAmountValues.amount = amount;

        // Compute all operations and put the result handles in an array
        uint256[] memory arrToDecrypt = new uint256[](198);

        // Compute operation on 256 bits
        computeAndCheckTransfer256(allGTCastingValues, allAmountValues, arrToDecrypt);
    
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