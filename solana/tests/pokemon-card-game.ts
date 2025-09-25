import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { PokemonCardGame } from "../target/types/pokemon_card_game";
import { expect } from "chai";

describe("pokemon-card-game", () => {
  // Configure the client to use the local cluster.
  anchor.setProvider(anchor.AnchorProvider.env());

  const program = anchor.workspace.PokemonCardGame as Program<PokemonCardGame>;
  const provider = anchor.getProvider();

  // Test accounts
  let gameState: anchor.web3.PublicKey;
  let player1: anchor.web3.Keypair;
  let player2: anchor.web3.Keypair;
  let player1State: anchor.web3.PublicKey;
  let player2State: anchor.web3.PublicKey;

  before(async () => {
    // Create test keypairs
    player1 = anchor.web3.Keypair.generate();
    player2 = anchor.web3.Keypair.generate();

    // Airdrop SOL to test accounts
    await provider.connection.requestAirdrop(player1.publicKey, 2 * anchor.web3.LAMPORTS_PER_SOL);
    await provider.connection.requestAirdrop(player2.publicKey, 2 * anchor.web3.LAMPORTS_PER_SOL);

    // Wait for airdrops to confirm
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Derive game state PDA
    [gameState] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("game_state")],
      program.programId
    );

    // Derive player state PDAs
    [player1State] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("player_state"), player1.publicKey.toBuffer()],
      program.programId
    );

    [player2State] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("player_state"), player2.publicKey.toBuffer()],
      program.programId
    );
  });

  it("Initializes the game", async () => {
    const tx = await program.methods
      .initialize()
      .accounts({
        gameState: gameState,
        authority: provider.wallet.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .rpc();

    console.log("Initialize transaction signature", tx);

    // Fetch the game state
    const gameStateAccount = await program.account.gameState.fetch(gameState);
    
    expect(gameStateAccount.authority.toString()).to.equal(provider.wallet.publicKey.toString());
    expect(gameStateAccount.totalCardsMinted.toNumber()).to.equal(0);
    expect(gameStateAccount.totalBattles.toNumber()).to.equal(0);
    expect(gameStateAccount.totalTrades.toNumber()).to.equal(0);
    expect(gameStateAccount.mintPrice.toNumber()).to.equal(1000000); // 0.001 SOL
    expect(gameStateAccount.battleReward.toNumber()).to.equal(500000); // 0.0005 SOL
    expect(gameStateAccount.tradingFee.toNumber()).to.equal(100000); // 0.0001 SOL
    expect(gameStateAccount.maxCardsPerPlayer.toNumber()).to.equal(1000);
    expect(gameStateAccount.maxBattleDuration.toNumber()).to.equal(3600); // 1 hour
    expect(gameStateAccount.maxEnergy.toNumber()).to.equal(100);
    expect(gameStateAccount.energyPerTurn.toNumber()).to.equal(10);
    expect(gameStateAccount.offerExpirationTime.toNumber()).to.equal(604800); // 7 days
  });

  it("Mints a Pokemon card", async () => {
    // Create sample Pokemon card data
    const cardData = {
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
    };

    // Derive Pokemon card PDA
    const [pokemonCard] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("pokemon_card"), new anchor.BN(0).toArrayLike(Buffer, "le", 8)],
      program.programId
    );

    // Create payment token account (simplified - in real implementation, you'd use SPL tokens)
    const payment = anchor.web3.Keypair.generate();

    const tx = await program.methods
      .mintPokemonCard(cardData)
      .accounts({
        gameState: gameState,
        pokemonCard: pokemonCard,
        playerState: player1State,
        player: player1.publicKey,
        payment: payment.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .signers([player1, payment])
      .rpc();

    console.log("Mint Pokemon card transaction signature", tx);

    // Fetch the Pokemon card
    const pokemonCardAccount = await program.account.pokemonCard.fetch(pokemonCard);
    
    expect(pokemonCardAccount.tokenId.toNumber()).to.equal(0);
    expect(pokemonCardAccount.owner.toString()).to.equal(player1.publicKey.toString());
    expect(pokemonCardAccount.name).to.equal("Pikachu");
    expect(pokemonCardAccount.pokemonType).to.equal(4);
    expect(pokemonCardAccount.hp.toNumber()).to.equal(60);
    expect(pokemonCardAccount.attack.toNumber()).to.equal(55);
    expect(pokemonCardAccount.defense.toNumber()).to.equal(40);
    expect(pokemonCardAccount.speed.toNumber()).to.equal(90);
    expect(pokemonCardAccount.rarity).to.equal(1);
    expect(pokemonCardAccount.evolutionStage).to.equal(0);
    expect(pokemonCardAccount.isActive).to.be.true;
    expect(pokemonCardAccount.moves.length).to.equal(2);
    expect(pokemonCardAccount.moves[0].name).to.equal("Thunder Shock");
    expect(pokemonCardAccount.moves[1].name).to.equal("Quick Attack");

    // Fetch the player state
    const playerStateAccount = await program.account.playerState.fetch(player1State);
    expect(playerStateAccount.cardCount.toNumber()).to.equal(1);
  });

  it("Creates a battle", async () => {
    // Create payment token account
    const payment = anchor.web3.Keypair.generate();

    // Derive battle PDA
    const [battle] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("battle"), new anchor.BN(0).toArrayLike(Buffer, "le", 8)],
      program.programId
    );

    const pokemonTokenIds = [new anchor.BN(0)]; // Use the Pokemon card we just minted

    const tx = await program.methods
      .createBattle(pokemonTokenIds)
      .accounts({
        gameState: gameState,
        battle: battle,
        playerState: player1State,
        player: player1.publicKey,
        payment: payment.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .signers([player1, payment])
      .rpc();

    console.log("Create battle transaction signature", tx);

    // Fetch the battle
    const battleAccount = await program.account.battle.fetch(battle);
    
    expect(battleAccount.battleId.toNumber()).to.equal(0);
    expect(battleAccount.player1.toString()).to.equal(player1.publicKey.toString());
    expect(battleAccount.player2.toString()).to.equal(anchor.web3.PublicKey.default.toString());
    expect(battleAccount.player1Pokemon.length).to.equal(1);
    expect(battleAccount.player1Pokemon[0].toNumber()).to.equal(0);
    expect(battleAccount.status.waiting).to.be.true;

    // Fetch the player state
    const playerStateAccount = await program.account.playerState.fetch(player1State);
    expect(playerStateAccount.activeBattleId.toNumber()).to.equal(0);
  });

  it("Joins a battle", async () => {
    // First, mint a Pokemon card for player2
    const cardData = {
      name: "Charmander",
      pokemonType: 1, // FIRE
      hp: new anchor.BN(50),
      attack: new anchor.BN(52),
      defense: new anchor.BN(43),
      speed: new anchor.BN(65),
      rarity: 0, // COMMON
      evolutionStage: 0, // BASIC
      evolutionCost: new anchor.BN(0),
      moves: [
        {
          name: "Ember",
          pokemonType: 1, // FIRE
          moveType: 1, // SPECIAL
          power: new anchor.BN(40),
          accuracy: new anchor.BN(100),
          energyCost: new anchor.BN(20),
          description: "A weak fire attack that may burn the target.",
        },
      ],
      imageUri: "https://api.pokemoncardgame.com/images/charmander.png",
      description: "A Fire-type Pokemon with a flame on its tail.",
    };

    // Derive Pokemon card PDA for player2
    const [pokemonCard2] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("pokemon_card"), new anchor.BN(1).toArrayLike(Buffer, "le", 8)],
      program.programId
    );

    // Create payment token account for minting
    const paymentMint = anchor.web3.Keypair.generate();

    // Mint Pokemon card for player2
    await program.methods
      .mintPokemonCard(cardData)
      .accounts({
        gameState: gameState,
        pokemonCard: pokemonCard2,
        playerState: player2State,
        player: player2.publicKey,
        payment: paymentMint.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .signers([player2, paymentMint])
      .rpc();

    // Now join the battle
    const payment = anchor.web3.Keypair.generate();

    // Derive battle PDA
    const [battle] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("battle"), new anchor.BN(0).toArrayLike(Buffer, "le", 8)],
      program.programId
    );

    const pokemonTokenIds = [new anchor.BN(1)]; // Use the Pokemon card we just minted

    const tx = await program.methods
      .joinBattle(pokemonTokenIds)
      .accounts({
        battle: battle,
        playerState: player2State,
        player: player2.publicKey,
        payment: payment.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .signers([player2, payment])
      .rpc();

    console.log("Join battle transaction signature", tx);

    // Fetch the battle
    const battleAccount = await program.account.battle.fetch(battle);
    
    expect(battleAccount.player2.toString()).to.equal(player2.publicKey.toString());
    expect(battleAccount.player2Pokemon.length).to.equal(1);
    expect(battleAccount.player2Pokemon[0].toNumber()).to.equal(1);
    expect(battleAccount.status.active).to.be.true;

    // Fetch player2 state
    const player2StateAccount = await program.account.playerState.fetch(player2State);
    expect(player2StateAccount.activeBattleId.toNumber()).to.equal(0);
  });

  it("Creates a trading offer", async () => {
    // Create payment token account
    const payment = anchor.web3.Keypair.generate();

    // Derive trading offer PDA
    const [tradingOffer] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("trading_offer"), new anchor.BN(0).toArrayLike(Buffer, "le", 8)],
      program.programId
    );

    const offeredCards = [new anchor.BN(0)]; // Pikachu
    const requestedCards = [new anchor.BN(1)]; // Charmander
    const targetPlayer = player2.publicKey;

    const tx = await program.methods
      .createTradingOffer(offeredCards, requestedCards, targetPlayer)
      .accounts({
        gameState: gameState,
        tradingOffer: tradingOffer,
        player: player1.publicKey,
        payment: payment.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .signers([player1, payment])
      .rpc();

    console.log("Create trading offer transaction signature", tx);

    // Fetch the trading offer
    const tradingOfferAccount = await program.account.tradingOffer.fetch(tradingOffer);
    
    expect(tradingOfferAccount.offerId.toNumber()).to.equal(0);
    expect(tradingOfferAccount.offerer.toString()).to.equal(player1.publicKey.toString());
    expect(tradingOfferAccount.targetPlayer.toString()).to.equal(player2.publicKey.toString());
    expect(tradingOfferAccount.offeredCards.length).to.equal(1);
    expect(tradingOfferAccount.offeredCards[0].toNumber()).to.equal(0);
    expect(tradingOfferAccount.requestedCards.length).to.equal(1);
    expect(tradingOfferAccount.requestedCards[0].toNumber()).to.equal(1);
    expect(tradingOfferAccount.isActive).to.be.true;
  });

  it("Accepts a trading offer", async () => {
    // Create payment token account
    const payment = anchor.web3.Keypair.generate();

    // Derive trading offer PDA
    const [tradingOffer] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("trading_offer"), new anchor.BN(0).toArrayLike(Buffer, "le", 8)],
      program.programId
    );

    const tx = await program.methods
      .acceptTradingOffer()
      .accounts({
        tradingOffer: tradingOffer,
        gameState: gameState,
        player: player2.publicKey,
        payment: payment.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .signers([player2, payment])
      .rpc();

    console.log("Accept trading offer transaction signature", tx);

    // Fetch the trading offer
    const tradingOfferAccount = await program.account.tradingOffer.fetch(tradingOffer);
    expect(tradingOfferAccount.isActive).to.be.false;
  });

  it("Handles insufficient payment error", async () => {
    // Create payment token account with insufficient funds
    const payment = anchor.web3.Keypair.generate();

    const cardData = {
      name: "Squirtle",
      pokemonType: 2, // WATER
      hp: new anchor.BN(50),
      attack: new anchor.BN(48),
      defense: new anchor.BN(65),
      speed: new anchor.BN(43),
      rarity: 0, // COMMON
      evolutionStage: 0, // BASIC
      evolutionCost: new anchor.BN(0),
      moves: [],
      imageUri: "",
      description: "",
    };

    // Derive Pokemon card PDA
    const [pokemonCard] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("pokemon_card"), new anchor.BN(2).toArrayLike(Buffer, "le", 8)],
      program.programId
    );

    try {
      await program.methods
        .mintPokemonCard(cardData)
        .accounts({
          gameState: gameState,
          pokemonCard: pokemonCard,
          playerState: player1State,
          player: player1.publicKey,
          payment: payment.publicKey,
          systemProgram: anchor.web3.SystemProgram.programId,
        })
        .signers([player1, payment])
        .rpc();

      expect.fail("Expected transaction to fail");
    } catch (error) {
      expect(error.message).to.include("InsufficientPayment");
    }
  });
});
