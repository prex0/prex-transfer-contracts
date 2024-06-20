// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./OnetimeLockRequest.sol";
import "permit2/lib/solmate/src/tokens/ERC20.sol";
import "permit2/src/interfaces/ISignatureTransfer.sol";
import "permit2/src/interfaces/IPermit2.sol";
import "../libraries/SecretUtil.sol";

contract OnetimeLockRequestDispatcher {
    using OnetimeLockRequestLib for OnetimeLockRequest;

    struct PendingRequest {
        uint256 amount;
        address token;
        bytes32 secretHash1;
        bytes32 secretHash2;
        address sender;
        address recipient;
        uint256 expiry;
    }

    mapping(bytes32 => PendingRequest) public pendingRequests;

    address public facilitator;

    error RequestAlreadyExists();
    error Expired();
    error RequestNotSubmitted();
    error RecipientAlreadySet();
    error RecipientNotSet();
    error InvalidSecret();

    event RequestSubmitted(bytes32 id, address sender, address token, uint256 amount, uint256 expiry, bytes metadata);
    event RecipientUpdated(bytes32 id, address recipient);
    event RequestCompleted(bytes32 id);
    event RequestCancelled(bytes32 id);

    modifier onlyFacilitator() {
        require(msg.sender == facilitator, "Only facilitator");
        _;
    }

    constructor(address _facilitator) {
        facilitator = _facilitator;
    }

    function submitRequest(OnetimeLockRequest memory request) public {
        bytes32 id = request.hash();

        if (pendingRequests[id].expiry > 0) {
            revert RequestAlreadyExists();
        }

        require(request.expiry > 0);

        pendingRequests[id] = PendingRequest({
            amount: request.amount,
            token: request.token,
            secretHash1: request.secretHash1,
            secretHash2: request.secretHash2,
            sender: msg.sender,
            recipient: address(0),
            expiry: request.expiry
        });

        ERC20(request.token).transferFrom(msg.sender, address(this), request.amount);

        emit RequestSubmitted(id, msg.sender, request.token, request.amount, request.expiry, request.metadata);
    }

    function setRecipient(bytes32 id, bytes32 secret, address recipient) public onlyFacilitator {
        PendingRequest storage request = pendingRequests[id];

        if (SecretUtil.hashSecret(secret, 1) != request.secretHash1) {
            revert InvalidSecret();
        }

        if (request.recipient != address(0)) {
            revert RecipientAlreadySet();
        }

        if (request.expiry == 0) {
            revert RequestNotSubmitted();
        }

        if (request.expiry < block.timestamp) {
            revert Expired();
        }

        request.recipient = recipient;

        emit RecipientUpdated(id, recipient);
    }

    function completeRequest(bytes32 id, bytes32 secret) public onlyFacilitator {
        PendingRequest storage request = pendingRequests[id];

        if (SecretUtil.hashSecret(secret, 2) != request.secretHash2) {
            revert InvalidSecret();
        }

        if (request.recipient == address(0)) {
            revert RecipientNotSet();
        }

        if (request.expiry == 0) {
            revert RequestNotSubmitted();
        }

        if (request.expiry < block.timestamp) {
            revert Expired();
        }

        uint256 amount = request.amount;

        request.amount = 0;

        ERC20(request.token).transfer(request.recipient, amount);

        emit RequestCompleted(id);
    }

    function cancelRequest(bytes32 id) public {
        PendingRequest storage request = pendingRequests[id];

        require(block.timestamp > request.expiry, "Request not expired");

        uint256 amount = request.amount;

        request.amount = 0;

        ERC20(request.token).transfer(request.sender, amount);

        emit RequestCancelled(id);
    }
}
