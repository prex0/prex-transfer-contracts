// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

/**
 * @title MultiFacilitatorsUpgradable
 * @notice A contract that allows multiple facilitators to be added and removed by the owner.
 */
contract MultiFacilitatorsUpgradable is OwnableUpgradeable {
    mapping(address => bool) public facilitators;

    event FacilitatorAdded(address indexed facilitator);
    event FacilitatorRemoved(address indexed facilitator);

    error CallerIsNotFacilitator();

    constructor() {}

    modifier onlyFacilitators() {
        if (!facilitators[msg.sender]) {
            revert CallerIsNotFacilitator();
        }

        _;
    }

    /**
     * @notice Initialize the contract
     * @param admin The address of the admin.
     */
    function __MultiFacilitators_init(address admin) internal onlyInitializing {
        __Ownable_init();

        _transferOwnership(admin);

        facilitators[admin] = true;
    }

    /**
     * @notice Add a facilitator
     * @param _facilitator The address of the facilitator to add.
     */
    function addFacilitator(address _facilitator) public onlyOwner {
        facilitators[_facilitator] = true;

        emit FacilitatorAdded(_facilitator);
    }

    /**
     * @notice Remove a facilitator
     * @param _facilitator The address of the facilitator to remove.
     */
    function removeFacilitator(address _facilitator) public onlyOwner {
        facilitators[_facilitator] = false;

        emit FacilitatorRemoved(_facilitator);
    }
}
