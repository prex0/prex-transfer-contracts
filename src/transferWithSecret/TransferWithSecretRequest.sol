// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct TransferWithSecretRequest {
    address dispatcher;
    address sender;
    uint256 deadline;
    uint256 nonce;
    uint256 amount;
    address token;
    bytes32 secretHash;
    bytes metadata;
}

/// @notice helpers for handling TransferRequest
library TransferWithSecretRequestLib {
    bytes internal constant TRANSFER_REQUEST_TYPE_S = abi.encodePacked(
        "TransferWithSecret(",
        "address dispatcher,",
        "address sender,",
        "uint256 deadline,",
        "uint256 nonce,",
        "uint256 amount,",
        "address token,",
        "bytes32 secretHash,",
        "bytes metadata)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec

    bytes internal constant TRANSFER_REQUEST_TYPE = abi.encodePacked(TRANSFER_REQUEST_TYPE_S);
    bytes32 internal constant TRANSFER_REQUEST_TYPE_HASH = keccak256(TRANSFER_REQUEST_TYPE);

    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";
    string internal constant PERMIT2_ORDER_TYPE =
        string(abi.encodePacked("TransferWithSecret witness)", TOKEN_PERMISSIONS_TYPE, TRANSFER_REQUEST_TYPE_S));

    /// @notice hash the given request
    /// @param request the request to hash
    /// @return the eip-712 request hash
    function hash(TransferWithSecretRequest memory request) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                TRANSFER_REQUEST_TYPE_HASH,
                request.dispatcher,
                request.sender,
                request.deadline,
                request.nonce,
                request.amount,
                request.token,
                request.secretHash,
                keccak256(request.metadata)
            )
        );
    }
}
