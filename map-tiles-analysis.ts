import { generateEarthMap } from './src/lib/hexmap/generator';
import type { HexTile } from './src/lib/hexmap/types';

/**
 * Complete analysis of all map tiles in the initial game map
 */

interface TerrainStats {
  terrain: string;
  count: number;
  percentage: number;
  avgElevation: number;
  minElevation: number;
  maxElevation: number;
  hasRiver: number;
  hasFeatures: number;
}

interface FeatureStats {
  feature: string;
  count: number;
  terrainTypes: string[];
}

interface ResourceStats {
  resource: string;
  count: number;
  terrainTypes: string[];
}

interface CoordinateStats {
  totalTiles: number;
  mapBounds: {
    minQ: number;
    maxQ: number;
    minR: number;
    maxR: number;
  };
  continents: {
    drantium: number;
    brontium: number;
    islands: number;
    ocean: number;
  };
}

async function analyzeMapTiles() {
  console.log('🗺️🗺️🗺️ COMPREHENSIVE MAP TILES ANALYSIS 🗺️🗺️🗺️');
  
  // Generate the map
  const tiles = await generateEarthMap(42, 1);
  console.log(`✅ Map generated with ${tiles.size} tiles`);
  
  // Initialize statistics
  const terrainMap = new Map<string, TerrainStats>();
  const featureMap = new Map<string, FeatureStats>();
  const resourceMap = new Map<string, ResourceStats>();
  
  let totalRiverTiles = 0;
  let totalFeatureTiles = 0;
  let totalResourceTiles = 0;
  
  // Coordinate bounds
  let minQ = Infinity, maxQ = -Infinity;
  let minR = Infinity, maxR = -Infinity;
  
  // Analyze each tile
  for (const tile of tiles.values()) {
    // Update bounds
    minQ = Math.min(minQ, tile.coordinates.q);
    maxQ = Math.max(maxQ, tile.coordinates.q);
    minR = Math.min(minR, tile.coordinates.r);
    maxR = Math.max(maxR, tile.coordinates.r);
    
    // Terrain statistics
    const terrain = tile.terrain;
    if (!terrainMap.has(terrain)) {
      terrainMap.set(terrain, {
        terrain,
        count: 0,
        percentage: 0,
        avgElevation: 0,
        minElevation: Infinity,
        maxElevation: -Infinity,
        hasRiver: 0,
        hasFeatures: 0
      });
    }
    
    const terrainStats = terrainMap.get(terrain)!;
    terrainStats.count++;
    terrainStats.avgElevation = (terrainStats.avgElevation * (terrainStats.count - 1) + tile.elevation) / terrainStats.count;
    terrainStats.minElevation = Math.min(terrainStats.minElevation, tile.elevation);
    terrainStats.maxElevation = Math.max(terrainStats.maxElevation, tile.elevation);
    
    if (tile.hasRiver) {
      terrainStats.hasRiver++;
      totalRiverTiles++;
    }
    
    if (tile.features && tile.features.length > 0) {
      terrainStats.hasFeatures++;
      totalFeatureTiles++;
      
      // Feature statistics
      for (const feature of tile.features) {
        if (!featureMap.has(feature)) {
          featureMap.set(feature, {
            feature,
            count: 0,
            terrainTypes: []
          });
        }
        
        const featureStats = featureMap.get(feature)!;
        featureStats.count++;
        if (!featureStats.terrainTypes.includes(terrain)) {
          featureStats.terrainTypes.push(terrain);
        }
      }
    }
    
    // Resource statistics
    if (tile.resources) {
      totalResourceTiles++;
      
      for (const resource of tile.resources) {
        if (!resourceMap.has(resource)) {
          resourceMap.set(resource, {
            resource,
            count: 0,
            terrainTypes: []
          });
        }
        
        const resourceStats = resourceMap.get(resource)!;
        resourceStats.count++;
        if (!resourceStats.terrainTypes.includes(terrain)) {
          resourceStats.terrainTypes.push(terrain);
        }
      }
    }
  }
  
  // Calculate percentages
  const totalTiles = tiles.size;
  for (const stats of terrainMap.values()) {
    stats.percentage = (stats.count / totalTiles) * 100;
  }
  
  // Coordinate statistics
  const coordStats: CoordinateStats = {
    totalTiles,
    mapBounds: { minQ, maxQ, minR, maxR },
    continents: {
      drantium: 0,
      brontium: 0,
      islands: 0,
      ocean: 0
    }
  };
  
  // Count by continent/region
  for (const tile of tiles.values()) {
    if (tile.terrain === 'ocean') {
      coordStats.continents.ocean++;
    } else if (tile.terrain === 'mountain_range' || tile.terrain === 'hills' || 
               tile.terrain === 'plains' || tile.terrain === 'meadow' || 
               tile.terrain === 'desert' || tile.terrain === 'forest' || 
               tile.terrain === 'jungle') {
      // Rough continent classification based on coordinates
      if (tile.coordinates.q < 0) {
        coordStats.continents.drantium++;
      } else {
        coordStats.continents.brontium++;
      }
    } else if (tile.terrain === 'tundra' || tile.terrain === 'ice') {
      // Polar regions
      if (Math.abs(tile.coordinates.r) > 70) {
        coordStats.continents.ocean++; // Count as oceanic/polar
      } else {
        coordStats.continents.islands++;
      }
    } else {
      coordStats.continents.islands++;
    }
  }
  
  // Generate comprehensive report
  console.log('\n📊 TERRAIN DISTRIBUTION:');
  console.log('─'.repeat(80));
  const sortedTerrain = Array.from(terrainMap.values()).sort((a, b) => b.count - a.count);
  for (const stats of sortedTerrain) {
    console.log(`${stats.terrain.padEnd(15)}: ${stats.count.toString().padStart(6)} tiles (${stats.percentage.toFixed(2)}%)`);
    console.log(``.padEnd(18) + `Elevation: ${stats.minElevation.toFixed(2)} - ${stats.maxElevation.toFixed(2)} (avg: ${stats.avgElevation.toFixed(2)})`);
    console.log(``.padEnd(18) + `Rivers: ${stats.hasRiver} | Features: ${stats.hasFeatures}`);
    console.log('');
  }
  
  console.log('\n🏞️ FEATURE DISTRIBUTION:');
  console.log('─'.repeat(80));
  const sortedFeatures = Array.from(featureMap.values()).sort((a, b) => b.count - a.count);
  for (const stats of sortedFeatures) {
    console.log(`${stats.feature.padEnd(20)}: ${stats.count.toString().padStart(6)} tiles`);
    console.log(``.padEnd(23) + `Found in: ${stats.terrainTypes.join(', ')}`);
    console.log('');
  }
  
  console.log('\n💎 RESOURCE DISTRIBUTION:');
  console.log('─'.repeat(80));
  if (resourceMap.size > 0) {
    const sortedResources = Array.from(resourceMap.values()).sort((a, b) => b.count - a.count);
    for (const stats of sortedResources) {
      console.log(`${stats.resource.padEnd(20)}: ${stats.count.toString().padStart(6)} tiles`);
      console.log(``.padEnd(23) + `Found in: ${stats.terrainTypes.join(', ')}`);
      console.log('');
    }
  } else {
    console.log('No resources found on the map');
  }
  
  console.log('\n🌍 COORDINATE STATISTICS:');
  console.log('─'.repeat(80));
  console.log(`Total Tiles: ${coordStats.totalTiles}`);
  console.log(`Map Bounds: Q[${coordStats.mapBounds.minQ}, ${coordStats.mapBounds.maxQ}], R[${coordStats.mapBounds.minR}, ${coordStats.mapBounds.maxR}]`);
  console.log(`Map Width: ${coordStats.mapBounds.maxQ - coordStats.mapBounds.minQ + 1} hexes`);
  console.log(`Map Height: ${coordStats.mapBounds.maxR - coordStats.mapBounds.minR + 1} hexes`);
  console.log('');
  console.log('Regional Distribution:');
  console.log(`  Drantium (West):  ${coordStats.continents.drantium} tiles`);
  console.log(`  Brontium (East):  ${coordStats.continents.brontium} tiles`);
  console.log(`  Islands:         ${coordStats.continents.islands} tiles`);
  console.log(`  Ocean/Polar:     ${coordStats.continents.ocean} tiles`);
  
  console.log('\n📈 SUMMARY STATISTICS:');
  console.log('─'.repeat(80));
  console.log(`Total tiles with rivers: ${totalRiverTiles} (${((totalRiverTiles/totalTiles)*100).toFixed(2)}%)`);
  console.log(`Total tiles with features: ${totalFeatureTiles} (${((totalFeatureTiles/totalTiles)*100).toFixed(2)}%)`);
  console.log(`Total tiles with resources: ${totalResourceTiles} (${((totalResourceTiles/totalTiles)*100).toFixed(2)}%)`);
  console.log(`Unique terrain types: ${terrainMap.size}`);
  console.log(`Unique features: ${featureMap.size}`);
  console.log(`Unique resources: ${resourceMap.size}`);
  
  // Generate markdown content
  const markdownContent = generateMarkdownReport(
    terrainMap, 
    featureMap, 
    resourceMap, 
    coordStats, 
    totalRiverTiles, 
    totalFeatureTiles, 
    totalResourceTiles
  );
  
  return {
    terrainStats: Array.from(terrainMap.values()),
    featureStats: Array.from(featureMap.values()),
    resourceStats: Array.from(resourceMap.values()),
    coordinateStats: coordStats,
    markdownContent
  };
}

function generateMarkdownReport(
  terrainMap: Map<string, TerrainStats>,
  featureMap: Map<string, FeatureStats>,
  resourceMap: Map<string, ResourceStats>,
  coordStats: CoordinateStats,
  totalRiverTiles: number,
  totalFeatureTiles: number,
  totalResourceTiles: number
): string {
  let md = '# Map Tiles Analysis - Altriux Tribal\n\n';
  md += `**Generated:** ${new Date().toISOString()}\n`;
  md += `**Total Tiles:** ${coordStats.totalTiles}\n\n`;
  
  md += '## 📊 Terrain Distribution\n\n';
  md += '| Terrain | Count | Percentage | Avg Elevation | Min Elevation | Max Elevation | Rivers | Features |\n';
  md += '|---------|-------|------------|---------------|---------------|---------------|--------|----------|\n';
  
  const sortedTerrain = Array.from(terrainMap.values()).sort((a, b) => b.count - a.count);
  for (const stats of sortedTerrain) {
    md += `| ${stats.terrain} | ${stats.count} | ${stats.percentage.toFixed(2)}% | ${stats.avgElevation.toFixed(2)} | ${stats.minElevation.toFixed(2)} | ${stats.maxElevation.toFixed(2)} | ${stats.hasRiver} | ${stats.hasFeatures} |\n`;
  }
  
  md += '\n## 🏞️ Feature Distribution\n\n';
  if (featureMap.size > 0) {
    md += '| Feature | Count | Found in Terrain Types |\n';
    md += '|---------|-------|----------------------|\n';
    
    const sortedFeatures = Array.from(featureMap.values()).sort((a, b) => b.count - a.count);
    for (const stats of sortedFeatures) {
      md += `| ${stats.feature} | ${stats.count} | ${stats.terrainTypes.join(', ')} |\n`;
    }
  } else {
    md += 'No features found on the map.\n';
  }
  
  md += '\n## 💎 Resource Distribution\n\n';
  if (resourceMap.size > 0) {
    md += '| Resource | Count | Found in Terrain Types |\n';
    md += '|----------|-------|----------------------|\n';
    
    const sortedResources = Array.from(resourceMap.values()).sort((a, b) => b.count - a.count);
    for (const stats of sortedResources) {
      md += `| ${stats.resource} | ${stats.count} | ${stats.terrainTypes.join(', ')} |\n`;
    }
  } else {
    md += 'No resources found on the map.\n';
  }
  
  md += '\n## 🌍 Map Statistics\n\n';
  md += `- **Total Tiles:** ${coordStats.totalTiles}\n`;
  md += `- **Map Bounds:** Q[${coordStats.mapBounds.minQ}, ${coordStats.mapBounds.maxQ}], R[${coordStats.mapBounds.minR}, ${coordStats.mapBounds.maxR}]\n`;
  md += `- **Map Width:** ${coordStats.mapBounds.maxQ - coordStats.mapBounds.minQ + 1} hexes\n`;
  md += `- **Map Height:** ${coordStats.mapBounds.maxR - coordStats.mapBounds.minR + 1} hexes\n\n`;
  
  md += '### Regional Distribution\n\n';
  md += '| Region | Tiles | Percentage |\n';
  md += '|--------|-------|------------|\n';
  md += `| Drantium (West) | ${coordStats.continents.drantium} | ${((coordStats.continents.drantium/coordStats.totalTiles)*100).toFixed(2)}% |\n`;
  md += `| Brontium (East) | ${coordStats.continents.brontium} | ${((coordStats.continents.brontium/coordStats.totalTiles)*100).toFixed(2)}% |\n`;
  md += `| Islands | ${coordStats.continents.islands} | ${((coordStats.continents.islands/coordStats.totalTiles)*100).toFixed(2)}% |\n`;
  md += `| Ocean/Polar | ${coordStats.continents.ocean} | ${((coordStats.continents.ocean/coordStats.totalTiles)*100).toFixed(2)}% |\n`;
  
  md += '\n## 📈 Summary\n\n';
  md += `- **Tiles with Rivers:** ${totalRiverTiles} (${((totalRiverTiles/coordStats.totalTiles)*100).toFixed(2)}%)\n`;
  md += `- **Tiles with Features:** ${totalFeatureTiles} (${((totalFeatureTiles/coordStats.totalTiles)*100).toFixed(2)}%)\n`;
  md += `- **Tiles with Resources:** ${totalResourceTiles} (${((totalResourceTiles/coordStats.totalTiles)*100).toFixed(2)}%)\n`;
  md += `- **Unique Terrain Types:** ${terrainMap.size}\n`;
  md += `- **Unique Features:** ${featureMap.size}\n`;
  md += `- **Unique Resources:** ${resourceMap.size}\n`;
  
  return md;
}

// Run the analysis
analyzeMapTiles()
  .then(result => {
    console.log('\n✅ Map tiles analysis completed!');
    console.log(`📄 Markdown report generated with ${result.markdownContent.length} characters`);
  })
  .catch(console.error);
