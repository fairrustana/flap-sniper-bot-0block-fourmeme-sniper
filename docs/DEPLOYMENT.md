# Deployment Guide

This guide covers the deployment process for both EVM and Solana implementations of the Pokemon Card Game.

## Prerequisites

### EVM Deployment

- Node.js (v16 or higher)
- npm or yarn
- Hardhat
- Access to an EVM-compatible network (Ethereum, Polygon, BSC, etc.)
- Private key with sufficient funds for deployment

### Solana Deployment

- Rust (latest stable version)
- Solana CLI tools
- Anchor framework
- Access to Solana network (devnet/testnet/mainnet)
- SOL for deployment fees

## EVM Deployment

### 1. Install Dependencies

```bash
cd evm
npm install
```

### 2. Configure Environment

Create a `.env` file in the `evm` directory:

```env
# Network Configuration
TESTNET_RPC_URL=https://your-testnet-rpc-url
MAINNET_RPC_URL=https://your-mainnet-rpc-url

# Private Key (for deployment)
PRIVATE_KEY=your-private-key-here

# Etherscan API Key (for verification)
ETHERSCAN_API_KEY=your-etherscan-api-key

# Gas Reporting
REPORT_GAS=true
```

### 3. Compile Contracts

```bash
npx hardhat compile
```

### 4. Run Tests

```bash
npx hardhat test
```

### 5. Deploy to Local Network

```bash
# Start local Hardhat network
npx hardhat node

# In another terminal, deploy contracts
npx hardhat run scripts/deploy.js --network localhost
```

### 6. Deploy to Testnet

```bash
npx hardhat run scripts/deploy.js --network testnet
```

### 7. Deploy to Mainnet

```bash
npx hardhat run scripts/deploy.js --network mainnet
```

### 8. Verify Contracts

```bash
npx hardhat verify --network mainnet <CONTRACT_ADDRESS>
```

## Solana Deployment

### 1. Install Dependencies

```bash
cd solana
npm install
```

### 2. Install Solana CLI

```bash
# Install Solana CLI
sh -c "$(curl -sSfL https://release.solana.com/v1.16.0/install)"

# Add to PATH
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# Verify installation
solana --version
```

### 3. Install Anchor

```bash
# Install Anchor
npm install -g @coral-xyz/anchor-cli

# Verify installation
anchor --version
```

### 4. Configure Solana CLI

```bash
# Set cluster (devnet for testing)
solana config set --url https://api.devnet.solana.com

# Create keypair
solana-keygen new --outfile ~/.config/solana/id.json

# Check balance
solana balance
```

### 5. Build Program

```bash
anchor build
```

### 6. Deploy Program

```bash
# Deploy to devnet
anchor deploy --provider.cluster devnet

# Deploy to testnet
anchor deploy --provider.cluster testnet

# Deploy to mainnet
anchor deploy --provider.cluster mainnet
```

### 7. Run Tests

```bash
anchor test
```

### 8. Initialize Game

```bash
# Run deployment script
npx ts-node scripts/deploy.ts
```

## Configuration

### EVM Configuration

The EVM contracts can be configured through the factory contract:

```javascript
// Set NFT configuration
await factory.setNFTConfiguration(
  ethers.utils.parseEther("0.01"), // Mint price
  1000 // Max cards per player
);

// Set battle configuration
await factory.setBattleConfiguration(
  3600, // Max battle duration (seconds)
  ethers.utils.parseEther("0.001"), // Battle reward
  10, // Energy per turn
  100 // Max energy
);

// Set trading configuration
await factory.setTradingConfiguration(
  7 * 24 * 3600, // Offer expiration (seconds)
  ethers.utils.parseEther("0.001") // Trading fee
);
```

### Solana Configuration

The Solana program configuration is set during initialization:

```rust
// Game configuration
game_state.mint_price = 1000000; // 0.001 SOL in lamports
game_state.battle_reward = 500000; // 0.0005 SOL in lamports
game_state.trading_fee = 100000; // 0.0001 SOL in lamports
game_state.max_cards_per_player = 1000;
game_state.max_battle_duration = 3600; // 1 hour
game_state.max_energy = 100;
game_state.energy_per_turn = 10;
game_state.offer_expiration_time = 604800; // 7 days
```

## Network-Specific Deployment

### Ethereum Mainnet

```bash
# Deploy to Ethereum mainnet
npx hardhat run scripts/deploy.js --network mainnet

# Verify on Etherscan
npx hardhat verify --network mainnet <CONTRACT_ADDRESS>
```

### Polygon

```bash
# Deploy to Polygon
npx hardhat run scripts/deploy.js --network polygon

# Verify on Polygonscan
npx hardhat verify --network polygon <CONTRACT_ADDRESS>
```

### Binance Smart Chain

```bash
# Deploy to BSC
npx hardhat run scripts/deploy.js --network bsc

# Verify on BSCScan
npx hardhat verify --network bsc <CONTRACT_ADDRESS>
```

### Solana Mainnet

```bash
# Deploy to Solana mainnet
anchor deploy --provider.cluster mainnet

# Initialize game
npx ts-node scripts/deploy.ts
```

## Post-Deployment

### 1. Verify Deployment

Check that all contracts are deployed correctly:

```bash
# EVM - Check contract addresses
npx hardhat run scripts/verify-deployment.js

# Solana - Check program ID and game state
solana account <PROGRAM_ID>
```

### 2. Test Basic Functionality

```bash
# EVM - Run integration tests
npx hardhat test --network testnet

# Solana - Run tests
anchor test
```

### 3. Monitor Deployment

- Check transaction logs for any errors
- Verify all contract interactions work correctly
- Monitor gas usage and costs
- Check for any security issues

### 4. Update Documentation

- Update contract addresses in documentation
- Update API endpoints if applicable
- Update frontend configuration
- Update monitoring and analytics

## Troubleshooting

### Common EVM Issues

1. **Insufficient Gas**: Increase gas limit in deployment script
2. **Contract Size**: Optimize contract code if too large
3. **Verification Failed**: Check constructor arguments and network
4. **Transaction Failed**: Check RPC URL and private key

### Common Solana Issues

1. **Insufficient SOL**: Ensure account has enough SOL for deployment
2. **Program ID Mismatch**: Update program ID in Anchor.toml
3. **Account Size**: Check account space allocation
4. **PDA Derivation**: Verify PDA seeds are correct

### Debug Commands

```bash
# EVM Debug
npx hardhat console --network localhost
npx hardhat run scripts/debug.js

# Solana Debug
solana logs <PROGRAM_ID>
anchor test --verbose
```

## Security Considerations

### Pre-Deployment

- Run comprehensive tests
- Perform security audit
- Check for known vulnerabilities
- Verify all configurations

### Post-Deployment

- Monitor for unusual activity
- Set up alerts for critical functions
- Regular security updates
- Community bug bounty program

## Maintenance

### Regular Tasks

- Monitor contract performance
- Update dependencies
- Security patches
- Performance optimizations
- Community feedback integration

### Emergency Procedures

- Pause contracts if needed
- Emergency upgrades
- Incident response
- Communication with community

## Conclusion

This deployment guide provides comprehensive instructions for deploying the Pokemon Card Game on both EVM and Solana networks. Follow the steps carefully and always test on testnets before deploying to mainnet.
