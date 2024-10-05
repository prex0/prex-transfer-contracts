// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestTokenDistributorSetup} from "./Setup.t.sol";
import "../../src/distributor/TokenDistributor.sol";
import "../../src/distributor/TokenDistributeSubmitRequest.sol";

contract TestTokenDistributorCancel is TestTokenDistributorSetup {
    using TokenDistributeSubmitRequestLib for TokenDistributeSubmitRequest;

    TokenDistributeSubmitRequest internal request;
    bytes32 internal requestId;

    uint256 constant AMOUNT = 100;
    uint256 constant EXPIRY_UNTIL = 1 hours;

    function setUp() public virtual override(TestTokenDistributorSetup) {
        super.setUp();

        uint256 tmpPrivKey = 11111000002;
        address tmpPublicKey = vm.addr(tmpPrivKey);

        request = TokenDistributeSubmitRequest({
            dispatcher: address(distributor),
            sender: sender,
            deadline: block.timestamp + EXPIRY_UNTIL,
            nonce: 0,
            token: address(token),
            publicKey: tmpPublicKey,
            amount: AMOUNT,
            amountPerWithdrawal: 1,
            expiry: block.timestamp + EXPIRY_UNTIL,
            name: "test",
            metadata: ""
        });

        requestId = request.hash();

        bytes memory sig = _sign(request, privateKey);

        vm.startPrank(facilitator);

        distributor.submit(request, sig);

        vm.stopPrank();
    }

    // fails to cancel if caller is not sender
    function testCannotCancelRequestIfCallerIsNotSender() public {
        vm.expectRevert(TokenDistributor.CallerIsNotSender.selector);
        distributor.cancelRequest(requestId);
    }

    // cancel request
    function testCancelRequest() public {
        vm.startPrank(sender);

        assertEq(token.balanceOf(sender), MINT_AMOUNT - AMOUNT);
        distributor.cancelRequest(requestId);
        assertEq(token.balanceOf(sender), MINT_AMOUNT);

        vm.stopPrank();

        (, , , , , , TokenDistributor.RequestStatus status) = distributor.pendingRequests(requestId);

        assertTrue(status == TokenDistributor.RequestStatus.Cancelled);
    }

    // fails to cancel request twice
    function testCannotCancelRequestTwice() public {
        vm.startPrank(sender);

        distributor.cancelRequest(requestId);

        vm.warp(block.timestamp + EXPIRY_UNTIL + 1);

        vm.expectRevert(TokenDistributor.RequestNotPending.selector);
        distributor.cancelRequest(requestId);

        assertEq(token.balanceOf(sender), MINT_AMOUNT);

        vm.stopPrank();
    }
}
