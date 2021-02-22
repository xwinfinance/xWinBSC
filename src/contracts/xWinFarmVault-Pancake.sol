pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later

import "./PancakeMasterChef.sol";
import "./Interface/xWinDefiInterface.sol";
import "./Interface/xWinMasterInterface.sol";
import "./Interface/IPancakeRouter02.sol";
import "./Library/utils/TransferHelper.sol";
import "./Library/PancakeSwapLibrary.sol";


contract xWinFarmP is IBEP20, BEP20 {
    
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    xWinMaster private _xWinMaster;

    address private protocolOwner;
    address private masterOwner;
    address private managerOwner;
    uint256 private managerFeeBps;
    bool public performFarm = true;
    
    address public farmToken;
    address public cakeToken;// = address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    uint256 public pid;
    address public BaseToken = address(0x0000000000000000000000000000000000000000);
    
    IPancakeRouter02 pancakeSwapRouter;
    MasterChef _masterChef;
    xWinDefiInterface xwinProtocol;
    
    event Received(address, uint);
    event _ManagerFeeUpdate(uint256 fromFee, uint256 toFee, uint txnTime);
    event _ManagerOwnerUpdate(address fromAddress, address toAddress, uint txnTime);
    
    struct TradeParams {
      address xFundAddress;
      uint256 amount;
      uint256 priceImpactTolerance;
      uint256 deadline;
      bool returnInBase;
      address referral;
    }  
    
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
            address _masterOwner,
            address _cakeToken,
            address _farmToken,
            uint256 _pid,
            bool _performFarm
        ) public BEP20(name, symbol) {
            performFarm = _performFarm;
            cakeToken = _cakeToken;
            farmToken = _farmToken;
            pid = _pid; 
            protocolOwner = _protocolOwner;
            masterOwner = _masterOwner;
            managerOwner = _managerOwner;
            managerFeeBps = _managerFeeBps;
            _xWinMaster = xWinMaster(masterOwner);
            pancakeSwapRouter = IPancakeRouter02(address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F));
            _masterChef = MasterChef(address(0x73feaa1eE314F8c655E354234017bE2193C9E24E));
            xwinProtocol = xWinDefiInterface(_protocolOwner);
        }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    function mint(address to, uint256 amount) internal onlyxWinProtocol {
        _mint(to, amount);
    }
    
    function updateFarmInfo(uint256 _pid, bool _on) public onlyManager {
        pid = _pid;
        performFarm = _on;
    }
    
    function _swapBNBToTokens(
            address toDest,
            uint amountIn, 
            uint deadline,
            address destAddress,
            uint priceImpactTolerance 
            )
    internal returns (uint){
            
            address[] memory path = new address[](2);
            path[0] = pancakeSwapRouter.WETH();
            path[1] = toDest;
            
            (uint reserveA,  uint reserveB) = PancakeLibrary.getReserves(pancakeSwapRouter.factory(), pancakeSwapRouter.WETH(), farmToken);
            uint quote = PancakeLibrary.quote(amountIn, reserveA, reserveB);
            uint[] memory amounts = pancakeSwapRouter.swapExactETHForTokens{value: amountIn}(quote.sub(quote.mul(priceImpactTolerance).div(10000)), path, destAddress, deadline);
            
            return amounts[amounts.length - 1];
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
            path[1] = pancakeSwapRouter.WETH();
            
            TransferHelper.safeApprove(token, address(pancakeSwapRouter), amountIn); 
            
            (uint reserveA,  uint reserveB) = PancakeLibrary.getReserves(pancakeSwapRouter.factory(), farmToken, pancakeSwapRouter.WETH());
            uint quote = PancakeLibrary.quote(amountIn, reserveA, reserveB);
            uint[] memory amounts = pancakeSwapRouter.swapExactTokensForETH(amountIn, quote.sub(quote.mul(priceImpactTolerance).div(10000)), path, destAddress, deadline);
			return amounts[amounts.length - 1];

        }
        
    function _addLiquidityBNB(
            uint amount, 
            uint bnbAmt,
            uint deadline
            )
    internal returns (uint amountToken, uint amountBNB, uint liquidity) {
            
        TransferHelper.safeApprove(farmToken, address(pancakeSwapRouter), amount); 
        
        (amountToken, amountBNB, liquidity) = pancakeSwapRouter.addLiquidityETH{value: bnbAmt}(
            farmToken,
            amount,
            amount.mul(9950).div(10000),
            bnbAmt.mul(9950).div(10000), 
            address(this),
            deadline
            );
        return (amountToken, amountBNB, liquidity);
            
    }
        
 /// @dev update manager owner
    function updateManager(address newManager) external onlyManager payable {
        
        emit _ManagerOwnerUpdate(managerOwner, newManager, block.timestamp);
        managerOwner = newManager;
    }
    
    /// @dev update protocol owner
    function updateProtocol(address _newProtocol) external onlyxWinProtocol {
        protocolOwner = _newProtocol;
        xwinProtocol = xWinDefiInterface(_newProtocol);
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
     * Returns the pair amount for the balance own
     */
    function getPairBalance(address _targetAdd) external view returns (uint, uint) {
        return _getPairBalance(_targetAdd);
    }
    
    /// @dev return fund total value in BNB
    function getFundValues() external view returns (uint256){
        return _getFundValues();
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
            
            address[] memory targetNamesAddress;
            
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
    
 
    /// @dev perform subscription based on BNB received and put them into LP
    function Subscribe(
        TradeParams memory _tradeParams,
        address _investorAddress
        ) external onlyxWinProtocol payable returns (uint256) {
        
        
        uint256 halfAmt =  _tradeParams.amount.mul(5000).div(10000);
        uint256 swapOutput = _swapBNBToTokens(farmToken, halfAmt, _tradeParams.deadline, address(this), _tradeParams.priceImpactTolerance);
        
        // get quote for farmtoken based on fixed bnb amount
        uint amountBToGo = _getQuoteAdjusted(halfAmt, swapOutput);
        (uint amountToken, uint amountBNB, uint liquidity) = _addLiquidityBNB(amountBToGo, halfAmt, _tradeParams.deadline);

        mint(_investorAddress, liquidity);
        
        if(performFarm) _addToPancakeFarm(liquidity);

        // refund any BNB leftover
        if(_tradeParams.amount.sub(amountBNB).sub(halfAmt) > 0) TransferHelper.safeTransferBNB(_investorAddress, _tradeParams.amount.sub(amountBNB).sub(halfAmt));

        // refund any XWN token leftover
        if(swapOutput.sub(amountToken) > 0) TransferHelper.safeTransfer(farmToken, _investorAddress, swapOutput.sub(amountToken));
        
        return liquidity;
    }
    
    /// @dev perform redemption based on unit redeem
    function Redeem(
        TradeParams memory _tradeParams,
        address _investorAddress
        ) external onlyxWinProtocol payable returns (uint256){
        
        uint256 redeemratio = _tradeParams.amount.mul(1e18).div(totalSupply());
        require(redeemratio > 0, "redeem ratio is zero");
        
        //get bnb bal before remove from L 
        uint256 totalBaseBal = address(this).balance;
        //if there is any BNB balance
        uint256 totalOutput = redeemratio.mul(totalBaseBal).div(1e18);
        
        //withdraw from pancake staking pool first
        if(performFarm) _removeFromFarm(_tradeParams.amount);

        (uint amountToken, uint amountBNB) = _removeFromLP(_tradeParams.amount, _tradeParams.deadline);
        
        _burn(msg.sender, _tradeParams.amount);
        
        uint256 cakeBal = IBEP20(cakeToken).balanceOf(address(this));
        
        totalOutput = totalOutput.add(amountBNB);
        
        uint256 cakeBalDiff = cakeBal;
        if(cakeToken == farmToken) cakeBalDiff = cakeBal.sub(amountToken);
        
        //convert farmtoken and return in BNB
        uint256 swapOutput = 0;
        if(amountToken > 0){
            swapOutput = _swapTokenToBNB(farmToken, amountToken, _tradeParams.deadline, address(this), _tradeParams.priceImpactTolerance);
            totalOutput = totalOutput.add(swapOutput);
        } 
        
        //convert caketoken and return in BNB
        if(cakeBalDiff > 0){
            swapOutput = _swapTokenToBNB(cakeToken, redeemratio.mul(cakeBalDiff).div(1e18), _tradeParams.deadline, address(this), _tradeParams.priceImpactTolerance);
            totalOutput = totalOutput.add(swapOutput);
        } 
        uint finalSwapOutput = _handleFeeTransfer(totalOutput);
        TransferHelper.safeTransferBNB(_investorAddress, finalSwapOutput);
        return redeemratio;
        
    }
    
    function _getWithdrawRewardWithCushion(address tokenaddress, uint256 withdrawQty) internal view returns ( 
            uint256 totalSupply, uint256 ratio, uint256 reserveA, uint256 reserveB, 
            uint256 ATokenAmount, uint256 amountB, uint256 ATokenAmountMin, uint256 amountBMin,
            address pair 
            ) {
        
        pair = PancakeLibrary.pairFor(pancakeSwapRouter.factory(), tokenaddress, pancakeSwapRouter.WETH());
        totalSupply = IBEP20(pair).totalSupply(); 
        ratio = withdrawQty.mul(1e18).div(totalSupply);
        
        if(ratio > 0){
            ( reserveA,  reserveB) = PancakeLibrary.getReserves(pancakeSwapRouter.factory(), tokenaddress,  pancakeSwapRouter.WETH());
            ATokenAmount = reserveA.mul(ratio).div(1e18);
            amountB = PancakeLibrary.quote(ATokenAmount, reserveA, reserveB);
        }else{
            ATokenAmount = 0;
            amountB = 0;
        }
        ATokenAmountMin = ATokenAmount.mul(9950).div(10000);
        amountBMin = amountB.mul(9950).div(10000);
        
        return (totalSupply, ratio, reserveA, reserveB, ATokenAmount, amountB, ATokenAmountMin, amountBMin,  pair);
    }
    
     function _getQuoteAdjusted(
        uint halfAmt,
        uint swapOutput
        ) internal view returns (uint){
            
            (uint amountB, ) = _getQuotes(halfAmt, farmToken);
            return (amountB > swapOutput ? swapOutput:  amountB);
        } 
    
    function _getFundValues() internal view returns (uint256){
        
        //get estimate cake value in bnb
        uint256 bnbBalance = address(this).balance;

        (uint farmtoBNBEstAmount,  uint caketoBNBEstAmount) = _getFarmCakeEstBalance();
        
        // estimate LP balance value in BNB
        (uint amountAInBNB, uint amountBNB) = _getPairBalance(farmToken);
        
        // add them up in BNB
        return bnbBalance.add(amountAInBNB).add(amountBNB).add(caketoBNBEstAmount).add(farmtoBNBEstAmount);
    }
    
    function _getUnitPrice() internal view returns(uint256){
        
        uint256 totalValueB4 = _getFundValues();
        if(totalValueB4 == 0) return 0;
        uint256 totalUnitB4 = totalSupply();
    	if(totalUnitB4 == 0) return 0;
        return totalValueB4.mul(1e18).div(totalUnitB4);
    }

    function _getUnitPriceInUSD() internal view returns(uint256){
        
        uint256 totalValue = this.getUnitPrice();
        uint256 toBasePrice = _xWinMaster.getPriceFromBand("BNB", "USDT"); 
        return totalValue.mul(toBasePrice).div(1e18);
    }
    
    function _getPairBalance(address _targetAdd) internal view returns (uint, uint) {
        
        address pair = PancakeLibrary.pairFor(pancakeSwapRouter.factory(), _targetAdd, pancakeSwapRouter.WETH());
        uint totalSupply = IBEP20(pair).totalSupply();
        if(totalSupply == 0) return (0,0);

        uint lpTokenBalance = 0;
        
        if(performFarm){
            (lpTokenBalance, ) = _readUserInfo();
        }else{
            lpTokenBalance = IBEP20(pair).balanceOf(address(this));
        }

        if(lpTokenBalance == 0) return (0,0);

        uint ratio = lpTokenBalance.mul(1e18).div(totalSupply);
        
        if(ratio == 0) return (0,0);
        
        (uint reserveA,  uint reserveB) = PancakeLibrary.getReserves(pancakeSwapRouter.factory(), _targetAdd,  pancakeSwapRouter.WETH());
        
        //convert A to BNb
        uint myPortions = reserveA.mul(ratio).div(1e18);
        uint AtoBNBEstAmount = PancakeLibrary.quote(myPortions, reserveA, reserveB);
        
        return (AtoBNBEstAmount, reserveB.mul(ratio).div(1e18));
    }
    
    function _getQuotes(
        uint256 bnbQty, 
        address targetToken
        ) internal view 
        returns (uint amountB, uint amountOut) {
        
        (uint reserveA, uint reserveB) = PancakeLibrary.getReserves(pancakeSwapRouter.factory(), pancakeSwapRouter.WETH(), targetToken);
        amountOut = PancakeLibrary.getAmountOut(bnbQty, reserveA, reserveB);
        amountB = PancakeLibrary.quote(bnbQty, reserveA, reserveB);
        
        return (amountB, amountOut);
        
    }
   
    /// @dev perform Add Syrup Pool
    function _addToPancakeFarm(uint256 _amount) internal {
        
        (IBEP20 lpToken, , , ) = _readPool();
        require(lpToken.approve(address(_masterChef), _amount), "approval to _masterChef failed");
        _masterChef.deposit(pid, _amount);

    }
    
    function _readPool() internal view returns (
        IBEP20 lpToken,          // Address of LP token contract.
        uint256 allocPoint,       // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 lastRewardBlock,  // Last block number that CAKEs distribution occurs.
        uint256 accCakePerShare
        ) {
        return _masterChef.poolInfo(pid);
    }
    
    function _readUserInfo() internal view returns (
        uint256 amount,    // How many LP tokens the user has provided.
        uint256 rewardDebt
        ) {
        return _masterChef.userInfo(pid, address(this));
    }
    
    function _removeFromFarm(uint256 _removeAmount) 
        internal {
        
        _masterChef.withdraw(pid, _removeAmount);

    }
    
    function _removeFromLP(uint256 redeemUnit, uint256 deadline) 
        internal returns (uint256 amountToken, uint256 amountBNB) {
        
        //calc how much to get from remove LP token liquidity
        (,,,,,, uint ATokenAmountMin, uint amountBMin, address pair) = _getWithdrawRewardWithCushion(farmToken, redeemUnit);
        
        TransferHelper.safeApprove(pair, address(pancakeSwapRouter), redeemUnit); 
        (amountToken, amountBNB) = pancakeSwapRouter.removeLiquidityETH(
            farmToken,
            redeemUnit,
            ATokenAmountMin,
            amountBMin, 
            address(this),
            deadline
            );
        return (amountToken, amountBNB);
    }
    
     function _getFarmCakeEstBalance() 
        internal view returns (uint256 farmtoBNBEstAmount, uint256 caketoBNBEstAmount) {
        
        uint256 totalCakeBal = IBEP20(cakeToken).balanceOf(address(this));
        if(performFarm){
            uint256 pendingCake = _masterChef.pendingCake(pid, address(this));
            totalCakeBal = totalCakeBal.add(pendingCake);
        }
        
        uint256 farmTokenBalance = 0;
        if(cakeToken != farmToken){
            farmTokenBalance = IBEP20(farmToken).balanceOf(address(this));
        }
        
        farmtoBNBEstAmount = 0;
        caketoBNBEstAmount = 0;
        
        if(farmTokenBalance > 0){
            (uint reserveA,  uint reserveB) = PancakeLibrary.getReserves(pancakeSwapRouter.factory(), farmToken, pancakeSwapRouter.WETH());
            farmtoBNBEstAmount = PancakeLibrary.quote(farmTokenBalance, reserveA, reserveB);
        }
        if(totalCakeBal > 0){
            (uint cakereserveA,  uint cakereserveB) = PancakeLibrary.getReserves(pancakeSwapRouter.factory(), cakeToken, pancakeSwapRouter.WETH());
            caketoBNBEstAmount = PancakeLibrary.quote(totalCakeBal, cakereserveA, cakereserveB);
        }
    
        return (farmtoBNBEstAmount, caketoBNBEstAmount);
    }
    
    function _handleFeeTransfer(
        uint swapOutput
        ) internal returns (uint finalSwapOutput){
        
        uint platformUnit = swapOutput.mul(xwinProtocol.getPlatformFee()).div(10000);
        
        if(platformUnit > 0){
            TransferHelper.safeTransferBNB(xwinProtocol.getPlatformAddress(), platformUnit);
        }
        
        uint managerUnit = swapOutput.mul(managerFeeBps).div(10000);
        
        if(managerUnit > 0){
            TransferHelper.safeTransferBNB(managerOwner, managerUnit);
        }
        
        finalSwapOutput = swapOutput.sub(platformUnit).sub(managerUnit);
        
        return (finalSwapOutput);

    }
    
    /// @dev manager perform remove from farm. Allow for user to claim LP token in emergency
    function emergencyRemoveFromFarm() external onlyxWinProtocol {
        
        (uint256 lpTokenBalance, ) = _readUserInfo();
        _masterChef.withdraw(pid, lpTokenBalance);
        performFarm = false;
    }
    
    /// @dev Allow for user to claim LP token in emergency
    function emergencyRedeem(uint256 redeemUnit, address _investorAddress) external onlyxWinProtocol payable {
        
        uint256 redeemratio = redeemUnit.mul(1e18).div(totalSupply());
        require(redeemratio > 0, "redeem ratio is zero");
        _burn(msg.sender, redeemUnit);
        address pair = PancakeLibrary.pairFor(pancakeSwapRouter.factory(), farmToken, pancakeSwapRouter.WETH());
        uint256 lpTokenBalance = IBEP20(pair).balanceOf(address(this));
        uint256 totalOutput = redeemratio.mul(lpTokenBalance).div(1e18);
        TransferHelper.safeTransfer(pair, _investorAddress, totalOutput);
    }
}
