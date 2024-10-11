// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library CoolTimeLib {
    struct DistributionInfo {
        uint256 lastDistributedAt;
        uint256 amount;
    }

    error NotEnoughCooltime();
    error ExceededMaxAmount();

    function validate(DistributionInfo memory info, uint256 cooltime, uint256 maxAmount) internal view {
        if (info.lastDistributedAt == 0) {
            return;
        }

        if (block.timestamp - info.lastDistributedAt < cooltime) {
            revert NotEnoughCooltime();
        }

        if (info.amount >= maxAmount) {
            revert ExceededMaxAmount();
        }
    }
}
