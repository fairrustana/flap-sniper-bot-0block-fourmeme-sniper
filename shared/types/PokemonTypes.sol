// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title PokemonTypes
 * @dev Shared data structures and enums for Pokemon Card Game
 */
library PokemonTypes {
    
    // Pokemon Types
    enum PokemonType {
        NORMAL,
        FIRE,
        WATER,
        GRASS,
        ELECTRIC,
        ICE,
        FIGHTING,
        POISON,
        GROUND,
        FLYING,
        PSYCHIC,
        BUG,
        ROCK,
        GHOST,
        DRAGON,
        DARK,
        STEEL,
        FAIRY
    }
    
    // Card Rarity
    enum Rarity {
        COMMON,
        UNCOMMON,
        RARE,
        EPIC,
        LEGENDARY
    }
    
    // Evolution Stage
    enum EvolutionStage {
        BASIC,
        STAGE_1,
        STAGE_2
    }
    
    // Battle Status
    enum BattleStatus {
        WAITING,
        ACTIVE,
        FINISHED,
        CANCELLED
    }
    
    // Move Type
    enum MoveType {
        PHYSICAL,
        SPECIAL,
        STATUS
    }
    
    // Pokemon Move Structure
    struct Move {
        string name;
        PokemonType type;
        MoveType moveType;
        uint256 power;
        uint256 accuracy;
        uint256 energyCost;
        string description;
    }
    
    // Pokemon Card Structure
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
    
    // Battle Participant
    struct BattleParticipant {
        address player;
        PokemonCard[] pokemon;
        uint256 currentPokemonIndex;
        uint256 energy;
        bool isReady;
    }
    
    // Battle Structure
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
    
    // Trading Offer Structure
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
    
    // Events
    event PokemonCardMinted(uint256 indexed tokenId, address indexed owner, string name);
    event BattleStarted(uint256 indexed battleId, address indexed player1, address indexed player2);
    event BattleFinished(uint256 indexed battleId, address indexed winner);
    event TradingOfferCreated(uint256 indexed offerId, address indexed offerer);
    event TradingOfferAccepted(uint256 indexed offerId, address indexed accepter);
    event PokemonEvolved(uint256 indexed tokenId, string newName, uint256 newHp);
}
