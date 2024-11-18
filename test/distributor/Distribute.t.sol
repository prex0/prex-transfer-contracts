// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestTokenDistributorSetup} from "./Setup.t.sol";
import "../../src/distributor/TokenDistributor.sol";
import "../../src/distributor/TokenDistributeSubmitRequest.sol";

contract TestTokenDistributorDistribute is TestTokenDistributorSetup {
    using TokenDistributeSubmitRequestLib for TokenDistributeSubmitRequest;

    TokenDistributeSubmitRequest internal request;
    bytes32 internal requestId;

    uint256 public constant AMOUNT = 3;
    uint256 public constant EXPIRY_UNTIL = 5 hours;

    uint256 public constant tmpPrivKey = 11111000002;
    uint256 public constant subPrivKey = 11111000003;

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
            cooltime: 1 hours,
            maxAmountPerAddress: 2,
            expiry: block.timestamp + EXPIRY_UNTIL,
            name: "test",
            coordinate: bytes32(0),
            additionalValidator: address(0),
            additionalData: bytes("")
        });

        requestId = request.hash();

        bytes memory sig = _sign(request, privateKey);

        vm.startPrank(facilitator);

        distributor.submit(request, sig);

        vm.stopPrank();
    }

    // distribute
    function testDistribute() public {
        RecipientData memory recipientData =
            _getRecipientData(requestId, 0, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.startPrank(facilitator);

        assertEq(token.balanceOf(recipient), 0);
        distributor.distribute(recipientData);
        assertEq(token.balanceOf(recipient), 1);

        vm.stopPrank();

        assertEq(token.balanceOf(recipient), 1);
    }

    function testDistributeWithSub() public {
        RecipientData memory recipientData = _getRecipientDataWithSub(
            requestId, 0, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey, request.expiry, subPrivKey
        );

        vm.startPrank(facilitator);

        assertEq(token.balanceOf(recipient), 0);
        distributor.distribute(recipientData);
        assertEq(token.balanceOf(recipient), 1);

        vm.stopPrank();

        assertEq(token.balanceOf(recipient), 1);
    }

    // fails to distribute if not facilitator
    function testCannotDistributeIfNotFacilitator() public {
        RecipientData memory recipientData =
            _getRecipientData(requestId, 0, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.startPrank(recipient);

        vm.expectRevert(MultiFacilitatorsUpgradable.CallerIsNotFacilitator.selector);
        distributor.distribute(recipientData);

        vm.stopPrank();
    }

    // fails to distribute with insufficient locked amount
    function testCannotDistributeWithInsufficientLockedAmount() public {
        distributor.distribute(_getRecipientData(requestId, 1, block.timestamp + EXPIRY_UNTIL, address(11), tmpPrivKey));
        distributor.distribute(_getRecipientData(requestId, 2, block.timestamp + EXPIRY_UNTIL, address(12), tmpPrivKey));
        distributor.distribute(_getRecipientData(requestId, 3, block.timestamp + EXPIRY_UNTIL, address(13), tmpPrivKey));

        RecipientData memory recipientData =
            _getRecipientData(requestId, 0, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.expectRevert(TokenDistributor.InsufficientFunds.selector);
        distributor.distribute(recipientData);

        assertEq(token.balanceOf(address(11)), 1);
        assertEq(token.balanceOf(address(12)), 1);
    }

    // fails to distribute after expiry
    function testCannotDistributeAfterExpiry() public {
        RecipientData memory recipientData =
            _getRecipientData(requestId, 0, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.warp(block.timestamp + EXPIRY_UNTIL + 1);

        vm.expectRevert(TokenDistributor.RequestExpiredError.selector);
        distributor.distribute(recipientData);
    }

    // fails to distribute with incorrect signature
    function testCannotDistributeWithIncorrectSignature() public {
        RecipientData memory recipientData =
            _getRecipientData(requestId, 0, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        recipientData.sig = _sign(request, privateKey);

        vm.expectRevert(TokenDistributor.InvalidSecret.selector);
        distributor.distribute(recipientData);
    }

    // fails to distribute with incorrect nonce
    function testCannotDistributeWithIncorrectNonce() public {
        distributor.distribute(_getRecipientData(requestId, 1, block.timestamp + EXPIRY_UNTIL, address(11), tmpPrivKey));

        RecipientData memory recipientData =
            _getRecipientData(requestId, 1, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.expectRevert(TokenDistributor.NonceUsed.selector);
        distributor.distribute(recipientData);
    }

    // fails to distribute if not enough cooltime
    function testCannotDistributeIfNotEnoughCooltime() public {
        distributor.distribute(_getRecipientData(requestId, 0, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey));

        RecipientData memory recipientData =
            _getRecipientData(requestId, 1, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.expectRevert(CoolTimeLib.NotEnoughCooltime.selector);
        distributor.distribute(recipientData);

        vm.warp(block.timestamp + 2 hours);

        // should be successful
        distributor.distribute(recipientData);
    }

    // fails to distribute if exceeded max amount
    function testCannotDistributeIfExceededMaxAmount() public {
        distributor.distribute(_getRecipientData(requestId, 0, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey));

        vm.warp(2 hours);

        distributor.distribute(_getRecipientData(requestId, 1, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey));

        vm.warp(4 hours);

        RecipientData memory recipientData =
            _getRecipientData(requestId, 2, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.expectRevert(CoolTimeLib.ExceededMaxAmount.selector);
        distributor.distribute(recipientData);
    }
}
