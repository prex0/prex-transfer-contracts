// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestTokenDistributorSetup} from "./Setup.t.sol";
import "../../src/distributor/TokenDistributor.sol";
import "../../src/distributor/TokenDistributeSubmitRequest.sol";

contract TestTokenDistributorDistribute is TestTokenDistributorSetup {
    using TokenDistributeSubmitRequestLib for TokenDistributeSubmitRequest;

    TokenDistributeSubmitRequest internal request;
    bytes32 internal requestId;

    uint256 public constant AMOUNT = 2;
    uint256 public constant EXPIRY_UNTIL = 1 hours;

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

    // distribute
    function testDistribute() public {
        TokenDistributor.RecipientData memory recipientData = _getRecipientData(requestId, 0, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.startPrank(facilitator);

        assertEq(token.balanceOf(recipient), 0);
        distributor.distribute(recipientData);
        assertEq(token.balanceOf(recipient), 1);

        vm.stopPrank();

        assertEq(token.balanceOf(recipient), 1);
    }

    // fails to distribute if not facilitator
    function testCannotDistributeIfNotFacilitator() public {
        TokenDistributor.RecipientData memory recipientData = _getRecipientData(requestId, 0, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.startPrank(recipient);

        vm.expectRevert(MultiFacilitators.CallerIsNotFacilitator.selector);
        distributor.distribute(recipientData);

        vm.stopPrank();
    }

    // fails to distribute with insufficient locked amount
    function testCannotDistributeWithInsufficientLockedAmount() public {
        distributor.distribute( _getRecipientData(requestId, 1, block.timestamp + EXPIRY_UNTIL, address(11), tmpPrivKey));
        distributor.distribute( _getRecipientData(requestId, 2, block.timestamp + EXPIRY_UNTIL, address(12), tmpPrivKey));

        TokenDistributor.RecipientData memory recipientData = _getRecipientData(requestId, 0, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.expectRevert(TokenDistributor.InsufficientFunds.selector);
        distributor.distribute(recipientData);

        assertEq(token.balanceOf(address(11)), 1);
        assertEq(token.balanceOf(address(12)), 1);
    }

    // fails to distribute after expiry
    function testCannotDistributeAfterExpiry() public {
        TokenDistributor.RecipientData memory recipientData = _getRecipientData(requestId, 0, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.warp(block.timestamp + EXPIRY_UNTIL + 1);

        vm.expectRevert(TokenDistributor.RequestExpiredError.selector);
        distributor.distribute(recipientData);
    }

    // fails to distribute with incorrect signature
    function testCannotDistributeWithIncorrectSignature() public {
        TokenDistributor.RecipientData memory recipientData = _getRecipientData(requestId, 0, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        recipientData.sig = _sign(request, privateKey);

        vm.expectRevert(TokenDistributor.InvalidSecret.selector);
        distributor.distribute(recipientData);
    }
    
    // fails to distribute with incorrect nonce
    function testCannotDistributeWithIncorrectNonce() public {
        distributor.distribute( _getRecipientData(requestId, 1, block.timestamp + EXPIRY_UNTIL, address(11), tmpPrivKey));

        TokenDistributor.RecipientData memory recipientData = _getRecipientData(requestId, 1, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.expectRevert(TokenDistributor.NonceUsed.selector);
        distributor.distribute(recipientData);
    }
    
    // fails to distribute with incorrect recipient
    function testCannotDistributeWithIncorrectRecipient() public {
        distributor.distribute( _getRecipientData(requestId, 0, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey));

        TokenDistributor.RecipientData memory recipientData = _getRecipientData(requestId, 1, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.expectRevert(abi.encodeWithSelector(TokenDistributor.AlreadyDistributed.selector, recipient));
        distributor.distribute(recipientData);
    }
}
