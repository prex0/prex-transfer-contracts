// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestTransferRequestDispatcher} from "../transfer/Setup.t.sol";
import "../../src/onetime-lock/OnetimeLockRequestDispatcher.sol";
import "../../src/onetime-lock/OnetimeLockRequest.sol";
import "../../src/libraries/SecretUtil.sol";

contract TestOnetime is TestTransferRequestDispatcher {
    using OnetimeLockRequestLib for OnetimeLockRequest;

    OnetimeLockRequestDispatcher public onetimeDispatcher;

    bytes32 secret = bytes32(keccak256(abi.encodePacked("secret")));

    function setUp() public virtual override(TestTransferRequestDispatcher) {
        super.setUp();

        onetimeDispatcher = new OnetimeLockRequestDispatcher(address(this));
    }

    function testSubmitTransfer() public {
        OnetimeLockRequest memory request = OnetimeLockRequest({
            id: 0,
            amount: 100,
            token: address(token),
            secretHash1: SecretUtil.hashSecret(address(onetimeDispatcher), secret, 1),
            secretHash2: SecretUtil.hashSecret(address(onetimeDispatcher), secret, 2),
            expiry: block.timestamp + 1000,
            metadata: ""
        });

        vm.startPrank(sender);

        token.approve(address(onetimeDispatcher), 100);
        onetimeDispatcher.submitRequest(request);

        vm.stopPrank();

        onetimeDispatcher.setRecipient(request.hash(), secret, recipient);

        onetimeDispatcher.completeRequest(request.hash(), secret);

        assertEq(token.balanceOf(recipient), 100);
    }
}
