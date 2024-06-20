// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Setup.t.sol";

contract TestSubmit is TestRequestDispatcher {
    using TransferWithSecretRequestLib for TransferWithSecretRequest;

    function setUp() public virtual override(TestRequestDispatcher) {
        super.setUp();
    }

    function testSubmit() public {
        TransferWithSecretRequest memory request = TransferWithSecretRequest({
            dispatcher: address(dispatcher),
            sender: sender,
            deadline: block.timestamp + 1000,
            nonce: 0,
            amount: 100,
            token: address(token),
            secretHash: keccak256(abi.encodePacked("secret")),
            metadata: ""
        });

        bytes memory sig = _sign(request, privateKey);

        dispatcher.submitRequest(request, sig, address(this));

        (uint256 amount, address token, bytes32 secretHash, address sender, address recipient, uint256 deadline) =
            dispatcher.pendingRequests(request.hash());

        assertEq(amount, 100);
    }
}
