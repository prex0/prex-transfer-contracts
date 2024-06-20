// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {
    TransferWithSecretRequest,
    TransferWithSecretRequestLib
} from "src/transferWithSecret/TransferWithSecretRequest.sol";
import {PermitHash} from "permit2/src/libraries/PermitHash.sol";
import "permit2/src/SignatureTransfer.sol";

contract Aaa is SignatureTransfer {
    using PermitHash for PermitTransferFrom;

    function aaa(ISignatureTransfer.PermitTransferFrom memory permit, bytes32 hash, string calldata witnessTypeHash)
        external
        view
        returns (bytes32)
    {
        return permit.hashWithWitness(hash, witnessTypeHash);
    }
}

contract TestTransferWithSecretRequest is Test, SignatureTransfer {
    using TransferWithSecretRequestLib for TransferWithSecretRequest;

    function testHash() public {
        bytes32 secretHash = keccak256(abi.encodePacked("secret"));

        TransferWithSecretRequest memory request = TransferWithSecretRequest({
            dispatcher: address(this),
            sender: address(2),
            deadline: 1000,
            nonce: 0,
            amount: 100,
            token: address(3),
            secretHash: secretHash,
            metadata: ""
        });

        assertEq(request.dispatcher, address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496));
        assertEq(request.sender, address(0x0000000000000000000000000000000000000002));
        assertEq(request.token, address(0x0000000000000000000000000000000000000003));
        assertEq(secretHash, bytes32(0x65462b0520ef7d3df61b9992ed3bea0c56ead753be7c8b3614e0ce01e4cac41b));

        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: request.token, amount: request.amount}),
            nonce: request.nonce,
            deadline: request.deadline
        });

        Aaa aaa = new Aaa();

        assertEq(address(aaa), address(0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f));

        assertEq(block.chainid, 31337);

        assertEq(
            aaa.aaa(permit, request.hash(), TransferWithSecretRequestLib.PERMIT2_ORDER_TYPE),
            bytes32(0x08dd4131ad58faeaec6e3f8b93f2420a28d1e165811c67c5d37560c114be6e88)
        );
    }
}
