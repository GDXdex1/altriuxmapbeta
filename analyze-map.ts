import { generateEarthMap } from './src/lib/hexmap/generator';

async function main() {
    try {
        const tiles = await generateEarthMap(42, 1);
        const counts: Record<string, number> = {};
        const featureCounts: Record<string, number> = {};

        for (const tile of tiles.values()) {
            const t = tile.terrain as string;
            counts[t] = (counts[t] || 0) + 1;
            if (tile.features) {
                for (const feature of tile.features) {
                    const f = feature as string;
                    featureCounts[f] = (featureCounts[f] || 0) + 1;
                }
            }
        }

        console.log("--- Terrain Counts ---");
        console.log(JSON.stringify(counts, null, 2));
        console.log("\n--- Feature Counts ---");
        console.log(JSON.stringify(featureCounts, null, 2));
    } catch (e) {
        console.error(e);
    }
}

main();
