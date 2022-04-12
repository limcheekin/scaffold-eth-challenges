const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  const balloons = await ethers.getContract("Balloons", deployer);

  await deploy("DEX", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [balloons.address],
    log: true,
  });

  const dex = await ethers.getContract("DEX", deployer);

  /* 
  const transferTransaction = await balloons.transfer(
              "0x802aDD347616451F13955bd78d3aFeE71FbCc5E9", 
              ethers.utils.parseEther("10"));
  console.log("\n    ✅ confirming...\n");
  await sleep(5000); // wait 5 seconds for transaction to propagate
  */
 
  // init liquidity
  console.log("Approving DEX (" + dex. address + ") to take Balloons from deployer account...");
  await balloons.approve(dex.address, ethers.utils.parseEther("100"));
  console.log("INIT DEX...");
  await dex.init(ethers.utils.parseEther("5"), {value: ethers.utils.parseEther("5") });
};

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

module.exports.tags = ["DEX"];
