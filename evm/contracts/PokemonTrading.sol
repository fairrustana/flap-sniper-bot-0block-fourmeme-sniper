// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./PokemonCardNFT.sol";
import "../shared/types/PokemonTypes.sol";

/**
 * @title PokemonTrading
 * @dev Contract for managing Pokemon card trading
 */
contract PokemonTrading is Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    
    Counters.Counter private _offerIdCounter;
    
    PokemonCardNFT public pokemonCardNFT;
    
    // Mapping from offer ID to trading offer
    mapping(uint256 => PokemonTypes.TradingOffer) public tradingOffers;
    
    // Mapping from player to their active offers
    mapping(address => uint256[]) public playerOffers;
    
    // Trading configuration
    uint256 public offerExpirationTime = 7 days;
    uint256 public tradingFee = 0.001 ether;
    
    // Events
    event TradingOfferCreated(
        uint256 indexed offerId,
        address indexed offerer,
        uint256[] offeredCards,
        address indexed targetPlayer,
        uint256[] requestedCards
    );
    
    event TradingOfferAccepted(
        uint256 indexed offerId,
        address indexed accepter
    );
    
    event TradingOfferCancelled(
        uint256 indexed offerId,
        address indexed offerer
    );
    
    event TradingOfferExpired(
        uint256 indexed offerId
    );
    
    constructor(address _pokemonCardNFT) {
        pokemonCardNFT = PokemonCardNFT(_pokemonCardNFT);
    }
    
    /**
     * @dev Create a trading offer
     * @param offeredCards Array of token IDs to offer
     * @param targetPlayer The target player address (address(0) for public offer)
     * @param requestedCards Array of token IDs requested
     */
    function createTradingOffer(
        uint256[] memory offeredCards,
        address targetPlayer,
        uint256[] memory requestedCards
    ) external payable whenNotPaused nonReentrant {
        require(msg.value >= tradingFee, "Insufficient trading fee");
        require(offeredCards.length > 0, "Must offer at least one card");
        require(requestedCards.length > 0, "Must request at least one card");
        
        // Validate offered cards ownership and active status
        for (uint256 i = 0; i < offeredCards.length; i++) {
            require(pokemonCardNFT.ownerOf(offeredCards[i]) == msg.sender, "Not owner of offered card");
            require(pokemonCardNFT.isCardActive(offeredCards[i]), "Offered card not active");
        }
        
        // Validate requested cards (if target player specified)
        if (targetPlayer != address(0)) {
            for (uint256 i = 0; i < requestedCards.length; i++) {
                require(pokemonCardNFT.ownerOf(requestedCards[i]) == targetPlayer, "Target player doesn't own requested card");
                require(pokemonCardNFT.isCardActive(requestedCards[i]), "Requested card not active");
            }
        }
        
        uint256 offerId = _offerIdCounter.current();
        _offerIdCounter.increment();
        
        // Create trading offer
        PokemonTypes.TradingOffer storage offer = tradingOffers[offerId];
        offer.offerId = offerId;
        offer.offerer = msg.sender;
        offer.offeredCards = offeredCards;
        offer.targetPlayer = targetPlayer;
        offer.requestedCards = requestedCards;
        offer.isActive = true;
        offer.createdAt = block.timestamp;
        offer.expiresAt = block.timestamp + offerExpirationTime;
        
        // Add to player's offers
        playerOffers[msg.sender].push(offerId);
        
        emit TradingOfferCreated(offerId, msg.sender, offeredCards, targetPlayer, requestedCards);
    }
    
    /**
     * @dev Accept a trading offer
     * @param offerId The offer ID to accept
     */
    function acceptTradingOffer(uint256 offerId) external payable whenNotPaused nonReentrant {
        require(msg.value >= tradingFee, "Insufficient trading fee");
        
        PokemonTypes.TradingOffer storage offer = tradingOffers[offerId];
        require(offer.isActive, "Offer not active");
        require(block.timestamp <= offer.expiresAt, "Offer expired");
        require(offer.offerer != msg.sender, "Cannot accept own offer");
        
        // Check if offer is targeted to this player or is public
        require(
            offer.targetPlayer == address(0) || offer.targetPlayer == msg.sender,
            "Offer not targeted to you"
        );
        
        // Validate requested cards ownership and active status
        for (uint256 i = 0; i < offer.requestedCards.length; i++) {
            require(pokemonCardNFT.ownerOf(offer.requestedCards[i]) == msg.sender, "Not owner of requested card");
            require(pokemonCardNFT.isCardActive(offer.requestedCards[i]), "Requested card not active");
        }
        
        // Validate offered cards are still owned by offerer and active
        for (uint256 i = 0; i < offer.offeredCards.length; i++) {
            require(pokemonCardNFT.ownerOf(offer.offeredCards[i]) == offer.offerer, "Offerer no longer owns offered card");
            require(pokemonCardNFT.isCardActive(offer.offeredCards[i]), "Offered card not active");
        }
        
        // Execute the trade
        _executeTrade(offer);
        
        // Mark offer as inactive
        offer.isActive = false;
        
        emit TradingOfferAccepted(offerId, msg.sender);
    }
    
    /**
     * @dev Execute the trade (internal)
     * @param offer The trading offer
     */
    function _executeTrade(PokemonTypes.TradingOffer storage offer) internal {
        // Transfer offered cards from offerer to accepter
        for (uint256 i = 0; i < offer.offeredCards.length; i++) {
            pokemonCardNFT.transferFrom(offer.offerer, msg.sender, offer.offeredCards[i]);
        }
        
        // Transfer requested cards from accepter to offerer
        for (uint256 i = 0; i < offer.requestedCards.length; i++) {
            pokemonCardNFT.transferFrom(msg.sender, offer.offerer, offer.requestedCards[i]);
        }
    }
    
    /**
     * @dev Cancel a trading offer
     * @param offerId The offer ID to cancel
     */
    function cancelTradingOffer(uint256 offerId) external whenNotPaused nonReentrant {
        PokemonTypes.TradingOffer storage offer = tradingOffers[offerId];
        require(offer.isActive, "Offer not active");
        require(offer.offerer == msg.sender, "Not offer owner");
        
        offer.isActive = false;
        
        // Remove from player's offers
        uint256[] storage offers = playerOffers[msg.sender];
        for (uint256 i = 0; i < offers.length; i++) {
            if (offers[i] == offerId) {
                offers[i] = offers[offers.length - 1];
                offers.pop();
                break;
            }
        }
        
        // Refund trading fee
        (bool success, ) = payable(msg.sender).call{value: tradingFee}("");
        require(success, "Refund failed");
        
        emit TradingOfferCancelled(offerId, msg.sender);
    }
    
    /**
     * @dev Get trading offer details
     * @param offerId The offer ID
     * @return The trading offer data
     */
    function getTradingOffer(uint256 offerId) external view returns (PokemonTypes.TradingOffer memory) {
        return tradingOffers[offerId];
    }
    
    /**
     * @dev Get player's active offers
     * @param player The player address
     * @return Array of offer IDs
     */
    function getPlayerOffers(address player) external view returns (uint256[] memory) {
        return playerOffers[player];
    }
    
    /**
     * @dev Get player's active offers with full data
     * @param player The player address
     * @return Array of trading offer data
     */
    function getPlayerTradingOffers(address player) external view returns (PokemonTypes.TradingOffer[] memory) {
        uint256[] memory offerIds = playerOffers[player];
        PokemonTypes.TradingOffer[] memory offers = new PokemonTypes.TradingOffer[](offerIds.length);
        
        for (uint256 i = 0; i < offerIds.length; i++) {
            offers[i] = tradingOffers[offerIds[i]];
        }
        
        return offers;
    }
    
    /**
     * @dev Get all active public trading offers
     * @return Array of active public offer IDs
     */
    function getPublicTradingOffers() external view returns (uint256[] memory) {
        uint256 totalOffers = _offerIdCounter.current();
        uint256[] memory publicOffers = new uint256[](totalOffers);
        uint256 count = 0;
        
        for (uint256 i = 0; i < totalOffers; i++) {
            PokemonTypes.TradingOffer storage offer = tradingOffers[i];
            if (offer.isActive && 
                offer.targetPlayer == address(0) && 
                block.timestamp <= offer.expiresAt) {
                publicOffers[count] = i;
                count++;
            }
        }
        
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = publicOffers[i];
        }
        
        return result;
    }
    
    /**
     * @dev Get trading offers targeted to a specific player
     * @param targetPlayer The target player address
     * @return Array of targeted offer IDs
     */
    function getTargetedTradingOffers(address targetPlayer) external view returns (uint256[] memory) {
        uint256 totalOffers = _offerIdCounter.current();
        uint256[] memory targetedOffers = new uint256[](totalOffers);
        uint256 count = 0;
        
        for (uint256 i = 0; i < totalOffers; i++) {
            PokemonTypes.TradingOffer storage offer = tradingOffers[i];
            if (offer.isActive && 
                offer.targetPlayer == targetPlayer && 
                block.timestamp <= offer.expiresAt) {
                targetedOffers[count] = i;
                count++;
            }
        }
        
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = targetedOffers[i];
        }
        
        return result;
    }
    
    /**
     * @dev Clean up expired offers (can be called by anyone)
     * @param offerIds Array of offer IDs to check and clean up
     */
    function cleanupExpiredOffers(uint256[] memory offerIds) external {
        for (uint256 i = 0; i < offerIds.length; i++) {
            PokemonTypes.TradingOffer storage offer = tradingOffers[offerIds[i]];
            if (offer.isActive && block.timestamp > offer.expiresAt) {
                offer.isActive = false;
                
                // Remove from player's offers
                uint256[] storage offers = playerOffers[offer.offerer];
                for (uint256 j = 0; j < offers.length; j++) {
                    if (offers[j] == offerIds[i]) {
                        offers[j] = offers[offers.length - 1];
                        offers.pop();
                        break;
                    }
                }
                
                emit TradingOfferExpired(offerIds[i]);
            }
        }
    }
    
    /**
     * @dev Set trading configuration
     * @param _offerExpirationTime New offer expiration time
     * @param _tradingFee New trading fee
     */
    function setTradingConfig(
        uint256 _offerExpirationTime,
        uint256 _tradingFee
    ) external onlyOwner {
        offerExpirationTime = _offerExpirationTime;
        tradingFee = _tradingFee;
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
