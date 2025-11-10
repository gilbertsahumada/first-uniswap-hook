// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// Foundry testing framework and console utilities
import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

/**
 * @notice Minimal ERC20 interface for balance queries
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint);
}

/**
 * @title ForkTest
 * @notice Demonstrates fork testing with Foundry
 * @dev Creates a local fork of Ethereum mainnet to test with real contracts and data
 */
contract ForkTest is Test {
    // USDC token contract address on Ethereum mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // Address with significant USDC balance for testing
    // Alternative whale address commented: 0x55fe002aeff02f77364de339a1292923a15844b8
    address constant USDC_WHALE = 0x37305B1cD40574E4C5Ce33f8e8306Be057fD7341;//0x55fe002aeff02f77364de339a1292923a15844b8;

    // Stores the fork ID for the created mainnet fork
    uint forkId;

    /**
     * @notice Modifier that creates and activates an Ethereum mainnet fork
     * @dev Uses public RPC endpoint to create a local copy of mainnet state
     */
    modifier forked() {
        // Create fork of Ethereum mainnet using public RPC
        forkId = vm.createFork(("https://ethereum-rpc.publicnode.com"));
        // Activate the fork for subsequent calls
        vm.selectFork(forkId);
        _;
    }
    
    /**
     * @notice Tests reading USDC balance from a whale address on forked mainnet
     * @dev Demonstrates fork testing: reads real data without spending real gas
     */
    function testUSDCBalanceForked() public forked {
        // Query real USDC balance from mainnet fork
        uint256 balance = IERC20(USDC).balanceOf(USDC_WHALE);
        // Log balance in human-readable format (USDC has 6 decimals)
        console.log("USDC Balance of Whale:", balance / 1e6);
        // Verify whale has substantial USDC (note: message says 1M but checks 100K)
        assertGt(balance, 100_000 * 1e6, "Whale should have more than 1 million USDC");
    }
}