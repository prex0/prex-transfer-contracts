// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import {Manager} from "src/Manager.sol";

contract DeployManager is Script {
    address public FACILITATOR_ADMIN = address(0x51B89C499F3038756Eff64a0EF52d753147EAd75);
    address public ONETIME_LOCK = address(0xc64c22220ca22D9E499719230100e5dc7E1D4f89);
    address public DISTRIBUTION = address(0xcb6a2184A2259040476CEDd111cA0513492E47D0);
    address public SWAP = address(0x0C4A9411B6c896390faBc295fbb472DB7B399aEC);

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
