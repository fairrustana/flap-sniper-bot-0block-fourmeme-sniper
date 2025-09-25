// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./PokemonCardNFT.sol";
import "../shared/types/PokemonTypes.sol";

/**
 * @title PokemonBattle
 * @dev Contract for managing Pokemon battles
 */
contract PokemonBattle is Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    
    Counters.Counter private _battleIdCounter;
    
    PokemonCardNFT public pokemonCardNFT;
    
    // Mapping from battle ID to battle data
    mapping(uint256 => PokemonTypes.Battle) public battles;
    
    // Mapping from player to active battle ID
    mapping(address => uint256) public playerActiveBattles;
    
    // Battle configuration
    uint256 public maxBattleDuration = 1 hours;
    uint256 public battleReward = 0.001 ether;
    uint256 public energyPerTurn = 10;
    uint256 public maxEnergy = 100;
    
    // Events
    event BattleCreated(uint256 indexed battleId, address indexed player1, address indexed player2);
    event BattleJoined(uint256 indexed battleId, address indexed player);
    event BattleStarted(uint256 indexed battleId);
    event BattleFinished(uint256 indexed battleId, address indexed winner);
    event BattleCancelled(uint256 indexed battleId);
    event MoveExecuted(uint256 indexed battleId, address indexed player, string moveName, uint256 damage);
    
    constructor(address _pokemonCardNFT) {
        pokemonCardNFT = PokemonCardNFT(_pokemonCardNFT);
    }
    
    /**
     * @dev Create a new battle
     * @param pokemonIds Array of Pokemon token IDs to use in battle
     */
    function createBattle(uint256[] memory pokemonIds) external payable whenNotPaused nonReentrant {
        require(msg.value >= battleReward, "Insufficient battle fee");
        require(pokemonIds.length > 0 && pokemonIds.length <= 6, "Invalid team size");
        require(playerActiveBattles[msg.sender] == 0, "Player already in active battle");
        
        // Validate Pokemon ownership and active status
        for (uint256 i = 0; i < pokemonIds.length; i++) {
            require(pokemonCardNFT.ownerOf(pokemonIds[i]) == msg.sender, "Not owner of Pokemon");
            require(pokemonCardNFT.isCardActive(pokemonIds[i]), "Pokemon not active");
        }
        
        uint256 battleId = _battleIdCounter.current();
        _battleIdCounter.increment();
        
        // Create battle
        PokemonTypes.Battle storage battle = battles[battleId];
        battle.battleId = battleId;
        battle.player1.player = msg.sender;
        battle.player1.energy = maxEnergy;
        battle.player1.isReady = true;
        battle.status = PokemonTypes.BattleStatus.WAITING;
        battle.createdAt = block.timestamp;
        
        // Set Pokemon cards for player 1
        for (uint256 i = 0; i < pokemonIds.length; i++) {
            PokemonTypes.PokemonCard memory card = pokemonCardNFT.getPokemonCard(pokemonIds[i]);
            battle.player1.pokemon.push(card);
        }
        
        playerActiveBattles[msg.sender] = battleId;
        
        emit BattleCreated(battleId, msg.sender, address(0));
    }
    
    /**
     * @dev Join an existing battle
     * @param battleId The battle ID to join
     * @param pokemonIds Array of Pokemon token IDs to use in battle
     */
    function joinBattle(uint256 battleId, uint256[] memory pokemonIds) external payable whenNotPaused nonReentrant {
        require(msg.value >= battleReward, "Insufficient battle fee");
        require(battles[battleId].status == PokemonTypes.BattleStatus.WAITING, "Battle not available");
        require(battles[battleId].player2.player == address(0), "Battle already full");
        require(pokemonIds.length > 0 && pokemonIds.length <= 6, "Invalid team size");
        require(playerActiveBattles[msg.sender] == 0, "Player already in active battle");
        
        // Validate Pokemon ownership and active status
        for (uint256 i = 0; i < pokemonIds.length; i++) {
            require(pokemonCardNFT.ownerOf(pokemonIds[i]) == msg.sender, "Not owner of Pokemon");
            require(pokemonCardNFT.isCardActive(pokemonIds[i]), "Pokemon not active");
        }
        
        PokemonTypes.Battle storage battle = battles[battleId];
        battle.player2.player = msg.sender;
        battle.player2.energy = maxEnergy;
        battle.player2.isReady = true;
        
        // Set Pokemon cards for player 2
        for (uint256 i = 0; i < pokemonIds.length; i++) {
            PokemonTypes.PokemonCard memory card = pokemonCardNFT.getPokemonCard(pokemonIds[i]);
            battle.player2.pokemon.push(card);
        }
        
        playerActiveBattles[msg.sender] = battleId;
        
        // Start battle if both players are ready
        if (battle.player1.isReady && battle.player2.isReady) {
            _startBattle(battleId);
        }
        
        emit BattleJoined(battleId, msg.sender);
    }
    
    /**
     * @dev Start a battle (internal)
     * @param battleId The battle ID
     */
    function _startBattle(uint256 battleId) internal {
        PokemonTypes.Battle storage battle = battles[battleId];
        
        battle.status = PokemonTypes.BattleStatus.ACTIVE;
        battle.turnNumber = 1;
        battle.currentPlayer = battle.player1.player;
        
        // Set Pokemon as inactive during battle
        for (uint256 i = 0; i < battle.player1.pokemon.length; i++) {
            pokemonCardNFT.setCardActiveStatus(battle.player1.pokemon[i].tokenId, false);
        }
        for (uint256 i = 0; i < battle.player2.pokemon.length; i++) {
            pokemonCardNFT.setCardActiveStatus(battle.player2.pokemon[i].tokenId, false);
        }
        
        emit BattleStarted(battleId);
    }
    
    /**
     * @dev Execute a move in battle
     * @param battleId The battle ID
     * @param moveIndex The index of the move to execute
     * @param targetPokemonIndex The target Pokemon index (0 for opponent's current Pokemon)
     */
    function executeMove(
        uint256 battleId,
        uint256 moveIndex,
        uint256 targetPokemonIndex
    ) external whenNotPaused nonReentrant {
        PokemonTypes.Battle storage battle = battles[battleId];
        require(battle.status == PokemonTypes.BattleStatus.ACTIVE, "Battle not active");
        require(battle.currentPlayer == msg.sender, "Not your turn");
        require(block.timestamp <= battle.createdAt + maxBattleDuration, "Battle timeout");
        
        PokemonTypes.BattleParticipant storage currentPlayer = 
            battle.currentPlayer == battle.player1.player ? battle.player1 : battle.player2;
        PokemonTypes.BattleParticipant storage opponent = 
            battle.currentPlayer == battle.player1.player ? battle.player2 : battle.player1;
        
        require(currentPlayer.currentPokemonIndex < currentPlayer.pokemon.length, "No active Pokemon");
        require(targetPokemonIndex < opponent.pokemon.length, "Invalid target");
        
        PokemonTypes.PokemonCard storage currentPokemon = currentPlayer.pokemon[currentPlayer.currentPokemonIndex];
        PokemonTypes.PokemonCard storage targetPokemon = opponent.pokemon[targetPokemonIndex];
        
        require(moveIndex < currentPokemon.moves.length, "Invalid move");
        
        PokemonTypes.Move memory move = currentPokemon.moves[moveIndex];
        require(currentPlayer.energy >= move.energyCost, "Insufficient energy");
        
        // Execute move
        currentPlayer.energy -= move.energyCost;
        
        uint256 damage = _calculateDamage(currentPokemon, targetPokemon, move);
        if (damage >= targetPokemon.hp) {
            targetPokemon.hp = 0;
            // Switch to next Pokemon or end battle
            _handlePokemonDefeat(battleId, targetPokemonIndex == opponent.currentPokemonIndex);
        } else {
            targetPokemon.hp -= damage;
        }
        
        emit MoveExecuted(battleId, msg.sender, move.name, damage);
        
        // Check if battle is over
        if (_isBattleOver(battleId)) {
            _finishBattle(battleId);
        } else {
            _nextTurn(battleId);
        }
    }
    
    /**
     * @dev Calculate damage for a move
     * @param attacker The attacking Pokemon
     * @param defender The defending Pokemon
     * @param move The move being used
     * @return The calculated damage
     */
    function _calculateDamage(
        PokemonTypes.PokemonCard memory attacker,
        PokemonTypes.PokemonCard memory defender,
        PokemonTypes.Move memory move
    ) internal pure returns (uint256) {
        // Simple damage calculation (can be enhanced with type effectiveness, etc.)
        uint256 baseDamage = move.power;
        uint256 attackStat = move.moveType == PokemonTypes.MoveType.PHYSICAL ? attacker.attack : attacker.attack;
        uint256 defenseStat = move.moveType == PokemonTypes.MoveType.PHYSICAL ? defender.defense : defender.defense;
        
        uint256 damage = (baseDamage * attackStat) / (defenseStat + 50);
        return damage > 0 ? damage : 1; // Minimum 1 damage
    }
    
    /**
     * @dev Handle Pokemon defeat
     * @param battleId The battle ID
     * @param isCurrentPokemon Whether the defeated Pokemon is the current active Pokemon
     */
    function _handlePokemonDefeat(uint256 battleId, bool isCurrentPokemon) internal {
        PokemonTypes.Battle storage battle = battles[battleId];
        PokemonTypes.BattleParticipant storage opponent = 
            battle.currentPlayer == battle.player1.player ? battle.player2 : battle.player1;
        
        if (isCurrentPokemon) {
            // Find next available Pokemon
            bool hasAlivePokemon = false;
            for (uint256 i = 0; i < opponent.pokemon.length; i++) {
                if (opponent.pokemon[i].hp > 0) {
                    opponent.currentPokemonIndex = i;
                    hasAlivePokemon = true;
                    break;
                }
            }
            
            if (!hasAlivePokemon) {
                // All Pokemon defeated, battle over
                _finishBattle(battleId);
            }
        }
    }
    
    /**
     * @dev Check if battle is over
     * @param battleId The battle ID
     * @return True if battle is over
     */
    function _isBattleOver(uint256 battleId) internal view returns (bool) {
        PokemonTypes.Battle storage battle = battles[battleId];
        
        // Check if all Pokemon of either player are defeated
        bool player1Alive = false;
        bool player2Alive = false;
        
        for (uint256 i = 0; i < battle.player1.pokemon.length; i++) {
            if (battle.player1.pokemon[i].hp > 0) {
                player1Alive = true;
                break;
            }
        }
        
        for (uint256 i = 0; i < battle.player2.pokemon.length; i++) {
            if (battle.player2.pokemon[i].hp > 0) {
                player2Alive = true;
                break;
            }
        }
        
        return !player1Alive || !player2Alive;
    }
    
    /**
     * @dev Move to next turn
     * @param battleId The battle ID
     */
    function _nextTurn(uint256 battleId) internal {
        PokemonTypes.Battle storage battle = battles[battleId];
        
        // Switch current player
        battle.currentPlayer = battle.currentPlayer == battle.player1.player ? 
            battle.player2.player : battle.player1.player;
        
        // Restore some energy
        PokemonTypes.BattleParticipant storage currentPlayer = 
            battle.currentPlayer == battle.player1.player ? battle.player1 : battle.player2;
        
        currentPlayer.energy = currentPlayer.energy + energyPerTurn > maxEnergy ? 
            maxEnergy : currentPlayer.energy + energyPerTurn;
        
        battle.turnNumber++;
    }
    
    /**
     * @dev Finish battle and determine winner
     * @param battleId The battle ID
     */
    function _finishBattle(uint256 battleId) internal {
        PokemonTypes.Battle storage battle = battles[battleId];
        
        battle.status = PokemonTypes.BattleStatus.FINISHED;
        battle.finishedAt = block.timestamp;
        
        // Determine winner
        address winner = address(0);
        bool player1Alive = false;
        bool player2Alive = false;
        
        for (uint256 i = 0; i < battle.player1.pokemon.length; i++) {
            if (battle.player1.pokemon[i].hp > 0) {
                player1Alive = true;
                break;
            }
        }
        
        for (uint256 i = 0; i < battle.player2.pokemon.length; i++) {
            if (battle.player2.pokemon[i].hp > 0) {
                player2Alive = true;
                break;
            }
        }
        
        if (player1Alive && !player2Alive) {
            winner = battle.player1.player;
        } else if (player2Alive && !player1Alive) {
            winner = battle.player2.player;
        }
        
        // Restore Pokemon active status
        for (uint256 i = 0; i < battle.player1.pokemon.length; i++) {
            pokemonCardNFT.setCardActiveStatus(battle.player1.pokemon[i].tokenId, true);
        }
        for (uint256 i = 0; i < battle.player2.pokemon.length; i++) {
            pokemonCardNFT.setCardActiveStatus(battle.player2.pokemon[i].tokenId, true);
        }
        
        // Clear active battle for both players
        playerActiveBattles[battle.player1.player] = 0;
        playerActiveBattles[battle.player2.player] = 0;
        
        // Distribute rewards
        if (winner != address(0)) {
            uint256 totalReward = battleReward * 2;
            (bool success, ) = payable(winner).call{value: totalReward}("");
            require(success, "Reward transfer failed");
        }
        
        emit BattleFinished(battleId, winner);
    }
    
    /**
     * @dev Cancel a battle (only if waiting for opponent)
     * @param battleId The battle ID
     */
    function cancelBattle(uint256 battleId) external whenNotPaused nonReentrant {
        PokemonTypes.Battle storage battle = battles[battleId];
        require(battle.status == PokemonTypes.BattleStatus.WAITING, "Battle not cancellable");
        require(battle.player1.player == msg.sender || battle.player2.player == msg.sender, "Not battle participant");
        
        battle.status = PokemonTypes.BattleStatus.CANCELLED;
        
        // Clear active battle
        playerActiveBattles[battle.player1.player] = 0;
        if (battle.player2.player != address(0)) {
            playerActiveBattles[battle.player2.player] = 0;
        }
        
        // Refund battle fee
        (bool success, ) = payable(msg.sender).call{value: battleReward}("");
        require(success, "Refund failed");
        
        emit BattleCancelled(battleId);
    }
    
    /**
     * @dev Get battle data
     * @param battleId The battle ID
     * @return The battle data
     */
    function getBattle(uint256 battleId) external view returns (PokemonTypes.Battle memory) {
        return battles[battleId];
    }
    
    /**
     * @dev Get player's active battle
     * @param player The player address
     * @return The active battle ID (0 if none)
     */
    function getPlayerActiveBattle(address player) external view returns (uint256) {
        return playerActiveBattles[player];
    }
    
    /**
     * @dev Set battle configuration
     * @param _maxBattleDuration New max battle duration
     * @param _battleReward New battle reward
     * @param _energyPerTurn New energy per turn
     * @param _maxEnergy New max energy
     */
    function setBattleConfig(
        uint256 _maxBattleDuration,
        uint256 _battleReward,
        uint256 _energyPerTurn,
        uint256 _maxEnergy
    ) external onlyOwner {
        maxBattleDuration = _maxBattleDuration;
        battleReward = _battleReward;
        energyPerTurn = _energyPerTurn;
        maxEnergy = _maxEnergy;
    }
    
    /**
     * @dev Pause contract
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Withdraw contract balance
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }
}
