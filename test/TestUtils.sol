// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ECDSA} from "permit2/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "permit2/src/interfaces/IPermit2.sol";
import {Permit2} from "permit2/src/Permit2.sol";

contract TestUtils is Test {
    string constant _PERMIT_TRANSFER_FROM_WITNESS_TYPEHASH_STUB =
        "PermitWitnessTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline,";

    bytes32 internal constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");

    function _hashTokenPermissions(ISignatureTransfer.TokenPermissions memory permitted)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permitted));
    }

    function getPermit2Signature(
        uint256 privateKey,
        ISignatureTransfer.PermitTransferFrom memory permit,
        address spender,
        string memory witnessTypeHash,
        bytes32 witness,
        bytes32 domainSeparator
    ) internal pure returns (bytes memory sig) {
        bytes32 typeHash = keccak256(abi.encodePacked(_PERMIT_TRANSFER_FROM_WITNESS_TYPEHASH_STUB, witnessTypeHash));

        bytes32 msgHash = ECDSA.toTypedDataHash(
            domainSeparator,
            keccak256(
                abi.encode(
                    typeHash, _hashTokenPermissions(permit.permitted), spender, permit.nonce, permit.deadline, witness
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
        sig = bytes.concat(r, s, bytes1(v));
    }

    function _signMessage(uint256 privateKey, bytes32 witness) internal pure returns (bytes memory sig) {
        bytes32 msgHash = ECDSA.toEthSignedMessageHash(witness);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
        sig = bytes.concat(r, s, bytes1(v));
    }
}
