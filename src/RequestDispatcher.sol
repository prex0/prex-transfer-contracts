// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./TransferRequest.sol";

interface IPermit2 {
}

contract RequestDispatcher {
    using TransferRequestLib for TransferRequest;

    struct PendingRequest {
        uint256 amount;
        address token;
        bytes32 secretHash;
        address sender;
        address recipient;
        uint256 deadline;
    }

    mapping(bytes32 => PendingRequest) public pendingRequests;
    IPermit2 private _permit2;

    function submitRequest(TransferRequest memory request, bytes memory sig, address recipent) public {
        _verifyRequest(request, sig);

        bytes32 id = request.hash();

        pendingRequests[id] = PendingRequest({
            amount: request.amount,
            token: request.token,
            secretHash: request.secretHash,
            sender: request.sender,
            recipient: recipent,
            deadline: block.timestamp + 1 days
        });
    }

    function completeRequest(bytes32 id, bytes32 secret) public {
        PendingRequest memory request = pendingRequests[id];

        require(keccak256(abi.encodePacked(secret)) == request.secretHash, "Invalid secret");

        ERC20(request.token).transfer(request.recipient, request.amount);

        delete pendingRequests[id];
    }

    function cancelRequest(bytes32 id) public {
        PendingRequest memory request = pendingRequests[id];

        require(block.timestamp > request.deadline, "Request not expired");

        ERC20(request.token).transfer(request.sender, request.amount);

        delete pendingRequests[id];
    }

    function _verifyRequest(TransferRequest memory request, bytes memory sig) internal {
        if (address(this) != address(request.dispatcher)) {
            revert InvalidMarket();
        }

        if (block.timestamp > request.deadline) {
            revert DeadlinePassed();
        }

        _permit2.permitWitnessTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: request.token, amount: request.amount}),
                nonce: order.nonce,
                deadline: order.deadline
            }),
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: request.amount}),
            request.sender,
            request.hash(),
            TransferRequestLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }
}
