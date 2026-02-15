import type { TerrainType, TerrainFeature, ResourceType, AnimalType, MineralType } from './types';

/**
 * Storage system for terrain modifications
 * Saves and loads custom terrain changes from localStorage
 * EXTENDED: Now supports resources, minerals, animals, and characteristics
 */

export interface TerrainModification {
  q: number;
  r: number;
  terrain?: TerrainType;
  features?: TerrainFeature[];
  resources?: ResourceType[];
  animals?: AnimalType[];
  minerals?: MineralType[];
  elevation?: number;
  temperature?: number;
  rainfall?: number;
  timestamp: number;
}

export interface CompleteTileData {
  q: number;
  r: number;
  x: number;
  y: number;
  terrain: TerrainType;
  features: TerrainFeature[];
  resources: ResourceType[];
  animals: AnimalType[];
  minerals: MineralType[];
  elevation: number;
  temperature: number;
  rainfall: number;
  hasVolcano: boolean;
  hasRiver: boolean;
  continent?: 'drantium' | 'brontium';
  latitude: number;
  hemisphere: 'northern' | 'southern' | 'equatorial';
  season?: string;
}

const STORAGE_KEY = 'altriux_terrain_modifications';
const COMPLETE_MAP_KEY = 'altriux_complete_map';

/**
 * Save terrain modification to localStorage
 */
export function saveTerrainModification(
  q: number,
  r: number,
  terrain?: TerrainType,
  features?: TerrainFeature[],
  resources?: ResourceType[],
  animals?: AnimalType[],
  minerals?: MineralType[],
  elevation?: number,
  temperature?: number,
  rainfall?: number
): void {
  const modifications = loadAllModifications();

  // Remove existing modification for this coordinate if it exists
  const filtered = modifications.filter(mod => !(mod.q === q && mod.r === r));

  // Add new modification
  filtered.push({
    q,
    r,
    terrain,
    features,
    resources,
    animals,
    minerals,
    elevation,
    temperature,
    rainfall,
    timestamp: Date.now()
  });

  localStorage.setItem(STORAGE_KEY, JSON.stringify(filtered));
}

/**
 * Save ONLY resources without modifying terrain/features
 */
export function saveResourcesOnly(
  q: number,
  r: number,
  resources?: ResourceType[],
  animals?: AnimalType[],
  minerals?: MineralType[]
): void {
  const modifications = loadAllModifications();

  // Find existing modification or create new one
  const existing = modifications.find(mod => mod.q === q && mod.r === r);

  if (existing) {
    // Update only resources, keep terrain/features unchanged
    existing.resources = resources;
    existing.animals = animals;
    existing.minerals = minerals;
    existing.timestamp = Date.now();
  } else {
    // Create new modification with resources only
    modifications.push({
      q,
      r,
      resources,
      animals,
      minerals,
      timestamp: Date.now()
    });
  }

  localStorage.setItem(STORAGE_KEY, JSON.stringify(modifications));
}

/**
 * Load all terrain modifications from localStorage
 */
export function loadAllModifications(): TerrainModification[] {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (!stored) return [];

    const parsed = JSON.parse(stored);
    return Array.isArray(parsed) ? parsed : [];
  } catch (error) {
    console.error('Error loading terrain modifications:', error);
    return [];
  }
}

/**
 * Get modification for specific coordinates
 */
export function getModification(q: number, r: number): TerrainModification | null {
  const modifications = loadAllModifications();
  return modifications.find(mod => mod.q === q && mod.r === r) || null;
}

/**
 * Clear all terrain modifications
 */
export function clearAllModifications(): void {
  localStorage.removeItem(STORAGE_KEY);
}

/**
 * Export modifications as JSON string
 */
export function exportModifications(): string {
  const modifications = loadAllModifications();
  return JSON.stringify(modifications, null, 2);
}

/**
 * Import modifications from JSON string
 */
export function importModifications(jsonString: string): boolean {
  try {
    const parsed = JSON.parse(jsonString);
    if (!Array.isArray(parsed)) {
      throw new Error('Invalid format: expected array');
    }

    // Validate each modification
    for (const mod of parsed) {
      if (typeof mod.q !== 'number' || typeof mod.r !== 'number') {
        throw new Error('Invalid modification format');
      }
    }

    localStorage.setItem(STORAGE_KEY, JSON.stringify(parsed));
    return true;
  } catch (error) {
    console.error('Error importing modifications:', error);
    return false;
  }
}

/**
 * Get count of modifications
 */
export function getModificationCount(): number {
  return loadAllModifications().length;
}

/**
 * Save complete map data (all tiles)
 */
export function saveCompleteMapData(tiles: CompleteTileData[]): void {
  try {
    localStorage.setItem(COMPLETE_MAP_KEY, JSON.stringify(tiles, null, 2));
  } catch (error) {
    console.error('Error saving complete map data:', error);
  }
}

/**
 * Export complete map data as JSON string
 */
export function exportCompleteMapData(): string {
  try {
    const stored = localStorage.getItem(COMPLETE_MAP_KEY);
    return stored || '[]';
  } catch (error) {
    console.error('Error exporting complete map data:', error);
    return '[]';
  }
}

/**
 * Download complete map data as JSON file
 */
export function downloadCompleteMapData(): void {
  const jsonData = exportCompleteMapData();
  const blob = new Blob([jsonData], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `altriux-complete-map-${Date.now()}.json`;
  a.click();
  URL.revokeObjectURL(url);
}
