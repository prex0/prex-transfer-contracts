// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import {TransferRequestDispatcher} from "src/transfer/TransferRequestDispatcher.sol";
import {TransferWithSecretRequestDispatcher} from "src/transferWithSecret/TransferWithSecretRequestDispatcher.sol";
import {OnetimeLockRequestDispatcher} from "src/onetime-lock/OnetimeLockRequestDispatcher.sol";
import {ExpiringLockRequestDispatcher} from "src/expiring-lock/ExpiringLockRequestDispatcher.sol";

contract DeployRequestDispatcher is Script {
    bytes32 constant SALT1 = bytes32(uint256(0x2322330000000000005300850000000000000000d3af2963da51c10215740000));
    bytes32 constant SALT2 = bytes32(uint256(0x1122330000000000005300850000000000000d3b000f29632a51c10215720000));
    bytes32 constant SALT3 = bytes32(uint256(0x11220000000005300330008500000000d3af2965da5100000000c10215720000));
    bytes32 constant SALT4 = bytes32(uint256(0x1122330000000000005300850000000da51c1021500000000051af2963720000));

    address public PERMIT2 = address(0x2b1796de5d6B3382038c7607b021886a35fAc188);
    address public FACILITATOR = address(0x51B89C499F3038756Eff64a0EF52d753147EAd75);

    function setUp() public {}

    function run()
        public
        returns (
            TransferRequestDispatcher dispatcher1,
            TransferWithSecretRequestDispatcher dispatcher2,
            OnetimeLockRequestDispatcher dispatcher3,
            ExpiringLockRequestDispatcher dispatcher4
        )
    {
        vm.startBroadcast();

        dispatcher1 = new TransferRequestDispatcher{salt: SALT1}(PERMIT2, FACILITATOR);
        dispatcher2 = new TransferWithSecretRequestDispatcher{salt: SALT2}(PERMIT2, FACILITATOR);
        dispatcher3 = new OnetimeLockRequestDispatcher{salt: SALT3}(FACILITATOR);
        dispatcher4 = new ExpiringLockRequestDispatcher{salt: SALT4}(FACILITATOR);

        console2.log("TransferRequestDispatcher Deployed:", address(dispatcher1));
        console2.log("TransferWithSecretRequestDispatcher Deployed:", address(dispatcher2));
        console2.log("OnetimeLockRequestDispatcher Deployed:", address(dispatcher3));
        console2.log("ExpiringLockRequestDispatcher Deployed:", address(dispatcher4));

        vm.stopBroadcast();
    }
}
