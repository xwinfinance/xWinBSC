pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later

import "./CakeToken.sol";
import "./SyrupBar.sol";

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

interface IMigratorChef {
    // Perform LP token migration from legacy PancakeSwap to CakeSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to PancakeSwap LP tokens.
    // CakeSwap must mint EXACTLY the same amount of CakeSwap LP tokens or
    // else something bad will happen. Traditional PancakeSwap does not
    // do that so be careful!
    function migrate(IBEP20 token) external returns (IBEP20);
}

contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of CAKEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accCakePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accCakePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that CAKEs distribution occurs.
        uint256 accCakePerShare; // Accumulated CAKEs per share, times 1e12. See below.
    }

    // The CAKE TOKEN!
    CakeToken public cake;
    // The SYRUP TOKEN!
    SyrupBar public syrup;
    // Dev address.
    address public devaddr;
    // CAKE tokens created per block.
    uint256 public cakePerBlock;
    // Bonus muliplier for early cake makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when CAKE mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        CakeToken _cake,
        SyrupBar _syrup,
        address _devaddr,
        uint256 _cakePerBlock,
        uint256 _startBlock
    ) public {
        cake = _cake;
        syrup = _syrup;
        devaddr = _devaddr;
        cakePerBlock = _cakePerBlock;
        startBlock = _startBlock;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _cake,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accCakePerShare: 0
        }));

        totalAllocPoint = 1000;

    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accCakePerShare: 0
        }));
        updateStakingPool();
    }

    // Update the given pool's CAKE allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            updateStakingPool();
        }
    }

    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(points);
            poolInfo[0].allocPoint = points;
        }
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IBEP20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IBEP20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending CAKEs on frontend.
    function pendingCake(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCakePerShare = pool.accCakePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 cakeReward = multiplier.mul(cakePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCakePerShare = accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accCakePerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 cakeReward = multiplier.mul(cakePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        cake.mint(devaddr, cakeReward.div(10));
        cake.mint(address(syrup), cakeReward);
        pool.accCakePerShare = pool.accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'deposit CAKE by staking');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeCakeTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'withdraw CAKE by unstaking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeCakeTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Stake CAKE tokens to MasterChef
    function enterStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeCakeTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);

        syrup.mint(msg.sender, _amount);
        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw CAKE tokens from STAKING.
    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeCakeTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);

        syrup.burn(msg.sender, _amount);
        emit Withdraw(msg.sender, 0, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe cake transfer function, just in case if rounding error causes pool to not have enough CAKEs.
    function safeCakeTransfer(address _to, uint256 _amount) internal {
        syrup.safeCakeTransfer(_to, _amount);
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}

interface xWinMaster {
    
    function getTokenName(address _tokenaddress) external view returns (string memory tokenname);
    function getPriceByAddress(address _targetAdd, string memory _toTokenName) external view returns (uint);
    function getPriceFromBand(string memory _fromToken, string memory _toToken) external view returns (uint);
    function getPancakeRouter() external view returns (IPancakeRouter02 pancakeRouter);
}


interface xWinDefiInterface {
    
    function getPlatformFee() view external returns (uint256);
    function getPlatformAddress() view external returns (address);
    function gexWinBenefitPool() view external returns (address) ;
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract xWinFarmV2 is IBEP20, BEP20 {
    
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    xWinMaster private _xWinMaster;

    address private protocolOwner;
    address private masterOwner;
    address private managerOwner;
    uint256 private managerFeeBps;

    address public farmToken;
    address public cakeToken;// = address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    uint256 public pid;
    address public BaseToken = address(0x0000000000000000000000000000000000000000);
    uint256 private reInvestCycle = 14400; // reinvest cycle
    uint256 public nextReInvest;
    bool public pause = false;

    DailyReturn public dailyReturn;
    
    struct DailyReturn {
        uint dailyRate;
        uint blockdiff;
    }
    
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
            uint256 _pid
        ) public BEP20(name, symbol) {
            cakeToken = _cakeToken;
            farmToken = _farmToken;
            pid = _pid; 
            protocolOwner = _protocolOwner;
            masterOwner = _masterOwner;
            managerOwner = _managerOwner;
            managerFeeBps = _managerFeeBps;
            _xWinMaster = xWinMaster(masterOwner);
            _masterChef = MasterChef(address(0x73feaa1eE314F8c655E354234017bE2193C9E24E));
            xwinProtocol = xWinDefiInterface(_protocolOwner);
            nextReInvest = block.number.add(reInvestCycle);
        }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    /// @dev owner to pause for depositing
    function setPause(bool _pause) public onlyOwner {
        pause = _pause;
    }
    
    function mint(address to, uint256 amount) internal onlyxWinProtocol {
        _mint(to, amount);
    }
    
    function updateFarmInfo(uint256 _pid, address _cakeAddress, address _farmAddress) public onlyOwner {
        pid = _pid;
        cakeToken = _cakeAddress;
        farmToken = _farmAddress;
    }
    
    function _swapBNBToTokens(
            address token,
            uint amountIn, 
            uint deadline,
            address destAddress,
            uint priceImpactTolerance 
            )
    internal returns (uint){
            
            IPancakeRouter02 router = _xWinMaster.getPancakeRouter();
            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = token;
            
            (uint reserveA,  uint reserveB) = PancakeLibrary.getReserves(router.factory(), router.WETH(), token);
            uint quote = PancakeLibrary.quote(amountIn, reserveA, reserveB);
            uint[] memory amounts = router.swapExactETHForTokens{value: amountIn}(quote.sub(quote.mul(priceImpactTolerance).div(10000)), path, destAddress, deadline);
            
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
            
            IPancakeRouter02 router = _xWinMaster.getPancakeRouter();
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = router.WETH();
            
            TransferHelper.safeApprove(token, address(router), amountIn); 
            
            (uint reserveA,  uint reserveB) = PancakeLibrary.getReserves(router.factory(), token, router.WETH());
            uint quote = PancakeLibrary.quote(amountIn, reserveA, reserveB);
            uint[] memory amounts = router.swapExactTokensForETH(amountIn, quote.sub(quote.mul(priceImpactTolerance).div(10000)), path, destAddress, deadline);
			return amounts[amounts.length - 1];

        }
        
    function _addLiquidityBNB(
            uint amount, 
            uint bnbAmt,
            uint deadline
            )
    internal returns (uint amountToken, uint amountBNB, uint liquidity) {
        
        IPancakeRouter02 router = _xWinMaster.getPancakeRouter();    
        TransferHelper.safeApprove(farmToken, address(router), amount); 
        
        (amountToken, amountBNB, liquidity) = router.addLiquidityETH{value: bnbAmt}(
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
    function updateManager(address newManager) external onlyOwner payable {
        
        emit _ManagerOwnerUpdate(managerOwner, newManager, block.timestamp);
        managerOwner = newManager;
    }
    
    /// @dev update protocol owner
    function updateProtocol(address _newProtocol) external onlyxWinProtocol {
        protocolOwner = _newProtocol;
        xwinProtocol = xWinDefiInterface(_newProtocol);
    }
    
    /// @dev update manager fee
    function updateManagerFee(uint256 newFeebps) external onlyOwner payable {
        
        emit _ManagerFeeUpdate(managerFeeBps, newFeebps, block.timestamp);
        managerFeeBps = newFeebps;
    }
    
    /// @dev update xwin master contract
    function updateXwinMaster(address _masterOwner) external onlyOwner {
        _xWinMaster = xWinMaster(_masterOwner);
    }
    
    /// @dev update reInvestCycle
    function updateVaultProperty(uint256 _reInvestCycle) external onlyOwner {
        reInvestCycle = _reInvestCycle;
        nextReInvest =  block.number.add(_reInvestCycle);
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
        
        require(pause == false, "temporariy pause");
        (uint256 mintQty, uint256 totalFundB4) = _getMintQty(_tradeParams.amount);
        mint(_investorAddress, mintQty);
        
        uint256 totalSubs = address(this).balance;
            
        _swapAndStakeFromBNB(totalSubs, _tradeParams);
       
        _addToPancakeFarm();

        if(nextReInvest < block.number) {
           
           if(farmToken == cakeToken){
               _reinvestCakes(_tradeParams, totalFundB4);
           } 
           else{
               _reinvestCakesDiffToken(_tradeParams, totalFundB4);
           }
        }

        return mintQty;
    }
    
    /// @dev perform redemption based on unit redeem
    function Redeem(
        TradeParams memory _tradeParams,
        address _investorAddress
        ) external onlyxWinProtocol payable returns (uint256){
        
        uint256 redeemratio = _tradeParams.amount.mul(1e18).div(totalSupply());
        require(redeemratio > 0, "redeem ratio is zero");
        
        uint lpTokenBalance = _getLPBalance();
        uint256 qtyToRedeem = redeemratio.mul(lpTokenBalance).div(1e18);
        
        //withdraw from pancake staking pool first
        _removeFromFarm(qtyToRedeem);
        
        (uint amountToken, uint amountBNB) = _removeFromLP(qtyToRedeem, _tradeParams.deadline);
        
        uint256 totalOutput = _getTotalOutput(redeemratio, _tradeParams, amountBNB, amountToken);
        
        uint cakeToBNBOutput = _redeemCakes(redeemratio, _tradeParams);
        totalOutput = totalOutput.add(cakeToBNBOutput);

        _burn(msg.sender, _tradeParams.amount);
        
        uint finalSwapOutput = _handleFeeTransfer(totalOutput);
        TransferHelper.safeTransferBNB(_investorAddress, finalSwapOutput);
        
       if(nextReInvest < block.number) {
           
           uint256 totalFundValue = _getFundValues();
        
           if(farmToken == cakeToken){
               _reinvestCakes(_tradeParams, totalFundValue);
           } 
           else{
               _reinvestCakesDiffToken(_tradeParams, totalFundValue);
           }
        }
        return redeemratio;
    }
    
    function _getWithdrawRewardWithCushion(address tokenaddress, uint256 withdrawQty) internal view returns ( 
            uint256 totalSupply, uint256 ratio, uint256 reserveA, uint256 reserveB, 
            uint256 ATokenAmount, uint256 amountB, uint256 ATokenAmountMin, uint256 amountBMin,
            address pair 
            ) {
        
        IPancakeRouter02 router = _xWinMaster.getPancakeRouter();    
        pair = PancakeLibrary.pairFor(router.factory(), tokenaddress, router.WETH());
        totalSupply = IBEP20(pair).totalSupply(); 
        ratio = withdrawQty.mul(1e18).div(totalSupply);
        
        if(ratio > 0){
            ( reserveA,  reserveB) = PancakeLibrary.getReserves(router.factory(), tokenaddress,  router.WETH());
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
        
        IPancakeRouter02 router = _xWinMaster.getPancakeRouter();    
        address pair = PancakeLibrary.pairFor(router.factory(), _targetAdd, router.WETH());
        uint totalSupply = IBEP20(pair).totalSupply();
        if(totalSupply == 0) return (0,0);

        uint lpTokenBalance = 0;
        
        (lpTokenBalance, ) = readUserInfo();

        if(lpTokenBalance == 0) return (0,0);

        uint ratio = lpTokenBalance.mul(1e18).div(totalSupply);
        
        if(ratio == 0) return (0,0);
        
        (uint reserveA,  uint reserveB) = PancakeLibrary.getReserves(router.factory(), _targetAdd,  router.WETH());
        
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
        
        IPancakeRouter02 router = _xWinMaster.getPancakeRouter();    
        (uint reserveA, uint reserveB) = PancakeLibrary.getReserves(router.factory(), router.WETH(), targetToken);
        amountOut = PancakeLibrary.getAmountOut(bnbQty, reserveA, reserveB);
        amountB = PancakeLibrary.quote(bnbQty, reserveA, reserveB);
        
        return (amountB, amountOut);
        
    }
   
    /// @dev perform Add Syrup Pool
    function _addToPancakeFarm() internal {
        
        (IBEP20 lpToken, , , ) = _readPool();
        uint liquidity = lpToken.balanceOf(address(this));
        require(lpToken.approve(address(_masterChef), liquidity), "approval to _masterChef failed");
        _masterChef.deposit(pid, liquidity);

    }
    
    function _readPool() internal view returns (
        IBEP20 lpToken,          // Address of LP token contract.
        uint256 allocPoint,       // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 lastRewardBlock,  // Last block number that CAKEs distribution occurs.
        uint256 accCakePerShare
        ) {
        return _masterChef.poolInfo(pid);
    }
    
    function readUserInfo() public view returns (
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
        
        IPancakeRouter02 router = _xWinMaster.getPancakeRouter();
        TransferHelper.safeApprove(pair, address(router), redeemUnit); 
        (amountToken, amountBNB) = router.removeLiquidityETH(
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
        uint256 pendingCake = _masterChef.pendingCake(pid, address(this));
        totalCakeBal = totalCakeBal.add(pendingCake);

        uint256 farmTokenBalance = 0;
        if(cakeToken != farmToken){
            farmTokenBalance = IBEP20(farmToken).balanceOf(address(this));
        }
        
        farmtoBNBEstAmount = 0;
        caketoBNBEstAmount = 0;
        IPancakeRouter02 router = _xWinMaster.getPancakeRouter();
        if(farmTokenBalance > 0){
            (uint reserveA,  uint reserveB) = PancakeLibrary.getReserves(router.factory(), farmToken, router.WETH());
            farmtoBNBEstAmount = PancakeLibrary.quote(farmTokenBalance, reserveA, reserveB);
        }
        if(totalCakeBal > 0){
            (uint cakereserveA,  uint cakereserveB) = PancakeLibrary.getReserves(router.factory(), cakeToken, router.WETH());
            caketoBNBEstAmount = PancakeLibrary.quote(totalCakeBal, cakereserveA, cakereserveB);
        }
    
        return (farmtoBNBEstAmount, caketoBNBEstAmount);
    }
    
    function _handleFeeTransfer(
        uint swapOutput
        ) internal returns (uint finalSwapOutput){
        
        uint platformUnit = swapOutput.mul(xwinProtocol.getPlatformFee()).div(10000);
        
        if(platformUnit > 0){
            uint benefit = platformUnit.mul(3000).div(10000); //30% go to benefit pool for community
            TransferHelper.safeTransferBNB(xwinProtocol.getPlatformAddress(), benefit);
            TransferHelper.safeTransferBNB(xwinProtocol.gexWinBenefitPool(), platformUnit.sub(benefit));
        }
        
        uint managerUnit = swapOutput.mul(managerFeeBps).div(10000);
        
        if(managerUnit > 0){
            TransferHelper.safeTransferBNB(managerOwner, managerUnit);
        }
        
        finalSwapOutput = swapOutput.sub(platformUnit).sub(managerUnit);
        
        return (finalSwapOutput);

    }
    
    function getMyLPBalance() public view returns (uint myLPBalance)  {
        
        if(totalSupply() == 0) return 0;
        uint lpbalance = _getLPBalance();
        uint userMybalance = IBEP20(address(this)).balanceOf(msg.sender);
        uint redeemratio = userMybalance.mul(1e18).div(totalSupply());
        myLPBalance = redeemratio.mul(lpbalance).div(1e18);
        return myLPBalance;
    }
    
    function _getLPBalance() internal view returns (uint lpTokenBalance)  {
    
        (lpTokenBalance, ) = readUserInfo();
        return lpTokenBalance;
    }
    
    function _getMintQty(uint256 srcQty) internal view returns (uint256 mintQty, uint256 totalFundB4)  {
        
        uint256 totalFundAfter = _getFundValues();
        totalFundB4 = totalFundAfter.sub(srcQty);
        mintQty = _getNewFundUnits(totalFundB4, totalFundAfter, totalSupply());
        return (mintQty, totalFundB4);
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
    
    /// @dev Calc qty to issue during subscription 
    function _getTotalOutput(uint redeemratio, TradeParams memory _tradeParams, uint amountBNB, uint amountToken) 
        internal returns (uint256 totalouput)  {
    
        //get bnb bal before remove from L 
        uint256 totalBaseBal = address(this).balance;
        uint existingBase = totalBaseBal.sub(amountBNB);
        uint256 totalOutput = redeemratio.mul(existingBase).div(1e18);
        totalOutput = totalOutput.add(amountBNB);
        
        //get farm token to bnb 
        uint farmtokenBal = IBEP20(farmToken).balanceOf(address(this));
        uint existingFarmToken = farmtokenBal.sub(amountToken);
        uint256 eligibleBal = redeemratio.mul(existingFarmToken).div(1e18);
        eligibleBal = eligibleBal.add(amountToken);
        
        //convert farmtoken into BNB
        if(eligibleBal > 0){
            uint256 swapOutput = _swapTokenToBNB(farmToken, eligibleBal, _tradeParams.deadline, address(this), _tradeParams.priceImpactTolerance);
            totalOutput = totalOutput.add(swapOutput);
        } 
        
        return totalOutput;
    }
    
     function _redeemCakes(uint redeemratio, TradeParams memory _tradeParams) internal returns (uint swapOutput) {
        
        if(farmToken == cakeToken) return 0; 
        uint cakeBal = IBEP20(cakeToken).balanceOf(address(this));
        //convert caketoken balance into BNB
        if(cakeBal > 0){
            swapOutput = _swapTokenToBNB(cakeToken, redeemratio.mul(cakeBal).div(1e18), _tradeParams.deadline, address(this), _tradeParams.priceImpactTolerance);
        } 
        return swapOutput;
     }
        
    /// @dev manager perform remove from farm. Allow for user to claim LP token in emergency
    function emergencyRemoveFromFarm() external onlyxWinProtocol {
        
        (uint256 lpTokenBalance, ) = readUserInfo();
        _masterChef.withdraw(pid, lpTokenBalance);
    }
    
    function _swapAndStakeFromBNB(uint amount, TradeParams memory _tradeParams) internal 
        returns (uint liquidity){
        
        uint halfAmt =  amount.mul(5000).div(10000);
        uint swapOutput = _swapBNBToTokens(farmToken, halfAmt, _tradeParams.deadline, address(this), _tradeParams.priceImpactTolerance);
        
        // get quote for farmtoken based on fixed bnb amount
        uint amountBToGo = _getQuoteAdjusted(halfAmt, swapOutput);
        (, , liquidity) = _addLiquidityBNB(amountBToGo, halfAmt, _tradeParams.deadline);
        return liquidity;
    }
    
    function _updateDailyRate(uint cakeValue, uint totalFundValue) internal {
        
        dailyReturn.dailyRate = cakeValue.mul(1e18).div(totalFundValue);
        dailyReturn.blockdiff = block.number > nextReInvest ? block.number.sub(nextReInvest).add(reInvestCycle) : reInvestCycle;
    }
    
    function _reinvestCakes(TradeParams memory _tradeParams, uint totalFundValue) internal {
        
        uint cakeBal = IBEP20(cakeToken).balanceOf(address(this));
        if(cakeBal == 0) return;
        
        uint cakePriceInBNB = _xWinMaster.getPriceByAddress(cakeToken, "BNB");
        uint cakeValue = cakeBal.mul(cakePriceInBNB).div(1e18);
        
        _updateDailyRate(cakeValue, totalFundValue);
        
        uint halfCakeAmt = cakeBal.mul(5000).div(10000);
        uint swapBNBOutput = _swapTokenToBNB(cakeToken, halfCakeAmt, _tradeParams.deadline, address(this), _tradeParams.priceImpactTolerance);
        // get quote for farmtoken based on fixed bnb amount
        uint amountBToGo = _getQuoteAdjusted(swapBNBOutput, halfCakeAmt);
        _addLiquidityBNB(amountBToGo, swapBNBOutput, _tradeParams.deadline);
        _addToPancakeFarm();
        
        //update next reinvest cycle
        nextReInvest = block.number.add(reInvestCycle);
    }
    
    function _reinvestCakesDiffToken(TradeParams memory _tradeParams, uint totalFundValue) internal {
        
        uint cakeBal = IBEP20(cakeToken).balanceOf(address(this));
        if(cakeBal == 0) return;
        
        uint cakePriceInBNB = _xWinMaster.getPriceByAddress(cakeToken, "BNB");
        uint cakeValue = cakeBal.mul(cakePriceInBNB).div(1e18);
        
        _updateDailyRate(cakeValue, totalFundValue);

        uint swapBNBOutput = _swapTokenToBNB(cakeToken, cakeBal, _tradeParams.deadline, address(this), _tradeParams.priceImpactTolerance);
        _swapAndStakeFromBNB(swapBNBOutput, _tradeParams);
        _addToPancakeFarm();
        
        //update next reinvest cycle
        nextReInvest = block.number.add(reInvestCycle);
    }
    
    /// @dev Allow manager to trigger reinvest for compounding effect
    function reInvest(TradeParams memory _tradeParams) public {
        
        _masterChef.deposit(pid, 0);
        uint256 totalFundValue = _getFundValues();
        if(farmToken == cakeToken){
           _reinvestCakes(_tradeParams, totalFundValue);
        } 
        else{
           _reinvestCakesDiffToken(_tradeParams, totalFundValue);
        }
    }
    
    /// @dev get pending cake
    function getPendingCake() public view returns (uint ) {
        return _masterChef.pendingCake(pid, address(this));
    }
    
    /// @dev Allow for user to claim LP token in emergency
    function emergencyRedeem(uint256 redeemUnit, address _investorAddress) external onlyxWinProtocol payable {
        
        IPancakeRouter02 router = _xWinMaster.getPancakeRouter();
        uint256 redeemratio = redeemUnit.mul(1e18).div(totalSupply());
        require(redeemratio > 0, "redeem ratio is zero");
        _burn(msg.sender, redeemUnit);
        address pair = PancakeLibrary.pairFor(router.factory(), farmToken, router.WETH());
        uint256 lpTokenBalance = IBEP20(pair).balanceOf(address(this));
        uint256 totalOutput = redeemratio.mul(lpTokenBalance).div(1e18);
        TransferHelper.safeTransfer(pair, _investorAddress, totalOutput);
    }
}
