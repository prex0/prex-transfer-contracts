// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import {TransferRequestDispatcher} from "src/transfer/TransferRequestDispatcher.sol";

contract DeployTransferRequestDispatcher is Script {
    address public PERMIT2 = address(0x000000000022D473030F116dDEE9F6B43aC78BA3);

    function setUp() public {}

    function run() public returns (TransferRequestDispatcher dispatcher) {
        vm.startBroadcast();

        dispatcher = new TransferRequestDispatcher{
            salt: 0x0000000000000000000000000000000000000000000000000000000000077777
        }(PERMIT2);

        console2.log("TransferRequestDispatcher Deployed:", address(dispatcher));

        vm.stopBroadcast();
    }
}
