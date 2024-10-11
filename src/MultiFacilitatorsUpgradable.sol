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

    constructor() {
    }

    modifier onlyFacilitators {
        if(!facilitators[msg.sender]) {
            revert CallerIsNotFacilitator();
        }

        _;
    }

    function __MultiFacilitators_init(address admin) internal onlyInitializing {
        __Ownable_init();
        transferOwnership(admin);

        facilitators[admin] = true;
    }

    function addFacilitator(address _facilitator) public onlyOwner {
        facilitators[_facilitator] = true;

        emit FacilitatorAdded(_facilitator);
    }

    function removeFacilitator(address _facilitator) public onlyOwner {
        facilitators[_facilitator] = false;

        emit FacilitatorRemoved(_facilitator);
    }
}
