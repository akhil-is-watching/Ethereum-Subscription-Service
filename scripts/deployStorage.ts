import { ethers } from "hardhat";

async function main() {

  const lockedAmount = ethers.utils.parseEther("1");

  const FundStorage = await ethers.getContractFactory("FundStorage");
  const storage = await FundStorage.deploy();

  await storage.deployed();

  console.log("EVMsub deployed to:", storage.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
