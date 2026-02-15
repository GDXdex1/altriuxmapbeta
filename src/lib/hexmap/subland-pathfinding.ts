/**
 * Pathfinding for SubLand hexagons (1km x 1km hexagons)
 * Similar to main hex pathfinding but for smaller scale
 */

interface SubLandHex {
  q: number;
  r: number;
}

interface PathNode {
  hex: SubLandHex;
  gCost: number;
  hCost: number;
  fCost: number;
  parent: PathNode | null;
}

/**
 * Calculate hexagonal distance
 */
function hexDistance(a: SubLandHex, b: SubLandHex): number {
  return (Math.abs(a.q - b.q) + Math.abs(a.r - b.r) + Math.abs((a.q + a.r) - (b.q + b.r))) / 2;
}

/**
 * Get hex neighbors
 */
function getNeighbors(hex: SubLandHex): SubLandHex[] {
  const directions = [
    { q: 1, r: 0 }, { q: 1, r: -1 }, { q: 0, r: -1 },
    { q: -1, r: 0 }, { q: -1, r: 1 }, { q: 0, r: 1 }
  ];
  
  return directions.map(dir => ({
    q: hex.q + dir.q,
    r: hex.r + dir.r
  }));
}

/**
 * Check if hex is within duchy bounds (approximately radius 58)
 */
function isInBounds(hex: SubLandHex): boolean {
  const maxRadius = 58;
  const distance = Math.sqrt(hex.q * hex.q + hex.r * hex.r + hex.q * hex.r);
  return distance <= maxRadius;
}

/**
 * Simple A* pathfinding for SubLand hexagons
 * Assumes all hexes are traversable within the duchy bounds
 */
export function findSubLandPath(
  start: SubLandHex,
  goal: SubLandHex
): SubLandHex[] | null {
  // Check if start and goal are within bounds
  if (!isInBounds(start) || !isInBounds(goal)) {
    return null;
  }
  
  const openSet = new Map<string, PathNode>();
  const closedSet = new Set<string>();
  
  const getKey = (hex: SubLandHex): string => `${hex.q},${hex.r}`;
  
  // Create start node
  const startNode: PathNode = {
    hex: start,
    gCost: 0,
    hCost: hexDistance(start, goal),
    fCost: hexDistance(start, goal),
    parent: null
  };
  
  openSet.set(getKey(start), startNode);
  
  let iterations = 0;
  const MAX_ITERATIONS = 5000;
  
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
    
    const currentKey = getKey(currentNode.hex);
    
    // Check if we reached the goal
    if (currentNode.hex.q === goal.q && currentNode.hex.r === goal.r) {
      // Reconstruct path
      const path: SubLandHex[] = [];
      let current: PathNode | null = currentNode;
      
      while (current !== null) {
        path.unshift(current.hex);
        current = current.parent;
      }
      
      return path;
    }
    
    // Move current node from open to closed set
    openSet.delete(currentKey);
    closedSet.add(currentKey);
    
    // Check all neighbors
    const neighbors = getNeighbors(currentNode.hex);
    
    for (const neighbor of neighbors) {
      const neighborKey = getKey(neighbor);
      
      // Skip if already evaluated or out of bounds
      if (closedSet.has(neighborKey) || !isInBounds(neighbor)) continue;
      
      // Calculate tentative gCost (simple: 1 per hex)
      const tentativeGCost = currentNode.gCost + 1;
      
      // Check if this is a better path
      const existingNode = openSet.get(neighborKey);
      
      if (!existingNode || tentativeGCost < existingNode.gCost) {
        const hCost = hexDistance(neighbor, goal);
        const newNode: PathNode = {
          hex: neighbor,
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
