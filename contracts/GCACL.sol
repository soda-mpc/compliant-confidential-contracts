// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {GCHandlerAddress} from "GCHandlerAddress.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title  GCACL
/// @notice The ACL (Access Control List) is a permission management system designed to
///         control who can access, compute on, or decrypt encrypted values in the bubble network.
///         By defining and enforcing these permissions, the ACL ensures that encrypted data remains secure while still being usable
///         within authorized contexts.
/// @dev      This contract is deployed using an UUPS proxy.
contract GCACL is UUPSUpgradeable, Ownable2StepUpgradeable{
   
    /// @notice         Returned if the sender address is not permitted for permit operations.
    /// @param handle   Handle.
    /// @param sender   Sender address.
    error SenderNotPermitted(uint256 handle, address sender);

    /// @notice         Emitted when a handle is permitted.
    /// @param caller   account calling the permit function.
    /// @param account  account being permitted for the handle.
    /// @param handle   handle being permitted.
    event GCHandlePermitted(address caller, address account, uint256 handle);

    /// @custom:storage-location erc7201:bubble.storage.GCACL
    struct GCACLStorage {
        mapping(uint256 handle => mapping(address account => bool isPermitted)) persistedPermitted;
    }

    /// keccak256(abi.encode(uint256(keccak256("bubble.storage.GCACL")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant GCACLStorageLocation = 0x85523aed7f74ec200b6de6cb9cced0a0ae2b17a83a0ffa6cd0d648212e559500;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    /// @notice              Permits the use of `handle` for the address `account`.
    /// @dev                 The caller must be permitted to use `handle` for permit() to succeed. If not, permit() reverts.
    /// @param handle        Handle.
    /// @param account       Address of the account.
    function permit(uint256 handle, address account) public virtual {
        if (!isPermitted(handle, msg.sender)) {
            revert SenderNotPermitted(handle, msg.sender);
        }

        GCACLStorage storage $ = _getGCACLStorage();
        $.persistedPermitted[handle][account] = true;
        emit GCHandlePermitted(msg.sender, account, handle);
    }
    
    /// @notice              Permits the use of `handle` by address `account` for this transaction.
    /// @dev                 The caller must be permitted to use `handle` for permitTransient() to succeed.
    ///                      If not, permitTransient() reverts.
    ///                      The GCHandler contract (which its address is stored in GCExtendedOperationsAddress) can always `permitTransient`, contrarily to `permit`.
    /// @param handle        Handle.
    /// @param account       Address of the account.
    function permitTransient(uint256 handle, address account) public virtual {
        if (msg.sender != GCHandlerAddress) {
            if (!isPermitted(handle, msg.sender)) {
                revert SenderNotPermitted(handle, msg.sender);
            }
        }
        bytes32 key = keccak256(abi.encodePacked(handle, account));
        // Store the key in the transient storage.
        assembly {
            tstore(key, 1)
        }
    }

    /// @notice                  Getter function for the GCHandler contract address.
    /// @return GCHandlerAddress Address of the GCHandler.
    function getGCHandlerAddress() public view virtual returns (address) {
        return GCHandlerAddress;
    }

    /// @notice              Returns true if the address account is permitted to use handle, otherwise, returns false.
    /// @param handle        Handle.
    /// @param account       Address of the account.
    /// @return isPermitted    Whether the account can access the handle.
    function isPermittedPersistent(uint256 handle, address account) public view virtual returns (bool) {
        GCACLStorage storage $ = _getGCACLStorage();
        return $.persistedPermitted[handle][account];
    }

    /// @notice                      Checks whether the account is permitted to use the handle in the
    ///                              same transaction (transient).
    /// @param handle                Handle.
    /// @param account               Address of the account.
    /// @return isPermittedTransient   Whether the account can access transiently the handle.
    function isPermittedTransient(uint256 handle, address account) public view virtual returns (bool) {
        bool isPermittedTransient;
        bytes32 key = keccak256(abi.encodePacked(handle, account));
        assembly {
            isPermittedTransient := tload(key)
        }
        return isPermittedTransient;
    }

    /// @notice              Returns whether the account is permitted to use the `handle`, either due to
    ///                      permitTransient() or permit().
    /// @param handle        Handle.
    /// @param account       Address of the account.
    /// @return isPermitted    Whether the account can access the handle.
    function isPermitted(uint256 handle, address account) public view virtual returns (bool) {
        return isPermittedTransient(handle, account) || isPermittedPersistent(handle, account);
    }

    /**
     * @dev                  Returns the ACL storage location.
     */
    function _getGCACLStorage() internal pure returns (GCACLStorage storage $) {
        assembly {
            $.slot := GCACLStorageLocation
        }
    }

    /**
     * @dev Should revert when `msg.sender` is not authorized to upgrade the contract.
     */
    function _authorizeUpgrade(address _newImplementation) internal virtual override onlyOwner {}
}
