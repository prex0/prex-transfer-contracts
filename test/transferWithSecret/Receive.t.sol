// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Setup.t.sol";

contract TestSubmit is TestRequestDispatcher {
    using TransferWithSecretRequestLib for TransferWithSecretRequest;

    TransferWithSecretRequest request;
    bytes32 secret = keccak256(abi.encodePacked("secret"));

    function setUp() public virtual override(TestRequestDispatcher) {
        super.setUp();

        request = TransferWithSecretRequest({
            dispatcher: address(dispatcher),
            sender: sender,
            deadline: block.timestamp + 1000,
            nonce: 0,
            amount: 100,
            token: address(token),
            secretHash: keccak256(abi.encode(address(dispatcher), secret)),
            metadata: ""
        });

        bytes memory sig = _sign(request, privateKey);

        dispatcher.submitRequest(request, sig, address(this));
    }

    function testComplete() public {
        dispatcher.completeRequest(request.hash(), secret);
    }
}
