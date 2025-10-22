// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
 
import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import { ERC1155 } from 'solmate/src/tokens/ERC1155.sol';

import { Currency } from 'v4-core/types/Currency.sol';
import { PoolKey } from 'v4-core/types/PoolKey.sol';
import { PoolId } from 'v4-core/types/PoolId.sol';
import { BalanceDelta } from 'v4-core/types/BalanceDelta.sol';
import { SwapParams, ModifyLiquidityParams } from 'v4-core/types/PoolOperation.sol';

import { IPoolManager } from 'v4-core/interfaces/IPoolManager.sol';
import {Hooks} from 'v4-core/libraries/Hooks.sol';

contract PointsHook is BaseHook, ERC1155 {
    constructor(IPoolManager _manager) BaseHook(_manager) { }
}

