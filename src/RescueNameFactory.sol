// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "solmate/auth/Owned.sol";

import "./RescueName.sol";

contract RescueNameFactory is Owned {

    address public rescueNameTemplate;
    constant uint256 public RENEW_DURATION = 365 days;

    event RescueNameVaultCreated(address newRescueNameVaultAddress);

    constructor(address _rescueNameTemplate) Owned(msg.sender) {
        rescueNameTemplate = _rescueNameTemplate;
    }

    function setRescueNameAddress(address _rescueNameTemplate) public onlyOwner {
        rescueNameTemplate = _rescueNameTemplate;
    }

    function createVault(string[] memory _names) public {
        address clone = Clones.clone(rescueNameTemplate);
        RescueNameVault(clone).initialize(_url, _signers, msg.sender);
        emit RescueNameVaultCreated(clone);
    }

    function execute(address[] vaults, string[][] names) public {
        // TODO: Write lmao
    }
}
