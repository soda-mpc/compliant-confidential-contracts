// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {GCHandlerAddress} from "GCHandlerAddress.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

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

    /// @notice         Returned if the sender address is the same as the permittee address.
    /// @param sender   Sender address.
    error SenderCannotBePermittee(address sender);

    /// @notice         Returned if the sender address is the same as the contract address.
    /// @param sender   Sender address.
    error SenderCannotBeContractAddress(address sender);

    /// @notice         Returned if the sender address is the same as the permittee address.
    /// @param permittee  Permittee address.
    error PermitteeCannotBeContractAddress(address permittee);

    /// @notice         Returned if the expiration date is before one hour from the current block timestamp.
    error ExpirationDateBeforeOneHour();

    /// @notice         Returned if the expiration date is already set to the same value.
    /// @param sender   Sender address.
    /// @param permittee  Permittee address.
    /// @param oldExpirationDate  Old expiration date.
    error ExpirationDateAlreadySetToSameValue(address sender, address permittee, uint64 oldExpirationDate);

    /// @notice         Returned if the permission is already permitted or revoked in the same block.
    /// @param sender   Sender address.
    /// @param permittee  Permittee address.
    /// @param blockNumber  Block number.
    error AlreadyPermittedOrRevokedInSameBlock(address sender, address permittee, uint256 blockNumber);

    /// @notice         Returned if the permission is not permitted yet.
    /// @param sender   Sender address.
    /// @param permittee  Permittee address.
    error NotPermittedYet(address sender, address permittee);

    /// @notice         Returned if the permission is expired.
    /// @param sender   Sender address.
    /// @param permittee  Permittee address.
    error Expired(address sender, address permittee);

    /// @notice         Emitted when a handle is permitted.
    /// @param caller   account calling the permit function.
    /// @param account  account being permitted for the handle.
    /// @param handle   handle being permitted.
    event GCHandlePermitted(address caller, address account, uint256 handle);

    /// @notice         Emitted when a viewer is permitted.
    /// @param caller   account calling the permit function.
    /// @param permittee  account being permitted for the handle.
    /// @param permissionType  type of the permission.
    /// @param permitCounter  counter of the permit.
    /// @param oldExpirationDate  old expiration date.
    /// @param newExpirationDate  new expiration date.
    event AccountPermitted(address caller, address permittee, PermissionType permissionType, uint64 permitCounter, uint64 oldExpirationDate, uint64 newExpirationDate);

    /// @notice         Emitted when a contract viewer is permitted.
    /// @param caller   account calling the permit function.
    /// @param permittee  account being permitted for the handle.
    /// @param contractAddress  contract address being permitted for the handle.
    /// @param permissionType  type of the permission.
    /// @param permitCounter  counter of the permit.
    /// @param oldExpirationDate  old expiration date.
    /// @param newExpirationDate  new expiration date.
    event ContractAccountPermitted(address caller, address permittee, address contractAddress, PermissionType permissionType, uint64 permitCounter, uint64 oldExpirationDate, uint64 newExpirationDate);
    
    /// @notice         Emitted when a viewer is revoked.
    /// @param caller   account calling the revoke function.
    /// @param permittee  account being revoked for the handle.
    /// @param permissionType  type of the permission.
    /// @param permitCounter  counter of the revoke.
    /// @param oldExpirationDate  old expiration date.
    event AccountRevoked(address caller, address permittee, PermissionType permissionType, uint64 permitCounter, uint64 oldExpirationDate);

    /// @notice         Emitted when a contract viewer is revoked.
    /// @param caller   account calling the revoke function.
    /// @param permittee  account being revoked for the handle.
    /// @param contractAddress  contract address being revoked for the handle.
    /// @param permissionType  type of the permission.
    /// @param permitCounter  counter of the revoke.
    /// @param oldExpirationDate  old expiration date.
    event ContractAccountRevoked(address caller, address permittee, address contractAddress, PermissionType permissionType, uint64 permitCounter, uint64 oldExpirationDate);

    /// @notice Available types of permission.
    enum PermissionType {
        /// @notice Permission to insert inputs.
        INSERT,
        /// @notice Permission to view the handles.
        VIEW
    }

    /**
     * @notice Struct that represents a permission.
     * @dev The `permitCounter` is incremented at each permit or revoke
     *      to allow off-chain clients to track changes.
     */
    struct Permission {
        /// @notice The UNIX timestamp when the user permission expires.
        uint64 expirationDate;
        /// @notice The last block number when a permit or revocation happened.
        uint64 lastBlockPermitOrRevoke;
        /// @notice Counter that tracks the order of each permit or revocation.
        uint64 permitCounter;
    }

    /// @custom:storage-location erc7201:bubble.storage.GCACL
    struct GCACLStorage {
        mapping(uint256 handle => mapping(address account => bool isPermitted)) persistedPermitted;
        mapping(address permitter => mapping(address permittee => mapping(PermissionType permissionType => Permission permission))) globalPermission;
        mapping(address permitter => mapping(address permittee => mapping(address contractAddress => mapping(PermissionType permissionType => Permission permission)))) contractPermission;
        // Enumerable set to track contract addresses for each permitter-permittee pair
        mapping(address permitter => mapping(address permittee => mapping(PermissionType permissionType => EnumerableSet.AddressSet))) contractPermissionsSet;
    }

    /// The storage location of the GCACLStorage struct.
    /// Calculated using the formula: keccak256(abi.encode(uint256(keccak256("bubble.storage.GCACL")) - 1)) & ~bytes32(uint256(0xff))
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

    function permitFullViewAccess(address permittee, uint64 expirationDate) public virtual{
        _permitAccountAccess(permittee, expirationDate, PermissionType.VIEW);
    }

    function permitContractViewAccess(address permittee, address contractAddress, uint64 expirationDate) public virtual{
        _permitContractAccountAccess(permittee, contractAddress, expirationDate, PermissionType.VIEW);
    }

    function revokeFullViewPermission(address permittee) public virtual{
        _revokeAccountAccess(permittee, PermissionType.VIEW);
    }

    function revokeContractViewPermission(address permittee, address contractAddress) public virtual{
        _revokeContractAccountAccess(permittee, contractAddress, PermissionType.VIEW);
    }

    /// Insert permissions
    function permitFullInsertAccess(address permittee, uint64 expirationDate) public virtual{
        _permitAccountAccess(permittee, expirationDate, PermissionType.INSERT);
    }

    function permitContractInsertAccess(address permittee, address contractAddress, uint64 expirationDate) public virtual{
        _permitContractAccountAccess(permittee, contractAddress, expirationDate, PermissionType.INSERT);
    }

    function revokeFullInsertPermission(address permittee) public virtual{
        _revokeAccountAccess(permittee, PermissionType.INSERT);
    }

    function revokeContractInsertPermission(address permittee, address contractAddress) public virtual{
        _revokeContractAccountAccess(permittee, contractAddress, PermissionType.INSERT);
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

    function isFullViewPermitted(address permitter, address permittee) public view virtual returns (bool) {
        return _isFullAccessPermitted(permitter, permittee, PermissionType.VIEW);
    }

    function isContractViewPermitted(address permitter, address permittee, address contractAddress) public view virtual returns (bool) {
        return _isContractAccessPermitted(permitter, permittee, contractAddress, PermissionType.VIEW);
    }

    function isFullInsertPermitted(address permitter, address permittee) public view virtual returns (bool) {
        return _isFullAccessPermitted(permitter, permittee, PermissionType.INSERT);
    }

    function isContractInsertPermitted(address permitter, address permittee, address contractAddress) public view virtual returns (bool) {
        return _isContractAccessPermitted(permitter, permittee, contractAddress, PermissionType.INSERT);
    }

    /// @notice              Returns whether the permitter is permitted to use the handle on behalf of the permittee.
    /// @param permitter     Address of the permitter.
    /// @param permittee     Address of the permittee.
    /// @param handle        Handle.
    /// @return isPermitted  Whether the permitter is permitted to use the handle on behalf of the permittee.
    function isPermittedToView(
        address permitter,
        address permittee,
        uint256 handle
    ) public view virtual returns (bool) {
        GCACLStorage storage $ = _getGCACLStorage();

        // Step 1: Ensure permitter is allowed for this handle
        if (!isPermitted(handle, permitter)) {
            return false;
        }

        // Step 2: Check if the permitter has full view access to the permittee.
        if (isFullViewPermitted(permitter, permittee)) {
            return true;
        }
         
        // Step 3: Check if the permitter has contract view access to the permittee.
        // Iterate over all contract addresses that the permitter has a contract view access permission for the permittee.
        EnumerableSet.AddressSet storage contractSet = $.contractPermissionsSet[permitter][permittee][PermissionType.VIEW];
        uint256 length = EnumerableSet.length(contractSet);
        for (uint256 i = 0; i < length; i++) {
            address contractAddress = EnumerableSet.at(contractSet, i);
            // If the permission is not expired, check if the handle is permitted on behalf of the contract address.
            if ($.contractPermission[permitter][permittee][contractAddress][PermissionType.VIEW].expirationDate >= block.timestamp) {
                if (isPermitted(handle, contractAddress)) {
                    // If the handle is permitted on behalf of the contract address, return true.
                    return true;
                }
            }
        }
        
        return false;
    }

    /**
     * @notice Permits the use of the sender's handles for the address `permittee`.
     * @param permittee The address of the account that is permitted to use the sender's handles.
     * @param expirationDate The UNIX timestamp when the user permission expires.
     */
    function _permitAccountAccess(address permittee, uint64 expirationDate, PermissionType permissionType) internal virtual {
        GCACLStorage storage $ = _getGCACLStorage();
        Permission storage permission = $.globalPermission[msg.sender][permittee][permissionType];

        uint64 oldExpirationDate = permission.expirationDate;

        _permitAccountAccess(permission, permittee, expirationDate);

        emit AccountPermitted(
            msg.sender,
            permittee,
            permissionType,
            ++permission.permitCounter,
            oldExpirationDate,
            expirationDate
        );
    }

    /**
     * @notice Permits the use of the sender's handles for the address `permittee`.
     * @param permittee The address of the account that is permitted to use the sender's handles.
     * @param contractAddress The contract address to delegate access to.
     * @param expirationDate The UNIX timestamp when the user permission expires.
     */
    function _permitContractAccountAccess(address permittee, address contractAddress, uint64 expirationDate, PermissionType permissionType) internal virtual {
        GCACLStorage storage $ = _getGCACLStorage();
        Permission storage permission = $.contractPermission[msg.sender][permittee][contractAddress][permissionType];

        if (contractAddress == msg.sender) {
            revert SenderCannotBeContractAddress(contractAddress);
        }
        if (permittee == contractAddress) {
            revert PermitteeCannotBeContractAddress(contractAddress);
        }

        uint64 oldExpirationDate = permission.expirationDate;
           
        _permitAccountAccess(permission, permittee, expirationDate);

        // Add contract address to enumerable set if not already present
        EnumerableSet.add($.contractPermissionsSet[msg.sender][permittee][permissionType], contractAddress);

        emit ContractAccountPermitted(
            msg.sender,
            permittee,
            contractAddress,
            permissionType,
            ++permission.permitCounter,
            oldExpirationDate,
            expirationDate
        );
    }

    function _permitAccountAccess(Permission storage permission, address permittee, uint64 expirationDate) internal {
        if (expirationDate < block.timestamp + 1 hours) {
            revert ExpirationDateBeforeOneHour();
        }
     
        uint256 blockNumber = block.number;

        if (permission.lastBlockPermitOrRevoke == blockNumber) {
            revert AlreadyPermittedOrRevokedInSameBlock(msg.sender, permittee, blockNumber);
        }

        // Set the last block where the permission happened.
        permission.lastBlockPermitOrRevoke = uint64(blockNumber);

        if (permittee == msg.sender) {
            revert SenderCannotBePermittee(permittee);
        }

        uint64 oldExpirationDate = permission.expirationDate;
        uint64 newExpirationDate = expirationDate;
        if (oldExpirationDate == newExpirationDate) {
            revert ExpirationDateAlreadySetToSameValue(msg.sender, permittee, oldExpirationDate);
        }

        // Set the permission expiration date.
        permission.expirationDate = newExpirationDate;
    }

    /**
     * @notice Revokes the permission to use the sender's handles for the address `permittee`.
     * @param permittee The address of the account that is permitted to use the sender's handles.
     */
    function _revokeAccountAccess(address permittee, PermissionType permissionType) internal virtual {
        GCACLStorage storage $ = _getGCACLStorage();
        Permission storage permission = $.globalPermission[msg.sender][permittee][permissionType];

        uint64 oldExpirationDate = permission.expirationDate;

        _revokeAccountAccess(permission, permittee);

        emit AccountRevoked(
            msg.sender,
            permittee,
            permissionType,
            ++permission.permitCounter,
            oldExpirationDate
        );
    }

    /**
     * @notice Revokes the permission to use the sender's handles for the address `permittee`.
     * @param permittee The address of the account that is permitted to use the sender's handles.
     * @param contractAddress The contract address to delegate access to.
     */
    function _revokeContractAccountAccess(address permittee, address contractAddress, PermissionType permissionType) internal virtual {
        GCACLStorage storage $ = _getGCACLStorage();
        Permission storage permission = $.contractPermission[msg.sender][permittee][contractAddress][permissionType];

        uint64 oldExpirationDate = permission.expirationDate;
            
        _revokeAccountAccess(permission, permittee);

        // Remove contract address from enumerable set if permission is revoked (expirationDate is 0)
        // Only remove if the permission is actually revoked, not just updated
        if (permission.expirationDate == 0) {
            EnumerableSet.remove($.contractPermissionsSet[msg.sender][permittee][permissionType], contractAddress);
        }

        emit ContractAccountRevoked(
            msg.sender,
            permittee,
            contractAddress,
            permissionType,
            ++permission.permitCounter,
            oldExpirationDate
        );
    }

    function _revokeAccountAccess(Permission storage permission, address permittee) internal {
        uint256 blockNumber = block.number;

        if (permission.lastBlockPermitOrRevoke == blockNumber) {
            revert AlreadyPermittedOrRevokedInSameBlock(msg.sender, permittee, blockNumber);
        }

        // Set the last block where the revocation happened.
        permission.lastBlockPermitOrRevoke = uint64(blockNumber);

        uint64 oldExpirationDate = permission.expirationDate;
        if (oldExpirationDate == 0) {
            revert NotPermittedYet(msg.sender, permittee);
        }

        // Reset the permission expiration date.
        permission.expirationDate = 0;
    }

    /// @notice              Returns whether the permitter has full view access to the permittee.
    /// @param permitter     Address of the permitter.
    /// @param permittee     Address of the permittee.
    /// @return isPermitted  Whether the permitter has full view access to the permittee.
    function _isFullAccessPermitted(
        address permitter,
        address permittee,
        PermissionType permissionType
    ) internal view virtual returns (bool) {
        GCACLStorage storage $ = _getGCACLStorage();

        // Check full-view access
        return $.globalPermission[permitter][permittee][permissionType].expirationDate >= block.timestamp;
    }

    
    /// @notice              Returns whether the permitter has contract view access to the permittee.
    /// @param permitter     Address of the permitter.
    /// @param permittee     Address of the permittee.
    /// @param contractAddress  Address of the contract address.
    /// @return isPermitted  Whether the permitter has contract view access to the permittee.
    function _isContractAccessPermitted(
        address permitter,
        address permittee,
        address contractAddress,
        PermissionType permissionType
    ) internal view virtual returns (bool) {
        GCACLStorage storage $ = _getGCACLStorage();

        // Check contract view access
        return $.contractPermission[permitter][permittee][contractAddress][permissionType].expirationDate >= block.timestamp;
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
