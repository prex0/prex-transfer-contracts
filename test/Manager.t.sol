pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Manager.sol";
import "../src/MultiFacilitators.sol";

contract ManagerTest is Test {
    Manager manager;
    MultiFacilitators onetimeLock;
    MultiFacilitators distribution;
    MultiFacilitators swap;
    address owner = address(0x1);
    address facilitator1 = address(0x2);
    address facilitator2 = address(0x3);

    function setUp() public {
        onetimeLock = new MultiFacilitators(owner);
        distribution = new MultiFacilitators(owner);
        swap = new MultiFacilitators(owner);
        manager = new Manager(owner, address(onetimeLock), address(distribution), address(swap));

        vm.startPrank(owner);
        onetimeLock.transferOwnership(address(manager));
        distribution.transferOwnership(address(manager));
        swap.transferOwnership(address(manager));
        vm.stopPrank();
    }

    function testBatchAddFacilitator() public {
        vm.startPrank(owner);
        address[] memory facilitators = new address[](2);
        facilitators[0] = facilitator1;
        facilitators[1] = facilitator2;

        manager.batchAddFacilitator(facilitators);

        assertTrue(onetimeLock.facilitators(facilitator1));
        assertTrue(onetimeLock.facilitators(facilitator2));
        assertTrue(distribution.facilitators(facilitator1));
        assertTrue(distribution.facilitators(facilitator2));
        assertTrue(swap.facilitators(facilitator1));
        assertTrue(swap.facilitators(facilitator2));
        vm.stopPrank();
    }

    function testBatchRemoveFacilitator() public {
        vm.startPrank(owner);
        address[] memory facilitators = new address[](2);
        facilitators[0] = facilitator1;
        facilitators[1] = facilitator2;

        manager.batchAddFacilitator(facilitators);
        manager.batchRemoveFacilitator(facilitators);

        assertFalse(onetimeLock.facilitators(facilitator1));
        assertFalse(onetimeLock.facilitators(facilitator2));
        assertFalse(distribution.facilitators(facilitator1));
        assertFalse(distribution.facilitators(facilitator2));
        assertFalse(swap.facilitators(facilitator1));
        assertFalse(swap.facilitators(facilitator2));
        vm.stopPrank();
    }
}
