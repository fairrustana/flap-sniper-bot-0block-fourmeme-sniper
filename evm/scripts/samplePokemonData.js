const { ethers } = require("hardhat");

// Sample Pokemon card data
const samplePokemonCards = [
  {
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
        description: "A weak electric attack that may paralyze the target."
      },
      {
        name: "Quick Attack",
        type: 0, // NORMAL
        moveType: 0, // PHYSICAL
        power: 30,
        accuracy: 100,
        energyCost: 15,
        description: "An extremely fast attack that always strikes first."
      }
    ],
    imageUri: "https://api.pokemoncardgame.com/images/pikachu.png",
    description: "A cute Electric-type Pokemon that stores electricity in its cheeks."
  },
  {
    name: "Charizard",
    pokemonType: 1, // FIRE
    hp: 120,
    attack: 84,
    defense: 78,
    speed: 100,
    rarity: 4, // LEGENDARY
    evolutionStage: 2, // STAGE 2
    evolutionCost: 50,
    moves: [
      {
        name: "Flamethrower",
        type: 1, // FIRE
        moveType: 1, // SPECIAL
        power: 90,
        accuracy: 100,
        energyCost: 30,
        description: "A powerful fire attack that may burn the target."
      },
      {
        name: "Dragon Claw",
        type: 14, // DRAGON
        moveType: 0, // PHYSICAL
        power: 80,
        accuracy: 100,
        energyCost: 25,
        description: "Sharp claws tear into the target with dragon power."
      },
      {
        name: "Wing Attack",
        type: 9, // FLYING
        moveType: 0, // PHYSICAL
        power: 60,
        accuracy: 100,
        energyCost: 20,
        description: "The target is struck with large, imposing wings."
      }
    ],
    imageUri: "https://api.pokemoncardgame.com/images/charizard.png",
    description: "A powerful Fire/Flying-type Pokemon that can breathe intense flames."
  },
  {
    name: "Blastoise",
    pokemonType: 2, // WATER
    hp: 120,
    attack: 83,
    defense: 100,
    speed: 78,
    rarity: 4, // LEGENDARY
    evolutionStage: 2, // STAGE 2
    evolutionCost: 50,
    moves: [
      {
        name: "Hydro Pump",
        type: 2, // WATER
        moveType: 1, // SPECIAL
        power: 110,
        accuracy: 80,
        energyCost: 35,
        description: "A powerful water attack that blasts the target."
      },
      {
        name: "Skull Bash",
        type: 0, // NORMAL
        moveType: 0, // PHYSICAL
        power: 100,
        accuracy: 100,
        energyCost: 30,
        description: "A powerful headbutt that raises defense."
      },
      {
        name: "Ice Beam",
        type: 5, // ICE
        moveType: 1, // SPECIAL
        power: 90,
        accuracy: 100,
        energyCost: 25,
        description: "A freezing beam that may freeze the target."
      }
    ],
    imageUri: "https://api.pokemoncardgame.com/images/blastoise.png",
    description: "A powerful Water-type Pokemon with massive water cannons on its shell."
  },
  {
    name: "Venusaur",
    pokemonType: 3, // GRASS
    hp: 120,
    attack: 82,
    defense: 83,
    speed: 80,
    rarity: 4, // LEGENDARY
    evolutionStage: 2, // STAGE 2
    evolutionCost: 50,
    moves: [
      {
        name: "Solar Beam",
        type: 3, // GRASS
        moveType: 1, // SPECIAL
        power: 120,
        accuracy: 100,
        energyCost: 40,
        description: "A powerful beam of solar energy that takes time to charge."
      },
      {
        name: "Earthquake",
        type: 8, // GROUND
        moveType: 0, // PHYSICAL
        power: 100,
        accuracy: 100,
        energyCost: 30,
        description: "A powerful ground attack that shakes the battlefield."
      },
      {
        name: "Sleep Powder",
        type: 3, // GRASS
        moveType: 2, // STATUS
        power: 0,
        accuracy: 75,
        energyCost: 20,
        description: "A powder that may put the target to sleep."
      }
    ],
    imageUri: "https://api.pokemoncardgame.com/images/venusaur.png",
    description: "A powerful Grass/Poison-type Pokemon with a large flower on its back."
  },
  {
    name: "Mewtwo",
    pokemonType: 10, // PSYCHIC
    hp: 130,
    attack: 110,
    defense: 90,
    speed: 130,
    rarity: 4, // LEGENDARY
    evolutionStage: 0, // BASIC
    evolutionCost: 0,
    moves: [
      {
        name: "Psychic",
        type: 10, // PSYCHIC
        moveType: 1, // SPECIAL
        power: 90,
        accuracy: 100,
        energyCost: 25,
        description: "A powerful psychic attack that may lower special defense."
      },
      {
        name: "Shadow Ball",
        type: 13, // GHOST
        moveType: 1, // SPECIAL
        power: 80,
        accuracy: 100,
        energyCost: 20,
        description: "A shadowy sphere that may lower special defense."
      },
      {
        name: "Recover",
        type: 10, // PSYCHIC
        moveType: 2, // STATUS
        power: 0,
        accuracy: 100,
        energyCost: 30,
        description: "Restores up to half of the user's maximum HP."
      }
    ],
    imageUri: "https://api.pokemoncardgame.com/images/mewtwo.png",
    description: "A legendary Psychic-type Pokemon created through genetic manipulation."
  }
];

// Function to create Pokemon card data for smart contract
function createPokemonCardData(pokemonData) {
  return {
    name: pokemonData.name,
    pokemonType: pokemonData.pokemonType,
    hp: pokemonData.hp,
    attack: pokemonData.attack,
    defense: pokemonData.defense,
    speed: pokemonData.speed,
    rarity: pokemonData.rarity,
    evolutionStage: pokemonData.evolutionStage,
    evolutionCost: pokemonData.evolutionCost,
    moves: pokemonData.moves,
    imageUri: pokemonData.imageUri,
    description: pokemonData.description
  };
}

// Function to mint sample Pokemon cards
async function mintSamplePokemonCards(pokemonCardNFT, owner) {
  console.log("Minting sample Pokemon cards...");
  
  for (const pokemonData of samplePokemonCards) {
    const cardData = createPokemonCardData(pokemonData);
    
    try {
      const tx = await pokemonCardNFT.mintPokemonCard(cardData, {
        value: ethers.utils.parseEther("0.01")
      });
      await tx.wait();
      console.log(`Minted ${pokemonData.name} card`);
    } catch (error) {
      console.error(`Failed to mint ${pokemonData.name}:`, error.message);
    }
  }
}

module.exports = {
  samplePokemonCards,
  createPokemonCardData,
  mintSamplePokemonCards
};
