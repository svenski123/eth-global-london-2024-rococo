// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Voucher} from "../src/Voucher.sol";

contract CounterTest is Test {
    Voucher public counter;

    function setUp() public {
        counter = new Voucher();
    }
}
