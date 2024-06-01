// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./RescueName.sol";
import "./interfaces/IUltraBulkRenewal.sol";
import "./structs/RescueStructs.sol";

contract RescueNameFactory is Ownable, ReentrancyGuard {

    // PUBLIC VARIABLES
    uint256 public MIN_RENEWAL_TIME;
    uint256 public constant MIN_DEADLINE = 1;
    uint256 public constant MAX_DEADLINE = 10;
    uint256 public RENEW_DURATION = 365 days;
    // uint256 public GAS_LIMIT = xyz; // ToDo
    IUltraBulkRenewal controller;
    uint256 vaultAmount;
    uint256 listAmount = 1;
    address public rescueNameTemplate;

    // MAPPINGS
    mapping(uint256 => RescueNameVault) public vaults; // vault -> vault config

    event RescueNameVaultCreated(address newRescueNameVaultAddress);

    constructor(address _rescueNameTemplate, IUltraBulkRenewal _controller, uint256 _min_renewal) Ownable(msg.sender) {
        rescueNameTemplate = _rescueNameTemplate;
        controller = _controller;
        MIN_RENEWAL_TIME = _min_renewal;
    }

    function setRescueNameAddress(address _rescueNameTemplate) public onlyOwner {
        rescueNameTemplate = _rescueNameTemplate;
    }

    function createVault(uint256 _min_renewal, uint256 deadline, uint256 renewReward) public payable {
        address clone = Clones.clone(rescueNameTemplate);
        RescueNameVault(clone).initialize(controller, _min_renewal, deadline, renewReward);
        emit RescueNameVaultCreated(clone);
    }

    function vaultById(uint256 vaultId) public view returns(VaultConfig memory) {
        RescueNameVault rescueContract = vaults[vaultId];
        VaultConfig memory config = rescueContract.getVault();
        return config;
    }

    function topUpVault(uint256 vaultId) public payable {
        RescueNameVault rescueContract = vaults[vaultId];
        rescueContract.topUpVault();
    }

    function editVault(uint256 vaultId, uint256 deadline) public payable {
        RescueNameVault rescueContract = vaults[vaultId];
        rescueContract.editVault(deadline);
    }

    function supplyList(uint256 vaultId, string[] calldata names) public payable {
        RescueNameVault rescueContract = vaults[vaultId];
        rescueContract.supplyList(names);
    }

    function toggleList(uint256 vaultId) public payable {
        RescueNameVault rescueContract = vaults[vaultId];
        rescueContract.toggleVault();
    }

    function execute(
        uint256[] calldata vaultIds, 
        string[][] calldata names,
        uint256 price,
        address payable multisig
    ) public payable nonReentrant() {
        uint256 length = names.length;
        uint256 i = 0;
        while (i < length) {
            executeSingle(vaultIds[i], names[i], price, multisig);
        }
    }

    function executeSingle(
        uint256 vaultId,
        string[] calldata names,
        uint256 price,
        address payable multisig
    ) public payable nonReentrant() {
        RescueNameVault rescueContract = vaults[vaultId];
        rescueContract.executeSingle(names, price, multisig);
    }
}
