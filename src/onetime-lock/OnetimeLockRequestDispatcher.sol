// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../transferWithSecret/TransferWithSecretRequest.sol";
import "permit2/lib/solmate/src/tokens/ERC20.sol";
import "permit2/src/interfaces/ISignatureTransfer.sol";
import "permit2/src/interfaces/IPermit2.sol";
import "permit2/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../libraries/SecretUtil.sol";

contract OnetimeLockRequestDispatcher {
    using TransferWithSecretRequestLib for TransferWithSecretRequest;

    enum RequestStatus {
        NotSubmitted,
        Pending,
        Completed,
        Cancelled
    }

    struct PendingRequest {
        uint256 amount;
        address token;
        address publicKey;
        address sender;
        uint256 nonce;
        uint256 expiry;
        RequestStatus status;
    }

    mapping(bytes32 => PendingRequest) public pendingRequests;

    uint256 private constant MAX_EXPIRY = 180 days;

    address public facilitator;
    IPermit2 permit2;

    error RequestAlreadyExists();
    error RequestExpired();
    error RequestNotExpired();
    error RequestIsNotPending();
    error RecipientNotSet();
    error InvalidSecret();
    error CallerIsNotSenderOrFacilitator();
    error InvalidDispatcher();
    error DeadlinePassed();

    struct RecipientData {
        address recipient;
        bytes sig;
        bytes metadata;
    }

    event RequestSubmitted(bytes32 id, address token, address sender, uint256 amount, uint256 expiry, bytes metadata);
    event RequestCompleted(bytes32 id, address recipient, bytes metadata);
    event RequestCancelled(bytes32 id);

    modifier onlyFacilitator() {
        require(msg.sender == facilitator, "Only facilitator");
        _;
    }

    constructor(address _permit2, address _facilitator) {
        permit2 = IPermit2(_permit2);
        facilitator = _facilitator;
    }

    function submitRequest(TransferWithSecretRequest memory request, bytes memory sig) public {
        bytes32 id = request.getId();

        if (pendingRequests[id].status != RequestStatus.NotSubmitted) {
            revert RequestAlreadyExists();
        }

        require(request.deadline > 0);
        require(request.deadline <= block.timestamp + MAX_EXPIRY);
        require(request.amount > 0);

        _verifySenderRequest(request, sig);

        pendingRequests[id] = PendingRequest({
            amount: request.amount,
            token: request.token,
            publicKey: request.publicKey,
            sender: request.sender,
            nonce: request.nonce,
            expiry: request.deadline,
            status: RequestStatus.Pending
        });

        emit RequestSubmitted(id, request.token, request.sender, request.amount, request.deadline, request.metadata);
    }

    function completeRequest(bytes32 id, RecipientData memory recipientData) public {
        PendingRequest storage request = pendingRequests[id];

        if (recipientData.recipient == address(0)) {
            revert RecipientNotSet();
        }

        if (request.status != RequestStatus.Pending) {
            revert RequestIsNotPending();
        }

        if (request.expiry < block.timestamp) {
            revert RequestExpired();
        }

        _verifyRecipientSignature(request.nonce, request.publicKey, recipientData.recipient, recipientData.sig);

        uint256 amount = request.amount;

        request.amount = 0;
        request.status = RequestStatus.Completed;

        ERC20(request.token).transfer(recipientData.recipient, amount);

        emit RequestCompleted(id, recipientData.recipient, recipientData.metadata);
    }

    function cancelRequest(bytes32 id) public {
        PendingRequest storage request = pendingRequests[id];

        if (request.status != RequestStatus.Pending) {
            revert RequestIsNotPending();
        }

        require(request.expiry > 0, "Expiry not set");

        if (block.timestamp < request.expiry) {
            revert RequestNotExpired();
        }

        if (msg.sender != request.sender && msg.sender != facilitator) {
            revert CallerIsNotSenderOrFacilitator();
        }

        uint256 amount = request.amount;

        request.amount = 0;
        request.status = RequestStatus.Cancelled;

        ERC20(request.token).transfer(request.sender, amount);

        emit RequestCancelled(id);
    }

    function getRequestId(TransferWithSecretRequest memory request) external view returns (bytes32) {
        return request.getId();
    }

    /**
     * @notice Verifies the request and the signature.
     */
    function _verifySenderRequest(TransferWithSecretRequest memory request, bytes memory sig) internal {
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

    /**
     * @notice Verifies the signature made by the recipient using the private key received from the sender.
     */
    function _verifyRecipientSignature(uint256 nonce, address publicKey, address recipient, bytes memory signature)
        internal
        view
    {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(abi.encode(address(this), nonce, recipient)));

        if (publicKey != ECDSA.recover(messageHash, signature)) {
            revert InvalidSecret();
        }
    }
}
