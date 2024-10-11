// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library CoolTimeLib {
    struct DistributionInfo {
        uint256 lastDistributedAt;
        uint256 amount;
    }

    error NotEnoughCooltime();
    error ExceededMaxAmount();

    /**
     * @notice Validate the distribution info
     * @param info The distribution info.
     * @param cooltime The cooltime.
     * @param maxAmount The maximum amount.
     */
    function validate(DistributionInfo memory info, uint256 cooltime, uint256 maxAmount) internal view {
        // if not distributed yet, the validation is passed
        if (info.lastDistributedAt == 0) {
            return;
        }

        // check if the cooltime is passed
        if (block.timestamp - info.lastDistributedAt < cooltime) {
            revert NotEnoughCooltime();
        }

        // check if the amount is exceeded
        if (info.amount >= maxAmount) {
            revert ExceededMaxAmount();
        }
    }
}
