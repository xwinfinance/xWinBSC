pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later

import "./Interface/xWinFundInterface.sol";
import "./Library/xWinLibrary.sol";
import "./Interface/xWinStakeInterface.sol";
import "./Library/utils/TransferHelper.sol";
import "./Library/utils/ReentrancyGuard.sol";
import "./Library/access/Ownable.sol";
import "./Library/token/SafeBEP20.sol";


contract xWinDefi is Ownable, ReentrancyGuard {
    
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;


    string public name;
    address public xWinToken;
    address private platformWallet;
    address public xwinBenefitPool;
    address private deployeraddress;
    address private stakeAddress;
    uint256 private platformFeeBps;
    uint256 public startblock;
    bool public emergencyOn = false;
    mapping (uint256 => mapping (address => xWinLib.UserInfo)) public userInfo;
    mapping(address => bool) public isxwinFund;
    xWinLib.PoolInfo[] public poolInfo;
    
    mapping(address => xWinLib.xWinReward) public xWinRewards;
    mapping(address => xWinLib.xWinReferral) public xWinReferral;
    uint256 private rewardperuint = 95129375951;
    uint256 private referralperunit = 100000000000000000;
    uint256 private managerRewardperunit = 50000000000000000;
    uint256 public rewardRemaining = 60000000000000000000000000;
    
    event Received(address, uint);

    event _MoveNonIndexNameToBaseEvent(address indexed from, address indexed toFund, address tokenAddress, uint256 amount, uint swapOutput);
    event _RebalanceAllInOne(address indexed from, address indexed toFund, uint256 baseBalance, uint txnTime);
    event _Subscribe(address indexed from, address indexed toFund, uint256 subsAmt, uint256 mintQty);
    event _Redeem(address indexed from, address indexed toFund, uint256 redeemUnit, uint256 rewardQty, uint256 redeemratio);
    event _CreateTarget(address indexed from, address indexed toFund, address[] newTargets, uint256[] newWeight, uint txnTime);
    event _StakeMyReward(address indexed from, uint256 rewardQty);
    event _WithdrawReward(address indexed from, uint256 rewardQty);
    event _DepositFarm(address indexed from, uint256 pid, uint256 amount);
    event _WithdrawFarm(address indexed from, uint256 pid, uint256 amount);
    event _EmergencyRedeem(address indexed user, address fundaddress, uint256 amount);
    
    modifier onlyEmergency {
        require(emergencyOn == true, "only emergency can call this");
        _;
    }
    
    modifier onlyNonEmergency {
        require(emergencyOn == false, "only non-emergency can call this");
        _;
    }
    
    constructor (
            uint256 _platformFeeBps,
            address _platformWallet,
            address _xwinBenefitPool,
            address _stakeAddress,
            address _xWinToken
        ) public {
        
        name = "xWinDefi Protocol";
        platformWallet = _platformWallet;
        xwinBenefitPool = _xwinBenefitPool;
        platformFeeBps = _platformFeeBps;
        deployeraddress = msg.sender;
        startblock = block.number;
        stakeAddress = _stakeAddress;
        xWinToken = _xWinToken;
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    function addxwinFund(address[] calldata _fundaddress, bool [] memory _isxwinFund) public onlyOwner {
        
        for (uint i = 0; i < _fundaddress.length; i++) {
            isxwinFund[_fundaddress[i]] = _isxwinFund[i];
        }
    }
    
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    
    // Add a new lp to the pool. Can only be called by the owner.
    // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(address _lpToken, uint256 _rewardperblock, uint256 _multiplier) public onlyOwner onlyNonEmergency {
        
        poolInfo.push(xWinLib.PoolInfo({
            lpToken: _lpToken,
            rewardperblock : _rewardperblock,
            multiplier : _multiplier
        }));
    }
    
    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public onlyEmergency {
        
        xWinLib.PoolInfo memory pool = poolInfo[_pid];
        xWinLib.UserInfo storage user = userInfo[_pid][msg.sender];
        TransferHelper.safeTransfer(pool.lpToken, msg.sender, user.amount);
        user.amount = 0;
        user.blockstart = 0;
    }
    
    /// @dev reward per block by deployer
    function updateRewardPerBlock(uint256 _rewardperblock) external onlyOwner {
        rewardperuint = _rewardperblock;
    }
    
    /// @dev turn on emerrgency state by deployer
    function updateEmergencyState(bool _state) external onlyOwner {
        emergencyOn = _state;
    }
    
    /// @dev update xwin defi protocol
    function updateProtocol(address _fundaddress, address _newProtocol) external onlyOwner {
        xWinFund _xWinFund = xWinFund(_fundaddress);
        _xWinFund.updateProtocol(_newProtocol);
    }
    
     /// @dev create or update farm pool fee by deployer
    function updateFarmPoolInfo(uint256 _pid, uint256 _rewardperblock, uint256 _multiplier) external onlyOwner {
        
        xWinLib.PoolInfo storage pool = poolInfo[_pid];
        if(pool.lpToken != address(0)){
            pool.rewardperblock = _rewardperblock;
            pool.multiplier = _multiplier;
        }
    }
    
    /// @dev View function to see all pending xWin token earn on frontend.
    function getAllPendingXwin(address _user) public view returns (uint256) {
        
        uint256 length = poolInfo.length;
        uint256 total = 0;
        for (uint256 pid = 0; pid < length; ++pid) {
            total = total.add(pendingXwin(pid, _user));
        }
        return total;
    }
    
    /// @dev View function to see pending xWin on frontend.
    function pendingXwin(uint256 _pid, address _user) public view returns (uint256) {
        
        if(rewardRemaining == 0) return 0;
        xWinLib.PoolInfo memory pool = poolInfo[_pid];
        xWinLib.UserInfo memory user = userInfo[_pid][_user];
        uint blockdiff = block.number.sub(user.blockstart);
        uint256 currentRealizedQty = pool.multiplier.mul(pool.rewardperblock).mul(blockdiff).mul(user.amount).div(1e18).div(100);
        return currentRealizedQty;
    }
    
    /// @dev Deposit LP tokens to xWin Protocol for xWin allocation.
    function DepositFarm(uint256 _pid, uint256 _amount) public nonReentrant onlyNonEmergency {

        xWinLib.PoolInfo memory pool = poolInfo[_pid];
        require(pool.lpToken != address(0), "No pool found");
        xWinLib.UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.amount > 0) {
            uint256 pending = pendingXwin(_pid, msg.sender);
            _sendRewards(msg.sender, pending);
        }
        if (_amount > 0) {
            TransferHelper.safeTransferFrom(pool.lpToken, msg.sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.blockstart = block.number;
        emit _DepositFarm(msg.sender, _pid, _amount);
    }
    
    /// @dev Withdraw LP tokens from xWin Protocol.
    function WithdrawFarm(uint256 _pid, uint256 _amount) public nonReentrant onlyNonEmergency {

        xWinLib.PoolInfo memory pool = poolInfo[_pid];
        xWinLib.UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        uint256 pending = pendingXwin(_pid, msg.sender);
        if(pending > 0) _sendRewards(msg.sender, pending);
        
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            TransferHelper.safeTransfer(pool.lpToken, msg.sender, _amount);
        }
        user.blockstart = block.number;
        emit _WithdrawFarm(msg.sender, _pid, _amount);
    }
    
   
    /// @dev perform subscription based on ratio setup and put into lending if available 
    function Subscribe(xWinLib.TradeParams memory _tradeParams) public nonReentrant onlyNonEmergency payable {
        
        require(isxwinFund[_tradeParams.xFundAddress] == true, "not xwin fund");
        xWinLib.xWinReferral memory _xWinReferral = xWinReferral[msg.sender];
        require(msg.sender != _tradeParams.referral, "referal cannot be own address");
        
        if(_xWinReferral.referral != address(0)){
            require(_xWinReferral.referral == _tradeParams.referral, "already had referral");
        }
        xWinFund _xWinFund = xWinFund(_tradeParams.xFundAddress);
        TransferHelper.safeTransferBNB(_tradeParams.xFundAddress, _tradeParams.amount);
        uint256 mintQty = _xWinFund.Subscribe(_tradeParams, msg.sender);
        
        if(rewardRemaining > 0){
            _storeRewardQty(msg.sender, _tradeParams.amount, mintQty);
            _updateReferralReward(_tradeParams, _xWinFund.getWhoIsManager());
        }
        emit _Subscribe(msg.sender, _tradeParams.xFundAddress, _tradeParams.amount, mintQty);
    }
    
    /// @dev perform redemption based on unit redeem
    function Redeem(xWinLib.TradeParams memory _tradeParams) external nonReentrant onlyNonEmergency payable {
        
        require(IBEP20(_tradeParams.xFundAddress).balanceOf(msg.sender) >= _tradeParams.amount, "Not enough balance to redeem");
        require(isxwinFund[_tradeParams.xFundAddress] == true, "not xwin fund");
        TransferHelper.safeTransferFrom(_tradeParams.xFundAddress, msg.sender, address(this), _tradeParams.amount);
        xWinFund _xWinFund = xWinFund(_tradeParams.xFundAddress);
        uint256 redeemratio = _xWinFund.Redeem(_tradeParams, msg.sender);
        uint256 rewardQty = _updateRewardBal(msg.sender, _tradeParams.amount);
        emit _Redeem(msg.sender, _tradeParams.xFundAddress, _tradeParams.amount, rewardQty, redeemratio);
    }
    
    /// @dev perform redemption based on unit redeem and give up all xwin rewards
    function emergencyRedeem(uint256 _redeemAmount, address _fundaddress) external nonReentrant onlyEmergency payable {
        
        require(IBEP20(_fundaddress).balanceOf(msg.sender) >= _redeemAmount, "Not enough balance to redeem");
        TransferHelper.safeTransferFrom(_fundaddress, msg.sender, address(this), _redeemAmount);
        xWinFund _xWinFund = xWinFund(_fundaddress);
        _xWinFund.emergencyRedeem(_redeemAmount, msg.sender);
        _resetRewards(msg.sender);
        emit _EmergencyRedeem(msg.sender, _fundaddress, _redeemAmount);
    }
    
    /// @dev manager perform remove from farm for emergency state
    function emergencyRemoveFromFarm(address _fundaddress) external nonReentrant onlyEmergency payable {
        
        xWinFund _xWinFund = xWinFund(_fundaddress);
        require(msg.sender == _xWinFund.getWhoIsManager(), "not the manager to move from farm");
        _xWinFund.emergencyRemoveFromFarm();
    }
    
    /// @dev perform MoveNonIndexNameTo BNB for non benchmark name
    function MoveNonIndexNameToBase(
        address xFundAddress,
        address _tokenaddress,
        uint256 deadline,
        uint256 priceImpactTolerance
        ) external nonReentrant payable {
        
        xWinFund _xWinFund = xWinFund(xFundAddress);
        require(msg.sender == _xWinFund.getWhoIsManager(), "not the manager to move the balance");
         (uint256 balanceToken, uint256 swapOutput) = _xWinFund.MoveNonIndexNameToBase(_tokenaddress, deadline, priceImpactTolerance);
        emit _MoveNonIndexNameToBaseEvent(msg.sender, xFundAddress, _tokenaddress, balanceToken, swapOutput);
    }
    
    /// @dev create target ratio by portfolio manager
    function CreateTarget(
        address[] calldata _toAddresses, 
        uint256[] calldata _targetWeight,
        address xFundAddress 
        ) external nonReentrant onlyNonEmergency {
        
        xWinFund _xWinFund = xWinFund(xFundAddress);
        require(msg.sender == _xWinFund.getWhoIsManager(), "only owner of the fund is allowed");
        _xWinFund.CreateTargetNames(_toAddresses, _targetWeight);
        emit _CreateTarget(msg.sender, xFundAddress, _toAddresses, _targetWeight, block.timestamp);
    }
    
    /// @dev perform update target, move non-bm to base and finally rebalance
    function RebalanceAllInOne(
        xWinLib.TradeParams memory _tradeParams,
        address[] calldata _toAddresses, 
        uint256[] calldata _targetWeight
        ) external nonReentrant onlyNonEmergency payable {
        
        xWinFund _xWinFund = xWinFund(_tradeParams.xFundAddress);
        require(msg.sender == _xWinFund.getWhoIsManager(), "only owner of the fund is allowed");
        
        uint256 baseccyBal = _xWinFund.Rebalance(_toAddresses, _targetWeight, _tradeParams.deadline, _tradeParams.priceImpactTolerance);
        emit _RebalanceAllInOne(msg.sender, _tradeParams.xFundAddress, baseccyBal, block.timestamp);
    }
    
    /// @dev update platform fee by deployer
    function updatePlatformFee(uint256 newPlatformFee) external onlyOwner {
        platformFeeBps = newPlatformFee;
    }
    
    /// @dev get platform fee
    function getPlatformFee() view external returns (uint256) {
        return platformFeeBps;
    }
    
    /// @dev get platform wallet address
    function getPlatformAddress() view external returns (address) {
        return platformWallet;
    }
    
    /// @dev get platform wallet address
    function gexWinBenefitPool() view external returns (address) {
        return xwinBenefitPool;
    }
    
    /// @dev update platform fee by deployer
    function updateXwinBenefitPool(address _xwinBenefitPool) external onlyOwner {
        xwinBenefitPool = _xwinBenefitPool;
    }
    
    /// @dev update rewardRemaining by deployer
    function updateRewardRemaining(uint256 _newRemaining) external onlyOwner {
        rewardRemaining = _newRemaining;
    }
    
    /// @dev update platform fee by deployer
    function updateStakeProtocol(address newStakeProtocol) external onlyOwner {
        stakeAddress = newStakeProtocol;
    }
    
    /// @dev update referal fee by deployer
    function updateReferralRewardPerUnit(uint256 _referralperunit) external onlyOwner {
        referralperunit = _referralperunit;
    }

    /// @dev update manager reward by deployer
    function updateManagerRewardPerUnit(uint256 _managerRewardperunit) external onlyOwner {
        managerRewardperunit = _managerRewardperunit;
    }
    
    function _multiplier(uint256 _blockstart) internal view returns (uint256) {
        
        if(_blockstart == 0) return 0;
        uint256 blockdiff = _blockstart.sub(startblock); 
        if(blockdiff < 5256000) return 50000; //first 6 months, 5x
        if(blockdiff >= 5256000 && blockdiff <= 10512000) return 25000; //then following 6 months 
        if(blockdiff >= 10512000 && blockdiff <= 15768000) return 12500; //then following 6 months
        if(blockdiff > 15768000) return 10000;
    }
    
    /// @dev get estimated reward of XWN token
    function GetEstimateReward(address fromAddress) public view returns (uint256) {
        
        xWinLib.xWinReward memory _xwinReward =  xWinRewards[fromAddress];
        if(_xwinReward.blockstart == 0) return 0;
        uint blockdiff = block.number.sub(_xwinReward.blockstart);
        uint256 currentRealizedQty = _multiplier(_xwinReward.blockstart).mul(rewardperuint).mul(blockdiff).mul(_xwinReward.accBasetoken).div(1e18).div(10000); 
        uint256 allRealizedQty = currentRealizedQty.add(_xwinReward.previousRealizedQty);
        return  (rewardRemaining >= allRealizedQty) ? allRealizedQty: rewardRemaining;
    }
    
    function GetQuotes(
        uint tokenBal,
        address targetToken
        ) external view returns (uint amountB, uint amountA) {
        xWinStake _xWinStake = xWinStake(stakeAddress);
        (amountB, amountA, ) = _xWinStake.GetQuotes(tokenBal, 1e18, targetToken);
        return (amountB, amountA);
    }   
    
    /// @dev User to claim the reward and stake them into DEX
    function StakeMyReward(
        uint256 deadline 
        ) external nonReentrant onlyNonEmergency payable {
        
        //only token owner are allowed
        xWinLib.xWinReward storage _xwinReward =  xWinRewards[msg.sender];
        uint256 rewardQty = GetEstimateReward(msg.sender);
        require(rewardQty > 0, "No reward to claim");
        
        _xwinReward.previousRealizedQty = 0;
        _xwinReward.blockstart = block.number;
        
        xWinStake _xWinStake = xWinStake(stakeAddress);
        TransferHelper.safeTransferBNB(stakeAddress, msg.value); 
        
        _sendRewards(stakeAddress, rewardQty);

        _xWinStake.StakeReward(msg.sender, rewardQty, msg.value, deadline);
        emit _StakeMyReward(msg.sender, rewardQty);
    }
    
    function _updateReferralReward(xWinLib.TradeParams memory _tradeParams, address _managerAddress) internal {
        
        xWinLib.xWinReferral storage _xWinReferral = xWinReferral[msg.sender];
        if(_xWinReferral.referral == address(0)){
            _xWinReferral.referral = _tradeParams.referral; //store referal address
        }
        xWinLib.xWinReward storage _xwinReward =  xWinRewards[_xWinReferral.referral];
        
        if(_xwinReward.accBasetoken > 0){
            uint256 entitleAmt = _tradeParams.amount.mul(referralperunit).div(1e18);  //0.10
            _xwinReward.previousRealizedQty = _xwinReward.previousRealizedQty.add(entitleAmt);
        } 

        xWinLib.xWinReward storage _xwinRewardManager =  xWinRewards[_managerAddress];
        if(_xwinRewardManager.blockstart == 0){
            _xwinRewardManager.blockstart = block.number;
        }
        uint256 entitleAmtManager = _tradeParams.amount.mul(managerRewardperunit).div(1e18); //manager get 0.05
        _xwinRewardManager.previousRealizedQty = _xwinRewardManager.previousRealizedQty.add(entitleAmtManager);
    }
    
    /// @dev withdraw reward of XWN token
    function WithdrawReward() external nonReentrant onlyNonEmergency payable {
        
        xWinLib.xWinReward storage _xwinReward =  xWinRewards[msg.sender];
        uint256 rewardQty = GetEstimateReward(msg.sender);
        require(rewardQty > 0, "No reward");
        
        _xwinReward.previousRealizedQty = 0;
        _xwinReward.blockstart = block.number;
        
        uint amountWithdraw = (rewardRemaining >= rewardQty) ? rewardQty: rewardRemaining;
        
        if(amountWithdraw > 0) _sendRewards(msg.sender, amountWithdraw);
        emit _WithdrawReward(msg.sender, amountWithdraw);
    }
    
    function _storeRewardQty(address from, uint256 baseQty, uint256 mintQty) internal {

        xWinLib.xWinReward storage _xwinReward =  xWinRewards[from];
        if(_xwinReward.blockstart == 0){
            _xwinReward.blockstart = block.number;
            _xwinReward.accBasetoken = baseQty;
            _xwinReward.accMinttoken = mintQty;
            _xwinReward.previousRealizedQty = 0;
        }else{
            
            uint blockdiff = block.number.sub(_xwinReward.blockstart);
            uint256 currentRealizedQty = _multiplier(_xwinReward.blockstart).mul(rewardperuint).mul(blockdiff).mul(_xwinReward.accBasetoken).div(1e18).div(10000); 
            _xwinReward.blockstart = block.number;
            _xwinReward.accBasetoken = baseQty.add(_xwinReward.accBasetoken);
            _xwinReward.accMinttoken = mintQty.add(_xwinReward.accMinttoken);
            _xwinReward.previousRealizedQty = _xwinReward.previousRealizedQty.add(currentRealizedQty);
        }
    }
    
    function _updateRewardBal(address from, uint256 redeemUnit) internal returns (uint256 rewardQty){

        if(rewardRemaining == 0) return 0;
        xWinLib.xWinReward storage _xwinReward =  xWinRewards[from];
        rewardQty = GetEstimateReward(from);
        
        if(_xwinReward.accMinttoken == 0) return 0;
        if(rewardQty == 0) return 0;
        
        if(_xwinReward.accMinttoken >= redeemUnit){
            uint256 ratio = redeemUnit.mul(1e8).div(_xwinReward.accMinttoken);
            uint256 reducedBal = _xwinReward.accBasetoken.mul(ratio).div(1e8);
            _xwinReward.accBasetoken = _xwinReward.accBasetoken.sub(reducedBal);    
            _xwinReward.accMinttoken = _xwinReward.accMinttoken.sub(redeemUnit);
        }else{
            _xwinReward.accMinttoken = 0;
            _xwinReward.accBasetoken = 0;
        }
        _xwinReward.previousRealizedQty = 0;
        _xwinReward.blockstart = block.number;
        
        _sendRewards(msg.sender, rewardQty);
        return rewardQty;
    }
    
    /// @dev emergency trf XWN token to new protocol
    function ProtocolTransfer(address _newProtocol, uint256 amount) public onlyOwner onlyEmergency payable {
        TransferHelper.safeTransfer(xWinToken, _newProtocol, amount);
    }
    
    function _sendRewards(address _to, uint256 amount) internal {
        
        if(rewardRemaining == 0) return;
        uint256 xwinTokenBal = IBEP20(xWinToken).balanceOf(address(this));
        if(xwinTokenBal == 0) return;
        
        if(rewardRemaining >= amount && xwinTokenBal >= amount){
            TransferHelper.safeTransfer(xWinToken, _to, amount);
            rewardRemaining = rewardRemaining.sub(amount);
        }else{
            uint amountTosend = (xwinTokenBal >= amount) ? amount: xwinTokenBal;
            TransferHelper.safeTransfer(xWinToken, _to, amountTosend);
            rewardRemaining = 0; //mark reward ended
        }
    }
    
    function _resetRewards(address _from) internal {
        xWinLib.xWinReward storage _xwinReward =  xWinRewards[_from];
        _xwinReward.accMinttoken = 0;
        _xwinReward.accBasetoken = 0;
        _xwinReward.previousRealizedQty = 0;
        _xwinReward.blockstart = block.number;
    }
}
