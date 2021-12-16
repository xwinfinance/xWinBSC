pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later

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

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
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

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

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

contract xWinDefi  {
    
    struct PoolInfo {
        address lpToken;           
        uint256 rewardperblock;       
        uint256 multiplier;       
    }
    function DepositFarm(uint256 _pid, uint256 _amount) public {}
    function pendingXwin(uint256 _pid, address _user) public view returns (uint256) {}
    function WithdrawFarm(uint256 _pid, uint256 _amount) public {}
    
    PoolInfo[] public poolInfo;
}


/*
Restaurant Sushi X:
------------------------
1. User A deposit xwin token (1000) into "smart contract".
2. Smart contract belongs to restaurant owner X
2. Restaurant X owner, retrieve or own 1000 xwin token
3. Once 1000 xwin is deposited into smart contract, automatically stake 1000 xwin token into xwin farming.
4. From smart contract, it allows restaurant owner to 
	a. Harvest XWIN interest
	b. Withdraw XWIN from smart contract

## multiple charities can be held

Method:

Keep charity events information
	a. Charity Name
	b. Charity Date
	c. Charity total

1. User A donate function (Open for multiple users for the donation)

	a. During donation, accept XWIN token. Parameter accept: charityId
	b. deposit farming in xwin protocol

2. Restaurant owner: Withdraw (Only registered restaurant owner wallet can perform withdraw)

3. Restaurant owner: Harvest (Only registered restaurant owner wallet can perform withdraw)
*/

contract xWinCharity is ReentrancyGuard, Ownable {
    
    using SafeMath for uint256;

    modifier onlyCharityOwner() {
        require(charityOwnerWallet == _msgSender(), "caller is not the charity owner");
        _;
    }
    
    struct CharityInfo {
        string name;
        uint startblock;
        uint daysToDue;
        uint dueBlock;
        uint tergetAmount;
        uint donatedTotal;
        uint stakedTotal;
    }
    
    string public name;
    uint public burnFee = 500;      // 5%
    CharityInfo[] public charityInfo;
    uint charityId = 0;

    uint public totalStakedAmount;
    uint public totalHavestAmount;    
    //address public xwin = address(0xd88ca08d8eec1E9E09562213Ae83A7853ebB5d28);
    address public xwin = address(0xa83575490D7df4E2F47b7D38ef351a2722cA45b9);

    address public charityOwnerWallet; 
    address public managerWallet; 
    address public platformWallet;
    address public burnAddress = address(0x000000000000000000000000000000000000dEaD);
    
    //xWinDefi _xWinDefi = xWinDefi(address(0x1Bf7fe7568211ecfF68B6bC7CCAd31eCd8fe8092));
    // main net
    //xWinDefi _xWinDefi = xWinDefi(address(0x21B323a2Ac030095A7f9509B3b53f52367B76D94));
    //test net
    xWinDefi _xWinDefi = xWinDefi(address(0xebAee150352ba99FcA309C9D57E14DC77736470e));
    uint public xwinpid = 0;
    uint public maturityBlock;
	uint public blocksOfADay = 28800;

    
    event Received(address, uint);
    event _StakeToken(address indexed from, uint256 pid, uint256 depositAmt, uint256 finalDeposit);
    event _harvestXWIN(address indexed from, uint256 balanceXWIN);
    event _Donate(address indexed from, uint256 charityId, uint256 amount);

    constructor (
            string memory _name,
            address _charityOwnerWallet
        ) public {
            name = _name;
            charityOwnerWallet = _charityOwnerWallet;
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    function addCharity(
        string calldata _name,
        uint _daysToDue,
        uint _tergetAmount
        ) external onlyCharityOwner {
            uint blocks = block.number.add(blocksOfADay.mul(_daysToDue));
            charityInfo.push(CharityInfo({
                name : _name,
                startblock : block.number,
                daysToDue : _daysToDue,
                dueBlock : blocks,
                tergetAmount : _tergetAmount,
                donatedTotal : 0,
                stakedTotal : 0
            }));
            charityId += 1;
    }

    
    function donate(uint _charityId, uint _amount) external nonReentrant {
        require(charityInfo[_charityId].dueBlock >= block.number,"Expired Charity");
        require(IBEP20(xwin).balanceOf(msg.sender) >= _amount, "Not enough xWin balance");

        TransferHelper.safeTransferFrom(xwin, msg.sender, address(this), _amount);

        uint burnAmount = _amount.mul(burnFee).div(10000);
        uint stakeAmount = _amount.sub(burnAmount);
        TransferHelper.safeTransfer(xwin, burnAddress, burnAmount); 

        CharityInfo storage charity = charityInfo[_charityId];
        charity.donatedTotal = charity.donatedTotal.add(_amount);
        charity.stakedTotal = charity.stakedTotal.add(stakeAmount);
        totalStakedAmount = totalStakedAmount.add(stakeAmount);
        _stakeToken(stakeAmount);
        emit _Donate(msg.sender,  _charityId,  _amount);
    }

    function withdrawByCharityOwner(uint _charityId, uint _amount) external onlyCharityOwner {
        require(charityInfo[_charityId].dueBlock <= block.number, "Earlier than the due date");
        require(charityInfo[_charityId].stakedTotal >= _amount, "More than staked");

        _unStakeToken(_amount);
        uint256 xwinBalance = IBEP20(xwin).balanceOf(address(this));
        TransferHelper.safeTransfer(xwin, charityOwnerWallet, xwinBalance);
        CharityInfo storage charity = charityInfo[_charityId];
        charity.stakedTotal = charity.stakedTotal.sub(_amount);
    }
    
    function harvestByCharityOwner() external onlyCharityOwner {
        _xWinDefi.DepositFarm(xwinpid, 0);
        uint256 xwinBalance = IBEP20(xwin).balanceOf(address(this));
        TransferHelper.safeTransfer(xwin, charityOwnerWallet, xwinBalance);
        totalHavestAmount = totalHavestAmount.add(xwinBalance);
        emit _harvestXWIN(charityOwnerWallet, xwinBalance);
    }
    
    function getXWINRewards(uint _pid) public view returns (uint) {
        
        uint xwinBalance = IBEP20(xwin).balanceOf(address(this));
        uint pending = _xWinDefi.pendingXwin(_pid, address(this));
        return xwinBalance.add(pending); 
    }
    
    function updateProperty(uint _burnFee, uint _xwinpid) public onlyOwner {
        burnFee = _burnFee;
        xwinpid = _xwinpid;
    }

    //allow admin to move unncessary token inside the contract
    function adminMoveToken(address _tokenAddress) public onlyOwner {
        uint256 tokenBal = IBEP20(_tokenAddress).balanceOf(address(this));
        TransferHelper.safeTransfer(_tokenAddress, msg.sender, tokenBal); 
    }
    
    function getNumberOfCharities() public view returns (uint) {
        return charityInfo.length;
    }
    
    /// @dev user to stake token 
	/// User deposits xWin to this contract. then that the xWin will be automatically staked
	/// Proc: 
	///   user buys this token by xWin(Deposit xWin)
	///   

    /// changes 
    /// external -> internal
    //function stakeToken(uint _pid, uint _amount) internal nonReentrant {
    function _stakeToken(uint _amount) internal {
        require(IBEP20(xwin).balanceOf(address(this)) >= _amount, "Not enough balance");
        TransferHelper.safeApprove(address(xwin), address(_xWinDefi), _amount);
        _xWinDefi.DepositFarm(xwinpid, _amount);
    }
    
    /// @dev user to unstake token 
    function _unStakeToken(uint _amount) internal {
        _xWinDefi.WithdrawFarm(xwinpid, _amount); //withdraw xwin farming 
        //emit _UnStakeToken(address(this), _amount);
    }
}