module altriux::altriuxland {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use sui::clock::Clock;
    use std::vector;
    use altriux::altriuxresources::{Inventory, add_jax, consume_jax};
    use altriux::kingdomutils;
    use std::option::{Self, Option};
    use sui::transfer;
    use sui::coin::{Coin};
    use altriux::agc::{Self, AGCTreasury, AGC};
    use sui::event;

    // --- Constants ---
    // --- Land Hierarchy ---
    const XLANDS_PER_HEX: u64 = 9919;   // Level 2 (1km²)
    const PARCELS_PER_XLAND: u64 = 91;   // Level 3 (1 hectare)

    // --- Global Land Census (Level 1 counts) ---
    const CENSUS_OCEAN: u64 = 48788;
    const CENSUS_TUNDRA: u64 = 7070;
    const CENSUS_ICE: u64 = 1062;
    const CENSUS_DESERT: u64 = 2614;
    const CENSUS_MEADOW: u64 = 2713;
    const CENSUS_PLAINS: u64 = 2084;
    const CENSUS_COAST: u64 = 3174;
    const CENSUS_MOUNTAIN_RANGE: u64 = 1535;
    const CENSUS_HILLS: u64 = 1310;

    // --- Biome Type IDs (Level 1/2) ---
    const BIOME_OCEAN: u8 = 1;
    const BIOME_TUNDRA: u8 = 2;
    const BIOME_ICE: u8 = 3;
    const BIOME_DESERT: u8 = 4;
    const BIOME_MEADOW: u8 = 5;
    const BIOME_PLAINS: u8 = 6;
    const BIOME_COAST: u8 = 7;
    const BIOME_MOUNTAIN_RANGE: u8 = 8;
    const BIOME_HILLS: u8 = 9;

    // --- Terrain Features (Characteristics) ---
    const FEATURE_NONE: u8 = 0;
    const FEATURE_BOREAL_FOREST: u8 = 1;
    const FEATURE_FOREST: u8 = 2; // Mixed into Hills/Meadow
    const FEATURE_JUNGLE: u8 = 3; // Mixed into Hills/Meadow
    const FEATURE_OASIS: u8 = 4;
    const FEATURE_VOLCANO: u8 = 5;
    const FEATURE_MOUNTAIN_PEAK: u8 = 6;
    const FEATURE_RIVER_SYSTEM: u8 = 7;

    // --- Resource Types ---
    const RESOURCE_STANDARD: u8 = 0;
    const RESOURCE_MINE_GOLD: u8 = 1;
    const RESOURCE_MINE_SILVER: u8 = 2;
    const RESOURCE_MINE_IRON: u8 = 3;
    const RESOURCE_MINE_COPPER: u8 = 4;
    const RESOURCE_MINE_TIN: u8 = 5;
    const RESOURCE_MINE_STONE: u8 = 7;
    const RESOURCE_MINE_GEMS: u8 = 8;
    const RESOURCE_FARMLAND_WHEAT: u8 = 9;
    const RESOURCE_FARMLAND_COTTON: u8 = 10;
    const RESOURCE_FARMLAND_SPICES: u8 = 11;
    const RESOURCE_COASTAL_LAND: u8 = 12;
    const RESOURCE_COASTAL_INLAND: u8 = 13;

    // Levels (removed sublands/small_lands constants)

    const E_INVALID_SEED: u64 = 104;
    const E_NOT_AUTHORIZED: u64 = 105;
    const E_INSUFFICIENT_PAYMENT: u64 = 107;

    const LAND_PRICE_AGC: u64 = 20_000_000_000; // 20 AGC (9 decimals)

    // --- Structs ---

    public struct LandRegistry has key {
        id: UID,
        lands: Table<u64, Land>, 
        admin: address,
    }

    public struct DiscoveryMap has key {
        id: UID,
        explored: Table<vector<u8>, bool>, // coordinate key -> true
    }

    /// Land NFT represents an xLand (SubLand) - 1km² hexagon
    /// 
    /// Hierarchy:
    /// - Level 1: Large Hex (100km²) - ~70,350 total
    /// - Level 2: xLand (1km²) - 9,919 per Large Hex (THIS NFT)
    /// - Level 3: Parcel (1 hectare) - 91 per xLand (frontend only, not minted)
    ///
    /// Lazy generation: xLand NFTs only minted when purchased for 20 AGC
    /// Parcels are managed off-chain for building placement
    public struct Land has key, store {
        id: UID,
        // Parent hex coordinates (Large Hex: Level 1)
        parent_q: u64,
        parent_r: u64,
        parent_q_is_neg: bool,
        parent_r_is_neg: bool,
        
        // xLand coordinates within parent hex (Level 2: radius 58, range -58 to +58)
        // Formula: 3R² - 3R + 1 = 3(58²) - 3(58) + 1 = 9,919 xLands per Large Hex
        subland_q: u64,
        subland_r: u64,
        subland_q_is_neg: bool,
        subland_r_is_neg: bool,
        
        // Terrain data
        terrain: u8,           // Legacy field for compatibility
        feature: u8,           // Characteristics (Forest, Jungle, Oasis, etc.)
        biome_type: u8,        // 1-9: Ice, Tundra, Desert, Plains, Hills, Meadow, MountainRange, Coast, Ocean
        resource_type: u8,     // 0-13: Metadata for deposits/yields
        
        // River data
        has_river: bool,
        is_navigable_river: bool,
        slope: u8,             // Slope in degrees (0-90)
    }

    /// LandParcel NFT represents a 1-hectare parcel within an xLand tile
    /// 
    /// Hierarchy:
    /// - Level 2: xLand (1km²) - Parent Land NFT
    /// - Level 3: Parcel (1 hectare) - THIS NFT (91 per xLand)
    ///
    /// Each xLand tile contains 91 parcel NFTs that can be individually owned and traded
    /// LandParcel object represents a 1-hectare parcel within an xLand tile
    /// 
    /// Hierarchy:
    /// - Level 2: xLand (1km²) - Parent Land NFT
    /// - Level 3: Parcel (1 hectare) - THIS OBJECT (91 per xLand)
    ///
    /// These are NOT standard NFTs (no store ability). They reside in the owner's account
    /// and can only be transferred or rented via specific contract functions.
    public struct LandParcel has key {
        id: UID,
        parent_land_id: ID,           // Reference to parent xLand tile
        parcel_index: u64,            // 0-90 (91 parcels per tile)
        owner: address,               // Current owner
        renter: Option<address>,      // Current renter (if any)
        rent_expiry: u64,             // Rent expiration timestamp
        // Parcel-specific data (inherited from parent but can diverge)
        ag_biome: u8,                 // Agricultural biome (from altriuxagbiome)
        fertility_bp: u64,            // Soil fertility (10000 = 100%)
        has_irrigation: bool,         // Irrigation system installed
        // Parcel coordinates within parent (optional, for spatial reference)
        local_q: u8,                  // Local hex coordinate within xLand
        local_r: u8,
    }

    // --- Events ---
    public struct MapExplored has copy, drop {
        q: u64,
        r: u64,
        q_neg: bool,
        r_neg: bool,
        terrain: u8,
        explorer: address,
    }

    public struct SubLandPurchased has copy, drop {
        parent_q: u64,
        parent_r: u64,
        subland_q: u64,
        subland_r: u64,
        biome_type: u8,
        resource_type: u8,
        buyer: address,
        land_id: ID,
    }

    public struct ParcelMinted has copy, drop {
        parcel_id: ID,
        parent_land_id: ID,
        parcel_index: u64,
        owner: address,
        ag_biome: u8,
    }

    public struct ParcelTransferred has copy, drop {
        parcel_id: ID,
        from: address,
        to: address,
    }

    // --- Initialization ---

    fun init(ctx: &mut TxContext) {
        transfer::share_object(LandRegistry {
            id: object::new(ctx),
            lands: table::new(ctx),
            admin: tx_context::sender(ctx),
        });
        transfer::share_object(DiscoveryMap {
            id: object::new(ctx),
            explored: table::new(ctx),
        });
    }

    // --- Logic ---

    public fun get_land_info(land: &Land): (u64, u64, bool, bool, u8, u8) {
        (land.parent_q, land.parent_r, land.parent_q_is_neg, land.parent_r_is_neg, land.terrain, land.feature)
    }

    public fun get_land_biome(land: &Land): u8 {
        land.biome_type
    }

    public fun get_river_status(land: &Land): bool {
        land.has_river
    }

    public fun has_river(land: &Land): bool {
        land.has_river
    }

    public fun is_owner_of_land(reg: &LandRegistry, land_id: u64, _owner: address): bool {
        // Simple check: if it exists in registry. 
        // Real logic should check ownership of the Land NFT if it's already bought.
        table::contains(&reg.lands, land_id)
    }

    public fun borrow_land(reg: &LandRegistry, land_id: u64): &Land {
        table::borrow(&reg.lands, land_id)
    }

    public fun get_land_uid_mut(land: &mut Land): &mut UID {
        &mut land.id
    }

    public fun get_default_feature(biome: u8): u8 {
        if (biome == BIOME_DESERT) { FEATURE_OASIS }
        else if (biome == BIOME_TUNDRA) { FEATURE_BOREAL_FOREST }
        else if (biome == BIOME_MOUNTAIN_RANGE) { FEATURE_MOUNTAIN_PEAK }
        else { FEATURE_NONE }
    }

    public fun get_agricultural_biome(land: &Land): u8 {
        // First check characteristics (features) as they override base for agriculture
        if (land.feature == FEATURE_FOREST) { return 3 }; // Ag-Forest
        if (land.feature == FEATURE_JUNGLE) { return 4 }; // Ag-Jungle

        if (land.biome_type == BIOME_TUNDRA) { return 9 }; // Ag-Tundra
        if (land.biome_type == BIOME_MOUNTAIN_RANGE) {
            if (land.slope > 25) { return 2 }; // Ag-Cordillera simulada (Plains/Cordillera?) 
            // In ag_biome, 1 is Mountain.
            return 1 // Ag-Mountain
        };
        if (land.biome_type == BIOME_MEADOW) { return 7 }; // Ag-Meadow
        if (land.biome_type == BIOME_HILLS) { return 8 }; // Ag-Hills
        if (land.biome_type == BIOME_PLAINS) { return 2 }; // Ag-Plains
        if (land.biome_type == BIOME_DESERT) {
            if (land.feature == FEATURE_OASIS) { return 5 }; // Ag-Desert (with Oasis)
            return 0 // Non-cultivable desert
        };
        if (land.biome_type == BIOME_COAST) { return 6 }; // Ag-Coast
        0
    }

    public fun has_irrigation(land: &Land): bool {
        // Rivers or irrigation infrastructure (placeholder logic)
        land.has_river || land.is_navigable_river
    }

    // --- Spatial Hierarchy IDs ---

    /// Generates a globally unique ID for a Level 3 Parcel.
    /// Hierarchy:
    /// - Level 1: Hex (Large) ~ 70,350
    /// - Level 2: xLand 9,919
    /// - Level 3: Parcel 91
    public fun compute_tile_id(hex_idx: u64, subland_idx: u64, parcel_idx: u64): u64 {
        assert!(subland_idx < XLANDS_PER_HEX, 106);
        assert!(parcel_idx < PARCELS_PER_XLAND, 106);
        // Formula: (hex * MAX_L2 * MAX_L3) + (l2 * MAX_L3) + l3
        (hex_idx * 9919 * 91) + (subland_idx * 91) + parcel_idx
    }

    /// Decomposes a unique tile ID back into its components: (hex_idx, subland_idx, parcel_idx).
    public fun decompose_tile_id(tile_id: u64): (u64, u64, u64) {
        let parcel_idx = tile_id % 91;
        let subland_idx = (tile_id / 91) % 9919;
        let hex_idx = tile_id / (9919 * 91);
        (hex_idx, subland_idx, parcel_idx)
    }

    /// Signed absolute difference between two values
    fun abs_diff(v1: u64, n1: bool, v2: u64, n2: bool): u64 {
        if (n1 == n2) {
            if (v1 > v2) v1 - v2 else v2 - v1
        } else {
            v1 + v2
        }
    }

    /// Signed sum of two values: returns (val, is_neg)
    fun signed_sum(v1: u64, n1: bool, v2: u64, n2: bool): (u64, bool) {
        if (n1 == n2) {
            (v1 + v2, n1)
        } else {
            if (v1 > v2) {
                (v1 - v2, n1)
            } else {
                (v2 - v1, n2)
            }
        }
    }

    /// Calculates Manhattan distance between two lands given their hex coordinates.
    public fun calculate_land_distance(q1: u64, r1: u64, q1_neg: bool, r1_neg: bool, q2: u64, r2: u64, q2_neg: bool, r2_neg: bool): u64 {
        // Cubic coordinates: s = -q - r
        let (qv1_r, qn1_r) = signed_sum(q1, q1_neg, r1, r1_neg);
        let s1_v = qv1_r;
        let mut s1_n = !qn1_r;
        if (s1_v == 0) s1_n = false;

        let (qv2_r, qn2_r) = signed_sum(q2, q2_neg, r2, r2_neg);
        let s2_v = qv2_r;
        let mut s2_n = !qn2_r;
        if (s2_v == 0) s2_n = false;

        let dq = abs_diff(q1, q1_neg, q2, q2_neg);
        let dr = abs_diff(r1, r1_neg, r2, r2_neg);
        let ds = abs_diff(s1_v, s1_n, s2_v, s2_n);

        let mut max = dq;
        if (dr > max) max = dr;
        if (ds > max) max = ds;

        max
    }

    /// Helper to get distance between two lands by their registry IDs.
    public fun get_distance_by_ids(registry: &LandRegistry, id1: u64, id2: u64): u64 {
        let l1 = table::borrow(&registry.lands, id1);
        let l2 = table::borrow(&registry.lands, id2);
        calculate_land_distance(l1.parent_q, l1.parent_r, l1.parent_q_is_neg, l1.parent_r_is_neg, 
                               l2.parent_q, l2.parent_r, l2.parent_q_is_neg, l2.parent_r_is_neg)
    }

    // --- Exploration ---

    /// Explores a new map hex (Large Tile).
    /// Registers the hex as discovered so SubLands can be purchased later.
    /// Does NOT create 10,000 NFTs - uses lazy generation.
    public fun explore_land(
        discovery: &mut DiscoveryMap,
        q: u64,
        r: u64,
        q_neg: bool,
        r_neg: bool,
        terrain: u8,
        ctx: &mut TxContext
    ) {
        let coord_key = format_coords(q, r, q_neg, r_neg);
        assert!(!table::contains(&discovery.explored, coord_key), 109); // Already explored
        
        table::add(&mut discovery.explored, coord_key, true);

        event::emit(MapExplored {
            q,
            r,
            q_neg,
            r_neg,
            terrain,
            explorer: tx_context::sender(ctx),
        });
    }

    /// Allows a user to buy a specific SubLand (xLand) for 20 AGC.
    /// Requirements:
    /// 1. Physical presence: Hero must be on this exact subland
    /// 2. Parent hex must be explored
    /// 3. Payment of 20 AGC
    ///
    /// Creates a Land NFT representing the purchased SubLand with full metadata.
    public fun buy_subland(
        discovery: &DiscoveryMap,
        agc_treasury: &mut AGCTreasury,
        payment: Coin<AGC>,
        // Parent hex coordinates
        parent_q: u64,
        parent_r: u64,
        parent_q_neg: bool,
        parent_r_neg: bool,
        // SubLand coordinates within parent
        subland_q: u64,
        subland_r: u64,
        subland_q_neg: bool,
        subland_r_neg: bool,
        // Terrain metadata
        terrain: u8,
        feature: u8,
        biome_type: u8,
        resource_type: u8,
        has_river: bool,
        is_navigable_river: bool,
        slope: u8,
        ctx: &mut TxContext
    ) {
        // 1. Verify parent hex is explored
        let coord_key = format_coords(parent_q, parent_r, parent_q_neg, parent_r_neg);
        assert!(table::contains(&discovery.explored, coord_key), 110); // Parent hex not explored

        // 2. Verify Hero is at this exact subland
        // TODO: Implement get_subland_position in altriuxhero
        // For now, we trust the frontend to call this correctly

        // 3. Verify payment
        assert!(sui::coin::value(&payment) >= LAND_PRICE_AGC, E_INSUFFICIENT_PAYMENT);
        
        // 4. Burn payment and update remint pool
        agc::burn_for_land(agc_treasury, payment);

        // 5. Mint SubLand NFT with full metadata
        let land = Land {
            id: object::new(ctx),
            parent_q,
            parent_r,
            parent_q_is_neg: parent_q_neg,
            parent_r_is_neg: parent_r_neg,
            subland_q,
            subland_r,
            subland_q_is_neg: subland_q_neg,
            subland_r_is_neg: subland_r_neg,
            terrain,
            feature,
            biome_type,
            resource_type,
            has_river,
            is_navigable_river,
            slope,
        };

        let buyer = tx_context::sender(ctx);

        // Emit event for DApp synchronization
        event::emit(SubLandPurchased {
            parent_q,
            parent_r,
            subland_q,
            subland_r,
            biome_type,
            resource_type,
            buyer,
            land_id: object::uid_to_inner(&land.id),
        });

        // 6. Transfer to buyer
        transfer::public_transfer(land, buyer);
    }

    /// Legacy buy_land for backwards compatibility (deprecated)
    /// Use buy_subland instead
    public fun buy_land(
        registry: &mut LandRegistry,
        agc_treasury: &mut AGCTreasury,
        payment: Coin<AGC>,
        land_id: u64,
        ctx: &mut TxContext
    ) {
        // This function is deprecated but kept for migration
        // TODO: Remove after frontend updates
        
        // Verify payment
        assert!(sui::coin::value(&payment) >= LAND_PRICE_AGC, E_INSUFFICIENT_PAYMENT);
        
        // Burn payment
        agc::burn_for_land(agc_treasury, payment);

        // Remove from old registry and transfer
        let land = table::remove(&mut registry.lands, land_id);
        transfer::public_transfer(land, tx_context::sender(ctx));
    }

    fun format_coords(q: u64, r: u64, q_neg: bool, r_neg: bool): vector<u8> {
        let mut res = vector::empty<u8>();
        if (q_neg) vector::push_back(&mut res, 45); // '-'
        append_u64(&mut res, q);
        vector::push_back(&mut res, 58); // ':'
        if (r_neg) vector::push_back(&mut res, 45); // '-'
        append_u64(&mut res, r);
        res
    }

    fun append_u64(res: &mut vector<u8>, mut val: u64) {
        if (val == 0) {
            vector::push_back(res, 48);
            return
        };
        let mut temp = vector::empty<u8>();
        while (val > 0) {
            vector::push_back(&mut temp, ((val % 10) + 48 as u8));
            val = val / 10;
        };
        vector::reverse(&mut temp);
        vector::append(res, temp);
    }

    // === PARCEL OBJECT MANAGEMENT ===
    
    /// Mint 91 parcel objects for an xLand tile (called after land purchase)
    public fun mint_land_parcels(
        land: &Land,
        ctx: &mut TxContext
    ): vector<LandParcel> {
        let land_id = object::id(land);
        let owner = tx_context::sender(ctx);
        let ag_biome = get_agricultural_biome(land);
        
        let mut i = 0;
        // Mint and transfer directly to owner
        while (i < PARCELS_PER_XLAND) {
            let local_q = ((i % 10) as u8);
            let local_r = ((i / 10) as u8);
            
            let parcel = LandParcel {
                id: object::new(ctx),
                parent_land_id: land_id,
                parcel_index: i,
                owner,
                renter: option::none(),
                rent_expiry: 0,
                ag_biome,
                fertility_bp: 10000,
                has_irrigation: false,
                local_q,
                local_r,
            };
            
            let parcel_id = object::id(&parcel);
            event::emit(ParcelMinted {
                parcel_id,
                parent_land_id: land_id,
                parcel_index: i,
                owner,
                ag_biome,
            });
            
            // Transfer to owner using standard transfer (it has key)
            // Since it has NO store, it cannot be transferred freely outside this module
            transfer::transfer(parcel, owner);
            
            i = i + 1;
        };
        
        vector::empty() // Return empty vector as ownership is already transferred
    }
    
    /// Transfer parcel ownership (Custom implementation for non-store objects)
    public fun transfer_parcel(parcel: LandParcel, recipient: address, _ctx: &mut TxContext) {
        let mut p = parcel;
        // Reset rental state on transfer
        p.renter = option::none();
        p.rent_expiry = 0;
        p.owner = recipient;
        
        let parcel_id = object::id(&p);
        event::emit(ParcelTransferred { parcel_id, from: tx_context::sender(_ctx), to: recipient });
        
        transfer::transfer(p, recipient);
    }
    
    /// Rent a parcel to another user
    public fun rent_parcel(
        parcel: &mut LandParcel, 
        renter: address, 
        duration_ms: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(parcel.owner == sender, E_NOT_AUTHORIZED);
        
        let now = sui::clock::timestamp_ms(clock);
        parcel.renter = option::some(renter);
        parcel.rent_expiry = now + duration_ms;
    }
    
    /// Reclaim a parcel after rent expires (or if owner wants to revoke early if allowed)
    public fun reclaim_rental(
        parcel: &mut LandParcel,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(parcel.owner == sender, E_NOT_AUTHORIZED);
        
        let now = sui::clock::timestamp_ms(clock);
        if (now >= parcel.rent_expiry) {
            parcel.renter = option::none();
            parcel.rent_expiry = 0;
        };
    }
    
    /// Get effective user (renter if active, else owner)
    public fun get_parcel_active_user(parcel: &LandParcel, clock: &Clock): address {
        let now = sui::clock::timestamp_ms(clock);
        if (option::is_some(&parcel.renter) && now < parcel.rent_expiry) {
            *option::borrow(&parcel.renter)
        } else {
            parcel.owner
        }
    }
    
    public fun get_parcel_owner(parcel: &LandParcel): address { parcel.owner }
    public fun get_parcel_ag_biome(parcel: &LandParcel): u8 { parcel.ag_biome }
    public fun get_parcel_fertility(parcel: &LandParcel): u64 { parcel.fertility_bp }
    public fun update_parcel_fertility(parcel: &mut LandParcel, new_fertility: u64) {
        parcel.fertility_bp = new_fertility;
    }
    public fun parcel_has_irrigation(parcel: &LandParcel): bool { parcel.has_irrigation }
    public fun install_parcel_irrigation(parcel: &mut LandParcel) { parcel.has_irrigation = true; }
    
    // Getters for UID to allow dynamic fields from other modules
    public fun get_parcel_uid(parcel: &LandParcel): &UID { &parcel.id }
    public fun get_parcel_uid_mut(parcel: &mut LandParcel): &mut UID { &mut parcel.id }
    
    public fun get_parcel_index(parcel: &LandParcel): u64 { parcel.parcel_index }

    public fun get_land_biome_by_id(reg: &LandRegistry, land_id: u64): u8 {
        if (table::contains(&reg.lands, land_id)) {
            let land = table::borrow(&reg.lands, land_id);
            land.biome_type
        } else {
            0
        }
    }

    #[test_only]
    public fun create_land_for_testing(
        parent_q: u64, parent_r: u64, parent_q_neg: bool, parent_r_neg: bool,
        subland_q: u64, subland_r: u64, subland_q_neg: bool, subland_r_neg: bool,
        terrain: u8, feature: u8, biome_type: u8, resource_type: u8,
        has_river: bool, is_navigable_river: bool, slope: u8,
        ctx: &mut TxContext
    ): Land {
        Land {
            id: object::new(ctx),
            parent_q, parent_r, parent_q_is_neg: parent_q_neg, parent_r_is_neg: parent_r_neg,
            subland_q, subland_r, subland_q_is_neg: subland_q_neg, subland_r_is_neg: subland_r_neg,
            terrain, feature, biome_type, resource_type,
            has_river, is_navigable_river, slope
        }
    }

    #[test_only]
    public fun destroy_land_for_testing(land: Land) {
        let Land {
            id,
            parent_q: _, parent_r: _, parent_q_is_neg: _, parent_r_is_neg: _,
            subland_q: _, subland_r: _, subland_q_is_neg: _, subland_r_is_neg: _,
            terrain: _, feature: _, biome_type: _, resource_type: _,
            has_river: _, is_navigable_river: _, slope: _
        } = land;
        object::delete(id);
    }
}
