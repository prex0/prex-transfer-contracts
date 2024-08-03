// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./TransferWithSecretRequest.sol";
import "permit2/lib/solmate/src/tokens/ERC20.sol";
import "permit2/src/interfaces/ISignatureTransfer.sol";
import "permit2/src/interfaces/IPermit2.sol";
import "permit2/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../MultiFacilitators.sol";
/**
 * @notice TransferWithSecret is a mechanism for securely implementing link transfers.
 * Instead of setting the recipient's address, the sender sets a generated public key and gives the corresponding private key to the recipient.
 * The recipient uses the private key to sign their real address, and this signature is used to receive the token.
 * By using a signature instead of secret information for receipt, it prevents intermediaries from exploiting the secret information.
 * This contract integrates with the Permit2 library to handle ERC20 token transfers securely and efficiently.
 */
contract TransferWithSecretRequestDispatcher is MultiFacilitators {
    using TransferWithSecretRequestLib for TransferWithSecretRequest;

    IPermit2 immutable permit2;

    error InvalidDispatcher();
    error DeadlinePassed();
    error InvalidSecret();

    struct RecipientData {
        address recipient;
        bytes sig;
        bytes metadata;
    }

    event RequestSubmitted(
        address token, address from, address to, uint256 amount, bytes metadata, bytes recipientMetadata
    );

    constructor(address _permit2, address _facilitatorAdmin) MultiFacilitators(_facilitatorAdmin) {
        permit2 = IPermit2(_permit2);
    }

    /**
     * @notice Submits a new transfer request.
     * This function is executed by the recipient after they receive the signature from the sender.
     */
    function submitRequest(
        TransferWithSecretRequest memory request,
        bytes memory sig,
        RecipientData memory recipientData
    ) external onlyFacilitators {
        _verifyRecipientSignature(request.nonce, request.publicKey, recipientData.recipient, recipientData.sig);

        _verifySenderRequest(request, recipientData.recipient, sig);

        emit RequestSubmitted(
            request.token,
            request.sender,
            recipientData.recipient,
            request.amount,
            request.metadata,
            recipientData.metadata
        );
    }

    /**
     * @notice Verifies the request and the signature.
     */
    function _verifySenderRequest(TransferWithSecretRequest memory request, address recipient, bytes memory sig)
        internal
    {
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
            ISignatureTransfer.SignatureTransferDetails({to: recipient, requestedAmount: request.amount}),
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
