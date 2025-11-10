// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// Foundry testing framework
import "forge-std/Test.sol";
// Uniswap V4 testing utilities
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {CurrencyDelta} from "v4-core/libraries/CurrencyDelta.sol";
import {SwapParams, ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {Currency} from "v4-core/types/Currency.sol";
// Contract under test and dependencies
import {FirstHook, IAvePool} from "../src/FirstHook.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {IERC20Minimal} from "v4-core/interfaces/external/IERC20Minimal.sol";

/**
 * @title MockAavePool
 * @notice Mock implementation of Aave Pool for testing purposes
 * @dev Simulates supply/withdraw operations without actual Aave integration
 */
contract MockAavePool is IAvePool {
    // The asset this mock pool accepts
    address public immutable asset;
    // Tracks balances deposited on behalf of each address
    mapping(address => uint256) public balances;
    // Variables to track last supply call for testing verification
    address public lastCaller;
    address public lastOnBehalfOf;
    uint256 public lastAmountSupplied;

    constructor(address _asset) {
        asset = _asset;
    }

    /**
     * @notice Mock implementation of Aave's supply function
     * @dev Transfers tokens from caller and tracks balances
     */
    function supply(address asset_, uint256 amount, address onBehalfOf, uint16) external override {
        require(asset_ == asset, "Asset mismatch");
        // Track call parameters for testing
        lastCaller = msg.sender;
        lastOnBehalfOf = onBehalfOf;
        lastAmountSupplied = amount;

        if(amount == 0) return;

        // Transfer tokens from caller and update balance
        IERC20Minimal(asset).transferFrom(msg.sender, address(this), amount);
        balances[onBehalfOf] += amount;
    }

    /**
     * @notice Mock implementation of Aave's withdraw function
     * @dev Returns tokens to specified address, limited by available balance
     */
    function withdraw(address asset_, uint256 amount, address to) external override returns(uint256){
        require(asset_ == asset, "Asset mismatch");
        uint256 available = balances[msg.sender];
        uint256 toWithdraw = amount > available ? available : amount;
        if(toWithdraw > 0) {
            balances[msg.sender] -= toWithdraw;
            IERC20Minimal(asset).transfer(to, toWithdraw);
        }
        return toWithdraw;
    }
}

/**
 * @title FirstHookTest
 * @notice Test suite for FirstHook contract
 * @dev Tests the reinvestment functionality of swaps into Aave
 */
contract FirstHookTest is Test, Deployers {
    using CurrencyDelta for Currency;

    // Test tokens
    MockERC20 internal token0;
    MockERC20 internal token1;
    // Mock Aave Pool for isolated testing
    MockAavePool internal mockAave;
    // The hook contract under test
    FirstHook internal hook;

    // Uniswap V4 currency wrappers
    Currency internal currency0;
    Currency internal currency1;

    // Test constants: 2000 bps = 20% reinvestment rate
    uint256 internal constant REINVEST_BPS = 2_000;
    // Liquidity range: ticks -60 to 60 (narrow range around current price)
    int24 internal constant TICK_LOWER = -60;
    int24 internal constant TICK_UPPER = 60;

    /**
     * @notice Set up test environment before each test
     * @dev Deploys pool, tokens, mock Aave, hook, and adds initial liquidity
     */
    function setUp() public {
        // Deploy Uniswap V4 core: PoolManager and routers (swap + liquidity modification)
        deployFreshManagerAndRouters();

        // Deploy mock ERC20 tokens for the pool
        token0 = new MockERC20("Token0", "T0", 18);
        token1 = new MockERC20("Token1", "T1", 18);

        // Mint initial token supply to test contract
        token0.mint(address(this), 1_000_000e18);
        token1.mint(address(this), 1_000_000e18);

        // Wrap tokens in Currency type (Uniswap V4 format)
        currency0 = Currency.wrap(address(token0));
        currency1 = Currency.wrap(address(token1));

        // Approve routers to spend our tokens
        token0.approve(address(swapRouter), type(uint256).max);
        token0.approve(address(modifyLiquidityRouter), type(uint256).max);
        token1.approve(address(swapRouter), type(uint256).max);
        token1.approve(address(modifyLiquidityRouter), type(uint256).max);

        // Deploy mock Aave Pool that will accept token1 deposits
        mockAave = new MockAavePool(address(token1));

        // Calculate hook address based on required permission flags
        // Hook needs AFTER_SWAP and AFTER_SWAP_RETURNS_DELTA permissions
        uint160 flags = uint160(Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG);
        address hookAddr = address(uint160(flags));
        // Deploy hook at the calculated address (required by Uniswap V4)
        deployCodeTo(
            "FirstHook.sol",
            abi.encode(manager, address(mockAave), Currency.wrap(address(token1)), address(this), uint16(0), REINVEST_BPS),
            hookAddr
        );

        hook = FirstHook(hookAddr);

        // Initialize the pool with 1:1 price ratio
        (key, ) = initPool(
            currency0,
            currency1,
            hook,
            3000,  // 0.3% fee tier
            SQRT_PRICE_1_1
        );

        // Calculate sqrt prices at tick boundaries
        uint160 sqrtLower = TickMath.getSqrtPriceAtTick(TICK_LOWER);
        uint160 sqrtUpper = TickMath.getSqrtPriceAtTick(TICK_UPPER);

        // Add initial liquidity: 100,000 of token0
        uint256 amount0Desired = 100_000e18;
        uint128 liquidityDelta = LiquidityAmounts.getLiquidityForAmount0(
            SQRT_PRICE_1_1,
            sqrtUpper,
            amount0Desired
        );

        // Execute liquidity addition to the pool
        modifyLiquidityRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: TICK_LOWER,
                tickUpper: TICK_UPPER,
                liquidityDelta: int256(uint256(liquidityDelta)),
                salt: bytes32(0)
            }),
            ZERO_BYTES
        );
    }

    /**
     * @notice Test that hook reinvests a portion of swap output to Aave
     * @dev Test is currently incomplete - only captures initial balance
     * TODO: Execute swap and verify reinvestment to Aave
     */
    function testReinvestPortionOfSwap() public {
        // Capture initial token1 balance before swap
        uint256 quoteBefore = token1.balanceOf(address(this));

        // TODO: Perform swap from token0 to token1
        // TODO: Verify that 20% (REINVEST_BPS) was deposited to Aave
        // TODO: Verify user received remaining 80% of swap output
    }
}