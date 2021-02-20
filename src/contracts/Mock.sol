pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later

import "./Library/math/SafeMath.sol";
import "./Library/utils/TransferHelper.sol";
import "./Library/token/SafeBEP20.sol";
import "./Library/access/Ownable.sol";


contract Mock is Ownable{
    
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    function factory() external view returns (address){
        return address(this);
    }
    function WBNB() external view returns (address){
        return address(this);
    }

    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }
    string public name;

    constructor() public {
        name = "Mock";
    }
    
    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory){
            ReferenceData memory ref;
            ref.rate = 1e18;
            ref.lastUpdatedQuote = 10000;
            ref.lastUpdatedBase = 10000;
            return ref;
        }

    function swapExactBNBForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts){
            
            uint[] memory tempamounts = new uint[](1);
            tempamounts[0] = 1e18;
            TransferHelper.safeTransfer(path[1], to, tempamounts[0]);
            return tempamounts;
        }

    function swapExactTokensForBNB(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts){
            
            uint[] memory tempamounts = new uint[](1);
            tempamounts[0] = 1e18;
            TransferHelper.safeTransfer(path[0], to, tempamounts[0]);
            return tempamounts;
        }

    
    function addLiquidityBNB(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountBNB, uint liquidity){

        return (10000, 20000, 500000);
    }

    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        // (address token0,) = sortTokens(tokenA, tokenB);
        // (uint reserve0, uint reserve1,) = IBSCswapPair(pairFor(factory, tokenA, tokenB)).getReserves();
        // (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        return (1000000000, 2000000000);
    }
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB){
        return 100000;
    }
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut){
        return 100000;
    }
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn){
        return 100000;
    }

}
