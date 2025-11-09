// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {SwapParams} from "v4-core/types/PoolOperation.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IERC20Minimal} from "v4-core/interfaces/external/IERC20Minimal.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

interface IAvePool {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(address asset, uint256 amount, address to) external;
}

contract FirstHook is BaseHook {
    using SafeCast for uint256;

    error OnlyOwner();
    error InvalidCurrency();
    error InvalidBps();

    event Reinvested(uint256 amount, address indexed beneficiary);
    event ReinvestedUpdated(uint256 bps);
    event BeneficiaryUpdated(address indexed newBeneficiary);
    event OwnershipTransfered(address indexed newOwner);

    uint256 public constant BPS_DENOMINATOR = 10_000;

    IAvePool public immutable aavePool;
    Currency public immutable reinvestCurrency;
    uint16 public immutable referralCode;

    address public owner;
    address public reinvestBeneficiary;
    uint256 public reinvestBps;

    constructor(
        IPoolManager _manager,
        IAvePool _aavePool,
        Currency _reinvestCurrency,
        address _beneficiary,
        uint16 _referralCode,
        uint256 _reinvestBps
    ) BaseHook(_manager) {
        if (_reinvestCurrency.isAddressZero()) revert InvalidCurrency();
        if (_reinvestBps > 10_000) revert InvalidBps();
        aavePool = _aavePool;
        reinvestCurrency = _reinvestCurrency;
        referralCode = _referralCode;
        reinvestBeneficiary = _beneficiary == address(0)
            ? address(this)
            : _beneficiary;
        _setReinvestBps(_reinvestBps);
    }

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterAddLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: false,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: true,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    function _setReinvestBps(uint256 _newBps) internal {
        if (_newBps > BPS_DENOMINATOR) revert InvalidBps();
        reinvestBps = _newBps;
        emit ReinvestedUpdated(_newBps);
    }
}
