pragma solidity ^0.6.0;
// SPDX-License-Identifier: GPL-3.0-or-later
interface xWinMaster {
    
    function getPriceFeedAddress() external view returns (address priceFeedaddress);
    function getTokenName(address _tokenaddress) external view returns (string memory tokenname);
    function getRouterAddress() external view returns (address);
    function getPriceByAddress(address _targetAdd, string memory _toTokenName) external view returns (uint);
    function getPriceFromBand(string memory _fromToken, string memory _toToken) external view returns (uint);
}
