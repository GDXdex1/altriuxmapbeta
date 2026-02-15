import type { TransportItem, TravelCalculation } from '@/types/game';
import { GAME_SPEED_MULTIPLIER } from '@/types/game';
import { calculateDuchyDistance } from './duchy-generator';

/**
 * Calculate travel time and arrival date
 */
export function calculateTravel(
  fromQ: number,
  fromR: number,
  toQ: number,
  toR: number,
  transport: TransportItem,
  currentServerTime: Date
): TravelCalculation {
  const distance = calculateDuchyDistance(fromQ, fromR, toQ, toR);
  
  // Calculate real-world days based on transport speed
  // Transport speed is in tiles per game day
  const gameDays = distance / transport.speed;
  
  // Convert to real-world time (4x speed means 1 real day = 4 game days)
  const realWorldDays = gameDays / GAME_SPEED_MULTIPLIER;
  
  // Calculate arrival date
  const arrivalDate = new Date(currentServerTime);
  arrivalDate.setDate(arrivalDate.getDate() + realWorldDays);
  
  return {
    fromDuchy: `Duchy (${fromQ}, ${fromR})`,
    toDuchy: `Duchy (${toQ}, ${toR})`,
    distance,
    selectedTransport: transport,
    travelTime: gameDays,
    arrivalDate
  };
}

/**
 * Default transport options
 */
export const TRANSPORT_OPTIONS: TransportItem[] = [
  {
    id: 'foot',
    name: 'On Foot',
    type: 'horse', // Using horse type as placeholder
    speed: 0.5, // 1 tile every 2 days
    icon: '🚶',
    weightCapacity: 0.5 // 0.5 Jax (10kg)
  },
  {
    id: 'horse-1',
    name: 'Horse',
    type: 'horse',
    speed: 1, // 1 tile per day
    icon: '🐎',
    weightCapacity: 2, // 2 Jax (40kg)
  },
  {
    id: 'cart-1',
    name: 'Cart',
    type: 'cart',
    speed: 0.75, // 0.75 tiles per day
    icon: '🛞',
    weightCapacity: 5, // 5 Jax (100kg)
  },
  {
    id: 'camel-1',
    name: 'Camel',
    type: 'camel',
    speed: 0.8, // 0.8 tiles per day
    icon: '🐪',
    weightCapacity: 3, // 3 Jax (60kg)
  },
  {
    id: 'ship-basic',
    name: 'Basic Ship',
    type: 'ship',
    speed: 1, // 1 tile per day (will be configurable)
    icon: '⛵',
    weightCapacity: 10, // 10 Jax (200kg)
  },
  {
    id: 'ship-advanced',
    name: 'Advanced Ship',
    type: 'ship',
    speed: 2, // 2 tiles per day
    icon: '🚢',
    weightCapacity: 20, // 20 Jax (400kg)
  }
];

/**
 * Calculate travel between SubLands (xLands) - 1km hexagons
 * Base speed: 50km/day = 50 hexagons/day in optimal conditions
 * Terrain modifiers apply to slow movement
 */
export function calculateSubLandTravel(
  path: Array<{ q: number; r: number }>,
  biomes: Map<string, string>, // Map of hex key to biome type
  features: Map<string, string[]> // Map of hex key to terrain features
): {
  totalTravelTimeHours: number;
  hexCosts: number[];
} {
  const BASE_SPEED_KM_PER_DAY = 50; // 50km/day in optimal conditions
  const HOURS_PER_DAY = 24;
  
  // Terrain cost multipliers
  const TERRAIN_COSTS: Record<string, number> = {
    mountain_range: 3.0, // x3 slower - cordillera
    hills: 1.5,         // x1.5 slower
    plains: 1.0,        // normal speed
    meadow: 1.0,        // normal speed
    desert: 1.2,        // slightly slower
    tundra: 1.3,        // slightly slower
    coast: 1.0,         // normal speed
    forest: 1.0,        // base terrain normal, feature applies cost
    jungle: 1.0         // base terrain normal, feature applies cost
  };
  
  // Feature cost multipliers (applied on top of terrain)
  const FEATURE_COSTS: Record<string, number> = {
    forest: 2.0,         // x2 slower - dense trees
    jungle: 2.0,         // x2 slower - very dense vegetation
    boreal_forest: 2.0   // x2 slower - dense northern forest
  };
  
  let totalCost = 0;
  const hexCosts: number[] = [];
  
  // Calculate cost for each hex in the path (skip first hex as it's the starting position)
  for (let i = 1; i < path.length; i++) {
    const hex = path[i];
    if (!hex) continue;
    
    const hexKey = `${hex.q},${hex.r}`;
    const biome = biomes.get(hexKey) || 'plains';
    const hexFeatures = features.get(hexKey) || [];
    
    // Base terrain cost
    let cost = TERRAIN_COSTS[biome] || 1.0;
    
    // Apply feature costs
    for (const feature of hexFeatures) {
      const featureCost = FEATURE_COSTS[feature];
      if (featureCost) {
        cost *= featureCost;
      }
    }
    
    totalCost += cost;
    hexCosts.push(cost);
  }
  
  // Calculate total time in hours
  // Time per hex = (1 km / (50 km/day)) * 24 hours/day * cost_multiplier
  const baseTimePerHexHours = (1 / BASE_SPEED_KM_PER_DAY) * HOURS_PER_DAY;
  const totalTravelTimeHours = totalCost * baseTimePerHexHours;
  
  return {
    totalTravelTimeHours,
    hexCosts
  };
}

/**
 * Calculate simple distance between two SubLand hexagons
 */
export function calculateSubLandDistance(
  q1: number,
  r1: number,
  q2: number,
  r2: number
): number {
  return (Math.abs(q1 - q2) + Math.abs(r1 - r2) + Math.abs((q1 + r1) - (q2 + r2))) / 2;
}
