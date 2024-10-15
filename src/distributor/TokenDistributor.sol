// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./TokenDistributeSubmitRequest.sol";
import "./TokenDistributeDepositRequest.sol";
import "permit2/lib/solmate/src/tokens/ERC20.sol";
import "permit2/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "permit2/src/interfaces/IPermit2.sol";
import "../MultiFacilitatorsUpgradable.sol";
import "solmate/src/utils/ReentrancyGuard.sol";
import "./CoolTimeLib.sol";
import "./IAdditionalValidator.sol";

/**
 * @notice TokenDistributor is a contract that allows senders to create multiple distribution requests.
 * Each request can have multiple recipients who can claim their allocated tokens.
 * Recipients complete their claims by providing the signature of a secret key associated with the request.
 * This contract integrates with the Permit2 library to handle ERC20 token transfers securely and efficiently.
 * It supports multiple concurrent requests, enabling flexible and scalable token distribution scenarios.
 */
contract TokenDistributor is ReentrancyGuard, MultiFacilitatorsUpgradable {
    using TokenDistributeSubmitRequestLib for TokenDistributeSubmitRequest;
    using TokenDistributeDepositRequestLib for TokenDistributeDepositRequest;
    using CoolTimeLib for CoolTimeLib.DistributionInfo;

    enum RequestStatus {
        NotSubmitted,
        Pending,
        Cancelled,
        Completed
    }

    struct PendingRequest {
        uint256 amount;
        uint256 amountPerWithdrawal;
        uint256 cooltime;
        uint256 maxAmountPerAddress;
        address token;
        address publicKey;
        address sender;
        uint256 expiry;
        RequestStatus status;
        string name;
        address additionalValidator;
        bytes additionalData;
        bytes32 coordinate;
    }

    mapping(bytes32 => PendingRequest) public pendingRequests;

    /// @dev id => recipient => lastDistributedAt
    mapping(bytes32 => mapping(address => CoolTimeLib.DistributionInfo)) public distributionInfoMap;

    /// @dev nonce => isUsed
    mapping(uint256 => bool) public nonceUsedMap;

    IPermit2 private permit2;

    /// @dev Error codes
    error InvalidRequest();
    /// request already exists
    error RequestAlreadyExists();
    /// request is not pending
    error RequestNotPending();
    /// request is expired
    error RequestExpiredError();
    /// insufficient funds
    error InsufficientFunds();
    /// request is not expired
    error RequestNotExpired();
    /// caller is not sender
    error CallerIsNotSender();
    /// nonce used
    error NonceUsed();
    /// invalid secret
    error InvalidSecret();

    // common permit2 errors
    /// invalid dispatcher
    error InvalidDispatcher();
    /// deadline passed
    error DeadlinePassed();

    /// invalid additional validation
    error InvalidAdditionalValidation();

    event Submitted(
        bytes32 id,
        address token,
        address sender,
        uint256 amount,
        uint256 amountPerWithdrawal,
        uint256 cooltime,
        uint256 maxAmountPerAddress,
        uint256 expiry,
        string name,
        bytes32 coordinate
    );

    event Deposited(bytes32 id, address depositor, uint256 amount);
    event Received(bytes32 id, address recipient, uint256 amount);
    event RequestCancelled(bytes32 id, uint256 amount);
    event RequestExpired(bytes32 id, uint256 amount);

    constructor() {
    }

    function initialize(address _permit2, address _admin) public initializer {
        __MultiFacilitators_init(_admin);

        permit2 = IPermit2(_permit2);
    }

    /**
     * @notice Submits a request to distribute tokens.
     * @dev Only facilitators can submit requests.
     * @param request The request to submit.
     * @param sig The signature of the request.
     */
    function submit(TokenDistributeSubmitRequest memory request, bytes memory sig) public onlyFacilitators {
        bytes32 id = request.hash();

        if(!request.verify()) {
            revert InvalidRequest();
        }

        if (pendingRequests[id].status != RequestStatus.NotSubmitted) {
            revert RequestAlreadyExists();
        }

        _verifySubmitRequest(request, sig);

        pendingRequests[id] = PendingRequest({
            amount: request.amount,
            amountPerWithdrawal: request.amountPerWithdrawal,
            cooltime: request.cooltime,
            maxAmountPerAddress: request.maxAmountPerAddress,
            token: request.token,
            publicKey: request.publicKey,
            sender: request.sender,
            expiry: request.expiry,
            status: RequestStatus.Pending,
            name: request.name,
            additionalValidator: request.additionalValidator,
            additionalData: request.additionalData,
            coordinate: request.coordinate
        });

        emit Submitted(
            id,
            request.token,
            request.sender,
            request.amount,
            request.amountPerWithdrawal,
            request.cooltime,
            request.maxAmountPerAddress,
            request.expiry,
            request.name,
            request.coordinate
        );
    }

    /**
     * @notice Deposit tokens to the request
     * @dev Only facilitators can submit deposit requests.
     * @param depositRequest The deposit request.
     * @param sig The signature of the deposit request.
     */
    function deposit(TokenDistributeDepositRequest memory depositRequest, bytes memory sig) public onlyFacilitators {
        PendingRequest storage request = pendingRequests[depositRequest.requestId];

        if (request.status != RequestStatus.Pending) {
            revert RequestNotPending();
        }

        if (block.timestamp > request.expiry) {
            revert RequestExpiredError();
        }

        if (depositRequest.token != request.token) {
            revert InvalidRequest();
        }

        _verifySenderDepositRequest(depositRequest, sig);

        request.amount += depositRequest.amount;

        emit Deposited(depositRequest.requestId, msg.sender, depositRequest.amount);
    }

    /**
     * @notice Distribute the request to the recipient
     * @dev Only facilitators can submit distribute requests.
     * @param recipientData The data of the recipient.
     */
    function distribute(RecipientData memory recipientData) public onlyFacilitators {
        PendingRequest storage request = pendingRequests[recipientData.requestId];
        CoolTimeLib.DistributionInfo storage info = distributionInfoMap[recipientData.requestId][recipientData.recipient];

        if (block.timestamp > request.expiry) {
            revert RequestExpiredError();
        }

        if (request.amount < request.amountPerWithdrawal) {
            revert InsufficientFunds();
        }

        info.validate(request.cooltime, request.maxAmountPerAddress);

        if(request.additionalValidator != address(0)) {
            if(!IAdditionalValidator(request.additionalValidator).verify(recipientData, request.additionalData)) {
                revert InvalidAdditionalValidation();
            }
        }

        _verifyRecipientSignature(request.publicKey, recipientData.nonce, recipientData.deadline, recipientData.recipient, recipientData.sig);

        request.amount -= request.amountPerWithdrawal;

        info.lastDistributedAt = block.timestamp;
        info.amount += request.amountPerWithdrawal;

        ERC20(request.token).transfer(recipientData.recipient, request.amountPerWithdrawal);

        emit Received(recipientData.requestId, recipientData.recipient, request.amountPerWithdrawal);
    }    

    /**
     * @notice Cancel the request during distribution
     * @param id The ID of the request to cancel.
     */
    function cancelRequest(bytes32 id) public nonReentrant {
        PendingRequest storage request = pendingRequests[id];

        if (request.sender != msg.sender) {
            revert CallerIsNotSender();
        }

        if (request.status != RequestStatus.Pending) {
            revert RequestNotPending();
        }

        uint256 leftAmount = request.amount;

        request.amount = 0;

        request.status = RequestStatus.Cancelled;

        ERC20(request.token).transfer(request.sender, leftAmount);

        emit RequestCancelled(id, leftAmount);
    }

    /**
     * @notice Complete the request after the expiry
     * @param id The ID of the request to complete.
     */
    function completeRequest(bytes32 id) public onlyFacilitators {
        PendingRequest storage request = pendingRequests[id];

        if (request.expiry > block.timestamp) {
            revert RequestNotExpired();
        }

        if (request.status != RequestStatus.Pending) {
            revert RequestNotPending();
        }

        uint256 leftAmount = request.amount;

        request.amount = 0;

        request.status = RequestStatus.Completed;

        ERC20(request.token).transfer(request.sender, leftAmount);

        emit RequestExpired(id, leftAmount);
    }

    /**
     * @notice Verifies the request and the signature.
     */
    function _verifySubmitRequest(TokenDistributeSubmitRequest memory request, bytes memory sig) internal {
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
            TokenDistributeSubmitRequestLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }

    function _verifySenderDepositRequest(TokenDistributeDepositRequest memory request, bytes memory sig) internal {
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
            TokenDistributeDepositRequestLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }

    /**
     * @notice Verifies the signature made by the recipient using the private key received from the sender.
     */
    function _verifyRecipientSignature(address publicKey, uint256 nonce, uint256 deadline, address recipient, bytes memory signature)
        internal
    {
        if (nonceUsedMap[nonce]) {
            revert NonceUsed();
        }

        nonceUsedMap[nonce] = true;

        if (block.timestamp > deadline) {
            revert DeadlinePassed();
        }

        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(abi.encode(address(this), nonce, deadline, recipient)));

        if (publicKey != ECDSA.recover(messageHash, signature)) {
            revert InvalidSecret();
        }
    }
}
