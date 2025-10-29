// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import "../src/PointsHook.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

contract DeployHook is Script {
    address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);
    
    function run() external {
        uint privateKey = vm.envUint("PRIVATE_KEY");

        // PoolManager Ethereum Sepolia
        address poolManagerAddress = vm.envAddress("POOL_MANAGER_ADDRESS");

        // Set the flags for the hook
        uint160 flags = uint160(Hooks.AFTER_SWAP_FLAG);
        bytes memory constructorArgs = abi.encode(poolManagerAddress);
        (address hookAddress, bytes32 salt) = HookMiner.find(CREATE2_DEPLOYER, flags, type(PointsHook).creationCode, constructorArgs);

        // Stop broadcasting transactions
        vm.broadcast(privateKey);

        // Deploy the PointsHook contract
        PointsHook pointsHook = new PointsHook{salt: salt}(IPoolManager(poolManagerAddress));

        require(address(pointsHook) == hookAddress, "Deployed address does not match expected address");
        // Optionally, you can log the address of the deployed contract
        console.log("PointsHook deployed at:", address(pointsHook));
    }
}