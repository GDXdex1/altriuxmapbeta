#[allow(unused_const, duplicate_alias, unused_use, unused_variable)]
module altriux::altriuxlocation {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::table::{Self, Table};
    use std::vector;
    use std::ascii;

    // === SISTEMA DE COORDENADAS HEXAGONALES (420×220) ===
    // Rango completo: q ∈ [-210, +209], r ∈ [-110, +109]
    // Offset encoding: q_stored = q + 210, r_stored = r + 110 → ambos en [0, 419] y [0, 219]
    
    // === BIOMAS (Terrain Types) ===
    const TERRAIN_OCEAN: u8 = 0;
    const TERRAIN_COAST: u8 = 1;
    const TERRAIN_PLAINS: u8 = 2;
    const TERRAIN_MEADOW: u8 = 3;
    const TERRAIN_HILLS: u8 = 4;
    const TERRAIN_MOUNTAIN_RANGE: u8 = 5;
    const TERRAIN_TUNDRA: u8 = 6;
    const TERRAIN_DESERT: u8 = 7;
    const TERRAIN_ICE: u8 = 8;
    const TERRAIN_SWAMP: u8 = 13;

    // === CARACTERÍSTICAS (Features) ===
    const FEATURE_NONE: u8 = 0;
    const FEATURE_FOREST: u8 = 1;
    const FEATURE_JUNGLE: u8 = 2;
    const FEATURE_BOREAL_FOREST: u8 = 3;
    const FEATURE_OASIS: u8 = 4;
    const FEATURE_VOLCANO: u8 = 5;
    const FEATURE_MOUNTAIN_PEAK: u8 = 6;
    const FEATURE_RIVER: u8 = 7;
    const FEATURE_LAKE: u8 = 8;
    const FEATURE_CAVE: u8 = 9;
    const FEATURE_MINERAL_DEPOSIT: u8 = 10;
    const FEATURE_ANIMAL_HERD: u8 = 11;
    const FEATURE_SWAMP: u8 = 12;

    // === CONTINENTES ===
    const CONTINENT_DRANTIUM: u8 = 1;  // Oeste (q < 0)
    const CONTINENT_BRONTIUM: u8 = 2;  // Este (q >= 0)

    // === HEMISFERIOS ===
    const HEMISPHERE_NORTHERN: u8 = 1;
    const HEMISPHERE_SOUTHERN: u8 = 2;
    const HEMISPHERE_EQUATORIAL: u8 = 3;

    // === ESTACIONES ===
    const SEASON_SPRING: u8 = 1;
    const SEASON_SUMMER: u8 = 2;
    const SEASON_AUTUMN: u8 = 3;
    const SEASON_WINTER: u8 = 4;

    // === ERRORES ===
    const E_INVALID_COORDINATES: u64 = 101;
    const E_NOT_ADJACENT: u64 = 102;
    const E_OUT_OF_BOUNDS: u64 = 103;

    // === STRUCTS ===
    public struct LocationRegistry has key {
        id: UID,
        // Mapa completo de terrenos: coord_key (u64) -> terrain_type (u8)
        terrain_map: Table<u64, u8>,
        // Mapa de características: coord_key -> vector<feature_type>
        feature_map: Table<u64, vector<u8>>,
        // Mapa de recursos naturales: coord_key -> TileResources
        resource_map: Table<u64, TileResources>,
    }

    // === UBICACIÓN DE RECURSOS (Global) ===
    // Almacena coordenadas completas para permitir cálculo de distancia off-chain y on-chain
    public struct ResourceLocation has store, copy, drop {
        h_q: u64, 
        h_r: u64, 
        s_q: u64, 
        s_r: u64,
        land_id: ID, 
        tile_id: u64 
    }

    public struct TileResources has store {
        natural_resources: vector<u8>,  // 1=Wheat, 2=Barley, 3=Olives, etc.
        minerals: vector<u8>,            // 115=Iron, 116=Tin, 124=Galena, etc.
        animals: vector<u8>,             // 40=Sheep, 44=Cattle, 48=Horse, etc.
        elevation: u8,                   // 0-10 (0=sea level, 10=peak)
        temperature: u8,                 // 0-100 (Offset 50: 50 = 0°C)
        rainfall: u8,                    // 0-100%
        continent: u8,                   // 1=Drantium, 2=Brontium
        hemisphere: u8,                  // 1=Northern, 2=Southern, 3=Equatorial
        season: u8,                      // 1=Spring, 2=Summer, 3=Autumn, 4=Winter
    }

    // === INICIALIZACIÓN DEL REGISTRO ===
    public fun init_location_registry(ctx: &mut TxContext) {
        let registry = LocationRegistry {
            id: object::new(ctx),
            terrain_map: table::new(ctx),
            feature_map: table::new(ctx),
            resource_map: table::new(ctx),
        };
        transfer::share_object(registry);
    }

    // === CODIFICACIÓN/DECODIFICACIÓN DE COORDENADAS ===
    public fun encode_coordinates(q: u64, r: u64): u64 {
        // q and r are already offset-encoded (0-419, 0-219)
        (q << 32) | r
    }

    public fun decode_coordinates(coord_key: u64): (u64, u64) {
        let q = (coord_key >> 32) & 0xFFFFFFFF;
        let r = coord_key & 0xFFFFFFFF;
        (q, r)
    }

    // === CÁLCULO DE DISTANCIA HEXAGONAL ===
    public fun hex_distance(q1: u64, r1: u64, q2: u64, r2: u64): u32 {
        let dq = if (q1 > q2) { q1 - q2 } else { q2 - q1 };
        let dr = if (r1 > r2) { r1 - r2 } else { r2 - r1 };
        // ds = abs((q1+r1) - (q2+r2))
        let sum1 = q1 + r1;
        let sum2 = q2 + r2;
        let ds = if (sum1 > sum2) { sum1 - sum2 } else { sum2 - sum1 };
        
        ((dq + dr + ds) / 2) as u32
    }

    /// Helper for signed absolute difference
    fun abs_diff(v1: u64, n1: bool, v2: u64, n2: bool): u64 {
        if (n1 == n2) {
            if (v1 > v2) v1 - v2 else v2 - v1
        } else {
            v1 + v2
        }
    }

    /// Helper for signed sum: returns (val, is_neg)
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

    public fun hex_distance_signed(
        q1: u64, r1: u64, q1_n: bool, r1_n: bool,
        q2: u64, r2: u64, q2_n: bool, r2_n: bool
    ): u64 {
        let (qv1_r, qn1_r) = signed_sum(q1, q1_n, r1, r1_n);
        let s1_v = qv1_r;
        let s1_n = !qn1_r;
        if (s1_v == 0) { let s1_n = false; }; // Suppressing binding warning if needed, but s1_n is used below

        let (qv2_r, qn2_r) = signed_sum(q2, q2_n, r2, r2_n);
        let s2_v = qv2_r;
        let s2_n = !qn2_r;
        if (s2_v == 0) { let s2_n = false; };

        let dq = abs_diff(q1, q1_n, q2, q2_n);
        let dr = abs_diff(r1, r1_n, r2, r2_n);
        let ds = abs_diff(s1_v, s1_n, s2_v, s2_n);

        let mut max = dq;
        if (dr > max) max = dr;
        if (ds > max) max = ds;

        max
    }

    // === VALIDACIÓN DE ADYACENCIA ===
    public fun is_adjacent(q1: u64, r1: u64, q2: u64, r2: u64): bool {
        hex_distance(q1, r1, q2, r2) == 1
    }

    // === DETERMINACIÓN DE CONTINENTE ===
    public fun get_continent(q: u64): u8 {
        if (q < 210) {
            CONTINENT_DRANTIUM  // Oeste del meridiano (original q < 0)
        } else {
            CONTINENT_BRONTIUM  // Este del meridiano (original q >= 0)
        }
    }

    public fun is_in_drantium(q: u64): bool {
        q < 210
    }

    public fun is_in_brontium(q: u64): bool {
        q >= 210
    }

    // === DETERMINACIÓN DE HEMISFERIO ===
    public fun get_hemisphere(r: u64): u8 {
        // Original r < -30 => r_offset < 80
        // Original r > 30 => r_offset > 140
        if (r < 80) {
            HEMISPHERE_SOUTHERN
        } else if (r > 140) {
            HEMISPHERE_NORTHERN
        } else {
            HEMISPHERE_EQUATORIAL
        }
    }

    // === VALIDACIÓN DE BIOMA ===
    public fun is_terrain_type(reg: &LocationRegistry, q: u64, r: u64, expected_terrain: u8): bool {
        let coord_key = encode_coordinates(q, r);
        if (!table::contains(&reg.terrain_map, coord_key)) {
            return false;
        };
        let terrain = table::borrow(&reg.terrain_map, coord_key);
        *terrain == expected_terrain
    }

    // === VALIDACIÓN DE CARACTERÍSTICA ===
    public fun has_feature(reg: &LocationRegistry, q: u64, r: u64, feature: u8): bool {
        let coord_key = encode_coordinates(q, r);
        if (!table::contains(&reg.feature_map, coord_key)) {
            return false;
        };
        let features = table::borrow(&reg.feature_map, coord_key);
        vector::contains(features, &feature)
    }

    // === OBTENCIÓN DE RECURSOS DEL TILE ===
    public fun get_tile_resources(reg: &LocationRegistry, q: u64, r: u64): &TileResources {
        let coord_key = encode_coordinates(q, r);
        assert!(table::contains(&reg.resource_map, coord_key), E_INVALID_COORDINATES);
        table::borrow(&reg.resource_map, coord_key)
    }

    // === COSTO DE MOVIMIENTO POR BIOMA ===
    public fun get_movement_cost(terrain: u8): u8 {
        if (terrain == TERRAIN_OCEAN) 0
        else if (terrain == TERRAIN_PLAINS) 1
        else if (terrain == TERRAIN_MEADOW) 1
        else if (terrain == TERRAIN_HILLS) 2
        else if (terrain == TERRAIN_MOUNTAIN_RANGE) 3
        else if (terrain == TERRAIN_DESERT) 2
        else if (terrain == TERRAIN_TUNDRA) 2
        else if (terrain == TERRAIN_SWAMP) 3
        else 1
    }

    public fun get_feature_movement_cost(feature: u8): u8 {
        if (feature == FEATURE_FOREST) 1
        else if (feature == FEATURE_JUNGLE) 2
        else if (feature == FEATURE_BOREAL_FOREST) 1
        else if (feature == FEATURE_OASIS) 0
        else if (feature == FEATURE_VOLCANO) 3
        else if (feature == FEATURE_SWAMP) 2 // Swamp as feature
        else 0
    }

    // === IMPORTACIÓN DE DATOS DEL MAPA (Batch) ===
    public fun import_tile_data(
        reg: &mut LocationRegistry,
        q: u64,
        r: u64,
        terrain: u8,
        features: vector<u8>,
        resources: vector<u8>,
        minerals: vector<u8>,
        animals: vector<u8>,
        elevation: u8,
        temperature: u8,
        rainfall: u8,
        _ctx: &mut TxContext
    ) {
        let coord_key = encode_coordinates(q, r);
        
        // Validar coordenadas (rango offset: q ∈ [0, 419], r ∈ [0, 219])
        assert!(q < 420, E_OUT_OF_BOUNDS);
        assert!(r < 220, E_OUT_OF_BOUNDS);
        
        // Almacenar terreno
        table::add(&mut reg.terrain_map, coord_key, terrain);
        
        // Almacenar características
        if (vector::length(&features) > 0) {
            table::add(&mut reg.feature_map, coord_key, features);
        };
        
        // Almacenar recursos
        let tile_resources = TileResources {
            natural_resources: resources,
            minerals,
            animals,
            elevation,
            temperature,
            rainfall,
            continent: get_continent(q),
            hemisphere: get_hemisphere(r),
            season: get_season_by_hemisphere(get_hemisphere(r)),
        };
        table::add(&mut reg.resource_map, coord_key, tile_resources);
    }

    // === DETERMINACIÓN DE ESTACIÓN DINÁMICA (App Sync) ===
    const GENESIS_TS: u64 = 1731628800000; // Nov 15, 2025
    const SPEED_MULTIPLIER: u64 = 4;
    const DAY_MS: u64 = 86400000;
    const MONTH_DAYS: u64 = 28;
    const YEAR_DAYS: u64 = 392;

    public fun calculate_current_month(clock: &sui::clock::Clock): u64 {
        let now = sui::clock::timestamp_ms(clock);
        if (now < GENESIS_TS) return 1;
        
        let elapsed_real = now - GENESIS_TS;
        let elapsed_game = elapsed_real * SPEED_MULTIPLIER;
        let total_days = elapsed_game / DAY_MS;
        let current_year_day = total_days % YEAR_DAYS;
        
        (current_year_day / MONTH_DAYS) + 1
    }

    public fun get_dynamic_season(r: u64, clock: &sui::clock::Clock): u8 {
        let month = calculate_current_month(clock);
        let hemisphere = get_hemisphere(r);

        // Zona Equatorial (r_offset entre 110-10 y 110+10 => 100 to 120)
        if (r >= 100 && r <= 120) {
            if (month <= 7) return SEASON_SUMMER else return SEASON_WINTER
        };

        if (hemisphere == HEMISPHERE_NORTHERN) {
            if (month <= 3) return SEASON_WINTER;
            if (month <= 7) return SEASON_SPRING;
            if (month <= 10) return SEASON_SUMMER;
            return SEASON_AUTUMN
        } else {
            // Hemisferio Sur (Opuesto)
            if (month <= 3) return SEASON_SUMMER;
            if (month <= 7) return SEASON_AUTUMN;
            if (month <= 10) return SEASON_WINTER;
            return SEASON_SPRING
        }
    }

    fun get_season_by_hemisphere(hemisphere: u8): u8 {
        // Fallback para inicialización estática simple
        if (hemisphere == HEMISPHERE_NORTHERN) {
            SEASON_SUMMER
        } else if (hemisphere == HEMISPHERE_SOUTHERN) {
            SEASON_WINTER
        } else {
            SEASON_SPRING
        }
    }

    // === GETTERS RPC ===
    public fun get_terrain_type(reg: &LocationRegistry, q: u64, r: u64): u8 {
        let coord_key = encode_coordinates(q, r);
        if (table::contains(&reg.terrain_map, coord_key)) {
            *table::borrow(&reg.terrain_map, coord_key)
        } else {
            TERRAIN_OCEAN // Por defecto
        }
    }

    public fun get_tile_elevation(reg: &LocationRegistry, q: u64, r: u64): u8 {
        let resources = get_tile_resources(reg, q, r);
        resources.elevation
    }

    public fun get_tile_temperature(reg: &LocationRegistry, q: u64, r: u64): u8 {
        let resources = get_tile_resources(reg, q, r);
        resources.temperature
    }

    public fun get_tile_rainfall(reg: &LocationRegistry, q: u64, r: u64): u8 {
        let resources = get_tile_resources(reg, q, r);
        resources.rainfall
    }

    public fun get_tile_continent(reg: &LocationRegistry, q: u64, r: u64): u8 {
        let resources = get_tile_resources(reg, q, r);
        resources.continent
    }

    // === CONSTANTES PÚBLICAS ===
    public fun terrain_ocean(): u8 { TERRAIN_OCEAN }
    public fun terrain_coast(): u8 { TERRAIN_COAST }
    public fun terrain_plains(): u8 { TERRAIN_PLAINS }
    public fun terrain_meadow(): u8 { TERRAIN_MEADOW }
    public fun terrain_hills(): u8 { TERRAIN_HILLS }
    public fun terrain_mountain_range(): u8 { TERRAIN_MOUNTAIN_RANGE }
    public fun terrain_tundra(): u8 { TERRAIN_TUNDRA }
    public fun terrain_desert(): u8 { TERRAIN_DESERT }
    public fun terrain_ice(): u8 { TERRAIN_ICE }
    public fun terrain_swamp(): u8 { TERRAIN_SWAMP }

    public fun feature_forest(): u8 { FEATURE_FOREST }
    public fun feature_jungle(): u8 { FEATURE_JUNGLE }
    public fun feature_boreal_forest(): u8 { FEATURE_BOREAL_FOREST }
    public fun feature_oasis(): u8 { FEATURE_OASIS }
    public fun feature_volcano(): u8 { FEATURE_VOLCANO }
    public fun feature_mountain_peak(): u8 { FEATURE_MOUNTAIN_PEAK }
    public fun feature_river(): u8 { FEATURE_RIVER }
    public fun feature_lake(): u8 { FEATURE_LAKE }
    public fun feature_cave(): u8 { FEATURE_CAVE }
    public fun feature_mineral_deposit(): u8 { FEATURE_MINERAL_DEPOSIT }
    public fun feature_animal_herd(): u8 { FEATURE_ANIMAL_HERD }
    public fun feature_swamp(): u8 { FEATURE_SWAMP }

    public fun continent_drantium(): u8 { CONTINENT_DRANTIUM }
    public fun continent_brontium(): u8 { CONTINENT_BRONTIUM }

    public fun hemisphere_northern(): u8 { HEMISPHERE_NORTHERN }
    public fun hemisphere_southern(): u8 { HEMISPHERE_SOUTHERN }
    public fun hemisphere_equatorial(): u8 { HEMISPHERE_EQUATORIAL }

    public fun season_spring(): u8 { SEASON_SPRING }
    public fun season_summer(): u8 { SEASON_SUMMER }
    public fun season_autumn(): u8 { SEASON_AUTUMN }
    public fun season_winter(): u8 { SEASON_WINTER }

    // === LÓGICA DE SUBLANDS (Nivel 2) ===
    const SUBLAND_RADIUS: u64 = 58;

    // Direcciones de vecinos (Axial)
    const DIR_NE: u8 = 0; // +1, -1
    const DIR_E: u8  = 1; // +1,  0
    const DIR_SE: u8 = 2; //  0, +1
    const DIR_SW: u8 = 3; // -1, +1
    const DIR_W: u8  = 4; // -1,  0
    const DIR_NW: u8 = 5; //  0, -1

    // === GEOLOCALIZACIÓN AVANZADA (Usuario: Cross-Border Logic) ===

    /// Calcula la distancia "Global" inteligente entre dos tiles (xLands)
    /// Si están en el mismo Hex Mayor: Distancia simple.
    /// Si son vecinos: Distancia a través de la frontera más cercana.
    /// Si están lejos: 100+ (Simplificado para evitar pathfinding on-chain costoso)
    public fun calculate_combined_distance(
        h1_q: u64, h1_r: u64, s1_q: u64, s1_r: u64,
        h2_q: u64, h2_r: u64, s2_q: u64, s2_r: u64
    ): u64 {
        // Legacy version for positive-only coords
        calculate_combined_distance_signed(
            h1_q, h1_r, false, false, s1_q, s1_r, false, false,
            h2_q, h2_r, false, false, s2_q, s2_r, false, false
        )
    }

    public fun calculate_combined_distance_signed(
        h1_q: u64, h1_r: u64, h1_qn: bool, h1_rn: bool,
        s1_q: u64, s1_r: u64, s1_qn: bool, s1_rn: bool,
        h2_q: u64, h2_r: u64, h2_qn: bool, h2_rn: bool,
        s2_q: u64, s2_r: u64, s2_qn: bool, s2_rn: bool
    ): u64 {
        // 1. Mismo Hex Mayor
        if (h1_q == h2_q && h1_r == h2_r && h1_qn == h2_qn && h1_rn == h2_rn) {
            return hex_distance_signed(s1_q, s1_r, s1_qn, s1_rn, s2_q, s2_r, s2_qn, s2_rn)
        };

        // 2. Hexagonos Vecinos (Distancia = 1)
        if (hex_distance_signed(h1_q, h1_r, h1_qn, h1_rn, h2_q, h2_r, h2_qn, h2_rn) == 1) {
            // Simplified cross-border distance calculation
            // We can re-use calculate_combined_distance logic with signed midpoints,
            // but for movement, a simpler sum is often used if we don't want to calculate mirror points exactly.
            // Let's use the Border Midpoint logic refactored for signs.
            
            // For now, let's use a very safe estimate:
            // dist = dist_to_border_H1 + 1 + dist_from_border_H2
            // Midpoint of border for neighbor 
            // I'll keep it simple for movement cost:
            let d1 = (SUBLAND_RADIUS - hex_distance_signed(0, 0, false, false, s1_q, s1_r, s1_qn, s1_rn));
            let d2 = (SUBLAND_RADIUS - hex_distance_signed(0, 0, false, false, s2_q, s2_r, s2_qn, s2_rn));
            return d1 + d2 + 1
        };

        // 3. Hexagonos No Vecinos
        let hex_dist = hex_distance_signed(h1_q, h1_r, h1_qn, h1_rn, h2_q, h2_r, h2_qn, h2_rn);
        (hex_dist * (2 * SUBLAND_RADIUS))
    }

    public fun new_location(h_q: u64, h_r: u64, s_q: u64, s_r: u64, land_id: ID, tile_id: u64): ResourceLocation {
        ResourceLocation { h_q, h_r, s_q, s_r, land_id, tile_id }
    }

    // Versión simplificada para edificios (parcel_idx no mapeado aún a coords)
    public fun new_location_simple(land_id: ID, tile_id: u64, _parcel_idx: u64): ResourceLocation {
        ResourceLocation { h_q: 0, h_r: 0, s_q: 0, s_r: 0, land_id, tile_id }
    }

    public fun get_land_id(loc: &ResourceLocation): ID { loc.land_id }
    public fun get_tile_id(loc: &ResourceLocation): u64 { loc.tile_id }

    public fun is_same_location(loc1: &ResourceLocation, loc2: &ResourceLocation): bool {
        loc1.h_q == loc2.h_q && 
        loc1.h_r == loc2.h_r && 
        loc1.s_q == loc2.s_q && 
        loc1.s_r == loc2.s_r && 
        loc1.land_id == loc2.land_id && 
        loc1.tile_id == loc2.tile_id
    }

    public fun get_hq(loc: &ResourceLocation): u64 { loc.h_q }
    public fun get_hr(loc: &ResourceLocation): u64 { loc.h_r }
    public fun get_sq(loc: &ResourceLocation): u64 { loc.s_q }
    public fun get_sr(loc: &ResourceLocation): u64 { loc.s_r }


    /// Linear interpolation between two values
    public fun lerp(start: u64, end: u64, numerator: u64, denominator: u64): u64 {
        if (denominator == 0) return start;
        if (numerator >= denominator) return end;
        
        if (end >= start) {
            start + ((end - start) * numerator / denominator)
        } else {
            start - ((start - end) * numerator / denominator)
        }
    }

    /// Interpolation for signed coordinates (represented as val + is_neg)
    public fun lerp_signed(v1: u64, n1: bool, v2: u64, n2: bool, num: u64, den: u64): (u64, bool) {
        if (den == 0) return (v1, n1);
        if (num >= den) return (v2, n2);
        
        let dist = abs_diff(v1, n1, v2, n2);
        let step = dist * num / den;
        
        if (step == 0) return (v1, n1);

        // Determine direction and apply step
        if (!n1 && !n2) {
            if (v2 >= v1) return (v1 + step, false) else return (v1 - step, false)
        }
        else if (n1 && n2) {
            if (v1 >= v2) return (v1 + step, true) else return (v1 - step, true)
        }
        else if (n1 && !n2) {
            if (step <= v1) return (v1 - step, true) else return (step - v1, false)
        }
        else {
            if (step <= v1) return (v1 - step, false) else return (step - v1, true)
        }
    }

    /// Get current position between two tiles based on time
    public fun get_intermediate_position(
        h1_q: u64, h1_r: u64, h1_qn: bool, h1_rn: bool,
        s1_q: u64, s1_r: u64, s1_qn: bool, s1_rn: bool,
        h2_q: u64, h2_r: u64, h2_qn: bool, h2_rn: bool,
        s2_q: u64, s2_r: u64, s2_qn: bool, s2_rn: bool,
        start_time: u64,
        arrival_time: u64,
        current_time: u64
    ): (u64, u64, bool, bool, u64, u64, bool, bool) {
        if (current_time >= arrival_time) return (h2_q, h2_r, h2_qn, h2_rn, s2_q, s2_r, s2_qn, s2_rn);
        if (current_time <= start_time) return (h1_q, h1_r, h1_qn, h1_rn, s1_q, s1_r, s1_qn, s1_rn);

        let num = current_time - start_time;
        let den = arrival_time - start_time;

        let (i_hq, i_hqn) = lerp_signed(h1_q, h1_qn, h2_q, h2_qn, num, den);
        let (i_hr, i_hrn) = lerp_signed(h1_r, h1_rn, h2_r, h2_rn, num, den);
        let (i_sq, i_sqn) = lerp_signed(s1_q, s1_qn, s2_q, s2_qn, num, den);
        let (i_sr, i_srn) = lerp_signed(s1_r, s1_rn, s2_r, s2_rn, num, den);

        (i_hq, i_hr, i_hqn, i_hrn, i_sq, i_sr, i_sqn, i_srn)
    }
}