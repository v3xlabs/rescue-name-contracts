// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.19;

import "solmate/auth/Owned.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./RescueName.sol";
import "./interfaces/IETHRegistrarController.sol";

contract RescueNameFactory is Owned, ReentrancyGuard {

    IETHRegistrarController public controller;
    address payable public rescueNameTemplate;
    mapping(address => bool) public deployedContracts;

    event RescueNameVaultCreated(address newRescueNameVaultAddress);

    constructor(address payable _rescueNameTemplate, IETHRegistrarController _controller) Owned(msg.sender) {
        rescueNameTemplate = _rescueNameTemplate;
        controller = _controller;
        owner = msg.sender;
    }

    function setRescueNameAddress(address payable _rescueNameTemplate) public onlyOwner {
        rescueNameTemplate = _rescueNameTemplate;
    }

    function createVault(uint256 deadline, uint256 renewReward) public payable {
        address clone = Clones.clone(rescueNameTemplate);
        RescueNameVault(clone).initialize(controller, deadline, renewReward);
        emit RescueNameVaultCreated(clone);

        deployedContracts[clone] = true;
    }

    function execute(
        RescueNameVault[] calldata vaults, 
        string[][] calldata names,
        uint256 price,
        address payable payee
    ) public payable nonReentrant() {
        uint256 length = names.length;
        uint256 i = 0;
        while (i < length) {
            vaults[i].execute(names[i], price, payee);
        }
    }
}
