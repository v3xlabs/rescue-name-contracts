// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.19;

import "solmate/auth/Owned.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/IETHRegistrarController.sol";
import "./interfaces/IBaseRegistrar.sol";

contract RescueNameFactory is Owned, ReentrancyGuard {

    event NameAdded(uint256 vault, string name);
    event NameRemoved(uint256 vault, string name);

    IBaseRegistrar public constant baseregistrar = IBaseRegistrar(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85);
    IETHRegistrarController public constant controller = IETHRegistrarController(0x253553366Da8546fC250F225fe3d25d0C782303b);

    uint256 public constant MAX_DEADLINE = 30;
    uint256 public constant RENEW_DURATION = 365 days;

    uint256 public lastVaultId = 0;
    mapping(uint256 => address) public vaultToOwner;
    mapping(uint256 => bool) public vaultIsActive;
    mapping(uint256 => mapping(string => bool)) public vaultNameList;
    mapping(uint256 => uint256) public vaultDeadline;
    mapping(uint256 => uint256) public vaultRenewReward;
    mapping(uint256 => uint256) public vaultBalance;

    event RescueNameVaultCreated(uint256 vaultId, address owner);

    constructor() Owned(msg.sender) {}

    function createVault(uint256 deadline, uint256 renewReward) public payable {
        emit RescueNameVaultCreated(lastVaultId, msg.sender);
        lastVaultId++;
    }

    function execute(
        uint256[] calldata vaults, 
        string[][] calldata names,
        uint256 price,
        address payable payee
    ) public payable nonReentrant() {
        uint256 length = names.length;
        uint256 i = 0;
        while (i < length) {
            require(vaultIsActive[vaults[i]], "Vault is not active");

            uint256 length = names.length;
            uint256 j = 0;
            uint256 total = price * length;

            while (j < length) {
                require(vaultNameList[vaults[i]][names[i][j]], "Name not in vault");
                // TODO: Check if we are currently (time) within deadline (expiryOfName - max_deadline)
                bytes32 labelhash = keccak256(abi.encodePacked(names[i][j]));
                baseregistrar.nameExpires(uint256(labelhash));

                controller.renew{value: price}(names[i][j], RENEW_DURATION * 24 * 60 * 60); 
                unchecked {
                    ++i;
                }
            }

            // TODO: add check to prevent `price` from being too high

            // uint256 reward = // TODO: calculate reward
            // payable(payee).transfer(reward);
            // vaultBalance[vaults[i]] -= reward;
        }
    }

    /* Vault Specific Functions */

    function topupVault(uint256 vault) public payable {
        vaultBalance[vault] += msg.value;
    }

    function toggleVaultActive(uint256 vault) public payable onlyOwner {
        vaultIsActive[vault] = !vaultIsActive[vault];
    }

    function toggleName(uint256 vault, string calldata name) public payable onlyOwner() {
        vaultNameList[vault][name] = !vaultNameList[vault][name];

        if (vaultNameList[vault][name]) {
            emit NameAdded(vault, name);
        } else {
            emit NameRemoved(vault, name);
        }
    }

    function supplyList(uint256 vault, string[] calldata names) public payable onlyOwner {
        uint256 length = names.length;
        uint256 i = 0;
        while (i < length) {
            vaultNameList[vault][names[i]] = true;
            emit NameAdded(vault, names[i]);
            unchecked {
                ++i;
            }
        }
    }


}
