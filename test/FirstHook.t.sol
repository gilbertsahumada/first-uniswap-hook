// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {CurrencyDelta} from "v4-core/libraries/CurrencyDelta.sol";
import {SwapParams, ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {FirstHook, IAvePool} from "../src/FirstHook.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {IERC20Minimal} from "v4-core/interfaces/external/IERC20Minimal.sol";


contract MockAavePool is IAvePool {
    address public immutable asset;
    mapping(address => uint256) public balances;
    address public lastCaller;
    address public lastOnBehalfOf;
    uint256 public lastAmountSupplied;

    constructor(address _asset) {
        asset = _asset;
    }

    function supply(address asset_, uint256 amount, address onBehalfOf, uint16) external override {
        // Mock implementation: just log the supply action
        require(asset_ == asset, "Asset mismatch");
        lastCaller = msg.sender;
        lastOnBehalfOf = onBehalfOf;
        lastAmountSupplied = amount;

        if(amount == 0) return;

        IERC20Minimal(asset).transferFrom(msg.sender, address(this), amount);
        balances[onBehalfOf] += amount;
    }

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

contract FirstHookTest is Test, Deployers {
    using CurrencyDelta for Currency;

    MockERC20 internal token0;
    MockERC20 internal token1;
    MockAavePool internal mockAave;
    FirstHook internal hook;

    Currency internal currency0;
    Currency internal currency1;

    uint256 internal constant REINVEST_BPS = 2_000;
    int24 internal constant TICK_LOWER = -60;
    int24 internal constant TICK_UPPER = 60;

    function setUp() public {
        deployFreshManagerAndRouters();

        token0 = new MockERC20("Token0", "T0", 18);
        token1 = new MockERC20("Token1", "T1", 18);
        
        token0.mint(address(this), 1_000_000e18);
        token1.mint(address(this), 1_000_000e18);

        currency0 = Currency.wrap(address(token0));
        currency1 = Currency.wrap(address(token1));

        token0.approve(address(swapRouter), type(uint256).max);
        token0.approve(address(modifyLiquidityRouter), type(uint256).max);
        token1.approve(address(swapRouter), type(uint256).max);
        token1.approve(address(modifyLiquidityRouter), type(uint256).max);

        mockAave = new MockAavePool(address(token1));

        uint160 flags = uint160(Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG);
        address hookAddr = address(uint160(flags));
        deployCodeTo(
            "FirstHook.sol", 
            abi.encode(manager, address(mockAave), Currency.wrap(address(token1)), address(this), uint16(0), REINVEST_BPS), 
            hookAddr
        );

        hook = FirstHook(hookAddr);

        (key, ) = initPool(
            currency0,
            currency1,
            hook,
            3000,
            SQRT_PRICE_1_1
        );

        uint160 sqrtLower = TickMath.getSqrtPriceAtTick(TICK_LOWER);
        uint160 sqrtUpper = TickMath.getSqrtPriceAtTick(TICK_UPPER);

        uint256 amount0Desired = 100_000e18;
        uint128 liquidityDelta = LiquidityAmounts.getLiquidityForAmount0(
            SQRT_PRICE_1_1,
            sqrtUpper,
            amount0Desired
        );

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

    function testReinvestPortionOfSwap() public {
        uint256 quoteBefore = token1.balanceOf(address(this));
    }
}