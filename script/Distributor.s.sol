// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Distributor} from "../src/Distributor.sol";

contract CounterScript is Script {
    Distributor public distributor;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        distributor = new Distributor();

        vm.stopBroadcast();
    }
}
