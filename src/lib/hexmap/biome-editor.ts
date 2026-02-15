import type { HexTile, TerrainType } from './types';
import { getHexKey } from './hex-utils';

/**
 * Change biome/terrain of specific hexagons by coordinates
 * This allows manual fine-tuning of map details
 * 
 * @param tiles - The map of all tiles
 * @param changes - Array of coordinate/terrain pairs
 * @returns Number of tiles successfully changed
 */
export function changeBiomesByCoordinates(
  tiles: Map<string, HexTile>,
  changes: Array<{ q: number; r: number; terrain: TerrainType }>
): number {
  let changedCount = 0;
  
  for (const change of changes) {
    const key = getHexKey(change.q, change.r);
    const tile = tiles.get(key);
    
    if (tile) {
      tile.terrain = change.terrain;
      changedCount++;
    }
  }
  
  return changedCount;
}

/**
 * Change biomes by hex IDs (q,r string format)
 * Accepts IDs in format "q:r" or "q,r"
 * 
 * @param tiles - The map of all tiles
 * @param changes - Array of ID/terrain pairs
 * @returns Number of tiles successfully changed
 */
export function changeBiomesByIds(
  tiles: Map<string, HexTile>,
  changes: Array<{ id: string; terrain: TerrainType }>
): number {
  let changedCount = 0;
  
  for (const change of changes) {
    // Parse ID - supports "q:r" or "q,r" format
    const parts = change.id.split(/[,:]/);
    if (parts.length !== 2) continue;
    
    const q = parseInt(parts[0] || '0', 10);
    const r = parseInt(parts[1] || '0', 10);
    
    if (isNaN(q) || isNaN(r)) continue;
    
    const key = getHexKey(q, r);
    const tile = tiles.get(key);
    
    if (tile) {
      tile.terrain = change.terrain;
      changedCount++;
    }
  }
  
  return changedCount;
}

/**
 * Batch change biomes in a rectangular area
 * Useful for quickly modifying large regions
 */
export function changeBiomesInArea(
  tiles: Map<string, HexTile>,
  minQ: number,
  maxQ: number,
  minR: number,
  maxR: number,
  terrain: TerrainType,
  predicate?: (tile: HexTile) => boolean
): number {
  let changedCount = 0;
  
  for (let q = minQ; q <= maxQ; q++) {
    for (let r = minR; r <= maxR; r++) {
      const key = getHexKey(q, r);
      const tile = tiles.get(key);
      
      if (tile && (!predicate || predicate(tile))) {
        tile.terrain = terrain;
        changedCount++;
      }
    }
  }
  
  return changedCount;
}

/**
 * Change biomes in a circular radius
 * Useful for creating circular features
 */
export function changeBiomesInRadius(
  tiles: Map<string, HexTile>,
  centerQ: number,
  centerR: number,
  radius: number,
  terrain: TerrainType,
  predicate?: (tile: HexTile) => boolean
): number {
  let changedCount = 0;
  
  for (let q = centerQ - radius; q <= centerQ + radius; q++) {
    for (let r = centerR - radius; r <= centerR + radius; r++) {
      const dq = q - centerQ;
      const dr = r - centerR;
      const distance = Math.sqrt(dq * dq + dr * dr);
      
      if (distance <= radius) {
        const key = getHexKey(q, r);
        const tile = tiles.get(key);
        
        if (tile && (!predicate || predicate(tile))) {
          tile.terrain = terrain;
          changedCount++;
        }
      }
    }
  }
  
  return changedCount;
}

/**
 * Export biome data for a list of coordinates
 * Useful for analyzing specific tiles
 */
export function exportBiomeData(
  tiles: Map<string, HexTile>,
  coordinates: Array<{ q: number; r: number }>
): Array<{ q: number; r: number; terrain: TerrainType; continent?: string }> {
  const results: Array<{ q: number; r: number; terrain: TerrainType; continent?: string }> = [];
  
  for (const coord of coordinates) {
    const key = getHexKey(coord.q, coord.r);
    const tile = tiles.get(key);
    
    if (tile) {
      results.push({
        q: coord.q,
        r: coord.r,
        terrain: tile.terrain,
        continent: tile.continent
      });
    }
  }
  
  return results;
}
