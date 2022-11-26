// import { ethers } from "hardhat";
const { ethers } = require("hardhat");
import hardhat from "hardhat";
import * as fs from "fs";
import { stakeContractSol } from "../typechain-types/contracts";

const addressFile = "contract_addresses.md";
const gen1Address = "0xD0BD375a43B58Fd8329980898802667a64623F60";
const gen2Address = "0x8ee54067dbb58d872424050234df6162aa27c06d";

const verify = async (addr: string, args: any[]) => {
  try {
    await hardhat.run("verify:verify", {
      address: addr,
      constructorArguments: args,
    });
  } catch (ex: any) {
    if (ex.toString().indexOf("Already Verified") == -1) {
      throw ex;
    }
  }
};

async function main() {
  console.log("Starting deployments");
  const accounts = await hardhat.ethers.getSigners();
  const deployer = accounts[0];

  const StakeContractFact = await ethers.getContractFactory("ERC721Staking");

  // deploy token contract
  const Stake_contract = await StakeContractFact.connect(deployer).deploy(
    gen1Address
  );
  // wait for the contract to deploy
  await Stake_contract.deployed();

  //* Write Address to addressFile
  const writeAddr = (addr: string, name: string) => {
    fs.appendFileSync(
      addressFile,
      `${name}: [https://testnet.cronoscan.com//address/${addr}](https://testnet.cronoscan.com//address/${addr})<br/>`
    );
  };

  if (fs.existsSync(addressFile)) {
    fs.rmSync(addressFile);
  }

  fs.appendFileSync(
    addressFile,
    "This file contains the latest test deployment addresses in the Cronos Testnet network<br/>"
  );
  writeAddr(Stake_contract.address, "Stake_Contract");

  console.log("Deployments done, waiting for cronoscan verifications");

  //* Wait for the contracts to be propagated inside cronoscan
  await new Promise((f) => setTimeout(f, 60000));

  //* Verify Contracts
  await verify(Stake_contract.address, [gen1Address]);

  console.log("All done");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => (process.exitCode = 0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
