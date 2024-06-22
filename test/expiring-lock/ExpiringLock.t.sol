// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestTransferRequestDispatcher} from "../transfer/Setup.t.sol";
import "../../src/expiring-lock/ExpiringLockRequestDispatcher.sol";
import "../../src/expiring-lock/ExpiringLockRequest.sol";

contract TestExpiring is TestTransferRequestDispatcher {
    using ExpiringLockRequestLib for ExpiringLockRequest;

    ExpiringLockRequestDispatcher public expiringDispatcher;

    ExpiringLockRequest testLimitedRequest;

    function setUp() public virtual override(TestTransferRequestDispatcher) {
        super.setUp();

        expiringDispatcher = new ExpiringLockRequestDispatcher(address(this));

        testLimitedRequest = ExpiringLockRequest({
            amount: 10,
            amountPerWithdrawal: 1,
            token: address(token),
            expiry: block.timestamp + 1000,
            isLimitedByAddress: true,
            metadata: ""
        });
    }

    function testSubmitRequest() public {
        ExpiringLockRequest memory request = ExpiringLockRequest({
            amount: 1,
            amountPerWithdrawal: 1,
            token: address(token),
            expiry: block.timestamp + 100,
            isLimitedByAddress: true,
            metadata: ""
        });

        vm.startPrank(sender);

        token.approve(address(expiringDispatcher), 2);
        expiringDispatcher.submit(request);

        expiringDispatcher.deposit(request.hash(), 1, "");
        vm.stopPrank();

        expiringDispatcher.distribute(request.hash(), recipient, "");

        assertEq(token.balanceOf(recipient), 1);

        vm.warp(block.timestamp + 101);

        assertEq(token.balanceOf(sender), 999999999999999998);
        expiringDispatcher.completeRequest(request.hash());
        assertEq(token.balanceOf(sender), 999999999999999999);
    }

    function testCannotDistributeTwice() public {
        vm.startPrank(sender);

        token.approve(address(expiringDispatcher), 110);
        expiringDispatcher.submit(testLimitedRequest);

        expiringDispatcher.deposit(testLimitedRequest.hash(), 10, "");
        vm.stopPrank();

        expiringDispatcher.distribute(testLimitedRequest.hash(), recipient, "");

        vm.expectRevert(abi.encodeWithSelector(ExpiringLockRequestDispatcher.AlreadyDistributed.selector, recipient));
        expiringDispatcher.distribute(testLimitedRequest.hash(), recipient, "");
    }
}
