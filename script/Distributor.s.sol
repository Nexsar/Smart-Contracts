// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Distributors} from "../src/Distributor.sol";

contract CounterScript is Script {
    Distributors public distributor;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        distributor = new Distributors();

        vm.stopBroadcast();
    }
}
