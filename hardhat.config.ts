import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-etherscan";
import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    hardhat: {},
    cronosTestnet: {
      url: "https://evm-t3.cronos.org/",
      chainId: 338,
      accounts: [`${process.env.CRONOS_PRIVATE_KEY}`],
      gasPrice: 5000000000000,
    },
    cronos: {
      url: "https://evm.cronos.org/",
      chainId: 25,
      accounts: [`${process.env.CRONOS_PRIVATE_KEY}`],
      gasPrice: 5000000000000,
    },
  },
  etherscan: {
    apiKey: {
      cronosTestnet: `${process.env.CRONOSCAN_API_KEY}`,
      cronos: `${process.env.CRONOSCAN_API_KEY}`,
    },
    customChains: [
      {
        network: "cronosTestnet",
        chainId: 338,
        urls: {
          apiURL: "https://evm-t3.cronos.org/",
          browserURL: "https://cronos.org/explorer/testnet3",
        },
      },
      {
        network: "cronos",
        chainId: 25,
        urls: {
          apiURL: "https://evm.cronos.org/",
          browserURL: "https://cronoscan.com/",
        },
      },
    ],
  },
};

export default config;
