// SPDX-License-Identifier: GPLv3
pragma solidity ~0.8.17;

import "solmate/auth/Owned.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./interfaces/IETHRegistrarController.sol";
import "./interfaces/IBaseRegistrar.sol";

contract RescueNameVault is Owned, ReentrancyGuard, Initializable {
    IETHRegistrarController controller;
    IBaseRegistrar baseregistrar = IBaseRegistrar(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85);
    uint256 public constant MAX_DEADLINE = 30;
    uint256 public RENEW_DURATION = 365 days;
    bool public isActive;
    uint256 public deadline;
    mapping(string => bool) public nameList;

    // Event for when name gets added to vault
    event NameAdded(address vault, string name);

    constructor() Owned(msg.sender) {
        _disableInitializers();
    }

    function initialize(IETHRegistrarController _controller, uint256 deadline, uint256 renewReward) external payable initializer {
        require(deadline <= MAX_DEADLINE, "Deadline overflow");

        // TODO: Test if this gets the correct address
        owner = msg.sender;
        isActive = true;
        controller = _controller;
    }

    function editDeadline(uint256 deadline) public payable onlyOwner {
        require(deadline <= MAX_DEADLINE, "Deadline overflow");
        deadline = deadline;
    }

    function toggleVault() public payable onlyOwner {
        !isActive;
    }

    function supplyList(string[] calldata names) public payable onlyOwner {
        uint256 length = names.length;
        uint256 i = 0;
        while (i < length) {
            nameList[names[i]] = true;
        }
    }

    function toggleName(string calldata name) public payable onlyOwner() {
        !nameList[name];
    }

    function execute(
        string[] calldata names,
        uint256 price,
        address payable payee
    ) public payable nonReentrant() {
        require(isActive, "Vault is not active");

        uint256 length = names.length;
        uint256 i = 0;
        uint256 total = price * length;

        while (i < length) {
            require(nameList[names[i]], "Name not in provided vault");
            // TODO: Check if we are currently (time) within deadline (expiryOfName - max_deadline)
            bytes32 labelhash = keccak256(abi.encodePacked(names[i]));
            baseregistrar.nameExpires(labelhash);

            controller.renew{value: price}(names[i], 365 * 24 * 60 * 60); 
            unchecked {
                ++i;
            }
        }

        // TODO: add check to prevent `price` from being too high

        // TODO: figure out rewards
        // multisig.transfer(msg.value);
    }

    receive() external payable {}

    // @dev Not needed?
    // function refund() external payable onlyOwner {
    //     payable(msg.sender).transfer(address(this).balance);
    // }
}
