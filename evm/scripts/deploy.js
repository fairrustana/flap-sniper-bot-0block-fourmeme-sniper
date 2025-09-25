const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying Pokemon Card Game contracts...");

  // Get the contract factory
  const PokemonGameFactory = await ethers.getContractFactory("PokemonGameFactory");

  // Deploy the factory contract
  const factory = await PokemonGameFactory.deploy();
  await factory.deployed();

  console.log("PokemonGameFactory deployed to:", factory.address);

  // Get contract addresses
  const [nftAddress, battleAddress, tradingAddress] = await factory.getContractAddresses();
  
  console.log("PokemonCardNFT deployed to:", nftAddress);
  console.log("PokemonBattle deployed to:", battleAddress);
  console.log("PokemonTrading deployed to:", tradingAddress);

  // Set initial configuration
  console.log("Setting initial configuration...");
  
  // Set NFT configuration
  await factory.setNFTConfiguration(
    ethers.utils.parseEther("0.01"), // 0.01 ETH mint price
    1000 // Max 1000 cards per player
  );
  
  // Set battle configuration
  await factory.setBattleConfiguration(
    3600, // 1 hour max battle duration
    ethers.utils.parseEther("0.001"), // 0.001 ETH battle reward
    10, // 10 energy per turn
    100 // 100 max energy
  );
  
  // Set trading configuration
  await factory.setTradingConfiguration(
    7 * 24 * 3600, // 7 days offer expiration
    ethers.utils.parseEther("0.001") // 0.001 ETH trading fee
  );

  console.log("Configuration set successfully!");

  // Save deployment info
  const deploymentInfo = {
    network: hre.network.name,
    factory: factory.address,
    contracts: {
      pokemonCardNFT: nftAddress,
      pokemonBattle: battleAddress,
      pokemonTrading: tradingAddress
    },
    timestamp: new Date().toISOString()
  };

  console.log("Deployment completed!");
  console.log("Deployment info:", JSON.stringify(deploymentInfo, null, 2));

  // Verify contracts on Etherscan (if on a supported network)
  if (hre.network.name !== "hardhat" && hre.network.name !== "localhost") {
    console.log("Waiting for block confirmations...");
    await factory.deployTransaction.wait(6);
    
    console.log("Verifying contracts on Etherscan...");
    try {
      await hre.run("verify:verify", {
        address: factory.address,
        constructorArguments: [],
      });
    } catch (error) {
      console.log("Verification failed:", error.message);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
