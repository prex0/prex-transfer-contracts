// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestTokenDistributorSetup} from "./Setup.t.sol";
import "../../src/distributor/TokenDistributor.sol";
import "../../src/distributor/TokenDistributeSubmitRequest.sol";

contract TestTokenDistributorDeposit is TestTokenDistributorSetup {
    using TokenDistributeSubmitRequestLib for TokenDistributeSubmitRequest;
    using TokenDistributeDepositRequestLib for TokenDistributeDepositRequest;

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

    // deposit
    function testDeposit() public {
        TokenDistributeDepositRequest memory depositRequest = TokenDistributeDepositRequest({
            dispatcher: address(distributor),
            sender: sender,
            deadline: block.timestamp + EXPIRY_UNTIL,
            nonce: 1,
            requestId: requestId,
            token: address(token),
            amount: AMOUNT
        });

        bytes memory sig = _sign(depositRequest, request.token, privateKey);

        assertEq(token.balanceOf(sender), MINT_AMOUNT - AMOUNT);
        distributor.deposit(depositRequest, sig);
        assertEq(token.balanceOf(sender), MINT_AMOUNT - 2 * AMOUNT);

        (uint256 amount,,,,,,,,,,,,) = distributor.pendingRequests(requestId);

        assertEq(amount, 2 * AMOUNT);
        assertEq(token.balanceOf(address(distributor)), 2 * AMOUNT);
    }

    function testCannotDepositIfRequestNotFound() public {
        TokenDistributeDepositRequest memory depositRequest = TokenDistributeDepositRequest({
            dispatcher: address(distributor),
            sender: sender,
            deadline: block.timestamp + EXPIRY_UNTIL,
            nonce: 1,
            requestId: bytes32(0),
            token: address(token),
            amount: AMOUNT
        });

        bytes memory sig = _sign(depositRequest, request.token, privateKey);

        vm.expectRevert(TokenDistributor.RequestNotPending.selector);
        distributor.deposit(depositRequest, sig);
    }

    function testCannotDepositIfDistribitionRequestExpired() public {
        vm.warp(block.timestamp + EXPIRY_UNTIL + 1);

        TokenDistributeDepositRequest memory depositRequest = TokenDistributeDepositRequest({
            dispatcher: address(distributor),
            sender: sender,
            deadline: block.timestamp + EXPIRY_UNTIL,
            nonce: 1,
            requestId: requestId,
            token: address(token),
            amount: AMOUNT
        });

        bytes memory sig = _sign(depositRequest, request.token, privateKey);

        vm.expectRevert(TokenDistributor.RequestExpiredError.selector);
        distributor.deposit(depositRequest, sig);
    }

    function testCannotDepositIfDepositRequestExpired() public {
        TokenDistributeDepositRequest memory depositRequest = TokenDistributeDepositRequest({
            dispatcher: address(distributor),
            sender: sender,
            deadline: block.timestamp - 1,
            nonce: 1,
            requestId: requestId,
            token: address(token),
            amount: AMOUNT
        });

        bytes memory sig = _sign(depositRequest, request.token, privateKey);

        vm.expectRevert(TokenDistributor.DeadlinePassed.selector);
        distributor.deposit(depositRequest, sig);
    }
}
