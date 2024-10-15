// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct RecipientData {
    bytes32 requestId;
    address recipient;
    uint256 nonce;
    uint256 deadline;
    bytes sig;
}

interface IAdditionalValidator {
    function verify(RecipientData memory recipientData, bytes memory additionalData) external view returns (bool);
}