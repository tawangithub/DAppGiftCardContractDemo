import { HardhatUserConfig } from "hardhat/config";
import "@openzeppelin/hardhat-upgrades";
import "dotenv/config";
import "@nomicfoundation/hardhat-chai-matchers";
import "hardhat-contract-sizer";
import dotenv from "dotenv";
dotenv.config();

const networks: any = {
  hardhat: {},
};

if (process.env.AMOY_RPC && process.env.AMOY_PRIVATE_KEY) {
  networks.amoy = {
    url: process.env.AMOY_RPC || "",
    accounts: [process.env.AMOY_PRIVATE_KEY],
    chainId: 80002,
  };
}

if (process.env.SEPOLIA_RPC && process.env.SEPOLIA_PRIVATE_KEY) {
  networks.sepolia = {
    url: process.env.SEPOLIA_RPC || "",
    accounts: [process.env.SEPOLIA_PRIVATE_KEY],
    chainId: 11155111,
  };
}

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
  networks,
};
export default config;
