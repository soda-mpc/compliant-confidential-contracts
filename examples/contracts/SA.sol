// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "MpcCore.sol";
import "MpcInterface.sol";

interface PrivateERC20Contract {
    function balanceOf() external view returns (gtUint256);
    function contractTransfer(address _to, gtUint256 _it) external returns (gtBool);
    function transfer(address _to, uint256 _value) external returns (gtBool);
}

contract SA {

    address private userAddress;
    PrivateERC20Contract private pERC20;
    GCACL private acl;

    /// @notice Deploys the SA contract
    /// @param user The address of the user
    /// @param privateERC20ContractAddress The address of the private ERC20 contract
    /// @param aclAddress The address of the ACL contract
    constructor(address user, address privateERC20ContractAddress, address aclAddress) {
        userAddress = user;
        pERC20 = PrivateERC20Contract(privateERC20ContractAddress);
        acl = GCACL(aclAddress);
    }

    /// @notice Permits the view access to the SA contract for the address `permittee`
    /// @param permittee The address of the account that is permitted to view the SA contract
    function permitViewAccess(address permittee) public {
        acl.permitFullViewAccess(permittee, type(uint64).max);
    }

    function getUserAddress() public view returns (address) {
        return userAddress;
    }

    function getPrivateERC20Address() public view returns (address) {
        return address(pERC20);
    }

    /// @notice Returns the handle of the contract's balance
    /// @dev The balance is returned as a handle 
    /// @return The balance handle
    function getBalance() public view returns (gtUint256) {
        return pERC20.balanceOf();
    }

    /// @notice Transfers tokens using an encrypted and signed value
    /// @param _to The address to transfer to
    /// @param _it The encrypted and signed transfer amount
    /// @return The handle to the transfer's result
    function transfer(address _to, itUint256 calldata _it) public returns (gtBool) {
        gtUint256 handle = MpcCore.validateCiphertext(_it);
        MpcCore.permitTransient(handle, address(pERC20));
        return pERC20.contractTransfer(_to, handle);
    }

    /// @notice Transfers tokens using an encrypted and signed value
    /// @param _to The address to transfer to
    /// @param _value The transfer amount
    /// @return The handle to the transfer's result
    function transfer(address _to, uint256 _value) public returns (gtBool) {
        return pERC20.transfer(_to, _value);
    }
}