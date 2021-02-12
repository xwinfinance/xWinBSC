pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later
//import "github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../Library/xWinLibrary.sol";

interface xWinFund {
    
    function getManagerFee() external view returns(uint256);
    function getTargetWeight(address addr) external view returns (uint256);
    function getWhoIsManager() external view returns(address mangerAddress);
    function getBalance(address fromAdd) external view returns (uint256 balance);
    function getFundValues() external view returns (uint256);
    function getTargetWeightQty(address targetAdd, uint256 srcQty) external view returns (uint256);
    function updateManager(address managerAdd) external payable;
    function updateManagerFee(uint256 newFeebps) external payable;
    function updateRebalancePeriod(uint newCycle) external payable;
    
    function Redeem(
        xWinLib.TradeParams memory _tradeParams,
        address _investorAddress
    ) external payable returns (uint256);
        
    function Rebalance(
        address[] calldata _toAddresses, 
        uint256[] calldata _targetWeight,
        uint256 deadline,
        uint256 priceImpactTolerance
        ) external payable returns (uint256 baseccyBal);
        
    function Subscribe(
        xWinLib.TradeParams memory _tradeParams,
        address _investorAddress
    ) external payable returns (uint256);
        
    function MoveNonIndexNameToBase(
        address _tokenaddress,
        uint256 deadline,
        uint256 priceImpactTolerance
        ) external returns (uint256 balanceToken, uint256 swapOutput);
        
    function CreateTargetNames(
        address[] calldata _toAddresses, 
        uint256[] calldata _targetWeight
    ) external payable;
    
    function emergencyRedeem(uint256 redeemUnit, address _investorAddress) external payable; 
    function emergencyRemoveFromFarm() external;
   
    function getUnitPrice() external view returns(uint256 unitprice);
    function getUnitPriceInUSD() external view returns(uint256 unitprice);
    function getTargetNamesAddress() external view returns (address[] memory _targetNamesAddress);
}
