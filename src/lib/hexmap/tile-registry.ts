import type { HexTile } from './types';
import type { CompleteTileData } from './terrain-storage';

/**
 * Tile Registry System
 * Converts HexTile map data to CompleteTileData for export
 */

export function buildCompleteTileRegistry(tiles: Map<string, HexTile>): CompleteTileData[] {
    const registry: CompleteTileData[] = [];

    for (const [, tile] of tiles) {
        const completeTile: CompleteTileData = {
            q: tile.coordinates.q,
            r: tile.coordinates.r,
            x: tile.coordinates.x,
            y: tile.coordinates.y,
            terrain: tile.terrain,
            features: tile.features || [],
            resources: tile.resources || [],
            animals: tile.animals || [],
            minerals: tile.minerals || [],
            elevation: tile.elevation,
            temperature: tile.temperature,
            rainfall: tile.rainfall,
            hasVolcano: tile.hasVolcano,
            hasRiver: tile.hasRiver,
            continent: tile.continent,
            latitude: tile.latitude,
            hemisphere: tile.hemisphere,
            season: tile.season
        };

        registry.push(completeTile);
    }

    return registry;
}

/**
 * Export complete tile registry as JSON string
 */
export function exportTileRegistry(tiles: Map<string, HexTile>): string {
    const registry = buildCompleteTileRegistry(tiles);
    return JSON.stringify(registry, null, 2);
}

/**
 * Download complete tile registry as JSON file
 */
export function downloadTileRegistry(tiles: Map<string, HexTile>): void {
    const jsonData = exportTileRegistry(tiles);
    const blob = new Blob([jsonData], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `altriux-complete-registry-${Date.now()}.json`;
    a.click();
    URL.revokeObjectURL(url);
}

/**
 * Get tile statistics for the entire map
 */
export function getMapStatistics(tiles: Map<string, HexTile>): {
    totalTiles: number;
    byTerrain: Record<string, number>;
    byContinent: Record<string, number>;
    withResources: number;
    withMinerals: number;
    withAnimals: number;
    withFeatures: number;
} {
    const stats = {
        totalTiles: tiles.size,
        byTerrain: {} as Record<string, number>,
        byContinent: {} as Record<string, number>,
        withResources: 0,
        withMinerals: 0,
        withAnimals: 0,
        withFeatures: 0
    };

    for (const [, tile] of tiles) {
        // Count by terrain
        stats.byTerrain[tile.terrain] = (stats.byTerrain[tile.terrain] || 0) + 1;

        // Count by continent
        if (tile.continent) {
            stats.byContinent[tile.continent] = (stats.byContinent[tile.continent] || 0) + 1;
        }

        // Count tiles with resources
        if (tile.resources && tile.resources.length > 0) stats.withResources++;
        if (tile.minerals && tile.minerals.length > 0) stats.withMinerals++;
        if (tile.animals && tile.animals.length > 0) stats.withAnimals++;
        if (tile.features && tile.features.length > 0) stats.withFeatures++;
    }

    return stats;
}
