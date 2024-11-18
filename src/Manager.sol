// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "solmate/src/auth/Owned.sol";

interface IMultiFacillicators {
    function addFacilitator(address _facilitator) external;
    function removeFacilitator(address _facilitator) external;
    function transferOwnership(address _newOwner) external;
}

/**
 * @title Manager
 * @notice A contract that manages the facilitators of the onetime lock, distribution, and swap contracts.
 */
contract Manager is Owned {
    IMultiFacillicators public immutable onetimeLock;
    IMultiFacillicators public immutable distribution;
    IMultiFacillicators public immutable swap;

    constructor(address _owner, address _onetimeLock, address _distribution, address _swap) Owned(_owner) {
        onetimeLock = IMultiFacillicators(_onetimeLock);
        distribution = IMultiFacillicators(_distribution);
        swap = IMultiFacillicators(_swap);
    }

    /**
     * @notice Transfers ownership of the onetime lock, distribution, and swap contracts to a new owner.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnershipOfContracts(address _newOwner) public onlyOwner {
        if (address(onetimeLock) != address(0)) {
            onetimeLock.transferOwnership(_newOwner);
        }
        if (address(distribution) != address(0)) {
            distribution.transferOwnership(_newOwner);
        }
        if (address(swap) != address(0)) {
            swap.transferOwnership(_newOwner);
        }
    }

    /**
     * @notice Adds multiple facilitators to the onetime lock, distribution, and swap contracts.
     * @param _facilitators The addresses of the facilitators to add.
     */
    function batchAddFacilitator(address[] calldata _facilitators) public onlyOwner {
        for (uint256 i = 0; i < _facilitators.length; i++) {
            addFacilitator(_facilitators[i]);
        }
    }

    /**
     * @notice Removes multiple facilitators from the onetime lock, distribution, and swap contracts.
     * @param _facilitators The addresses of the facilitators to remove.
     */
    function batchRemoveFacilitator(address[] calldata _facilitators) public onlyOwner {
        for (uint256 i = 0; i < _facilitators.length; i++) {
            removeFacilitator(_facilitators[i]);
        }
    }

    function addFacilitator(address _facilitator) internal {
        if (address(onetimeLock) != address(0)) {
            onetimeLock.addFacilitator(_facilitator);
        }
        if (address(distribution) != address(0)) {
            distribution.addFacilitator(_facilitator);
        }
        if (address(swap) != address(0)) {
            swap.addFacilitator(_facilitator);
        }
    }

    function removeFacilitator(address _facilitator) internal {
        if (address(onetimeLock) != address(0)) {
            onetimeLock.removeFacilitator(_facilitator);
        }
        if (address(distribution) != address(0)) {
            distribution.removeFacilitator(_facilitator);
        }
        if (address(swap) != address(0)) {
            swap.removeFacilitator(_facilitator);
        }
    }
}
