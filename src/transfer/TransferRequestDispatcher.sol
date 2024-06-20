// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../interfaces/IRequestDispatcher.sol";
import "./TransferRequest.sol";
import "permit2/lib/solmate/src/tokens/ERC20.sol";
import "permit2/src/interfaces/ISignatureTransfer.sol";
import "permit2/src/interfaces/IPermit2.sol";

contract TransferRequestDispatcher is IRequestDispatcher {
    using TransferRequestLib for TransferRequest;

    struct PendingRequest {
        uint256 amount;
        address token;
        bytes32 secretHash;
        address sender;
        address recipient;
        uint256 deadline;
    }

    IPermit2 permit2;
    address public facilitator;

    event Transfered(address token, address from, address to, uint256 amount, uint256 nonce, uint256 deadline);

    modifier onlyFacilitator() {
        require(msg.sender == facilitator, "Only facilitator");
        _;
    }

    constructor(address _permit2, address _facilitator) {
        permit2 = IPermit2(_permit2);
        facilitator = _facilitator;
    }

    function submitTransfer(TransferRequest memory request, bytes memory sig) public onlyFacilitator {
        _verifyRequest(request, sig);

        emit Transfered(
            request.token, request.sender, request.recipient, request.amount, request.nonce, request.deadline
        );
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
