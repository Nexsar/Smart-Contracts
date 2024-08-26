// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Distributors} from "../src/Distributor.sol";

contract CounterTest is Test {
    Distributors public distributor;

    address public distributor1 = makeAddr("distributor1");
    address public distributor2 = makeAddr("distributor2");

    function setUp() public {
        distributor = new Distributors();
        vm.deal(distributor1, 10 ether);
        vm.deal(distributor2, 5 ether);
    }
}
