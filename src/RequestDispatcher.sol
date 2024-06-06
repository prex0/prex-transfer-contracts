// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./TransferRequest.sol";
import "../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import "../lib/permit2/src/interfaces/IPermit2.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

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

    mapping(address => mapping(uint256 => PendingRequest)) public pendingRequests;

    IPermit2 private _permit2;

    error InvalidDispatcher();
    error DeadlinePassed();

    event RequestSubmitted(address sender, uint256 nonce, address recipient, uint256 amount, address token, uint256 deadline);
    event RequestCompleted(address sender, address recipient, uint256 amount, address token);
    event RequestCancelled(address sender, address recipient, uint256 amount, address token);

    constructor(IPermit2 permit2) {
        _permit2 = permit2;
    }

    function submitRequest(TransferRequest memory request, bytes memory sig, address recipent) public {
        _verifyRequest(request, sig);

        if(pendingRequests[request.sender][request.nonce].amount != 0) {
            revert("Request already exists");
        }

        pendingRequests[request.sender][request.nonce] = PendingRequest({
            amount: request.amount,
            token: request.token,
            secretHash: request.secretHash,
            sender: request.sender,
            recipient: recipent,
            deadline: request.deadline
        });

        emit RequestSubmitted(request.sender, request.nonce, recipent, request.amount, request.token, request.deadline);
    }

    function completeRequest(address sender, uint256 nonce, bytes32 secret) public {
        PendingRequest memory request = pendingRequests[sender][nonce];

        require(keccak256(abi.encode(
            address(this),
            secret
        )) == request.secretHash, "Invalid secret");

        ERC20(request.token).transfer(request.recipient, request.amount);

        emit RequestCompleted(request.sender, request.recipient, request.amount, request.token);

        delete pendingRequests[sender][nonce];
    }

    function cancelRequest(address sender, uint256 nonce) public {
        PendingRequest memory request = pendingRequests[sender][nonce];

        require(block.timestamp > request.deadline, "Request not expired");

        ERC20(request.token).transfer(request.sender, request.amount);

        emit RequestCancelled(request.sender, request.recipient, request.amount, request.token);

        delete pendingRequests[sender][nonce];
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
                nonce: request.nonce,
                deadline: request.deadline
            }),
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: request.amount}),
            request.sender,
            request.hash(),
            TransferRequestLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }
}
