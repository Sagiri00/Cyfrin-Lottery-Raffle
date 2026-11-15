// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

abstract contract CodeConstants{
    uint256 public constant ETH_SEPOLIA_CHAINID = 11155111;
    uint256 public constant LOCAL_CHAINID = 31337;
}

contract HelperConfig is CodeConstants, Script {

    error NetworkIdNotSupported();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAINID] = getSepoliaNetworkConfig();
    }

    function getConfigByChianId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAINID) {
            return getOrCreateAnvilConfig();
        } else {
            revert NetworkIdNotSupported();
        }
    }

    function getSepoliaNetworkConfig() public pure returns(NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether, //1e16
            interval: 30, // 30 Seconds
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            callbackGasLimit: 500000
        
        });

    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(0),
            gasLane: bytes32(0),
            subscriptionId: 0,
            callbackGasLimit: 500000
        });

        networkConfigs[LOCAL_CHAINID] = localNetworkConfig;
        return localNetworkConfig;
    } 
}
