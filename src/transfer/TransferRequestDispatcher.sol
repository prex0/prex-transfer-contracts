// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../interfaces/IRequestDispatcher.sol";
import "./TransferRequest.sol";
import "permit2/lib/solmate/src/tokens/ERC20.sol";
import "permit2/src/interfaces/ISignatureTransfer.sol";
import "permit2/src/interfaces/IPermit2.sol";

contract TransferRequestDispatcher is IRequestDispatcher {
    using TransferRequestLib for TransferRequest;

    IPermit2 permit2;

    event Transferred(address token, address from, address to, uint256 amount, bytes metadata);

    constructor(address _permit2) {
        permit2 = IPermit2(_permit2);
    }

    function submitTransfer(TransferRequest memory request, bytes memory sig) public {
        _verifyRequest(request, sig);

        emit Transferred(request.token, request.sender, request.recipient, request.amount, request.metadata);
    }

    function _verifyRequest(TransferRequest memory request, bytes memory sig) internal {
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
            ISignatureTransfer.SignatureTransferDetails({to: request.recipient, requestedAmount: request.amount}),
            request.sender,
            request.hash(),
            TransferRequestLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }
}
