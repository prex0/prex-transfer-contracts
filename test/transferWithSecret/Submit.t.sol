// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Setup.t.sol";

contract TestSubmit is TestRequestDispatcher {
    using TransferWithSecretRequestLib for TransferWithSecretRequest;

    function setUp() public virtual override(TestRequestDispatcher) {
        super.setUp();
    }

    function testSubmit() public {
        uint256 tmpPrivKey = 11111000002;
        address tmpPublicKey = vm.addr(tmpPrivKey);

        TransferWithSecretRequest memory request = TransferWithSecretRequest({
            dispatcher: address(dispatcher),
            sender: sender,
            deadline: block.timestamp + 1000,
            nonce: 0,
            amount: 100,
            token: address(token),
            publicKey: tmpPublicKey,
            metadata: ""
        });

        bytes memory sig = _sign(request, privateKey);

        TransferWithSecretRequestDispatcher.RecipientData memory recipientData = TransferWithSecretRequestDispatcher.RecipientData({
            recipient: from2,
            sig: _signMessage(
                tmpPrivKey,
                keccak256(abi.encode(address(dispatcher), request.nonce, from2))
            ),
            metadata: ""
        });

        uint256 amountBefore = token.balanceOf(from2);
        dispatcher.submitRequest(request, sig, recipientData);
        uint256 amountAfter = token.balanceOf(from2);


        assertEq(amountAfter - amountBefore, 100);
    }
}
