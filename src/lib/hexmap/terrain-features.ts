import type { HexTile, MapConfig, TerrainFeature } from './types';

/**
 * Seeded random number generator for terrain features
 */
class SeededRandom {
  private seed: number;
  
  constructor(seed: number) {
    this.seed = seed;
  }
  
  next(): number {
    this.seed = (this.seed * 9301 + 49297) % 233280;
    return this.seed / 233280;
  }
  
  range(min: number, max: number): number {
    return min + this.next() * (max - min);
  }
}

/**
 * NEW SYSTEM: Add terrain features (forest in Brontium, jungle in Drantium)
 * Forest and jungle are now FEATURES ON TOP OF base terrain (ONLY hills)
 * NOT terrain types themselves
 * 
 * NEW RULES (ULTRA RESTRICTIVE):
 * - Jungle: ONLY on hills in Drantium (NEVER meadow, NEVER Brontium)
 * - Forest: ONLY on hills in Brontium (NEVER meadow, NEVER Drantium)
 * - Boreal Forest: ONLY on tundra terrain (NEVER anywhere else)
 * - Oasis: ONLY on desert (unique to desert, NEVER anywhere else)
 * - Volcano: ONLY on mountain_range (unique to mountain_range, additional to hasVolcano flag)
 * - Mountain: Can exist on tundra, desert, or ice (mountain peaks as feature)
 */
export function addTerrainFeatures(
  tiles: Map<string, HexTile>,
  config: MapConfig,
  random: SeededRandom
): void {
  for (const [, tile] of tiles) {
    // Only add features to land tiles (not ocean/coast/ice)
    if (tile.terrain === 'ocean' || tile.terrain === 'coast' || tile.terrain === 'ice') {
      continue;
    }
    
    // DRANTIUM: Add jungle features (selva) - ONLY on hills (NOT meadow)
    // ULTRA RESTRICTIVE: NEVER in Brontium, NEVER in desert, NEVER in meadow, NEVER outside Drantium
    if (tile.continent === 'drantium' && 
        tile.terrain !== 'desert' && 
        tile.terrain !== 'meadow' &&
        tile.terrain === 'hills') {
      // High chance for jungle on hills ONLY in warm, wet areas
      if (tile.temperature > 20 && tile.rainfall > 60) {
        const jungleChance = 0.7;
        if (random.next() < jungleChance) {
          if (!tile.features) tile.features = [];
          tile.features.push('jungle');
        }
      }
    }
    
    // BRONTIUM: Add forest features (bosque) - ONLY on hills (NOT meadow)
    // ULTRA RESTRICTIVE: NEVER in Drantium, NEVER in desert, NEVER in meadow, NEVER outside Brontium
    if (tile.continent === 'brontium' && 
        tile.terrain !== 'desert' && 
        tile.terrain !== 'meadow' &&
        tile.terrain === 'hills') {
      // High chance for forest on hills ONLY in temperate areas
      if (tile.temperature > 5 && 
          tile.temperature < 25 && 
          tile.rainfall > 50) {
        const forestChance = 0.7;
        if (random.next() < forestChance) {
          if (!tile.features) tile.features = [];
          tile.features.push('forest');
        }
      }
    }
    
    // BOREAL FOREST: Add boreal forest to tundra tiles
    // ULTRA RESTRICTIVE: ONLY in tundra terrain, NEVER anywhere else
    if (tile.terrain === 'tundra' && tile.rainfall > 30) {
      const borealChance = 0.6;
      if (random.next() < borealChance) {
        if (!tile.features) tile.features = [];
        tile.features.push('boreal_forest');
      }
    }
    
    // OASIS: Add oasis to desert tiles ONLY (unique feature exclusive to desert)
    // ULTRA RESTRICTIVE: ONLY in desert terrain, NEVER EVER anywhere else
    if (tile.terrain === 'desert') {
      const oasisChance = 0.08; // 8% chance
      if (random.next() < oasisChance) {
        if (!tile.features) tile.features = [];
        tile.features.push('oasis');
      }
    }
    
    // VOLCANO: Add volcano feature to mountain_range tiles (additional to hasVolcano flag)
    // ULTRA RESTRICTIVE: ONLY in mountain_range terrain, NEVER anywhere else
    if (tile.terrain === 'mountain_range') {
      const volcanoChance = 0.15; // 15% chance
      if (random.next() < volcanoChance) {
        if (!tile.features) tile.features = [];
        tile.features.push('volcano');
      }
    }
    
    // MOUNTAIN: Add mountain feature to tundra, desert, or ice
    // Mountains can appear as peaks in these terrains
    if (tile.terrain === 'tundra' || tile.terrain === 'desert' || tile.terrain === 'ice') {
      // Lower chance for mountains as features
      const mountainChance = tile.terrain === 'ice' ? 0.05 : 0.08; // 5% for ice, 8% for tundra/desert
      if (random.next() < mountainChance && tile.elevation >= 5) {
        if (!tile.features) tile.features = [];
        tile.features.push('mountain');
      }
    }
    
    // ISLANDS: Add features based on island type
    // Note: This maintains backward compatibility with island generation
    const islandConfig = config.islands.find(isl => 
      Math.abs(isl.centerQ - tile.coordinates.q) <= 1 && 
      Math.abs(isl.centerR - tile.coordinates.r) <= 1
    );
    
    if (islandConfig) {
      if (islandConfig.type === 'jungle' && tile.continent !== 'brontium') {
        // Jungle islands (Drantium side only)
        if (!tile.features) tile.features = [];
        if (!tile.features.includes('jungle')) {
          tile.features.push('jungle');
        }
      } else if (islandConfig.type === 'forest' && tile.continent !== 'drantium') {
        // Forest islands (Brontium side only)
        if (!tile.features) tile.features = [];
        if (!tile.features.includes('forest')) {
          tile.features.push('forest');
        }
      }
    }
  }
}
