// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import {Manager} from "src/Manager.sol";

contract DeployManager is Script {
    address public FACILITATOR_ADMIN = address(0x51B89C499F3038756Eff64a0EF52d753147EAd75);
    address public ONETIME_LOCK = address(0x7bB6682bAe76b8a394F9Ed2812A2968182814804);
    address public DISTRIBUTION = address(0x1bDF9c09D05F660C91e334df9ce531B2B3CE6e1d);
    address public SWAP = address(0x0C4A9411B6c896390faBc295fbb472DB7B399aEC);
    // for arbitrum sepolia
    // address public SWAP = address(0);

    function setUp() public {}

    function run() public returns (Manager manager) {
        vm.startBroadcast();

        manager = new Manager{salt: 0x0000000000000000000000000000000000000000000000000000000007777777}(
            FACILITATOR_ADMIN, ONETIME_LOCK, DISTRIBUTION, SWAP
        );

        console2.log("Manager Deployed:", address(manager));

        vm.stopBroadcast();
    }
}
