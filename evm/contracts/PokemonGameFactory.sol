// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./PokemonCardNFT.sol";
import "./PokemonBattle.sol";
import "./PokemonTrading.sol";

/**
 * @title PokemonGameFactory
 * @dev Factory contract for deploying and managing Pokemon Game contracts
 */
contract PokemonGameFactory is Ownable, Pausable {
    
    // Contract addresses
    PokemonCardNFT public pokemonCardNFT;
    PokemonBattle public pokemonBattle;
    PokemonTrading public pokemonTrading;
    
    // Game configuration
    string public gameName = "Pokemon Card Game";
    string public gameVersion = "1.0.0";
    string public baseTokenURI = "https://api.pokemoncardgame.com/metadata/";
    
    // Events
    event GameDeployed(
        address indexed pokemonCardNFT,
        address indexed pokemonBattle,
        address indexed pokemonTrading
    );
    
    event GameConfigurationUpdated(
        string gameName,
        string gameVersion,
        string baseTokenURI
    );
    
    constructor() {
        _deployGameContracts();
    }
    
    /**
     * @dev Deploy all game contracts
     */
    function _deployGameContracts() internal {
        // Deploy PokemonCardNFT
        pokemonCardNFT = new PokemonCardNFT(
            "Pokemon Cards",
            "PKMN",
            baseTokenURI
        );
        
        // Deploy PokemonBattle
        pokemonBattle = new PokemonBattle(address(pokemonCardNFT));
        
        // Deploy PokemonTrading
        pokemonTrading = new PokemonTrading(address(pokemonCardNFT));
        
        // Transfer ownership of contracts to factory owner
        pokemonCardNFT.transferOwnership(owner());
        pokemonBattle.transferOwnership(owner());
        pokemonTrading.transferOwnership(owner());
        
        emit GameDeployed(
            address(pokemonCardNFT),
            address(pokemonBattle),
            address(pokemonTrading)
        );
    }
    
    /**
     * @dev Get all contract addresses
     * @return nftAddress The PokemonCardNFT address
     * @return battleAddress The PokemonBattle address
     * @return tradingAddress The PokemonTrading address
     */
    function getContractAddresses() external view returns (
        address nftAddress,
        address battleAddress,
        address tradingAddress
    ) {
        return (
            address(pokemonCardNFT),
            address(pokemonBattle),
            address(pokemonTrading)
        );
    }
    
    /**
     * @dev Update game configuration
     * @param _gameName New game name
     * @param _gameVersion New game version
     * @param _baseTokenURI New base token URI
     */
    function updateGameConfiguration(
        string memory _gameName,
        string memory _gameVersion,
        string memory _baseTokenURI
    ) external onlyOwner {
        gameName = _gameName;
        gameVersion = _gameVersion;
        baseTokenURI = _baseTokenURI;
        
        // Update base URI in NFT contract
        pokemonCardNFT.setBaseURI(_baseTokenURI);
        
        emit GameConfigurationUpdated(_gameName, _gameVersion, _baseTokenURI);
    }
    
    /**
     * @dev Set NFT contract configuration
     * @param mintPrice New minting price
     * @param maxCardsPerPlayer New max cards per player
     */
    function setNFTConfiguration(
        uint256 mintPrice,
        uint256 maxCardsPerPlayer
    ) external onlyOwner {
        pokemonCardNFT.setMintPrice(mintPrice);
        pokemonCardNFT.setMaxCardsPerPlayer(maxCardsPerPlayer);
    }
    
    /**
     * @dev Set battle contract configuration
     * @param maxBattleDuration New max battle duration
     * @param battleReward New battle reward
     * @param energyPerTurn New energy per turn
     * @param maxEnergy New max energy
     */
    function setBattleConfiguration(
        uint256 maxBattleDuration,
        uint256 battleReward,
        uint256 energyPerTurn,
        uint256 maxEnergy
    ) external onlyOwner {
        pokemonBattle.setBattleConfig(
            maxBattleDuration,
            battleReward,
            energyPerTurn,
            maxEnergy
        );
    }
    
    /**
     * @dev Set trading contract configuration
     * @param offerExpirationTime New offer expiration time
     * @param tradingFee New trading fee
     */
    function setTradingConfiguration(
        uint256 offerExpirationTime,
        uint256 tradingFee
    ) external onlyOwner {
        pokemonTrading.setTradingConfig(offerExpirationTime, tradingFee);
    }
    
    /**
     * @dev Pause all game contracts
     */
    function pauseAllContracts() external onlyOwner {
        pokemonCardNFT.pause();
        pokemonBattle.pause();
        pokemonTrading.pause();
        _pause();
    }
    
    /**
     * @dev Unpause all game contracts
     */
    function unpauseAllContracts() external onlyOwner {
        pokemonCardNFT.unpause();
        pokemonBattle.unpause();
        pokemonTrading.unpause();
        _unpause();
    }
    
    /**
     * @dev Withdraw funds from all contracts
     */
    function withdrawAllFunds() external onlyOwner {
        pokemonCardNFT.withdraw();
        pokemonBattle.withdraw();
        pokemonTrading.withdraw();
    }
    
    /**
     * @dev Get game statistics
     * @return totalCardsMinted Total number of cards minted
     * @return totalBattles Total number of battles created
     * @return totalTrades Total number of trading offers created
     */
    function getGameStatistics() external view returns (
        uint256 totalCardsMinted,
        uint256 totalBattles,
        uint256 totalTrades
    ) {
        // Note: These would need to be tracked in the individual contracts
        // For now, returning placeholder values
        return (0, 0, 0);
    }
    
    /**
     * @dev Emergency function to transfer ownership of individual contracts
     * @param contractType 0: NFT, 1: Battle, 2: Trading
     * @param newOwner New owner address
     */
    function transferContractOwnership(
        uint256 contractType,
        address newOwner
    ) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        
        if (contractType == 0) {
            pokemonCardNFT.transferOwnership(newOwner);
        } else if (contractType == 1) {
            pokemonBattle.transferOwnership(newOwner);
        } else if (contractType == 2) {
            pokemonTrading.transferOwnership(newOwner);
        } else {
            revert("Invalid contract type");
        }
    }
}
