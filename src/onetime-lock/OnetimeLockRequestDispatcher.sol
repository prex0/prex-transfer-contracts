// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../transferWithSecret/TransferWithSecretRequest.sol";
import "permit2/lib/solmate/src/tokens/ERC20.sol";
import "permit2/src/interfaces/ISignatureTransfer.sol";
import "permit2/src/interfaces/IPermit2.sol";
import "permit2/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../libraries/SecretUtil.sol";
import "solmate/src/utils/ReentrancyGuard.sol";
import "../MultiFacilitators.sol";

/**
 * @notice OnetimeLockRequestDispatcher is a contract that allows the sender to create a request with a secret key.
 * The recipient can complete the request by providing the signature of the secret key.
 * This contract integrates with the Permit2 library to handle ERC20 token transfers securely and efficiently.
 */
contract OnetimeLockRequestDispatcher is ReentrancyGuard, MultiFacilitators {
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

    IPermit2 immutable permit2;

    error RequestAlreadyExists();
    error RequestExpired();
    error RequestNotExpired();
    error RequestIsNotPending();
    error RecipientNotSet();
    error InvalidSecret();
    error InvalidDispatcher();
    error InvalidDeadline();
    error InvalidAmount();
    error DeadlinePassed();
    error TransferFailed();

    struct RecipientData {
        address recipient;
        bytes sig;
        bytes metadata;
    }

    event RequestSubmitted(bytes32 id, address token, address sender, uint256 amount, uint256 expiry, bytes metadata);
    event RequestCompleted(bytes32 id, address recipient, bytes metadata);
    event RequestCancelled(bytes32 id);

    constructor(address _permit2, address _admin) MultiFacilitators(_admin) {
        permit2 = IPermit2(_permit2);
    }

    /**
     * @notice Submits a new transfer request.
     * This function is executed by the sender after they receive the signature from the recipient.
     */
    function submitRequest(TransferWithSecretRequest memory request, bytes memory sig)
        external
        nonReentrant
        onlyFacilitators
    {
        bytes32 id = request.getId();

        if (pendingRequests[id].status != RequestStatus.NotSubmitted) {
            revert RequestAlreadyExists();
        }

        if (request.deadline == 0) {
            revert InvalidDeadline();
        }

        if (request.deadline > block.timestamp + MAX_EXPIRY) {
            revert InvalidDeadline();
        }

        if (request.amount == 0) {
            revert InvalidAmount();
        }

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

    /**
     * @notice Completes a pending request.
     * This function is executed by the recipient after they receive the secret from the sender.
     */
    function completeRequest(bytes32 id, RecipientData memory recipientData) external nonReentrant onlyFacilitators {
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

        if (!ERC20(request.token).transfer(recipientData.recipient, amount)) {
            revert TransferFailed();
        }

        emit RequestCompleted(id, recipientData.recipient, recipientData.metadata);
    }

    /**
     * @notice Cancels pending requests.
     */
    function batchCancelRequest(bytes32[] memory ids) external nonReentrant onlyFacilitators {
        for (uint256 i = 0; i < ids.length; i++) {
            cancelRequest(ids[i]);
        }
    }

    function cancelRequest(bytes32 id) internal {
        PendingRequest storage request = pendingRequests[id];

        if (request.status != RequestStatus.Pending) {
            revert RequestIsNotPending();
        }

        require(request.expiry > 0, "Expiry not set");

        if (block.timestamp < request.expiry) {
            revert RequestNotExpired();
        }

        uint256 amount = request.amount;

        request.amount = 0;
        request.status = RequestStatus.Cancelled;

        if (!ERC20(request.token).transfer(request.sender, amount)) {
            revert TransferFailed();
        }

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
