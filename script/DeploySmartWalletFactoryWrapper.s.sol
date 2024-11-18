// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import {SmartWalletFactoryWrapper} from "src/smart-wallet-factory-wrapper/SmartWalletFactoryWrapper.sol";

contract DeploySmartWalletFactoryWrapper is Script {
    address public SMART_WALLET_FACTORY = address(0xB8C45FCf2e45732EBCB4BE81e3426ea407896938);

    function setUp() public {}

    function run() public returns (SmartWalletFactoryWrapper wrapper) {
        vm.startBroadcast();

        wrapper = new SmartWalletFactoryWrapper{
            salt: 0x0000000000000000000000000000000000000000000000000000000007777777
        }(SMART_WALLET_FACTORY);

        console2.log("SmartWalletFactoryWrapper Deployed:", address(wrapper));

        vm.stopBroadcast();
    }
}
