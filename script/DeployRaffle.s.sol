//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployScript is Script {
    function run() public {
        deployContract();

    }
    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // local => Deploy mock and get local config
        // sepolia => get sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
    
    vm.startBroadcast();
    Raffle raffle = new Raffle (
        config.entranceFee,
        config.interval,
        config.vrfCoordinator,
        config.gasLane,
        config.subscriptionId,
        config.callbackGasLimit
    );
    return (raffle, helperConfig);
    vm.stopBroadcast();
    }
}