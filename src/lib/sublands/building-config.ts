import type { BuildingConfig, BuildingType, NFTType, HexagonSettlementData } from './types';

/**
 * Building configurations with costs, area requirements, and properties
 * Each building has a specific area footprint in square meters
 * Maximum area per SubLand: 1,000,000 m² (1 km² = 100 hectares)
 */
export const BUILDING_CONFIGS: Record<BuildingType, BuildingConfig> = {
  // Residential buildings
  house: {
    name: 'House',
    type: 'house',
    slxCost: 10,
    areaM2: 100, // 100 m²
    category: 'residential',
    description: 'Basic dwelling for settlers. Provides shelter and storage.'
  },
  village: {
    name: 'Village',
    type: 'village',
    slxCost: 100,
    areaM2: 5000, // 5,000 m² (0.5 hectares)
    category: 'residential',
    description: 'Small settlement. Houses multiple families and basic services.'
  },
  
  // Production buildings - Workshops
  smithy: {
    name: 'Smithy',
    type: 'smithy',
    slxCost: 35,
    areaM2: 250, // 250 m²
    category: 'production',
    description: 'Metalworking forge. Creates weapons, tools, and armor. Requires iron or copper resources.'
  },
  carpentry: {
    name: 'Carpentry',
    type: 'carpentry',
    slxCost: 25,
    areaM2: 250, // 250 m²
    category: 'production',
    description: 'Woodworking workshop. Produces tools, furniture, and building materials.'
  },
  tailoring: {
    name: 'Tailoring',
    type: 'tailoring',
    slxCost: 18,
    areaM2: 250, // 250 m²
    category: 'production',
    description: 'Textile workshop. Produces clothing and cloth goods from cotton or flax.'
  },
  spinning_mill: {
    name: 'Spinning Mill',
    type: 'spinning_mill',
    slxCost: 30,
    areaM2: 250, // 250 m²
    category: 'production',
    description: 'Processes raw fibers into thread and yarn. Requires cotton or flax.'
  },
  weaving_mill: {
    name: 'Weaving Mill',
    type: 'weaving_mill',
    slxCost: 35,
    areaM2: 250, // 250 m²
    category: 'production',
    description: 'Weaves thread into cloth and fabric. Works with spinning mill output.'
  },
  blood_mill: {
    name: 'Blood Mill',
    type: 'blood_mill',
    slxCost: 40,
    areaM2: 250, // 250 m²
    category: 'production',
    description: 'Animal-powered mill. Grinds grain and processes materials. Requires animals.'
  },
  
  // Agricultural buildings
  farm: {
    name: 'Farm',
    type: 'farm',
    slxCost: 15,
    areaM2: 100000, // 10 hectares = 100,000 m²
    category: 'production',
    description: 'Agricultural facility. Produces food resources over time. Requires fertile land.'
  },
  stable: {
    name: 'Stable',
    type: 'stable',
    slxCost: 20,
    areaM2: 250, // 250 m²
    category: 'infrastructure',
    description: 'Horse stables. Enables faster travel and cavalry training. Houses up to 20 horses.'
  },
  
  // Resource extraction buildings
  mine: {
    name: 'Mine',
    type: 'mine',
    slxCost: 40,
    areaM2: 500, // 500 m²
    category: 'production',
    description: 'Mining facility. Extracts minerals and ores from the ground. Requires mineral-rich land.'
  },
  logging_camp: {
    name: 'Logging Camp',
    type: 'logging_camp',
    slxCost: 25,
    areaM2: 300, // 300 m²
    category: 'production',
    description: 'Forestry camp. Harvests timber from nearby forests. Requires forested land.'
  },
  
  // Infrastructure buildings
  windmill: {
    name: 'Windmill',
    type: 'windmill',
    slxCost: 35,
    areaM2: 200, // 200 m²
    category: 'production',
    description: 'Wind-powered mill. Grinds grain using wind energy. More efficient than blood mill.'
  },
  warehouse: {
    name: 'Warehouse',
    type: 'warehouse',
    slxCost: 30,
    areaM2: 500, // 500 m²
    category: 'infrastructure',
    description: 'Storage facility. Increases resource storage capacity. Essential for trade.'
  },
  blacksmith: {
    name: 'Blacksmith',
    type: 'blacksmith',
    slxCost: 40,
    areaM2: 300, // 300 m²
    category: 'production',
    description: 'Advanced metalworking forge. Produces high-quality weapons, tools, and armor.'
  },
  
  // Commerce buildings
  tavern: {
    name: 'Tavern',
    type: 'tavern',
    slxCost: 30,
    areaM2: 250, // 250 m²
    category: 'commerce',
    description: 'Social hub and inn. Provides rest for travelers, boosts morale, and generates income.'
  },
  
  // River-dependent buildings (non-navigable)
  river_mill: {
    name: 'River Mill',
    type: 'river_mill',
    slxCost: 45,
    areaM2: 300, // 300 m²
    requiresRiver: 'non-navigable',
    category: 'production',
    description: 'Water-powered mill. Grinds grain using river current. 50% more efficient than blood mill.'
  },
  river_sawmill: {
    name: 'River Sawmill',
    type: 'river_sawmill',
    slxCost: 50,
    areaM2: 300, // 300 m²
    requiresRiver: 'non-navigable',
    category: 'production',
    description: 'Water-powered sawmill. Processes timber efficiently. Requires nearby forest.'
  },
  
  // River-dependent buildings (navigable)
  river_shipyard: {
    name: 'River Shipyard',
    type: 'river_shipyard',
    slxCost: 80,
    areaM2: 1000, // 1,000 m² (0.1 hectares)
    requiresRiver: 'navigable',
    category: 'infrastructure',
    description: 'Builds and repairs river vessels. Requires navigable waterway. Enables river trade.'
  },
  river_port: {
    name: 'River Port',
    type: 'river_port',
    slxCost: 70,
    areaM2: 800, // 800 m²
    requiresRiver: 'navigable',
    category: 'commerce',
    description: 'Trading port on navigable river. Enables river commerce and generates trade income.'
  },
  
  // Coastal buildings (require adjacent coastal_inland hex)
  dock: {
    name: 'Dock (Muelle)',
    type: 'dock',
    slxCost: 50,
    areaM2: 500, // 500 m²
    requiresCoastalAdjacency: true,
    category: 'infrastructure',
    description: 'Basic dock for small boats. Must be built on land adjacent to coastal inland zones. Enables coastal fishing and small vessel mooring.'
  },
  port: {
    name: 'Port (Puerto)',
    type: 'port',
    slxCost: 120,
    areaM2: 2000, // 2,000 m² (0.2 hectares)
    requiresCoastalAdjacency: true,
    category: 'commerce',
    description: 'Major trading port. Must be built on land adjacent to coastal inland zones. Enables maritime commerce and generates substantial trade income.'
  },
  shipyard: {
    name: 'Shipyard (Astillero)',
    type: 'shipyard',
    slxCost: 150,
    areaM2: 3000, // 3,000 m² (0.3 hectares)
    requiresCoastalAdjacency: true,
    category: 'production',
    description: 'Ship construction facility. Must be built on land adjacent to coastal inland zones. Builds and repairs ocean-going vessels.'
  },
  
  // Special buildings
  settlement: {
    name: 'Settlement',
    type: 'settlement',
    slxCost: 200,
    areaM2: 10000, // 1 hectare = 10,000 m²
    requiresSpecialNFTs: true,
    category: 'special',
    description: 'Large settlement. Requires special NFTs to establish. Permanent ownership. Population up to 500.'
  },
  
  // SETTLEMENT HIERARCHY
  // Urban Core (Village/Aldea) - County Land NFT required
  urban_core: {
    name: 'Urban Core (Village)',
    type: 'urban_core',
    slxCost: 500,
    areaM2: 50000, // 5 hectares = 50,000 m²
    requiresEmptyTile: true, // Must be virgin land
    requiresNFTType: 'county_land',
    category: 'settlement',
    description: 'Village/Aldea. Provides 300 inhabitants as workers. Includes: Market, Tavern, Barracks (30 soldiers), Religious Building, and 100 Houses. Only buildable on empty land by County Land NFT owners. Limit: 100 per hexagon.'
  },
  
  // Town (Ciudad) - Duchy Land NFT required + 20 villages
  town: {
    name: 'Town (Ciudad)',
    type: 'town',
    slxCost: 2000,
    areaM2: 4000000, // 4 km² (occupies central hexagon and immediate neighbors)
    requiresNFTType: 'duchy_land',
    requiresVillages: 20,
    isTownCenter: true,
    category: 'settlement',
    description: 'City/Town. Requires 20+ villages in hexagon. Built at center hex (0,0). Only 1 town per hexagon. Only buildable by Duchy Land NFT owner (hexagon owner).'
  }
};

/**
 * Get available buildings for a SubLand based on its properties
 */
export function getAvailableBuildings(
  hasRiver: boolean,
  isNavigableRiver: boolean,
  hasSpecialNFTs: boolean,
  availableAreaM2: number,
  nftType: NFTType = 'none',
  subland: { status: string; buildings: Array<{ type: string }>; resourceType: string },
  hexagonData?: HexagonSettlementData,
  isAdjacentToCoastalInland?: boolean
): BuildingConfig[] {
  const available: BuildingConfig[] = [];
  
  for (const config of Object.values(BUILDING_CONFIGS)) {
    // Check area availability
    if (config.areaM2 > availableAreaM2) {
      continue;
    }
    
    // Check river requirements
    if (config.requiresRiver === 'navigable' && (!hasRiver || !isNavigableRiver)) {
      continue;
    }
    if (config.requiresRiver === 'non-navigable' && (!hasRiver || isNavigableRiver)) {
      continue;
    }
    
    // Check coastal adjacency requirement
    if (config.requiresCoastalAdjacency && !isAdjacentToCoastalInland) {
      continue;
    }
    
    // Cannot build in coastal_inland areas
    if (subland.resourceType === 'coastal_inland') {
      continue;
    }
    
    // Check special NFT requirements
    if (config.requiresSpecialNFTs && !hasSpecialNFTs) {
      continue;
    }
    
    // Check NFT type requirements
    if (config.requiresNFTType && config.requiresNFTType !== nftType) {
      continue;
    }
    
    // Check empty tile requirement (urban_core must be on virgin land)
    if (config.requiresEmptyTile && (subland.status !== 'virgin' || subland.buildings.length > 0)) {
      continue;
    }
    
    // Check village requirements for town
    if (config.requiresVillages && hexagonData) {
      if (hexagonData.urbanCoreCount < config.requiresVillages) {
        continue;
      }
      // Only one town per hexagon
      if (config.isTownCenter && hexagonData.hasTown) {
        continue;
      }
    }
    
    // Skip town if no hexagon data available
    if (config.isTownCenter && !hexagonData) {
      continue;
    }
    
    available.push(config);
  }
  
  return available;
}

/**
 * Check if a hex is the central hex (0, 0) where towns must be built
 */
export function isCentralTile(q: number, r: number): boolean {
  // Town must be built at the center of the hexagonal grid
  return q === 0 && r === 0;
}

/**
 * Get the central hex and its immediate neighbors for a town
 * Town occupies the center hex (0,0) and its 6 neighbors
 */
export function getTownTiles(q: number, r: number): Array<{ q: number; r: number }> {
  // Always return center and its 6 neighbors
  return [
    { q: 0, r: 0 },      // Center
    { q: 1, r: 0 },      // East
    { q: 1, r: -1 },     // Northeast
    { q: 0, r: -1 },     // Northwest
    { q: -1, r: 0 },     // West
    { q: -1, r: 1 },     // Southwest
    { q: 0, r: 1 }       // Southeast
  ];
}

/**
 * Count urban cores in sublands array
 */
export function countUrbanCores(sublands: Array<{ buildings: Array<{ type: string }> }>): number {
  let count = 0;
  for (const subland of sublands) {
    for (const building of subland.buildings) {
      if (building.type === 'urban_core') {
        count++;
      }
    }
  }
  return count;
}

/**
 * Check if hexagon has a town
 */
export function hasTownInHexagon(sublands: Array<{ buildings: Array<{ type: string }> }>): boolean {
  for (const subland of sublands) {
    for (const building of subland.buildings) {
      if (building.type === 'town') {
        return true;
      }
    }
  }
  return false;
}

/**
 * Format area for display
 */
export function formatArea(areaM2: number): string {
  if (areaM2 >= 10000) {
    const hectares = areaM2 / 10000;
    return `${hectares.toFixed(1)} ha`;
  }
  return `${areaM2.toLocaleString()} m²`;
}
