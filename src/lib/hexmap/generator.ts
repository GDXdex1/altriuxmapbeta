import type { HexTile, MapConfig, ResourceType, TerrainType, AnimalType, MineralType, IslandType, IslandConfig } from './types';
import { isInBounds, getHexKey, createHexCoordinates, calculateLatitude, getHemisphere } from './hex-utils';
import { getSeasonForTile } from './season-system';
import { addTerrainFeatures } from './terrain-features';
import { generateAllRiversImproved as generateAllRivers } from './river-system-improved';

/**
 * Seeded random number generator for deterministic map generation
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

  int(min: number, max: number): number {
    return Math.floor(this.range(min, max + 1));
  }
}

/**
 * Generate Earth-sized hexagonal map with two continents (Drantium & Brontium) and 200 islands
 * NEW GEOGRAPHY:
 * - Drantium (West): Desert divided in half, C-shaped mountain range enclosing desert, river crossing E-W
 * - Brontium (East): Half of Drantium's desert, C-shaped mountain range, central tundra replaced by mountains
 * - Poles: First ice line replaced with tundra
 */
export async function generateEarthMap(seed: number = 42, currentMonth: number = 1): Promise<Map<string, HexTile>> {
  const random = new SeededRandom(seed);

  // Earth configuration: EXPANDED map with more ocean
  // Width: 420 hexes (400 + 20 for expanded ocean between continents)
  // Height: 220 hexes (200 + 10 north + 10 south for expanded polar oceans)
  const config: MapConfig = {
    width: 420,
    height: 220,
    hexSizeKm: 100,
    continents: [
      // Drantium continent (West/left): jungle-based, analogous to America
      // Moved further west to accommodate expanded ocean
      // Moved down 17 units so q:-70, r:17 is at the equator (r:0)
      { centerQ: -70, centerR: -17, width: 70, height: 70, type: 'drantium' },
      // Brontium continent (East/right): forest-based, analogous to Europe
      // Moved further east to accommodate expanded ocean
      { centerQ: 70, centerR: 0, width: 70, height: 70, type: 'brontium' }
    ],
    islands: []
  };

  // Generate 160 specialized islands with improved distribution
  const islands: IslandConfig[] = [];

  // REMOVED: 40 Desert islands - eliminated per user request
  // generateDesertIslandsNearContinentalDeserts(islands, 40, random, config);

  // 40 Tundra islands - ONLY near poles (70-88° latitude), NOT near equator
  // EXPANDED: Adjusted to match new tundra zone (76-88°)
  generateIslandsByType(islands, 40, 'tundra', random, config, {
    latRange: [70, 88],
    minDistFromEquator: 70
  });

  // 40 Jungle islands - ALL on WEST side of meridian (Drantium side), near equator
  generateIslandsByType(islands, 40, 'jungle', random, config, {
    continentSide: 'west',
    latRange: [-20, 20],
    minDistFromPoles: 50
  });

  // 40 Forest islands - on EAST side (Brontium side), temperate latitudes
  generateIslandsByType(islands, 40, 'forest', random, config, {
    continentSide: 'east',
    latRange: [30, 60],
    minDistFromPoles: 35
  });

  // 40 Mountain_range islands - distributed globally, volcanic centers
  generateIslandsByType(islands, 40, 'mountain_range', random, config, {
    minDistFromPoles: 20
  });

  config.islands = islands;

  const tiles = new Map<string, HexTile>();

  // First pass: Generate all hexes with basic terrain
  for (let r = -config.height / 2; r < config.height / 2; r++) {
    for (let q = -config.width / 2; q < config.width / 2; q++) {
      if (!isInBounds(q, r, config.width, config.height)) continue;

      // Calculate latitude and hemisphere
      const latitude = calculateLatitude(r, config.height);
      const absLat = Math.abs(latitude);
      const hemisphere = getHemisphere(latitude);

      // Get season for this tile based on current month
      const seasonInfo = getSeasonForTile(currentMonth, latitude);

      // NEW: Check if polar tundra zone (first line replacing ice) - between 76° and 88°
      // EXPANDED: 6 degrees wider toward equator on each pole
      // BUT: Do NOT place tundra inside continents or near their islands
      const isPolarTundra = absLat > 76 && absLat <= 88;

      // Ice cap only at extreme poles (>88°)
      const isIceCap = absLat > 88;

      // Check if this hex is in a continent
      const continent = config.continents.find(cont =>
        isInContinent(q, r, cont, random)
      );

      // Check if this hex is in an island
      const island = !continent && config.islands.find(isl =>
        isInIsland(q, r, isl)
      );

      // Determine terrain and climate
      let elevation = 0;
      let terrain: TerrainType = 'ocean';

      if (isIceCap) {
        terrain = 'ice';
        elevation = 0;
      } else if (isPolarTundra && !continent && !island) {
        // Only place tundra in open ocean, NOT in continents or islands
        terrain = 'tundra';
        elevation = 0;
      } else if (continent || island) {
        elevation = calculateElevation(q, r, continent, island, random);
        terrain = determineTerrain(latitude, elevation, random, continent?.type, island?.type);
      }

      const temperature = calculateTemperature(latitude, elevation);
      const rainfall = calculateRainfall(latitude, random);

      tiles.set(getHexKey(q, r), {
        coordinates: createHexCoordinates(q, r),
        terrain,
        features: [], // Initialize empty features array
        resources: [],
        animals: [],
        minerals: [],
        elevation,
        temperature,
        rainfall,
        hasVolcano: false,
        hasRiver: false,
        continent: continent?.type || island?.type as any, // Ensure continent is assigned
        season: seasonInfo.season,
        latitude,
        hemisphere
      });
    }
  }

  // Second pass: Add DIVIDED desert zones (50% Drantium, 50% Brontium)
  addDividedDesertZones(tiles, config, random);

  // Third pass: Add C-shaped mountain ranges that enclose deserts
  addCShapedMountainRanges(tiles, config, random);

  // Fourth pass: Replace central tundra in Brontium with mountains and forests
  replaceCentralTundraWithMountainsAndForests(tiles, config, random);

  // Fifth pass: Add MASSIVE jungle expansion in central Drantium
  addMassiveJungleExpansion(tiles, config, random);

  // Sixth pass: Add 100 volcanoes (EXACTLY 100)
  addVolcanoes(tiles, config, random);

  // RESOURCES REMOVED: No minerals, animals, or food resources
  // Only terrain features (forest, jungle, oasis, volcano, boreal forest)

  // Ninth pass: Convert ocean tiles adjacent to land into coast
  addCoastalTiles(tiles, config);

  // NEW: Clean up all existing oasis features before regeneration
  cleanupOasisFeatures(tiles);

  // Fourteenth pass: Add terrain features (forest in Brontium, jungle in Drantium)
  // This must happen AFTER all terrain is set but BEFORE resources that depend on features
  addTerrainFeatures(tiles, config, random);

  // Fifteenth pass: CONSISTENCY CLEANUP - Remove isolated tiles and make deserts compact
  cleanupInlandCoastTiles(tiles, config);
  makeDesertsCompact(tiles, config);
  smoothTerrainNoise(tiles, config);

  // Sixteenth pass: Ensure all mountain_ranges (cordilleras) have hills or mountains around them
  ensureMountainRangeNeighbors(tiles, config);

  // Analysis removed - kept internal only

  // CRITICAL DEBUG: Check for mountain_range tiles before generating rivers
  console.log('🔍🔍🔍 PRE-RIVER GENERATION CHECK 🔍🔍🔍');
  let mountainCount = 0;
  const sampleMountains: string[] = [];
  for (const [key, tile] of tiles) {
    if (tile.terrain === 'mountain_range') {
      mountainCount++;
      if (sampleMountains.length < 5) {
        sampleMountains.push(`(${tile.coordinates.q}, ${tile.coordinates.r})`);
      }
    }
  }
  console.log(`   Found ${mountainCount} mountain_range tiles BEFORE river generation`);
  console.log(`   Sample mountains:`, sampleMountains.join(', '));

  // CRITICAL: Generate rivers AFTER all terrain is finalized
  // Rivers MUST start in mountain_range (cordillera) and end in coast
  // Generate EXACTLY 40 rivers
  console.log('🚀🚀🚀 CALLING generateAllRivers() 🚀🚀🚀');

  let rivers: any[] = [];
  try {
    rivers = generateAllRivers(tiles, {
      minLength: 4,  // Reduced further from 8 to 4 to ensure more success in river generation
      maxAttempts: 200, // Increased attempts for better coverage
      flowToOcean: true,
      allowLakes: false
    }, 40); // Target: 40 rivers

    console.log(`✅ generateAllRivers() returned successfully with ${rivers.length} rivers`);
  } catch (error) {
    console.error('❌❌❌ ERROR calling generateAllRivers:', error);
    console.error('Error details:', error instanceof Error ? error.message : String(error));
    console.error('Stack trace:', error instanceof Error ? error.stack : 'No stack trace');
  }

  // Extract all river edges (borders where rivers flow)
  // Rivers are rendered as LINES on the EDGES between hexagons, NOT as overlays
  const riverEdges = rivers.flatMap(river => river.edges || []);

  console.log(`✅✅✅ RIVERS GENERATED ✅✅✅`);
  console.log(`   Total rivers generated: ${rivers.length}`);
  console.log(`   Total river edges (borders): ${riverEdges.length}`);
  console.log(`   Average river length: ${rivers.length > 0 ? (riverEdges.length / rivers.length).toFixed(1) : 0} segments`);

  // CRITICAL DEBUG: Verify tiles were marked with 'river' feature
  let tilesWithRiverFeature = 0;
  for (const [key, tile] of tiles) {
    if (tile.features?.includes('river')) {
      tilesWithRiverFeature++;
    }
  }
  console.log(`   Tiles marked with 'river' feature: ${tilesWithRiverFeature}`);

  // Store river edges in the map metadata (we'll attach to return value)
  (tiles as any).__riverEdges = riverEdges;

  return tiles;
}



/**
 * NEW: Add DIVIDED desert zones - 50% in Drantium, 50% in Brontium
 */
function addDividedDesertZones(tiles: Map<string, HexTile>, config: MapConfig, random: SeededRandom): void {
  let landTileCount = 0;
  for (const [, tile] of tiles) {
    if (tile.terrain !== 'ocean' && tile.terrain !== 'ice' && tile.terrain !== 'coast') {
      landTileCount++;
    }
  }

  const targetDesertTiles = Math.floor(landTileCount * 0.20);
  const desertPerContinent = Math.floor(targetDesertTiles / 2);

  // DRANTIUM: Half of total desert - East side of continent
  // Adjusted for new continent position (centerR = -17)
  const drantiumContinent = config.continents.find(c => c.type === 'drantium');
  if (drantiumContinent) {
    const desertCenterQ = drantiumContinent.centerQ + 20;
    const desertCenterR = drantiumContinent.centerR + 27; // Adjusted: was +10, now +27 (10 + 17)
    const desertRadius = Math.sqrt(desertPerContinent * 1.5);

    addDesertCluster(tiles, desertCenterQ, desertCenterR, desertRadius, desertPerContinent, 'drantium', random);
  }

  // BRONTIUM: Other half - West side of continent
  const brontiumContinent = config.continents.find(c => c.type === 'brontium');
  if (brontiumContinent) {
    const desertCenterQ = brontiumContinent.centerQ - 20;
    const desertCenterR = brontiumContinent.centerR + 15;
    const desertRadius = Math.sqrt(desertPerContinent * 1.5);

    addDesertCluster(tiles, desertCenterQ, desertCenterR, desertRadius, desertPerContinent, 'brontium', random);
  }
}

/**
 * Helper: Add desert cluster at specific location
 */
function addDesertCluster(
  tiles: Map<string, HexTile>,
  centerQ: number,
  centerR: number,
  radius: number,
  maxTiles: number,
  continentType: 'drantium' | 'brontium',
  random: SeededRandom
): void {
  let desertCount = 0;

  for (let r = centerR - radius; r < centerR + radius && desertCount < maxTiles; r++) {
    for (let q = centerQ - radius; q < centerQ + radius && desertCount < maxTiles; q++) {
      const key = getHexKey(Math.round(q), Math.round(r));
      const tile = tiles.get(key);

      if (tile &&
        tile.terrain !== 'ocean' &&
        tile.terrain !== 'ice' &&
        tile.terrain !== 'coast' &&
        tile.terrain !== 'mountain_range' &&
        tile.continent === continentType) {

        const dq = q - centerQ;
        const dr = r - centerR;
        const dist = Math.sqrt(dq * dq + dr * dr);
        const threshold = radius * random.range(0.8, 1.1);

        if (dist < threshold) {
          tile.terrain = 'desert';
          tile.rainfall = random.range(5, 25);
          desertCount++;
        }
      }
    }
  }
}

/**
 * NEW: Add C-shaped mountain ranges that enclose deserts toward coasts
 */
function addCShapedMountainRanges(tiles: Map<string, HexTile>, config: MapConfig, random: SeededRandom): void {
  // DRANTIUM: C-shaped range enclosing desert on EAST side (opening toward east coast)
  // Adjusted for new continent position (centerR = -17)
  const drantiumContinent = config.continents.find(c => c.type === 'drantium');
  if (drantiumContinent) {
    const centerQ = drantiumContinent.centerQ + 20;
    const centerR = drantiumContinent.centerR + 27; // Adjusted: was +10, now +27 (10 + 17)

    // C shape: West arc + North arc + South arc (opening toward east)
    addMountainArc(tiles, centerQ - 15, centerR, 20, 0, Math.PI, 'drantium', random); // West arc
    addMountainArc(tiles, centerQ - 8, centerR - 15, 12, -Math.PI / 2, Math.PI / 2, 'drantium', random); // North arc
    addMountainArc(tiles, centerQ - 8, centerR + 15, 12, -Math.PI / 2, Math.PI / 2, 'drantium', random); // South arc
  }

  // BRONTIUM: C-shaped range enclosing desert on WEST side (opening toward west coast)
  const brontiumContinent = config.continents.find(c => c.type === 'brontium');
  if (brontiumContinent) {
    const centerQ = brontiumContinent.centerQ - 20;
    const centerR = brontiumContinent.centerR + 15;

    // C shape mirrored: East arc + North arc + South arc (opening toward west)
    addMountainArc(tiles, centerQ + 15, centerR, 20, -Math.PI, 0, 'brontium', random); // East arc
    addMountainArc(tiles, centerQ + 8, centerR - 15, 12, Math.PI / 2, 3 * Math.PI / 2, 'brontium', random); // North arc
    addMountainArc(tiles, centerQ + 8, centerR + 15, 12, Math.PI / 2, 3 * Math.PI / 2, 'brontium', random); // South arc
  }
}

/**
 * Helper: Add mountain arc
 */
function addMountainArc(
  tiles: Map<string, HexTile>,
  centerQ: number,
  centerR: number,
  radius: number,
  startAngle: number,
  endAngle: number,
  continentType: 'drantium' | 'brontium',
  random: SeededRandom
): void {
  const points = 50;
  const thickness = 3;

  for (let i = 0; i < points; i++) {
    const angle = startAngle + (endAngle - startAngle) * (i / points);

    for (let t = 0; t < thickness; t++) {
      const r = radius + random.range(-2, 2) + t;
      const q = Math.round(centerQ + Math.cos(angle) * r);
      const rCoord = Math.round(centerR + Math.sin(angle) * r);

      const key = getHexKey(q, rCoord);
      const tile = tiles.get(key);

      if (tile && tile.continent === continentType && tile.terrain !== 'ocean' && tile.terrain !== 'ice') {
        tile.terrain = 'mountain_range';
        tile.elevation = random.range(7, 10);
      }
    }
  }
}

/**
 * NEW: Replace central tundra in Brontium with mountains and forests on foothills
 */
function replaceCentralTundraWithMountainsAndForests(tiles: Map<string, HexTile>, config: MapConfig, random: SeededRandom): void {
  const brontiumContinent = config.continents.find(c => c.type === 'brontium');
  if (!brontiumContinent) return;

  const centerQ = brontiumContinent.centerQ;
  const centerR = brontiumContinent.centerR;
  const mountainRadius = 15;
  const forestRadius = 25;

  for (const [, tile] of tiles) {
    if (tile.continent !== 'brontium') continue;

    const dq = tile.coordinates.q - centerQ;
    const dr = tile.coordinates.r - centerR;
    const dist = Math.sqrt(dq * dq + dr * dr);

    // Central mountains
    if (dist < mountainRadius && tile.terrain === 'tundra') {
      tile.terrain = 'mountain_range';
      tile.elevation = random.range(6, 9);
    }

    // Meadows/hills on foothills (forest feature added later)
    if (dist >= mountainRadius && dist < forestRadius && tile.terrain === 'tundra') {
      tile.terrain = tile.elevation >= 3 ? 'hills' : 'meadow';
      tile.elevation = random.range(2, 5);
    }
  }
}

/**
 * NEW: Add MASSIVE jungle expansion in central Drantium
 */
function addMassiveJungleExpansion(tiles: Map<string, HexTile>, config: MapConfig, random: SeededRandom): void {
  const drantiumContinent = config.continents.find(c => c.type === 'drantium');
  if (!drantiumContinent) return;

  const centerQ = drantiumContinent.centerQ;
  const centerR = drantiumContinent.centerR;
  const jungleRadius = 30;

  let jungleAdded = 0;

  for (const [, tile] of tiles) {
    if (tile.continent !== 'drantium') continue;
    if (tile.terrain === 'mountain_range' || tile.terrain === 'desert') continue;

    const dq = tile.coordinates.q - centerQ;
    const dr = tile.coordinates.r - centerR;
    const dist = Math.sqrt(dq * dq + dr * dr);

    // Massive meadow/hills in center (jungle feature added later)
    if (dist < jungleRadius) {
      const jungleChance = 1 - (dist / jungleRadius);
      if (random.next() < jungleChance * 0.8) {
        tile.terrain = tile.elevation >= 3 ? 'hills' : 'meadow';
        tile.rainfall = random.range(80, 150);
        jungleAdded++;
      }
    }
  }

  // Jungle expansion complete
}



/**
 * Generate desert islands clustered near BOTH continental deserts
 */
function generateDesertIslandsNearContinentalDeserts(
  islands: IslandConfig[],
  count: number,
  random: SeededRandom,
  config: MapConfig
): void {
  const halfCount = Math.floor(count / 2);

  // Half near Drantium desert (adjusted for new continent position)
  // Desert center is now at approximately r:10 (was r:-7, now adjusted to r:10 = -17 + 27)
  generateDesertIslandCluster(islands, halfCount, -50, 10, 50, random, config);

  // Half near Brontium desert (adjusted for new continent position)
  generateDesertIslandCluster(islands, count - halfCount, 50, 15, 50, random, config);
}

/**
 * Helper: Generate desert island cluster
 */
function generateDesertIslandCluster(
  islands: IslandConfig[],
  count: number,
  centerQ: number,
  centerR: number,
  radius: number,
  random: SeededRandom,
  config: MapConfig
): void {
  const attempts = count * 100;
  let created = 0;

  for (let i = 0; i < attempts && created < count; i++) {
    const angle = random.range(0, Math.PI * 2);
    const distance = random.range(10, radius);
    const q = Math.round(centerQ + Math.cos(angle) * distance);
    const r = Math.round(centerR + Math.sin(angle) * distance);

    const tooCloseToContinent = config.continents.some(cont => {
      const dq = q - cont.centerQ;
      const dr = r - cont.centerR;
      const dist = Math.sqrt(dq * dq + dr * dr);
      return dist < 35;
    });

    const tooCloseToIsland = islands.some(island => {
      const dq = q - island.centerQ;
      const dr = r - island.centerR;
      const dist = Math.sqrt(dq * dq + dr * dr);
      return dist < 8;
    });

    if (!tooCloseToContinent && !tooCloseToIsland && isInBounds(q, r, config.width, config.height)) {
      islands.push({ centerQ: q, centerR: r, type: 'desert' });
      created++;
    }
  }
}

/**
 * Generate islands with strict placement constraints
 */
function generateIslandsByType(
  islands: IslandConfig[],
  count: number,
  type: IslandType,
  random: SeededRandom,
  config: MapConfig,
  constraints: {
    latRange?: [number, number];
    continentSide?: 'east' | 'west';
    minDistFromPoles?: number;
    minDistFromEquator?: number;
  }
): void {
  const attempts = count * 100;

  for (let i = 0; i < attempts && islands.filter(isl => isl.type === type).length < count; i++) {
    let q = random.int(-180, 180);
    let r = random.int(-90, 90);

    if (constraints.latRange) {
      const [minLat, maxLat] = constraints.latRange;
      const targetR = random.range(minLat, maxLat) / 180 * config.height;
      r = Math.round(targetR * (random.next() > 0.5 ? 1 : -1));
    }

    if (constraints.continentSide === 'east') {
      q = Math.abs(q);
    } else if (constraints.continentSide === 'west') {
      q = -Math.abs(q);
    }

    if (constraints.minDistFromPoles) {
      const poleDistNorth = Math.abs(r - config.height / 2);
      const poleDistSouth = Math.abs(r + config.height / 2);
      if (poleDistNorth < constraints.minDistFromPoles && poleDistSouth < constraints.minDistFromPoles) {
        continue;
      }
    }

    if (constraints.minDistFromEquator) {
      if (Math.abs(r) < constraints.minDistFromEquator / 180 * config.height) {
        continue;
      }
    }

    const tooCloseToContinent = config.continents.some(cont => {
      const dq = q - cont.centerQ;
      const dr = r - cont.centerR;
      const dist = Math.sqrt(dq * dq + dr * dr);
      return dist < 40;
    });

    const tooCloseToIsland = islands.some(island => {
      const dq = q - island.centerQ;
      const dr = r - island.centerR;
      const dist = Math.sqrt(dq * dq + dr * dr);
      return dist < 10;
    });

    if (!tooCloseToContinent && !tooCloseToIsland && isInBounds(q, r, config.width, config.height)) {
      islands.push({ centerQ: q, centerR: r, type });
    }
  }
}

/**
 * Check if hex is within continent boundaries
 */
function isInContinent(
  q: number,
  r: number,
  continent: { centerQ: number; centerR: number; width: number; height: number },
  random: SeededRandom
): boolean {
  const dq = q - continent.centerQ;
  const dr = r - continent.centerR;

  const normalizedDist =
    (dq * dq) / ((continent.width / 2) ** 2) +
    (dr * dr) / ((continent.height / 2) ** 2);

  const noise = random.range(0.7, 1.3);

  return normalizedDist * noise < 1;
}

/**
 * Check if hex is within island boundaries (2x2 tiles)
 */
function isInIsland(
  q: number,
  r: number,
  island: IslandConfig
): boolean {
  const dq = Math.abs(q - island.centerQ);
  const dr = Math.abs(r - island.centerR);

  return dq <= 1 && dr <= 1;
}

/**
 * Calculate elevation based on position
 */
function calculateElevation(
  q: number,
  r: number,
  continent: { centerQ: number; centerR: number; width: number; height: number; type: string } | undefined,
  island: IslandConfig | undefined,
  random: SeededRandom
): number {
  if (island?.type === 'mountain_range') {
    return random.range(7, 10);
  }

  if (continent) {
    const dq = q - continent.centerQ;
    const dr = r - continent.centerR;
    const distFromCenter = Math.sqrt(dq * dq + dr * dr);
    const normalizedDist = distFromCenter / (continent.width / 2);

    if (normalizedDist < 0.3) {
      return random.range(5, 8);
    } else if (normalizedDist < 0.6) {
      return random.range(2, 5);
    } else {
      return random.range(1, 3);
    }
  }

  return random.range(1, 4);
}

/**
 * Calculate temperature based on latitude and elevation
 */
function calculateTemperature(latitude: number, elevation: number): number {
  const baseTemp = 30 - Math.abs(latitude) * 0.6;
  const elevationEffect = -(elevation * 6);
  return baseTemp + elevationEffect;
}

/**
 * Calculate rainfall based on latitude
 */
function calculateRainfall(latitude: number, random: SeededRandom): number {
  const latEffect = Math.abs(latitude);
  let rainfall: number;

  if (latEffect < 20) {
    rainfall = random.range(60, 100);
  } else if (latEffect < 40) {
    rainfall = random.range(20, 60);
  } else if (latEffect < 60) {
    rainfall = random.range(40, 80);
  } else {
    rainfall = random.range(10, 40);
  }

  return rainfall;
}

/**
 * Determine terrain type based on climate, elevation, and continent type
 */
function determineTerrain(
  latitude: number,
  elevation: number,
  random: SeededRandom,
  continentType?: 'drantium' | 'brontium',
  islandType?: IslandType
): TerrainType {
  const temperature = 30 - Math.abs(latitude) * 0.6 - elevation * 6;
  const rainfall = Math.abs(latitude) < 20 ? 80 : 50;

  // Islands: Return base terrain, features added separately
  if (islandType === 'mountain_range') return 'mountain_range';
  if (islandType === 'desert') return 'desert';
  if (islandType === 'tundra') return 'tundra';
  if (islandType === 'jungle') return 'meadow'; // Jungle as feature, meadow as base
  if (islandType === 'forest') return 'hills'; // Forest as feature, hills as base

  if (elevation >= 6) {
    // NEVER return tundra for continental or island land - always mountain_range (cordillera)
    return 'mountain_range';
  }

  // REMOVED: No tundra terrain inside continents or islands
  // Tundra only exists in polar ocean zones

  // NEW SYSTEM: Return base terrain (meadow/hills/plains), features added separately

  if (continentType === 'drantium') {
    // Drantium: More tropical/humid climate
    if (temperature > 20 && rainfall > 60) {
      // High rainfall tropical areas - meadow/hills (jungle feature added later)
      return elevation >= 3 ? 'hills' : 'meadow';
    } else if (temperature > 15 && rainfall > 40) {
      // Moderate climate - hills in higher elevations
      return elevation >= 2 ? 'hills' : 'meadow';
    }
    return 'plains';
  }

  if (continentType === 'brontium') {
    // Brontium: More temperate climate
    if (temperature > 5 && temperature < 25 && rainfall > 50) {
      // Temperate forest zone - meadow/hills (forest feature added later)
      return elevation >= 3 ? 'hills' : 'meadow';
    } else if (elevation >= 2 && temperature > 0) {
      // Hilly temperate areas
      return 'hills';
    } else if (rainfall > 40) {
      // Wetter areas become meadows
      return 'meadow';
    }
    return 'plains';
  }

  // General terrain logic for islands
  if (temperature > 25 && rainfall < 30) {
    return 'desert';
  }

  if (temperature > 20 && rainfall > 70) {
    // Tropical humid - meadow/hills (jungle feature added later)
    return elevation >= 3 ? 'hills' : 'meadow';
  }

  if (temperature > 5 && temperature < 25 && rainfall > 50) {
    // Temperate humid - meadow/hills (forest feature added later)
    return elevation >= 3 ? 'hills' : 'meadow';
  }

  // Elevation-based terrain for moderate climates
  if (elevation >= 2 && rainfall > 30) {
    return 'hills';
  }

  if (rainfall > 50) {
    return 'meadow';
  }

  return 'plains';
}

/**
 * Add EXACTLY 100 volcanoes across the map
 */
function addVolcanoes(tiles: Map<string, HexTile>, config: MapConfig, random: SeededRandom): void {
  let volcanoCount = 0;
  const targetVolcanoes = 100;

  const mountainIslands = config.islands.filter(isl => isl.type === 'mountain_range');
  for (const island of mountainIslands) {
    const key = getHexKey(island.centerQ, island.centerR);
    const tile = tiles.get(key);
    if (tile) {
      tile.hasVolcano = true;
      tile.terrain = 'mountain_range';
      tile.elevation = 10;
      // REMOVED: No mineral deposits
      volcanoCount++;
    }
  }

  const attempts = targetVolcanoes * 20;
  for (let i = 0; i < attempts && volcanoCount < targetVolcanoes; i++) {
    const q = random.int(-config.width / 2, config.width / 2);
    const r = random.int(-config.height / 2, config.height / 2);
    const key = getHexKey(q, r);
    const tile = tiles.get(key);

    if (tile &&
      (tile.terrain === 'mountain_range' || tile.elevation >= 6) &&
      !tile.hasVolcano &&
      tile.terrain !== 'ice') {
      tile.hasVolcano = true;
      // REMOVED: No mineral deposits
      volcanoCount++;
    }
  }
}



/**
 * Add mineral deposits based on geological logic
 */
function addMineralDeposits(tiles: Map<string, HexTile>, config: MapConfig, random: SeededRandom): void {
  const deposits = {
    silver: { target: 3000, count: 0, terrains: ['mountain_range', 'desert', 'tundra'] },
    iron: { target: 10000, count: 0, terrains: ['mountain_range', 'plains', 'forest', 'desert'] },
    tin: { target: 10000, count: 0, terrains: ['mountain_range', 'plains', 'forest'] },
    bronze: { target: 4000, count: 0, terrains: ['mountain_range', 'plains'] },
    gold: { target: 500, count: 0, terrains: ['mountain_range', 'desert'] }
  };

  const maxAttempts = 100000;

  for (let i = 0; i < maxAttempts; i++) {
    const q = random.int(-config.width / 2, config.width / 2);
    const r = random.int(-config.height / 2, config.height / 2);
    const key = getHexKey(q, r);
    const tile = tiles.get(key);

    if (!tile || tile.terrain === 'ocean' || tile.terrain === 'ice' || tile.terrain === 'coast') continue;

    // Check total resource count before adding minerals
    const totalResources = tile.animals.length + tile.minerals.length + tile.resources.length;
    if (totalResources >= 2) continue; // Maximum 2 resources per tile

    for (const [mineral, data] of Object.entries(deposits)) {
      if (data.count >= data.target) continue;

      // Re-check after each mineral addition
      const currentTotal = tile.animals.length + tile.minerals.length + tile.resources.length;
      if (currentTotal >= 2) break;

      if (data.terrains.includes(tile.terrain)) {
        const chance = tile.elevation > 5 ? 0.05 : 0.02;
        if (random.next() < chance && !tile.minerals.includes(mineral as MineralType)) {
          tile.minerals.push(mineral as MineralType);
          data.count++;
        }
      }
    }

    if (Object.values(deposits).every(d => d.count >= d.target)) break;
  }
}

/**
 * Add animals based on biome
 */
function addAnimals(tiles: Map<string, HexTile>, config: MapConfig, random: SeededRandom): void {
  for (const [, tile] of tiles) {
    if (tile.terrain === 'ocean' || tile.terrain === 'ice' || tile.terrain === 'coast') continue;

    const animalChances: Record<string, Array<{ type: AnimalType; chance: number }>> = {
      plains: [
        { type: 'horses', chance: 0.3 },
        { type: 'buffalo', chance: 0.25 },
        { type: 'sheep', chance: 0.2 }
      ],
      jungle: [
        { type: 'buffalo', chance: 0.2 }
      ],
      forest: [
        { type: 'horses', chance: 0.15 },
        { type: 'sheep', chance: 0.2 }
      ],
      mountain_range: [
        { type: 'muffon', chance: 0.4 },
        { type: 'sheep', chance: 0.25 }
      ],
      tundra: [
        { type: 'yaks', chance: 0.5 },
        { type: 'muffon', chance: 0.2 }
      ],
      desert: [
        { type: 'horses', chance: 0.1 },
        { type: 'camels', chance: 0.35 }
      ]
    };

    const chances = animalChances[tile.terrain as string] || [];

    for (const { type, chance } of chances) {
      // Check total resource count (animals + minerals + resources) before adding
      const totalResources = tile.animals.length + tile.minerals.length + tile.resources.length;
      if (totalResources >= 2) break; // Maximum 2 resources per tile

      if (random.next() < chance) {
        tile.animals.push(type);
      }
    }
  }
}

/**
 * CONTROLLED food resource distribution
 * Rule: 1 food resource per 5 land tiles, 1 per 10 water tiles
 */
function addFoodResourcesControlled(tiles: Map<string, HexTile>, config: MapConfig, random: SeededRandom): void {
  const landTiles: HexTile[] = [];
  const waterTiles: HexTile[] = [];

  for (const [, tile] of tiles) {
    if (tile.terrain === 'ocean' || tile.terrain === 'coast') {
      waterTiles.push(tile);
    } else if (tile.terrain !== 'ice') {
      landTiles.push(tile);
    }
  }

  const targetLandFood = Math.floor(landTiles.length / 5);
  const targetWaterFood = Math.floor(waterTiles.length / 10);

  shuffleArray(landTiles, random);
  shuffleArray(waterTiles, random);

  let landFoodPlaced = 0;
  for (const tile of landTiles) {
    if (landFoodPlaced >= targetLandFood) break;

    const foodOptions: ResourceType[] = [];

    if (tile.terrain === 'plains') {
      foodOptions.push('wheat');
      if (tile.continent === 'brontium' || tile.continent === 'drantium') {
        foodOptions.push('legumes');
      }
    } else if (tile.terrain === 'jungle') {
      foodOptions.push('spices', 'wood');
      if (tile.continent === 'drantium') {
        foodOptions.push('corn');
      }
    } else if (tile.terrain === 'forest') {
      foodOptions.push('wood');
      if (tile.continent === 'brontium') {
        foodOptions.push('flax');
      }
      if (tile.continent === 'brontium' || tile.continent === 'drantium') {
        foodOptions.push('legumes');
      }
    } else if (tile.terrain === 'mountain_range') {
      foodOptions.push('stone');
    } else if (tile.terrain === 'desert') {
      // ARID DESERT: Only dates (primary) and occasionally stone (no wood)
      // Minerals and camels are added separately by other functions
      foodOptions.push('dates');
      if (random.next() < 0.3) {
        foodOptions.push('stone');
      }
    }

    // Check total resource count before adding food
    const totalResources = tile.animals.length + tile.minerals.length + tile.resources.length;
    if (totalResources >= 2) continue; // Maximum 2 resources per tile

    if (foodOptions.length > 0) {
      const chosenFood = foodOptions[random.int(0, foodOptions.length - 1)];
      if (!tile.resources.includes(chosenFood)) {
        tile.resources.push(chosenFood);
        landFoodPlaced++;
      }
    }
  }

  let waterFoodPlaced = 0;
  for (const tile of waterTiles) {
    if (waterFoodPlaced >= targetWaterFood) break;

    // Check total resource count before adding marine resources
    const totalResources = tile.animals.length + tile.minerals.length + tile.resources.length;
    if (totalResources >= 2) continue; // Maximum 2 resources per tile

    const foodType: ResourceType = random.next() > 0.3 ? 'fish' : (random.next() > 0.5 ? 'whales' : 'crabs');
    if (!tile.resources.includes(foodType)) {
      tile.resources.push(foodType);
      waterFoodPlaced++;
    }
  }
}

/**
 * Shuffle array in place using seeded random
 */
function shuffleArray<T>(array: T[], random: SeededRandom): void {
  for (let i = array.length - 1; i > 0; i--) {
    const j = random.int(0, i);
    [array[i], array[j]] = [array[j], array[i]];
  }
}

/**
 * Get which sides (0-5) of a coastal hex touch land (not ocean/ice)
 * Used to determine where to place coastal land in sublands
 * Returns array of side indices: [0, 1, 5] means sides 0, 1, and 5 touch land
 */
export function getCoastalLandSides(tile: HexTile, tiles: Map<string, HexTile>): number[] {
  // The 6 neighbors in order (clockwise from East)
  const neighbors = [
    { q: +1, r: 0, side: 0 }, // East
    { q: +1, r: -1, side: 1 }, // Northeast
    { q: 0, r: -1, side: 2 }, // Northwest
    { q: -1, r: 0, side: 3 }, // West
    { q: -1, r: +1, side: 4 }, // Southwest
    { q: 0, r: +1, side: 5 }  // Southeast
  ];

  const landSides: number[] = [];

  for (const n of neighbors) {
    const neighborKey = getHexKey(
      tile.coordinates.q + n.q,
      tile.coordinates.r + n.r
    );
    const neighbor = tiles.get(neighborKey);

    // If the neighbor is land (not ocean, coast, or ice)
    if (neighbor &&
      neighbor.terrain !== 'ocean' &&
      neighbor.terrain !== 'coast' &&
      neighbor.terrain !== 'ice') {
      landSides.push(n.side);
    }
  }

  return landSides;
}

/**
 * Get which sides (0-5) of ANY hex touch ocean or coast
 * Used to determine where to place coastal inland areas in sublands
 * Returns array of side indices: [0, 1, 5] means sides 0, 1, and 5 touch ocean/coast
 */
export function getOceanNeighborSides(tile: HexTile, tiles: Map<string, HexTile>): number[] {
  // The 6 neighbors in order (clockwise from East)
  const neighbors = [
    { q: +1, r: 0, side: 0 }, // East
    { q: +1, r: -1, side: 1 }, // Northeast
    { q: 0, r: -1, side: 2 }, // Northwest
    { q: -1, r: 0, side: 3 }, // West
    { q: -1, r: +1, side: 4 }, // Southwest
    { q: 0, r: +1, side: 5 }  // Southeast
  ];

  const oceanSides: number[] = [];

  for (const n of neighbors) {
    const neighborKey = getHexKey(
      tile.coordinates.q + n.q,
      tile.coordinates.r + n.r
    );
    const neighbor = tiles.get(neighborKey);

    // If the neighbor is ocean OR coast (both count as water)
    if (neighbor && (neighbor.terrain === 'ocean' || neighbor.terrain === 'coast')) {
      oceanSides.push(n.side);
    }
  }

  return oceanSides;
}

/**
 * Convert ocean tiles adjacent to land into coastal tiles
 * EXPORTED: Can be called after user modifications to regenerate coasts
 * VALIDATION: Ensures all coastal tiles have at least one land neighbor (no orphaned coasts)
 */
export function addCoastalTiles(tiles: Map<string, HexTile>, config: MapConfig): void {
  const tilesToConvert: string[] = [];

  // First pass: Convert ocean tiles adjacent to land into coast
  for (const [key, tile] of tiles) {
    if (tile.terrain !== 'ocean') continue;

    const neighbors = [
      { q: tile.coordinates.q + 1, r: tile.coordinates.r },
      { q: tile.coordinates.q - 1, r: tile.coordinates.r },
      { q: tile.coordinates.q, r: tile.coordinates.r + 1 },
      { q: tile.coordinates.q, r: tile.coordinates.r - 1 },
      { q: tile.coordinates.q + 1, r: tile.coordinates.r - 1 },
      { q: tile.coordinates.q - 1, r: tile.coordinates.r + 1 }
    ];

    const hasLandNeighbor = neighbors.some(n => {
      const neighborKey = getHexKey(n.q, n.r);
      const neighborTile = tiles.get(neighborKey);
      return neighborTile && neighborTile.terrain !== 'ocean' && neighborTile.terrain !== 'ice';
    });

    if (hasLandNeighbor) {
      tilesToConvert.push(key);
    }
  }

  // Convert ocean to coast
  for (const key of tilesToConvert) {
    const tile = tiles.get(key);
    if (tile) {
      tile.terrain = 'coast';
    }
  }

  // Second pass: Validate that all coastal tiles have at least one land neighbor
  // Remove orphaned coasts (coasts without land neighbors)
  const orphanedCoasts: string[] = [];

  for (const [key, tile] of tiles) {
    if (tile.terrain !== 'coast') continue;

    const neighbors = [
      { q: tile.coordinates.q + 1, r: tile.coordinates.r },
      { q: tile.coordinates.q - 1, r: tile.coordinates.r },
      { q: tile.coordinates.q, r: tile.coordinates.r + 1 },
      { q: tile.coordinates.q, r: tile.coordinates.r - 1 },
      { q: tile.coordinates.q + 1, r: tile.coordinates.r - 1 },
      { q: tile.coordinates.q - 1, r: tile.coordinates.r + 1 }
    ];

    const hasLandNeighbor = neighbors.some(n => {
      const neighborKey = getHexKey(n.q, n.r);
      const neighborTile = tiles.get(neighborKey);
      // Land = not ocean, not coast, not ice
      return neighborTile &&
        neighborTile.terrain !== 'ocean' &&
        neighborTile.terrain !== 'coast' &&
        neighborTile.terrain !== 'ice';
    });

    // If no land neighbor, mark as orphaned
    if (!hasLandNeighbor) {
      orphanedCoasts.push(key);
    }
  }

  // Convert orphaned coasts back to ocean
  for (const key of orphanedCoasts) {
    const tile = tiles.get(key);
    if (tile) {
      tile.terrain = 'ocean';
    }
  }
}

/**
 * Add marine resources to coastal tiles
 */
function addMarineResources(tiles: Map<string, HexTile>, config: MapConfig, random: SeededRandom): void {
  // Marine resources are now handled by addFoodResourcesControlled
}

/**
 * CLEANUP: Remove all oasis features from non-desert tiles
 * This ensures oasis only exists in desert terrain
 */
function cleanupOasisFeatures(tiles: Map<string, HexTile>): void {
  for (const [, tile] of tiles) {
    if (tile.features && tile.features.length > 0) {
      // Remove oasis from all tiles (will be regenerated only in deserts)
      tile.features = tile.features.filter(feature => feature !== 'oasis');
    }
  }
}

/**
 * CONSISTENCY CLEANUP: Remove inland coast tiles (coast surrounded by land)
 */
function cleanupInlandCoastTiles(tiles: Map<string, HexTile>, config: MapConfig): void {
  const tilesToConvert: Array<{ key: string; newTerrain: TerrainType }> = [];

  for (const [key, tile] of tiles) {
    if (tile.terrain !== 'coast') continue;

    const neighbors = [
      { q: tile.coordinates.q + 1, r: tile.coordinates.r },
      { q: tile.coordinates.q - 1, r: tile.coordinates.r },
      { q: tile.coordinates.q, r: tile.coordinates.r + 1 },
      { q: tile.coordinates.q, r: tile.coordinates.r - 1 },
      { q: tile.coordinates.q + 1, r: tile.coordinates.r - 1 },
      { q: tile.coordinates.q - 1, r: tile.coordinates.r + 1 }
    ];

    // Check if surrounded by land (no ocean neighbors)
    const hasOceanNeighbor = neighbors.some(n => {
      const neighborKey = getHexKey(n.q, n.r);
      const neighborTile = tiles.get(neighborKey);
      return neighborTile && neighborTile.terrain === 'ocean';
    });

    // If no ocean neighbor, convert to appropriate land terrain
    if (!hasOceanNeighbor) {
      // Find most common terrain among neighbors
      const neighborTerrains: TerrainType[] = [];
      for (const n of neighbors) {
        const neighborKey = getHexKey(n.q, n.r);
        const neighborTile = tiles.get(neighborKey);
        if (neighborTile && neighborTile.terrain !== 'coast' && neighborTile.terrain !== 'ocean') {
          neighborTerrains.push(neighborTile.terrain);
        }
      }

      // Use most common neighbor terrain, default to plains
      const newTerrain = neighborTerrains.length > 0 ? neighborTerrains[0] : 'plains';
      tilesToConvert.push({ key, newTerrain });
    }
  }

  // Apply conversions
  for (const { key, newTerrain } of tilesToConvert) {
    const tile = tiles.get(key);
    if (tile) {
      tile.terrain = newTerrain;
    }
  }
}

/**
 * CONSISTENCY CLEANUP: Make deserts compact by removing isolated desert tiles
 */
function makeDesertsCompact(tiles: Map<string, HexTile>, config: MapConfig): void {
  const MAX_PASSES = 3; // Run multiple passes for thoroughness

  for (let pass = 0; pass < MAX_PASSES; pass++) {
    const tilesToConvert: string[] = [];

    for (const [key, tile] of tiles) {
      if (tile.terrain !== 'desert') continue;

      const neighbors = [
        { q: tile.coordinates.q + 1, r: tile.coordinates.r },
        { q: tile.coordinates.q - 1, r: tile.coordinates.r },
        { q: tile.coordinates.q, r: tile.coordinates.r + 1 },
        { q: tile.coordinates.q, r: tile.coordinates.r - 1 },
        { q: tile.coordinates.q + 1, r: tile.coordinates.r - 1 },
        { q: tile.coordinates.q - 1, r: tile.coordinates.r + 1 }
      ];

      // Count desert neighbors
      let desertNeighbors = 0;
      let mountainNeighbors = 0;
      const otherTerrains: TerrainType[] = [];

      for (const n of neighbors) {
        const neighborKey = getHexKey(n.q, n.r);
        const neighborTile = tiles.get(neighborKey);
        if (neighborTile) {
          if (neighborTile.terrain === 'desert') {
            desertNeighbors++;
          } else if (neighborTile.terrain === 'mountain_range') {
            mountainNeighbors++;
          } else if (neighborTile.terrain !== 'ocean' && neighborTile.terrain !== 'coast' && neighborTile.terrain !== 'ice') {
            otherTerrains.push(neighborTile.terrain);
          }
        }
      }

      // Remove isolated deserts or deserts surrounded by mountains
      if (desertNeighbors < 2 || mountainNeighbors >= 4) {
        tilesToConvert.push(key);
      }
    }

    // Convert isolated deserts to appropriate terrain
    for (const key of tilesToConvert) {
      const tile = tiles.get(key);
      if (!tile) continue;

      // Find neighbor terrains
      const neighbors = [
        { q: tile.coordinates.q + 1, r: tile.coordinates.r },
        { q: tile.coordinates.q - 1, r: tile.coordinates.r },
        { q: tile.coordinates.q, r: tile.coordinates.r + 1 },
        { q: tile.coordinates.q, r: tile.coordinates.r - 1 },
        { q: tile.coordinates.q + 1, r: tile.coordinates.r - 1 },
        { q: tile.coordinates.q - 1, r: tile.coordinates.r + 1 }
      ];

      const neighborTerrains: TerrainType[] = [];
      for (const n of neighbors) {
        const neighborKey = getHexKey(n.q, n.r);
        const neighborTile = tiles.get(neighborKey);
        if (neighborTile && neighborTile.terrain !== 'desert' && neighborTile.terrain !== 'ocean' && neighborTile.terrain !== 'coast') {
          neighborTerrains.push(neighborTile.terrain);
        }
      }

      // Convert to most common neighbor (or plains)
      if (neighborTerrains.length > 0) {
        // Count terrain types
        const terrainCounts: Record<string, number> = {};
        for (const t of neighborTerrains) {
          terrainCounts[t] = (terrainCounts[t] || 0) + 1;
        }

        // Find most common
        let maxCount = 0;
        let mostCommon: TerrainType = 'plains';
        for (const [terrain, count] of Object.entries(terrainCounts)) {
          if (count > maxCount) {
            maxCount = count;
            mostCommon = terrain as TerrainType;
          }
        }

        tile.terrain = mostCommon;
      } else {
        tile.terrain = 'plains';
      }
    }

    // If no changes in this pass, stop early
    if (tilesToConvert.length === 0) break;
  }
}

/**
 * CONSISTENCY CLEANUP: Smooth terrain by removing isolated single tiles
 */
function smoothTerrainNoise(tiles: Map<string, HexTile>, config: MapConfig): void {
  const MAX_PASSES = 2;

  for (let pass = 0; pass < MAX_PASSES; pass++) {
    const tilesToSmooth: Array<{ key: string; newTerrain: TerrainType }> = [];

    for (const [key, tile] of tiles) {
      // Skip water, ice, mountain_ranges (intentionally isolated), and deserts (already handled)
      if (tile.terrain === 'ocean' || tile.terrain === 'coast' || tile.terrain === 'ice' ||
        tile.terrain === 'mountain_range' || tile.terrain === 'desert') {
        continue;
      }

      const neighbors = [
        { q: tile.coordinates.q + 1, r: tile.coordinates.r },
        { q: tile.coordinates.q - 1, r: tile.coordinates.r },
        { q: tile.coordinates.q, r: tile.coordinates.r + 1 },
        { q: tile.coordinates.q, r: tile.coordinates.r - 1 },
        { q: tile.coordinates.q + 1, r: tile.coordinates.r - 1 },
        { q: tile.coordinates.q - 1, r: tile.coordinates.r + 1 }
      ];

      // Count neighbors with same terrain
      let sameTerrainCount = 0;
      const differentTerrains: TerrainType[] = [];

      for (const n of neighbors) {
        const neighborKey = getHexKey(n.q, n.r);
        const neighborTile = tiles.get(neighborKey);
        if (neighborTile) {
          if (neighborTile.terrain === tile.terrain) {
            sameTerrainCount++;
          } else if (neighborTile.terrain !== 'ocean' && neighborTile.terrain !== 'coast' &&
            neighborTile.terrain !== 'ice' && neighborTile.terrain !== 'mountain_range') {
            differentTerrains.push(neighborTile.terrain);
          }
        }
      }

      // If isolated (less than 2 same neighbors), convert to most common neighbor
      if (sameTerrainCount < 2 && differentTerrains.length > 0) {
        // Count terrain types
        const terrainCounts: Record<string, number> = {};
        for (const t of differentTerrains) {
          terrainCounts[t] = (terrainCounts[t] || 0) + 1;
        }

        // Find most common
        let maxCount = 0;
        let mostCommon: TerrainType = differentTerrains[0];
        for (const [terrain, count] of Object.entries(terrainCounts)) {
          if (count > maxCount) {
            maxCount = count;
            mostCommon = terrain as TerrainType;
          }
        }

        tilesToSmooth.push({ key, newTerrain: mostCommon });
      }
    }

    // Apply smoothing
    for (const { key, newTerrain } of tilesToSmooth) {
      const tile = tiles.get(key);
      if (tile) {
        tile.terrain = newTerrain;
      }
    }

    // If no changes, stop early
    if (tilesToSmooth.length === 0) break;
  }
}

/**
 * CORDILLERA CONSISTENCY: Ensure all cordilleras (mountain_range) have only hills or mountain features around them
 * STRICT RULE: A cordillera can ONLY have hills OR tiles with 'mountain' feature adjacent
 */
function ensureMountainRangeNeighbors(tiles: Map<string, HexTile>, config: MapConfig): void {
  console.log('🏔️ ENFORCING CORDILLERA NEIGHBOR RULE...');
  let conversionsCount = 0;

  for (const [, tile] of tiles) {
    // Only process mountain_range (cordillera) tiles
    if (tile.terrain !== 'mountain_range') continue;

    const neighbors = [
      { q: tile.coordinates.q + 1, r: tile.coordinates.r },
      { q: tile.coordinates.q - 1, r: tile.coordinates.r },
      { q: tile.coordinates.q, r: tile.coordinates.r + 1 },
      { q: tile.coordinates.q, r: tile.coordinates.r - 1 },
      { q: tile.coordinates.q + 1, r: tile.coordinates.r - 1 },
      { q: tile.coordinates.q - 1, r: tile.coordinates.r + 1 }
    ];

    // Process each neighbor of the cordillera
    for (const n of neighbors) {
      const neighborKey = getHexKey(n.q, n.r);
      const neighborTile = tiles.get(neighborKey);

      if (!neighborTile) continue;

      // Skip if neighbor is ocean, coast, ice, or already a mountain_range
      if (neighborTile.terrain === 'ocean' ||
        neighborTile.terrain === 'coast' ||
        neighborTile.terrain === 'ice' ||
        neighborTile.terrain === 'mountain_range') {
        continue;
      }

      // STRICT RULE: Cordillera neighbors must be either:
      // 1. Hills terrain
      // 2. Any terrain WITH 'mountain' feature

      // Check if neighbor has 'mountain' feature
      const hasMountainFeature = neighborTile.features && neighborTile.features.includes('mountain');

      // If not hills and doesn't have mountain feature, convert to hills
      if (neighborTile.terrain !== 'hills' && !hasMountainFeature) {
        neighborTile.terrain = 'hills';
        // CRITICAL: Ensure hills have LOWER elevation than cordillera
        // Cordilleras typically have elevation 6-10
        // Hills should be 1-2 levels lower to allow river flow
        neighborTile.elevation = Math.max(1, tile.elevation - 2);
        conversionsCount++;
      }
    }
  }

  console.log(`✅ Cordillera neighbor rule enforced: ${conversionsCount} tiles converted to hills`);
}
