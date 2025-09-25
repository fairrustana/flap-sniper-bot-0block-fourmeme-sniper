import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { PokemonCardGame } from "../target/types/pokemon_card_game";
import { PublicKey } from "@solana/web3.js";

async function main() {
  console.log("Deploying Pokemon Card Game to Solana...");

  // Configure the client to use the local cluster
  anchor.setProvider(anchor.AnchorProvider.env());
  const provider = anchor.getProvider();
  const program = anchor.workspace.PokemonCardGame as Program<PokemonCardGame>;

  console.log("Program ID:", program.programId.toString());
  console.log("Provider wallet:", provider.wallet.publicKey.toString());

  // Derive game state PDA
  const [gameState] = PublicKey.findProgramAddressSync(
    [Buffer.from("game_state")],
    program.programId
  );

  console.log("Game State PDA:", gameState.toString());

  try {
    // Initialize the game
    console.log("Initializing game...");
    const tx = await program.methods
      .initialize()
      .accounts({
        gameState: gameState,
        authority: provider.wallet.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .rpc();

    console.log("Initialize transaction signature:", tx);

    // Fetch and display game state
    const gameStateAccount = await program.account.gameState.fetch(gameState);
    console.log("Game initialized successfully!");
    console.log("Game State:", {
      authority: gameStateAccount.authority.toString(),
      totalCardsMinted: gameStateAccount.totalCardsMinted.toNumber(),
      totalBattles: gameStateAccount.totalBattles.toNumber(),
      totalTrades: gameStateAccount.totalTrades.toNumber(),
      mintPrice: gameStateAccount.mintPrice.toNumber(),
      battleReward: gameStateAccount.battleReward.toNumber(),
      tradingFee: gameStateAccount.tradingFee.toNumber(),
      maxCardsPerPlayer: gameStateAccount.maxCardsPerPlayer.toNumber(),
      maxBattleDuration: gameStateAccount.maxBattleDuration.toNumber(),
      maxEnergy: gameStateAccount.maxEnergy.toNumber(),
      energyPerTurn: gameStateAccount.energyPerTurn.toNumber(),
      offerExpirationTime: gameStateAccount.offerExpirationTime.toNumber(),
    });

    // Create sample Pokemon cards
    console.log("\nCreating sample Pokemon cards...");
    await createSamplePokemonCards(program, gameState);

    console.log("\nDeployment completed successfully!");
    console.log("Game State Address:", gameState.toString());
    console.log("Program ID:", program.programId.toString());

  } catch (error) {
    console.error("Deployment failed:", error);
    process.exit(1);
  }
}

async function createSamplePokemonCards(program: Program<PokemonCardGame>, gameState: PublicKey) {
  const provider = anchor.getProvider();
  
  // Sample Pokemon cards data
  const sampleCards = [
    {
      name: "Pikachu",
      pokemonType: 4, // ELECTRIC
      hp: new anchor.BN(60),
      attack: new anchor.BN(55),
      defense: new anchor.BN(40),
      speed: new anchor.BN(90),
      rarity: 1, // UNCOMMON
      evolutionStage: 0, // BASIC
      evolutionCost: new anchor.BN(0),
      moves: [
        {
          name: "Thunder Shock",
          pokemonType: 4, // ELECTRIC
          moveType: 1, // SPECIAL
          power: new anchor.BN(40),
          accuracy: new anchor.BN(100),
          energyCost: new anchor.BN(20),
          description: "A weak electric attack that may paralyze the target.",
        },
        {
          name: "Quick Attack",
          pokemonType: 0, // NORMAL
          moveType: 0, // PHYSICAL
          power: new anchor.BN(30),
          accuracy: new anchor.BN(100),
          energyCost: new anchor.BN(15),
          description: "An extremely fast attack that always strikes first.",
        },
      ],
      imageUri: "https://api.pokemoncardgame.com/images/pikachu.png",
      description: "A cute Electric-type Pokemon that stores electricity in its cheeks.",
    },
    {
      name: "Charizard",
      pokemonType: 1, // FIRE
      hp: new anchor.BN(120),
      attack: new anchor.BN(84),
      defense: new anchor.BN(78),
      speed: new anchor.BN(100),
      rarity: 4, // LEGENDARY
      evolutionStage: 2, // STAGE 2
      evolutionCost: new anchor.BN(50),
      moves: [
        {
          name: "Flamethrower",
          pokemonType: 1, // FIRE
          moveType: 1, // SPECIAL
          power: new anchor.BN(90),
          accuracy: new anchor.BN(100),
          energyCost: new anchor.BN(30),
          description: "A powerful fire attack that may burn the target.",
        },
        {
          name: "Dragon Claw",
          pokemonType: 14, // DRAGON
          moveType: 0, // PHYSICAL
          power: new anchor.BN(80),
          accuracy: new anchor.BN(100),
          energyCost: new anchor.BN(25),
          description: "Sharp claws tear into the target with dragon power.",
        },
      ],
      imageUri: "https://api.pokemoncardgame.com/images/charizard.png",
      description: "A powerful Fire/Flying-type Pokemon that can breathe intense flames.",
    },
    {
      name: "Blastoise",
      pokemonType: 2, // WATER
      hp: new anchor.BN(120),
      attack: new anchor.BN(83),
      defense: new anchor.BN(100),
      speed: new anchor.BN(78),
      rarity: 4, // LEGENDARY
      evolutionStage: 2, // STAGE 2
      evolutionCost: new anchor.BN(50),
      moves: [
        {
          name: "Hydro Pump",
          pokemonType: 2, // WATER
          moveType: 1, // SPECIAL
          power: new anchor.BN(110),
          accuracy: new anchor.BN(80),
          energyCost: new anchor.BN(35),
          description: "A powerful water attack that blasts the target.",
        },
        {
          name: "Skull Bash",
          pokemonType: 0, // NORMAL
          moveType: 0, // PHYSICAL
          power: new anchor.BN(100),
          accuracy: new anchor.BN(100),
          energyCost: new anchor.BN(30),
          description: "A powerful headbutt that raises defense.",
        },
      ],
      imageUri: "https://api.pokemoncardgame.com/images/blastoise.png",
      description: "A powerful Water-type Pokemon with massive water cannons on its shell.",
    },
  ];

  // Create a test player keypair
  const testPlayer = anchor.web3.Keypair.generate();
  
  // Airdrop SOL to test player
  await provider.connection.requestAirdrop(testPlayer.publicKey, 2 * anchor.web3.LAMPORTS_PER_SOL);
  await new Promise(resolve => setTimeout(resolve, 1000));

  // Derive player state PDA
  const [playerState] = PublicKey.findProgramAddressSync(
    [Buffer.from("player_state"), testPlayer.publicKey.toBuffer()],
    program.programId
  );

  for (let i = 0; i < sampleCards.length; i++) {
    const cardData = sampleCards[i];
    
    // Derive Pokemon card PDA
    const [pokemonCard] = PublicKey.findProgramAddressSync(
      [Buffer.from("pokemon_card"), new anchor.BN(i).toArrayLike(Buffer, "le", 8)],
      program.programId
    );

    // Create payment token account
    const payment = anchor.web3.Keypair.generate();

    try {
      const tx = await program.methods
        .mintPokemonCard(cardData)
        .accounts({
          gameState: gameState,
          pokemonCard: pokemonCard,
          playerState: playerState,
          player: testPlayer.publicKey,
          payment: payment.publicKey,
          systemProgram: anchor.web3.SystemProgram.programId,
        })
        .signers([testPlayer, payment])
        .rpc();

      console.log(`Minted ${cardData.name} card - Transaction: ${tx}`);
      
      // Fetch and display card info
      const cardAccount = await program.account.pokemonCard.fetch(pokemonCard);
      console.log(`  Token ID: ${cardAccount.tokenId.toNumber()}`);
      console.log(`  HP: ${cardAccount.hp.toNumber()}`);
      console.log(`  Attack: ${cardAccount.attack.toNumber()}`);
      console.log(`  Defense: ${cardAccount.defense.toNumber()}`);
      console.log(`  Speed: ${cardAccount.speed.toNumber()}`);
      console.log(`  Rarity: ${cardAccount.rarity}`);
      console.log(`  Moves: ${cardAccount.moves.length}`);
      
    } catch (error) {
      console.error(`Failed to mint ${cardData.name}:`, error);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
