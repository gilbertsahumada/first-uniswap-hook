// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
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

    function supply(address asset_, uint256 amount, address onBehalfOf, uint16 referralCode) external override {
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

}