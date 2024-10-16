// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestTokenDistributorSetup} from "./Setup.t.sol";
import "../../src/distributor/TokenDistributor.sol";
import "../../src/distributor/TokenDistributeSubmitRequest.sol";

contract TestTokenDistributorComplete is TestTokenDistributorSetup {
    using TokenDistributeSubmitRequestLib for TokenDistributeSubmitRequest;

    TokenDistributeSubmitRequest internal request;
    bytes32 internal requestId;

    uint256 constant AMOUNT = 100;
    uint256 constant EXPIRY_UNTIL = 1 hours;

    uint256 public constant tmpPrivKey = 11111000002;

    function setUp() public virtual override(TestTokenDistributorSetup) {
        super.setUp();

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
            cooltime: 1,
            maxAmountPerAddress: 100,
            expiry: block.timestamp + EXPIRY_UNTIL,
            name: "test",
            additionalValidator: address(0),
            additionalData: bytes(""),
            coordinate: bytes32(0)
        });

        requestId = request.hash();

        bytes memory sig = _sign(request, privateKey);

        vm.startPrank(facilitator);

        distributor.submit(request, sig);

        vm.stopPrank();
    }

    // fails to complete if caller is not facilitator
    function testCannotCompleteRequestIfCallerIsNotFacilitator() public {
        vm.warp(block.timestamp + EXPIRY_UNTIL - 1);

        vm.startPrank(sender);

        vm.expectRevert(MultiFacilitatorsUpgradable.CallerIsNotFacilitator.selector);
        distributor.completeRequest(requestId);

        vm.stopPrank();
    }

    // complete request
    function testCompleteRequest() public {
        vm.warp(block.timestamp + EXPIRY_UNTIL + 1);

        vm.startPrank(facilitator);

        assertEq(token.balanceOf(sender), MINT_AMOUNT - AMOUNT);
        distributor.completeRequest(requestId);
        assertEq(token.balanceOf(sender), MINT_AMOUNT);

        vm.stopPrank();

        (, , , , , , , , TokenDistributor.RequestStatus status, , , , ) = distributor.pendingRequests(requestId);

        assertTrue(status == TokenDistributor.RequestStatus.Completed);
    }

    // complete request
    function testCompleteRequestIfAmountIsZero() public {
        RecipientData memory recipientData = _getRecipientData(requestId, 0, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.startPrank(facilitator);

        distributor.distribute(recipientData);

        vm.warp(block.timestamp + EXPIRY_UNTIL + 1);

        distributor.completeRequest(requestId);

        vm.stopPrank();

        (, , , , , , , , TokenDistributor.RequestStatus status, , , , ) = distributor.pendingRequests(requestId);

        assertTrue(status == TokenDistributor.RequestStatus.Completed);
    }

    // fails if request is not expired
    function testCannotCompleteRequestBeforeExpiry() public {
        vm.startPrank(facilitator);

        vm.expectRevert(TokenDistributor.RequestNotExpired.selector);
        distributor.completeRequest(requestId);
    }

    // fails to complete request twice
    function testCannotCompleteRequestTwice() public {
        vm.warp(block.timestamp + EXPIRY_UNTIL + 1);

        vm.startPrank(facilitator);

        distributor.completeRequest(requestId);

        vm.expectRevert(TokenDistributor.RequestNotPending.selector);
        distributor.completeRequest(requestId);

        assertEq(token.balanceOf(sender), MINT_AMOUNT);

        vm.stopPrank();
    }
}
