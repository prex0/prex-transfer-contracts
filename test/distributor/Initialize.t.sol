// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestTokenDistributorSetup} from "./Setup.t.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

contract TestTokenDistributorInitialize is TestTokenDistributorSetup {
    function setUp() public virtual override(TestTokenDistributorSetup) {
        super.setUp();
    }

    // fails to initialize if already initialized
    function testCannotInitialize() public {
        vm.expectRevert(bytes("Initializable: contract is already initialized"));
        distributor.initialize(address(permit2), address(this));
    }
}
