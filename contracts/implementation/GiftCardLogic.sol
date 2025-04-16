// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../feature/GiftCardTrade.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract GiftCardLogic is Initializable, GiftCardTrade {
    /**
     * @dev Initializes the contract with a price feed address
     * @param _priceFeedAddress The address of the ETH/USD price feed
     */
    function initialize(address _priceFeedAddress) public initializer {
        name = "Demo DApp GiftCard";
        symbol = "DDAG";
        contractOwner = msg.sender;
        if (nextGiftCardId == 0) nextGiftCardId = 1; // start from 1 to avoid 0 index because it will be used for invalid id
        if (_priceFeedAddress == address(0)) revert InvalidPriceFeedAddress();

        // Normally in solidity,the map will return 0 if the key is not found.
        // Therefore, to prevent the ambiguousity of the mapping between the cardId to the index of buyableList in the mapIdToBuyableListIndex 
        // we will ensure that the index 0 of buyableList will never be used.
        if (buyableListIds.length == 0) buyableListIds.push(0);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        admins[msg.sender] = true;
    }
}
