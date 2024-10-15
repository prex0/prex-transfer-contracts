// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IAdditionalValidator.sol";
import "permit2/lib/solmate/src/tokens/ERC20.sol";

contract HolderValidation is IAdditionalValidator {
    function verify(RecipientData memory recipientData, bytes memory additionalData) external view returns (bool) {
        (address tokenAddress, uint256 amount) = abi.decode(additionalData, (address, uint256));

        ERC20 token = ERC20(tokenAddress);

        return token.balanceOf(recipientData.recipient) >= amount;
    }
}