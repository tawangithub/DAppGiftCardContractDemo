// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./ERC721Compact.sol";
contract GiftCardStorage is ERC721Compact {
    struct GiftCard {
        uint256 id;
        address issuer; // the issuer of the gift card
        uint256 issueDate; // the date that the gift card is issued
        uint256 startDate; // the date that the gift card can be redeemed (some cards have a waiting period before they can be redeemed)
        uint256 expirationDate; // the expiration date of the gift card
        uint256 balanceInUSD_e2; // the balance of the gift card in USD (e2 means 100 means 1 USD)
        bool sellable; // whether the gift card is sellable or not
        uint256 sellPriceInUSD_e2; // the price of the gift card in USD (e2 means 100 means 1 USD)
    }
    // mapping from the id of the gift card to the gift card (main gift card list storage)
    mapping(uint256 => GiftCard) public giftCards;

    // the history of the gift cards that the user has owned (including the ones already sold or transferred to other users)
    // this is used to optimize performance when display the gift cards of a specific user.
    // (more efficient than ERC721Enumerable contract)
    mapping(address => uint256[]) public myGiftCardsHistory;

    // the list of 2nd hand gift cards that the are buyable in the app's resold marketplace.
    uint256[] buyableListIds; 

    // the index of the gift card mapping to index position in the buyable list (for fast and efficient removal)
    mapping(uint256 => uint256) public mapOfIdToBuyableListIndex;

    // The id of the redeem voucher that the user has been generated (as a QR code)
    // This is used to prevent the user from redeeming the same gift card multiple times
    mapping(uint256 => bool) public redeemId;

    uint256 public nextGiftCardId; // the next gift card id that will be issued (must start from 1 to avoid 0 index because it will be used for invalid id)

    // The type of gift card that the user buys from the shop
    struct TypeOfGiftCardFromShop {
        uint256 id;
        uint256 balanceInUSD_e2;
        uint256 sellPriceInUSD_e2;
        uint256 expireAfterBuyInYears;
        uint256 waitingAfterBuyInMonths;
        bool isActive;
        uint256 numberOfRemainingGiftCards;
    }
    uint256 public nextTypeOfGiftCardFromShopId;
    mapping(uint256 => TypeOfGiftCardFromShop) public typesOfGiftCardFromShop;

    // The list of gift cards that the user has bought from the shop
    string internal staticTokenURI;

    uint256[30] private __gap; // Storage gap for future upgrades
}
