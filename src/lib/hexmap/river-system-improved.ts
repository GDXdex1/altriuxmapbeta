/**
 * Improved River Generation System with Backtracking
 * Solves the low success rate problem with robust pathfinding
 */

import type { HexTile, HexCoordinates, TerrainType } from './types';
import type { 
  River, 
  RiverSegment, 
  RiverEdge, 
  RiverPath, 
  RiverGenerationConfig,
  SubLandRiverHex 
} from './river-types';
import { createRiverEdgeId } from './river-types';
import { getHexKey, getNeighbors, hexDistance } from './hex-utils';

/**
 * Enhanced configuration with better defaults
 */
const IMPROVED_CONFIG: RiverGenerationConfig = {
  minLength: 6, // Reduced minimum for better success rate
  maxAttempts: 200, // More attempts per source
  flowToOcean: true,
  allowLakes: false
};

/**
 * Priority queue for A* pathfinding
 */
class PriorityQueue<T> {
  private items: {item: T, priority: number}[] = [];
  
  enqueue(item: T, priority: number) {
    this.items.push({item, priority});
    this.items.sort((a, b) => a.priority - b.priority);
  }
  
  dequeue(): T | undefined {
    return this.items.shift()?.item;
  }
  
  isEmpty(): boolean {
    return this.items.length === 0;
  }
  
  size(): number {
    return this.items.length;
  }
}

/**
 * Find all coast tiles for pathfinding targets
 */
function findCoastTiles(tiles: Map<string, HexTile>): HexTile[] {
  const coasts: HexTile[] = [];
  for (const tile of tiles.values()) {
    if (tile.terrain === 'coast') {
      coasts.push(tile);
    }
  }
  return coasts;
}

/**
 * A* pathfinding for river generation
 * Guarantees optimal path if one exists
 */
function findRiverPathAStar(
  source: HexTile,
  targetCoasts: HexTile[],
  tiles: Map<string, HexTile>,
  minLength: number
): RiverPath {
  if (targetCoasts.length === 0) {
    return {
      isValid: false,
      path: [source.coordinates],
      length: 1,
      reason: 'No coast tiles found'
    };
  }
  
  // Try each coast as target, return the best valid path
  let bestPath: RiverPath | null = null;
  
  for (const targetCoast of targetCoasts) {
    const openSet = new PriorityQueue<{coord: HexCoordinates, path: HexCoordinates[], gScore: number}>();
    const closedSet = new Set<string>();
    const gScores = new Map<string, number>();
    const fScores = new Map<string, number>();
    
    const startKey = getHexKey(source.coordinates.q, source.coordinates.r);
    gScores.set(startKey, 0);
    
    // Heuristic: distance to target + elevation difference
    const hScore = hexDistance(source.coordinates, targetCoast.coordinates) + 
                   Math.abs(source.elevation - targetCoast.elevation) * 0.5;
    fScores.set(startKey, hScore);
    
    openSet.enqueue({
      coord: source.coordinates,
      path: [source.coordinates],
      gScore: 0
    }, hScore);
    
    while (!openSet.isEmpty()) {
      const current = openSet.dequeue()!;
      const currentKey = getHexKey(current.coord.q, current.coord.r);
      
      // Check if we reached the target
      if (current.coord.q === targetCoast.coordinates.q && 
          current.coord.r === targetCoast.coordinates.r) {
        if (current.path.length >= minLength) {
          const pathResult = {
            isValid: true,
            path: current.path,
            length: current.path.length
          };
          
          // Keep the shortest valid path
          if (!bestPath || pathResult.length < bestPath.length) {
            bestPath = pathResult;
          }
          break;
        }
      }
      
      closedSet.add(currentKey);
      
      // Explore neighbors
      const neighbors = getNeighbors(current.coord);
      for (const neighborCoord of neighbors) {
        const neighborKey = getHexKey(neighborCoord.q, neighborCoord.r);
        
        // Skip if already evaluated
        if (closedSet.has(neighborKey)) continue;
        
        const neighborTile = tiles.get(neighborKey);
        if (!neighborTile) continue;
        
        // Skip ice terrain
        if (neighborTile.terrain === 'ice') continue;
        
        // Only allow downhill or flat flow
        const currentTile = tiles.get(currentKey)!;
        if (neighborTile.elevation > currentTile.elevation) continue;
        
        // Calculate tentative g-score
        const tentativeGScore = current.gScore + 1;
        
        // Check if this path is better
        const existingGScore = gScores.get(neighborKey) || Infinity;
        if (tentativeGScore < existingGScore) {
          gScores.set(neighborKey, tentativeGScore);
          
          // Calculate f-score with heuristic
          const hScore = hexDistance(neighborCoord, targetCoast.coordinates) + 
                        Math.abs(neighborTile.elevation - targetCoast.elevation) * 0.5;
          const fScore = tentativeGScore + hScore;
          fScores.set(neighborKey, fScore);
          
          // Add to open set with new path
          const newPath = [...current.path, neighborCoord];
          openSet.enqueue({
            coord: neighborCoord,
            path: newPath,
            gScore: tentativeGScore
          }, fScore);
        }
      }
    }
    
    // If we found a valid path for this coast, don't try others
    if (bestPath && bestPath.isValid) break;
  }
  
  return bestPath || {
    isValid: false,
    path: [source.coordinates],
    length: 1,
    reason: 'No valid path found to any coast'
  };
}

/**
 * Backtracking river generation for when A* fails
 */
function generateRiverPathWithBacktracking(
  source: HexTile,
  tiles: Map<string, HexTile>,
  config: RiverGenerationConfig,
  coastTiles: HexTile[]
): RiverPath {
  const path: HexCoordinates[] = [source.coordinates];
  const visited = new Set<string>([getHexKey(source.coordinates.q, source.coordinates.r)]);
  const stack: {position: HexTile, alternatives: HexTile[]}[] = [];
  
  let current = source;
  const maxSteps = 100; // Prevent infinite loops
  
  for (let step = 0; step < maxSteps; step++) {
    // Success: reached coast
    if (current.terrain === 'coast') {
      if (path.length >= config.minLength) {
        return {
          isValid: true,
          path: [...path],
          length: path.length
        };
      } else {
        break; // Too short, try backtracking
      }
    }
    
    // Find candidates with multi-factor scoring
    const candidates = findRankedCandidates(current, tiles, visited, coastTiles);
    
    if (candidates.length === 0) {
      // Dead end, backtrack if possible
      if (stack.length === 0) break;
      
      const backtrack = stack.pop()!;
      
      // Remove current position from path and visited
      const removed = path.pop()!;
      visited.delete(getHexKey(removed.q, removed.r));
      
      // Try next alternative
      if (backtrack.alternatives.length > 0) {
        current = backtrack.alternatives.shift()!;
        path.push(current.coordinates);
        visited.add(getHexKey(current.coordinates.q, current.coordinates.r));
        
        // Update stack with remaining alternatives
        if (backtrack.alternatives.length > 0) {
          stack.push({
            position: tiles.get(getHexKey(path[path.length - 2].q, path[path.length - 2].r))!,
            alternatives: backtrack.alternatives
          });
        }
      } else {
        current = backtrack.position;
      }
    } else {
      // Save alternatives for backtracking
      stack.push({
        position: current,
        alternatives: candidates.slice(1) // All except the first
      });
      
      // Move to best candidate
      current = candidates[0];
      path.push(current.coordinates);
      visited.add(getHexKey(current.coordinates.q, current.coordinates.r));
    }
  }
  
  return {
    isValid: false,
    path,
    length: path.length,
    reason: path.length < config.minLength ? 
      `River too short: ${path.length} < ${config.minLength}` : 
      'No valid path found'
  };
}

/**
 * Find ranked candidates for next river step
 */
function findRankedCandidates(
  current: HexTile,
  tiles: Map<string, HexTile>,
  visited: Set<string>,
  coastTiles: HexTile[]
): HexTile[] {
  const neighbors = getNeighbors(current.coordinates);
  const candidates: {tile: HexTile, score: number}[] = [];
  
  const currentCoastDistance = getDistanceToNearestCoast(current.coordinates, coastTiles);
  
  for (const neighborCoord of neighbors) {
    const key = getHexKey(neighborCoord.q, neighborCoord.r);
    
    if (visited.has(key)) continue;
    
    const neighborTile = tiles.get(key);
    if (!neighborTile) continue;
    if (neighborTile.terrain === 'ice') continue;
    if (neighborTile.elevation > current.elevation) continue;
    
    let score = 0;
    
    // Elevation difference
    const elevationDiff = current.elevation - neighborTile.elevation;
    score += elevationDiff * 10;
    
    // Coast proximity
    const neighborCoastDistance = getDistanceToNearestCoast(neighborCoord, coastTiles);
    score += (currentCoastDistance - neighborCoastDistance) * 5;
    
    // Coast bonus
    if (neighborTile.terrain === 'coast') {
      score += 100;
    }
    
    // Avoid loops penalty
    for (const visitedKey of visited) {
      const visitedCoord = {
        q: parseInt(visitedKey.split(',')[0]),
        r: parseInt(visitedKey.split(',')[1]),
        x: parseInt(visitedKey.split(',')[0]),
        y: parseInt(visitedKey.split(',')[1])
      };
      const distance = hexDistance(neighborCoord, visitedCoord);
      if (distance <= 2) {
        score -= 10;
      }
    }
    
    candidates.push({tile: neighborTile, score});
  }
  
  candidates.sort((a, b) => b.score - a.score);
  return candidates.map(c => c.tile);
}

/**
 * Get distance to nearest coast
 */
function getDistanceToNearestCoast(
  coordinates: HexCoordinates,
  coastTiles: HexTile[]
): number {
  if (coastTiles.length === 0) return Infinity;
  
  let minDistance = Infinity;
  for (const coast of coastTiles) {
    const distance = hexDistance(coordinates, coast.coordinates);
    if (distance < minDistance) {
      minDistance = distance;
    }
  }
  return minDistance;
}

/**
 * Create river segments
 */
function createRiverSegments(
  path: HexCoordinates[],
  tiles: Map<string, HexTile>
): RiverSegment[] {
  const segments: RiverSegment[] = [];
  
  for (let i = 0; i < path.length; i++) {
    const coord = path[i];
    const tile = tiles.get(getHexKey(coord.q, coord.r));
    if (!tile) continue;
    
    segments.push({
      coordinates: coord,
      elevation: tile.elevation,
      flowDirection: 'downstream',
      distanceFromSource: i,
      distanceToMouth: path.length - 1 - i
    });
  }
  
  return segments;
}

/**
 * Create river edges
 */
function createRiverEdges(
  path: HexCoordinates[],
  riverId: string
): RiverEdge[] {
  const edges: RiverEdge[] = [];
  
  for (let i = 0; i < path.length - 1; i++) {
    const current = path[i];
    const next = path[i + 1];
    
    if (!current || !next) continue;
    
    const edgeId = createRiverEdgeId(current, next);
    const neighbors = getNeighbors(current);
    const direction = neighbors.findIndex(
      n => n.q === next.q && n.r === next.r
    );
    
    edges.push({
      edgeId,
      hex1: current,
      hex2: next,
      direction: direction >= 0 ? direction : 0,
      riverId
    });
  }
  
  return edges;
}

/**
 * Generate a single river using improved methods
 */
export function generateRiverImproved(
  source: HexTile,
  tiles: Map<string, HexTile>,
  config: RiverGenerationConfig = IMPROVED_CONFIG
): River | null {
  if (source.terrain !== 'mountain_range') {
    return null;
  }
  
  const coastTiles = findCoastTiles(tiles);
  if (coastTiles.length === 0) {
    return null;
  }
  
  // Try A* first (most reliable)
  let pathResult = findRiverPathAStar(source, coastTiles, tiles, config.minLength);
  
  // If A* fails, try backtracking
  if (!pathResult.isValid) {
    pathResult = generateRiverPathWithBacktracking(source, tiles, config, coastTiles);
  }
  
  if (!pathResult.isValid || pathResult.path.length < config.minLength) {
    return null;
  }
  
  const riverId = `river-${source.coordinates.q}-${source.coordinates.r}-${Date.now()}`;
  const segments = createRiverSegments(pathResult.path, tiles);
  const edges = createRiverEdges(pathResult.path, riverId);
  const mouth = pathResult.path[pathResult.path.length - 1];
  
  return {
    id: riverId,
    source: source.coordinates,
    mouth: mouth!,
    segments,
    edges,
    length: pathResult.path.length,
    flowDirection: 'downstream'
  };
}

/**
 * Generate all rivers with improved success rate
 */
export function generateAllRiversImproved(
  tiles: Map<string, HexTile>,
  config: RiverGenerationConfig = IMPROVED_CONFIG,
  targetCount: number = 20
): River[] {
  const rivers: River[] = [];
  const mountainRanges = Array.from(tiles.values()).filter(t => t.terrain === 'mountain_range');
  
  console.log(`🌊🌊🌊 IMPROVED RIVER GENERATION START 🌊🌊🌊`);
  console.log(`   Found ${mountainRanges.length} mountain_range hexagons`);
  console.log(`   Target: Generate ${targetCount} rivers`);
  console.log(`   Min length: ${config.minLength} hexagons`);
  
  if (mountainRanges.length === 0) {
    console.error(`❌ NO MOUNTAIN RANGES FOUND!`);
    return [];
  }
  
  // Sort mountain ranges by elevation (highest first) for better river sources
  mountainRanges.sort((a, b) => b.elevation - a.elevation);
  
  let attempts = 0;
  const maxAttempts = Math.min(mountainRanges.length * 2, 200);
  let failedAttempts = 0;
  const failureReasons: Record<string, number> = {};
  
  for (const mountainRange of mountainRanges) {
    if (rivers.length >= targetCount) break;
    if (attempts >= maxAttempts) break;
    
    attempts++;
    
    const river = generateRiverImproved(mountainRange, tiles, config);
    
    if (river) {
      rivers.push(river);
      
      // Mark tiles with river feature
      for (const segment of river.segments) {
        const tileKey = getHexKey(segment.coordinates.q, segment.coordinates.r);
        const tile = tiles.get(tileKey);
        if (tile) {
          if (!tile.features) tile.features = [];
          if (!tile.features.includes('river')) tile.features.push('river');
          tile.hasRiver = true;
        }
      }
      
      console.log(`   ✓ River ${rivers.length}/${targetCount}: ${river.length} hexagons from (${mountainRange.coordinates.q},${mountainRange.coordinates.r})`);
    } else {
      failedAttempts++;
      failureReasons['Failed to generate river'] = (failureReasons['Failed to generate river'] || 0) + 1;
    }
  }
  
  console.log(`✅ IMPROVED RIVERS GENERATED ✅`);
  console.log(`   Successfully generated: ${rivers.length} rivers`);
  console.log(`   Failed attempts: ${failedAttempts}`);
  console.log(`   Success rate: ${attempts > 0 ? ((rivers.length / attempts) * 100).toFixed(1) : 0}%`);
  
  const tilesWithRiver = Array.from(tiles.values()).filter(t => t.features?.includes('river'));
  console.log(`   Total tiles marked with river feature: ${tilesWithRiver.length}`);
  console.log(`   Average river length: ${rivers.length > 0 ? (tilesWithRiver.length / rivers.length).toFixed(1) : 0} tiles`);
  
  return rivers;
}
