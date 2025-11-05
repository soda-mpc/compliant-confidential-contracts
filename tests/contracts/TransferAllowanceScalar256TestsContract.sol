// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "MpcCore.sol";
import "../../lib/onchain/contracts/DecryptionCaller.sol";

contract TransferAllowanceScalar256TestsContract is DecryptionCaller {

    uint32 constant NUM_DECRYPTIONS_PER_TRANSFER = 4;

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

    struct AllAllowanceValues {
        gtUint8 allowance8_s;
        gtUint16 allowance16_s;
        gtUint32 allowance32_s;
        gtUint64 allowance64_s;
        gtUint128 allowance128_s;
        gtUint256 allowance256_s;
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

    function getNewAllowance() public view returns (uint8) {
        return newAllowance;
    }

    function getResult() public view returns (bool) {
        return result;
    }

    function resetStates() public {
        transferDecrypted = false;
    }

    function setDecryption(gtUint256 newA_s, gtUint256 newB_s, gtBool res_s, gtUint256 newAllowance_s, uint256[] memory arrToDecrypt, uint32 index) internal {
        arrToDecrypt[index] = gtUint256.unwrap(newA_s);
        arrToDecrypt[index+1] = gtUint256.unwrap(newB_s);
        arrToDecrypt[index+2] = gtBool.unwrap(res_s);
        arrToDecrypt[index+3] = gtUint256.unwrap(newAllowance_s);
    }

    

    function computeAndCheckTransfer256(AllGTCastingValues memory allGTCastingValues, AllAllowanceValues memory allAllowanceValues, uint8 amount, uint256[] memory arrToDecrypt) public {

        uint32 index = 0;
        // Check all options for casting to 256 while amount is scalar and allowance is 8
        (gtUint256 newA_s, gtUint256 newB_s, gtBool res_s, gtUint256 newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance8_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance8_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b8_s, amount, allAllowanceValues.allowance8_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance8_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b16_s, amount, allAllowanceValues.allowance8_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance8_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b32_s, amount, allAllowanceValues.allowance8_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a64_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance8_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b64_s, amount, allAllowanceValues.allowance8_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a128_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance8_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b128_s, amount, allAllowanceValues.allowance8_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        // Check all options for casting to 256 while amount is scalar and allowance is 16
        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance16_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance16_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b8_s, amount, allAllowanceValues.allowance16_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance16_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b16_s, amount, allAllowanceValues.allowance16_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance16_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b32_s, amount, allAllowanceValues.allowance16_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a64_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance16_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b64_s, amount, allAllowanceValues.allowance16_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a128_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance16_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b128_s, amount, allAllowanceValues.allowance16_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        // Check all options for casting to 256 while amount is scalar and allowance is 32
        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance32_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance32_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b8_s, amount, allAllowanceValues.allowance32_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance32_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b16_s, amount, allAllowanceValues.allowance32_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance32_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b32_s, amount, allAllowanceValues.allowance32_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a64_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance32_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b64_s, amount, allAllowanceValues.allowance32_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a128_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance32_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b128_s, amount, allAllowanceValues.allowance32_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        // Check all options for casting to 256 while amount is scalar and allowance is 64
        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance64_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance64_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b8_s, amount, allAllowanceValues.allowance64_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance64_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b16_s, amount, allAllowanceValues.allowance64_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance64_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b32_s, amount, allAllowanceValues.allowance64_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a64_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance64_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b64_s, amount, allAllowanceValues.allowance64_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a128_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance64_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b128_s, amount, allAllowanceValues.allowance64_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        // Check all options for casting to 256 while amount is scalar and allowance is 128
        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance128_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance128_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b8_s, amount, allAllowanceValues.allowance128_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance128_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b16_s, amount, allAllowanceValues.allowance128_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance128_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b32_s, amount, allAllowanceValues.allowance128_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a64_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance128_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b64_s, amount, allAllowanceValues.allowance128_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a128_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance128_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b128_s, amount, allAllowanceValues.allowance128_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        // Check all options for casting to 256 while amount is scalar and allowance is 256
        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance256_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a8_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance256_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b8_s, amount, allAllowanceValues.allowance256_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a16_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance256_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b16_s, amount, allAllowanceValues.allowance256_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a32_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance256_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b32_s, amount, allAllowanceValues.allowance256_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a64_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance256_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b64_s, amount, allAllowanceValues.allowance256_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a128_s, allGTCastingValues.b256_s, amount, allAllowanceValues.allowance256_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

        (newA_s, newB_s, res_s, newAllowance_s) = MpcCore.transferWithAllowance(allGTCastingValues.a256_s, allGTCastingValues.b128_s, amount, allAllowanceValues.allowance256_s);
        setDecryption(newA_s, newB_s, res_s, newAllowance_s, arrToDecrypt, index);
        index += NUM_DECRYPTIONS_PER_TRANSFER;

    }


    function transferWithAllowanceTest(uint8 a, uint8 b, uint8 amount, uint8 allowance) public returns (uint256) {
        AllGTCastingValues memory allGTCastingValues;
        AllAllowanceValues memory allAllowanceValues;
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
        allAllowanceValues.allowance8_s = MpcCore.setPublic8(allowance);
        allAllowanceValues.allowance16_s = MpcCore.setPublic16(allowance);
        allAllowanceValues.allowance32_s = MpcCore.setPublic32(allowance);
        allAllowanceValues.allowance64_s = MpcCore.setPublic64(allowance);
        allAllowanceValues.allowance128_s = MpcCore.setPublic128(allowance);
        allAllowanceValues.allowance256_s = MpcCore.setPublic256(allowance);

        // Compute all operations and put the result handles in an array 
        uint256[] memory arrToDecrypt = new uint256[](4 * (11 * 6));  // 264
        
        // Calculate the result with casting to 256
        computeAndCheckTransfer256(allGTCastingValues, allAllowanceValues, amount, arrToDecrypt);
    
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