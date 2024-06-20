// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library SecretUtil {
    function hashSecret(bytes32 secret, uint256 version) internal view returns (bytes32) {
        return hashSecret(address(this), secret, version);
    }

    function hashSecret(address verifier, bytes32 secret, uint256 version) internal view returns (bytes32) {
        return keccak256(abi.encode(verifier, version, secret));
    }
}
