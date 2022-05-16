/**
 *Submitted for verification at BscScan.com on 2021-03-26
*/

pragma solidity ^0.6.0;
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

contract AutoFarm  {
    
    function deposit(uint256 _pid, uint256 _wantAmt) public{}
    function withdraw(uint256 _pid, uint256 _wantAmt) public{}
    function withdrawAll(uint256 _pid) public {}
    function pendingAUTO(uint256 _pid, address _user)
        external
        view
        returns (uint256){}
        
    // View function to see staked Want tokens on frontend.
    function stakedWantTokens(uint256 _pid, address _user)
        external
        view
        returns (uint256){}
}

interface IPancakeRouter02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakePair {    
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

library PancakeLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(9975);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(9975);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
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

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
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

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
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

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
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

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    
    /*function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }*/

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
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

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
    }
    
    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract xWinDefi  {
    
    struct UserInfo {
        uint256 amount;     
        uint256 blockstart; 
    }
    struct PoolInfo {
        address lpToken;           
        uint256 rewardperblock;       
        uint256 multiplier;       
    }
    function DepositFarm(uint256 _pid, uint256 _amount) public {}
    function pendingXwin(uint256 _pid, address _user) public view returns (uint256) {}
    function WithdrawFarm(uint256 _pid, uint256 _amount) public {}
    
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    PoolInfo[] public poolInfo;
}


contract xWINPrivate is ReentrancyGuard, IBEP20, BEP20 {
    
    using SafeMath for uint256;

    // Info of each pool.
    struct PoolInfo {
        string name;
        uint totalLockedSupply;
        uint totalInterestPaid;
        uint totalXWINPaid;
    }
    
    struct UserInfo {
        uint amount; 
        uint lpTokenAmount;
        uint lpTokenStakedAmount;
        uint lastHarvest; 
    }
    
    uint public platformFeeOnProfit = 100; 
    bool public swapTokenB = true; 
    uint public slippage = 50; 
    uint public entryFee = 10; 
    uint public burnFee = 500; 
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    PoolInfo[] public poolInfo;
    address public tokenB = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address public tokenA = address(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47); 
    address public tokenABLP = address(0x28415ff2C35b65B9E5c7de82126b4015ab9d031F);
    address public xwin = address(0xd88ca08d8eec1E9E09562213Ae83A7853ebB5d28);
    address public investorWallet = address(0x5D450b7A2bAFbc071cF1313099C3744f91c3BC24);
    address public platformWallet = address(0x62691eF999C7F07BC1653416df0eC4f3CDDBb0c7);
    address public burnAddress = address(0x000000000000000000000000000000000000dEaD);
    
    AutoFarm public _autoFarm = AutoFarm(address(0x0895196562C7868C5Be92459FaE7f877ED450452));
    IPancakeRouter02 public pancakeSwapRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    xWinDefi public _xWinDefi = xWinDefi(address(0x1Bf7fe7568211ecfF68B6bC7CCAd31eCd8fe8092));
    
    
    uint public autopid = 621; 
    uint public xwinpid = 0;
    
    event Received(address, uint);
    event _StakeToken(address indexed from, uint256 pid, uint256 depositAmt, uint256 finalDeposit);
    event _UnStakeToken(address indexed from, uint256 pid, uint256 totalReturnToUser);
    event _harvestXWIN(address indexed from, uint256 balanceXWIN);
    

    constructor (
            string memory name,
            string memory symbol            
        ) public BEP20(name, symbol) {}
        
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    

    function getXWINRewards(uint _pid) public view returns (uint) {
        
        uint xwinBalance = IBEP20(xwin).balanceOf(address(this));
        uint pending = _xWinDefi.pendingXwin(_pid, address(this));
        return xwinBalance.add(pending); 
    }
    
    function updateRouter(
        address pancakeSwapRouter_,
        address autoFarm_,
        address xWinDefi_
        ) public onlyOwner {
        pancakeSwapRouter = IPancakeRouter02(pancakeSwapRouter_);
        _autoFarm = AutoFarm(autoFarm_);
        _xWinDefi = xWinDefi(xWinDefi_);
    }

    // update xwin farming pool id
    function updateXWINid(uint _xwinpid) public onlyOwner {
        xwinpid = _xwinpid;
    }
    
    function updateSlippage(uint _slippage) public onlyOwner {
        slippage = _slippage;
    }

    function updateFee(uint _burnFee, uint _entryFee, uint _platformFeeOnProfit) public onlyOwner {
        burnFee = _burnFee;
        entryFee = _entryFee;
        platformFeeOnProfit = _platformFeeOnProfit;
    }

    function updateInvestorWallet(address _investorWallet) public onlyOwner {
        investorWallet = _investorWallet;
    }

    function updateplatformWallet(address _platformWallet) public onlyOwner {
        platformWallet = _platformWallet;
    }
    
    //allow admin to move unncessary token inside the contract
    function adminMoveToken(address _tokenAddress) public onlyOwner {
        uint256 tokenBal = IBEP20(_tokenAddress).balanceOf(address(this));
        TransferHelper.safeTransfer(_tokenAddress, msg.sender, tokenBal); 
    }
    
    //allow admin to unfarmed from autofarm
    function adminEmergencyRemoveAutoFarm() public onlyOwner {
        
        uint stakedBal = getTotalStakedBalance();
        _autoFarm.withdraw(autopid, stakedBal);
    }
    
    function getTotalStakedBalance() public view returns (uint){
        return _autoFarm.stakedWantTokens(autopid, address(this));
    }

    function getOwnershipStakeAmount(uint _userBalance) public view returns (uint){
        
        uint256 redeemratio = _userBalance.mul(1e18).div(totalSupply());
        uint totalAutoStake = getTotalStakedBalance();
        uint withdrawAmt = redeemratio.mul(totalAutoStake).div(1e18);
        withdrawAmt = totalAutoStake < withdrawAmt ? totalAutoStake: withdrawAmt;
        return withdrawAmt;
    }
    
    function add(
        string memory _name
        ) public onlyOwner {
        
        poolInfo.push(PoolInfo({
            name : _name,
            totalLockedSupply : 0,
            totalInterestPaid : 0,
            totalXWINPaid : 0
        }));
    }
    
    function _swapTokenToETH(uint amountIn) 
        internal returns (uint) {
            
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = pancakeSwapRouter.WETH();

        TransferHelper.safeApprove(tokenA, address(pancakeSwapRouter), amountIn); 
        uint256[] memory amounts = pancakeSwapRouter.getAmountsOut(amountIn, path);
        uint256 amountOut = amounts[amounts.length.sub(1)];
        uint[] memory amountOutput = pancakeSwapRouter.swapExactTokensForETH(amountIn, amountOut.sub(amountOut.mul(slippage).div(10000)), path, address(this), block.timestamp);
		
        return amountOutput[amountOutput.length - 1];
    }

    function _swapETHToToken() 
        internal returns (uint) {

        uint bnbBal = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = pancakeSwapRouter.WETH();
        path[1] = tokenA;

        uint256[] memory amounts = pancakeSwapRouter.getAmountsOut(bnbBal, path);
        uint256 amountOut = amounts[amounts.length-1];
        pancakeSwapRouter.swapExactETHForTokens{value: bnbBal}(
            amountOut.sub((amountOut.mul(slippage).div(10000))), 
            path, 
            address(this), 
            block.timestamp
        );                
    }
    
    
    function getBeforeAfterStakedLPAmount(uint _pid) public view 
        returns (uint currentBalance, uint origBalance, uint dailyRate, uint blockDiff) {
        
        UserInfo memory user = userInfo[_pid][msg.sender];
        if(user.amount == 0) return (0,0,0,0);
        currentBalance = getTotalStakedBalance();
        dailyRate = currentBalance == user.lpTokenStakedAmount ? 0 : currentBalance.mul(1e18).div(user.lpTokenStakedAmount).sub(1e18);
        blockDiff = block.number.sub(user.lastHarvest);
        return (currentBalance, user.lpTokenStakedAmount, dailyRate, blockDiff);
    }
    
    function getBeforeAfterStakedLPAmountInTokenA(uint _pid) public view returns (uint afterStakedAmount, uint originalStakedAmount) {
        
        UserInfo memory user = userInfo[_pid][msg.sender];
        if(user.amount == 0) return (0,0);
        uint totalSupply = IBEP20(tokenABLP).totalSupply();
        uint lpTokenBalance = getTotalStakedBalance();
        uint ratio = lpTokenBalance.mul(1e18).div(totalSupply);
        if(ratio == 0) return (0,0);
        (uint reserveA,  ) = PancakeLibrary.getReserves(pancakeSwapRouter.factory(), tokenA, pancakeSwapRouter.WETH());
        afterStakedAmount = reserveA.mul(ratio).div(1e18).mul(2);
        return (afterStakedAmount, user.amount);
    }
    
    /// @dev user to stake token 
    function stakeToken(uint _pid, uint _amount) external nonReentrant payable {
        
        require(investorWallet == msg.sender, "not allowed to stake");
        PoolInfo storage pool = poolInfo[_pid];
        require(IBEP20(tokenA).balanceOf(msg.sender) >= _amount, "Not enough balance");
        
        TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), _amount);
        
        //process manager and referralFee
        _processManagerFee(_pid);

        UserInfo storage user = userInfo[_pid][msg.sender];
        
        uint entryAmt = _amount.mul(entryFee).div(10000);
        uint finalDeposit = _amount.sub(entryAmt);
        TransferHelper.safeTransfer(tokenA, platformWallet, entryAmt); 
        //perform autofarm staking
        uint liquidity = _exchangeDepositLP();
        user.amount = user.amount.add(finalDeposit);
        user.lastHarvest = block.number;
        user.lpTokenStakedAmount = getTotalStakedBalance();
        user.lpTokenAmount = user.lpTokenAmount.add(liquidity);

        _mint(address(this), finalDeposit);
        pool.totalLockedSupply = pool.totalLockedSupply.add(finalDeposit);
        
        TransferHelper.safeApprove(address(this), address(_xWinDefi), finalDeposit); 
        _xWinDefi.DepositFarm(xwinpid, finalDeposit);
        
        emit _StakeToken(msg.sender, _pid, _amount, finalDeposit);
    }
    
    /// @dev user to unstake token 
    function unStakeToken(uint _pid, uint _amount) external nonReentrant payable {
        
        require(investorWallet == msg.sender, "not allowed to unstake");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        //process manager and referralFee
        _processManagerFee(_pid);

        //remove LP from PCS
        uint withdrawAmt = getOwnershipStakeAmount(_amount);
        
        _removeFromLP(withdrawAmt);
        _xWinDefi.WithdrawFarm(xwinpid, _amount); //withdraw xwin farming 

        _burn(address(this), _amount);

        uint256 xwinBalance = IBEP20(xwin).balanceOf(address(this));
        if(xwinBalance > 0){
            uint burnFeeTotal = xwinBalance.mul(burnFee).div(10000);
            TransferHelper.safeTransfer(xwin, burnAddress, burnFeeTotal); 
            TransferHelper.safeTransfer(xwin, msg.sender, xwinBalance.sub(burnFeeTotal));
            pool.totalXWINPaid = pool.totalXWINPaid.add(xwinBalance);
        }
        
        //swap to tokenA and send back to user
        if(swapTokenB) _swapETHToToken();

        uint256 tokenABalance = IBEP20(tokenA).balanceOf(address(this));
        TransferHelper.safeTransfer(tokenA, msg.sender, tokenABalance); 
        
        user.amount = user.amount > _amount? user.amount.sub(_amount) : 0; 
        user.lpTokenAmount = user.lpTokenAmount > withdrawAmt ? user.lpTokenAmount.sub(withdrawAmt) : 0;
        user.lastHarvest = block.number;
        user.lpTokenStakedAmount = getTotalStakedBalance();
        pool.totalLockedSupply = pool.totalLockedSupply > _amount ? pool.totalLockedSupply.sub(_amount) : 0;
        
        emit _UnStakeToken(msg.sender, _pid, tokenABalance);
    }
    
    
    /// @dev user to unstake token 
    function harvestXWIN(uint _pid) external nonReentrant payable {
    
        require(investorWallet == msg.sender, "not allowed to harvest");
        _xWinDefi.DepositFarm(xwinpid, 0);
        PoolInfo storage pool = poolInfo[_pid];
        uint256 xwinBalance = IBEP20(xwin).balanceOf(address(this));
        uint burnFeeTotal = xwinBalance.mul(burnFee).div(10000);
        TransferHelper.safeTransfer(xwin, burnAddress, burnFeeTotal); 
        TransferHelper.safeTransfer(xwin, msg.sender, xwinBalance.sub(burnFeeTotal));
        pool.totalXWINPaid = pool.totalXWINPaid.add(xwinBalance);
        emit _harvestXWIN(msg.sender, xwinBalance);
    }

    // _amount is in ADA
    function _exchangeDepositLP() internal returns (uint liquidity) {
        
        uint256 tokenABal = IBEP20(tokenA).balanceOf(address(this));
        uint halfAmt =  tokenABal.mul(5000).div(10000); //this half is ADA
        uint outputSwapInBNB = _swapTokenToETH(halfAmt);  // this half is BNB

        // get quote fixed usdt amount
        uint amountBToGo = _getQuoteAdjusted(outputSwapInBNB, halfAmt);
        (,, liquidity) = _addLiquidityBNB(amountBToGo, outputSwapInBNB);
        uint256 lpBal = IBEP20(tokenABLP).balanceOf(address(this));
        TransferHelper.safeApprove(tokenABLP, address(_autoFarm), lpBal); 
        _autoFarm.deposit(autopid, lpBal);
        return lpBal;
    }
    
    function _removeFromLP(uint _amount) internal {
        
        _autoFarm.withdraw(autopid, _amount);
        
        uint lpbal = IBEP20(tokenABLP).balanceOf(address(this));
        uint LPtotalSupply = IBEP20(tokenABLP).totalSupply(); 
        uint ratio = lpbal.mul(1e18).div(LPtotalSupply);
        if(ratio > 0){
            uint amountA = 0;
            uint amountB = 0;
            
            (uint  reserveA,  uint reserveB) = PancakeLibrary.getReserves(pancakeSwapRouter.factory(), tokenA, pancakeSwapRouter.WETH());
            amountA = reserveA.mul(ratio).div(1e18);
            amountB = PancakeLibrary.quote(amountA, reserveA, reserveB);
            
            uint amtAMin = amountA.mul(9950).div(10000);
            uint amtBMin = amountB.mul(9950).div(10000);
            
            TransferHelper.safeApprove(tokenABLP, address(pancakeSwapRouter), lpbal); 
            pancakeSwapRouter.removeLiquidityETH(
                tokenA,
                lpbal,
                amtAMin,
                amtBMin, 
                address(this),
                block.timestamp
            );
        }
    }
    
    function _getQuotes(uint256 bnbQty) internal view returns (uint amountB) {
        
        (uint reserveA, uint reserveB) = PancakeLibrary.getReserves(pancakeSwapRouter.factory(), pancakeSwapRouter.WETH(), tokenA);
        amountB = PancakeLibrary.quote(bnbQty, reserveA, reserveB);
        return amountB;        
    }
    
    function _getQuoteAdjusted(
        uint halfAmtInBNB,
        uint halfAmtInTokenA
        ) internal view returns (uint){
            
            uint amountB = _getQuotes(halfAmtInBNB);
            return (amountB > halfAmtInTokenA ? halfAmtInTokenA:  amountB);
        } 
    
    function _addLiquidityBNB(
            uint amount, 
            uint bnbAmt
            ) internal returns (uint amountToken, uint amountBNB, uint liquidity) {
        
        TransferHelper.safeApprove(tokenA, address(pancakeSwapRouter), amount); 
        
        (amountToken, amountBNB, liquidity) = pancakeSwapRouter.addLiquidityETH{value: bnbAmt}(
            tokenA,
            amount,
            amount.mul(9950).div(10000),
            bnbAmt.mul(9950).div(10000), 
            address(this),
            block.timestamp
            );
        return (amountToken, amountBNB, liquidity);
            
    }

    function _processManagerFee(uint _pid) internal {
    
        (uint afterBalance, uint beforeBalance, , ) = getBeforeAfterStakedLPAmount(_pid);
        uint profit = afterBalance.sub(beforeBalance);
        if(profit == 0) return;
        uint platformFee = 0;
        if(platformFeeOnProfit > 0) platformFee = profit.mul(platformFeeOnProfit).div(10000);
        if(platformFee > 0){
            _autoFarm.withdraw(autopid, platformFee);
            uint256 lpBal = IBEP20(tokenABLP).balanceOf(address(this));        
            if(lpBal > 0) TransferHelper.safeTransfer(tokenABLP, platformWallet, lpBal); 
        }
    }
    
}