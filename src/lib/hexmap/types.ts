export type TerrainType =
  | 'ocean'
  | 'coast'
  | 'plains'
  | 'meadow'
  | 'hills'
  | 'mountain_range'
  | 'tundra'
  | 'desert'
  | 'ice';

// Terrain Features: vegetation characteristics that can exist ON terrain
export type TerrainFeature =
  | 'forest'
  | 'jungle'
  | 'boreal_forest'
  | 'oasis'
  | 'volcano'
  | 'mountain'
  | 'river'
  | 'swamp'  // Pantanal
  | 'none';

export type AnimalType =
  | 'horses'
  | 'sheep'
  | 'buffalo'
  | 'muffon'
  | 'yaks'
  | 'camels'
  | 'wild_cattle'
  | 'wild_horse'
  | 'wild_camel'
  | 'wild_yak'
  | 'boar'
  | 'wolf'
  | 'jackal'
  | 'wild_cat'
  | 'wild_dog'
  | 'wild_donkey';

export type MineralType =
  | 'gold'
  | 'silver'
  | 'iron'
  | 'tin'
  | 'bronze'
  | 'copper'
  | 'stone'
  | 'gems'
  | 'galena'      // Lead + Silver
  | 'zinc'
  | 'nickel'
  | 'cobalt'
  | 'laterite'    // Ni + Co ore
  | 'cassiterite' // Tin ore
  | 'limestone'
  | 'marble';

export type NaturalResourceType =
  | 'wood'
  | 'fish'
  | 'whales'
  | 'crabs'
  | 'wheat'
  | 'cotton'
  | 'spices'
  | 'legumes'
  | 'flax'
  | 'corn'
  | 'dates'
  | 'oil_well'; // Pozo de petróleo

export type ResourceType = AnimalType | MineralType | NaturalResourceType;

// Continents: Drantium (analogous to America), Brontium (analogous to Europe)
export type ContinentType = 'drantium' | 'brontium';

// Season system with hemispheric logic
export type Season = 'winter' | 'summer' | 'spring' | 'autumn';

export interface HexCoordinates {
  q: number; // column (axial coordinate)
  r: number; // row (axial coordinate)
  x: number; // horizontal coordinate (cartesian-like, for display)
  y: number; // vertical coordinate (cartesian-like, for display)
}

export interface HexTile {
  coordinates: HexCoordinates;
  terrain: TerrainType;
  features?: TerrainFeature[]; // NEW: Terrain features (forest/jungle) separate from base terrain
  resources: ResourceType[];
  animals: AnimalType[];
  minerals: MineralType[];
  elevation: number; // 0-10
  temperature: number; // -50 to 50 celsius
  rainfall: number; // 0-100 (percentage)
  hasVolcano: boolean;
  hasRiver: boolean; // Kept for compatibility but no longer used
  owner?: string; // Sui address of owner
  continent?: ContinentType; // Track which continent
  season?: Season; // Current season based on latitude
  latitude: number; // -90 to 90 degrees
  hemisphere: 'northern' | 'southern' | 'equatorial';
}

export type IslandType = 'desert' | 'tundra' | 'jungle' | 'forest' | 'mountain_range'; // Still used for island generation logic

export interface ContinentConfig {
  centerQ: number;
  centerR: number;
  width: number; // in hexes
  height: number; // in hexes
  type: ContinentType; // Drantium = jungle, Brontium = forest
}

export interface IslandConfig {
  centerQ: number;
  centerR: number;
  type: IslandType;
}

export interface MapConfig {
  // Earth-sized map: ~400 hexes wide, ~200 hexes tall
  width: number; // hexes around equator
  height: number; // hexes from pole to pole
  hexSizeKm: number; // 100km per hex
  continents: ContinentConfig[];
  islands: IslandConfig[];
}

export interface GameTime {
  startDate: Date; // November 15, 2025
  currentDate: Date;
  dayNumber: number; // Days since start
  monthNumber: number; // Month 1-14
  yearNumber: number; // Year since start
  speed: number; // 4x speed multiplier
  seasonInNorth: Season; // Current season in northern hemisphere
  seasonInSouth: Season; // Current season in southern hemisphere
}
