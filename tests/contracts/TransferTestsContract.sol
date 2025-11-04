// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "MpcCore.sol";
import "../../lib/onchain/contracts/DecryptionCaller.sol";

contract TransferTestsContract is DecryptionCaller {

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
    }

    struct AllAmountValues {
        gtUint8 amount8_s;
        gtUint16 amount16_s;
        gtUint32 amount32_s;
        gtUint64 amount64_s;
        gtUint128 amount128_s;
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

    function computeAndCheckTransfer16(AllGTCastingValues memory allGTCastingValues, AllAmountValues memory allAmountValues, uint256[] memory arrToDecrypt) public {
        // Check all options for casting to 16 while amount is 8
        (gtUint16 newA_s, gtUint16 newB_s, gtBool res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b16_s, allAmountValues.amount8_s);
        arrToDecrypt[3] = gtUint16.unwrap(newA_s);
        arrToDecrypt[4] = gtUint16.unwrap(newB_s);
        arrToDecrypt[5] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b16_s, allAmountValues.amount8_s);
        arrToDecrypt[6] = gtUint16.unwrap(newA_s);
        arrToDecrypt[7] = gtUint16.unwrap(newB_s);
        arrToDecrypt[8] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b8_s, allAmountValues.amount8_s);
        arrToDecrypt[9] = gtUint16.unwrap(newA_s);
        arrToDecrypt[10] = gtUint16.unwrap(newB_s);
        arrToDecrypt[11] = gtBool.unwrap(res_s);

        // Check all options for casting to 16 while amount is 16
        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b16_s, allAmountValues.amount16_s);
        arrToDecrypt[12] = gtUint16.unwrap(newA_s);
        arrToDecrypt[13] = gtUint16.unwrap(newB_s);
        arrToDecrypt[14] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b16_s, allAmountValues.amount16_s);
        arrToDecrypt[15] = gtUint16.unwrap(newA_s);
        arrToDecrypt[16] = gtUint16.unwrap(newB_s);
        arrToDecrypt[17] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b8_s, allAmountValues.amount16_s);
        arrToDecrypt[18] = gtUint16.unwrap(newA_s);
        arrToDecrypt[19] = gtUint16.unwrap(newB_s);
        arrToDecrypt[20] = gtBool.unwrap(res_s);
    }

    function computeAndCheckTransfer32(AllGTCastingValues memory allGTCastingValues, AllAmountValues memory allAmountValues, uint256[] memory arrToDecrypt) public {

        // Check all options for casting to 32 while amount is 32
        (gtUint32 newA_s, gtUint32 newB_s, gtBool res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b32_s, allAmountValues.amount32_s);
        arrToDecrypt[21] = gtUint32.unwrap(newA_s);
        arrToDecrypt[22] = gtUint32.unwrap(newB_s);
        arrToDecrypt[23] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b32_s, allAmountValues.amount32_s);
        arrToDecrypt[24] = gtUint32.unwrap(newA_s);
        arrToDecrypt[25] = gtUint32.unwrap(newB_s);
        arrToDecrypt[26] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b8_s, allAmountValues.amount32_s);
        arrToDecrypt[27] = gtUint32.unwrap(newA_s);
        arrToDecrypt[28] = gtUint32.unwrap(newB_s);
        arrToDecrypt[29] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b32_s, allAmountValues.amount32_s);
        arrToDecrypt[30] = gtUint32.unwrap(newA_s);
        arrToDecrypt[31] = gtUint32.unwrap(newB_s);
        arrToDecrypt[32] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b16_s, allAmountValues.amount32_s);
        arrToDecrypt[33] = gtUint32.unwrap(newA_s);
        arrToDecrypt[34] = gtUint32.unwrap(newB_s);
        arrToDecrypt[35] = gtBool.unwrap(res_s);

        // Check all options for casting to 32 while amount is 8
        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b32_s, allAmountValues.amount8_s);
        arrToDecrypt[36] = gtUint32.unwrap(newA_s);
        arrToDecrypt[37] = gtUint32.unwrap(newB_s);
        arrToDecrypt[38] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b32_s, allAmountValues.amount8_s);
        arrToDecrypt[39] = gtUint32.unwrap(newA_s);
        arrToDecrypt[40] = gtUint32.unwrap(newB_s);
        arrToDecrypt[41] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b8_s, allAmountValues.amount8_s);
        arrToDecrypt[42] = gtUint32.unwrap(newA_s);
        arrToDecrypt[43] = gtUint32.unwrap(newB_s);
        arrToDecrypt[44] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b32_s, allAmountValues.amount8_s);
        arrToDecrypt[45] = gtUint32.unwrap(newA_s);
        arrToDecrypt[46] = gtUint32.unwrap(newB_s);
        arrToDecrypt[47] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b16_s, allAmountValues.amount8_s);
        arrToDecrypt[48] = gtUint32.unwrap(newA_s);
        arrToDecrypt[49] = gtUint32.unwrap(newB_s);
        arrToDecrypt[50] = gtBool.unwrap(res_s);

        // Check all options for casting to 32 while amount is 16
        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b32_s, allAmountValues.amount16_s);
        arrToDecrypt[51] = gtUint32.unwrap(newA_s);
        arrToDecrypt[52] = gtUint32.unwrap(newB_s);
        arrToDecrypt[53] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b32_s, allAmountValues.amount16_s);
        arrToDecrypt[54] = gtUint32.unwrap(newA_s);
        arrToDecrypt[55] = gtUint32.unwrap(newB_s);
        arrToDecrypt[56] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b8_s, allAmountValues.amount16_s);
        arrToDecrypt[57] = gtUint32.unwrap(newA_s);
        arrToDecrypt[58] = gtUint32.unwrap(newB_s);
        arrToDecrypt[59] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b32_s, allAmountValues.amount16_s);
        arrToDecrypt[60] = gtUint32.unwrap(newA_s);
        arrToDecrypt[61] = gtUint32.unwrap(newB_s);
        arrToDecrypt[62] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b16_s, allAmountValues.amount16_s);
        arrToDecrypt[63] = gtUint32.unwrap(newA_s);
        arrToDecrypt[64] = gtUint32.unwrap(newB_s);
        arrToDecrypt[65] = gtBool.unwrap(res_s);
    }

    function computeAndCheckTransfer64(AllGTCastingValues memory allGTCastingValues, AllAmountValues memory allAmountValues, uint256[] memory arrToDecrypt) public {

        // Check all options for casting to 64 while amount is 64
        (gtUint64 newA_s, gtUint64 newB_s, gtBool res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b64_s, allAmountValues.amount64_s);
        arrToDecrypt[66] = gtUint64.unwrap(newA_s);
        arrToDecrypt[67] = gtUint64.unwrap(newB_s);
        arrToDecrypt[68] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b64_s, allAmountValues.amount64_s);
        arrToDecrypt[69] = gtUint64.unwrap(newA_s);
        arrToDecrypt[70] = gtUint64.unwrap(newB_s);
        arrToDecrypt[71] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b8_s, allAmountValues.amount64_s);
        arrToDecrypt[72] = gtUint64.unwrap(newA_s);
        arrToDecrypt[73] = gtUint64.unwrap(newB_s);
        arrToDecrypt[74] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b64_s, allAmountValues.amount64_s);
        arrToDecrypt[75] = gtUint64.unwrap(newA_s);
        arrToDecrypt[76] = gtUint64.unwrap(newB_s);
        arrToDecrypt[77] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b16_s, allAmountValues.amount64_s);
        arrToDecrypt[78] = gtUint64.unwrap(newA_s);
        arrToDecrypt[79] = gtUint64.unwrap(newB_s);
        arrToDecrypt[80] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b64_s, allAmountValues.amount64_s);
        arrToDecrypt[81] = gtUint64.unwrap(newA_s);
        arrToDecrypt[82] = gtUint64.unwrap(newB_s);
        arrToDecrypt[83] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b32_s, allAmountValues.amount64_s);
        arrToDecrypt[84] = gtUint64.unwrap(newA_s);
        arrToDecrypt[85] = gtUint64.unwrap(newB_s);
        arrToDecrypt[86] = gtBool.unwrap(res_s);

        // Check all options for casting to 64 while amount is 32
        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b64_s, allAmountValues.amount32_s);
        arrToDecrypt[87] = gtUint64.unwrap(newA_s);
        arrToDecrypt[88] = gtUint64.unwrap(newB_s);
        arrToDecrypt[89] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b64_s, allAmountValues.amount32_s);
        arrToDecrypt[90] = gtUint64.unwrap(newA_s);
        arrToDecrypt[91] = gtUint64.unwrap(newB_s);
        arrToDecrypt[92] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b8_s, allAmountValues.amount32_s);
        arrToDecrypt[93] = gtUint64.unwrap(newA_s);
        arrToDecrypt[94] = gtUint64.unwrap(newB_s);
        arrToDecrypt[95] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b64_s, allAmountValues.amount32_s);
        arrToDecrypt[96] = gtUint64.unwrap(newA_s);
        arrToDecrypt[97] = gtUint64.unwrap(newB_s);
        arrToDecrypt[98] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b16_s, allAmountValues.amount32_s);
        arrToDecrypt[99] = gtUint64.unwrap(newA_s);
        arrToDecrypt[100] = gtUint64.unwrap(newB_s);
        arrToDecrypt[101] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b64_s, allAmountValues.amount32_s);
        arrToDecrypt[102] = gtUint64.unwrap(newA_s);
        arrToDecrypt[103] = gtUint64.unwrap(newB_s);
        arrToDecrypt[104] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b32_s, allAmountValues.amount32_s);
        arrToDecrypt[105] = gtUint64.unwrap(newA_s);
        arrToDecrypt[106] = gtUint64.unwrap(newB_s);
        arrToDecrypt[107] = gtBool.unwrap(res_s);

        // Check all options for casting to 64 while amount is 8
        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b64_s, allAmountValues.amount8_s);
        arrToDecrypt[108] = gtUint64.unwrap(newA_s);
        arrToDecrypt[109] = gtUint64.unwrap(newB_s);
        arrToDecrypt[110] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b64_s, allAmountValues.amount8_s);
        arrToDecrypt[111] = gtUint64.unwrap(newA_s);
        arrToDecrypt[112] = gtUint64.unwrap(newB_s);
        arrToDecrypt[113] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b8_s, allAmountValues.amount8_s);
        arrToDecrypt[114] = gtUint64.unwrap(newA_s);
        arrToDecrypt[115] = gtUint64.unwrap(newB_s);
        arrToDecrypt[116] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b64_s, allAmountValues.amount8_s);
        arrToDecrypt[117] = gtUint64.unwrap(newA_s);
        arrToDecrypt[118] = gtUint64.unwrap(newB_s);
        arrToDecrypt[119] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b16_s, allAmountValues.amount8_s);
        arrToDecrypt[120] = gtUint64.unwrap(newA_s);
        arrToDecrypt[121] = gtUint64.unwrap(newB_s);
        arrToDecrypt[122] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b64_s, allAmountValues.amount8_s);
        arrToDecrypt[123] = gtUint64.unwrap(newA_s);
        arrToDecrypt[124] = gtUint64.unwrap(newB_s);
        arrToDecrypt[125] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b32_s, allAmountValues.amount8_s);
        arrToDecrypt[126] = gtUint64.unwrap(newA_s);
        arrToDecrypt[127] = gtUint64.unwrap(newB_s);
        arrToDecrypt[128] = gtBool.unwrap(res_s);
       
        // Check all options for casting to 64 while amount is 16
        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b64_s, allAmountValues.amount16_s);
        arrToDecrypt[129] = gtUint64.unwrap(newA_s);
        arrToDecrypt[130] = gtUint64.unwrap(newB_s);
        arrToDecrypt[131] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b64_s, allAmountValues.amount16_s);
        arrToDecrypt[132] = gtUint64.unwrap(newA_s);
        arrToDecrypt[133] = gtUint64.unwrap(newB_s);
        arrToDecrypt[134] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b8_s, allAmountValues.amount16_s);
        arrToDecrypt[135] = gtUint64.unwrap(newA_s);
        arrToDecrypt[136] = gtUint64.unwrap(newB_s);
        arrToDecrypt[137] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b64_s, allAmountValues.amount16_s);
        arrToDecrypt[138] = gtUint64.unwrap(newA_s);
        arrToDecrypt[139] = gtUint64.unwrap(newB_s);
        arrToDecrypt[140] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b16_s, allAmountValues.amount16_s);
        arrToDecrypt[141] = gtUint64.unwrap(newA_s);
        arrToDecrypt[142] = gtUint64.unwrap(newB_s);
        arrToDecrypt[143] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b64_s, allAmountValues.amount16_s);
        arrToDecrypt[144] = gtUint64.unwrap(newA_s);
        arrToDecrypt[145] = gtUint64.unwrap(newB_s);
        arrToDecrypt[146] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b32_s, allAmountValues.amount16_s);
        arrToDecrypt[147] = gtUint64.unwrap(newA_s);
        arrToDecrypt[148] = gtUint64.unwrap(newB_s);
        arrToDecrypt[149] = gtBool.unwrap(res_s);
    }

    function computeAndCheckTransfer128(AllGTCastingValues memory allGTCastingValues, AllAmountValues memory allAmountValues, uint256[] memory arrToDecrypt) public {

        // Check all options for casting to 128 while amount is 128
        (gtUint128 newA_s, gtUint128 newB_s, gtBool res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b128_s, allAmountValues.amount128_s);
        arrToDecrypt[150] = gtUint128.unwrap(newA_s);
        arrToDecrypt[151] = gtUint128.unwrap(newB_s);
        arrToDecrypt[152] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b128_s, allAmountValues.amount128_s);
        arrToDecrypt[153] = gtUint128.unwrap(newA_s);
        arrToDecrypt[154] = gtUint128.unwrap(newB_s);
        arrToDecrypt[155] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b8_s, allAmountValues.amount128_s);
        arrToDecrypt[156] = gtUint128.unwrap(newA_s);
        arrToDecrypt[157] = gtUint128.unwrap(newB_s);
        arrToDecrypt[158] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b128_s, allAmountValues.amount128_s);
        arrToDecrypt[159] = gtUint128.unwrap(newA_s);
        arrToDecrypt[160] = gtUint128.unwrap(newB_s);
        arrToDecrypt[161] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b16_s, allAmountValues.amount128_s);
        arrToDecrypt[162] = gtUint128.unwrap(newA_s);
        arrToDecrypt[163] = gtUint128.unwrap(newB_s);
        arrToDecrypt[164] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b128_s, allAmountValues.amount128_s);
        arrToDecrypt[165] = gtUint128.unwrap(newA_s);
        arrToDecrypt[166] = gtUint128.unwrap(newB_s);
        arrToDecrypt[167] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b32_s, allAmountValues.amount128_s);
        arrToDecrypt[168] = gtUint128.unwrap(newA_s);
        arrToDecrypt[169] = gtUint128.unwrap(newB_s);
        arrToDecrypt[170] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b128_s, allAmountValues.amount128_s);
        arrToDecrypt[171] = gtUint128.unwrap(newA_s);
        arrToDecrypt[172] = gtUint128.unwrap(newB_s);
        arrToDecrypt[173] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b64_s, allAmountValues.amount128_s);
        arrToDecrypt[174] = gtUint128.unwrap(newA_s);
        arrToDecrypt[175] = gtUint128.unwrap(newB_s);
        arrToDecrypt[176] = gtBool.unwrap(res_s);

        // Check all options for casting to 128 while amount is 64
        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b128_s, allAmountValues.amount64_s);
        arrToDecrypt[177] = gtUint128.unwrap(newA_s);
        arrToDecrypt[178] = gtUint128.unwrap(newB_s);
        arrToDecrypt[179] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b128_s, allAmountValues.amount64_s);
        arrToDecrypt[180] = gtUint128.unwrap(newA_s);
        arrToDecrypt[181] = gtUint128.unwrap(newB_s);
        arrToDecrypt[182] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b8_s, allAmountValues.amount64_s);
        arrToDecrypt[183] = gtUint128.unwrap(newA_s);
        arrToDecrypt[184] = gtUint128.unwrap(newB_s);
        arrToDecrypt[185] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b128_s, allAmountValues.amount64_s);
        arrToDecrypt[186] = gtUint128.unwrap(newA_s);
        arrToDecrypt[187] = gtUint128.unwrap(newB_s);
        arrToDecrypt[188] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b16_s, allAmountValues.amount64_s);
        arrToDecrypt[189] = gtUint128.unwrap(newA_s);
        arrToDecrypt[190] = gtUint128.unwrap(newB_s);
        arrToDecrypt[191] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b128_s, allAmountValues.amount64_s);
        arrToDecrypt[192] = gtUint128.unwrap(newA_s);
        arrToDecrypt[193] = gtUint128.unwrap(newB_s);
        arrToDecrypt[194] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b32_s, allAmountValues.amount64_s);
        arrToDecrypt[195] = gtUint128.unwrap(newA_s);
        arrToDecrypt[196] = gtUint128.unwrap(newB_s);
        arrToDecrypt[197] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b128_s, allAmountValues.amount64_s);
        arrToDecrypt[198] = gtUint128.unwrap(newA_s);
        arrToDecrypt[199] = gtUint128.unwrap(newB_s);
        arrToDecrypt[200] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b64_s, allAmountValues.amount64_s);
        arrToDecrypt[201] = gtUint128.unwrap(newA_s);
        arrToDecrypt[202] = gtUint128.unwrap(newB_s);
        arrToDecrypt[203] = gtBool.unwrap(res_s);

        // Check all options for casting to 128 while amount is 32
        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b128_s, allAmountValues.amount32_s);
        arrToDecrypt[204] = gtUint128.unwrap(newA_s);
        arrToDecrypt[205] = gtUint128.unwrap(newB_s);
        arrToDecrypt[206] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b128_s, allAmountValues.amount32_s);
        arrToDecrypt[207] = gtUint128.unwrap(newA_s);
        arrToDecrypt[208] = gtUint128.unwrap(newB_s);
        arrToDecrypt[209] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b8_s, allAmountValues.amount32_s);
        arrToDecrypt[210] = gtUint128.unwrap(newA_s);
        arrToDecrypt[211] = gtUint128.unwrap(newB_s);
        arrToDecrypt[212] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b128_s, allAmountValues.amount32_s);
        arrToDecrypt[213] = gtUint128.unwrap(newA_s);
        arrToDecrypt[214] = gtUint128.unwrap(newB_s);
        arrToDecrypt[215] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b16_s, allAmountValues.amount32_s);
        arrToDecrypt[216] = gtUint128.unwrap(newA_s);
        arrToDecrypt[217] = gtUint128.unwrap(newB_s);
        arrToDecrypt[218] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b128_s, allAmountValues.amount32_s);
        arrToDecrypt[219] = gtUint128.unwrap(newA_s);
        arrToDecrypt[220] = gtUint128.unwrap(newB_s);
        arrToDecrypt[221] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b32_s, allAmountValues.amount32_s);
        arrToDecrypt[222] = gtUint128.unwrap(newA_s);
        arrToDecrypt[223] = gtUint128.unwrap(newB_s);
        arrToDecrypt[224] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b128_s, allAmountValues.amount32_s);
        arrToDecrypt[225] = gtUint128.unwrap(newA_s);
        arrToDecrypt[226] = gtUint128.unwrap(newB_s);
        arrToDecrypt[227] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b64_s, allAmountValues.amount32_s);
        arrToDecrypt[228] = gtUint128.unwrap(newA_s);
        arrToDecrypt[229] = gtUint128.unwrap(newB_s);
        arrToDecrypt[230] = gtBool.unwrap(res_s);

        // Check all options for casting to 128 while amount is 16
        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b128_s, allAmountValues.amount16_s);
        arrToDecrypt[231] = gtUint128.unwrap(newA_s);
        arrToDecrypt[232] = gtUint128.unwrap(newB_s);
        arrToDecrypt[233] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b128_s, allAmountValues.amount16_s);
        arrToDecrypt[234] = gtUint128.unwrap(newA_s);
        arrToDecrypt[235] = gtUint128.unwrap(newB_s);
        arrToDecrypt[236] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b8_s, allAmountValues.amount16_s);
        arrToDecrypt[237] = gtUint128.unwrap(newA_s);
        arrToDecrypt[238] = gtUint128.unwrap(newB_s);
        arrToDecrypt[239] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b128_s, allAmountValues.amount16_s);
        arrToDecrypt[240] = gtUint128.unwrap(newA_s);
        arrToDecrypt[241] = gtUint128.unwrap(newB_s);
        arrToDecrypt[242] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b16_s, allAmountValues.amount16_s);
        arrToDecrypt[243] = gtUint128.unwrap(newA_s);
        arrToDecrypt[244] = gtUint128.unwrap(newB_s);
        arrToDecrypt[245] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b128_s, allAmountValues.amount16_s);
        arrToDecrypt[246] = gtUint128.unwrap(newA_s);
        arrToDecrypt[247] = gtUint128.unwrap(newB_s);
        arrToDecrypt[248] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b32_s, allAmountValues.amount16_s);
        arrToDecrypt[249] = gtUint128.unwrap(newA_s);
        arrToDecrypt[250] = gtUint128.unwrap(newB_s);
        arrToDecrypt[251] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b128_s, allAmountValues.amount16_s);
        arrToDecrypt[252] = gtUint128.unwrap(newA_s);
        arrToDecrypt[253] = gtUint128.unwrap(newB_s);
        arrToDecrypt[254] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b64_s, allAmountValues.amount16_s);
        arrToDecrypt[255] = gtUint128.unwrap(newA_s);
        arrToDecrypt[256] = gtUint128.unwrap(newB_s);
        arrToDecrypt[257] = gtBool.unwrap(res_s);

        // Check all options for casting to 128 while amount is 8
        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b128_s, allAmountValues.amount8_s);
        arrToDecrypt[258] = gtUint128.unwrap(newA_s);
        arrToDecrypt[259] = gtUint128.unwrap(newB_s);
        arrToDecrypt[260] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b128_s, allAmountValues.amount8_s);
        arrToDecrypt[261] = gtUint128.unwrap(newA_s);
        arrToDecrypt[262] = gtUint128.unwrap(newB_s);
        arrToDecrypt[263] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b8_s, allAmountValues.amount8_s);
        arrToDecrypt[264] = gtUint128.unwrap(newA_s);
        arrToDecrypt[265] = gtUint128.unwrap(newB_s);
        arrToDecrypt[266] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a16_s, allGTCastingValues.b128_s, allAmountValues.amount8_s);
        arrToDecrypt[267] = gtUint128.unwrap(newA_s);
        arrToDecrypt[268] = gtUint128.unwrap(newB_s);
        arrToDecrypt[269] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b16_s, allAmountValues.amount8_s);
        arrToDecrypt[270] = gtUint128.unwrap(newA_s);
        arrToDecrypt[271] = gtUint128.unwrap(newB_s);
        arrToDecrypt[272] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a32_s, allGTCastingValues.b128_s, allAmountValues.amount8_s);
        arrToDecrypt[273] = gtUint128.unwrap(newA_s);
        arrToDecrypt[274] = gtUint128.unwrap(newB_s);
        arrToDecrypt[275] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b32_s, allAmountValues.amount8_s);
        arrToDecrypt[276] = gtUint128.unwrap(newA_s);
        arrToDecrypt[277] = gtUint128.unwrap(newB_s);
        arrToDecrypt[278] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a64_s, allGTCastingValues.b128_s, allAmountValues.amount8_s);
        arrToDecrypt[279] = gtUint128.unwrap(newA_s);
        arrToDecrypt[280] = gtUint128.unwrap(newB_s);
        arrToDecrypt[281] = gtBool.unwrap(res_s);

        (newA_s, newB_s, res_s) = MpcCore.transfer(allGTCastingValues.a128_s, allGTCastingValues.b64_s, allAmountValues.amount8_s);
        arrToDecrypt[282] = gtUint128.unwrap(newA_s);
        arrToDecrypt[283] = gtUint128.unwrap(newB_s);
        arrToDecrypt[284] = gtBool.unwrap(res_s);
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
        allAmountValues.amount8_s = MpcCore.setPublic8(amount);
        allAmountValues.amount16_s = MpcCore.setPublic16(amount);
        allAmountValues.amount32_s = MpcCore.setPublic32(amount);
        allAmountValues.amount64_s = MpcCore.setPublic64(amount);
        allAmountValues.amount128_s = MpcCore.setPublic128(amount);
        allAmountValues.amount = amount;

        // Compute all operations and put the result handles in an array
        uint256[] memory arrToDecrypt = new uint256[](285);

        // uint8 operations
        (gtUint8 newA_s, gtUint8 newB_s, gtBool res_s) = MpcCore.transfer(allGTCastingValues.a8_s, allGTCastingValues.b8_s, allAmountValues.amount8_s);
        arrToDecrypt[0] = gtUint8.unwrap(newA_s);
        arrToDecrypt[1] = gtUint8.unwrap(newB_s);
        arrToDecrypt[2] = gtBool.unwrap(res_s);

        // Compute operation on 16 bits
        computeAndCheckTransfer16(allGTCastingValues, allAmountValues, arrToDecrypt);

        // Compute operation on 32 bits
        computeAndCheckTransfer32(allGTCastingValues, allAmountValues, arrToDecrypt);

        // Compute operation on 64 bits
        computeAndCheckTransfer64(allGTCastingValues, allAmountValues, arrToDecrypt);

        // Compute operation on 128 bits
        computeAndCheckTransfer128(allGTCastingValues, allAmountValues, arrToDecrypt);
    
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