# GiftCard Smart Contract System Documentation

## Overview
The GiftCard system is a comprehensive smart contract solution that enables the creation, management, and trading of gift cards (ERC721) on the blockchain. The system supports both direct purchases from a shop and secondary market trading between users.
In addition, the minted gift card is also seamlessly compatilbe with the welknown market place that supports ERC721 such as OpenSea

This project use smart contract with upgradable pattern via hardhat

## Contract Architecture

### Core Contracts
1. `GiftCardLogic` - Main implementation contract (for initialize the variable)
2. `GiftCardTrade` - Handles trading functionality such as buy sell transfer redeem
3. `GiftCardAdmin` - Administrative functions such as create a token type, etc
4. `GiftCardACL` - Access control layer
5. `GiftCardStorage` - Data storage structures

### Dependencies
- OpenZeppelin's `Initializable`
- Chainlink's `AggregatorV3Interface` for ETH/USD price feeds

## Features

### 1. Gift Card Management

#### Gift Card Structure
```solidity
struct GiftCard {
    uint256 id;
    address issuer;
    uint256 issueDate;
    uint256 startDate;
    uint256 expirationDate;
    uint256 balanceInUSD_e2;
    bool sellable;
    uint256 sellPriceInUSD_e2;
}
```

#### Gift Card Type Structure
```solidity
struct TypeOfGiftCardFromShop {
    uint256 id;
    uint256 balanceInUSD_e2;
    uint256 sellPriceInUSD_e2;
    uint256 expireAfterBuyInYears;
    uint256 waitingAfterBuyInMonths;
    bool isActive;
    uint256 numberOfRemainingGiftCards;
}
```

### 2. Administrative Functions

#### Shop Management
- Create new gift card types
- Set gift card type active status
- Manage remaining gift card inventory
- Update price feed contract address
- Withdraw contract balance to the contract owner

#### Access Control
- Add/remove administrators
- Contract owner privileges
- Admin privileges

### 3. Trading Functions

#### Primary Market (buy from the official shop)
- Purchase gift cards from shop
- Automatic ETH to USD conversion
- Support for bulk purchases
- Some gifcard has a waiting period before redeemable
- Expiration date management

#### Secondary Market (buy from the previous card's owner)
- Set our card for sale in the marketplace
- Update selling prices
- List my gift cards for sale
- Purchase from other users
- Transfer gift cards between users (for free)

### 4. Gift Card Operations

#### Redemption
- Shop-side redemption functionality
- QR code-based redemption system
- Balance tracking
- Prevention of double redemption

#### Viewing Functions
- View individual gift card
- List active gift card types
- View user's gift cards
- Browse marketplace listings (with pagination)

## Events

### System Events
- `GiftCardIssued` - When a new gift card is created
- `GiftCardTransferred` - When ownership changes
- `GiftCardSold` - When a card is sold in the marketplace
- `GiftCardSetSellable` - When a card's sale status changes
- `GiftCardSetSellPrice` - When a card's price is updated
- `GiftCardTypeCreated` - When a new gift card type is created
- `GiftCardRedeemed` - When a card is redeemed
- `PriceFeedAddressUpdated` - When the price feed is updated

## Security Features

### Access Control
- Role-based access control (Admin, Contract Owner)
- Owner-only functions
- Admin-only functions
- Card owner verification

### Safety Checks
- Expiration and waiting period date validation
- Balance verification
- Price feed validation
- Duplicate redemption prevention
- Marketplace listing validation

## Technical Details

### Price Conversion
- Uses Chainlink price feeds for ETH/USD conversion
- Supports 2 decimal places for USD amounts
- Automatic conversion for purchases and sales

### Storage Optimization
- Efficient mapping structures
- Optimized list management for marketplace
- Storage gap for future upgrades

### Error Handling
- Custom error messages
- Input validation
- State verification
- Transaction safety checks

## Usage Examples

### For Shop Owners
1. Initialize contract with price feed
2. Create gift card types
3. Manage inventory
4. Process redemptions
5. Monitor balances

### For Customers
1. Purchase gift cards
2. Transfer to others
3. List for sale
4. Create a Redeem voucher (QR code) to redeem at shops (by frontend UI on another repo)
5. View card details

### For Administrators
1. Manage gift card types
2. Update price feeds
3. Process redemptions from the voucher
4. Monitor system status
5. Manage access control

## Best Practices

### For Developers
1. Always verify price feed addresses
2. Implement proper error handling
3. Use appropriate access controls
4. Monitor contract balance
5. Regular security audits

### For Users
1. Verify card details before purchase
2. Check expiration dates
3. Confirm balances before redemption
4. Use secure wallets
5. Keep track of transactions

## Limitations and Considerations

1. ETH price volatility
2. Gas costs for operations
3. Network congestion effects
4. Price feed reliability
5. Contract upgrade considerations

## Note about Redemption flow
1. User navigate to his/her own giftcard via frontend UI (another repo).
2. Click redeem button.
3. Enter the amount of redemption to generate the QR code voucher (via web frontend)
Note: The QR code contains both data and signature (signed by Metamask)
4. Shop admin scan QR code (via web frontend, verify signature and the voucher 5 mins expiration)
5. The web frontend (with admin meta mask will update the redemption amount of the giftcard from the smart contract)