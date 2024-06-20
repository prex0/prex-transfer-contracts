// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./TransferWithSecretRequest.sol";
import "permit2/lib/solmate/src/tokens/ERC20.sol";
import "permit2/src/interfaces/ISignatureTransfer.sol";
import "permit2/src/interfaces/IPermit2.sol";

contract TransferWithSecretRequestDispatcher {
    using TransferWithSecretRequestLib for TransferWithSecretRequest;

    struct PendingRequest {
        uint256 amount;
        address token;
        bytes32 secretHash;
        address sender;
        address recipient;
        uint256 deadline;
    }

    mapping(bytes32 => PendingRequest) public pendingRequests;

    IPermit2 permit2;
    address public facilitator;

    error InvalidDispatcher();
    error DeadlinePassed();

    event RequestSubmitted(
        bytes32 id, address sender, address recipient, address token, uint256 amount, bytes metadata
    );
    event RequestCompleted(bytes32 id);
    event RequestCancelled(bytes32 id);

    modifier onlyFacilitator() {
        require(msg.sender == facilitator, "Only facilitator");
        _;
    }

    constructor(address _permit2, address _facilitator) {
        permit2 = IPermit2(_permit2);
        facilitator = _facilitator;
    }

    function submitRequest(TransferWithSecretRequest memory request, bytes memory sig, address recipent)
        public
        onlyFacilitator
    {
        _verifyRequest(request, sig);

        bytes32 id = request.hash();

        if (pendingRequests[id].amount != 0) {
            revert("Request already exists");
        }

        pendingRequests[id] = PendingRequest({
            amount: request.amount,
            token: request.token,
            secretHash: request.secretHash,
            sender: request.sender,
            recipient: recipent,
            deadline: request.deadline
        });

        emit RequestSubmitted(id, request.sender, recipent, request.token, request.amount, request.metadata);
    }

    function completeRequest(bytes32 id, bytes32 secret) public {
        PendingRequest storage request = pendingRequests[id];

        require(keccak256(abi.encode(address(this), secret)) == request.secretHash, "Invalid secret");

        uint256 amount = request.amount;

        request.amount = 0;

        ERC20(request.token).transfer(request.recipient, amount);

        emit RequestCompleted(id);
    }

    function cancelRequest(bytes32 id) public {
        PendingRequest storage request = pendingRequests[id];

        require(block.timestamp > request.deadline, "Request not expired");

        uint256 amount = request.amount;

        request.amount = 0;

        ERC20(request.token).transfer(request.sender, amount);

        emit RequestCancelled(id);
    }

    function _verifyRequest(TransferWithSecretRequest memory request, bytes memory sig) internal {
        if (address(this) != address(request.dispatcher)) {
            revert InvalidDispatcher();
        }

        if (block.timestamp > request.deadline) {
            revert DeadlinePassed();
        }

        permit2.permitWitnessTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: request.token, amount: request.amount}),
                nonce: request.nonce,
                deadline: request.deadline
            }),
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: request.amount}),
            request.sender,
            request.hash(),
            TransferWithSecretRequestLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }
}
