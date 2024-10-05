// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import {TokenDistributor} from "src/distributor/TokenDistributor.sol";

contract DeployTokenDistributor is Script {
    address public PERMIT2 = address(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    address public FACILITATOR_ADMIN = address(0x51B89C499F3038756Eff64a0EF52d753147EAd75);
    address public FACILITATOR = address(0x40e1A25DbF7D054f8b86e490A06050bb07ABbF09);

    function setUp() public {}

    function run() public returns (TokenDistributor dispatcher) {
        vm.startBroadcast();

        dispatcher = new TokenDistributor{
            salt: 0x0000000000000000000000000000000000000000000000000000000007777777
        }(PERMIT2, FACILITATOR_ADMIN);

        console2.log("TokenDistributor Deployed:", address(dispatcher));

        vm.stopBroadcast();
    }
}
