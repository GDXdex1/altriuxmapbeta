import { generateEarthMap } from './src/lib/hexmap/generator';
import { generateAllRiversImproved } from './src/lib/hexmap/river-system-improved';

/**
 * Test the improved river generation system
 */

async function testImprovedRivers() {
  console.log('🧪🧪🧪 TESTING IMPROVED RIVER GENERATION 🧪🧪🧪');
  
  // Generate map
  const tiles = await generateEarthMap(42, 1);
  console.log(`✅ Map generated with ${tiles.size} tiles`);
  
  // Count terrain types
  const terrainCounts: Record<string, number> = {};
  for (const tile of tiles.values()) {
    terrainCounts[tile.terrain] = (terrainCounts[tile.terrain] || 0) + 1;
  }
  
  console.log('📊 Terrain distribution:');
  for (const [terrain, count] of Object.entries(terrainCounts)) {
    console.log(`   ${terrain}: ${count} tiles`);
  }
  
  // Test improved river generation
  console.log('🚀🚀🚀 TESTING IMPROVED RIVER ALGORITHM 🚀🚀🚀');
  
  const startTime = Date.now();
  
  const rivers = generateAllRiversImproved(tiles, {
    minLength: 6,  // Reduced minimum for better success
    maxAttempts: 100,
    flowToOcean: true,
    allowLakes: false
  }, 15); // Target 15 rivers
  
  const endTime = Date.now();
  const duration = endTime - startTime;
  
  console.log(`✅ Improved river generation completed in ${duration}ms`);
  console.log(`🌊 Generated ${rivers.length} rivers (target: 15)`);
  
  if (rivers.length > 0) {
    const avgLength = rivers.reduce((sum, river) => sum + river.length, 0) / rivers.length;
    console.log(`📏 Average river length: ${avgLength.toFixed(1)} tiles`);
    
    // Show sample rivers
    console.log('🔍 Sample rivers:');
    for (let i = 0; i < Math.min(5, rivers.length); i++) {
      const river = rivers[i];
      console.log(`   River ${i + 1}: ${river.length} tiles from (${river.source.q},${river.source.r}) to (${river.mouth.q},${river.mouth.r})`);
    }
    
    // Calculate success rate
    const successRate = (rivers.length / 15) * 100;
    console.log(`📈 Success rate: ${successRate.toFixed(1)}%`);
    
    if (successRate >= 50) {
      console.log('🎉 EXCELLENT: Success rate 50% or higher!');
    } else if (successRate >= 30) {
      console.log('✅ GOOD: Success rate 30% or higher!');
    } else {
      console.log('⚠️ NEEDS IMPROVEMENT: Success rate below 30%');
    }
  }
  
  // Count tiles with river feature
  const tilesWithRiver = Array.from(tiles.values()).filter(t => t.features?.includes('river'));
  console.log(`🏞️ ${tilesWithRiver.length} tiles marked with river feature`);
  
  console.log('🧪🧪🧪 IMPROVED RIVER TEST COMPLETE 🧪🧪🧪');
}

// Run the test
testImprovedRivers().catch(console.error);
