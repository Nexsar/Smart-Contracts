// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Distributor} from "../src/Distributor.sol";

contract CounterTest is Test {
    Distributor public distributor;

    function setUp() public {
        distributor = new Distributor();
        distributor.setNumber(0);
    }

    function test_Increment() public {
        distributor.increment();
        assertEq(distributor.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        distributor.setNumber(x);
        assertEq(distributor.number(), x);
    }
}
