// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/smart-wallet-factory-wrapper/SmartWalletFactoryWrapper.sol";

contract SmartWalletFactoryMock is ISmartWalletFactory {
    address public lastCreatedAccount;
    bytes[] public lastOwners;
    uint256 public lastNonce;

    function createAccount(bytes[] calldata owners, uint256 nonce)
        external
        payable
        override
        returns (address account)
    {
        lastOwners = owners;
        lastNonce = nonce;
        lastCreatedAccount = address(this); // Mock account address
        return lastCreatedAccount;
    }
}

contract SmartWalletFactoryWrapperTest is Test {
    SmartWalletFactoryWrapper public wrapper;
    SmartWalletFactoryMock public factoryMock;

    function setUp() public {
        factoryMock = new SmartWalletFactoryMock();
        wrapper = new SmartWalletFactoryWrapper(address(factoryMock));
    }

    function testCreateAccount() public {
        bytes[] memory owners = new bytes[](1);
        owners[0] = abi.encodePacked(address(0x123));
        uint256 nonce = 1;

        uint256 value = 1 ether;
        address account = wrapper.createAccount{value: value}(owners, nonce);

        assertEq(account, address(factoryMock));
        assertEq(factoryMock.lastOwners(0), owners[0]);
        assertEq(factoryMock.lastNonce(), nonce);
        assertEq(factoryMock.lastCreatedAccount(), account);
        assertEq(address(account).balance, value);
    }
}
