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

    uint256 private constant MAX_EXPIRY = 180 days;

    address public facilitator;

    error RequestAlreadyExists();
    error RequestExpired();
    error RequestNotSubmitted();
    error RecipientAlreadySet();
    error RecipientNotSet();
    error InvalidSecret();
    error CallerIsNotSenderOrFacilitator();

    event RequestSubmitted(bytes32 id, address sender, address token, uint256 amount, uint256 expiry, bytes metadata);
    event RecipientUpdated(bytes32 id, address recipient, bytes metadata);
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
        require(request.expiry <= block.timestamp + MAX_EXPIRY);

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

    function setRecipient(bytes32 id, bytes32 secret, address recipient, bytes memory metadata)
        public
        onlyFacilitator
    {
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
            revert RequestExpired();
        }

        request.recipient = recipient;

        emit RecipientUpdated(id, recipient, metadata);
    }

    function completeRequest(bytes32 id, bytes32 secret) public {
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
            revert RequestExpired();
        }

        uint256 amount = request.amount;

        request.amount = 0;

        ERC20(request.token).transfer(request.recipient, amount);

        emit RequestCompleted(id);
    }

    function cancelRequest(bytes32 id) public {
        PendingRequest storage request = pendingRequests[id];

        require(block.timestamp > request.expiry, "Request not expired");

        if (request.sender != msg.sender && facilitator != msg.sender) {
            revert CallerIsNotSenderOrFacilitator();
        }

        uint256 amount = request.amount;

        request.amount = 0;

        ERC20(request.token).transfer(request.sender, amount);

        emit RequestCancelled(id);
    }
}
