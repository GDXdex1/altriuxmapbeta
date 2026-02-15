import type { HexTile, TerrainType } from './types';
import { getNeighbors, hexDistance, getHexKey } from './hex-utils';
import type { HexCoordinates } from './types';

/**
 * Terrain movement costs
 * - Impassable terrains have cost Infinity
 * - Higher costs = slower movement
 */
export const TERRAIN_COSTS: Record<TerrainType, number> = {
  ocean: Infinity,      // Cannot walk on water
  coast: Infinity,      // Cannot walk on water
  ice: Infinity,        // Cannot walk on ice (need special equipment)
  plains: 1,            // Easy movement
  meadow: 1.2,          // Slightly harder than plains
  hills: 1.5,           // x1.5 slower (moderate difficulty)
  mountain_range: 3,    // x3 slower (very difficult, steep terrain - cordillera)
  tundra: 2.5,          // Cold, difficult terrain
  desert: 1.5           // Hot, sand makes movement harder
};

/**
 * Feature movement cost multipliers
 * Applied on top of terrain costs
 */
export const FEATURE_COSTS: Record<string, number> = {
  forest: 2.0,          // x2 slower - dense trees slow movement
  jungle: 2.0,          // x2 slower - very dense vegetation
  boreal_forest: 2.0,   // x2 slower - dense northern forest
  none: 1.0
};

/**
 * Calculate total movement cost for a hex tile
 */
export function getMovementCost(tile: HexTile): number {
  let cost = TERRAIN_COSTS[tile.terrain];
  
  // If terrain is impassable, return infinity
  if (cost === Infinity) return Infinity;
  
  // Apply feature costs
  if (tile.features && tile.features.length > 0) {
    for (const feature of tile.features) {
      const featureCost = FEATURE_COSTS[feature] || 1.0;
      cost *= featureCost;
    }
  }
  
  return cost;
}

/**
 * Check if a tile is traversable (not water, ice, etc.)
 */
export function isTraversable(tile: HexTile): boolean {
  return getMovementCost(tile) !== Infinity;
}

/**
 * Node for A* pathfinding
 */
interface PathNode {
  coordinates: HexCoordinates;
  gCost: number;      // Cost from start to this node
  hCost: number;      // Estimated cost from this node to goal (heuristic)
  fCost: number;      // Total cost (g + h)
  parent: PathNode | null;
}

/**
 * A* pathfinding algorithm for hexagonal grid
 * Returns null if no path exists (e.g., destination is water)
 */
export function findPath(
  start: HexCoordinates,
  goal: HexCoordinates,
  tiles: Map<string, HexTile>
): HexCoordinates[] | null {
  const startTile = tiles.get(getHexKey(start.q, start.r));
  const goalTile = tiles.get(getHexKey(goal.q, goal.r));
  
  // Check if start or goal tiles exist and are traversable
  if (!startTile || !goalTile) {
    return null;
  }
  
  if (!isTraversable(goalTile)) {
    return null; // Cannot reach water/ice destinations
  }
  
  const openSet = new Map<string, PathNode>();
  const closedSet = new Set<string>();
  
  // Create start node
  const startNode: PathNode = {
    coordinates: start,
    gCost: 0,
    hCost: hexDistance(start, goal),
    fCost: hexDistance(start, goal),
    parent: null
  };
  
  openSet.set(getHexKey(start.q, start.r), startNode);
  
  let iterations = 0;
  const MAX_ITERATIONS = 10000; // Prevent infinite loops
  
  while (openSet.size > 0 && iterations < MAX_ITERATIONS) {
    iterations++;
    
    // Find node with lowest fCost
    let currentNode: PathNode | null = null;
    let lowestF = Infinity;
    
    for (const node of openSet.values()) {
      if (node.fCost < lowestF) {
        lowestF = node.fCost;
        currentNode = node;
      }
    }
    
    if (!currentNode) break;
    
    const currentKey = getHexKey(currentNode.coordinates.q, currentNode.coordinates.r);
    
    // Check if we reached the goal
    if (currentNode.coordinates.q === goal.q && currentNode.coordinates.r === goal.r) {
      // Reconstruct path
      const path: HexCoordinates[] = [];
      let current: PathNode | null = currentNode;
      
      while (current !== null) {
        path.unshift(current.coordinates);
        current = current.parent;
      }
      
      return path;
    }
    
    // Move current node from open to closed set
    openSet.delete(currentKey);
    closedSet.add(currentKey);
    
    // Check all neighbors
    const neighbors = getNeighbors(currentNode.coordinates);
    
    for (const neighbor of neighbors) {
      const neighborKey = getHexKey(neighbor.q, neighbor.r);
      
      // Skip if already evaluated
      if (closedSet.has(neighborKey)) continue;
      
      const neighborTile = tiles.get(neighborKey);
      
      // Skip if tile doesn't exist or is impassable
      if (!neighborTile || !isTraversable(neighborTile)) continue;
      
      // Calculate tentative gCost
      const movementCost = getMovementCost(neighborTile);
      const tentativeGCost = currentNode.gCost + movementCost;
      
      // Check if this is a better path
      const existingNode = openSet.get(neighborKey);
      
      if (!existingNode || tentativeGCost < existingNode.gCost) {
        const hCost = hexDistance(neighbor, goal);
        const newNode: PathNode = {
          coordinates: neighbor,
          gCost: tentativeGCost,
          hCost: hCost,
          fCost: tentativeGCost + hCost,
          parent: currentNode
        };
        
        openSet.set(neighborKey, newNode);
      }
    }
  }
  
  // No path found
  return null;
}

/**
 * Calculate total travel time along a path
 * Returns time in game days
 */
export function calculatePathTravelTime(
  path: HexCoordinates[],
  tiles: Map<string, HexTile>,
  baseSpeed: number // tiles per game day
): number {
  let totalCost = 0;
  
  for (let i = 1; i < path.length; i++) {
    const coord = path[i];
    if (!coord) continue;
    
    const tile = tiles.get(getHexKey(coord.q, coord.r));
    if (!tile) continue;
    
    const movementCost = getMovementCost(tile);
    totalCost += movementCost;
  }
  
  // Time = distance / speed
  // With movement costs, effective distance = sum of costs
  return totalCost / baseSpeed;
}

/**
 * Get terrain summary along a path
 */
export function getPathTerrainSummary(
  path: HexCoordinates[],
  tiles: Map<string, HexTile>
): Record<string, number> {
  const summary: Record<string, number> = {};
  
  for (const coord of path) {
    const tile = tiles.get(getHexKey(coord.q, coord.r));
    if (!tile) continue;
    
    const terrain = tile.terrain;
    summary[terrain] = (summary[terrain] || 0) + 1;
  }
  
  return summary;
}

/**
 * Check if destination is reachable (not water/ice)
 */
export function isDestinationReachable(
  destination: HexCoordinates,
  tiles: Map<string, HexTile>
): boolean {
  const tile = tiles.get(getHexKey(destination.q, destination.r));
  if (!tile) return false;
  return isTraversable(tile);
}
