pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later
//import "../Library/xWinLibrary.sol";

interface xWinDefiInterface {
    
    function getPlatformFee() view external returns (uint256);
    function getPlatformAddress() view external returns (address);
    function gexWinBenefitPool() view external returns (address) ;
}
