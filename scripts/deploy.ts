import { ethers } from "hardhat";

async function main() {

  const lockedAmount = ethers.utils.parseEther("1");

  const EVMsub = await ethers.getContractFactory("EVMsub");
  const sub = await EVMsub.deploy("1000");

  await sub.deployed();

  console.log("EVMsub deployed to:", sub.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
