// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct ExpiringLockRequest {
    uint256 amount;
    uint256 amountPerWithdrawal;
    address token;
    uint256 expiry;
}

library ExpiringLockRequestLib {
    bytes internal constant EXPIRING_LOCK_REQUEST_TYPE_S = abi.encodePacked(
        "ExpiringLockRequest(", "uint256 amount,", "uint256 amountPerWithdrawal,", "address token,", "uint256 expiry)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec

    bytes internal constant EXPIRING_LOCK_REQUEST_TYPE = abi.encodePacked(EXPIRING_LOCK_REQUEST_TYPE_S);
    bytes32 internal constant EXPIRING_LOCK_REQUEST_TYPE_HASH = keccak256(EXPIRING_LOCK_REQUEST_TYPE);

    /// @notice hash the given request
    /// @param request the request to hash
    /// @return the eip-712 request hash
    function hash(ExpiringLockRequest memory request) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                EXPIRING_LOCK_REQUEST_TYPE_HASH,
                request.amount,
                request.amountPerWithdrawal,
                request.token,
                request.expiry
            )
        );
    }
}
