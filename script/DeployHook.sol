// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import "../src/PointsHook.sol";

contract DeployHook is Script {
    function run() external {
        uint privateKey = vm.envUint("PRIVATE_KEY");

        // PoolManager Ethereum Sepolia
        address poolManagerAddress = vm.envAddress("0xE03A1074c86CFeDd5C142C4F04F1a1536e203543");
        // Start broadcasting transactions
        vm.startBroadcast(privateKey);

        // Replace with the actual PoolManager address
        //PoolManager manager = PoolManager(poolManagerAddress);

        // Set the flags for the hook
        uint160 flags = uint160(Hooks.AFTER_SWAP_FLAG);

        // Deploy the PointsHook contract
        PointsHook pointsHook = new PointsHook(IPoolManager(poolManagerAddress));

        // Optionally, you can log the address of the deployed contract
        console.log("PointsHook deployed at:", address(pointsHook));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}