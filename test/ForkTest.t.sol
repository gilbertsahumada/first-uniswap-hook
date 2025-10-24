// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
 
import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
}

contract ForkTest is Test {
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDC_WHALE = 0x37305B1cD40574E4C5Ce33f8e8306Be057fD7341;//0x55fe002aeff02f77364de339a1292923a15844b8;

    uint forkId;

    modifier forked() {
        forkId = vm.createFork(("https://ethereum-rpc.publicnode.com"));
        vm.selectFork(forkId);
        _;
    }
    
    function testUSDCBalanceForked() public forked {
        uint256 balance = IERC20(USDC).balanceOf(USDC_WHALE);
        console.log("USDC Balance of Whale:", balance / 1e6);
        assertGt(balance, 100_000 * 1e6, "Whale should have more than 1 million USDC");
    }
}