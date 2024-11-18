// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Setup.t.sol";

contract TestSubmit is TestOnetimeLockRequestDispatcher {
    using TransferWithSecretRequestLib for TransferWithSecretRequest;

    uint256 privKeyAlreadyUsed = 11111000005;

    function setUp() public virtual override(TestOnetimeLockRequestDispatcher) {
        super.setUp();

        address tmpPublicKey = vm.addr(privKeyAlreadyUsed);

        TransferWithSecretRequest memory request = TransferWithSecretRequest({
            dispatcher: address(ontimeLockDispatcher),
            sender: sender,
            deadline: block.timestamp + 1000,
            nonce: 100,
            amount: 100,
            token: address(token),
            publicKey: tmpPublicKey,
            metadata: ""
        });

        bytes memory sig = _sign(request, privateKey);

        ontimeLockDispatcher.submitRequest(request, sig);
    }

    function testSubmit() public {
        uint256 tmpPrivKey = 11111000002;
        address tmpPublicKey = vm.addr(tmpPrivKey);

        TransferWithSecretRequest memory request = TransferWithSecretRequest({
            dispatcher: address(ontimeLockDispatcher),
            sender: sender,
            deadline: block.timestamp + 1000,
            nonce: 0,
            amount: 100,
            token: address(token),
            publicKey: tmpPublicKey,
            metadata: ""
        });

        bytes memory sig = _sign(request, privateKey);

        ontimeLockDispatcher.submitRequest(request, sig);

        bytes32 id = ontimeLockDispatcher.getRequestId(request);

        {
            // check reverts if private key is invalid
            OnetimeLockRequestDispatcher.RecipientData memory recipientData = OnetimeLockRequestDispatcher.RecipientData({
                recipient: from2,
                sig: _signMessage(privateKey2, keccak256(abi.encode(address(ontimeLockDispatcher), request.nonce, from2))),
                metadata: ""
            });

            vm.expectRevert(OnetimeLockRequestDispatcher.InvalidSecret.selector);
            ontimeLockDispatcher.completeRequest(id, recipientData);
        }

        {
            OnetimeLockRequestDispatcher.RecipientData memory recipientData = OnetimeLockRequestDispatcher.RecipientData({
                recipient: from2,
                sig: _signMessage(tmpPrivKey, keccak256(abi.encode(address(ontimeLockDispatcher), request.nonce, from2))),
                metadata: ""
            });

            uint256 amountBefore = token.balanceOf(from2);
            ontimeLockDispatcher.completeRequest(id, recipientData);
            uint256 amountAfter = token.balanceOf(from2);

            assertEq(amountAfter - amountBefore, 100);
        }
    }

    function testCannotSubmitIfAmountIsZero() public {
        uint256 tmpPrivKey = 11111000002;
        address tmpPublicKey = vm.addr(tmpPrivKey);

        TransferWithSecretRequest memory request = TransferWithSecretRequest({
            dispatcher: address(ontimeLockDispatcher),
            sender: sender,
            deadline: block.timestamp + 1000,
            nonce: 0,
            amount: 0,
            token: address(token),
            publicKey: tmpPublicKey,
            metadata: ""
        });

        bytes memory sig = _sign(request, privateKey);

        vm.expectRevert(OnetimeLockRequestDispatcher.InvalidAmount.selector);
        ontimeLockDispatcher.submitRequest(request, sig);
    }

    function testCannotSubmitIfSamePublicKeyIsUsed() public {
        address tmpPublicKey = vm.addr(privKeyAlreadyUsed);

        TransferWithSecretRequest memory request = TransferWithSecretRequest({
            dispatcher: address(ontimeLockDispatcher),
            sender: sender,
            deadline: block.timestamp + 1000,
            nonce: 0,
            amount: 100,
            token: address(token),
            publicKey: tmpPublicKey,
            metadata: ""
        });

        bytes memory sig = _sign(request, privateKey);

        vm.expectRevert(OnetimeLockRequestDispatcher.PublicKeyAlreadyExists.selector);
        ontimeLockDispatcher.submitRequest(request, sig);
    }

    function testCannotSubmitIfDeadlineIsInvalid() public {
        uint256 tmpPrivKey = 11111000002;
        address tmpPublicKey = vm.addr(tmpPrivKey);

        TransferWithSecretRequest memory request = TransferWithSecretRequest({
            dispatcher: address(ontimeLockDispatcher),
            sender: sender,
            deadline: block.timestamp + 200 days,
            nonce: 0,
            amount: 100,
            token: address(token),
            publicKey: tmpPublicKey,
            metadata: ""
        });

        bytes memory sig = _sign(request, privateKey);

        vm.expectRevert(OnetimeLockRequestDispatcher.InvalidDeadline.selector);
        ontimeLockDispatcher.submitRequest(request, sig);
    }

    function testCannotSubmitIfCallerIsNotFacilitator() public {
        uint256 tmpPrivKey = 11111000002;
        address tmpPublicKey = vm.addr(tmpPrivKey);

        TransferWithSecretRequest memory request = TransferWithSecretRequest({
            dispatcher: address(ontimeLockDispatcher),
            sender: sender,
            deadline: block.timestamp + 1000,
            nonce: 0,
            amount: 100,
            token: address(token),
            publicKey: tmpPublicKey,
            metadata: ""
        });

        bytes memory sig = _sign(request, privateKey);

        vm.startPrank(from2);
        vm.expectRevert(MultiFacilitators.CallerIsNotFacilitator.selector);
        ontimeLockDispatcher.submitRequest(request, sig);

        vm.stopPrank();
    }

    function testCancel() public {
        uint256 tmpPrivKey = 11111000002;
        address tmpPublicKey = vm.addr(tmpPrivKey);

        TransferWithSecretRequest memory request = TransferWithSecretRequest({
            dispatcher: address(ontimeLockDispatcher),
            sender: sender,
            deadline: block.timestamp + 1000,
            nonce: 0,
            amount: 100,
            token: address(token),
            publicKey: tmpPublicKey,
            metadata: ""
        });

        bytes memory sig = _sign(request, privateKey);

        ontimeLockDispatcher.submitRequest(request, sig);

        bytes32 id = ontimeLockDispatcher.getRequestId(request);

        bytes32[] memory ids = new bytes32[](1);
        ids[0] = id;

        vm.expectRevert(OnetimeLockRequestDispatcher.RequestNotExpired.selector);
        ontimeLockDispatcher.batchCancelRequest(ids);

        vm.warp(block.timestamp + 1001);

        uint256 amountBefore = token.balanceOf(sender);
        ontimeLockDispatcher.batchCancelRequest(ids);
        uint256 amountAfter = token.balanceOf(sender);

        assertEq(amountAfter - amountBefore, 100);
    }
}
