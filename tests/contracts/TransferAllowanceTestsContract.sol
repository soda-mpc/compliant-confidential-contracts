// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "MpcCore.sol";
import "../../lib/onchain/contracts/DecryptionCaller.sol";

contract TransferAllowanceTestsContract is DecryptionCaller {

    struct AllGTCastingValues {
        gtUint8 a8_s;
        gtUint8 b8_s;
        gtUint16 a16_s;
        gtUint16 b16_s;
        gtUint32 a32_s;
        gtUint32 b32_s;
        gtUint64 a64_s;
        gtUint64 b64_s;
    }

    struct AllAmountValues {
        gtUint8 amount8_s;
        gtUint16 amount16_s;
        gtUint32 amount32_s;
        gtUint64 amount64_s;
        uint8 amount;
    }

    struct AllAllowanceValues {
        gtUint8 allowance8_s;
        gtUint16 allowance16_s;
        gtUint32 allowance32_s;
        gtUint64 allowance64_s;
    }

    bool transferDecrypted;

    uint8 newA;
    uint8 newB;
    bool result;
    uint8 newAllowance;

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
    
    function getNewAllowance() public view returns (uint8) {
        return newAllowance;
    }

    function resetStates() public {
        transferDecrypted = false;
    }

    function computeAndCheckTransfer16(AllGTCastingValues memory allGTCastingValues, AllAmountValues memory allAmountValues, 
                AllAllowanceValues memory allAllowanceValues, uint256[] memory arrToDecrypt) public {
        // Perform all transfer with allowance operations with uint8 allowance
        (gtUint16 newA_s, gtUint16 newB_s, gtBool res_s, gtUint16 newAllowance_s) = MpcCore.transferWithAllowance
                    (allGTCastingValues.a16_s, allGTCastingValues.b16_s, allAmountValues.amount8_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[4] = gtUint16.unwrap(newA_s);
        arrToDecrypt[5] = gtUint16.unwrap(newB_s);
        arrToDecrypt[6] = gtBool.unwrap(res_s);
        arrToDecrypt[7] = gtUint16.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b16_s, allAmountValues.amount8_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[8] = gtUint16.unwrap(newA_s);
        arrToDecrypt[9] = gtUint16.unwrap(newB_s);
        arrToDecrypt[10] = gtBool.unwrap(res_s);
        arrToDecrypt[11] = gtUint16.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b8_s, allAmountValues.amount8_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[12] = gtUint16.unwrap(newA_s);
        arrToDecrypt[13] = gtUint16.unwrap(newB_s);
        arrToDecrypt[14] = gtBool.unwrap(res_s);
        arrToDecrypt[15] = gtUint16.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b16_s, allAmountValues.amount16_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[16] = gtUint16.unwrap(newA_s);
        arrToDecrypt[17] = gtUint16.unwrap(newB_s);
        arrToDecrypt[18] = gtBool.unwrap(res_s);
        arrToDecrypt[19] = gtUint16.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b16_s, allAmountValues.amount16_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[20] = gtUint16.unwrap(newA_s);
        arrToDecrypt[21] = gtUint16.unwrap(newB_s);
        arrToDecrypt[22] = gtBool.unwrap(res_s);
        arrToDecrypt[23] = gtUint16.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b8_s, allAmountValues.amount16_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[24] = gtUint16.unwrap(newA_s);
        arrToDecrypt[25] = gtUint16.unwrap(newB_s);
        arrToDecrypt[26] = gtBool.unwrap(res_s);
        arrToDecrypt[27] = gtUint16.unwrap(newAllowance_s);

        // Allowance with 16 bits
        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b16_s, allAmountValues.amount8_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[28] = gtUint16.unwrap(newA_s);
        arrToDecrypt[29] = gtUint16.unwrap(newB_s);
        arrToDecrypt[30] = gtBool.unwrap(res_s);
        arrToDecrypt[31] = gtUint16.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b16_s, allAmountValues.amount8_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[32] = gtUint16.unwrap(newA_s);
        arrToDecrypt[33] = gtUint16.unwrap(newB_s);
        arrToDecrypt[34] = gtBool.unwrap(res_s);
        arrToDecrypt[35] = gtUint16.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b8_s, allAmountValues.amount8_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[36] = gtUint16.unwrap(newA_s);
        arrToDecrypt[37] = gtUint16.unwrap(newB_s);
        arrToDecrypt[38] = gtBool.unwrap(res_s);
        arrToDecrypt[39] = gtUint16.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b16_s, allAmountValues.amount16_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[40] = gtUint16.unwrap(newA_s);
        arrToDecrypt[41] = gtUint16.unwrap(newB_s);
        arrToDecrypt[42] = gtBool.unwrap(res_s);
        arrToDecrypt[43] = gtUint16.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b16_s, allAmountValues.amount16_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[44] = gtUint16.unwrap(newA_s);
        arrToDecrypt[45] = gtUint16.unwrap(newB_s);
        arrToDecrypt[46] = gtBool.unwrap(res_s);
        arrToDecrypt[47] = gtUint16.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b8_s, allAmountValues.amount16_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[48] = gtUint16.unwrap(newA_s);
        arrToDecrypt[49] = gtUint16.unwrap(newB_s);
        arrToDecrypt[50] = gtBool.unwrap(res_s);
        arrToDecrypt[51] = gtUint16.unwrap(newAllowance_s);
        
    }

    function computeAndCheckTransfer32(AllGTCastingValues memory allGTCastingValues, AllAmountValues memory allAmountValues, AllAllowanceValues memory allAllowanceValues, uint256[] memory arrToDecrypt) public {

        // Perform all uint32 options while amount is 32 and allowance is 32
        (gtUint32 newA_s, gtUint32 newB_s, gtBool res_s, gtUint32 newAllowance_s) = MpcCore.transferWithAllowance
            (allGTCastingValues.a32_s, allGTCastingValues.b32_s, allAmountValues.amount32_s, allAllowanceValues.allowance32_s);
        arrToDecrypt[52] = gtUint32.unwrap(newA_s);
        arrToDecrypt[53] = gtUint32.unwrap(newB_s);
        arrToDecrypt[54] = gtBool.unwrap(res_s);
        arrToDecrypt[55] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b32_s, allAmountValues.amount32_s, allAllowanceValues.allowance32_s);
        arrToDecrypt[56] = gtUint32.unwrap(newA_s);
        arrToDecrypt[57] = gtUint32.unwrap(newB_s);
        arrToDecrypt[58] = gtBool.unwrap(res_s);
        arrToDecrypt[59] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b8_s, allAmountValues.amount32_s, allAllowanceValues.allowance32_s);
        arrToDecrypt[60] = gtUint32.unwrap(newA_s);
        arrToDecrypt[61] = gtUint32.unwrap(newB_s);
        arrToDecrypt[62] = gtBool.unwrap(res_s);
        arrToDecrypt[63] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b32_s, allAmountValues.amount32_s, allAllowanceValues.allowance32_s);
        arrToDecrypt[64] = gtUint32.unwrap(newA_s);
        arrToDecrypt[65] = gtUint32.unwrap(newB_s);
        arrToDecrypt[66] = gtBool.unwrap(res_s);
        arrToDecrypt[67] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b16_s, allAmountValues.amount32_s, allAllowanceValues.allowance32_s);
        arrToDecrypt[68] = gtUint32.unwrap(newA_s);
        arrToDecrypt[69] = gtUint32.unwrap(newB_s);
        arrToDecrypt[70] = gtBool.unwrap(res_s);
        arrToDecrypt[71] = gtUint32.unwrap(newAllowance_s);


        // Check all options for casting to 32 while amount is 8 and allowance is 32
        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b32_s, allAmountValues.amount8_s, allAllowanceValues.allowance32_s);
        arrToDecrypt[72] = gtUint32.unwrap(newA_s);
        arrToDecrypt[73] = gtUint32.unwrap(newB_s);
        arrToDecrypt[74] = gtBool.unwrap(res_s);
        arrToDecrypt[75] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b32_s, allAmountValues.amount8_s, allAllowanceValues.allowance32_s);
        arrToDecrypt[76] = gtUint32.unwrap(newA_s);
        arrToDecrypt[77] = gtUint32.unwrap(newB_s);
        arrToDecrypt[78] = gtBool.unwrap(res_s);
        arrToDecrypt[79] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b8_s, allAmountValues.amount8_s, allAllowanceValues.allowance32_s);
        arrToDecrypt[80] = gtUint32.unwrap(newA_s);
        arrToDecrypt[81] = gtUint32.unwrap(newB_s);
        arrToDecrypt[82] = gtBool.unwrap(res_s);
        arrToDecrypt[83] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b32_s, allAmountValues.amount8_s, allAllowanceValues.allowance32_s);
        arrToDecrypt[84] = gtUint32.unwrap(newA_s);
        arrToDecrypt[85] = gtUint32.unwrap(newB_s);
        arrToDecrypt[86] = gtBool.unwrap(res_s);
        arrToDecrypt[87] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b16_s, allAmountValues.amount8_s, allAllowanceValues.allowance32_s);
        arrToDecrypt[88] = gtUint32.unwrap(newA_s);
        arrToDecrypt[89] = gtUint32.unwrap(newB_s);
        arrToDecrypt[90] = gtBool.unwrap(res_s);
        arrToDecrypt[91] = gtUint32.unwrap(newAllowance_s);

        // Check all options for casting to 32 while amount is 16 and allowance is 32
        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b32_s, allAmountValues.amount16_s, allAllowanceValues.allowance32_s);
        arrToDecrypt[92] = gtUint32.unwrap(newA_s);
        arrToDecrypt[93] = gtUint32.unwrap(newB_s);
        arrToDecrypt[94] = gtBool.unwrap(res_s);
        arrToDecrypt[95] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b32_s, allAmountValues.amount16_s, allAllowanceValues.allowance32_s);
        arrToDecrypt[96] = gtUint32.unwrap(newA_s);
        arrToDecrypt[97] = gtUint32.unwrap(newB_s);
        arrToDecrypt[98] = gtBool.unwrap(res_s);
        arrToDecrypt[99] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b8_s, allAmountValues.amount16_s, allAllowanceValues.allowance32_s);
        arrToDecrypt[100] = gtUint32.unwrap(newA_s);
        arrToDecrypt[101] = gtUint32.unwrap(newB_s);
        arrToDecrypt[102] = gtBool.unwrap(res_s);
        arrToDecrypt[103] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b32_s, allAmountValues.amount16_s, allAllowanceValues.allowance32_s);
        arrToDecrypt[104] = gtUint32.unwrap(newA_s);
        arrToDecrypt[105] = gtUint32.unwrap(newB_s);
        arrToDecrypt[106] = gtBool.unwrap(res_s);
        arrToDecrypt[107] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b16_s, allAmountValues.amount16_s, allAllowanceValues.allowance32_s);
        arrToDecrypt[108] = gtUint32.unwrap(newA_s);
        arrToDecrypt[109] = gtUint32.unwrap(newB_s);
        arrToDecrypt[110] = gtBool.unwrap(res_s);
        arrToDecrypt[111] = gtUint32.unwrap(newAllowance_s);


        // Allowance 8

        // Perform all uint32 options while amount is 32 and allowance is 8
        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b32_s, allAmountValues.amount32_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[112] = gtUint32.unwrap(newA_s);
        arrToDecrypt[113] = gtUint32.unwrap(newB_s);
        arrToDecrypt[114] = gtBool.unwrap(res_s);
        arrToDecrypt[115] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b32_s, allAmountValues.amount32_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[116] = gtUint32.unwrap(newA_s);
        arrToDecrypt[117] = gtUint32.unwrap(newB_s);
        arrToDecrypt[118] = gtBool.unwrap(res_s);
        arrToDecrypt[119] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b8_s, allAmountValues.amount32_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[120] = gtUint32.unwrap(newA_s);
        arrToDecrypt[121] = gtUint32.unwrap(newB_s);
        arrToDecrypt[122] = gtBool.unwrap(res_s);
        arrToDecrypt[123] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b32_s, allAmountValues.amount32_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[124] = gtUint32.unwrap(newA_s);
        arrToDecrypt[125] = gtUint32.unwrap(newB_s);
        arrToDecrypt[126] = gtBool.unwrap(res_s);
        arrToDecrypt[127] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b16_s, allAmountValues.amount32_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[128] = gtUint32.unwrap(newA_s);
        arrToDecrypt[129] = gtUint32.unwrap(newB_s);
        arrToDecrypt[130] = gtBool.unwrap(res_s);
        arrToDecrypt[131] = gtUint32.unwrap(newAllowance_s);


        // Check all options for casting to 32 while amount is 8 and allowance is 8
        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b32_s, allAmountValues.amount8_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[132] = gtUint32.unwrap(newA_s);
        arrToDecrypt[133] = gtUint32.unwrap(newB_s);
        arrToDecrypt[134] = gtBool.unwrap(res_s);
        arrToDecrypt[135] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b32_s, allAmountValues.amount8_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[136] = gtUint32.unwrap(newA_s);
        arrToDecrypt[137] = gtUint32.unwrap(newB_s);
        arrToDecrypt[138] = gtBool.unwrap(res_s);
        arrToDecrypt[139] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b8_s, allAmountValues.amount8_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[140] = gtUint32.unwrap(newA_s);
        arrToDecrypt[141] = gtUint32.unwrap(newB_s);
        arrToDecrypt[142] = gtBool.unwrap(res_s);
        arrToDecrypt[143] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b32_s, allAmountValues.amount8_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[144] = gtUint32.unwrap(newA_s);
        arrToDecrypt[145] = gtUint32.unwrap(newB_s);
        arrToDecrypt[146] = gtBool.unwrap(res_s);
        arrToDecrypt[147] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b16_s, allAmountValues.amount8_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[148] = gtUint32.unwrap(newA_s);
        arrToDecrypt[149] = gtUint32.unwrap(newB_s);
        arrToDecrypt[150] = gtBool.unwrap(res_s);
        arrToDecrypt[151] = gtUint32.unwrap(newAllowance_s);

        // Check all options for casting to 32 while amount is 16 and allowance is 8
        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b32_s, allAmountValues.amount16_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[152] = gtUint32.unwrap(newA_s);
        arrToDecrypt[153] = gtUint32.unwrap(newB_s);
        arrToDecrypt[154] = gtBool.unwrap(res_s);
        arrToDecrypt[155] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b32_s, allAmountValues.amount16_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[156] = gtUint32.unwrap(newA_s);
        arrToDecrypt[157] = gtUint32.unwrap(newB_s);
        arrToDecrypt[158] = gtBool.unwrap(res_s);
        arrToDecrypt[159] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b8_s, allAmountValues.amount16_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[160] = gtUint32.unwrap(newA_s);
        arrToDecrypt[161] = gtUint32.unwrap(newB_s);
        arrToDecrypt[162] = gtBool.unwrap(res_s);
        arrToDecrypt[163] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b32_s, allAmountValues.amount16_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[164] = gtUint32.unwrap(newA_s);
        arrToDecrypt[165] = gtUint32.unwrap(newB_s);
        arrToDecrypt[166] = gtBool.unwrap(res_s);
        arrToDecrypt[167] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b16_s, allAmountValues.amount16_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[168] = gtUint32.unwrap(newA_s);
        arrToDecrypt[169] = gtUint32.unwrap(newB_s);
        arrToDecrypt[170] = gtBool.unwrap(res_s);
        arrToDecrypt[171] = gtUint32.unwrap(newAllowance_s);


        // Allowance 16

        // Perform all uint32 options while amount is 32 and allowance is 16
        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b32_s, allAmountValues.amount32_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[172] = gtUint32.unwrap(newA_s);
        arrToDecrypt[173] = gtUint32.unwrap(newB_s);
        arrToDecrypt[174] = gtBool.unwrap(res_s);
        arrToDecrypt[175] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b32_s, allAmountValues.amount32_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[176] = gtUint32.unwrap(newA_s);
        arrToDecrypt[177] = gtUint32.unwrap(newB_s);
        arrToDecrypt[178] = gtBool.unwrap(res_s);
        arrToDecrypt[179] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b8_s, allAmountValues.amount32_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[180] = gtUint32.unwrap(newA_s);
        arrToDecrypt[181] = gtUint32.unwrap(newB_s);
        arrToDecrypt[182] = gtBool.unwrap(res_s);
        arrToDecrypt[183] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b32_s, allAmountValues.amount32_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[184] = gtUint32.unwrap(newA_s);
        arrToDecrypt[185] = gtUint32.unwrap(newB_s);
        arrToDecrypt[186] = gtBool.unwrap(res_s);
        arrToDecrypt[187] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b16_s, allAmountValues.amount32_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[188] = gtUint32.unwrap(newA_s);
        arrToDecrypt[189] = gtUint32.unwrap(newB_s);
        arrToDecrypt[190] = gtBool.unwrap(res_s);
        arrToDecrypt[191] = gtUint32.unwrap(newAllowance_s);


        // Check all options for casting to 32 while amount is 8 and allowance is 16
        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b32_s, allAmountValues.amount8_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[192] = gtUint32.unwrap(newA_s);
        arrToDecrypt[193] = gtUint32.unwrap(newB_s);
        arrToDecrypt[194] = gtBool.unwrap(res_s);
        arrToDecrypt[195] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b32_s, allAmountValues.amount8_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[196] = gtUint32.unwrap(newA_s);
        arrToDecrypt[197] = gtUint32.unwrap(newB_s);
        arrToDecrypt[198] = gtBool.unwrap(res_s);
        arrToDecrypt[199] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b8_s, allAmountValues.amount8_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[200] = gtUint32.unwrap(newA_s);
        arrToDecrypt[201] = gtUint32.unwrap(newB_s);
        arrToDecrypt[202] = gtBool.unwrap(res_s);
        arrToDecrypt[203] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b32_s, allAmountValues.amount8_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[204] = gtUint32.unwrap(newA_s);
        arrToDecrypt[205] = gtUint32.unwrap(newB_s);
        arrToDecrypt[206] = gtBool.unwrap(res_s);
        arrToDecrypt[207] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b16_s, allAmountValues.amount8_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[208] = gtUint32.unwrap(newA_s);
        arrToDecrypt[209] = gtUint32.unwrap(newB_s);
        arrToDecrypt[210] = gtBool.unwrap(res_s);
        arrToDecrypt[211] = gtUint32.unwrap(newAllowance_s);

        // Check all options for casting to 32 while amount is 16 and allowance is 16
        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b32_s, allAmountValues.amount16_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[212] = gtUint32.unwrap(newA_s);
        arrToDecrypt[213] = gtUint32.unwrap(newB_s);
        arrToDecrypt[214] = gtBool.unwrap(res_s);
        arrToDecrypt[215] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b32_s, allAmountValues.amount16_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[216] = gtUint32.unwrap(newA_s);
        arrToDecrypt[217] = gtUint32.unwrap(newB_s);
        arrToDecrypt[218] = gtBool.unwrap(res_s);
        arrToDecrypt[219] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b8_s, allAmountValues.amount16_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[220] = gtUint32.unwrap(newA_s);
        arrToDecrypt[221] = gtUint32.unwrap(newB_s);
        arrToDecrypt[222] = gtBool.unwrap(res_s);
        arrToDecrypt[223] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b32_s, allAmountValues.amount16_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[224] = gtUint32.unwrap(newA_s);
        arrToDecrypt[225] = gtUint32.unwrap(newB_s);
        arrToDecrypt[226] = gtBool.unwrap(res_s);
        arrToDecrypt[227] = gtUint32.unwrap(newAllowance_s);

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b16_s, allAmountValues.amount16_s, allAllowanceValues.allowance16_s);
        arrToDecrypt[228] = gtUint32.unwrap(newA_s);
        arrToDecrypt[229] = gtUint32.unwrap(newB_s);
        arrToDecrypt[230] = gtBool.unwrap(res_s);
        arrToDecrypt[231] = gtUint32.unwrap(newAllowance_s);
    }


    function transferWithAllowanceTest(uint8 a, uint8 b, uint8 amount, uint8 allowance) public returns (uint256) {
        AllGTCastingValues memory allGTCastingValues;
        AllAmountValues memory allAmountValues;
        AllAllowanceValues memory allAllowanceValues;
        allGTCastingValues.a8_s = MpcCore.setPublic8(a);
        allGTCastingValues.b8_s = MpcCore.setPublic8(b);
        allGTCastingValues.a16_s =  MpcCore.setPublic16(a);
        allGTCastingValues.b16_s =  MpcCore.setPublic16(b);
        allGTCastingValues.a32_s =  MpcCore.setPublic32(a);
        allGTCastingValues.b32_s =  MpcCore.setPublic32(b);
        allGTCastingValues.a64_s =  MpcCore.setPublic64(a);
        allGTCastingValues.b64_s =  MpcCore.setPublic64(b);
        allAmountValues.amount8_s = MpcCore.setPublic8(amount);
        allAmountValues.amount16_s = MpcCore.setPublic16(amount);
        allAmountValues.amount32_s = MpcCore.setPublic32(amount);
        allAmountValues.amount64_s = MpcCore.setPublic64(amount);
        allAmountValues.amount = amount;
        allAllowanceValues.allowance8_s = MpcCore.setPublic8(allowance);
        allAllowanceValues.allowance16_s = MpcCore.setPublic16(allowance);
        allAllowanceValues.allowance32_s = MpcCore.setPublic32(allowance);
        allAllowanceValues.allowance64_s = MpcCore.setPublic64(allowance);
        
        // Compute all operations and put the result handles in an array
        uint256[] memory arrToDecrypt = new uint256[](232);

        // Calculate the expected result 
        (gtUint8 newA_s, gtUint8 newB_s, gtBool res_s, gtUint8 newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b8_s, allAmountValues.amount8_s, allAllowanceValues.allowance8_s);
        arrToDecrypt[0] = gtUint8.unwrap(newA_s);
        arrToDecrypt[1] = gtUint8.unwrap(newB_s);
        arrToDecrypt[2] = gtBool.unwrap(res_s);
        arrToDecrypt[3] = gtUint8.unwrap(newAllowance_s);

        // Calculate the result with casting to 16
        computeAndCheckTransfer16(allGTCastingValues, allAmountValues, allAllowanceValues, arrToDecrypt);

        // Calculate the result with casting to 32
        computeAndCheckTransfer32(allGTCastingValues, allAmountValues, allAllowanceValues, arrToDecrypt);
    
        return requestDecryption(arrToDecrypt, this.checkTransferWithAllowanceResults.selector); 
    }

    function checkTransferWithAllowanceResults(uint256 decryptID, bytes[] calldata output, bytes calldata signature) public {
        require(checkCallbackHandles(decryptID, output.length), "checkTransferWithAllowanceResults: Invalid callback parameters");
        
        uint8 firstNewA = abi.decode(output[0], (uint8));
        uint8 firstNewB = abi.decode(output[1], (uint8));
        bool firstRes = abi.decode(output[2], (bool));
        uint8 firstNewAllowance = abi.decode(output[3], (uint8));
        
        for (uint256 i = 4; i < output.length; i+=4) {
            uint8 newA = abi.decode(output[i], (uint8));
            uint8 newB = abi.decode(output[i+1], (uint8));
            bool res = abi.decode(output[i+2], (bool));
            uint8 newAllowance = abi.decode(output[i+3], (uint8));
            require(newA == firstNewA && newB == firstNewB && res == firstRes && newAllowance == firstNewAllowance, "checkTransferWithAllowanceResults: Invalid output");
        }

        transferDecrypted = true;
        newA = firstNewA;
        newB = firstNewB;
        result = firstRes;
        newAllowance = firstNewAllowance;
    }

}