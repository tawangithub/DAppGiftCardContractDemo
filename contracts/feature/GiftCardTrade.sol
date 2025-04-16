// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../feature/GiftCardAdmin.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract GiftCardTrade is GiftCardAdmin {

    struct PaginatedGiftCards {
        GiftCard[] items;
        address[] owners;
        uint256 total;
        uint256 page;
        uint256 limit;
    }

    event GiftCardIssued(uint256 indexed id, address issuer, address owner, uint256 balanceInUSD_e2);
    event GiftCardSetSellable(uint256 indexed id, bool sellable, uint256 sellPrice);
    event GiftCardSetSellPrice(uint256 indexed id, uint256 sellPrice);

    function _convertUSDToWei(uint256 _amountInUSD_e2) private view returns (uint256) {
        uint8 decimal = ethUsdPriceFeed.decimals();
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        return (_amountInUSD_e2 * 10 ** decimal) * 10 ** 16 / uint256(price);
    }

    /**
     * @dev Function for the customer to buy the gift card from the shop
     * @param _giftCardTypeId The id of the gift card type
     * @param _numberOfGiftCards The number of gift cards to buy
     */
    function buyGiftCardFromShop(uint256 _giftCardTypeId, uint256 _numberOfGiftCards) external payable {
        TypeOfGiftCardFromShop storage giftCardType = typesOfGiftCardFromShop[_giftCardTypeId];
        require(giftCardType.numberOfRemainingGiftCards >= _numberOfGiftCards, "Not enough remaining gift cards");
        uint256 totalPrice = _convertUSDToWei(giftCardType.sellPriceInUSD_e2 * _numberOfGiftCards);
        require(msg.value >= totalPrice, "Insufficient funds");

        // Refund excess amount if any
        uint256 excessAmount = msg.value - totalPrice;

        for(uint32 i = 0; i < _numberOfGiftCards; i++) {
            _mint(msg.sender, nextGiftCardId, staticTokenURI);
            giftCards[nextGiftCardId] = GiftCard({
                id: nextGiftCardId,
                issuer: address(this),
                issueDate: block.timestamp,
                startDate: block.timestamp + (giftCardType.waitingAfterBuyInMonths == 0 ? 0 : giftCardType.waitingAfterBuyInMonths * 30 days),
                expirationDate: giftCardType.expireAfterBuyInYears == 0 ? 0 : block.timestamp + giftCardType.expireAfterBuyInYears * 366 days,
                balanceInUSD_e2: giftCardType.balanceInUSD_e2,
                sellable: false,
                sellPriceInUSD_e2: 0
            });
            giftCardType.numberOfRemainingGiftCards--;
            myGiftCardsHistory[msg.sender].push(nextGiftCardId);
            emit GiftCardIssued(nextGiftCardId, address(this), msg.sender, giftCardType.balanceInUSD_e2);
            nextGiftCardId++;
        }
        if (excessAmount > 0) {
            (bool success, ) = msg.sender.call{value: excessAmount}("");
            require(success, "Refund failed");
        }
    }

    /**
     * @dev Function to allow the giftcard's owner to sell thier gift cards via our app's market place only
     * For the 3rd party market place such as opensea will, on the other hand, be handled by the standard function approve() from ERC721
     * @param _id The id of the gift card
     * @param _sellable Whether the gift card is sellable
     * @param _sellPriceInUSD_e2 The sell price of the gift card in USD (supporting 2 decimal digits)
     */
    function setSellable(uint256 _id, bool _sellable, uint256 _sellPriceInUSD_e2) external onlyCardOwner(_id) {
        GiftCard storage card = giftCards[_id];
        if (_sellable) {
            // avoid duplication
            require(card.sellable == false, "Gift card is already listed in the app's market place");
            // ensure that it sync with the buyable list
            require(mapOfIdToBuyableListIndex[_id] == 0, "Gift card is already listed in the app's market place");
            require(_sellPriceInUSD_e2 > 0, "Invalid sell price"); 
            card.sellPriceInUSD_e2 = _sellPriceInUSD_e2;
            card.sellable = _sellable;
            buyableListIds.push(_id); // add the id to the buyable list for iterable
            mapOfIdToBuyableListIndex[_id] = buyableListIds.length - 1; // update the revert mapping between card id to the index of the buyable list (for fast removal later)
        } else {
            require(card.sellable == true, "Gift card is currently not in the market place");
            // ensure that it sync with the buyable list
            uint256 index = mapOfIdToBuyableListIndex[_id]; // remove the id from the buyable list
                 
            card.sellPriceInUSD_e2 = 0;
            card.sellable = _sellable;
            uint256 idOfTheLastItem = buyableListIds[buyableListIds.length - 1];
            buyableListIds[index] = idOfTheLastItem; // swap the removal index to the last index (for optimization of removal)
            buyableListIds.pop(); // after swap we just remove the last item
            mapOfIdToBuyableListIndex[idOfTheLastItem] = index; // update the mapping of the last item to the new index
            delete mapOfIdToBuyableListIndex[_id]; // remove the mapping between card id to the index of the buyable list
        }
        emit GiftCardSetSellable(_id, _sellable, _sellPriceInUSD_e2);
    }

    /** 
     * @dev Function for the giftcard's owner to set the gift card to be sellable
     * @param _id The id of the gift card
     * @param _sellPriceInUSD_e2 The sell price of the gift card in USD (supporting 2 decimal digits)
    */ 
    function setSellPrice(uint256 _id, uint256 _sellPriceInUSD_e2) external onlyCardOwner(_id) {
        GiftCard storage card = giftCards[_id];
        card.sellPriceInUSD_e2 = _sellPriceInUSD_e2;
        emit GiftCardSetSellPrice(_id, _sellPriceInUSD_e2);
    }

    /**
     * @dev Function for anyone to buy the resold gift card from the giftcard's owner
     * @param _id The id of the gift card
     */
    function buyTheResoldGiftCard(uint256 _id) external payable {
        GiftCard storage card = giftCards[_id];
        address owner = ownerOf(_id);
        require(card.sellable, "Gift card not sellable");

        uint256 weiAmount = _convertUSDToWei(card.sellPriceInUSD_e2);
        require(weiAmount <= msg.value, "Insufficient funds");

        approve(msg.sender, _id);
        safeTransferFrom(owner, msg.sender, _id, "");

        payable(owner).transfer(weiAmount);

        uint256 excessAmount = msg.value - weiAmount;
        if (excessAmount > 0) {
            (bool success, ) = msg.sender.call{value: excessAmount}("");
            require(success, "Refund failed");
        }
    }

    /**
     * @dev Function for anyone to view the gift card
     * @param _id The id of the gift card
     * @return The gift card
     */
    function viewGiftCard(uint256 _id) external view returns (GiftCard memory) {
        return giftCards[_id];
    }

    /**
     * @dev Function for anyone to view the list of the 2nd hand giftcards that are buyable
     * @param _page The page number
     * @param _limit The number of gift cards per page
     * @return The gift cards
     */
    function listBuyableGiftCards(uint256 _page, uint256 _limit) external view returns (PaginatedGiftCards memory) {
       // start from index 1 because index 0 is used as no mapping found in the reverse mapping table
       require(_page > 0, "Page must be at least 1");
       require(_limit > 0, "Limit must be greater than 0");
       uint256 offset = ((_page - 1) * _limit) + 1;
       uint256 itemsLeft = buyableListIds.length - offset;
       uint256 pageCount = itemsLeft < _limit ? itemsLeft : _limit;
       GiftCard[] memory paginatedBuyableCards = new GiftCard[](pageCount);
       address[] memory owners = new address[](pageCount);
       uint256 addedIndex = 0;
       for (uint256 i = offset; i < offset + pageCount && i < buyableListIds.length; i++) {
         GiftCard memory card = giftCards[buyableListIds[i]];
         paginatedBuyableCards[addedIndex] = card;
         owners[addedIndex] = ownerOf(card.id);
         addedIndex++;
       }

        return PaginatedGiftCards({
            items: paginatedBuyableCards,
            owners: owners,
            total: buyableListIds.length - 1,
            page: _page,
            limit: _limit
        });
    }

    /**
     * @dev Function for the giftcard's owner to view all of his own gift cards
     * @return The gift cards
     */ 
    function listMyOwnGiftCards() external view returns (GiftCard[] memory) {
        address owner = msg.sender;
        uint256 count = 0;
        uint256[] memory myHistoryIds = myGiftCardsHistory[owner];
        for (uint256 i = 0; i < myHistoryIds.length; i++) {
            GiftCard memory card = giftCards[myHistoryIds[i]];
            // select for the card that currently belongs to this user (not being sold or transferred yet)
            if (ownerOf(card.id) == owner) {
                count++;
            }
        }

        GiftCard[] memory myGiftCards = new GiftCard[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < myHistoryIds.length; i++) {
            GiftCard memory card = giftCards[myHistoryIds[i]];
            // ensure that the card is not transferred or sold to other users.
            if (ownerOf(card.id) == owner) {
                myGiftCards[index] = card;
                index++;
            }
        }
        // the myGiftCards array is sorted by the hold date. 
        // It is allow to have duplicate id in rare case, if the user transfer to other users and then transfer back to the original owner
        // so the fetcher (frontend) need to filter out the rare possible duplicate id
        return myGiftCards;
    }

     /**
     * @dev This function will handle the transfer card from one user to another inclluding reset the sellable status and sell price 
     // and remove from the buyable list
     * @param from The address of the sender
     * @param to The address of the recipient
     * @param tokenId The id of the gift card
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId); // calls _transfer() internally and check for the ownership of the card
        GiftCard storage card = giftCards[tokenId];
        card.sellable = false; // set the gift card to be not sellable 
        card.sellPriceInUSD_e2 = 0; // set the sell price back to 0
        myGiftCardsHistory[to].push(tokenId);
        approve(address(0), tokenId); // disapprove the card after transfer
        _removeFromBuyableList(tokenId);
        emit Transfer(from, to, tokenId);
    }

    function _removeFromBuyableList(uint256 _id) private {
        uint256 index = mapOfIdToBuyableListIndex[_id]; // remove the id from the buyable list
        if (index != 0) {
            // if it is in the buyable list, we will remove it
            uint256 idOfTheLastItem = buyableListIds[buyableListIds.length - 1];
            buyableListIds[index] = idOfTheLastItem; // swap the removal index to the last index (for optimization of removal)
            buyableListIds.pop(); // after swap we just remove the last item
            mapOfIdToBuyableListIndex[idOfTheLastItem] = index; // update the mapping of the last item to the new index
            delete mapOfIdToBuyableListIndex[_id]; // remove the mapping between card id to the index of the buyable list
        }
    }
}
