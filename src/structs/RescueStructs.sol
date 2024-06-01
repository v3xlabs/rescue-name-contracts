// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.19;

struct VaultConfig {
    address owner;
    uint256 deadline;
    uint256 balance; // wei
    uint256 renewReward; // wei
    uint256 listId;
    bool isActive;
    // ToDo
}