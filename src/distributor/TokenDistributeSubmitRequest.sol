// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct TokenDistributeSubmitRequest {
    address dispatcher;
    address sender;
    uint256 deadline;
    uint256 nonce;
    address token;
    address publicKey;
    uint256 amount;
    uint256 amountPerWithdrawal;
    uint256 expiry;
    string name;
    uint256 cooltime;
    uint256 maxAmountPerAddress;
    address additionalValidator;
    bytes additionalData;
    bytes32 coordinate;
}

library TokenDistributeSubmitRequestLib {
    bytes internal constant TOKEN_DISTRIBUTE_SUBMIT_REQUEST_TYPE_S = abi.encodePacked(
        "TokenDistributeSubmitRequest(",
        "address dispatcher,",
        "address sender,",
        "uint256 deadline,",
        "uint256 nonce,",
        "address token,",
        "address publicKey,",
        "uint256 amount,",
        "uint256 amountPerWithdrawal,",
        "uint256 expiry,",
        "string name,",
        "uint256 cooltime,",
        "uint256 maxAmountPerAddress,",
        "address additionalValidator,",
        "bytes additionalData,",
        "bytes32 coordinate)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec

    bytes internal constant TOKEN_DISTRIBUTE_SUBMIT_REQUEST_TYPE = abi.encodePacked(TOKEN_DISTRIBUTE_SUBMIT_REQUEST_TYPE_S);
    bytes32 internal constant TOKEN_DISTRIBUTE_SUBMIT_REQUEST_TYPE_HASH = keccak256(TOKEN_DISTRIBUTE_SUBMIT_REQUEST_TYPE);

    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";

    string internal constant PERMIT2_ORDER_TYPE =
        string(abi.encodePacked("TokenDistributeSubmitRequest witness)", TOKEN_DISTRIBUTE_SUBMIT_REQUEST_TYPE_S, TOKEN_PERMISSIONS_TYPE));

    uint256 private constant MAX_EXPIRY = 360 days;

    /// @notice hash the given request
    /// @param request the request to hash
    /// @return the eip-712 request hash
    function hash(TokenDistributeSubmitRequest memory request) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                TOKEN_DISTRIBUTE_SUBMIT_REQUEST_TYPE_HASH,
                request.dispatcher,
                request.sender,
                request.deadline,
                request.nonce,
                request.token,
                request.publicKey,
                request.amount,
                request.amountPerWithdrawal,
                request.expiry,
                keccak256(bytes(request.name)),
                request.cooltime,
                request.maxAmountPerAddress,
                request.additionalValidator,
                keccak256(request.additionalData),
                request.coordinate
            )
        );
    }

    function verify(TokenDistributeSubmitRequest memory request) internal view returns (bool) {
        if(request.expiry <= block.timestamp) {
            return false;
        }

        if(request.expiry > block.timestamp + MAX_EXPIRY) {
            return false;
        }

        if(request.amount <= 0) {
            return false;
        }

        if(request.amountPerWithdrawal <= 0) {
            return false;
        }

        return true;
    }
}
