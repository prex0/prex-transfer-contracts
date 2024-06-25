// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import {TransferRequestDispatcher} from "src/transfer/TransferRequestDispatcher.sol";
import {TransferWithSecretRequestDispatcher} from "src/transferWithSecret/TransferWithSecretRequestDispatcher.sol";
import {OnetimeLockRequestDispatcher} from "src/onetime-lock/OnetimeLockRequestDispatcher.sol";
import {ExpiringLockRequestDispatcher} from "src/expiring-lock/ExpiringLockRequestDispatcher.sol";

contract DeployRequestDispatcher is Script {
    address public PERMIT2 = address(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    address public FACILITATOR = address(0x40e1A25DbF7D054f8b86e490A06050bb07ABbF09);

    function setUp() public {}

    function run()
        public
        returns (
            TransferRequestDispatcher dispatcher1,
            TransferWithSecretRequestDispatcher dispatcher2
        )
    {
        vm.startBroadcast();

        dispatcher1 = new TransferRequestDispatcher{salt: 0x0000000000000000000000000000000000000000000000000000000000077777}(PERMIT2);
        dispatcher2 = new TransferWithSecretRequestDispatcher{salt: 0x0000000000000000000000000000000000000000000000000000000000077777}(PERMIT2, FACILITATOR);
        //dispatcher3 = new OnetimeLockRequestDispatcher{salt: 0x0000000000000000000000000000000000000000000000000000000000000777}(FACILITATOR);
        //dispatcher4 = new ExpiringLockRequestDispatcher{salt: 0x0000000000000000000000000000000000000000000000000000000000000777}(FACILITATOR);

        console2.log("TransferRequestDispatcher Deployed:", address(dispatcher1));
        console2.log("TransferWithSecretRequestDispatcher Deployed:", address(dispatcher2));
        //console2.log("OnetimeLockRequestDispatcher Deployed:", address(dispatcher3));
        //console2.log("ExpiringLockRequestDispatcher Deployed:", address(dispatcher4));

        vm.stopBroadcast();
    }
}
