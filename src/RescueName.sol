// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.19;

import "solmate/auth/Owned.sol";

import "./interfaces/IETHRegistrarController.sol";
import "./interfaces/IBaseRegistrar.sol";
import "./interfaces/IPriceOracle.sol";

// struct Price {
//         uint256 base;
//         uint256 premium;
//     }

// interface IPriceOracle {
//     struct Price {
//         uint256 base;
//         uint256 premium;
//     }
// }

// struct RentPrice { 
//    string name;
//    string duration;
//    uint book_id;
// }

contract RescueName is Owned {

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
        // require(deadline <= MAX_DEADLINE, "Deadline too high");
        // TODO uncomment check, removed just for testing

        vaultDeadline[lastVaultId] = deadline;
        vaultRenewReward[lastVaultId] = renewReward;
        vaultToOwner[lastVaultId] = msg.sender;
        vaultBalance[lastVaultId] = msg.value;
        vaultIsActive[lastVaultId] = true;

        emit RescueNameVaultCreated(lastVaultId, msg.sender);

        unchecked {
            lastVaultId++;
        }
    }

    function getPrice(uint256[] calldata vaults, 
        string[][] calldata names,
        uint256 price,
        address payable payee) public view returns (uint256 result) {
            uint256 length = names.length;
            uint256 rentPrice = controller.rentPrice(names[0][0], RENEW_DURATION).base;
            return rentPrice;
    }

    function execute(
        uint256[] calldata vaults, 
        string[][] calldata names,
        address payable payee
    ) public payable {
        uint256 length = names.length;
        uint256 i = 0;
        uint256 price = controller.rentPrice(names[0][0], RENEW_DURATION).base;
        while (i < length) {
            require(vaultIsActive[vaults[i]], "Vault is not active");

            uint256 length = names.length;
            uint256 j = 0;

            while (j < length) {
                require(vaultNameList[vaults[i]][names[i][j]], "Name not in vault");
                bytes32 labelhash = keccak256(abi.encodePacked(names[i][j]));
                uint256 expiresAt = baseregistrar.nameExpires(uint256(labelhash));
                // TODO: include grace period
                // require(expiresAt - block.timestamp <= vaultDeadline[vaults[i]], "Deadline not met");
                // TODO uncomment check, removed just for testing

                controller.renew{value: price}(names[i][j], RENEW_DURATION); 
                unchecked {
                    ++j;
                }
            }

            // TODO: add check to prevent `price` from being too high

            // uint256 reward = // TODO: calculate reward
            // payable(payee).transfer(reward);
            // vaultBalance[vaults[i]] -= reward;

            unchecked {
                ++i;
            }
        }
    }

    /* Vault Specific Functions */

    function topupVault(uint256 vault) public payable {
        vaultBalance[vault] += msg.value;
    }

    function toggleVaultActive(uint256 vault) public payable {
        require(msg.sender == vaultToOwner[vault], "Not owner");

        vaultIsActive[vault] = !vaultIsActive[vault];
    }

    function toggleName(uint256 vault, string calldata name) public payable {
        require(msg.sender == vaultToOwner[vault], "Not owner");

        vaultNameList[vault][name] = !vaultNameList[vault][name];

        if (vaultNameList[vault][name]) {
            emit NameAdded(vault, name);
        } else {
            emit NameRemoved(vault, name);
        }
    }

    function supplyList(uint256 vault, string[] calldata names) public payable {
        require(msg.sender == vaultToOwner[vault], "Not owner");

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

    /* Owner Only Functions */

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function withdrawVault(uint256 vault) public {
        require(msg.sender == vaultToOwner[vault] || msg.sender == owner, "Not owner");
        vaultBalance[vault] = 0;
        payable(msg.sender).transfer(vaultBalance[vault]);
    }
}
