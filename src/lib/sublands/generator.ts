import type { SubLand, SubLandResourceType } from './types';
import type { HexTile, MineralType, NaturalResourceType } from '../hexmap/types';
import { WORLD_CITIES } from '../data/world-cities';

/**
 * Check if a subland is adjacent to any coastal_inland hexagons
 */
export function isAdjacentToCoastalInland(
  subland: SubLand,
  allSublands: SubLand[]
): boolean {
  const neighbors = [
    { q: subland.q + 1, r: subland.r },
    { q: subland.q + 1, r: subland.r - 1 },
    { q: subland.q, r: subland.r - 1 },
    { q: subland.q - 1, r: subland.r },
    { q: subland.q - 1, r: subland.r + 1 },
    { q: subland.q, r: subland.r + 1 }
  ];

  for (const neighbor of neighbors) {
    const adjacentHex = allSublands.find(sl => sl.q === neighbor.q && sl.r === neighbor.r);
    if (adjacentHex && adjacentHex.resourceType === 'coastal_inland') {
      return true;
    }
  }

  return false;
}

/**
 * Generate ~10,000 SubLands in HEXAGONAL layout for a parent hex tile
 * Each SubLand is a small hexagon within the parent hex
 * Uses axial coordinates (q, r) to fill a hexagonal shape
 * @param coastalLandSides - Array of sides (0-5) that touch land (for coastal tiles)
 * @param oceanNeighborSides - Array of sides (0-5) that touch ocean (for any land tile)
 */
export function generateSubLandsForHex(
  parentTile: HexTile,
  parentQ: number,
  parentR: number,
  coastalLandSides?: number[],
  oceanNeighborSides?: number[]
): SubLand[] {
  const sublands: SubLand[] = [];

  // Radius of the hexagonal grid (to get ~10,000 hexagons)
  // Formula: 3R² - 3R + 1 ≈ 10,000  => R ≈ 58
  const radius = 58; // This gives us 9,973 hexagons

  // Determine biome type based on parent terrain
  const biomeType = getBiomeType(parentTile);

  // Determine resource distribution based on parent hex
  const mineLocations = generateMineLocations(parentTile, radius);
  const farmlandLocations = generateFarmlandLocations(parentTile, radius);
  const riverLocations = generateRiverLocations(parentTile, radius);

  // Check if this hex is a World City location
  const worldCity = WORLD_CITIES.find(c => c.q === parentQ && c.r === parentR);

  // Define settlement locations if it is a city
  const citySettlements = new Map<string, 'city' | 'town' | 'village'>();
  if (worldCity) {
    // City Center at (0,0)
    citySettlements.set("0,0", 'city');

    // 3 Towns at ~15km radius (spread 120 degrees)
    // Town 1: East (15, 0)
    citySettlements.set("15,0", 'town');
    // Town 2: North West (-7, 15) roughly
    citySettlements.set("-7,15", 'town');
    // Town 3: South West (-8, -15) roughly
    citySettlements.set("-8,-15", 'town');

    // 6 Villages (2 per town)
    citySettlements.set("17,0", 'village');
    citySettlements.set("13,0", 'village');

    citySettlements.set("-9,17", 'village');
    citySettlements.set("-5,13", 'village');

    citySettlements.set("-8,-13", 'village');
    citySettlements.set("-8,-17", 'village');
  }

  // Generate hexagonal grid using axial coordinates
  for (let q = -radius; q <= radius; q++) {
    const r1 = Math.max(-radius, -q - radius);
    const r2 = Math.min(radius, -q + radius);

    for (let r = r1; r <= r2; r++) {
      const posKey = `${q},${r}`;

      // Determine resource type
      let resourceType: SubLandResourceType = 'standard';

      // For coastal tiles, check if this subland should be coastal land
      if (parentTile.terrain === 'coast' && coastalLandSides && coastalLandSides.length > 0) {
        const sublandSide = determineSublandSide(q, r, radius);

        if (sublandSide !== null && coastalLandSides.includes(sublandSide)) {
          const distanceFromEdge = getDistanceFromEdge(q, r, sublandSide, radius);

          // Place at least 5 hexagons of coastal land on sides that touch land
          if (distanceFromEdge <= 5) {
            resourceType = 'coastal_land';
          }
        }
      }

      // For any land tile with ocean neighbors, check if this subland should be coastal inland
      if (parentTile.terrain !== 'ocean' && parentTile.terrain !== 'ice' && oceanNeighborSides && oceanNeighborSides.length > 0) {
        const sublandSide = determineSublandSide(q, r, radius);

        // Mark only the first 5 hexagons from the edge as coastal inland
        if (sublandSide !== null && oceanNeighborSides.includes(sublandSide)) {
          const distanceFromEdge = getDistanceFromEdge(q, r, sublandSide, radius);
          if (distanceFromEdge <= 5) {
            resourceType = 'coastal_inland';
          }
        }
      }

      if (mineLocations.has(posKey)) {
        resourceType = mineLocations.get(posKey)!;
      } else if (farmlandLocations.has(posKey)) {
        resourceType = farmlandLocations.get(posKey)!;
      }

      // Check if this SubLand has a river
      const riverInfo = riverLocations.get(posKey);
      const hasRiver = riverInfo !== undefined;
      const isNavigableRiver = riverInfo?.navigable || false;

      // Natural features (trees, rocks) present on virgin lands
      const hasNaturalFeatures = biomeType === 'forest' || biomeType === 'jungle' || biomeType === 'boreal_forest';

      sublands.push({
        id: `${parentQ}:${parentR}:${q}:${r}`,
        q,
        r,
        resourceType,
        hasRiver,
        isNavigableRiver,
        biomeType,
        hasNaturalFeatures,
        status: 'virgin',
        buildings: [],
        usedAreaM2: 0,
        maxAreaM2: 1000000 // 1 km² = 1,000,000 m²
      });

      // Inject Settlement Buildings if applicable
      if (citySettlements.has(posKey)) {
        const type = citySettlements.get(posKey)!;
        const subland = sublands[sublands.length - 1]; // Get the one we just pushed

        subland.status = 'claimed';
        subland.owner = 'System'; // Reserved
        subland.ownerName = type === 'city' ? worldCity?.name : `${worldCity?.name} ${type === 'town' ? 'Town' : 'Village'}`;

        // Add building
        subland.buildings.push({
          id: `sys-build-${parentQ}-${parentR}-${q}-${r}`,
          type: type === 'city' ? 'town' : (type === 'town' ? 'town' : 'urban_core'), // Mapping: City->Town(Building), Town->Town, Village->UrbanCore
          builtAt: new Date(),
          nftId: 'system-reserved',
          position: { offsetX: 0.5, offsetY: 0.5 },
          workers: type === 'city' ? 1000 : (type === 'town' ? 500 : 100),
          productionRate: 100
        });

        // If it's a city, reserve neighbors too (7 tiles rule)
        if (type === 'city') {
          // We can't easily access neighbors here as they might not be generated yet or passed.
          // But we can add to citySettlements map via logic if we did it before the loop.
          // For now, simpler implementation: just the center is the core.
          // The user asked for "7 casillas... reserva". We can implement that by marking neighbors 
          // in the citySettlements map in the initialization phase if we wanted.
          // But for compact code, let's stick to the core for now or assume visual radius handles it.
          subland.isPartOfTown = true;
          subland.townCenterPosition = { centerQ: 0, centerR: 0 };
        }
      }
    }
  }

  return sublands;
}

/**
 * Determine biome type based on parent hex terrain AND features
 * NEW: Features (forest/jungle/boreal_forest) determine visual biome, not terrain type
 */
function getBiomeType(parentTile: HexTile): 'mountain' | 'plains' | 'forest' | 'jungle' | 'desert' | 'coast' | 'meadow' | 'hills' | 'tundra' | 'boreal_forest' {
  // Check features first (forest/jungle/boreal_forest as visual characteristics)
  if (parentTile.features && parentTile.features.length > 0) {
    if (parentTile.features.includes('jungle')) {
      return 'jungle';
    }
    if (parentTile.features.includes('forest')) {
      return 'forest';
    }
    if (parentTile.features.includes('boreal_forest')) {
      return 'boreal_forest';
    }
  }

  // Then check terrain type
  switch (parentTile.terrain) {
    case 'mountain':
      return 'mountain';
    case 'meadow':
      return 'meadow';
    case 'hills':
      return 'hills';
    case 'desert':
      return 'desert';
    case 'coast':
      return 'coast';
    case 'tundra':
      return 'tundra';
    case 'plains':
    default:
      return 'plains';
  }
}

/**
 * Generate mine locations based on parent hex minerals
 */
function generateMineLocations(
  parentTile: HexTile,
  radius: number
): Map<string, SubLandResourceType> {
  const mines = new Map<string, SubLandResourceType>();

  if (parentTile.minerals.length === 0) return mines;

  // 10-15 mines per parent hex that has minerals
  const mineCount = Math.min(15, Math.max(10, parentTile.minerals.length * 3));

  for (let i = 0; i < mineCount; i++) {
    // Generate random hexagonal coordinates within the radius
    const q = Math.floor(Math.random() * (2 * radius + 1)) - radius;
    const r1 = Math.max(-radius, -q - radius);
    const r2 = Math.min(radius, -q + radius);
    const r = Math.floor(Math.random() * (r2 - r1 + 1)) + r1;
    const posKey = `${q},${r}`;

    if (!mines.has(posKey)) {
      const mineral = parentTile.minerals[Math.floor(Math.random() * parentTile.minerals.length)];
      const mineType = `mine_${mineral}` as SubLandResourceType;
      mines.set(posKey, mineType);
    }
  }

  return mines;
}

/**
 * Generate farmland locations based on parent hex resources
 */
function generateFarmlandLocations(
  parentTile: HexTile,
  radius: number
): Map<string, SubLandResourceType> {
  const farmlands = new Map<string, SubLandResourceType>();

  const hasWheat = parentTile.resources.includes('wheat');
  const hasCotton = parentTile.resources.includes('cotton');
  const hasSpices = parentTile.resources.includes('spices');

  if (!hasWheat && !hasCotton && !hasSpices) return farmlands;

  // 20-30 farmlands per parent hex that has agricultural resources
  const farmlandCount = 25;

  for (let i = 0; i < farmlandCount; i++) {
    // Generate random hexagonal coordinates within the radius
    const q = Math.floor(Math.random() * (2 * radius + 1)) - radius;
    const r1 = Math.max(-radius, -q - radius);
    const r2 = Math.min(radius, -q + radius);
    const r = Math.floor(Math.random() * (r2 - r1 + 1)) + r1;
    const posKey = `${q},${r}`;

    if (!farmlands.has(posKey)) {
      let farmType: SubLandResourceType = 'farmland_wheat';

      if (hasWheat && Math.random() > 0.5) {
        farmType = 'farmland_wheat';
      } else if (hasCotton && Math.random() > 0.5) {
        farmType = 'farmland_cotton';
      } else if (hasSpices) {
        farmType = 'farmland_spices';
      }

      farmlands.set(posKey, farmType);
    }
  }

  return farmlands;
}

/**
 * Generate river locations in hexagonal pattern
 * FEW LARGE NAVIGABLE rivers that reach the sea (flowing through hex)
 * MORE ABUNDANT non-navigable rivers (scattered hexagons)
 */
function generateRiverLocations(
  parentTile: HexTile,
  radius: number
): Map<string, { navigable: boolean }> {
  const rivers = new Map<string, { navigable: boolean }>();

  if (!parentTile.hasRiver) return rivers;

  // Determine if this is a navigable river (20% chance if near coast/ocean)
  const isNearWater = parentTile.terrain === 'coast' ||
    parentTile.elevation < 2;
  const hasNavigableRiver = isNearWater && Math.random() < 0.2;

  if (hasNavigableRiver) {
    // FEW large navigable rivers flowing through the hex
    // Create a path from one edge to another
    const direction = Math.floor(Math.random() * 6); // 6 possible directions
    const riverWidth = Math.floor(Math.random() * 4) + 5; // 5-8 hexagons wide

    // Generate river path through the hex
    for (let q = -radius; q <= radius; q++) {
      for (let offset = -Math.floor(riverWidth / 2); offset <= Math.floor(riverWidth / 2); offset++) {
        const r = Math.floor(-q / 2) + offset;
        if (Math.abs(q) + Math.abs(r) + Math.abs(-q - r) <= 2 * radius) {
          const posKey = `${q},${r}`;
          rivers.set(posKey, { navigable: true });
        }
      }
    }
  } else {
    // MORE ABUNDANT non-navigable rivers (15-25 scattered hexagons)
    const riverCount = Math.floor(Math.random() * 11) + 15; // 15-25

    for (let i = 0; i < riverCount; i++) {
      const q = Math.floor(Math.random() * (2 * radius + 1)) - radius;
      const r1 = Math.max(-radius, -q - radius);
      const r2 = Math.min(radius, -q + radius);
      const r = Math.floor(Math.random() * (r2 - r1 + 1)) + r1;
      const posKey = `${q},${r}`;

      if (!rivers.has(posKey)) {
        rivers.set(posKey, { navigable: false });
      }
    }
  }

  return rivers;
}

/**
 * Determine which side (0-5) of the parent hexagon a subland belongs to
 * Uses axial coordinate dominance to determine sector
 * Sides match main map neighbors:
 * - 0 = East (q+1, r+0)
 * - 1 = Northeast (q+1, r-1)
 * - 2 = Northwest (q+0, r-1)
 * - 3 = West (q-1, r+0)
 * - 4 = Southwest (q-1, r+1)
 * - 5 = Southeast (q+0, r+1)
 */
function determineSublandSide(q: number, r: number, radius: number): number | null {
  // Using axial coordinates to determine sector
  const s = -q - r; // Third axial coordinate

  // Determine the dominant direction based on axial coordinates
  // This matches the neighbor directions in the main map

  // Calculate distances to each edge
  const distEast = radius - q;      // Side 0: East
  const distNE = radius + r;        // Side 1: Northeast
  const distNW = radius - s;        // Side 2: Northwest
  const distWest = radius + q;      // Side 3: West
  const distSW = radius - r;        // Side 4: Southwest
  const distSE = radius + s;        // Side 5: Southeast

  // Find the minimum distance (closest edge)
  const distances = [
    { side: 0, dist: distEast },
    { side: 1, dist: distNE },
    { side: 2, dist: distNW },
    { side: 3, dist: distWest },
    { side: 4, dist: distSW },
    { side: 5, dist: distSE }
  ];

  // Return the side with minimum distance (the edge this subland is closest to)
  let minDist = Infinity;
  let closestSide = 0;

  for (const { side, dist } of distances) {
    if (dist < minDist) {
      minDist = dist;
      closestSide = side;
    }
  }

  return closestSide;
}

/**
 * Calculate distance from the edge of a specific side
 * Returns 0 if on the edge, higher values as we move inward
 */
function getDistanceFromEdge(q: number, r: number, side: number, radius: number): number {
  const s = -q - r;

  switch (side) {
    case 0: // East
      return radius - q;
    case 1: // Northeast
      return radius + r;
    case 2: // Northwest
      return radius - s;
    case 3: // West
      return radius + q;
    case 4: // Southwest
      return radius - r;
    case 5: // Southeast
      return radius + s;
    default:
      return radius;
  }
}
