// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../shared/types/PokemonTypes.sol";

/**
 * @title PokemonCardNFT
 * @dev ERC721 NFT contract for Pokemon Cards
 */
contract PokemonCardNFT is ERC721, ERC721URIStorage, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIdCounter;
    
    // Mapping from token ID to Pokemon card data
    mapping(uint256 => PokemonTypes.PokemonCard) public pokemonCards;
    
    // Mapping from player to their card collection
    mapping(address => uint256[]) public playerCollections;
    
    // Mapping from player to number of cards owned
    mapping(address => uint256) public playerCardCount;
    
    // Base URI for metadata
    string private _baseTokenURI;
    
    // Maximum cards per player
    uint256 public maxCardsPerPlayer = 1000;
    
    // Minting price
    uint256 public mintPrice = 0.01 ether;
    
    // Events
    event PokemonCardMinted(
        uint256 indexed tokenId,
        address indexed owner,
        string name,
        PokemonTypes.PokemonType pokemonType,
        PokemonTypes.Rarity rarity
    );
    
    event PokemonCardTransferred(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to
    );
    
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }
    
    /**
     * @dev Mint a new Pokemon card
     * @param cardData The Pokemon card data structure
     */
    function mintPokemonCard(
        PokemonTypes.PokemonCard memory cardData
    ) external payable whenNotPaused nonReentrant {
        require(msg.value >= mintPrice, "Insufficient payment");
        require(playerCardCount[msg.sender] < maxCardsPerPlayer, "Max cards per player exceeded");
        
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        // Set token ID in card data
        cardData.tokenId = tokenId;
        cardData.isActive = true;
        
        // Store card data
        pokemonCards[tokenId] = cardData;
        
        // Update player collection
        playerCollections[msg.sender].push(tokenId);
        playerCardCount[msg.sender]++;
        
        // Mint NFT
        _safeMint(msg.sender, tokenId);
        
        emit PokemonCardMinted(
            tokenId,
            msg.sender,
            cardData.name,
            cardData.pokemonType,
            cardData.rarity
        );
    }
    
    /**
     * @dev Get Pokemon card data by token ID
     * @param tokenId The token ID
     * @return The Pokemon card data
     */
    function getPokemonCard(uint256 tokenId) external view returns (PokemonTypes.PokemonCard memory) {
        require(_exists(tokenId), "Token does not exist");
        return pokemonCards[tokenId];
    }
    
    /**
     * @dev Get player's card collection
     * @param player The player address
     * @return Array of token IDs owned by the player
     */
    function getPlayerCollection(address player) external view returns (uint256[] memory) {
        return playerCollections[player];
    }
    
    /**
     * @dev Get player's Pokemon cards with full data
     * @param player The player address
     * @return Array of Pokemon card data
     */
    function getPlayerPokemonCards(address player) external view returns (PokemonTypes.PokemonCard[] memory) {
        uint256[] memory tokenIds = playerCollections[player];
        PokemonTypes.PokemonCard[] memory cards = new PokemonTypes.PokemonCard[](tokenIds.length);
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            cards[i] = pokemonCards[tokenIds[i]];
        }
        
        return cards;
    }
    
    /**
     * @dev Check if a card is active (not in battle)
     * @param tokenId The token ID
     * @return True if the card is active
     */
    function isCardActive(uint256 tokenId) external view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        return pokemonCards[tokenId].isActive;
    }
    
    /**
     * @dev Set card active status (only callable by game contract)
     * @param tokenId The token ID
     * @param active The active status
     */
    function setCardActiveStatus(uint256 tokenId, bool active) external onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        pokemonCards[tokenId].isActive = active;
    }
    
    /**
     * @dev Override transfer to update collections
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        
        if (from != address(0) && to != address(0)) {
            // Remove from sender's collection
            uint256[] storage senderCollection = playerCollections[from];
            for (uint256 i = 0; i < senderCollection.length; i++) {
                if (senderCollection[i] == tokenId) {
                    senderCollection[i] = senderCollection[senderCollection.length - 1];
                    senderCollection.pop();
                    break;
                }
            }
            playerCardCount[from]--;
            
            // Add to receiver's collection
            playerCollections[to].push(tokenId);
            playerCardCount[to]++;
            
            emit PokemonCardTransferred(tokenId, from, to);
        }
    }
    
    /**
     * @dev Set base URI for metadata
     * @param baseURI The new base URI
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    /**
     * @dev Set minting price
     * @param newPrice The new minting price
     */
    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }
    
    /**
     * @dev Set maximum cards per player
     * @param newMax The new maximum
     */
    function setMaxCardsPerPlayer(uint256 newMax) external onlyOwner {
        maxCardsPerPlayer = newMax;
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
    
    /**
     * @dev Override tokenURI to return metadata
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : "";
    }
    
    /**
     * @dev Override _baseURI
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    /**
     * @dev Override _burn
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    /**
     * @dev Convert uint256 to string
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
