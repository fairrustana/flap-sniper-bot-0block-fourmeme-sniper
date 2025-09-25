use anchor_lang::prelude::*;

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[program]
pub mod pokemon_card_game {
    use super::*;

    /// Initialize the Pokemon Card Game program
    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        let game_state = &mut ctx.accounts.game_state;
        game_state.authority = ctx.accounts.authority.key();
        game_state.total_cards_minted = 0;
        game_state.total_battles = 0;
        game_state.total_trades = 0;
        game_state.mint_price = 1000000; // 0.001 SOL in lamports
        game_state.battle_reward = 500000; // 0.0005 SOL in lamports
        game_state.trading_fee = 100000; // 0.0001 SOL in lamports
        game_state.max_cards_per_player = 1000;
        game_state.max_battle_duration = 3600; // 1 hour in seconds
        game_state.max_energy = 100;
        game_state.energy_per_turn = 10;
        game_state.offer_expiration_time = 604800; // 7 days in seconds
        
        msg!("Pokemon Card Game initialized");
        Ok(())
    }

    /// Mint a new Pokemon card
    pub fn mint_pokemon_card(
        ctx: Context<MintPokemonCard>,
        card_data: PokemonCardData,
    ) -> Result<()> {
        let game_state = &mut ctx.accounts.game_state;
        let player_state = &mut ctx.accounts.player_state;
        let pokemon_card = &mut ctx.accounts.pokemon_card;

        // Check payment
        require!(
            ctx.accounts.payment.amount >= game_state.mint_price,
            ErrorCode::InsufficientPayment
        );

        // Check max cards per player
        require!(
            player_state.card_count < game_state.max_cards_per_player,
            ErrorCode::MaxCardsExceeded
        );

        // Set card data
        pokemon_card.token_id = game_state.total_cards_minted;
        pokemon_card.owner = ctx.accounts.player.key();
        pokemon_card.name = card_data.name;
        pokemon_card.pokemon_type = card_data.pokemon_type;
        pokemon_card.hp = card_data.hp;
        pokemon_card.attack = card_data.attack;
        pokemon_card.defense = card_data.defense;
        pokemon_card.speed = card_data.speed;
        pokemon_card.rarity = card_data.rarity;
        pokemon_card.evolution_stage = card_data.evolution_stage;
        pokemon_card.evolution_cost = card_data.evolution_cost;
        pokemon_card.moves = card_data.moves;
        pokemon_card.image_uri = card_data.image_uri;
        pokemon_card.description = card_data.description;
        pokemon_card.is_active = true;
        pokemon_card.minted_at = Clock::get()?.unix_timestamp;

        // Update counters
        game_state.total_cards_minted += 1;
        player_state.card_count += 1;

        emit!(PokemonCardMinted {
            token_id: pokemon_card.token_id,
            owner: pokemon_card.owner,
            name: pokemon_card.name.clone(),
            pokemon_type: pokemon_card.pokemon_type,
            rarity: pokemon_card.rarity,
        });

        Ok(())
    }

    /// Create a new battle
    pub fn create_battle(
        ctx: Context<CreateBattle>,
        pokemon_token_ids: Vec<u64>,
    ) -> Result<()> {
        let game_state = &mut ctx.accounts.game_state;
        let battle = &mut ctx.accounts.battle;
        let player_state = &mut ctx.accounts.player_state;

        // Check payment
        require!(
            ctx.accounts.payment.amount >= game_state.battle_reward,
            ErrorCode::InsufficientPayment
        );

        // Check player is not already in a battle
        require!(
            player_state.active_battle_id == 0,
            ErrorCode::PlayerAlreadyInBattle
        );

        // Validate team size
        require!(
            pokemon_token_ids.len() > 0 && pokemon_token_ids.len() <= 6,
            ErrorCode::InvalidTeamSize
        );

        // Initialize battle
        battle.battle_id = game_state.total_battles;
        battle.player1 = ctx.accounts.player.key();
        battle.player2 = Pubkey::default();
        battle.player1_pokemon = pokemon_token_ids;
        battle.player2_pokemon = Vec::new();
        battle.status = BattleStatus::Waiting;
        battle.turn_number = 0;
        battle.current_player = ctx.accounts.player.key();
        battle.created_at = Clock::get()?.unix_timestamp;
        battle.finished_at = 0;

        // Update player state
        player_state.active_battle_id = battle.battle_id;

        // Update game state
        game_state.total_battles += 1;

        emit!(BattleCreated {
            battle_id: battle.battle_id,
            player1: battle.player1,
            player2: battle.player2,
        });

        Ok(())
    }

    /// Join an existing battle
    pub fn join_battle(
        ctx: Context<JoinBattle>,
        pokemon_token_ids: Vec<u64>,
    ) -> Result<()> {
        let battle = &mut ctx.accounts.battle;
        let player_state = &mut ctx.accounts.player_state;

        // Check battle is waiting for opponent
        require!(
            battle.status == BattleStatus::Waiting,
            ErrorCode::BattleNotAvailable
        );

        // Check player is not already in a battle
        require!(
            player_state.active_battle_id == 0,
            ErrorCode::PlayerAlreadyInBattle
        );

        // Validate team size
        require!(
            pokemon_token_ids.len() > 0 && pokemon_token_ids.len() <= 6,
            ErrorCode::InvalidTeamSize
        );

        // Set player2 data
        battle.player2 = ctx.accounts.player.key();
        battle.player2_pokemon = pokemon_token_ids;
        battle.status = BattleStatus::Active;

        // Update player state
        player_state.active_battle_id = battle.battle_id;

        emit!(BattleJoined {
            battle_id: battle.battle_id,
            player: battle.player2,
        });

        emit!(BattleStarted {
            battle_id: battle.battle_id,
        });

        Ok(())
    }

    /// Execute a move in battle
    pub fn execute_move(
        ctx: Context<ExecuteMove>,
        move_index: u8,
        target_pokemon_index: u8,
    ) -> Result<()> {
        let battle = &mut ctx.accounts.battle;
        let player_state = &mut ctx.accounts.player_state;

        // Check battle is active
        require!(
            battle.status == BattleStatus::Active,
            ErrorCode::BattleNotActive
        );

        // Check it's player's turn
        require!(
            battle.current_player == ctx.accounts.player.key(),
            ErrorCode::NotYourTurn
        );

        // Check battle hasn't timed out
        let current_time = Clock::get()?.unix_timestamp;
        require!(
            current_time <= battle.created_at + ctx.accounts.game_state.max_battle_duration,
            ErrorCode::BattleTimeout
        );

        // Get current Pokemon (simplified - in real implementation, you'd need to fetch Pokemon data)
        let current_pokemon = &ctx.accounts.current_pokemon;
        let target_pokemon = &ctx.accounts.target_pokemon;

        // Validate move index
        require!(
            move_index < current_pokemon.moves.len() as u8,
            ErrorCode::InvalidMove
        );

        let move_data = &current_pokemon.moves[move_index as usize];

        // Check energy
        require!(
            player_state.energy >= move_data.energy_cost,
            ErrorCode::InsufficientEnergy
        );

        // Execute move
        player_state.energy -= move_data.energy_cost;

        let damage = calculate_damage(current_pokemon, target_pokemon, move_data);
        
        emit!(MoveExecuted {
            battle_id: battle.battle_id,
            player: ctx.accounts.player.key(),
            move_name: move_data.name.clone(),
            damage,
        });

        // Check if battle is over (simplified)
        if damage >= target_pokemon.hp {
            battle.status = BattleStatus::Finished;
            battle.finished_at = current_time;
            
            emit!(BattleFinished {
                battle_id: battle.battle_id,
                winner: ctx.accounts.player.key(),
            });
        } else {
            // Switch turns
            battle.current_player = if battle.current_player == battle.player1 {
                battle.player2
            } else {
                battle.player1
            };
            battle.turn_number += 1;
        }

        Ok(())
    }

    /// Create a trading offer
    pub fn create_trading_offer(
        ctx: Context<CreateTradingOffer>,
        offered_cards: Vec<u64>,
        requested_cards: Vec<u64>,
        target_player: Option<Pubkey>,
    ) -> Result<()> {
        let game_state = &mut ctx.accounts.game_state;
        let trading_offer = &mut ctx.accounts.trading_offer;

        // Check payment
        require!(
            ctx.accounts.payment.amount >= game_state.trading_fee,
            ErrorCode::InsufficientPayment
        );

        // Validate offer
        require!(
            offered_cards.len() > 0 && requested_cards.len() > 0,
            ErrorCode::InvalidTradingOffer
        );

        // Initialize trading offer
        trading_offer.offer_id = game_state.total_trades;
        trading_offer.offerer = ctx.accounts.player.key();
        trading_offer.offered_cards = offered_cards;
        trading_offer.target_player = target_player;
        trading_offer.requested_cards = requested_cards;
        trading_offer.is_active = true;
        trading_offer.created_at = Clock::get()?.unix_timestamp;
        trading_offer.expires_at = Clock::get()?.unix_timestamp + game_state.offer_expiration_time;

        // Update game state
        game_state.total_trades += 1;

        emit!(TradingOfferCreated {
            offer_id: trading_offer.offer_id,
            offerer: trading_offer.offerer,
            target_player: trading_offer.target_player,
        });

        Ok(())
    }

    /// Accept a trading offer
    pub fn accept_trading_offer(ctx: Context<AcceptTradingOffer>) -> Result<()> {
        let trading_offer = &mut ctx.accounts.trading_offer;
        let game_state = &ctx.accounts.game_state;

        // Check offer is active
        require!(
            trading_offer.is_active,
            ErrorCode::OfferNotActive
        );

        // Check offer hasn't expired
        let current_time = Clock::get()?.unix_timestamp;
        require!(
            current_time <= trading_offer.expires_at,
            ErrorCode::OfferExpired
        );

        // Check payment
        require!(
            ctx.accounts.payment.amount >= game_state.trading_fee,
            ErrorCode::InsufficientPayment
        );

        // Check if offer is targeted to this player or is public
        require!(
            trading_offer.target_player.is_none() || 
            trading_offer.target_player.unwrap() == ctx.accounts.player.key(),
            ErrorCode::OfferNotTargetedToYou
        );

        // Execute trade (simplified - in real implementation, you'd transfer NFT ownership)
        trading_offer.is_active = false;

        emit!(TradingOfferAccepted {
            offer_id: trading_offer.offer_id,
            accepter: ctx.accounts.player.key(),
        });

        Ok(())
    }
}

// Helper function to calculate damage
fn calculate_damage(
    attacker: &PokemonCard,
    defender: &PokemonCard,
    move_data: &PokemonMove,
) -> u64 {
    // Simple damage calculation
    let base_damage = move_data.power;
    let attack_stat = attacker.attack;
    let defense_stat = defender.defense;
    
    let damage = (base_damage * attack_stat) / (defense_stat + 50);
    if damage > 0 { damage } else { 1 }
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(
        init,
        payer = authority,
        space = 8 + GameState::INIT_SPACE,
        seeds = [b"game_state"],
        bump
    )]
    pub game_state: Account<'info, GameState>,
    
    #[account(mut)]
    pub authority: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct MintPokemonCard<'info> {
    #[account(
        mut,
        seeds = [b"game_state"],
        bump
    )]
    pub game_state: Account<'info, GameState>,
    
    #[account(
        init,
        payer = player,
        space = 8 + PokemonCard::INIT_SPACE,
        seeds = [b"pokemon_card", game_state.total_cards_minted.to_le_bytes().as_ref()],
        bump
    )]
    pub pokemon_card: Account<'info, PokemonCard>,
    
    #[account(
        init_if_needed,
        payer = player,
        space = 8 + PlayerState::INIT_SPACE,
        seeds = [b"player_state", player.key().as_ref()],
        bump
    )]
    pub player_state: Account<'info, PlayerState>,
    
    #[account(mut)]
    pub player: Signer<'info>,
    
    #[account(mut)]
    pub payment: Account<'info, anchor_spl::token::TokenAccount>,
    
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct CreateBattle<'info> {
    #[account(
        mut,
        seeds = [b"game_state"],
        bump
    )]
    pub game_state: Account<'info, GameState>,
    
    #[account(
        init,
        payer = player,
        space = 8 + Battle::INIT_SPACE,
        seeds = [b"battle", game_state.total_battles.to_le_bytes().as_ref()],
        bump
    )]
    pub battle: Account<'info, Battle>,
    
    #[account(
        mut,
        seeds = [b"player_state", player.key().as_ref()],
        bump
    )]
    pub player_state: Account<'info, PlayerState>,
    
    #[account(mut)]
    pub player: Signer<'info>,
    
    #[account(mut)]
    pub payment: Account<'info, anchor_spl::token::TokenAccount>,
    
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct JoinBattle<'info> {
    #[account(
        mut,
        seeds = [b"battle", battle.battle_id.to_le_bytes().as_ref()],
        bump
    )]
    pub battle: Account<'info, Battle>,
    
    #[account(
        mut,
        seeds = [b"player_state", player.key().as_ref()],
        bump
    )]
    pub player_state: Account<'info, PlayerState>,
    
    #[account(mut)]
    pub player: Signer<'info>,
    
    #[account(mut)]
    pub payment: Account<'info, anchor_spl::token::TokenAccount>,
    
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct ExecuteMove<'info> {
    #[account(
        mut,
        seeds = [b"battle", battle.battle_id.to_le_bytes().as_ref()],
        bump
    )]
    pub battle: Account<'info, Battle>,
    
    #[account(
        seeds = [b"game_state"],
        bump
    )]
    pub game_state: Account<'info, GameState>,
    
    #[account(
        mut,
        seeds = [b"player_state", player.key().as_ref()],
        bump
    )]
    pub player_state: Account<'info, PlayerState>,
    
    #[account(
        seeds = [b"pokemon_card", current_pokemon.token_id.to_le_bytes().as_ref()],
        bump
    )]
    pub current_pokemon: Account<'info, PokemonCard>,
    
    #[account(
        seeds = [b"pokemon_card", target_pokemon.token_id.to_le_bytes().as_ref()],
        bump
    )]
    pub target_pokemon: Account<'info, PokemonCard>,
    
    #[account(mut)]
    pub player: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct CreateTradingOffer<'info> {
    #[account(
        mut,
        seeds = [b"game_state"],
        bump
    )]
    pub game_state: Account<'info, GameState>,
    
    #[account(
        init,
        payer = player,
        space = 8 + TradingOffer::INIT_SPACE,
        seeds = [b"trading_offer", game_state.total_trades.to_le_bytes().as_ref()],
        bump
    )]
    pub trading_offer: Account<'info, TradingOffer>,
    
    #[account(mut)]
    pub player: Signer<'info>,
    
    #[account(mut)]
    pub payment: Account<'info, anchor_spl::token::TokenAccount>,
    
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct AcceptTradingOffer<'info> {
    #[account(
        mut,
        seeds = [b"trading_offer", trading_offer.offer_id.to_le_bytes().as_ref()],
        bump
    )]
    pub trading_offer: Account<'info, TradingOffer>,
    
    #[account(
        seeds = [b"game_state"],
        bump
    )]
    pub game_state: Account<'info, GameState>,
    
    #[account(mut)]
    pub player: Signer<'info>,
    
    #[account(mut)]
    pub payment: Account<'info, anchor_spl::token::TokenAccount>,
    
    pub system_program: Program<'info, System>,
}

// Account structures
#[account]
pub struct GameState {
    pub authority: Pubkey,
    pub total_cards_minted: u64,
    pub total_battles: u64,
    pub total_trades: u64,
    pub mint_price: u64,
    pub battle_reward: u64,
    pub trading_fee: u64,
    pub max_cards_per_player: u64,
    pub max_battle_duration: u64,
    pub max_energy: u64,
    pub energy_per_turn: u64,
    pub offer_expiration_time: u64,
}

impl GameState {
    pub const INIT_SPACE: usize = 32 + 8 + 8 + 8 + 8 + 8 + 8 + 8 + 8 + 8 + 8 + 8;
}

#[account]
pub struct PokemonCard {
    pub token_id: u64,
    pub owner: Pubkey,
    pub name: String,
    pub pokemon_type: u8,
    pub hp: u64,
    pub attack: u64,
    pub defense: u64,
    pub speed: u64,
    pub rarity: u8,
    pub evolution_stage: u8,
    pub evolution_cost: u64,
    pub moves: Vec<PokemonMove>,
    pub image_uri: String,
    pub description: String,
    pub is_active: bool,
    pub minted_at: i64,
}

impl PokemonCard {
    pub const INIT_SPACE: usize = 8 + 8 + 32 + 4 + 32 + 1 + 8 + 8 + 8 + 8 + 1 + 1 + 8 + 4 + 8 + 4 + 32 + 4 + 32 + 1 + 8;
}

#[account]
pub struct PlayerState {
    pub player: Pubkey,
    pub card_count: u64,
    pub active_battle_id: u64,
    pub energy: u64,
    pub wins: u64,
    pub losses: u64,
}

impl PlayerState {
    pub const INIT_SPACE: usize = 32 + 8 + 8 + 8 + 8 + 8;
}

#[account]
pub struct Battle {
    pub battle_id: u64,
    pub player1: Pubkey,
    pub player2: Pubkey,
    pub player1_pokemon: Vec<u64>,
    pub player2_pokemon: Vec<u64>,
    pub status: BattleStatus,
    pub turn_number: u64,
    pub current_player: Pubkey,
    pub created_at: i64,
    pub finished_at: i64,
}

impl Battle {
    pub const INIT_SPACE: usize = 8 + 32 + 32 + 4 + 8 + 4 + 8 + 4 + 8 + 32 + 8 + 8 + 1 + 8;
}

#[account]
pub struct TradingOffer {
    pub offer_id: u64,
    pub offerer: Pubkey,
    pub offered_cards: Vec<u64>,
    pub target_player: Option<Pubkey>,
    pub requested_cards: Vec<u64>,
    pub is_active: bool,
    pub created_at: i64,
    pub expires_at: i64,
}

impl TradingOffer {
    pub const INIT_SPACE: usize = 8 + 8 + 32 + 4 + 8 + 1 + 32 + 4 + 8 + 1 + 8 + 8;
}

// Data structures
#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct PokemonCardData {
    pub name: String,
    pub pokemon_type: u8,
    pub hp: u64,
    pub attack: u64,
    pub defense: u64,
    pub speed: u64,
    pub rarity: u8,
    pub evolution_stage: u8,
    pub evolution_cost: u64,
    pub moves: Vec<PokemonMove>,
    pub image_uri: String,
    pub description: String,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct PokemonMove {
    pub name: String,
    pub pokemon_type: u8,
    pub move_type: u8, // 0: Physical, 1: Special, 2: Status
    pub power: u64,
    pub accuracy: u64,
    pub energy_cost: u64,
    pub description: String,
}

// Enums
#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq)]
pub enum BattleStatus {
    Waiting,
    Active,
    Finished,
    Cancelled,
}

// Events
#[event]
pub struct PokemonCardMinted {
    pub token_id: u64,
    pub owner: Pubkey,
    pub name: String,
    pub pokemon_type: u8,
    pub rarity: u8,
}

#[event]
pub struct BattleCreated {
    pub battle_id: u64,
    pub player1: Pubkey,
    pub player2: Pubkey,
}

#[event]
pub struct BattleJoined {
    pub battle_id: u64,
    pub player: Pubkey,
}

#[event]
pub struct BattleStarted {
    pub battle_id: u64,
}

#[event]
pub struct BattleFinished {
    pub battle_id: u64,
    pub winner: Pubkey,
}

#[event]
pub struct MoveExecuted {
    pub battle_id: u64,
    pub player: Pubkey,
    pub move_name: String,
    pub damage: u64,
}

#[event]
pub struct TradingOfferCreated {
    pub offer_id: u64,
    pub offerer: Pubkey,
    pub target_player: Option<Pubkey>,
}

#[event]
pub struct TradingOfferAccepted {
    pub offer_id: u64,
    pub accepter: Pubkey,
}

// Error codes
#[error_code]
pub enum ErrorCode {
    #[msg("Insufficient payment")]
    InsufficientPayment,
    #[msg("Max cards per player exceeded")]
    MaxCardsExceeded,
    #[msg("Player already in active battle")]
    PlayerAlreadyInBattle,
    #[msg("Invalid team size")]
    InvalidTeamSize,
    #[msg("Battle not available")]
    BattleNotAvailable,
    #[msg("Battle not active")]
    BattleNotActive,
    #[msg("Not your turn")]
    NotYourTurn,
    #[msg("Battle timeout")]
    BattleTimeout,
    #[msg("Invalid move")]
    InvalidMove,
    #[msg("Insufficient energy")]
    InsufficientEnergy,
    #[msg("Invalid trading offer")]
    InvalidTradingOffer,
    #[msg("Offer not active")]
    OfferNotActive,
    #[msg("Offer expired")]
    OfferExpired,
    #[msg("Offer not targeted to you")]
    OfferNotTargetedToYou,
}
