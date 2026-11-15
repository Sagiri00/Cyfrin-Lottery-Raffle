//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";

contract DeployScript is Script {
    function run() public {

    // function deployContract() public returns(Raffle, helperConfig) {}
    vm.startBroadcast();

    vm.stopBroadcast();
    }
}