// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// mock contract for local testing only
contract MockLocalAggregratorV3 is AggregatorV3Interface {
    int256 private price;

    constructor(int256 _initialPrice) {
        price = _initialPrice;
    }

    function decimals() external pure override returns (uint8) {
        return 8; // Like the real Chainlink USD feeds
    }

    function description() external pure override returns (string memory) {
        return "Mock Price Feed";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        return (_roundId, price, block.timestamp, block.timestamp, _roundId);
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        return (0, price, block.timestamp, block.timestamp, 0);
    }

    // Helper function to update price
    function updatePrice(int256 _newPrice) external {
        price = _newPrice;
    }
}
