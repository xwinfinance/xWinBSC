pragma solidity ^0.6.0;
// SPDX-License-Identifier: GPL-3.0-or-later

import "./AccessControl.sol";
/**
 * @title Administered
 * @author Alberto Cuesta Canada
 * @notice Implements Admin and User roles.
 */
contract AdminAccessRoles is AccessControl {
  
  bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
  
  /// @dev Add `root` to the admin role as a member.
  constructor (address root) public
  {
    _setupRole(DEFAULT_ADMIN_ROLE, root);
    _setRoleAdmin(MINT_ROLE, DEFAULT_ADMIN_ROLE);
  }
  /// @dev Restricted to members of the admin role.
  modifier onlyAdmin()
  {
    require(isAdmin(msg.sender), "Restricted to admins.");
    _;
  }
  /// @dev Restricted to members of the user role.
  modifier onlyMintUser()
  {
    require(isMintUser(msg.sender), "Restricted to MintUser.");
    _;
  }
  /// @dev Return `true` if the account belongs to the admin role.
  function isAdmin(address account)
    public virtual view returns (bool)
  {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }
  /// @dev Return `true` if the account belongs to the user role.
  function isMintUser(address account)
    public virtual view returns (bool)
  {
    return hasRole(MINT_ROLE, account);
  }
  /// @dev Add an account to the user role. Restricted to admins.
  function addMintUser(address account)
    public virtual onlyAdmin
  {
    grantRole(MINT_ROLE, account);
  }
  /// @dev Add an account to the admin role. Restricted to admins.
  function addAdmin(address account)
    public virtual onlyAdmin
  {
    grantRole(DEFAULT_ADMIN_ROLE, account);
  }
  /// @dev Remove an account from the user role. Restricted to admins.
  function removeMintUser(address account)
    public virtual onlyAdmin
  {
    revokeRole(MINT_ROLE, account);
  }
  /// @dev Remove oneself from the admin role.
  function renounceAdmin()
    public virtual
  {
    renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }
}