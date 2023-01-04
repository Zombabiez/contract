// import { ethers } from "hardhat";
const { ethers } = require("hardhat");
import hardhat from "hardhat";
import * as fs from "fs";
import { ZombabieStake, ZombabiesNFT } from "../typechain-types/contracts";

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

  const ZombabieStakeFact = await ethers.getContractFactory("ZombabieStake");
  //! deploy zombabiesNFT Contract temporarily
  // const ZombabiesNFTFact = await ethers.getContractFactory("ZombabiesNFT");

  // // deploy zombabie staking contract for gen1 collection
  // const ZombabiesNFTContract = (await ZombabiesNFTFact.connect(deployer).deploy(
  //   "Zombabies",
  //   "ZOM",
  //   "ipfs://QmeLnMBvjfdMqBT6vXPBXmC8dKEUVuWvNsvMthqxqFwUcg/",
  //   "ipfs://QmeLnMBvjfdMqBT6vXPBXmC8dKEUVuWvNsvMthqxqFwUcg/1.json"
  // )) as ZombabiesNFT;
  // // wait for the contract to deploy
  // await ZombabiesNFTContract.deployed();
  //! deploy zombabiesNFT Contract temporarily

  // deploy zombabie staking contract for gen1 collection

  // const ZombabieStakePool1Contract = (await ZombabieStakeFact.connect(
  //   deployer
  // ).deploy(gen1Address)) as ZombabieStake;
  // // wait for the contract to deploy
  // await ZombabieStakePool1Contract.deployed();

  // deploy zombabie staking contract for pool2 collection
  const ZombabieStakePool2Contract = (await ZombabieStakeFact.connect(
    deployer
  ).deploy(gen2Address)) as ZombabieStake;
  // wait for the contract to deploy
  await ZombabieStakePool2Contract.deployed();

  // deploy zombabie staking contract for pool3 collection
  const ZombabieStakePool3Contract = (await ZombabieStakeFact.connect(
    deployer
  ).deploy(gen2Address)) as ZombabieStake;
  // wait for the contract to deploy
  await ZombabieStakePool3Contract.deployed();

  // deploy zombabie staking contract for pool4 collection
  const ZombabieStakePool4Contract = (await ZombabieStakeFact.connect(
    deployer
  ).deploy(gen2Address)) as ZombabieStake;
  // wait for the contract to deploy
  await ZombabieStakePool4Contract.deployed();

  // deploy zombabie staking contract for pool5 collection
  const ZombabieStakePool5Contract = (await ZombabieStakeFact.connect(
    deployer
  ).deploy(gen2Address)) as ZombabieStake;
  // wait for the contract to deploy
  await ZombabieStakePool5Contract.deployed();

  //* Write Address to addressFile
  const writeAddr = (addr: string, name: string) => {
    fs.appendFileSync(
      addressFile,
      // `${name}: [https://testnet.cronoscan.com/address/${addr}](https://testnet.cronoscan.com/address/${addr})<br/>`
      `${name}: [https://cronoscan.com/address/${addr}](https://cronoscan.com/address/${addr})<br/>`
    );
  };

  if (fs.existsSync(addressFile)) {
    fs.rmSync(addressFile);
  }

  fs.appendFileSync(
    addressFile,
    "This file contains the latest test deployment addresses in the Cronos Testnet network<br/>"
    // "This file contains the latest deployment addresses in the Cronos network<br/>"
  );
  // writeAddr(ZombabiesNFTContract.address, "ZombabiesNFTContract");
  // writeAddr(ZombabieStakePool1Contract.address, "ZombabieStakePool1Contract");
  writeAddr(ZombabieStakePool2Contract.address, "ZombabieStakePool2Contract");
  writeAddr(ZombabieStakePool3Contract.address, "ZombabieStakePool3Contract");
  writeAddr(ZombabieStakePool4Contract.address, "ZombabieStakePool4Contract");
  writeAddr(ZombabieStakePool5Contract.address, "ZombabieStakePool5Contract");

  console.log("Deployments done, waiting for cronoscan verifications");

  //* Wait for the contracts to be propagated inside cronoscan
  await new Promise((f) => setTimeout(f, 60000));

  //* Verify Contracts
  // await verify(ZombabiesNFTContract.address, [
  //   "Zombabies",
  //   "ZOM",
  //   "ipfs://QmeLnMBvjfdMqBT6vXPBXmC8dKEUVuWvNsvMthqxqFwUcg/",
  //   "ipfs://QmeLnMBvjfdMqBT6vXPBXmC8dKEUVuWvNsvMthqxqFwUcg/1.json",
  // ]);

  // await verify(ZombabieStakePool1Contract.address, [
  //   ZombabiesNFTContract.address,
  // ]);
  await verify(ZombabieStakePool2Contract.address, [gen2Address]);
  await verify(ZombabieStakePool3Contract.address, [gen2Address]);
  await verify(ZombabieStakePool4Contract.address, [gen2Address]);
  await verify(ZombabieStakePool5Contract.address, [gen2Address]);

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
