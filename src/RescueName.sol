// SPDX-License-Identifier: GPLv3
pragma solidity ~0.8.17;

// import "solmate/auth/Owned.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

// import "./ETHRegistrarController.sol";
import "./interfaces/IUltraBulkRenewal.sol";
import "./structs/RescueStructs.sol";

contract RescueNameVault is Ownable, ReentrancyGuard, Initializable {
    // PUBLIC VARIABLES
    IUltraBulkRenewal controller;
    uint256 public MIN_RENEWAL_TIME;
    uint256 public constant MIN_DEADLINE = 1;
    uint256 public constant MAX_DEADLINE = 30;
    // uint256 public GAS_LIMIT = xyz; // ToDo

    // MAPPINGS
    mapping(string => bool) public listNames; // list id to name

    VaultConfig public vault;

    constructor() Ownable(msg.sender) {
        _disableInitializers();
    }

    function initialize(IUltraBulkRenewal _controller, uint256 _min_renewal, uint256 deadline, uint256 renewReward) external payable initializer {
        require(deadline >= MIN_DEADLINE && deadline <= MAX_DEADLINE , "Deadline overflow");
        vault = VaultConfig(
			msg.sender,
            deadline, // in days, days to expiry has to be lower than val
            msg.value,
            renewReward,
            0,
            true
            // ToDo
		);

        controller = _controller;
        MIN_RENEWAL_TIME = _min_renewal;
    }

    function getVault() public view returns (VaultConfig memory) {
        // Add additional filtering etc
        return vault;
    }

    function topUpVault() public payable {
        require(msg.sender == vault.owner, "Caller is not vault owner");
        require(msg.value != 0, "Can't add 0 to rewards");
        vault.balance += msg.value;
    }

    function editVault(uint256 deadline) public payable {
        require(msg.sender == vault.owner, "Caller is not vault owner");
        vault.deadline = deadline;
    }

    function toggleVault() public payable {
        require(msg.sender == vault.owner, "Caller is not vault owner");
        !vault.isActive;
    }

    function supplyList(string[] calldata names) public payable {
        require(msg.sender == vault.owner, "Caller is not vault owner");
        uint256 length = names.length;
        uint256 i = 0;
        while (i < length) {
            listNames[names[i]] = true;
        }
        vault.listId = length;
    }

    function toggleListName(string calldata name) public payable {
        require(msg.sender == vault.owner, "Caller is not vault owner");
        !listNames[name];
    }    

    // function executeMultiple(
    //     uint256[] calldata vaultIds, 
    //     string[][] calldata names,
    //     uint256 price,
    //     address payable multisig
    // ) external payable nonReentrant() {
    //     uint256 length = names.length;
    //     uint256 i = 0;
    //     while (i < length) {
    //         executeSingle(vaultIds[i], names[i], price, multisig);
    //     }
    // }
    
    function executeSingle(
        // uint256 vaultId,
        string[] calldata names,
        uint256 price,
        address payable multisig
    ) public payable nonReentrant() {
        // VaultConfig storage vault = vaults[vaultId];
        require(vault.balance >= vault.renewReward, "Not enough balance for reward payout");
        // uint256 listId = vault.listId;
        uint256 length = names.length;
        uint256 i = 0;
        require(length < vault.listId, "Names index overflow");
        while (i < length) {
             require(listNames[names[i]], "Name not in provided vault");
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
