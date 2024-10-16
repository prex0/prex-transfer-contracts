// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct TokenDistributeDepositRequest {
    address dispatcher;
    address sender;
    uint256 deadline;
    uint256 nonce;
    bytes32 requestId;
    address token;
    uint256 amount;
}

library TokenDistributeDepositRequestLib {
    bytes internal constant TOKEN_DISTRIBUTE_DEPOSIT_REQUEST_TYPE_S = abi.encodePacked(
        "TokenDistributeDepositRequest(",
        "address dispatcher,",
        "address sender,",
        "uint256 deadline,",
        "uint256 nonce,",
        "bytes32 requestId,",
        "address token,",
        "uint256 amount)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec

    bytes internal constant TOKEN_DISTRIBUTE_DEPOSIT_REQUEST_TYPE = abi.encodePacked(TOKEN_DISTRIBUTE_DEPOSIT_REQUEST_TYPE_S);
    bytes32 internal constant TOKEN_DISTRIBUTE_DEPOSIT_REQUEST_TYPE_HASH = keccak256(TOKEN_DISTRIBUTE_DEPOSIT_REQUEST_TYPE);

    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";

    string internal constant PERMIT2_ORDER_TYPE =
        string(abi.encodePacked("TokenDistributeDepositRequest witness)", TOKEN_DISTRIBUTE_DEPOSIT_REQUEST_TYPE_S, TOKEN_PERMISSIONS_TYPE));

    /// @notice hash the given request
    /// @param request the request to hash
    /// @return the eip-712 request hash
    function hash(TokenDistributeDepositRequest memory request) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                TOKEN_DISTRIBUTE_DEPOSIT_REQUEST_TYPE_HASH,
                request.dispatcher,
                request.sender,
                request.deadline,
                request.nonce,
                request.requestId,
                request.token,
                request.amount
            )
        );
    }
}
