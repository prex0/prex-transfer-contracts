// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestTransferRequestDispatcher} from "../transfer/Setup.t.sol";
import "../../src/expiring-lock/ExpiringLockRequestDispatcher.sol";
import "../../src/expiring-lock/ExpiringLockRequest.sol";

contract TestExpiring is TestTransferRequestDispatcher {
    using ExpiringLockRequestLib for ExpiringLockRequest;

    ExpiringLockRequestDispatcher public expiringDispatcher;

    function setUp() public virtual override(TestTransferRequestDispatcher) {
        super.setUp();

        expiringDispatcher = new ExpiringLockRequestDispatcher(address(this));
    }

    function testSubmitRequest() public {
        ExpiringLockRequest memory request = ExpiringLockRequest({
            amount: 100,
            amountPerWithdrawal: 1,
            token: address(token),
            expiry: block.timestamp + 1000
        });

        vm.startPrank(sender);

        token.approve(address(expiringDispatcher), 110);
        expiringDispatcher.submit(request);

        expiringDispatcher.deposit(request.hash(), 10);
        vm.stopPrank();

        expiringDispatcher.distribute(request.hash(), recipient);

        assertEq(token.balanceOf(recipient), 1);
    }
}
