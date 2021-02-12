pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later

interface xWinStake {
    
    function StakeReward(
        address payable _investorAddress,
        uint256 rewardQty,
        uint256 bnbQty,
        uint256 deadline
        ) external payable; 
        
    function GetQuotes(
        uint256 rewardQty, 
        uint256 baseQty,
        address targetToken
        ) external view 
        returns (uint amountB, uint amountA, uint amountOut); 
}
