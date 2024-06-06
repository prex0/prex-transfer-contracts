// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @notice Mock of ERC20 contract
 */
contract DemoToken is ERC20Permit {
    address minter;

    modifier onlyMinter() {
        require(msg.sender == minter, "Only minter can call this function");
        _;
    }

    constructor(string memory _name, string memory _symbol, address _minter) ERC20(_name, _symbol) ERC20Permit(_name) {
        minter = _minter;
    }

    function mint(address account, uint256 amount) public onlyMinter {
        _mint(account, amount);
    }
}
