# API Documentation

This document provides comprehensive API documentation for the Pokemon Card Game smart contracts on both EVM and Solana platforms.

## EVM API (Solidity)

### PokemonCardNFT Contract

#### Functions

##### `mintPokemonCard(PokemonCardData memory cardData)`
Mints a new Pokemon card NFT.

**Parameters:**
- `cardData`: Pokemon card data structure containing all card information

**Requirements:**
- Sufficient payment (mint price)
- Player hasn't exceeded max cards per player limit

**Events:**
- `PokemonCardMinted(uint256 indexed tokenId, address indexed owner, string name, PokemonType pokemonType, Rarity rarity)`

##### `getPokemonCard(uint256 tokenId)`
Retrieves Pokemon card data by token ID.

**Parameters:**
- `tokenId`: The token ID of the Pokemon card

**Returns:**
- `PokemonCard`: Complete Pokemon card data structure

##### `getPlayerCollection(address player)`
Gets all token IDs owned by a player.

**Parameters:**
- `player`: Player address

**Returns:**
- `uint256[]`: Array of token IDs owned by the player

##### `getPlayerPokemonCards(address player)`
Gets all Pokemon card data for a player.

**Parameters:**
- `player`: Player address

**Returns:**
- `PokemonCard[]`: Array of Pokemon card data structures

##### `isCardActive(uint256 tokenId)`
Checks if a card is active (not in battle).

**Parameters:**
- `tokenId`: The token ID

**Returns:**
- `bool`: True if card is active

##### `setCardActiveStatus(uint256 tokenId, bool active)`
Sets card active status (only callable by game contracts).

**Parameters:**
- `tokenId`: The token ID
- `active`: Active status

**Access:** Owner only

#### Configuration Functions

##### `setMintPrice(uint256 newPrice)`
Sets the minting price for new cards.

**Parameters:**
- `newPrice`: New minting price in wei

**Access:** Owner only

##### `setMaxCardsPerPlayer(uint256 newMax)`
Sets the maximum cards per player.

**Parameters:**
- `newMax`: New maximum limit

**Access:** Owner only

##### `setBaseURI(string memory baseURI)`
Sets the base URI for metadata.

**Parameters:**
- `baseURI`: New base URI

**Access:** Owner only

### PokemonBattle Contract

#### Functions

##### `createBattle(uint256[] memory pokemonIds)`
Creates a new battle.

**Parameters:**
- `pokemonIds`: Array of Pokemon token IDs to use in battle

**Requirements:**
- Sufficient battle fee payment
- Player not already in active battle
- Valid team size (1-6 Pokemon)

**Events:**
- `BattleCreated(uint256 indexed battleId, address indexed player1, address indexed player2)`

##### `joinBattle(uint256 battleId, uint256[] memory pokemonIds)`
Joins an existing battle.

**Parameters:**
- `battleId`: The battle ID to join
- `pokemonIds`: Array of Pokemon token IDs to use in battle

**Requirements:**
- Battle is waiting for opponent
- Player not already in active battle
- Valid team size

**Events:**
- `BattleJoined(uint256 indexed battleId, address indexed player)`
- `BattleStarted(uint256 indexed battleId)`

##### `executeMove(uint256 battleId, uint256 moveIndex, uint256 targetPokemonIndex)`
Executes a move in battle.

**Parameters:**
- `battleId`: The battle ID
- `moveIndex`: Index of the move to execute
- `targetPokemonIndex`: Target Pokemon index

**Requirements:**
- Battle is active
- Player's turn
- Battle hasn't timed out
- Sufficient energy for move

**Events:**
- `MoveExecuted(uint256 indexed battleId, address indexed player, string moveName, uint256 damage)`
- `BattleFinished(uint256 indexed battleId, address indexed winner)`

##### `cancelBattle(uint256 battleId)`
Cancels a waiting battle.

**Parameters:**
- `battleId`: The battle ID to cancel

**Requirements:**
- Battle is waiting for opponent
- Player is battle participant

**Events:**
- `BattleCancelled(uint256 indexed battleId)`

##### `getBattle(uint256 battleId)`
Gets battle data.

**Parameters:**
- `battleId`: The battle ID

**Returns:**
- `Battle`: Complete battle data structure

##### `getPlayerActiveBattle(address player)`
Gets player's active battle ID.

**Parameters:**
- `player`: Player address

**Returns:**
- `uint256`: Active battle ID (0 if none)

### PokemonTrading Contract

#### Functions

##### `createTradingOffer(uint256[] memory offeredCards, address targetPlayer, uint256[] memory requestedCards)`
Creates a trading offer.

**Parameters:**
- `offeredCards`: Array of token IDs to offer
- `targetPlayer`: Target player address (address(0) for public offer)
- `requestedCards`: Array of token IDs requested

**Requirements:**
- Sufficient trading fee payment
- Valid offer (at least one card offered and requested)
- Player owns offered cards

**Events:**
- `TradingOfferCreated(uint256 indexed offerId, address indexed offerer, uint256[] offeredCards, address indexed targetPlayer, uint256[] requestedCards)`

##### `acceptTradingOffer(uint256 offerId)`
Accepts a trading offer.

**Parameters:**
- `offerId`: The offer ID to accept

**Requirements:**
- Offer is active and not expired
- Player owns requested cards
- Sufficient trading fee payment

**Events:**
- `TradingOfferAccepted(uint256 indexed offerId, address indexed accepter)`

##### `cancelTradingOffer(uint256 offerId)`
Cancels a trading offer.

**Parameters:**
- `offerId`: The offer ID to cancel

**Requirements:**
- Player is offer owner

**Events:**
- `TradingOfferCancelled(uint256 indexed offerId, address indexed offerer)`

##### `getTradingOffer(uint256 offerId)`
Gets trading offer data.

**Parameters:**
- `offerId`: The offer ID

**Returns:**
- `TradingOffer`: Complete trading offer data structure

##### `getPlayerOffers(address player)`
Gets player's active offers.

**Parameters:**
- `player`: Player address

**Returns:**
- `uint256[]`: Array of offer IDs

##### `getPublicTradingOffers()`
Gets all active public trading offers.

**Returns:**
- `uint256[]`: Array of public offer IDs

##### `getTargetedTradingOffers(address targetPlayer)`
Gets offers targeted to a specific player.

**Parameters:**
- `targetPlayer`: Target player address

**Returns:**
- `uint256[]`: Array of targeted offer IDs

##### `cleanupExpiredOffers(uint256[] memory offerIds)`
Cleans up expired offers.

**Parameters:**
- `offerIds`: Array of offer IDs to check and clean up

**Access:** Anyone can call

### PokemonGameFactory Contract

#### Functions

##### `getContractAddresses()`
Gets all contract addresses.

**Returns:**
- `address`: PokemonCardNFT address
- `address`: PokemonBattle address
- `address`: PokemonTrading address

##### `updateGameConfiguration(string memory gameName, string memory gameVersion, string memory baseTokenURI)`
Updates game configuration.

**Parameters:**
- `gameName`: New game name
- `gameVersion`: New game version
- `baseTokenURI`: New base token URI

**Access:** Owner only

##### `setNFTConfiguration(uint256 mintPrice, uint256 maxCardsPerPlayer)`
Sets NFT contract configuration.

**Parameters:**
- `mintPrice`: New minting price
- `maxCardsPerPlayer`: New max cards per player

**Access:** Owner only

##### `setBattleConfiguration(uint256 maxBattleDuration, uint256 battleReward, uint256 energyPerTurn, uint256 maxEnergy)`
Sets battle contract configuration.

**Parameters:**
- `maxBattleDuration`: New max battle duration
- `battleReward`: New battle reward
- `energyPerTurn`: New energy per turn
- `maxEnergy`: New max energy

**Access:** Owner only

##### `setTradingConfiguration(uint256 offerExpirationTime, uint256 tradingFee)`
Sets trading contract configuration.

**Parameters:**
- `offerExpirationTime`: New offer expiration time
- `tradingFee`: New trading fee

**Access:** Owner only

##### `pauseAllContracts()`
Pauses all game contracts.

**Access:** Owner only

##### `unpauseAllContracts()`
Unpauses all game contracts.

**Access:** Owner only

##### `withdrawAllFunds()`
Withdraws funds from all contracts.

**Access:** Owner only

## Solana API (Rust/Anchor)

### Program Functions

#### `initialize()`
Initializes the Pokemon Card Game program.

**Accounts:**
- `game_state`: Game state account (PDA)
- `authority`: Program authority
- `system_program`: Solana system program

**Requirements:**
- Authority must be a signer
- Game state account must be initialized

#### `mint_pokemon_card(card_data: PokemonCardData)`
Mints a new Pokemon card.

**Parameters:**
- `card_data`: Pokemon card data structure

**Accounts:**
- `game_state`: Game state account (PDA)
- `pokemon_card`: Pokemon card account (PDA)
- `player_state`: Player state account (PDA)
- `player`: Player account (signer)
- `payment`: Payment token account
- `system_program`: Solana system program

**Requirements:**
- Sufficient payment
- Player hasn't exceeded max cards per player
- Valid card data

**Events:**
- `PokemonCardMinted`

#### `create_battle(pokemon_token_ids: Vec<u64>)`
Creates a new battle.

**Parameters:**
- `pokemon_token_ids`: Array of Pokemon token IDs

**Accounts:**
- `game_state`: Game state account (PDA)
- `battle`: Battle account (PDA)
- `player_state`: Player state account (PDA)
- `player`: Player account (signer)
- `payment`: Payment token account
- `system_program`: Solana system program

**Requirements:**
- Sufficient payment
- Player not already in active battle
- Valid team size

**Events:**
- `BattleCreated`

#### `join_battle(pokemon_token_ids: Vec<u64>)`
Joins an existing battle.

**Parameters:**
- `pokemon_token_ids`: Array of Pokemon token IDs

**Accounts:**
- `battle`: Battle account (PDA)
- `player_state`: Player state account (PDA)
- `player`: Player account (signer)
- `payment`: Payment token account
- `system_program`: Solana system program

**Requirements:**
- Battle is waiting for opponent
- Player not already in active battle
- Valid team size

**Events:**
- `BattleJoined`
- `BattleStarted`

#### `execute_move(move_index: u8, target_pokemon_index: u8)`
Executes a move in battle.

**Parameters:**
- `move_index`: Index of the move to execute
- `target_pokemon_index`: Target Pokemon index

**Accounts:**
- `battle`: Battle account (PDA)
- `game_state`: Game state account (PDA)
- `player_state`: Player state account (PDA)
- `current_pokemon`: Current Pokemon card account
- `target_pokemon`: Target Pokemon card account
- `player`: Player account (signer)
- `system_program`: Solana system program

**Requirements:**
- Battle is active
- Player's turn
- Battle hasn't timed out
- Sufficient energy

**Events:**
- `MoveExecuted`
- `BattleFinished`

#### `create_trading_offer(offered_cards: Vec<u64>, requested_cards: Vec<u64>, target_player: Option<Pubkey>)`
Creates a trading offer.

**Parameters:**
- `offered_cards`: Array of token IDs to offer
- `requested_cards`: Array of token IDs requested
- `target_player`: Target player (None for public offer)

**Accounts:**
- `game_state`: Game state account (PDA)
- `trading_offer`: Trading offer account (PDA)
- `player`: Player account (signer)
- `payment`: Payment token account
- `system_program`: Solana system program

**Requirements:**
- Sufficient payment
- Valid offer
- Player owns offered cards

**Events:**
- `TradingOfferCreated`

#### `accept_trading_offer()`
Accepts a trading offer.

**Accounts:**
- `trading_offer`: Trading offer account (PDA)
- `game_state`: Game state account (PDA)
- `player`: Player account (signer)
- `payment`: Payment token account
- `system_program`: Solana system program

**Requirements:**
- Offer is active and not expired
- Player owns requested cards
- Sufficient payment

**Events:**
- `TradingOfferAccepted`

## Data Structures

### PokemonCard

```solidity
struct PokemonCard {
    uint256 tokenId;
    string name;
    PokemonType pokemonType;
    uint256 hp;
    uint256 attack;
    uint256 defense;
    uint256 speed;
    Rarity rarity;
    EvolutionStage evolutionStage;
    uint256 evolutionCost;
    Move[] moves;
    string imageUri;
    string description;
    bool isActive;
}
```

### Battle

```solidity
struct Battle {
    uint256 battleId;
    BattleParticipant player1;
    BattleParticipant player2;
    BattleStatus status;
    uint256 turnNumber;
    address currentPlayer;
    uint256 createdAt;
    uint256 finishedAt;
}
```

### TradingOffer

```solidity
struct TradingOffer {
    uint256 offerId;
    address offerer;
    uint256[] offeredCards;
    address targetPlayer;
    uint256[] requestedCards;
    bool isActive;
    uint256 createdAt;
    uint256 expiresAt;
}
```

## Error Codes

### EVM Errors

- `InsufficientPayment`: Payment amount is less than required
- `MaxCardsExceeded`: Player has reached maximum cards limit
- `PlayerAlreadyInBattle`: Player is already in an active battle
- `InvalidTeamSize`: Team size is not valid (must be 1-6)
- `BattleNotAvailable`: Battle is not available for joining
- `BattleNotActive`: Battle is not in active state
- `NotYourTurn`: It's not the player's turn
- `BattleTimeout`: Battle has timed out
- `InvalidMove`: Move index is invalid
- `InsufficientEnergy`: Player doesn't have enough energy
- `InvalidTradingOffer`: Trading offer is invalid
- `OfferNotActive`: Trading offer is not active
- `OfferExpired`: Trading offer has expired
- `OfferNotTargetedToYou`: Trading offer is not targeted to you

### Solana Errors

- `InsufficientPayment`: Payment amount is less than required
- `MaxCardsExceeded`: Player has reached maximum cards limit
- `PlayerAlreadyInBattle`: Player is already in an active battle
- `InvalidTeamSize`: Team size is not valid (must be 1-6)
- `BattleNotAvailable`: Battle is not available for joining
- `BattleNotActive`: Battle is not in active state
- `NotYourTurn`: It's not the player's turn
- `BattleTimeout`: Battle has timed out
- `InvalidMove`: Move index is invalid
- `InsufficientEnergy`: Player doesn't have enough energy
- `InvalidTradingOffer`: Trading offer is invalid
- `OfferNotActive`: Trading offer is not active
- `OfferExpired`: Trading offer has expired
- `OfferNotTargetedToYou`: Trading offer is not targeted to you

## Events

### EVM Events

- `PokemonCardMinted`: Emitted when a Pokemon card is minted
- `BattleCreated`: Emitted when a battle is created
- `BattleJoined`: Emitted when a player joins a battle
- `BattleStarted`: Emitted when a battle starts
- `BattleFinished`: Emitted when a battle finishes
- `MoveExecuted`: Emitted when a move is executed
- `BattleCancelled`: Emitted when a battle is cancelled
- `TradingOfferCreated`: Emitted when a trading offer is created
- `TradingOfferAccepted`: Emitted when a trading offer is accepted
- `TradingOfferCancelled`: Emitted when a trading offer is cancelled
- `PokemonCardTransferred`: Emitted when a Pokemon card is transferred

### Solana Events

- `PokemonCardMinted`: Emitted when a Pokemon card is minted
- `BattleCreated`: Emitted when a battle is created
- `BattleJoined`: Emitted when a player joins a battle
- `BattleStarted`: Emitted when a battle starts
- `BattleFinished`: Emitted when a battle finishes
- `MoveExecuted`: Emitted when a move is executed
- `TradingOfferCreated`: Emitted when a trading offer is created
- `TradingOfferAccepted`: Emitted when a trading offer is accepted

## Usage Examples

### EVM Examples

#### Mint a Pokemon Card

```javascript
const cardData = {
    name: "Pikachu",
    pokemonType: 4, // ELECTRIC
    hp: 60,
    attack: 55,
    defense: 40,
    speed: 90,
    rarity: 1, // UNCOMMON
    evolutionStage: 0, // BASIC
    evolutionCost: 0,
    moves: [
        {
            name: "Thunder Shock",
            type: 4, // ELECTRIC
            moveType: 1, // SPECIAL
            power: 40,
            accuracy: 100,
            energyCost: 20,
            description: "A weak electric attack."
        }
    ],
    imageUri: "https://api.pokemoncardgame.com/images/pikachu.png",
    description: "A cute Electric-type Pokemon."
};

const mintPrice = await pokemonCardNFT.mintPrice();
await pokemonCardNFT.mintPokemonCard(cardData, { value: mintPrice });
```

#### Create a Battle

```javascript
const battleReward = await pokemonBattle.battleReward();
const pokemonIds = [0, 1, 2]; // Token IDs of Pokemon to use

await pokemonBattle.createBattle(pokemonIds, { value: battleReward });
```

#### Create a Trading Offer

```javascript
const tradingFee = await pokemonTrading.tradingFee();
const offeredCards = [0]; // Pikachu
const requestedCards = [1]; // Charmander
const targetPlayer = "0x..."; // Target player address

await pokemonTrading.createTradingOffer(
    offeredCards,
    targetPlayer,
    requestedCards,
    { value: tradingFee }
);
```

### Solana Examples

#### Mint a Pokemon Card

```typescript
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
            description: "A weak electric attack."
        }
    ],
    imageUri: "https://api.pokemoncardgame.com/images/pikachu.png",
    description: "A cute Electric-type Pokemon."
};

await program.methods
    .mintPokemonCard(cardData)
    .accounts({
        gameState: gameState,
        pokemonCard: pokemonCard,
        playerState: playerState,
        player: player.publicKey,
        payment: payment.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
    })
    .signers([player, payment])
    .rpc();
```

#### Create a Battle

```typescript
const pokemonTokenIds = [new anchor.BN(0), new anchor.BN(1), new anchor.BN(2)];

await program.methods
    .createBattle(pokemonTokenIds)
    .accounts({
        gameState: gameState,
        battle: battle,
        playerState: playerState,
        player: player.publicKey,
        payment: payment.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
    })
    .signers([player, payment])
    .rpc();
```

#### Create a Trading Offer

```typescript
const offeredCards = [new anchor.BN(0)]; // Pikachu
const requestedCards = [new anchor.BN(1)]; // Charmander
const targetPlayer = new anchor.web3.PublicKey("..."); // Target player

await program.methods
    .createTradingOffer(offeredCards, requestedCards, targetPlayer)
    .accounts({
        gameState: gameState,
        tradingOffer: tradingOffer,
        player: player.publicKey,
        payment: payment.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
    })
    .signers([player, payment])
    .rpc();
```

## Conclusion

This API documentation provides comprehensive information about all functions, data structures, events, and error codes for both EVM and Solana implementations of the Pokemon Card Game. Use this documentation to integrate with the smart contracts and build applications on top of the game.
