pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later

import "./Library/PancakeSwapLibrary.sol";
import "./Interface/IPancakeRouter02.sol";
import "./Library/utils/TransferHelper.sol";
import "./Library/access/Ownable.sol";

contract xWinStake is Ownable  {
    
    using SafeMath for uint256;

    address private protocolOwner;
    address public farmToken;
    string public name;
    address private deployeraddress;
    IPancakeRouter02 pancakeSwapRouter;
    event Received(address, uint);

    constructor(
        string memory _name
        ) public {
            
        deployeraddress = msg.sender;
        pancakeSwapRouter = IPancakeRouter02(address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F));
        name = _name;
    }
    
    event _StakeReward(uint amountToken, uint amountBNB, uint liquidity, uint refund, uint balanceBNB);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
   
    /// @dev Add rewarded XWIN token to pancake LP
    function StakeReward(
        address payable _investorAddress,
        uint256 rewardQty,
        uint256 bnbQty,
        uint256 deadline
        ) external payable {
        
        require(farmToken != address(0), "no farmtoken assign");
        
        (uint amountToken, uint amountBNB, uint liquidity) = _addLiquidityBNB(_investorAddress, rewardQty, bnbQty, deadline);

        uint refund = (bnbQty).sub(amountBNB);
        TransferHelper.safeTransferBNB(_investorAddress, refund); //refund remaining bnb to investor
        emit _StakeReward(amountToken, amountBNB, liquidity, refund, bnbQty);

    }
    
    function _addLiquidityBNB(
            address fromaddress,
            uint rewardQty, 
            uint bnbAmt,
            uint deadline
            )
    internal returns (uint amountToken, uint amountBNB, uint liquidity) {
            
        TransferHelper.safeApprove(farmToken, address(pancakeSwapRouter), rewardQty); 
        
        (uint amountB,,,,,) = GetQuotes(rewardQty, bnbAmt, farmToken);       
        (amountToken, amountBNB, liquidity) = pancakeSwapRouter.addLiquidityETH{value: bnbAmt}(
            farmToken,
            rewardQty,
            rewardQty.mul(9950).div(10000),
            amountB.mul(9950).div(10000), 
            fromaddress,
            deadline
            );
        return (amountToken, amountBNB, liquidity);
            
    }

    /// @dev update XWN token address by deployer
    function updateFarmToken(address newFarmToken) external onlyOwner {
        farmToken = newFarmToken;
    }
    
    function GetQuotes(
        uint256 rewardQty, 
        uint256 baseQty,
        address targetToken
    ) public view 
        returns (uint amountB, uint amountA, uint amountOutB, uint amountOutA, uint amountInA, uint amountInB) {
        
        (uint reserveA, uint reserveB) = PancakeLibrary.getReserves(pancakeSwapRouter.factory(), targetToken, pancakeSwapRouter.WETH());
        amountOutB = PancakeLibrary.getAmountOut(rewardQty, reserveA, reserveB);
        amountInA = PancakeLibrary.getAmountIn(amountOutB, reserveA, reserveB);
        
        amountOutA = PancakeLibrary.getAmountOut(baseQty, reserveB, reserveA);
        amountInB = PancakeLibrary.getAmountIn(baseQty, reserveB, reserveA);
        
        amountB = PancakeLibrary.quote(rewardQty, reserveA, reserveB);
        amountA = PancakeLibrary.quote(baseQty, reserveB, reserveA);
        
        return (amountB, amountA, amountOutB, amountOutA, amountInA, amountInB);
        
    }
   
}