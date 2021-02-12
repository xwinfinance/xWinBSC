pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later

import "./Library/xWinLibrary.sol";
import "./Interface/xWinDefiInterface.sol";
import "./Library/token/BEP20.sol";
import "./Library/token/SafeBEP20.sol";
import "./Interface/xWinMasterInterface.sol";
import "./Interface/BscSwapRouterInterface.sol";
import "./Interface/IPancakeRouter02.sol";
import "./Library/utils/TransferHelper.sol";
// ****** Turn on for unit test only
import "./mock/MockLibrary.sol";
// ****** Turn on for unit test only

contract xWinFund is IBEP20, BEP20 {
    
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    xWinMaster private _xWinMaster;

    address private protocolOwner;
    address private masterOwner;
    address[] private targetNamesAddress;
    address private managerOwner;
    uint256 private managerFeeBps;
    mapping(address => uint256) public TargetWeight;
    uint256 private rebalanceCycle = 876000; // will change back to 876000 in mainnet;
    
    uint256 public nextRebalance;
    address public BaseToken = address(0x0000000000000000000000000000000000000000);
    string public BaseTokenName = "BNB";
    IBSCswapRouter02 bscswapRouter;
    IPancakeRouter02 pancakeSwapRouter;
    xWinDefiInterface xwinProtocol;

    event Received(address, uint);
    event _ManagerFeeUpdate(uint256 fromFee, uint256 toFee, uint txnTime);
    event _ManagerOwnerUpdate(address fromAddress, address toAddress, uint txnTime);
    event _RebalanceCycleUpdate(uint fromCycle, uint toCycle, uint txnTime);

    modifier onlyxWinProtocol {
        require(
            msg.sender == protocolOwner,
            "Only xWinProtocol can call this function."
        );
        _;
    }
    modifier onlyManager {
        require(
            msg.sender == managerOwner,
            "Only managerOwner can call this function."
        );
        _;
    }
    
     constructor (
            string memory name,
            string memory symbol,
            address _protocolOwner,
            address _managerOwner,
            uint256 _managerFeeBps,
            address _masterOwner
        ) public BEP20(name, symbol) {
            protocolOwner = _protocolOwner;
            masterOwner = _masterOwner;
            managerOwner = _managerOwner;
            managerFeeBps = _managerFeeBps;
            _xWinMaster = xWinMaster(masterOwner);
            bscswapRouter = IBSCswapRouter02(_xWinMaster.getRouterAddress());
            xwinProtocol = xWinDefiInterface(_protocolOwner);
            nextRebalance = block.number.add(rebalanceCycle);
        }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    function mint(address to, uint256 amount) internal onlyxWinProtocol {
        _mint(to, amount);
    }
    
    function _swapBNBToTokens(
            address toDest,
            uint amountIn, 
            uint deadline,
            address destAddress,
            uint priceImpactTolerance 
            )
    internal returns (uint) {
            
            address[] memory path = new address[](2);
            path[0] = bscswapRouter.WBNB();
            path[1] = toDest;
            
            uint[] memory amounts = bscswapRouter.swapExactBNBForTokens{value: amountIn}(0, path, destAddress, deadline);
            
            uint swapOutput = amounts[amounts.length - 1];
            (uint priceImpact, uint subValue, ) = _outOfTolerancePriceImpact(toDest, amountIn, swapOutput, false);
            
            if(swapOutput < subValue){
                //require(priceImpact <= priceImpactTolerance, "price impact is higher");
            }
            return swapOutput;
        }

    function _swapTokenToBNB(
            address token,
            uint amountIn, 
            uint deadline,
            address destAddress,
            uint priceImpactTolerance
            )
    internal returns (uint) {
            
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = bscswapRouter.WBNB();
            
            TransferHelper.safeApprove(token, address(bscswapRouter), amountIn); 
            
            uint[] memory amounts = bscswapRouter.swapExactTokensForBNB(amountIn, 0, path, destAddress, deadline);
            
            uint swapOutput = amounts[amounts.length - 1];
            (uint priceImpact, uint subValue, ) = _outOfTolerancePriceImpact(token, amountIn, swapOutput, true);
            
            if(swapOutput < subValue){
                //require(priceImpact <= priceImpactTolerance, "price impact is higher");
            }
            return swapOutput;
        }
        
    function _outOfTolerancePriceImpact(
            address tokenaddress, 
            uint amountIn, 
            uint swapOutput, 
            bool toBNB
        ) internal view returns (uint priceImpact, uint subValue, uint price){
        
        require(swapOutput > 0, "swapOutput is zero");
        uint256 nominator = 1e18;
        price = toBNB == true? _getLatestPrice(tokenaddress) : nominator.mul(1e18).div(_getLatestPrice(tokenaddress));
        subValue = amountIn.mul(price).div(1e18);
        require(subValue > 0, "subValue is zero");
        priceImpact = 0;
        if(swapOutput >= subValue){
            priceImpact = swapOutput.mul(10000).div(subValue).sub(10000);
        }else{
            priceImpact = subValue.mul(10000).div(swapOutput).sub(10000);
        }
        return (priceImpact, subValue, price);
    }    
    
    /// Get All the fund data needed for client
    function GetFundDataAll() external view returns (
          IBEP20 _baseToken,
          address[] memory _targetNamesAddress,
          address _managerOwner,
          uint256 totalUnitB4,
          uint256 baseBalance,
          uint256 unitprice,
          uint256 fundvalue,
          string memory fundName,
          string memory symbolName,
          uint256 managerFee,
          uint256 unitpriceInUSD
        ){
            return (
                IBEP20(BaseToken), 
                targetNamesAddress, 
                managerOwner, 
                totalSupply(), 
                address(this).balance, 
                _getUnitPrice(), 
                _getFundValues(),
                name(),
                symbol(),
                managerFeeBps,
                _getUnitPriceInUSD()
            );
    }
   
   function getTargetNamesAddress() external view returns (address[] memory _targetNamesAddress){
        return targetNamesAddress;
   }

    /// @dev Get token balance
    function getBalance(address fromAdd) external view returns (uint256){
        return _getBalance(fromAdd);
    }

    /// @dev return target amount based on weight of each token in the fund
    function getTargetWeightQty(address targetAdd, uint256 srcQty) internal view returns (uint256){
        return TargetWeight[targetAdd].mul(srcQty).div(10000);
    }
    
    /// @dev return weight of each token in the fund
    function getTargetWeight(address addr) external view returns (uint256){
        return TargetWeight[addr];
    }
 
    /// @dev return number of target names
    function CreateTargetNames(
        address[] calldata _toAddresses, 
        uint256[] calldata _targetWeight
    ) external onlyxWinProtocol payable {

        _createTargetNames(_toAddresses, _targetWeight);
    }

    /// @dev update manager owner
    function updateRebalancePeriod(uint newCycle) external onlyManager payable {
        
        emit _RebalanceCycleUpdate(rebalanceCycle, newCycle, block.timestamp);
        rebalanceCycle = newCycle;
    }

    /// @dev update manager owner
    function updateManager(address newManager) external onlyManager payable {
        
        emit _ManagerOwnerUpdate(managerOwner, newManager, block.timestamp);
        managerOwner = newManager;
    }
    
    /// @dev update manager fee
    function updateManagerFee(uint256 newFeebps) external onlyManager payable {
        
        emit _ManagerFeeUpdate(managerFeeBps, newFeebps, block.timestamp);
        managerFeeBps = newFeebps;
    }
    
    /// @dev update xwin master contract
    function updateXwinMaster(address _masterOwner) external onlyManager {
        _xWinMaster = xWinMaster(_masterOwner);
    }
    
    /// @dev return target address
    function getWhoIsManager() external view returns(address){
        return managerOwner;
    }
    
    /// @dev return target address
    function getManagerFee() external view returns(uint256){
        return managerFeeBps;
    }

    /// @dev return unit price
    function getUnitPrice()
        external view returns(uint256){
        return _getUnitPrice();
    }
    
    /// @dev return unit price in USDT
    function getUnitPriceInUSD()
        external view returns(uint256){
        return _getUnitPriceInUSD();
    }
    
    /**
     * Returns the latest price
     */
    function getLatestPrice(address _targetAdd) external view returns (uint256) {
        return _getLatestPrice(_targetAdd);
    }
    
    /// @dev return fund total value in BNB
    function getFundValues() external view returns (uint256){
        return _getFundValues();
    }
    
    /// @dev return token value in the vault in BNB
    function getTokenValues(address tokenaddress) external view returns (uint256){
        return _getTokenValues(tokenaddress);
    }
    
    /// @dev perform rebalance with new weight and reset next rebalance period
    function Rebalance(
        address[] calldata _toAddresses, 
        uint256[] calldata _targetWeight,
        uint256 deadline,
        uint256 priceImpactTolerance
        ) external onlyxWinProtocol payable returns (uint256 baseccyBal) {
        
        //get delete names
        xWinLib.DeletedNames[] memory deletedNames = _getDeleteNames(_toAddresses);
        
        // move to base balance
        for (uint x = 0; x < deletedNames.length; x++){
            if(deletedNames[x].token != address(0)){
                  _moveNonIndexNameToBase(deletedNames[x].token, deadline, priceImpactTolerance); 
            }
        }
        // update new target
        _createTargetNames(_toAddresses, _targetWeight);
        
        //rebalance
        baseccyBal = _rebalance(deadline, priceImpactTolerance);
        return baseccyBal;
    }
    
    /// @dev perform subscription based on ratio setup
    function Subscribe(
        xWinLib.TradeParams memory _tradeParams,
        address _investorAddress
    ) external onlyxWinProtocol payable returns (uint256) {
        
        require(targetNamesAddress.length > 0, "no target setup");
        
        (uint256 mintQty, uint256 fundvalue) = _getMintQty(_tradeParams.amount);
        mint(_investorAddress, mintQty);
        
        // if hit rebalance period, do rebalance after minting qty
        if(nextRebalance < block.number){
            _rebalance(_tradeParams.deadline, _tradeParams.priceImpactTolerance);
        }else{
            uint256 totalSubs = address(this).balance;
            if(!_isSmallSubs(fundvalue, totalSubs)){
                for (uint i = 0; i < targetNamesAddress.length; i++) {
                    uint256 proposalQty = getTargetWeightQty(targetNamesAddress[i], totalSubs);
                    if(proposalQty > 0){
                        _swapBNBToTokens(targetNamesAddress[i], proposalQty, _tradeParams.deadline, address(this), _tradeParams.priceImpactTolerance);
                    }
                }
            }
        }
        return mintQty;
    }
    
    /// @dev perform redemption based on unit redeem
    function Redeem(
        xWinLib.TradeParams memory _tradeParams,
        address _investorAddress
    ) external onlyxWinProtocol payable returns (uint256){
        
        uint256 redeemratio = _tradeParams.amount.mul(1e18).div(totalSupply());
        require(redeemratio > 0, "redeem ratio is zero");
        
        _burn(msg.sender, _tradeParams.amount);
        
        uint256 totalBaseBal = address(this).balance;
        uint256 totalOutput = redeemratio.mul(totalBaseBal).div(1e18);
        
	    //start to transfer back to investor based on the targets
        for (uint i = 0; i < targetNamesAddress.length; i++) {
            xWinLib.transferData memory _transferData = _getTransferAmt(targetNamesAddress[i], redeemratio);
            
            if(_transferData.totalTrfAmt > 0){
                uint swapOutput = _swapTokenToBNB(targetNamesAddress[i], _transferData.totalTrfAmt, _tradeParams.deadline, address(this), _tradeParams.priceImpactTolerance);
                totalOutput = totalOutput.add(swapOutput);
            }
        }
        uint finalSwapOutput = _handleFeeTransfer(totalOutput);
        //TransferHelper.safeTransferBNB(_investorAddress, finalSwapOutput);
        MockLibrary.safeTransferBNB(_investorAddress, finalSwapOutput);
        return redeemratio;
    }
    
    /// @dev fund owner move any name back to BNB
    function MoveNonIndexNameToBase(
        address _tokenaddress,
        uint256 deadline,
        uint256 priceImpactTolerance
        ) external onlyxWinProtocol returns (uint256 balanceToken, uint256 swapOutput) {
            
            (balanceToken, swapOutput) = _moveNonIndexNameToBase(_tokenaddress, deadline, priceImpactTolerance);
            return (balanceToken, swapOutput);
        }
        
        
    /// @dev fund owner move all token to BNB. user call this to get the portion in BNB
    function emergencyRedeem(uint256 redeemUnit, address _investorAddress) external onlyxWinProtocol payable {
            
        uint256 redeemratio = redeemUnit.mul(1e18).div(totalSupply());
        require(redeemratio > 0, "redeem ratio is zero");
        _burn(msg.sender, redeemUnit);
        uint256 totalBaseBal = address(this).balance;
        uint256 totalOutput = redeemratio.mul(totalBaseBal).div(1e18);
        TransferHelper.safeTransferBNB(_investorAddress, totalOutput);
    }
        
    /// @dev Calc return balance during redemption
    function _getTransferAmt(address underyingAdd, uint256 redeemratio) 
        internal view returns (xWinLib.transferData memory transData) {
       
        xWinLib.transferData memory _transferData;
        _transferData.totalUnderlying = _getBalance(underyingAdd); 
        uint256 qtyToTrf = redeemratio.mul(_transferData.totalUnderlying).div(1e18);
        _transferData.totalTrfAmt = qtyToTrf;
        return _transferData;
    }
    
    /// @dev Calc qty to issue during subscription 
    function _getMintQty(uint256 srcQty) internal view returns (uint256 mintQty, uint256 totalFundB4)  {
        
        uint256 totalFundAfter = _getFundValues();
        totalFundB4 = totalFundAfter.sub(srcQty);
        mintQty = _getNewFundUnits(totalFundB4, totalFundAfter, totalSupply());
        return (mintQty, totalFundB4);
    }
    
    function _getActiveOverWeight(address destAddress, uint256 totalfundvalue) 
        internal view returns (uint256 destRebQty, uint256 destActiveWeight, bool overweight, uint256 fundWeight) {
        
        destRebQty = 0;
        uint256 destTargetWeight = TargetWeight[destAddress];
        uint256 destValue = _getTokenValues(destAddress);
        fundWeight = destValue.mul(10000).div(totalfundvalue);
        overweight = fundWeight > destTargetWeight;
        destActiveWeight = overweight ? fundWeight.sub(destTargetWeight): destTargetWeight.sub(fundWeight);
        if(overweight){
            uint price = _getLatestPrice(destAddress);
            destRebQty = destActiveWeight.mul(totalfundvalue).mul(1e18).div(price).div(10000);
        }
        return (destRebQty, destActiveWeight, overweight, fundWeight);
    }
    
    function _rebalance(uint256 deadline, uint256 priceImpactTolerance) 
        internal returns (uint256 baseccyBal) {
        
        (xWinLib.UnderWeightData[] memory underweightNames, uint256 totalunderActiveweight) = _sellOverWeightNames (deadline, priceImpactTolerance);
        baseccyBal = _buyUnderWeightNames(deadline, priceImpactTolerance, underweightNames, totalunderActiveweight); 
        nextRebalance = block.number.add(rebalanceCycle);
        return baseccyBal;
    }
    
    function _sellOverWeightNames (uint256 deadline, uint256 priceImpactTolerance) 
        internal returns (xWinLib.UnderWeightData[] memory underweightNames, uint256 totalunderActiveweight) {
        
        uint256 totalfundvaluebefore = _getFundValues();
        totalunderActiveweight = 0;
        
        underweightNames = new xWinLib.UnderWeightData[](targetNamesAddress.length);

        for (uint i = 0; i < targetNamesAddress.length; i++) {
            (uint256 rebalQty, uint256 destActiveWeight, bool overweight, uint256 fundWeight) = _getActiveOverWeight(targetNamesAddress[i], totalfundvaluebefore);
            if(overweight) //sell token to BNB
            {
                _swapTokenToBNB(targetNamesAddress[i], rebalQty, deadline, address(this), priceImpactTolerance);
            }else{
                if(destActiveWeight > 0){
                    xWinLib.UnderWeightData memory _underWeightData;
                    _underWeightData.token = targetNamesAddress[i];
                    _underWeightData.fundWeight = fundWeight;
                    _underWeightData.activeWeight = destActiveWeight;
                    _underWeightData.overweight = false;
                    underweightNames[i] = _underWeightData;
    
                    totalunderActiveweight = totalunderActiveweight.add(destActiveWeight);
                }
            }
        }
        
        return (underweightNames, totalunderActiveweight);
    }
    
    function _buyUnderWeightNames (
        uint256 deadline, 
        uint256 priceImpactTolerance, 
        xWinLib.UnderWeightData[] memory underweightNames,
        uint256 totalunderActiveweight
        ) 
        internal returns (uint256 baseccyBal) {
        
        baseccyBal = address(this).balance;
        for (uint i = 0; i < underweightNames.length; i++) {
            
            if(underweightNames[i].token != address(0)){
                uint256 rebaseActiveWgt = underweightNames[i].activeWeight.mul(10000).div(totalunderActiveweight);
                uint256 rebBuyQty = rebaseActiveWgt.mul(baseccyBal).div(10000);
                if(rebBuyQty > 0 && rebBuyQty <= address(this).balance){
                    _swapBNBToTokens(underweightNames[i].token, rebBuyQty, deadline, address(this), priceImpactTolerance);
                }
            }
        }
        return baseccyBal;
    }
    
    function _getLatestPrice(address _targetAdd) internal view returns (uint256) {
        return _xWinMaster.getPriceByAddress(_targetAdd, BaseTokenName);
    }

    function _getFundValues() internal view returns (uint256){
        
        uint256 totalValue = address(this).balance;
        for (uint i = 0; i < targetNamesAddress.length; i++) {
            uint256 tokenBalance = _getBalance(targetNamesAddress[i]);
            if(tokenBalance > 0){
                uint256 price = _getLatestPrice(targetNamesAddress[i]); //price from token to BNB
                uint256 subValue = tokenBalance.mul(uint256(price)).div(1e18);
                totalValue = totalValue.add(subValue);
            }
        }
        return totalValue; 
    }
    
    function _getUnitPrice() internal view returns(uint256){
        
        uint256 totalValueB4 = _getFundValues();
        if(totalValueB4 == 0) return 0;
        uint256 totalUnitB4 = totalSupply();
    	if(totalUnitB4 == 0) return 0;
        return totalValueB4.mul(1e18).div(totalUnitB4);
    }

    function _getTokenValues(address tokenaddress) internal view returns (uint256){
        
        uint256 tokenBalance = _getBalance(tokenaddress);
        uint256 price = _getLatestPrice(tokenaddress); //price from token to BNB
        return tokenBalance.mul(uint256(price)).div(1e18);
    }

    function _getBalance(address fromAdd) internal view returns (uint256){
        
        if(IBEP20(fromAdd) == IBEP20(BaseToken)) return address(this).balance;
        return IBEP20(fromAdd).balanceOf(address(this));
    }
    
    function _getUnitPriceInUSD() internal view returns(uint256){
        
        uint256 totalValue = _getUnitPrice();
        uint256 toBasePrice = _xWinMaster.getPriceFromBand(BaseTokenName, "USDT"); 
        return totalValue.mul(toBasePrice).div(1e18);
    }
    
    function _moveNonIndexNameToBase(
        address _tokenaddress,
        uint256 deadline,
        uint256 priceImpactTolerance
        ) internal returns (uint256 balanceToken, uint256 swapOutput) {
            
            balanceToken = _getBalance(_tokenaddress);
            swapOutput = _swapTokenToBNB(_tokenaddress, balanceToken, deadline, address(this), priceImpactTolerance);
            return (balanceToken, swapOutput);
    }

    function _createTargetNames(
        address[] calldata _toAddresses, 
        uint256[] calldata _targetWeight
    ) internal {

        if(targetNamesAddress.length > 0){
            for (uint i = 0; i < targetNamesAddress.length; i++) {
                TargetWeight[targetNamesAddress[i]] = 0;
            }
            delete targetNamesAddress;
        }
        
        for (uint i = 0; i < _toAddresses.length; i++) {
            TargetWeight[_toAddresses[i]] = _targetWeight[i];
            targetNamesAddress.push(_toAddresses[i]);
        }
    }
    
    function _getDeleteNames(
            address[] calldata _toAddresses
        ) internal view returns (xWinLib.DeletedNames[] memory deletedNames){
        
        deletedNames = new xWinLib.DeletedNames[](targetNamesAddress.length);

        for (uint i = 0; i < targetNamesAddress.length; i++) {
            uint matchtotal = 1;
            for (uint x = 0; x < _toAddresses.length; x++){
                if(targetNamesAddress[i] == _toAddresses[x]){
                    break;
                }else if(targetNamesAddress[i] != _toAddresses[x] && _toAddresses.length == matchtotal){
                    deletedNames[i].token = targetNamesAddress[i]; 
                }
                matchtotal++;
            }
        }
        return deletedNames;
     }

    function _handleFeeTransfer(
        uint swapOutput
        ) internal returns (uint finalSwapOutput){
        
        
        uint platformUnit = swapOutput.mul(xwinProtocol.getPlatformFee()).div(10000);
        
        if(platformUnit > 0){
            uint benefit = platformUnit.mul(3000).div(10000); //30% go to benefit pool for community
            MockLibrary.safeTransferBNB(xwinProtocol.getPlatformAddress(), benefit);
            MockLibrary.safeTransferBNB(xwinProtocol.gexWinBenefitPool(), platformUnit.sub(benefit));
            // TransferHelper.safeTransferBNB(xwinProtocol.getPlatformAddress(), benefit);
            // TransferHelper.safeTransferBNB(xwinProtocol.gexWinBenefitPool(), platformUnit.sub(benefit));
        }
        
        uint managerUnit = swapOutput.mul(managerFeeBps).div(10000);
        
        if(managerUnit > 0){
            MockLibrary.safeTransferBNB(managerOwner, managerUnit);
            //TransferHelper.safeTransferBNB(managerOwner, managerUnit);
        }
        
        finalSwapOutput = swapOutput.sub(platformUnit).sub(managerUnit);
        
        return (finalSwapOutput);

    }
    
    function _isSmallSubs(uint256 fundvalue, uint256 subsAmt) 
        internal pure returns (bool)  {
        
        if(fundvalue == 0) return false;
        uint256 percentage = subsAmt.mul(10000).div(fundvalue);
        if(percentage > 500) return false;
        
        return true;
    }
    
    /// @dev Mint unit back to investor
    function _getNewFundUnits(uint256 totalFundB4, uint256 totalValueAfter, uint256 totalSupply) 
        internal pure returns (uint256){
          
        if(totalValueAfter == 0) return 0;
        if(totalFundB4 == 0) return totalValueAfter; 

        uint256 totalUnitAfter = totalValueAfter.mul(totalSupply).div(totalFundB4);
        uint256 mintUnit = totalUnitAfter.sub(totalSupply);
        
        return mintUnit;
    }
}