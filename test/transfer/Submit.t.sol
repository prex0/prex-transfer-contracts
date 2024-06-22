// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Setup.t.sol";

contract TestSubmitTransfer is TestTransferRequestDispatcher {
    using TransferRequestLib for TransferRequest;

    function setUp() public virtual override(TestTransferRequestDispatcher) {
        super.setUp();
    }

    function testSubmitTransfer() public {
        TransferRequest memory request = TransferRequest({
            dispatcher: address(dispatcher),
            sender: sender,
            recipient: address(this),
            deadline: block.timestamp + 1000,
            nonce: 0,
            amount: 100,
            token: address(token)
        });

        bytes memory sig = _sign(request, privateKey);

        uint256 balance0 = token.balanceOf(address(this));

        dispatcher.submitTransfer(request, sig, "");

        uint256 balance1 = token.balanceOf(address(this));

        assertEq(balance1 - balance0, 100);
    }
}
