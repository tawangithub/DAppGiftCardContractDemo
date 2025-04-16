# Demo DApp GiftCard

This project demonstrates a concept of minting, trading including the redemption of the dApp giftCard with the compatibility with ERC721 token.
To try to deploy smart contract on your localhost please follow the below step
Try running some of the following tasks:

For Yarn (recommended)
```shell
yarn
yarn hardhat node
yarn hardhat run scripts/deploy.ts --network localhost
```
For NPM
```shell
npm install
npm hardhat node
npm run hardhat run scripts/deploy.ts --network localhost
```

To deploy on localhost, you don't have to do anything about .env file
To deploy on testnet, please copy value from env.example to .env and edit the variable based on your own config.

See the contract features detail in [docs/GiftCardFlow.md](docs/GiftCardFlow.md)
For the frontend part, please checkout the repository https://github.com/tawangithub/DAppGiftCardFrontendDemo and run separately