// SPDX-License-Identifier: GPLv3
pragma solidity >=0.8.25;

interface IUltraBulkRenewal {
    function renewAll(
        string[] calldata names,
        uint256 duration,
        uint256 price
    ) external payable;
}
