# Smart Contract Integration Guide

## Overview
This guide explains how to use the Altriux coordinate system and tile data in Move smart contracts for location-based gameplay, movement validation, and resource management.

## Tile Data Structure

### Complete Tile Export Format
When you export the complete map data, each tile includes:

```typescript
{
  q: number,              // Axial coordinate (column)
  r: number,              // Axial coordinate (row)
  x: number,              // Display coordinate (pixels)
  y: number,              // Display coordinate (pixels)
  terrain: TerrainType,   // Base biome
  features: TerrainFeature[],  // Forest, jungle, oasis, etc.
  resources: ResourceType[],   // Natural resources
  animals: AnimalType[],       // Animal populations
  minerals: MineralType[],     // Mineral deposits
  elevation: number,           // 0-10
  temperature: number,         // -50 to 50 °C
  rainfall: number,            // 0-100%
  hasVolcano: boolean,
  hasRiver: boolean,
  continent: 'drantium' | 'brontium',
  latitude: number,            // -90 to 90°
  hemisphere: 'northern' | 'southern' | 'equatorial',
  season: string              // Current season
}
```

## Move Contract Implementation

### Coordinate Storage
Store coordinates as a single u64 or as separate u32 values:

```move
// Option 1: Encode as single u64
public fun encode_coordinates(q: i32, r: i32): u64 {
    let q_u32 = if (q >= 0) { (q as u32) } else { ((q + 420) as u32) };
    let r_u32 = if (r >= 0) { (r as u32) } else { ((r + 220) as u32) };
    ((q_u32 as u64) << 32) | (r_u32 as u64)
}

// Option 2: Struct with signed integers (if supported)
struct HexCoord has copy, drop, store {
    q: u32,  // Offset by 210 to handle negatives: q_stored = q + 210
    r: u32,  // Offset by 110 to handle negatives: r_stored = r + 110
}
```

### Terrain Types (Enum Constants)

```move
// Terrain type constants
const TERRAIN_OCEAN: u8 = 0;
const TERRAIN_COAST: u8 = 1;
const TERRAIN_PLAINS: u8 = 2;
const TERRAIN_MEADOW: u8 = 3;
const TERRAIN_HILLS: u8 = 4;
const TERRAIN_MOUNTAIN_RANGE: u8 = 5;
const TERRAIN_TUNDRA: u8 = 6;
const TERRAIN_DESERT: u8 = 7;
const TERRAIN_ICE: u8 = 8;

// Feature type constants
const FEATURE_FOREST: u8 = 1;
const FEATURE_JUNGLE: u8 = 2;
const FEATURE_BOREAL_FOREST: u8 = 3;
const FEATURE_OASIS: u8 = 4;
const FEATURE_VOLCANO: u8 = 5;
const FEATURE_MOUNTAIN: u8 = 6;
const FEATURE_RIVER: u8 = 7;
```

### Distance Calculation

```move
public fun hex_distance(q1: u32, r1: u32, q2: u32, r2: u32): u32 {
    // Convert back to signed by subtracting offsets
    let q1_signed = (q1 as i32) - 210;
    let r1_signed = (r1 as i32) - 110;
    let q2_signed = (q2 as i32) - 210;
    let r2_signed = (r2 as i32) - 110;
    
    let dq = abs(q1_signed - q2_signed);
    let dr = abs(r1_signed - r2_signed);
    let ds = abs(q1_signed + r1_signed - q2_signed - r2_signed);
    
    ((dq + dr + ds) / 2) as u32
}
```

### Movement Validation

```move
public fun is_valid_move(
    from_q: u32, 
    from_r: u32, 
    to_q: u32, 
    to_r: u32,
    movement_range: u32
): bool {
    let distance = hex_distance(from_q, from_r, to_q, to_r);
    distance <= movement_range
}

public fun is_adjacent(q1: u32, r1: u32, q2: u32, r2: u32): bool {
    hex_distance(q1, r1, q2, r2) == 1
}
```

### Biome/Terrain Checks

```move
// Check if a coordinate is in a specific biome
public fun is_terrain_type(
    terrain_db: &Table<u64, u8>,  // Coordinate -> Terrain map
    q: u32,
    r: u32,
    expected_terrain: u8
): bool {
    let coord_key = encode_coordinates(q, r);
    let terrain = table::borrow(terrain_db, coord_key);
    *terrain == expected_terrain
}

// Check if coordinate has a specific feature
public fun has_feature(
    feature_db: &Table<u64, vector<u8>>,
    q: u32,
    r: u32,
    feature: u8
): bool {
    let coord_key = encode_coordinates(q, r);
    if (!table::contains(feature_db, coord_key)) return false;
    
    let features = table::borrow(feature_db, coord_key);
    vector::contains(features, &feature)
}
```

### Resource Management

```move
struct TileResources has store {
    natural_resources: vector<u8>,  // Wood, fish, wheat, etc.
    minerals: vector<u8>,            // Gold, silver, iron, etc.
    animals: vector<u8>,             // Horses, sheep, buffalo, etc.
}

public fun get_tile_resources(
    resource_db: &Table<u64, TileResources>,
    q: u32,
    r: u32
): &TileResources {
    let coord_key = encode_coordinates(q, r);
    table::borrow(resource_db, coord_key)
}

public fun has_resource(
    resource_db: &Table<u64, TileResources>,
    q: u32,
    r: u32,
    resource_type: u8
): bool {
    let coord_key = encode_coordinates(q, r);
    if (!table::contains(resource_db, coord_key)) return false;
    
    let resources = table::borrow(resource_db, coord_key);
    vector::contains(&resources.natural_resources, &resource_type) ||
    vector::contains(&resources.minerals, &resource_type)
}
```

### Continental System

```move
const CONTINENT_DRANTIUM: u8 = 1;
const CONTINENT_BRONTIUM: u8 = 2;

public fun get_continent(q: u32, r: u32): u8 {
    let q_signed = (q as i32) - 210;
    
    if (q_signed < 0) {
        CONTINENT_DRANTIUM  // West of meridian
    } else {
        CONTINENT_BRONTIUM  // East of meridian
    }
}

public fun is_in_drantium(q: u32): bool {
    let q_signed = (q as i32) - 210;
    q_signed < 0
}

public fun is_in_brontium(q: u32): bool {
    let q_signed = (q as i32) - 210;
    q_signed >= 0
}
```

### Hero Movement System

```move
struct Hero has key {
    id: UID,
    current_q: u32,
    current_r: u32,
    movement_points: u32,
}

public fun move_hero(
    hero: &mut Hero,
    terrain_db: &Table<u64, u8>,
    to_q: u32,
    to_r: u32
) {
    // Validate movement
    assert!(is_adjacent(hero.current_q, hero.current_r, to_q, to_r), E_NOT_ADJACENT);
    
    // Get movement cost based on terrain
    let coord_key = encode_coordinates(to_q, to_r);
    let terrain = table::borrow(terrain_db, coord_key);
    let cost = get_movement_cost(*terrain);
    
    assert!(hero.movement_points >= cost, E_INSUFFICIENT_MOVEMENT);
    
    // Execute move
    hero.current_q = to_q;
    hero.current_r = to_r;
    hero.movement_points = hero.movement_points - cost;
}

fun get_movement_cost(terrain: u8): u32 {
    if (terrain == TERRAIN_OCEAN) 0          // Can't walk on water
    else if (terrain == TERRAIN_PLAINS) 1
    else if (terrain == TERRAIN_MEADOW) 1
    else if (terrain == TERRAIN_HILLS) 2
    else if (terrain == TERRAIN_MOUNTAIN_RANGE) 3
    else if (terrain == TERRAIN_DESERT) 2
    else if (terrain == TERRAIN_TUNDRA) 2
    else 1
}
```

### Resource Extraction

```move
public fun extract_resource(
    hero: &Hero,
    resource_db: &mut Table<u64, TileResources>,
    resource_type: u8,
    amount: u64
): u64 {
    let coord_key = encode_coordinates(hero.current_q, hero.current_r);
    
    // Verify resource exists at location
    assert!(table::contains(resource_db, coord_key), E_NO_RESOURCES);
    
    let tile_resources = table::borrow_mut(resource_db, coord_key);
    
    // Implementation depends on how you track resource quantities
    // This is a simplified example
    amount  // Return extracted amount
}
```

## Data Import Strategy

### On-Chain Storage Options

**Option 1: Full Map On-Chain**
- Store complete tile data in smart contract tables
- Pro: Immediate access, no external dependencies
- Con: High gas costs for initial deployment
- Best for: Small maps or critical gameplay data

**Option 2: Merkle Tree Verification**
- Store Merkle root of tile data on-chain
- Keep full data off-chain
- Verify tile properties with Merkle proofs when needed
- Pro: Low on-chain storage cost
- Con: Requires off-chain data availability
- Best for: Large maps like Altriux (420×220)

**Option 3: Hybrid Approach** (Recommended for Altriux)
- Store critical data on-chain (terrain, continents)
- Keep detailed data (resources, features) off-chain
- Use events to track modifications
- Pro: Balance of cost and functionality
- Con: Requires careful architecture

### Sample Initialization

```move
public fun initialize_map(
    admin: &AdminCap,
    ctx: &mut TxContext
) {
    let terrain_db = table::new<u64, u8>(ctx);
    let feature_db = table::new<u64, vector<u8>>(ctx);
    let resource_db = table::new<u64, TileResources>(ctx);
    
    // Import from JSON export (would be done via multiple transactions)
    // For production, use batch import scripts
    
    transfer::share_object(MapData {
        id: object::new(ctx),
        terrain: terrain_db,
        features: feature_db,
        resources: resource_db,
    });
}
```

## Best Practices

1. **Use Coordinate Encoding**: Always encode (q,r) into a single u64 key for efficient table lookups
2. **Batch Operations**: Import map data in batches to manage gas costs
3. **Event Emission**: Emit events when tiles are modified for off-chain indexing
4. **Validation Layers**: Validate movements and actions before state changes
5. **Resource Regeneration**: Implement time-based resource regeneration if applicable

## Integration Workflow

1. **Export Map Data**: Use the terrain editor to export complete map JSON
2. **Process Data**: Convert JSON to Move-compatible format
3. **Deploy Tables**: Initialize on-chain storage structures
4. **Import Data**: Batch-import critical tile data
5. **Implement Logic**: Build gameplay mechanics using coordinate functions
6. **Test**: Verify distance calculations, movement, and resource checks

## Example Usage in Altriux

```move
// Check if hero can harvest wheat
public fun can_harvest_wheat(hero: &Hero, map: &MapData): bool {
    let q = hero.current_q;
    let r = hero.current_r;
    
    // Must be in Brontium (wheat is temperate crop)
    if (!is_in_brontium(q)) return false;
    
    // Must be in meadow or plains
    let terrain = get_terrain(map, q, r);
    if (terrain != TERRAIN_MEADOW && terrain != TERRAIN_PLAINS) return false;
    
    // Must have wheat resource
    has_resource(&map.resources, q, r, RESOURCE_WHEAT)
}
```
