pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later

import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}


contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    /*function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }*/

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract xWinDefi  {
    
    struct UserInfo {
        uint256 amount;     
        uint256 blockstart; 
    }
    function DepositFarm(uint256 _pid, uint256 _amount) public {}
    function pendingXwin(uint256 _pid, address _user) public view returns (uint256) {}
    function WithdrawFarm(uint256 _pid, uint256 _amount) public {}
    
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
}

contract xWinLuckyWinner is VRFConsumerBase, ReentrancyGuard, IBEP20, BEP20("Lucky Draw", "LUCKY") {
    
    //using SafeMath for uint256;
    
    // Info of each pool.
    struct PoolInfo {
        uint count;
        uint totalTobeWon;
        uint drawDateTime;
    }
    
    struct UserInfo {
        uint userid;
        bool registered;
        address userAddress;
        uint lpTokenStakedAmount;
        uint xWINTokenStakedAmount;
    }
    
    struct WinnerInfo {
        uint totalWonBalance;
        uint poolID;
        uint receivedBalance;
    }
    
    PoolInfo[] public poolInfo;
    address[] public userAddressArray;
    mapping (address => UserInfo) public userInfo;
    mapping (uint256 => mapping (address => WinnerInfo)) public winnerUser;
    
    uint public burnFee = 1000; 
    uint public activePool = 0; 
    uint public minimalBalanceLP = 5 * 10 ** 18; 
    uint public minimalBalanceXWIN = 400 * 10 ** 18; 
    uint public luckypid = 0;
    uint public lppid = 34;
    uint public xWINpid = 0;
    uint public numberOfPrizes = 3;
    uint256[] public randomValues;
    mapping (uint256 => uint256[]) public luckyValues;
    
    
    bytes32 internal keyHash;
    uint256 internal fee;
    address public burnAddress = address(0x000000000000000000000000000000000000dEaD);
    address public executorAddress = address(0x1a65a8d3C3f9FE6175659f531f9F04E955a94Aed);
    
    address public targetToken = address(0xd88ca08d8eec1E9E09562213Ae83A7853ebB5d28);
    xWinDefi _xWinDefi = xWinDefi(address(0x1Bf7fe7568211ecfF68B6bC7CCAd31eCd8fe8092)); // this is prod
    address LINKaddress = address(0x404460C6A5EdE2D891e8297795264fDe62ADBB75);
    
    event Received(address, uint);
    event _ClaimPrizes(address indexed from, uint256 pid, uint256 prizeBalance);
    event _UnStakeToken(address indexed from, uint256 pid, uint256 totalReturnToUser);
    
    
    constructor() 
        VRFConsumerBase(
            0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31,
            LINKaddress  // LINK Token
        ) public
    {
        keyHash = 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c;
        fee = 0.2 * 10 ** 18; // 0.1 LINK for testnet (Varies by network)
        _mint(address(this), 10000 * 10 ** 18);
        _addNextPhase();
    }
    
    // update xwin protocol
    function updateProtocol(address xWinDefi_) public onlyOwner {
        _xWinDefi = xWinDefi(xWinDefi_);
    }
    
    // update executor
    function updateExecutor(address _executorAddress) public onlyOwner {
        executorAddress = _executorAddress;
    }
    
    // update xwin farming pool id
    function updateLuckyId(uint _luckypid) public onlyOwner {
        luckypid = _luckypid;
    }
    
    // update xwin LP and XWIN pool id in xWINDEFI
    function updateXWINLPId(uint _lppid, uint _xWINpid) public onlyOwner {
        lppid = _lppid;
        xWINpid = _xWINpid;
    }

    // update number of prize
    function updateNumberOfPrizes(uint _numberOfPrizes) public onlyOwner {
        numberOfPrizes = _numberOfPrizes;
    }
    
    // update minimal balance
    function updateMinimalBalance(uint _minimalBalanceLP, uint _minimalBalanceXWIN) public onlyOwner {
        minimalBalanceLP = _minimalBalanceLP;
        minimalBalanceXWIN = _minimalBalanceXWIN;
    }
    
    
    function farmTokenByAdmin() public onlyOwner {
        TransferHelper.safeApprove(address(this), address(_xWinDefi), totalSupply()); 
        _xWinDefi.DepositFarm(luckypid, totalSupply());
    } 

    function unFarmTokenByAdmin() public onlyOwner {
        _xWinDefi.WithdrawFarm(luckypid, totalSupply());
    }
    
    function addNextPhase() public onlyOwner {
        _addNextPhase();
    }

    function adminUpdateUser(address _user, bool _registered, uint _lpTokenStakedAmount, uint _xWINTokenStakedAmount) public onlyOwner {
        UserInfo storage user = userInfo[_user];
        user.registered = _registered;
        user.lpTokenStakedAmount = _lpTokenStakedAmount;
        user.xWINTokenStakedAmount = _xWINTokenStakedAmount;
    }

    function burn() public onlyOwner {
        _burn(address(this), totalSupply());
    } 

    function _harvest() internal {
        _xWinDefi.DepositFarm(luckypid, 0);
    }
    
    function getNextPrizesBalance() public view returns (uint) {
        
        return _xWinDefi.pendingXwin(luckypid, address(this));
    }
    
    function getNumberOfUsers() public view returns (uint) {
        return userAddressArray.length;
    }
    
    function claimPrizes(uint _pid) public nonReentrant {
        
        WinnerInfo storage winneruser_ = winnerUser[_pid][msg.sender];
        require(winneruser_.totalWonBalance > 0, "no prize");
        require(winneruser_.receivedBalance == 0, "already claimed prize");
        uint256 xwinBalance = IBEP20(targetToken).balanceOf(address(this));
        require(xwinBalance >= winneruser_.totalWonBalance, "not enough xwin. contact admin");
        uint burnFeeTotal = winneruser_.totalWonBalance * burnFee / 10000;
        uint remaining = winneruser_.totalWonBalance - burnFeeTotal;
        TransferHelper.safeTransfer(targetToken, burnAddress, burnFeeTotal); 
        TransferHelper.safeTransfer(targetToken, msg.sender, remaining);
        winneruser_.receivedBalance = winneruser_.totalWonBalance;
        emit _ClaimPrizes(msg.sender, _pid, winneruser_.totalWonBalance);
    }
    
    
    // it has to be admin
    function _addNextPhase() internal {
        
        poolInfo.push(PoolInfo({
            count : activePool,
            totalTobeWon : 0,
            drawDateTime : 0
        }));
    }

    function registerMe() public {
        
        UserInfo storage user = userInfo[msg.sender];
        require(user.registered == false, "already registered");
        (uint amountLP, ) = _xWinDefi.userInfo(lppid, msg.sender);
        (uint amountXWIN, ) = _xWinDefi.userInfo(xWINpid, msg.sender);
        
        if(amountLP >= minimalBalanceLP || amountXWIN >= minimalBalanceXWIN){
            userAddressArray.push(msg.sender);
            user.registered = true;
            user.userAddress = msg.sender;
            user.lpTokenStakedAmount = amountLP;
            user.xWINTokenStakedAmount = amountXWIN;
            user.userid = userAddressArray.length - 1;
        }else{
            revert("do not meet minimal balance");
        }
    }
    

    function start() public returns (bytes32 requestId) {
        
        require(msg.sender == executorAddress, "not allow to execute");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }
    
    
    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        
        _getWinners(randomness, numberOfPrizes);
        _harvest();
        activePool = activePool + 1;
        _addNextPhase();
    }
    
    function _getWinners(uint256 randomness, uint256 n) internal {
        
        uint totalPrize = getNextPrizesBalance();
        PoolInfo storage pool = poolInfo[activePool];
        pool.totalTobeWon = totalPrize;
        pool.drawDateTime = block.timestamp;
        randomValues = _expandGetRandom(randomness, n);
        luckyValues[activePool] = randomValues;
        uint winBal = totalPrize / n;
        for (uint256 i = 0; i < randomValues.length; i++) {
            UserInfo memory user = userInfo[userAddressArray[randomValues[i]]];
            (uint amountLP, ) = _xWinDefi.userInfo(lppid, user.userAddress);
            (uint amountXWIN, ) = _xWinDefi.userInfo(xWINpid, user.userAddress);
            if(amountLP >= minimalBalanceLP || amountXWIN >= minimalBalanceXWIN){
                WinnerInfo storage winneruser_ = winnerUser[activePool][user.userAddress];
                winneruser_.totalWonBalance = winneruser_.totalWonBalance + winBal;
                winneruser_.poolID = activePool;
            }
        }
    }
    
    function _expandGetRandom(uint256 randomValue, uint256 n) internal view returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = (uint256(keccak256(abi.encode(randomValue, i))) % userAddressArray.length);
        }
        return expandedValues;
    }
    
    //allow admin to move unncessary token inside the contract
    function withdrawLink(uint tokenBal) public onlyOwner {
        TransferHelper.safeTransfer(LINKaddress, msg.sender, tokenBal); 
    }
    
        //allow admin to move unncessary token inside the contract
    function withdrawXWIN(uint tokenBal) public onlyOwner {
        TransferHelper.safeTransfer(targetToken, msg.sender, tokenBal); 
    }
}
