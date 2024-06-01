// SPDX-License-Identifier: GPLv3
pragma solidity ~0.8.17;

import "./ETHRegistrarController.sol";
import "./IUltraBulkRenewal.sol";
// import "solmate/auth/Owned.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

struct VaultConfig {
    address owner;
    uint256 deadline;
    uint256 balance; // wei
    uint256 renewReward; // wei
    uint256 listId;
    bool isActive;
    // ToDo
}

contract NameValutRescue is Ownable, ReentrancyGuard {
    // PUBLIC VARIABLES
    IUltraBulkRenewal controller;
    uint256 public MIN_RENEWAL_TIME;
    uint256 public constant MIN_DEADLINE = 1;
    uint256 public constant MAX_DEADLINE = 10;
    // uint256 public GAS_LIMIT = xyz; // ToDo
    uint256 vaultAmount;
    uint256 listAmount = 1;

    // MAPPINGS
    mapping(uint256 => VaultConfig) public vaults; // vault id to its full config
    mapping(uint256 => mapping(string => bool)) public listNames; // list id to name

    constructor(IUltraBulkRenewal _controller, uint256 _min_renewal) Ownable(msg.sender) {
        controller = _controller;
        MIN_RENEWAL_TIME = _min_renewal;
    }

    function createVault(uint256 deadline, uint256 renewReward) public payable {
        require(deadline >= MIN_DEADLINE && deadline <= MAX_DEADLINE , "Caller is not owner");
        vaults[vaultAmount] = VaultConfig(
			msg.sender,
            deadline, // in days, days to expiry has to be lower than that | possible range from 1 - 30
            msg.value,
            renewReward,
            0,
            true
            // ToDo
		);
		vaultAmount++;
    }

    function topUpVault(uint256 vaultId) public payable {
        VaultConfig storage vault = vaults[vaultId];
        require(msg.sender == vault.owner, "Caller is not vault owner");
        require(msg.value != 0, "Can't add 0 to rewards");
        vault.balance += msg.value;
    }

    function editVault(uint256 vaultId, uint256 deadline) public payable {
        VaultConfig storage vault = vaults[vaultId];
        require(msg.sender == vault.owner, "Caller is not vault owner");
        vault.deadline = deadline;
    }

    function toggleVault(uint256 vaultId) public payable {
        VaultConfig storage vault = vaults[vaultId];
        require(msg.sender == vault.owner, "Caller is not vault owner");
        !vault.isActive;
    }

    function supplyList(uint256 vaultId, string[] calldata names) public payable {
        VaultConfig storage vault = vaults[vaultId];
        require(msg.sender == vault.owner, "Caller is not vault owner");
        uint256 length = names.length;
        uint256 i = 0;
        while (i < length) {
            listNames[listAmount][names[i]] = true;
        }
        vault.listId = listAmount;
        listAmount++;
    }

    function toggleListName(uint256 vaultId, string calldata name) public payable {
        VaultConfig storage vault = vaults[vaultId];
        require(msg.sender == vault.owner, "Caller is not vault owner");
        uint256 listId = vault.listId;
        !listNames[listId][name];
    }    

    function executeMultiple(
        uint256[] calldata vaultIds, 
        string[][] calldata names,
        uint256 price,
        address payable multisig
    ) external payable nonReentrant() {
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
        VaultConfig storage vault = vaults[vaultId];
        require(vault.balance >= vault.renewReward, "Not enough balance for reward payout");
        uint256 listId = vault.listId;
        uint256 length = names.length;
        uint256 i = 0;
        while (i < length) {
             require(listNames[listId][names[i]], "Name not in provided vault");
        }
        // We are assuming ultra bulk checks if reneval is possible, if price is correct etc and does reverts
        controller.renewAll{value: price}(names, MIN_RENEWAL_TIME, price);
        vault.balance - vault.renewReward;
        multisig.transfer(msg.value);
    }

    // @dev Not needed?
    // function refund() external payable onlyOwner {
    //     payable(msg.sender).transfer(address(this).balance);
    // }
}
