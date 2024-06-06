// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./TransferRequest.sol";
import "../lib/permit2/src/ISignatureTransfer.sol";
import "../lib/permit2/src/IPermit2.sol";

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

    error InvalidDispatcher();
    error DeadlinePassed();

    event RequestSubmitted(bytes32 id, address sender, address recipient, uint256 amount, address token, uint256 deadline);
    event RequestCompleted(bytes32 id, address sender, address recipient, uint256 amount, address token);
    event RequestCancelled(bytes32 id, address sender, address recipient, uint256 amount, address token);

    constructor(IPermit2 permit2) {
        _permit2 = permit2;
    }

    function submitRequest(TransferRequest memory request, bytes memory sig, address recipent) public {
        _verifyRequest(request, sig);

        bytes32 id = request.hash();

        pendingRequests[id] = PendingRequest({
            amount: request.amount,
            token: request.token,
            secretHash: request.secretHash,
            sender: request.sender,
            recipient: recipent,
            deadline: request.deadline
        });

        emit RequestSubmitted(id, request.sender, recipent, request.amount, request.token, request.deadline);
    }

    function completeRequest(bytes32 id, bytes32 secret) public {
        PendingRequest memory request = pendingRequests[id];

        require(keccak256(abi.encodePacked(secret)) == request.secretHash, "Invalid secret");

        ERC20(request.token).transfer(request.recipient, request.amount);

        emit RequestCompleted(id, request.sender, request.recipient, request.amount, request.token);

        delete pendingRequests[id];
    }

    function cancelRequest(bytes32 id) public {
        PendingRequest memory request = pendingRequests[id];

        require(block.timestamp > request.deadline, "Request not expired");

        ERC20(request.token).transfer(request.sender, request.amount);

        emit RequestCancelled(id, request.sender, request.recipient, request.amount, request.token);

        delete pendingRequests[id];
    }

    function _verifyRequest(TransferRequest memory request, bytes memory sig) internal {
        if (address(this) != address(request.dispatcher)) {
            revert InvalidDispatcher();
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
