// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import "../../src/distributor/TokenDistributeSubmitRequest.sol";

contract TestTokenDistributeSubmitRequestLib is Test {
    using TokenDistributeSubmitRequestLib for TokenDistributeSubmitRequest;

    function testHash() public {
        TokenDistributeSubmitRequest memory request = TokenDistributeSubmitRequest({
            dispatcher: address(0),
            sender: address(0),
            deadline: 2,
            nonce: 3,
            token: address(0),
            publicKey: address(0),
            amount: 1,
            amountPerWithdrawal: 1,
            expiry: 1,
            name: "test",
            cooltime: 1,
            maxAmountPerAddress: 1,
            additionalValidator: address(0),
            additionalData: bytes(""),
            coordinate: bytes32(0)
        });

        assertEq(request.dispatcher, address(0x0000000000000000000000000000000000000000));
        assertEq(request.additionalData, bytes(""));

        assertEq(
            TokenDistributeSubmitRequestLib.TOKEN_DISTRIBUTE_SUBMIT_REQUEST_TYPE_HASH,
            bytes32(0x13b9edf32f211ec691f4b51119893c12a51d6c95668f077715577e25be93f27f)
        );

        assertEq(request.hash(), bytes32(0xfb3b3e3ba62a48624e05e63b7dbd092bedbf5ab03a72b63660b88c5b92d8c520));
    }
}

