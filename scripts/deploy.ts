import { ethers, upgrades, network } from "hardhat";
import dotenv from "dotenv";
dotenv.config();

const PRICE_FEED_ADDRESSES: any = {
  polygon: "0xAB594600376Ec9fD91F8e885dADF0CE036862dE0", // ETH/USD testnet // MATIC/USD testnet
  amoy: process.env.AMOY_MOCK_AGGREGATOR_CONTRACT_ADDRESS,
  sepolia: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
};

const supportedNetworks = [
  "polygon",
  "amoy",
  "sepolia",
  "ganache",
  "hardhat",
  "localhost",
];

async function main() {
  const networks = network.name;
  if (!supportedNetworks.includes(networks)) {
    throw new Error(`Unsupported network: ${networks}`);
  }
  console.log(`Deploying on network: ${networks}`);
  let priceFeedAddress = PRICE_FEED_ADDRESSES[networks];
  const [deployer] = await ethers.getSigners();
  if (!priceFeedAddress) {
    const MockAggregator = await ethers.getContractFactory(
      "MockLocalAggregratorV3"
    );
    let ethPriceInUSD_e8;
    // for the test net, we will use the fake static price as 1 MATIC = 10,000 for testing purpose (because testnet we won't have that much MATIC to test)
    if (["amoy", "sepolia"].includes(networks)) {
      ethPriceInUSD_e8 = 10000 * 1e8;
    } else {
      // for the localhost, we will the price will be static from the mock contract as well but we will initially fetch the price from the coingecko api
      // and then will be static forever.
      const response = await fetch(
        "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd"
      );
      const data = await response.json();
      ethPriceInUSD_e8 = Math.round(data.ethereum.usd * 1e8);
    }
    console.log("Ether price in USD (e8)", ethPriceInUSD_e8 / 1e8);
    const mock = await MockAggregator.deploy(ethPriceInUSD_e8);
    await mock.waitForDeployment();
    priceFeedAddress = await mock.getAddress();
    console.log(`MockLocalAggregatorV3 deployed at: ${priceFeedAddress}`);
  }
  console.log(`Deploying contracts with account: ${deployer.address}`);

  // Deploy Upgradable Logic Contract (Proxy will be created)
  const Logic = await ethers.getContractFactory("GiftCardLogic");
  const logic = await upgrades.deployProxy(Logic, [priceFeedAddress], {
    initializer: "initialize",
  });

  await logic.waitForDeployment();
  await (logic as any).setStaticTokenURI(
    process.env.STATIC_IPFS_TOKEN_URI || ""
  );
  console.log(`GiftCardLogic (Proxy) deployed at: ${await logic.getAddress()}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
