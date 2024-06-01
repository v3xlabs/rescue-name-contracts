// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./interfaces/IUltraBulkRenewal.sol";

struct VaultConfig {
    address owner;
    uint256 deadline;
    uint256 balance; // wei
    uint256 renewReward; // wei
    uint256[] listIds;
    // ToDo
}

contract RescueNameVault is Initializable, Ownable {

      /**
     * Constructor
     */
    constructor() Owned(msg.sender) {
        _disableInitializers();
    }

    function initialize(IUltraBulkRenewal _controller, uint256 _min_renewal) external initializer {
        controller = _controller;
        MIN_RENEWAL_TIME = _min_renewal;
    }

    // CONSTANTS
    IUltraBulkRenewal controller;
    uint256 public MIN_RENEWAL_TIME;

    // PUBLIC VARIABLES
    uint256 vaultAmount;

    // MAPPINGS
    mapping(uint256 => VaultConfig) public vaults;
    mapping(uint256 => string[]) public vaultNames;

    constructor(IUltraBulkRenewal _controller, uint256 _min_renewal) Ownable(msg.sender) {
        controller = _controller;
        MIN_RENEWAL_TIME = _min_renewal;
    }

    function createVault() public payable {

    }

    function topupVault(uint256 vaultId) public payable {

    }

    function editVault(uint256 vaultId) public payable {

    }

    function supplyList(uint256 vaultId) public payable {

    }

    function renewAll(
        string[] calldata names,
        uint256 duration,
        uint256 price
    ) external payable override {
        uint256 length = names.length;
        uint256 i = 0;
        while (i < length) {
            controller.renew{value: price}(names[i], duration);
            unchecked {
                ++i;
            }
        }
    }
}
