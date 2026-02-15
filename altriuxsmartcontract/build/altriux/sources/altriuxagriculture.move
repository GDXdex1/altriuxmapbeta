module altriux::altriuxagriculture {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::transfer;
    use sui::table::{Self, Table};
    use sui::dynamic_field;
    use std::vector;
    use std::option::{Self, Option};
    use altriux::altriuxresources::{Self, Inventory};
    use altriux::altriuxland::{Self, Land, LandParcel};
    use altriux::altriuxhero::{Self, Hero};
    use altriux::altriuxagstats;
    use altriux::altriuxagbiome;
    use altriux::altriuxfertilizers;
    use altriux::altriuxactionpoints::{Self, ActionPointRegistry};
    use sui::event;

    // === CONSTANTES AU ===
    const AU_CLEAR_FOREST: u64 = 6;       // Deforestar parcela
    const AU_PLOW_PARCEL: u64 = 2;        // Arar parcela
    const AU_PLANT_SMALL: u64 = 4;        // Sembrar parcela pequeña
    const AU_PLANT_FARM: u64 = 1;         // Sembrar cuarto de granja
    
    // AU por cosecha (según cultivo)
    const AU_HARVEST_WHEAT: u64 = 3;
    const AU_HARVEST_BARLEY: u64 = 3;
    const AU_HARVEST_RYE: u64 = 3;
    const AU_HARVEST_OATS: u64 = 2;
    const AU_HARVEST_RICE: u64 = 4;
    const AU_HARVEST_CORN: u64 = 3;
    const AU_HARVEST_FLAX: u64 = 2;
    const AU_HARVEST_COTTON: u64 = 3;
    const AU_HARVEST_HEMP: u64 = 3;
    const AU_HARVEST_LENTILS: u64 = 3;
    const AU_HARVEST_PEAS: u64 = 2;
    const AU_HARVEST_BEANS: u64 = 3;
    const AU_HARVEST_SOY: u64 = 3;
    const AU_HARVEST_POTATO: u64 = 4;
    const AU_HARVEST_CASSAVA: u64 = 3;

    // === ASOCIACIONES ===
    const ASSOC_NONE: u8 = 0;
    const ASSOC_MILPA: u8 = 1;            // Maíz + Frijol + Calabaza
    const ASSOC_WHEAT_PEA: u8 = 2;        // Trigo + Guisantes
    const ASSOC_BARLEY_LENTIL: u8 = 3;    // Cebada + Lentejas
    const ASSOC_RYE_VETCH: u8 = 4;        // Centeno + Veza
    const ASSOC_RICE_FISH: u8 = 5;        // Arroz + Peces
    const ASSOC_CANE_BEAN: u8 = 6;        // Caña + Frijol
    const ASSOC_OLIVE_BARLEY: u8 = 7;     // Olivo + Cebada
    const ASSOC_BANANA_CACAO: u8 = 8;     // Plátano + Cacao
    const ASSOC_CLOVER_CEREAL: u8 = 9;    // Trébol + Cereales

    // === ERRORES ===
    const E_NOT_OWNER: u64 = 101;
    const E_INVALID_BIOME: u64 = 102;
    const E_PARCEL_OCCUPIED: u64 = 103;
    const E_NO_CROP: u64 = 104;
    const E_NOT_READY: u64 = 105;
    const E_INVALID_ASSOCIATION: u64 = 106;
    const E_INSUFFICIENT_AU: u64 = 107;
    const E_NO_WORKERS: u64 = 108;
    const E_NOBILITY_LABOR_RESTRICTION: u64 = 109;

    // === STRUCTS ===
    public struct AgricultureRegistry has key {
        id: UID,
        total_parcels: u64,
        total_crops_planted: u64,
        total_crops_harvested: u64,
    }

    // ParcelData removed - replaced by LandParcel object

    public struct Crop has store, drop {
        seed_id: u64,                     // Semilla principal
        assoc_type: u8,                   // ASSOC_*
        assoc_stage: u8,                  // 0=solo, 1=primera, 2=segunda, 3=tercera
        sow_timestamp: u64,
        fertilizer_bonus_bp: u64,         // Basis points
        au_invested: u64,                 // AU gastados en este cultivo
    }

    // === EVENTS ===
    public struct CropPlanted has copy, drop {
        land_id: ID,
        parcel_idx: u64,
        seed_id: u64,
        assoc_type: u8,
        au_consumed: u64,
        timestamp: u64,
    }

    public struct CropHarvested has copy, drop {
        land_id: ID,
        parcel_idx: u64,
        seed_id: u64,
        yield_jax: u64,
        au_consumed: u64,
        timestamp: u64,
    }

    public struct AssociationPlanted has copy, drop {
        land_id: ID,
        parcel_idx: u64,
        assoc_type: u8,
        stage: u8,
        seed_id: u64,
        timestamp: u64,
    }

    // === INICIALIZACIÓN ===
    public fun init_agriculture_registry(ctx: &mut TxContext) {
        let registry = AgricultureRegistry {
            id: object::new(ctx),
            total_parcels: 0,
            total_crops_planted: 0,
            total_crops_harvested: 0,
        };
        transfer::share_object(registry);
    }

    // === SEMBRAR CON AU ===
    public fun sow_with_au(
        au_reg: &mut ActionPointRegistry,
        parcel: &mut LandParcel,
        seed_id: u64,
        hero: &Hero,
        nobility_titles: &vector<ID>,
        inventory: &mut Inventory,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        
        // 1. Validate Ownership/Rental
        let active_user = altriuxland::get_parcel_active_user(parcel, clock);
        assert!(active_user == sender, E_NOT_OWNER);
        
        // 2. Validate Nobility (Labor Restriction)
        let hero_id = object::id(hero);
        assert!(altriuxhero::can_perform_manual_labor(hero_id, nobility_titles), E_NOBILITY_LABOR_RESTRICTION);
        
        // 3. Check if parcel is occupied
        // 3. Check if parcel is occupied
        let uid = altriuxland::get_parcel_uid(parcel);
        assert!(!dynamic_field::exists_(uid, b"crop"), E_PARCEL_OCCUPIED);
        
        let now = clock::timestamp_ms(clock);
        
        // 4. Validate Ag Stats & Requirements
        let mut stats_opt = altriuxagstats::get_crop_stats(seed_id);
        assert!(option::is_some(&stats_opt), E_INVALID_BIOME); // Reuse error code
        let s = option::extract(&mut stats_opt);
        
        // Check Biome compatibility
        let parcel_biome = altriuxland::get_parcel_ag_biome(parcel);
        assert!(altriuxagstats::is_biome_allowed(seed_id, parcel_biome), E_INVALID_BIOME);
        
        // 5. Consume Seed & AU
        let cost = altriuxagstats::seed_cost_bp(&s);
        altriuxresources::consume_jax(inventory, seed_id, cost, clock);
        
        // Consume AU from Hero
        altriuxactionpoints::consume_au(au_reg, hero_id, AU_PLANT_SMALL, b"sow", clock, ctx);
        
        // 6. Initialize Crop
        let crop = Crop {
            seed_id,
            assoc_type: ASSOC_NONE,
            assoc_stage: 0,
            sow_timestamp: now,
            fertilizer_bonus_bp: 0,
            au_invested: AU_PLANT_SMALL,
        };
        
        // Store crop as dynamic field
        // Store crop as dynamic field
        let uid_mut = altriuxland::get_parcel_uid_mut(parcel);
        dynamic_field::add(uid_mut, b"crop", crop);
        
        // Update parcel fertility or other stats if needed (omitted for now as simple field add)
        // Note: we can't easily access parent land ID from here without storing it in parcel
        // But parcel object has it
        
        event::emit(CropPlanted {
            land_id: object::id(parcel), // Use parcel ID as reference
            parcel_idx: 0, // Legacy
            seed_id,
            assoc_type: ASSOC_NONE,
            au_consumed: AU_PLANT_SMALL,
            timestamp: now,
        });
    }

    // === SEMBRAR ASOCIACIÓN SECUENCIAL ===
    public fun sow_association_sequential(
        au_reg: &mut ActionPointRegistry,
        parcel: &mut LandParcel,
        inventory: &mut Inventory,
        hero: &Hero,
        nobility_titles: &vector<ID>,
        assoc_type: u8,
        stage: u8,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        // Ownership check
        let active_user = altriuxland::get_parcel_active_user(parcel, clock);
        assert!(active_user == sender, E_NOT_OWNER);
        
        // Nobility check
        let hero_id = object::id(hero);
        assert!(altriuxhero::can_perform_manual_labor(hero_id, nobility_titles), E_NOBILITY_LABOR_RESTRICTION);

        assert!(stage >= 1 && stage <= 3, E_INVALID_ASSOCIATION);

        let (seed1, seed2, seed3) = get_assoc_seeds(assoc_type);
        let seed_id = if (stage == 1) seed1 else if (stage == 2) seed2 else seed3;
        assert!(seed_id != 0, E_INVALID_ASSOCIATION);

        // Consume AU
        altriuxactionpoints::consume_au(au_reg, hero_id, AU_PLANT_SMALL, b"plant_association", clock, ctx);

        // Consume seeds
        let mut opt = altriuxagstats::get_crop_stats(seed_id);
        let s = option::extract(&mut opt);
        let cost = altriuxagstats::seed_cost_bp(&s);
        altriuxresources::consume_jax(inventory, seed_id, cost, clock);


        if (stage == 1) {
            // First stage
            let uid = altriuxland::get_parcel_uid(parcel);
            assert!(!dynamic_field::exists_(uid, b"crop"), E_PARCEL_OCCUPIED);
            let crop = Crop {
                seed_id,
                assoc_type,
                assoc_stage: 1,
                sow_timestamp: clock::timestamp_ms(clock),
                fertilizer_bonus_bp: 0,
                au_invested: AU_PLANT_SMALL,
            };
            let uid_mut = altriuxland::get_parcel_uid_mut(parcel);
            dynamic_field::add(uid_mut, b"crop", crop);
        } else {
            // Subsequent stages
            let uid = altriuxland::get_parcel_uid(parcel);
            assert!(dynamic_field::exists_(uid, b"crop"), E_NO_CROP);
            let uid_mut = altriuxland::get_parcel_uid_mut(parcel);
            let crop = dynamic_field::borrow_mut<vector<u8>, Crop>(uid_mut, b"crop");
            assert!(crop.assoc_type == assoc_type, E_INVALID_ASSOCIATION);
            assert!(crop.assoc_stage == stage - 1, E_INVALID_ASSOCIATION);
            crop.assoc_stage = stage;
            crop.au_invested = crop.au_invested + AU_PLANT_SMALL;
        };

        // Update last cultivated is missing on parcel object unless we add it to struct
        // previous impl had it on ParcelData. We can ignore for now or add dynamic field for it.

        event::emit(AssociationPlanted {
            land_id: object::id(parcel),
            parcel_idx: 0,
            assoc_type,
            stage,
            seed_id,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // === COSECHAR CON AU ===
    public fun harvest_with_au(
        au_reg: &mut ActionPointRegistry,
        parcel: &mut LandParcel,
        inventory: &mut Inventory,
        hero: &Hero,
        nobility_titles: &vector<ID>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        // Ownership check
        let active_user = altriuxland::get_parcel_active_user(parcel, clock);
        assert!(active_user == sender, E_NOT_OWNER);
        
        // Nobility check
        let hero_id = object::id(hero);
        assert!(altriuxhero::can_perform_manual_labor(hero_id, nobility_titles), E_NOBILITY_LABOR_RESTRICTION);
        
        let uid = altriuxland::get_parcel_uid(parcel);
        assert!(dynamic_field::exists_(uid, b"crop"), E_NO_CROP);
        
        // Borrow crop to check readiness
        let crop_ref = dynamic_field::borrow<vector<u8>, Crop>(uid, b"crop");
        let now = clock::timestamp_ms(clock);
        let elapsed_seconds = (now - crop_ref.sow_timestamp) / 1000;
        
        let mut stats_opt = altriuxagstats::get_crop_stats(crop_ref.seed_id);
        let stats = option::extract(&mut stats_opt);
        let duration_seconds = altriuxagstats::growth_days(&stats) * 86400;
        assert!(elapsed_seconds >= duration_seconds, E_NOT_READY);

        // Determine AU cost
        let harvest_au = get_harvest_au(crop_ref.seed_id);
        
        // Consume AU from Hero
        altriuxactionpoints::consume_au(au_reg, hero_id, harvest_au, b"harvest_crop", clock, ctx);

        // Extract crop to process
        // Extract crop to process
        let uid_mut = altriuxland::get_parcel_uid_mut(parcel);
        let crop = dynamic_field::remove<vector<u8>, Crop>(uid_mut, b"crop");
        
        // Calculate Yield
        let parcel_ag_biome = altriuxland::get_parcel_ag_biome(parcel);
        let (biome_bonus_bp, bonus_neg) = altriuxagbiome::get_biome_bonus(crop.seed_id, parcel_ag_biome);
        let biome_multiplier = if (bonus_neg) { 
            if (10000 > biome_bonus_bp) 10000 - biome_bonus_bp else 0 
        } else { 
            10000 + biome_bonus_bp 
        };

        let parcel_fertility = altriuxland::get_parcel_fertility(parcel);
        let final_yield_bp = safe_multiply_divide_4(
            altriuxagstats::base_yield_bp(&stats),
            biome_multiplier,
            parcel_fertility,
            10000 + crop.fertilizer_bonus_bp,
            1000000000000
        );

        let mut soil_delta_val = altriuxagstats::soil_delta_bp(&stats);
        let mut soil_delta_neg = altriuxagstats::soil_delta_neg(&stats);
        
        if (crop.assoc_type == ASSOC_NONE) {
            let food_id = get_crop_from_seed(crop.seed_id);
            let mut irrigation_penalty = 10000;
            // Irrigation check
            if (altriuxagstats::needs_irrigation(&stats) && !altriuxland::parcel_has_irrigation(parcel)) {
                irrigation_penalty = 5000;
            };
            let actual_yield = (final_yield_bp * irrigation_penalty / 1000000);
            if (actual_yield > 0) {
                altriuxresources::add_jax(inventory, food_id, actual_yield, 0, clock);
            };

            event::emit(CropHarvested {
                land_id: object::id(parcel),
                parcel_idx: 0,
                seed_id: crop.seed_id,
                yield_jax: actual_yield,
                au_consumed: harvest_au,
                timestamp: now,
            });
        } else {
            // Association yield
            let (yield_jak, delta_v, delta_n) = get_assoc_results(crop.assoc_type);
            soil_delta_val = delta_v;
            soil_delta_neg = delta_n;
            let food1 = get_crop_from_seed(crop.seed_id);
            altriuxresources::add_jax(inventory, food1, yield_jak, 0, clock);

            event::emit(CropHarvested {
                land_id: object::id(parcel),
                parcel_idx: 0,
                seed_id: crop.seed_id,
                yield_jax: yield_jak,
                au_consumed: harvest_au,
                timestamp: now,
            });
        };

        // Update Fertility
        let mut new_fertility = parcel_fertility;
        if (soil_delta_neg) {
            if (parcel_fertility > soil_delta_val) { 
                new_fertility = parcel_fertility - soil_delta_val; 
            } else { 
                new_fertility = 0; 
            };
        } else {
            new_fertility = min_u64(12000, parcel_fertility + soil_delta_val);
        };
        altriuxland::update_parcel_fertility(parcel, new_fertility);

        // Perennials
        if (altriuxagstats::is_perennial(&stats)) {
            let next_crop = Crop {
                seed_id: crop.seed_id,
                assoc_type: crop.assoc_type,
                assoc_stage: crop.assoc_stage,
                sow_timestamp: now,
                fertilizer_bonus_bp: 0,
                au_invested: 0,
            };

            let uid_mut = altriuxland::get_parcel_uid_mut(parcel);
            dynamic_field::add(uid_mut, b"crop", next_crop);
        };
    }

    // === FERTILIZAR ===
    public fun fertilize(
        parcel: &mut LandParcel,
        inventory: &mut Inventory,
        fertilizer_type: u64,
        clock: &Clock,
        _ctx: &mut TxContext
    ) {
        assert!(
            fertilizer_type == altriuxfertilizers::JAX_GALLINAZA() || 
            fertilizer_type == altriuxfertilizers::JAX_ESTIERCOL(), 
            E_INVALID_ASSOCIATION
        );
        altriuxresources::consume_jax(inventory, fertilizer_type, 1, clock);

        let uid = altriuxland::get_parcel_uid(parcel);
        if (dynamic_field::exists_(uid, b"crop")) {
            let uid_mut = altriuxland::get_parcel_uid_mut(parcel);
            let crop = dynamic_field::borrow_mut<vector<u8>, Crop>(uid_mut, b"crop");
            crop.fertilizer_bonus_bp = crop.fertilizer_bonus_bp + 1500;
        } else {
            let current_fertility = altriuxland::get_parcel_fertility(parcel);
            let new_fertility = min_u64(12000, current_fertility + 1000);
            altriuxland::update_parcel_fertility(parcel, new_fertility);
        };
    }

    // === HELPERS (unchanged from originals mostly) ===
    fun get_harvest_au(seed_id: u64): u64 {
        if (seed_id == 1) AU_HARVEST_WHEAT
        else if (seed_id == 7) AU_HARVEST_BARLEY
        else if (seed_id == 15) AU_HARVEST_RYE
        else if (seed_id == 13) AU_HARVEST_OATS
        else if (seed_id == 5) AU_HARVEST_RICE
        else if (seed_id == 3) AU_HARVEST_CORN
        else if (seed_id == 17) AU_HARVEST_FLAX
        else if (seed_id == 19) AU_HARVEST_COTTON
        else if (seed_id == 21) AU_HARVEST_HEMP
        else if (seed_id == 33) AU_HARVEST_LENTILS
        else if (seed_id == 35) AU_HARVEST_PEAS
        else if (seed_id == 29) AU_HARVEST_BEANS
        else if (seed_id == 31) AU_HARVEST_SOY
        else if (seed_id == 23) AU_HARVEST_POTATO
        else if (seed_id == 25) AU_HARVEST_CASSAVA
        else 3
    }

    fun min_u64(a: u64, b: u64): u64 { if (a < b) a else b }

    fun get_crop_from_seed(seed_id: u64): u64 {
        if (seed_id >= 1 && seed_id < 114 && seed_id % 2 != 0) {
            seed_id + 1
        } else { 0 }
    }

    fun safe_multiply_divide_4(a: u64, b: u64, c: u64, d: u64, divisor: u128): u64 {
        let val = (a as u128) * (b as u128) * (c as u128) * (d as u128);
        ((val / divisor) as u64)
    }

    fun get_assoc_seeds(t: u8): (u64, u64, u64) {
        if (t == ASSOC_MILPA) (3, 29, 63)
        else if (t == ASSOC_WHEAT_PEA) (1, 35, 0)
        else if (t == ASSOC_BARLEY_LENTIL) (7, 33, 0)
        else if (t == ASSOC_RYE_VETCH) (15, 113, 0)
        else if (t == ASSOC_RICE_FISH) (5, 0, 0)
        else if (t == ASSOC_CANE_BEAN) (45, 29, 0)
        else if (t == ASSOC_OLIVE_BARLEY) (87, 7, 0)
        else if (t == ASSOC_BANANA_CACAO) (71, 99, 0)
        else if (t == ASSOC_CLOVER_CEREAL) (107, 13, 0)
        else (0, 0, 0)
    }

    fun get_assoc_results(t: u8): (u64, u64, bool) {
        if (t == ASSOC_MILPA) (145, 100, false)
        else if (t == ASSOC_WHEAT_PEA) (58, 300, true)
        else if (t == ASSOC_BARLEY_LENTIL) (60, 100, false)
        else if (t == ASSOC_RYE_VETCH) (155, 600, false)
        else if (t == ASSOC_RICE_FISH) (85, 800, true)
        else if (t == ASSOC_CANE_BEAN) (540, 800, true)
        else if (t == ASSOC_OLIVE_BARLEY) (45, 200, true)
        else if (t == ASSOC_BANANA_CACAO) (50, 600, false)
        else if (t == ASSOC_CLOVER_CEREAL) (135, 1500, false)
        else (0, 0, false)
    }
}
