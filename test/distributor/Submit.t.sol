// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestTokenDistributorSetup} from "./Setup.t.sol";
import "../../src/distributor/TokenDistributor.sol";
import "../../src/distributor/TokenDistributeSubmitRequest.sol";
import {SignatureVerification} from "../../lib/permit2/src/libraries/SignatureVerification.sol";

contract TestTokenDistributorSubmit is TestTokenDistributorSetup {
    using TokenDistributeSubmitRequestLib for TokenDistributeSubmitRequest;

    uint256 public tmpPrivKey = 11111000002;

    function setUp() public virtual override(TestTokenDistributorSetup) {
        super.setUp();
    }

    function _getRequest(address _dispatcher, uint256 _deadline, uint256 _expiry)
        internal
        view
        returns (TokenDistributeSubmitRequest memory)
    {
        address tmpPublicKey = vm.addr(tmpPrivKey);

        return TokenDistributeSubmitRequest({
            dispatcher: _dispatcher,
            sender: sender,
            deadline: _deadline,
            nonce: 0,
            token: address(token),
            publicKey: tmpPublicKey,
            amount: 1,
            amountPerWithdrawal: 1,
            cooltime: 1,
            maxAmountPerAddress: 100,
            expiry: _expiry,
            name: "test",
            coordinate: bytes32(0),
            additionalValidator: address(0),
            additionalData: bytes("")
        });
    }

    // submit request
    function testSubmitRequest() public {
        TokenDistributeSubmitRequest memory request =
            _getRequest(address(distributor), block.timestamp + 100, block.timestamp + 100);

        bytes memory sig = _sign(request, privateKey);

        vm.startPrank(facilitator);

        distributor.submit(request, sig);

        vm.stopPrank();

        assertEq(token.balanceOf(sender), MINT_AMOUNT - 1);
    }

    // fails to submit if invalid signature
    function testCannotSubmitRequestIfInvalidSignature() public {
        TokenDistributeSubmitRequest memory request =
            _getRequest(address(distributor), block.timestamp + 100, block.timestamp + 100);

        bytes memory sig = _sign(request, privateKey2);

        vm.startPrank(facilitator);

        vm.expectRevert(SignatureVerification.InvalidSigner.selector);
        distributor.submit(request, sig);
    }

    // fails to submit if invalid dispatcher
    function testCannotSubmitRequestIfInvalidDispatcher() public {
        TokenDistributeSubmitRequest memory request =
            _getRequest(address(0), block.timestamp + 100, block.timestamp + 100);

        bytes memory sig = _sign(request, privateKey2);

        vm.startPrank(facilitator);

        vm.expectRevert(TokenDistributor.InvalidDispatcher.selector);
        distributor.submit(request, sig);
    }

    // fails to submit if request already exists
    function testCannotSubmitRequestIfAlreadyExists() public {
        TokenDistributeSubmitRequest memory request =
            _getRequest(address(distributor), block.timestamp + 100, block.timestamp + 100);

        bytes memory sig = _sign(request, privateKey);

        vm.startPrank(facilitator);

        distributor.submit(request, sig);

        vm.expectRevert(TokenDistributor.RequestAlreadyExists.selector);
        distributor.submit(request, sig);

        vm.stopPrank();
    }

    // fails to submit if request is expired
    function testCannotSubmitRequestIfExpired() public {
        vm.warp(block.timestamp + 1000);

        TokenDistributeSubmitRequest memory request = _getRequest(address(distributor), block.timestamp + 100, 100);

        bytes memory sig = _sign(request, privateKey);

        vm.startPrank(facilitator);

        vm.expectRevert(TokenDistributor.InvalidRequest.selector);
        distributor.submit(request, sig);

        vm.stopPrank();
    }

    // fails to submit if request is expired
    function testCannotSubmitRequestIfInvalidExpiry() public {
        vm.warp(block.timestamp + 1000);

        TokenDistributeSubmitRequest memory request =
            _getRequest(address(distributor), block.timestamp + 100, block.timestamp + 365 days);

        bytes memory sig = _sign(request, privateKey);

        vm.startPrank(facilitator);

        vm.expectRevert(TokenDistributor.InvalidRequest.selector);
        distributor.submit(request, sig);

        vm.stopPrank();
    }

    // fails to submit if deadline passed
    function testCannotSubmitIfDeadlinePassed() public {
        TokenDistributeSubmitRequest memory request =
            _getRequest(address(distributor), block.timestamp - 1, block.timestamp + 100);

        bytes memory sig = _sign(request, privateKey);

        vm.startPrank(facilitator);

        vm.expectRevert(TokenDistributor.DeadlinePassed.selector);
        distributor.submit(request, sig);

        vm.stopPrank();
    }
}
