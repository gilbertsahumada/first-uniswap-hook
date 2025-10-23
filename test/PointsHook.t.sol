// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import {Test} from "forge-std/Test.sol";
 
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
 
import {PoolManager} from "v4-core/PoolManager.sol";
import {SwapParams, ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
 
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {PoolId} from "v4-core/types/PoolId.sol";
 
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {SqrtPriceMath} from "v4-core/libraries/SqrtPriceMath.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
 
import {ERC1155TokenReceiver} from "solmate/src/tokens/ERC1155.sol";
 
import "forge-std/console.sol";
import {PointsHook} from "../src/PointsHook.sol";

contract TestPointHook is Test, Deployers, ERC1155TokenReceiver { 
    MockERC20 token;

    Currency ethCurrency = Currency.wrap(address(0));

    PointsHook pointsHook;

    function setUp() public {
        
    }
}