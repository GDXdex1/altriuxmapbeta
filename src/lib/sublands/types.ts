/**
 * SubLands System Types
 * Each hex tile contains ~10,000 SubLands in HEXAGONAL layout
 * Each SubLand is a small hexagon within the parent hex
 * Uses axial coordinates (q, r) for positioning
 */

export type SubLandResourceType = 
  | 'mine_gold' 
  | 'mine_silver' 
  | 'mine_iron'
  | 'mine_copper'
  | 'mine_tin'
  | 'mine_bronze'
  | 'mine_stone'
  | 'mine_gems'
  | 'farmland_wheat'
  | 'farmland_cotton'
  | 'farmland_spices'
  | 'coastal_land' // Land on coastlines (for ports, shipyards, etc.)
  | 'coastal_inland' // Inland coastal areas near ocean (for coastal duchies)
  | 'standard'; // Moderate agricultural performance

export type BuildingType =
  | 'smithy'
  | 'carpentry'
  | 'farm'
  | 'village'
  | 'spinning_mill'
  | 'weaving_mill'
  | 'blood_mill'
  | 'tailoring'
  | 'stable'
  | 'house'
  | 'tavern'
  | 'mine'              // Mining facility
  | 'logging_camp'      // Forestry camp
  | 'windmill'          // Wind-powered mill
  | 'warehouse'         // Storage facility
  | 'blacksmith'        // Advanced forge
  | 'dock'              // Coastal dock
  | 'port'              // Coastal port
  | 'shipyard'          // Coastal shipyard
  | 'river_shipyard'    // Requires navigable river
  | 'river_mill'        // Requires non-navigable river
  | 'river_port'        // Requires navigable river
  | 'river_sawmill'     // Requires non-navigable river
  | 'settlement'        // Requires special NFTs
  | 'urban_core'        // Village/Aldea - Requires County Land NFT
  | 'town';             // Ciudad - Requires Duchy Land NFT + 20 villages

export type NFTType = 'county_land' | 'duchy_land' | 'none';

export type ReligionType = 'christian' | 'muslim' | 'pagan' | 'none';

export interface UrbanCoreBuildings {
  market: boolean;
  tavern: boolean;
  barracks: boolean;
  religiousBuilding: ReligionType;
  houses: number; // Always 100
  soldiers: number; // Always 30
  population: number; // Always 300
}

export interface BuildingConfig {
  name: string;
  type: BuildingType;
  slxCost: number; // SILVEX tokens to burn
  areaM2: number; // Area in square meters
  requiresRiver?: 'navigable' | 'non-navigable';
  requiresCoastalAdjacency?: boolean; // Must be adjacent to coastal_inland hex
  requiresSpecialNFTs?: boolean;
  requiresNFTType?: NFTType;
  requiresEmptyTile?: boolean; // Must be built on virgin land only
  requiresVillages?: number; // Minimum villages in hexagon
  isTownCenter?: boolean; // Occupies central hexagon cluster
  description: string;
  category: 'residential' | 'production' | 'commerce' | 'infrastructure' | 'special' | 'settlement';
}

export interface PlacedBuilding {
  id: string; // Unique ID for this building instance
  type: BuildingType;
  builtAt: Date;
  nftId: string;
  position: { offsetX: number; offsetY: number }; // Position within the hex (0-1 range)
  workers?: number; // Number of workers assigned
  productionRate?: number; // Current production rate (0-100%)
  inventory?: Record<string, number>; // Resources stored in building
  urbanCoreData?: UrbanCoreBuildings; // Only for urban_core type
  religion?: ReligionType; // For urban cores and towns
}

export interface SubLand {
  id: string; // Format: "{parentQ}:{parentR}:{q}:{r}"
  q: number;  // Axial coordinate within hexagonal grid (horizontal axis)
  r: number;  // Axial coordinate within hexagonal grid (diagonal axis)
  resourceType: SubLandResourceType;
  hasRiver: boolean;
  isNavigableRiver: boolean;
  biomeType: 'mountain' | 'plains' | 'forest' | 'jungle' | 'desert' | 'coast' | 'meadow' | 'hills' | 'tundra' | 'boreal_forest'; // Visual biome
  hasNaturalFeatures: boolean; // Trees, rocks, etc. (cleared on claim)
  status: 'virgin' | 'claimed' | 'developed';
  owner?: string;           // Wallet address
  ownerName?: string;
  nftId?: string;          // Format: "SL-{parentQ}-{parentR}-{q}-{r}"
  nftType?: NFTType;       // Type of NFT owned (county_land, duchy_land, none)
  claimedAt?: Date;
  claimExpiresAt?: Date;   // 6 months real time from claim
  buildings: PlacedBuilding[]; // Multiple buildings per hex
  usedAreaM2: number;      // Total area occupied by buildings
  maxAreaM2: number;       // Maximum area (1,000,000 m² = 1 km²)
  isPartOfTown?: boolean;  // True if this hex is part of a town's central cluster
  townCenterPosition?: { centerQ: number; centerR: number }; // Reference to town center
}

export interface HexagonSettlementData {
  parentQ: number;
  parentR: number;
  urbanCoreCount: number; // Current number of urban cores (villages)
  maxUrbanCores: number; // Always 100
  hasTown: boolean; // Only one town allowed per hexagon
  townPosition?: { q: number; r: number }; // Center position of town
  totalPopulation: number; // Sum of all villages (300 each)
}

export interface RiverSystem {
  navigableRivers: Array<{ q: number; r: number; parentQ: number; parentR: number }>;
  nonNavigableRivers: Array<{ q: number; r: number; parentQ: number; parentR: number }>;
}
