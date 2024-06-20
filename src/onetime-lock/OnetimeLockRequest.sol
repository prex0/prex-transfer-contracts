// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct OnetimeLockRequest {
    uint256 id;
    uint256 amount;
    address token;
    bytes32 secretHash1;
    bytes32 secretHash2;
    uint256 expiry;
}

library OnetimeLockRequestLib {
    bytes internal constant ONETIME_LOCK_REQUEST_TYPE_S = abi.encodePacked(
        "OnetimeLockRequest(",
        "uint256 amount,",
        "address token,",
        "bytes32 secretHash1,",
        "bytes32 secretHash2,",
        "uint256 expiry)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec

    bytes internal constant ONETIME_LOCK_REQUEST_TYPE = abi.encodePacked(ONETIME_LOCK_REQUEST_TYPE_S);
    bytes32 internal constant ONETIME_LOCK_REQUEST_TYPE_HASH = keccak256(ONETIME_LOCK_REQUEST_TYPE);

    /// @notice hash the given request
    /// @param request the request to hash
    /// @return the eip-712 request hash
    function hash(OnetimeLockRequest memory request) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                ONETIME_LOCK_REQUEST_TYPE_HASH,
                request.amount,
                request.token,
                request.secretHash1,
                request.secretHash2,
                request.expiry
            )
        );
    }
}
