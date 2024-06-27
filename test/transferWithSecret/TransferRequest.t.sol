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

    function parsePaymasterAndData(bytes calldata paymasterAndData)
    external pure returns(uint48 validUntil, uint48 validAfter, uint32 spentKey, bytes calldata signature) {
        validUntil = uint48(bytes6(paymasterAndData[20:26]));
        validAfter = uint48(bytes6(paymasterAndData[26:32]));
        spentKey = uint32(bytes4(paymasterAndData[32:36]));
        signature = paymasterAndData[36:];
    }
}

contract TestTransferWithSecretRequest is Test, SignatureTransfer {
    using TransferWithSecretRequestLib for TransferWithSecretRequest;

    function testSign() public {
        TransferWithSecretRequest memory request = TransferWithSecretRequest({
            dispatcher: address(this),
            sender: address(2),
            deadline: 1000,
            nonce: 0,
            amount: 100,
            token: address(3),
            publicKey: address(4),
            metadata: ""
        });

        assertEq(request.dispatcher, address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496));
        assertEq(request.sender, address(0x0000000000000000000000000000000000000002));
        assertEq(request.token, address(0x0000000000000000000000000000000000000003));

        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: request.token, amount: request.amount}),
            nonce: request.nonce,
            deadline: request.deadline
        });

        Aaa aaa = new Aaa();

        assertEq(address(aaa), address(0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f));

        assertEq(block.chainid, 31337);

        assertEq(
            request.hash(),
            bytes32(0xc3d5f16c9e6302e43e7e199d653677f6e2f59be6812b66986fa396a8376f57cc)
        );


        assertEq(
            aaa.aaa(permit, request.hash(), TransferWithSecretRequestLib.PERMIT2_ORDER_TYPE),
            bytes32(0x9282dc87973afab86ab03c5b7080a9e8522e11ef876f0f25922494239c300335)
        );
    }

    function testHash() public {
        TransferWithSecretRequest memory request = TransferWithSecretRequest({
            dispatcher: address(1),
            sender: address(2),
            deadline: 1000,
            nonce: 0,
            amount: 100,
            token: address(3),
            publicKey: address(4),
            metadata: "0x"
        });

        assertEq(request.dispatcher, address(0x0000000000000000000000000000000000000001));
        assertEq(request.sender, address(0x0000000000000000000000000000000000000002));
        assertEq(request.token, address(0x0000000000000000000000000000000000000003));

        
        assertEq(
            TransferWithSecretRequestLib.TRANSFER_REQUEST_TYPE_HASH,
            bytes32(0xad56504a879a0a3a3f0eb62e8e541174f27f4f3f75473be0cece846fdcc8154e)
        );

        assertEq(
            request.hash(),
            bytes32(0xbcd6e468d5baaa21a17410b4968f4adf1a915a1a3585dd6676b68f591c610e9b)
        );
    }
}
