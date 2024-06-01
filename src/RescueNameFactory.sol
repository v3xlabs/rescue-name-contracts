// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "solmate/auth/Owned.sol";

import "./interfaces/IUltraBulkRenewal.sol";
import "./RescueName.sol";

// Work in progress
contract RescueNameFactory is Owned {

    address public rescueNameTemplate;
    IUltraBulkRenewal controller;
    constant uint256 public RENEW_DURATION = 365 days;
    uint256 public MIN_RENEWAL_TIME;
    uint256 public constant MIN_DEADLINE = 1;
    uint256 public constant MAX_DEADLINE = 10;
    // uint256 public GAS_LIMIT = xyz; // ToDo
    uint256 vaultAmount;
    uint256 listAmount;

    event RescueNameVaultCreated(address newRescueNameVaultAddress);

    constructor(address _rescueNameTemplate, IUltraBulkRenewal _controller, uint256 _min_renewal) Owned(msg.sender) {
        rescueNameTemplate = _rescueNameTemplate;
        controller = _controller;
        MIN_RENEWAL_TIME = _min_renewal;
    }

    function setRescueNameAddress(address _rescueNameTemplate) public onlyOwner {
        rescueNameTemplate = _rescueNameTemplate;
    }

    function createVault(uint256 deadline, uint256 renewReward) public payable {
        address clone = Clones.clone(rescueNameTemplate);
        RescueNameVault(clone).initialize(_url, _signers, msg.sender);
        emit RescueNameVaultCreated(clone);
    }

    function topupVault(uint256 vaultId) public payable {
        // TODO: Write lmao
    }

    function editVault(uint256 vaultId, uint256 deadline) public payable {
        // TODO: Write lmao
    }

    function supplyList(uint256 vaultId, string[] calldata names) public payable {
        // TODO: Write lmao
    }

    function toggleList(uint256 vaultId) public payable {
        // TODO: Write lmao
    }

    function execute(
        uint256[] calldata vaultIds, 
        string[][] calldata names,
        uint256 price,
        address payable multisig
    ) public payable nonReentrant() {
        // TODO: Write lmao
    }

    function executeSingle(
        uint256 vaultId,
        string[] calldata names,
        uint256 price,
        address payable multisig
    ) public payable nonReentrant() {
        // TODO: Write lmao
    }
}
