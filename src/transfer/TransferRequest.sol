// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct TransferRequest {
    address dispatcher;
    address sender;
    address recipient;
    uint256 deadline;
    uint256 nonce;
    uint256 amount;
    address token;
}

/// @notice helpers for handling TransferRequest
library TransferRequestLib {
    bytes internal constant TRANSFER_REQUEST_TYPE_S = abi.encodePacked(
        "TransferRequest(",
        "address dispatcher,",
        "address sender,",
        "address recipient,",
        "uint256 deadline,",
        "uint256 nonce,",
        "uint256 amount,",
        "address token)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec

    bytes internal constant TRANSFER_REQUEST_TYPE = abi.encodePacked(TRANSFER_REQUEST_TYPE_S);
    bytes32 internal constant TRANSFER_REQUEST_TYPE_HASH = keccak256(TRANSFER_REQUEST_TYPE);

    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";
    string internal constant PERMIT2_ORDER_TYPE =
        string(abi.encodePacked("TransferRequest witness)", TOKEN_PERMISSIONS_TYPE, TRANSFER_REQUEST_TYPE_S));

    /// @notice hash the given request
    /// @param request the request to hash
    /// @return the eip-712 request hash
    function hash(TransferRequest memory request) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                TRANSFER_REQUEST_TYPE_HASH,
                request.dispatcher,
                request.sender,
                request.recipient,
                request.deadline,
                request.nonce,
                request.amount,
                request.token
            )
        );
    }
}
