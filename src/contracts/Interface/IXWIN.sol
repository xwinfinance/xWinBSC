pragma solidity >=0.6.0;
// SPDX-License-Identifier: GPL-3.0-or-later
interface IXWIN {
    
    function mint(address _to, uint256 _amount) external;
    function isCapReach() external view returns (bool); 
}