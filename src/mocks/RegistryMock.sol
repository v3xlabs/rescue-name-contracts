// SPDX-License-Identifier: GPLv3
pragma solidity ~0.8.17;

import "../interfaces/IUltraBulkRenewal.sol";

struct Price {
        uint256 base;
        uint256 premium;
    }

contract RegistryMock is IUltraBulkRenewal {
     function rentPrice(
        string memory name,
        uint256 duration
    ) public view returns (Price memory price) {
        return Price(
			100,
            100
		);
    }

     function renewAll(
        string[] calldata names,
        uint256 duration,
        uint256 price
    ) external payable override {
        Price memory renewalPrice = rentPrice("luc.eth", 1);
        require(price == renewalPrice.base + renewalPrice.premium, "Price has to match");
    }
}
