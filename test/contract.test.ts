import { ethers } from "hardhat";
import { expect } from "chai";
describe("GiftCardLogic", function () {
  let giftCardLogic: any;
  let adminAddress: string;
  let userAddress: string;
  let user: any;

  beforeEach(async function () {
    const [deployer, user1] = await ethers.getSigners();
    user = user1;
    adminAddress = deployer.address;
    userAddress = user1.address;

    const MockAggregator = await ethers.getContractFactory(
      "MockLocalAggregratorV3"
    );

    const usdsPerEther_e8 = Math.round(2000 * 1e8);
    const mock = await MockAggregator.deploy(usdsPerEther_e8);
    await mock.waitForDeployment();
    const priceFeedAddress = await mock.getAddress();
    const GiftCardLogic = await ethers.getContractFactory("GiftCardLogic");
    giftCardLogic = await GiftCardLogic.deploy();
    await giftCardLogic.waitForDeployment();
    await giftCardLogic.initialize(priceFeedAddress); // _priceFeedAddress
  });

  it("should be able to create a new gift card type", async function () {
    await giftCardLogic.createNewGiftCardTypeByShop(
      100,
      1,
      1,
      100 * 100,
      120 * 100
    );
    const giftCardType = await giftCardLogic.typesOfGiftCardFromShop(0);
    expect(giftCardType.balanceInUSD_e2).to.equal(10000n);
    expect(giftCardType.sellPriceInUSD_e2).to.equal(12000n);
  });

  it("should allow the owner to set the active status of the gift card type", async function () {
    await giftCardLogic.createNewGiftCardTypeByShop(
      100,
      1,
      1,
      100 * 100,
      120 * 100
    );
    await giftCardLogic.setTypeOfGiftCardFromShopActive(0, true);
    const activeGiftCardTypes = await giftCardLogic.listContractGiftCardTypes();
    expect(activeGiftCardTypes.length).to.equal(1);
    expect(activeGiftCardTypes[0].id).to.equal(0n);
    expect(activeGiftCardTypes[0].isActive).to.equal(true);
  });

  it("should allow the admin to set the number of remaining gift cards", async function () {
    await giftCardLogic.createNewGiftCardTypeByShop(
      100,
      1,
      1,
      100 * 100,
      120 * 100
    );
    await giftCardLogic.setNumberOfRemainingGiftCards(0, 50);
    const typeOfCards = await giftCardLogic.typesOfGiftCardFromShop(0);
    expect(typeOfCards.numberOfRemainingGiftCards).to.equal(50n);
  });

  it("should allow a user to buy a gift card from the shop", async function () {
    await giftCardLogic.createNewGiftCardTypeByShop(
      100,
      1,
      1,
      100 * 100,
      100 * 100
    );
    await giftCardLogic.setNumberOfRemainingGiftCards(0, 50);
    await giftCardLogic
      .connect(user)
      .buyGiftCardFromShop(0, 3, { value: ethers.parseUnits("0.3", "ether") });
    const giftCard = await giftCardLogic.giftCards(1);
    const cardOwner = await giftCardLogic.ownerOf(1);
    expect(cardOwner).to.equal(user);
    expect(giftCard.balanceInUSD_e2).to.equal(10000n);
    expect(giftCard.sellPriceInUSD_e2).to.equal(0n);
    expect(giftCard.sellable).to.equal(false);
  });

  it("should allow the admin to redeem a gift card", async function () {
    await giftCardLogic.createNewGiftCardTypeByShop(
      100,
      0,
      1,
      100 * 100,
      120 * 100
    );
    await giftCardLogic.setNumberOfRemainingGiftCards(0, 50);
    await giftCardLogic
      .connect(user)
      .buyGiftCardFromShop(0, 1, { value: ethers.parseUnits("0.08", "ether") });
    await giftCardLogic.redeemGiftCard(1, 70 * 100, 1);
    const giftCard = await giftCardLogic.giftCards(1);
    expect(giftCard.balanceInUSD_e2).to.equal(3000n);
  });

  it("should not allow the user to redeem a gift card when it is expired", async function () {
    await giftCardLogic.createNewGiftCardTypeByShop(
      100,
      1,
      1,
      100 * 100,
      120 * 100
    );
    await giftCardLogic.setNumberOfRemainingGiftCards(0, 50);
    await giftCardLogic
      .connect(user)
      .buyGiftCardFromShop(0, 1, { value: ethers.parseUnits("0.08", "ether") });

    // Fast forward time to simulate expiration
    await ethers.provider.send("evm_increaseTime", [366 * 24 * 60 * 60]); // Increase time by 1 year
    await ethers.provider.send("evm_mine", []); // Mine a new block to apply the time increase

    // Try to redeem the gift card after expiration
    await expect(
      giftCardLogic.redeemGiftCard(1, 70 * 100, 1)
    ).to.be.revertedWith("Gift card expired");
  });

  it("should allow the owner to transfer a gift card", async function () {
    await giftCardLogic.createNewGiftCardTypeByShop(
      100,
      1,
      1,
      100 * 100,
      120 * 100
    );
    await giftCardLogic.setNumberOfRemainingGiftCards(0, 50);
    await giftCardLogic
      .connect(user)
      .buyGiftCardFromShop(0, 1, { value: ethers.parseUnits("0.08", "ether") });
    await giftCardLogic
      .connect(user)
      .safeTransferFrom(
        userAddress,
        adminAddress,
        1,
        new TextEncoder().encode("")
      );
    const newOwner = await giftCardLogic.ownerOf(1);
    expect(await giftCardLogic.ownerOf(1)).to.equal(adminAddress);
  });

  it("should allow the owner to set the gift card to be sellable", async function () {
    await giftCardLogic.createNewGiftCardTypeByShop(
      100,
      1,
      1,
      100 * 100,
      120 * 100
    );
    await giftCardLogic.setNumberOfRemainingGiftCards(0, 50);
    await giftCardLogic
      .connect(user)
      .buyGiftCardFromShop(0, 1, { value: ethers.parseUnits("0.08", "ether") });
    await giftCardLogic.connect(user).setSellable(1, true, 150 * 100);
    const giftCard = await giftCardLogic.giftCards(1);
    expect(giftCard.sellable).to.be.true;
    expect(giftCard.sellPriceInUSD_e2).to.equal(15000n);
  });

  it("should allow the owner to set the sell price of the gift card", async function () {
    await giftCardLogic.createNewGiftCardTypeByShop(
      100,
      1,
      1,
      100 * 100,
      120 * 100
    );
    await giftCardLogic.setNumberOfRemainingGiftCards(0, 50);
    await giftCardLogic
      .connect(user)
      .buyGiftCardFromShop(0, 1, { value: ethers.parseUnits("0.08", "ether") });
    await giftCardLogic.connect(user).setSellPrice(1, 150 * 100);
    const giftCard = await giftCardLogic.giftCards(1);
    expect(giftCard.sellPriceInUSD_e2).to.equal(15000n);
  });

  it("should allow the owner to list the active gift card types", async function () {
    await giftCardLogic.createNewGiftCardTypeByShop(
      100,
      1,
      1,
      100 * 100,
      120 * 100
    );
    const activeGiftCardTypes = await giftCardLogic.listContractGiftCardTypes();
    expect(activeGiftCardTypes.length).to.equal(1);
    expect(activeGiftCardTypes[0].id).to.equal(0n);
    expect(activeGiftCardTypes[0].balanceInUSD_e2).to.equal(10000n);
    expect(activeGiftCardTypes[0].sellPriceInUSD_e2).to.equal(12000n);
    expect(activeGiftCardTypes[0].expireAfterBuyInYears).to.equal(1n);
    expect(activeGiftCardTypes[0].waitingAfterBuyInMonths).to.equal(1n);
  });

  it("should allow the owner to set the active status of the gift card type", async function () {
    await giftCardLogic.createNewGiftCardTypeByShop(
      100,
      1,
      1,
      100 * 100,
      120 * 100
    );
    let activeGiftCardTypes = await giftCardLogic.listContractGiftCardTypes();
    expect(
      activeGiftCardTypes.filter((item: any) => item.isActive).length
    ).to.equal(1);
    await giftCardLogic.setTypeOfGiftCardFromShopActive(0, false);
    activeGiftCardTypes = await giftCardLogic.listContractGiftCardTypes();
    expect(
      activeGiftCardTypes.filter((item: any) => item.isActive).length
    ).to.equal(0);
  });
});
