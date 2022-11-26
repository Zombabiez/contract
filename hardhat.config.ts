import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-etherscan";
import "@cronos-labs/hardhat-cronoscan";
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
  },
};

export default config;
