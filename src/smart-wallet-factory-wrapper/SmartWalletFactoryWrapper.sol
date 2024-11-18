// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface ISmartWalletFactory {
    function createAccount(bytes[] calldata owners, uint256 nonce)
    external
    payable
    returns (address account);
}


contract SmartWalletFactoryWrapper {
    ISmartWalletFactory public immutable smartWalletFactory;

    event WalletCreated(address indexed account, bytes[] owners, uint256 nonce);

    constructor(address _smartWalletFactory) {
        smartWalletFactory = ISmartWalletFactory(_smartWalletFactory);
    }

    function createAccount(bytes[] calldata owners, uint256 nonce) external payable returns (address account) {
        account = smartWalletFactory.createAccount{value: msg.value}(owners, nonce);

        emit WalletCreated(account, owners, nonce);
        
        return account;
    }
}
