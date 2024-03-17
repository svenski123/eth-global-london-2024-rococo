// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Voucher} from "../src/Voucher.sol";

address payable constant PROMOTER1 = payable(address(1111));
address payable constant PROMOTER2 = payable(address(2222));
address payable constant PROMOTER3 = payable(address(3333));
address constant CONSUMER1 = address(9999);

contract VoucherTest is Test {
    Voucher public voucher;

    function setUp() public {
        voucher = new Voucher();
	voucher.addPromoter(PROMOTER1, 200);
	voucher.addPromoter(PROMOTER2, 750);
	voucher.createOffer(1711839600, 0.0001 ether, 5);
	vm.deal(CONSUMER1, 10 ether);
    }

    function testFail_setURI() public {
	vm.prank(address(0));
	voucher.setURI("");
    }

    function test_setURI() public {
	voucher.setURI("");
    }

    function testFail_purchaseOffer_1() public {
	vm.prank(CONSUMER1);
	voucher.purchaseOffer(PROMOTER3, 1);
    }

    function testFail_purchaseOffer_2() public {
	vm.prank(CONSUMER1);
	voucher.purchaseOffer(PROMOTER1, 2);
    }

    function testFail_purchaseOffer_3() public {
	vm.prank(CONSUMER1);
	voucher.purchaseOffer(PROMOTER1, 1);
    }

    function test_purchaseOffer_1() public {
	vm.startPrank(CONSUMER1);
	voucher.purchaseOffer{value: 0.0001 ether}(PROMOTER1, 1);
	voucher.purchaseOffer{value: 0.0001 ether}(PROMOTER1, 1);
	voucher.purchaseOffer{value: 0.0001 ether}(PROMOTER1, 1);
	voucher.purchaseOffer{value: 0.0001 ether}(PROMOTER1, 1);
	voucher.purchaseOffer{value: 0.0001 ether}(PROMOTER1, 1);
	vm.stopPrank();
    }
}
