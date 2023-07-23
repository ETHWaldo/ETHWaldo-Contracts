const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log(
    "Deploying contracts with the account:",
    deployer.address
  );
  
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const ETHWaldo = await hre.ethers.getContractFactory("ETHWaldo");
  const manager = "0x7964F3F022076BD3fF7215691CBF28D1Df6B3410";
  const ethWaldo = await ETHWaldo.deploy(manager);

  await ethWaldo.deployed();

  console.log("ETHWaldo deployed to:", ethWaldo.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
