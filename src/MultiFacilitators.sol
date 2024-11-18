// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "solmate/src/auth/Owned.sol";

/**
 * @title MultiFacilitators
 * @notice A contract that allows multiple facilitators to be added and removed by the owner.
 */
contract MultiFacilitators is Owned {
    mapping(address => bool) public facilitators;

    event FacilitatorAdded(address indexed facilitator);
    event FacilitatorRemoved(address indexed facilitator);

    error CallerIsNotFacilitator();

    constructor(address admin) Owned(admin) {
        facilitators[admin] = true;
    }

    modifier onlyFacilitators() {
        if (!facilitators[msg.sender]) {
            revert CallerIsNotFacilitator();
        }

        _;
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
