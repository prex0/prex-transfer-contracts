// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {TestTokenDistributorSetup} from "./Setup.t.sol";
import "../../src/distributor/TokenDistributor.sol";
import "../../src/distributor/TokenDistributeSubmitRequest.sol";
import "../../src/distributor/HolderValidation.sol";

contract TestTokenDistributorValidation is TestTokenDistributorSetup {
    using TokenDistributeSubmitRequestLib for TokenDistributeSubmitRequest;

    TokenDistributeSubmitRequest internal request;
    bytes32 internal requestId;

    uint256 public constant AMOUNT = 3;
    uint256 public constant EXPIRY_UNTIL = 5 hours;

    uint256 public constant tmpPrivKey = 11111000002;

    function setUp() public virtual override(TestTokenDistributorSetup) {
        super.setUp();

        address tmpPublicKey = vm.addr(tmpPrivKey);

        HolderValidation holderValidation = new HolderValidation();

        request = TokenDistributeSubmitRequest({
            dispatcher: address(distributor),
            sender: sender,
            deadline: block.timestamp + EXPIRY_UNTIL,
            nonce: 0,
            token: address(token),
            publicKey: tmpPublicKey,
            amount: AMOUNT,
            amountPerWithdrawal: 1,
            cooltime: 1 hours,
            maxAmountPerAddress: 2,
            expiry: block.timestamp + EXPIRY_UNTIL,
            name: "test",
            coordinate: bytes32(0),
            additionalValidator: address(holderValidation),
            additionalData: abi.encode(address(token), 1)
        });

        requestId = request.hash();

        bytes memory sig = _sign(request, privateKey);

        vm.startPrank(facilitator);

        distributor.submit(request, sig);

        vm.stopPrank();
    }

    // distribute
    function testDistribute() public {
        token.mint(recipient, 1);

        RecipientData memory recipientData = _getRecipientData(requestId, 0, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.startPrank(facilitator);

        assertEq(token.balanceOf(recipient), 1);
        distributor.distribute(recipientData);
        assertEq(token.balanceOf(recipient), 2);

        vm.stopPrank();
    }

    // fails to distribute if invalid additional validation
    function testCannotDistributeIfInvalidAdditionalValidation() public {
        vm.startPrank(facilitator);

        RecipientData memory recipientData = _getRecipientData(requestId, 0, block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.expectRevert(TokenDistributor.InvalidAdditionalValidation.selector);
        distributor.distribute(recipientData);

        vm.stopPrank();
    }
}
