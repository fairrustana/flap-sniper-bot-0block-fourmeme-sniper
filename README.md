# Pokemon Card Game Smart Contracts

A blockchain-based Pokemon Card Game implementation supporting both EVM-compatible chains and Solana.

## Contact me on Telegram to build your own trading bots
<a href="https://t.me/cashblaze129" target="_blank">
  <img src="https://img.shields.io/badge/Telegram-@Contact_Me-0088cc?style=for-the-badge&logo=telegram&logoColor=white" alt="Telegram Support" />
</a>

## Features

- **Card Collection**: Mint and collect Pokemon cards as NFTs
- **Battle System**: Engage in Pokemon battles with other players
- **Trading**: Trade cards with other players
- **Cross-Chain**: Support for both EVM and Solana ecosystems

## Project Structure

```
pokemon-card-game/
├── evm/                    # EVM-compatible contracts (Solidity)
│   ├── contracts/          # Smart contracts
│   ├── test/              # Test files
│   ├── scripts/           # Deployment scripts
│   └── hardhat.config.js  # Hardhat configuration
├── solana/                 # Solana contracts (Rust)
│   ├── programs/          # Anchor programs
│   ├── tests/             # Test files
│   └── Anchor.toml        # Anchor configuration
├── shared/                 # Shared utilities and types
└── docs/                  # Documentation
```

## Getting Started

### EVM Contracts (Solidity)

1. Install dependencies:
```bash
cd evm
npm install
```

2. Compile contracts:
```bash
npx hardhat compile
```

3. Run tests:
```bash
npx hardhat test
```

### Solana Contracts (Rust)

1. Install dependencies:
```bash
cd solana
anchor build
```

2. Run tests:
```bash
anchor test
```

## Smart Contract Features

### Core Functionality

- **Card Minting**: Create new Pokemon cards with unique attributes
- **Battle Mechanics**: Implement turn-based Pokemon battles
- **Energy System**: Manage energy consumption for attacks
- **Evolution**: Allow Pokemon to evolve with proper conditions
- **Trading**: Peer-to-peer card trading system
- **Leaderboards**: Track top players and collections

### Card Attributes

- **Name**: Pokemon species name
- **Type**: Fire, Water, Grass, Electric, etc.
- **HP**: Hit Points
- **Attack**: Attack power
- **Defense**: Defense power
- **Speed**: Battle speed
- **Rarity**: Common, Uncommon, Rare, Epic, Legendary
- **Evolution Stage**: Basic, Stage 1, Stage 2
- **Moves**: Available attacks and abilities

## License

MIT License
