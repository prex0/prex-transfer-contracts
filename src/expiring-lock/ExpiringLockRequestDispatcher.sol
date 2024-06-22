// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ExpiringLockRequest.sol";
import "permit2/lib/solmate/src/tokens/ERC20.sol";

contract ExpiringLockRequestDispatcher {
    using ExpiringLockRequestLib for ExpiringLockRequest;

    struct PendingRequest {
        uint256 amount;
        uint256 amountPerWithdrawal;
        address token;
        address sender;
        uint256 expiry;
        bool isLimitedByAddress;
    }

    mapping(bytes32 => PendingRequest) public pendingRequests;
    mapping(bytes32 => mapping(address => bool)) public isDistributed;

    address public facilitator;

    error AlreadyExist();
    error RequestExpired();
    error InsufficientFunds();
    error AlreadyDistributed(address recipient);
    error OnlySenderCanCancel();
    error RequestNotExpired();

    event Submitted(
        bytes32 id,
        address sender,
        address token,
        uint256 amount,
        uint256 amountPerWithdrawal,
        uint256 expiry,
        bytes metadata
    );
    event Deposited(bytes32 id, address depositor, uint256 amount, bytes metadata);
    event Received(bytes32 id, address recipient, uint256 amount, bytes metadata);
    event RequestCancelled(bytes32 id, uint256 amount);
    event RequestCompleted(bytes32 id, uint256 amount);

    modifier onlyFacilitator() {
        require(msg.sender == facilitator, "Only facilitator");
        _;
    }

    constructor(address _facilitator) {
        facilitator = _facilitator;
    }

    function submit(ExpiringLockRequest memory request) public {
        bytes32 id = request.hash();

        if (pendingRequests[id].expiry > 0) {
            revert AlreadyExist();
        }

        require(request.expiry > 0);

        pendingRequests[id] = PendingRequest({
            amount: request.amount,
            amountPerWithdrawal: request.amountPerWithdrawal,
            token: request.token,
            sender: msg.sender,
            expiry: request.expiry,
            isLimitedByAddress: request.isLimitedByAddress
        });

        ERC20(request.token).transferFrom(msg.sender, address(this), request.amount);

        emit Submitted(
            id, msg.sender, request.token, request.amount, request.amountPerWithdrawal, request.expiry, request.metadata
        );
    }

    function deposit(bytes32 id, uint256 amount, bytes memory metadata) public {
        PendingRequest storage request = pendingRequests[id];

        if (block.timestamp > request.expiry) {
            revert RequestExpired();
        }

        request.amount += amount;

        ERC20(request.token).transferFrom(msg.sender, address(this), amount);

        emit Deposited(id, msg.sender, amount, metadata);
    }

    function distribute(bytes32 id, address recipient, bytes memory metadata) public onlyFacilitator {
        PendingRequest storage request = pendingRequests[id];

        if (block.timestamp > request.expiry) {
            revert RequestExpired();
        }

        if (request.amount < request.amountPerWithdrawal) {
            revert InsufficientFunds();
        }

        if (request.isLimitedByAddress && isDistributed[id][recipient]) {
            revert AlreadyDistributed(recipient);
        }

        request.amount -= request.amountPerWithdrawal;

        isDistributed[id][recipient] = true;

        ERC20(request.token).transfer(recipient, request.amountPerWithdrawal);

        emit Received(id, recipient, request.amountPerWithdrawal, metadata);
    }

    function cancelRequest(bytes32 id) public {
        PendingRequest storage request = pendingRequests[id];

        if (request.sender != msg.sender) {
            revert OnlySenderCanCancel();
        }

        uint256 leftAmount = request.amount;

        request.amount = 0;

        ERC20(request.token).transfer(request.sender, leftAmount);

        emit RequestCancelled(id, leftAmount);
    }

    function completeRequest(bytes32 id) public {
        PendingRequest storage request = pendingRequests[id];

        if (block.timestamp <= request.expiry) {
            revert RequestNotExpired();
        }

        uint256 leftAmount = request.amount;

        request.amount = 0;

        ERC20(request.token).transfer(request.sender, leftAmount);

        emit RequestCompleted(id, leftAmount);
    }
}
