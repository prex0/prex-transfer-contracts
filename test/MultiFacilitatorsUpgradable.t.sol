// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/MultiFacilitatorsUpgradable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

contract MockMultiFacilitators is MultiFacilitatorsUpgradable {
    function initialize(address admin) public initializer {
        __MultiFacilitators_init(admin);
    }

    function facilitatorOnlyFunction() public onlyFacilitators {
        // Mock function to test facilitator-only access
    }
}

contract MockMultiFacilitatorsTest is Test {
    MockMultiFacilitators mock;
    address owner = address(0x1);
    address addr1 = address(0x2);
    address addr2 = address(0x3);

    function setUp() public {
        vm.startPrank(owner);
        mock = new MockMultiFacilitators();
        mock.initialize(owner);
        vm.stopPrank();
    }

    function testInitialOwnerIsFacilitator() public view {
        bool isFacilitator = mock.facilitators(owner);
        assertTrue(isFacilitator, "Owner should be a facilitator");
    }

    function testAddFacilitator() public {
        vm.prank(owner);
        mock.addFacilitator(addr1);
        bool isFacilitator = mock.facilitators(addr1);
        assertTrue(isFacilitator, "Address should be added as a facilitator");
    }

    function testRemoveFacilitator() public {
        vm.startPrank(owner);
        mock.addFacilitator(addr1);
        mock.removeFacilitator(addr1);
        vm.stopPrank();

        bool isFacilitator = mock.facilitators(addr1);
        assertFalse(isFacilitator, "Address should be removed as a facilitator");
    }

    function testOnlyOwnerCanAddFacilitator() public {
        vm.prank(addr1);
        vm.expectRevert("Ownable: caller is not the owner");
        mock.addFacilitator(addr2);
    }

    function testOnlyOwnerCanRemoveFacilitator() public {
        vm.prank(owner);
        mock.addFacilitator(addr1);

        vm.prank(addr1);
        vm.expectRevert("Ownable: caller is not the owner");
        mock.removeFacilitator(addr1);
    }

    function testFacilitatorOnlyFunctionRevertsForNonFacilitator() public {
        vm.prank(addr1);
        vm.expectRevert(MultiFacilitatorsUpgradable.CallerIsNotFacilitator.selector);
        mock.facilitatorOnlyFunction();
    }

    function testFacilitatorOnlyFunctionSucceedsForFacilitator() public {
        vm.prank(owner);
        mock.addFacilitator(addr1);

        vm.prank(addr1);
        mock.facilitatorOnlyFunction(); // Should not revert
    }
}