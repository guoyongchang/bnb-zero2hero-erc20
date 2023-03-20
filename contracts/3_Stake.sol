// SPDX-License-Identifier: GPL-3.0

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity >=0.8.2 <0.9.0;

interface Mintable {
    function mint(address addr, uint256 amount) external;
}

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Stake is Ownable, ReentrancyGuard {
    address stakeToken;
    address rewardToken;

    uint256 constant RAY = 10 ** 27;

    mapping(address => uint256) public userStakedAmount;
    mapping(address => uint256) public userRewardPerTokenIndex;
    mapping(address => uint256) public rewardsAccrued;

    uint256 public lastRewardPerTokenIndex;
    uint256 public lastUpdatedTimestamp;
    uint256 public rewardEverySecond;
    uint256 public totalStakedAmount;

    constructor(
        address stakingTokenAddr,
        address rewardsTokenAddr,
        uint _rewardEverySecond
    ) {
        stakeToken = stakingTokenAddr;
        rewardToken = rewardsTokenAddr;
        rewardEverySecond = _rewardEverySecond;
    }

    function stake(uint256 amount) external nonReentrant {
        _updateIndex();

        userStakedAmount[_msgSender()] += amount;
        totalStakedAmount += amount;

        IERC20(stakeToken).transferFrom(_msgSender(), address(this), amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        _updateIndex();

        userStakedAmount[_msgSender()] -= amount;
        totalStakedAmount -= amount;

        // safe
        IERC20(stakeToken).transfer(_msgSender(), amount);
    }

    function withdrawRewards() external nonReentrant {
        _updateIndex();

        uint256 reward = rewardsAccrued[_msgSender()];
        rewardsAccrued[_msgSender()] = 0;

        // safe
        Mintable(rewardToken).mint(_msgSender(), reward);
    }

    function rewardsEarned(address user) external view returns (uint256) {
        return
            rewardsAccrued[user] +
            ((_getLatestRewardPerTokenIndex() - userRewardPerTokenIndex[user]) *
                userStakedAmount[user]) /
            RAY;
    }

    function _updateIndex() internal {
        if (block.timestamp > lastUpdatedTimestamp) {
            lastRewardPerTokenIndex = _getLatestRewardPerTokenIndex();

            rewardsAccrued[_msgSender()] +=
                ((lastRewardPerTokenIndex -
                    userRewardPerTokenIndex[_msgSender()]) *
                    userStakedAmount[_msgSender()]) /
                RAY;

            userRewardPerTokenIndex[_msgSender()] = lastRewardPerTokenIndex;
            lastUpdatedTimestamp = block.timestamp;
        }
    }

    function _getLatestRewardPerTokenIndex() public view returns (uint256) {
        if (totalStakedAmount == 0) {
            return lastRewardPerTokenIndex;
        } else {
            return
                (RAY *
                    (block.timestamp - lastUpdatedTimestamp) *
                    rewardEverySecond) /
                totalStakedAmount +
                lastRewardPerTokenIndex;
        }
    }
}
