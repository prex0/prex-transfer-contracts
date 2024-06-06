// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Setup.t.sol";

contract TestSubmit is TestRequestDispatcher {
    using TransferRequestLib for TransferRequest;

    function setUp() public virtual override(TestRequestDispatcher){
        super.setUp();
    }

    function testSubmit() public {
        TransferRequest memory request = TransferRequest({
            dispatcher: address(dispatcher),
            sender: sender,
            deadline: block.timestamp + 1000,
            nonce: 0,
            amount: 100,
            token: address(token),
            secretHash: keccak256(abi.encodePacked("secret"))
        });

        bytes memory sig = _sign(request, privateKey);

        dispatcher.submitRequest(request, sig, address(this));

        (
            uint256 amount,
            address token,
            bytes32 secretHash,
            address sender,
            address recipient,
            uint256 deadline
        ) = dispatcher.pendingRequests(request.sender, request.nonce);

        assertEq(amount, 100);
    }

}
