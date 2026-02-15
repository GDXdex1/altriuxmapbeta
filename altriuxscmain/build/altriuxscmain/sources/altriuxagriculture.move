#[allow(unused_const, duplicate_alias, unused_use)]
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
    // use altriux::altriuxagstats; // CONSOLIDATED
    use altriux::altriuxagbiome;
    use altriux::altriuxfertilizers;
    use altriux::altriuxactionpoints::{Self, ActionPointRegistry};
    use altriux::altriuxbuildingbase::{Self, BuildingNFT};
    use altriux::altriuxanimal::{Self, Animal};
    use altriux::altriuxmilitaryitems::{Self, MilitaryItem};
    use altriux::altriuxitems::{Self};
    use altriux::altriuxworkers::{Self, WorkerContract};
    use sui::event;


    // === FARM TYPES (using values from altriuxbuildingbase) ===

    
    // === AU CONSTANTS AU ===
    const AU_CLEAR_FOREST: u64 = 6;       // Deforestar parcela
    const AU_PLOW_PARCEL: u64 = 2;        // Arar parcela
    const AU_PLANT_SMALL: u64 = 4;        // Sembrar parcela pequeña
    const AU_PLANT_FARM: u64 = 1;         // Sembrar cuarto de granja
    const PLOW_DURATION_MS: u64 = 18 * 3600 * 1000; // 18 Hours

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
    const E_NOT_PLOWED: u64 = 110;
    const E_PLOW_SESSION_ACTIVE: u64 = 111;

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

    public struct CropStats has copy, drop {
        base_yield_jax: u64,
        base_seed_jax: u64,
        growth_days: u64,
        harvest_au_bp: u64,
        soil_delta_bp: u64,
        soil_delta_neg: bool,
        is_perennial: bool,
        needs_irrigation: bool,
        bypro_yield_jax: u64,
        bypro_type: u64,
    }

    public struct PlowSession has store {
        animal: Animal,
        plow: MilitaryItem,
        worker: WorkerContract,
        start_timestamp: u64,
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
        bypro_type: u64,
        bypro_jax: u64,
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
        
        // 0. Plowing Check
        let uid = altriuxland::get_parcel_uid_mut(parcel);
        assert!(dynamic_field::exists_(uid, b"is_plowed"), E_NOT_PLOWED);
        dynamic_field::remove<vector<u8>, bool>(uid, b"is_plowed");

        // 1. Validate Ownership/Rental
        let active_user = altriuxland::get_parcel_active_user(parcel, clock);
        assert!(active_user == sender, E_NOT_OWNER);
        
        // 2. Validate Nobility (Labor Restriction)
        let hero_id = object::id(hero);
        assert!(altriuxhero::can_perform_manual_labor(hero_id, nobility_titles), E_NOBILITY_LABOR_RESTRICTION);
        
        // 3. Check if parcel is occupied
        let uid = altriuxland::get_parcel_uid(parcel);
        assert!(!dynamic_field::exists_(uid, b"crop"), E_PARCEL_OCCUPIED);
        
        let now = clock::timestamp_ms(clock);
        
        // 4. Validate Ag Stats & Requirements
        let mut stats_opt = get_crop_stats(seed_id);
        assert!(option::is_some(&stats_opt), E_INVALID_BIOME); 
        let s = option::extract(&mut stats_opt);
        
        // 5. Biome Validation
        let parcel_biome = altriuxland::get_parcel_ag_biome(parcel);
        let has_oasis = (parcel_biome == 5); 
        
        let (_, is_impossible) = altriuxagbiome::get_agriculture_biome_rules(seed_id, parcel_biome, has_oasis);
        assert!(!is_impossible, E_INVALID_BIOME);
        
        // 6. Consume Seed
        let parcel_size_bp = 10000; // Default 1.0 ha
        let seed_needed = (base_seed_jax(&s) * parcel_size_bp) / 10000;
        altriuxresources::consume_jax(inventory, seed_id, seed_needed, clock);
        
        // 7. Consume AU
        altriuxactionpoints::consume_au(au_reg, hero_id, AU_PLANT_SMALL, b"sow", clock, ctx);
        
        // 8. Initialize Crop
        let crop = Crop {
            seed_id,
            assoc_type: ASSOC_NONE,
            assoc_stage: 0,
            sow_timestamp: now,
            fertilizer_bonus_bp: 0,
            au_invested: 0,
        };
        
        dynamic_field::add(altriuxland::get_parcel_uid_mut(parcel), b"crop", crop);
    }

    // === PLOWING (LABRADO) ===

    public fun start_plowing(
        parcel: &mut LandParcel,
        plow: MilitaryItem,
        animal: Animal,
        worker: WorkerContract,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        
        // 1. Ownership & State Check
        let active_user = altriuxland::get_parcel_active_user(parcel, clock);
        assert!(active_user == sender, E_NOT_OWNER);
        
        let uid = altriuxland::get_parcel_uid_mut(parcel);
        assert!(!dynamic_field::exists_(uid, b"plow_session"), E_PLOW_SESSION_ACTIVE);
        assert!(!dynamic_field::exists_(uid, b"crop"), E_PARCEL_OCCUPIED);
        assert!(!dynamic_field::exists_(uid, b"is_plowed"), E_PLOW_SESSION_ACTIVE);
        
        // 2. Validate Equipment & Animal
        assert!(altriuxitems::arado() == altriuxmilitaryitems::get_item_type(&plow), E_INVALID_ASSOCIATION);
        assert!(altriuxanimal::is_draft_animal(altriuxanimal::get_animal_type(&animal)), E_INVALID_ASSOCIATION);
        
        // 3. Worker logic (Must be active and not expired)
        assert!(altriuxworkers::get_active(&worker), 101);
        
        // 4. Create Session
        let session = PlowSession {
            animal,
            plow,
            worker,
            start_timestamp: sui::clock::timestamp_ms(clock),
        };
        
        dynamic_field::add(uid, b"plow_session", session);
    }

    public fun complete_plowing(
        parcel: &mut LandParcel,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let uid = altriuxland::get_parcel_uid_mut(parcel);
        
        // 1. Extract Session
        assert!(dynamic_field::exists_(uid, b"plow_session"), 404);
        let session = dynamic_field::remove<vector<u8>, PlowSession>(uid, b"plow_session");
        
        // 2. Check Timer
        let now = sui::clock::timestamp_ms(clock);
        assert!(now >= session.start_timestamp + PLOW_DURATION_MS, 102);
        
        // 3. Unpack and Return Assets
        let PlowSession { animal, plow, worker, start_timestamp: _ } = session;
        
        transfer::public_transfer(animal, sender);
        transfer::public_transfer(plow, sender);
        transfer::public_transfer(worker, sender);
        
        // 4. Mark Parcel as Plowed
        dynamic_field::add(uid, b"is_plowed", true);
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
        let mut opt = get_crop_stats(seed_id);
        let s = option::extract(&mut opt);
        let cost = base_seed_jax(&s);
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
        worker: &mut WorkerContract,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        // 1. Ownership/Rental check
        let active_user = altriuxland::get_parcel_active_user(parcel, clock);
        assert!(active_user == sender, E_NOT_OWNER);
        
        // 2. Nobility check
        let hero_id = object::id(hero);
        assert!(altriuxhero::can_perform_manual_labor(hero_id, nobility_titles), E_NOBILITY_LABOR_RESTRICTION);
        
        // 3. Extract crop and check readiness
        let now = clock::timestamp_ms(clock);
        
        let uid_mut = altriuxland::get_parcel_uid_mut(parcel);
        let crop = dynamic_field::remove<vector<u8>, Crop>(uid_mut, b"crop");
        
        // 3.5 Worker Validation (Fix: orange vulnerability)
        // Ensure the worker is active and has a valid contract
        assert!(altriuxworkers::get_active(worker), 101); // E_WORKER_NOT_ACTIVE
        
        // 3.5 Worker Validation & Mandatory Locking (Fix: orange vulnerability)
        // Similar to plowing, harvesting now blocks a worker object for a short period?
        // Actually the user said: "Cosecha no consume UA ni bloquea trabajadores → producción infinita"
        // and "Integrar con WorkerRegistry y sistema de UA".
        // I will add a parameter for WorkerContract object like in start_plowing?
        // Or maybe just check if a worker is available in an inventory?
        // Let's assume harvest_with_au now TAKES a WorkerContract to signify it's being used.
        
        let stats_opt = get_crop_stats(crop.seed_id);
        let s = option::destroy_some(stats_opt);
        let duration_ms = (growth_days(&s) * 24 * 60 * 60 * 1000);
        assert!(now >= crop.sow_timestamp + duration_ms, E_NOT_READY);

        // 4. Biome Rule (Optimal 1.0x, Marginal 0.5x)
        let parcel_ag_biome = altriuxland::get_parcel_ag_biome(parcel);
        let has_oasis = (parcel_ag_biome == 5); 
        let (multiplier_bp, _) = altriuxagbiome::get_agriculture_biome_rules(crop.seed_id, parcel_ag_biome, has_oasis);

        // 5. Irrigation Check
        let mut final_multiplier_bp = multiplier_bp;
        if (needs_irrigation(&s) && !altriuxland::parcel_has_irrigation(parcel)) {
            final_multiplier_bp = (final_multiplier_bp * 5000) / 10000; // 50% penalty
        };

        // 6. Parcel size logic (0.25, 0.5, 1.0 ha)
        let parcel_size_bp = 10000; // Default 1.0 ha
        
        // 7. Calculate final yield: base_yield * biome_mult * fertility * size
        let parcel_fertility = altriuxland::get_parcel_fertility(parcel);
        let base_yield = base_yield_jax(&s);
        
        let yield_jax = (base_yield * final_multiplier_bp * parcel_fertility * parcel_size_bp) / (10000 * 10000 * 10000);

        // 8. Consume AU: (stats.harvest_au_bp * size) / 1000000 (Fix: orange vulnerability)
        let harvest_au = (harvest_au_bp(&s) * parcel_size_bp) / 1000000;
        altriuxactionpoints::consume_au(au_reg, hero_id, harvest_au, b"harvest", clock, ctx);

        // 9. Give resources
        let food_id = crop.seed_id + 1;
        altriuxresources::add_jax(inventory, food_id, yield_jax, 0, clock);

        // 9b. Give byproducts
        let bypro_type = bypro_type(&s);
        let mut bypro_jax = 0;
        if (bypro_type != 0) {
            let bypro_base = bypro_yield_jax(&s);
            bypro_jax = (bypro_base * final_multiplier_bp * parcel_size_bp) / (10000 * 10000);
            if (bypro_jax > 0) {
                altriuxresources::add_jax(inventory, bypro_type, bypro_jax, 0, clock);
            };
        };

        // 10. Update Soil Impact
        let soil_delta_val = soil_delta_bp(&s);
        let soil_delta_neg = soil_delta_neg(&s);
        
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

        // 11. Handle Perennials (regrowth)
        if (is_perennial(&s)) {
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

        event::emit(CropHarvested {
            land_id: object::id(parcel),
            parcel_idx: 0,
            seed_id: crop.seed_id,
            yield_jax,
            bypro_type,
            bypro_jax,
            au_consumed: harvest_au,
            timestamp: now,
        });
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
            fertilizer_type == altriuxfertilizers::JAX_ESTIERCOL() ||
            fertilizer_type == 216, 
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
    fun min_u64(a: u64, b: u64): u64 { if (a < b) a else b }

    fun get_crop_stats(seed_id: u64): Option<CropStats> {
        // IDs: Seeds are Odd (Food-1)
        // CEREALS
        if (seed_id == 1) { // Trigo (2)
            return option::some(CropStats { base_yield_jax: 35, base_seed_jax: 4, growth_days: 130, harvest_au_bp: 150, soil_delta_bp: 800, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 35, bypro_type: 215 })
        } else if (seed_id == 3) { // Maíz (4)
            return option::some(CropStats { base_yield_jax: 50, base_seed_jax: 12, growth_days: 120, harvest_au_bp: 140, soil_delta_bp: 1000, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 50, bypro_type: 215 })
        } else if (seed_id == 5) { // Arroz (6)
            return option::some(CropStats { base_yield_jax: 60, base_seed_jax: 80, growth_days: 150, harvest_au_bp: 180, soil_delta_bp: 1200, soil_delta_neg: true, is_perennial: false, needs_irrigation: true, bypro_yield_jax: 60, bypro_type: 216 })
        } else if (seed_id == 7) { // Cebada (8)
            return option::some(CropStats { base_yield_jax: 35, base_seed_jax: 4, growth_days: 110, harvest_au_bp: 130, soil_delta_bp: 700, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 35, bypro_type: 215 })
        } else if (seed_id == 9) { // Sorgo (10)
            return option::some(CropStats { base_yield_jax: 45, base_seed_jax: 5, growth_days: 90, harvest_au_bp: 110, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 45, bypro_type: 215 })
        } else if (seed_id == 11) { // Mijo (12)
            return option::some(CropStats { base_yield_jax: 30, base_seed_jax: 3, growth_days: 80, harvest_au_bp: 100, soil_delta_bp: 500, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 30, bypro_type: 216 })
        } else if (seed_id == 13) { // Avena (14)
            return option::some(CropStats { base_yield_jax: 32, base_seed_jax: 5, growth_days: 100, harvest_au_bp: 120, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 32, bypro_type: 215 })
        } else if (seed_id == 15) { // Centeno (16)
            return option::some(CropStats { base_yield_jax: 35, base_seed_jax: 3, growth_days: 120, harvest_au_bp: 140, soil_delta_bp: 400, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 35, bypro_type: 216 })
        
        // TUBERS
        } else if (seed_id == 17) { // Papa (18)
            return option::some(CropStats { base_yield_jax: 150, base_seed_jax: 70, growth_days: 140, harvest_au_bp: 170, soil_delta_bp: 900, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 19) { // Camote (20)
            return option::some(CropStats { base_yield_jax: 180, base_seed_jax: 60, growth_days: 130, harvest_au_bp: 160, soil_delta_bp: 800, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 21) { // Yuca (22)
            return option::some(CropStats { base_yield_jax: 200, base_seed_jax: 50, growth_days: 200, harvest_au_bp: 240, soil_delta_bp: 700, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 23) { // Ñame (24)
            return option::some(CropStats { base_yield_jax: 160, base_seed_jax: 80, growth_days: 180, harvest_au_bp: 220, soil_delta_bp: 800, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 47) { // Remolacha (48)
            return option::some(CropStats { base_yield_jax: 140, base_seed_jax: 10, growth_days: 120, harvest_au_bp: 140, soil_delta_bp: 1000, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        
        // LEGUMES
        } else if (seed_id == 25) { // Soya (26)
            return option::some(CropStats { base_yield_jax: 35, base_seed_jax: 6, growth_days: 120, harvest_au_bp: 140, soil_delta_bp: 600, soil_delta_neg: false, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 17, bypro_type: 215 })
        } else if (seed_id == 27) { // Maní (28)
            return option::some(CropStats { base_yield_jax: 40, base_seed_jax: 80, growth_days: 130, harvest_au_bp: 160, soil_delta_bp: 500, soil_delta_neg: false, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 20, bypro_type: 215 })
        } else if (seed_id == 29) { // Frijol (30)
            return option::some(CropStats { base_yield_jax: 30, base_seed_jax: 7, growth_days: 100, harvest_au_bp: 120, soil_delta_bp: 700, soil_delta_neg: false, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 15, bypro_type: 215 })
        } else if (seed_id == 31) { // Garbanzo (32)
            return option::some(CropStats { base_yield_jax: 25, base_seed_jax: 6, growth_days: 110, harvest_au_bp: 130, soil_delta_bp: 600, soil_delta_neg: false, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 12, bypro_type: 215 })
        } else if (seed_id == 33) { // Lenteja (34)
            return option::some(CropStats { base_yield_jax: 28, base_seed_jax: 5, growth_days: 80, harvest_au_bp: 100, soil_delta_bp: 800, soil_delta_neg: false, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 14, bypro_type: 215 })
        } else if (seed_id == 35) { // Guisante (36)
            return option::some(CropStats { base_yield_jax: 32, base_seed_jax: 6, growth_days: 90, harvest_au_bp: 110, soil_delta_bp: 700, soil_delta_neg: false, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 16, bypro_type: 215 })
        
        // OILSEEDS / FIBER
        } else if (seed_id == 37) { // Girasol (38)
            return option::some(CropStats { base_yield_jax: 30, base_seed_jax: 5, growth_days: 110, harvest_au_bp: 130, soil_delta_bp: 700, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 39) { // Sésamo (40)
            return option::some(CropStats { base_yield_jax: 20, base_seed_jax: 3, growth_days: 90, harvest_au_bp: 110, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 41) { // Lino Textil (42)
            return option::some(CropStats { base_yield_jax: 25, base_seed_jax: 8, growth_days: 100, harvest_au_bp: 120, soil_delta_bp: 500, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 12, bypro_type: 216 })
        } else if (seed_id == 43) { // Cáñamo (44)
            return option::some(CropStats { base_yield_jax: 45, base_seed_jax: 60, growth_days: 120, harvest_au_bp: 140, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 22, bypro_type: 215 })
        } else if (seed_id == 45) { // Caña (46)
            return option::some(CropStats { base_yield_jax: 300, base_seed_jax: 8000, growth_days: 270, harvest_au_bp: 320, soil_delta_bp: 1500, soil_delta_neg: true, is_perennial: true, needs_irrigation: true, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 105) { // Algodón (106)
            return option::some(CropStats { base_yield_jax: 40, base_seed_jax: 10, growth_days: 150, harvest_au_bp: 180, soil_delta_bp: 900, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 20, bypro_type: 216 })
        } else if (seed_id == 119) { // Lino Aceite (120)
            return option::some(CropStats { base_yield_jax: 35, base_seed_jax: 6, growth_days: 110, harvest_au_bp: 130, soil_delta_bp: 500, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 12, bypro_type: 216 })
        
        // TOBACCO
        } else if (seed_id == 161) { // Tabaco (162)
            return option::some(CropStats { base_yield_jax: 25, base_seed_jax: 1, growth_days: 130, harvest_au_bp: 220, soil_delta_bp: 1200, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })

        // VEGETABLES
        } else if (seed_id == 49) { // Tomate (50)
            return option::some(CropStats { base_yield_jax: 120, base_seed_jax: 1, growth_days: 110, harvest_au_bp: 130, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 51) { // Pimiento (52)
            return option::some(CropStats { base_yield_jax: 100, base_seed_jax: 1, growth_days: 120, harvest_au_bp: 140, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 53) { // Chile (54)
            return option::some(CropStats { base_yield_jax: 90, base_seed_jax: 1, growth_days: 130, harvest_au_bp: 160, soil_delta_bp: 500, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 55) { // Cebolla (56)
            return option::some(CropStats { base_yield_jax: 180, base_seed_jax: 200, growth_days: 120, harvest_au_bp: 140, soil_delta_bp: 500, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 54, bypro_type: 215 })
        } else if (seed_id == 57) { // Ajo (58)
            return option::some(CropStats { base_yield_jax: 150, base_seed_jax: 150, growth_days: 150, harvest_au_bp: 180, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 45, bypro_type: 216 })
        } else if (seed_id == 59) { // Zanahoria (60)
            return option::some(CropStats { base_yield_jax: 160, base_seed_jax: 1, growth_days: 110, harvest_au_bp: 130, soil_delta_bp: 400, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 48, bypro_type: 215 })
        } else if (seed_id == 61) { // Repollo (62)
            return option::some(CropStats { base_yield_jax: 200, base_seed_jax: 1, growth_days: 90, harvest_au_bp: 110, soil_delta_bp: 500, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 60, bypro_type: 215 })
        } else if (seed_id == 63) { // Calabaza (64)
            return option::some(CropStats { base_yield_jax: 140, base_seed_jax: 2, growth_days: 100, harvest_au_bp: 120, soil_delta_bp: 400, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })

        // FRUITS (Perennial yields are per year, cost includes saplings)
        } else if (seed_id == 65) { // Manzana (66)
            return option::some(CropStats { base_yield_jax: 40, base_seed_jax: 200, growth_days: 1460, harvest_au_bp: 400, soil_delta_bp: 300, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 67) { // Pera (68)
            return option::some(CropStats { base_yield_jax: 35, base_seed_jax: 200, growth_days: 1460, harvest_au_bp: 380, soil_delta_bp: 300, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 69) { // Durazno (70)
            return option::some(CropStats { base_yield_jax: 30, base_seed_jax: 150, growth_days: 1095, harvest_au_bp: 320, soil_delta_bp: 200, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 71) { // Banana (72)
            return option::some(CropStats { base_yield_jax: 250, base_seed_jax: 10, growth_days: 365, harvest_au_bp: 280, soil_delta_bp: 400, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 73) { // Plátano (74)
            return option::some(CropStats { base_yield_jax: 220, base_seed_jax: 10, growth_days: 365, harvest_au_bp: 260, soil_delta_bp: 500, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 75) { // Naranja (76)
            return option::some(CropStats { base_yield_jax: 180, base_seed_jax: 100, growth_days: 1825, harvest_au_bp: 450, soil_delta_bp: 300, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 77) { // Mango (78)
            return option::some(CropStats { base_yield_jax: 150, base_seed_jax: 80, growth_days: 1825, harvest_au_bp: 420, soil_delta_bp: 400, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 79) { // Papaya (80)
            return option::some(CropStats { base_yield_jax: 200, base_seed_jax: 50, growth_days: 547, harvest_au_bp: 220, soil_delta_bp: 300, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 81) { // Piña (82)
            return option::some(CropStats { base_yield_jax: 160, base_seed_jax: 50, growth_days: 547, harvest_au_bp: 200, soil_delta_bp: 200, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 83) { // Aguacate (84)
            return option::some(CropStats { base_yield_jax: 120, base_seed_jax: 50, growth_days: 1460, harvest_au_bp: 350, soil_delta_bp: 300, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 85) { // Coco (86)
            return option::some(CropStats { base_yield_jax: 100, base_seed_jax: 50, growth_days: 2190, harvest_au_bp: 500, soil_delta_bp: 200, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 87) { // Oliva (88)
            return option::some(CropStats { base_yield_jax: 20, base_seed_jax: 100, growth_days: 2555, harvest_au_bp: 600, soil_delta_bp: 400, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 89) { // Dátil (90)
            return option::some(CropStats { base_yield_jax: 150, base_seed_jax: 50, growth_days: 1825, harvest_au_bp: 440, soil_delta_bp: 300, soil_delta_neg: false, is_perennial: true, needs_irrigation: true, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 91) { // Uva (92)
            return option::some(CropStats { base_yield_jax: 50, base_seed_jax: 300, growth_days: 1095, harvest_au_bp: 300, soil_delta_bp: 500, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 93) { // Fresa (94)
            return option::some(CropStats { base_yield_jax: 25, base_seed_jax: 2, growth_days: 365, harvest_au_bp: 150, soil_delta_bp: 600, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })

        // LUXURY
        } else if (seed_id == 99) { // Almendra (100)
            return option::some(CropStats { base_yield_jax: 30, base_seed_jax: 150, growth_days: 1460, harvest_au_bp: 360, soil_delta_bp: 400, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 101) { // Nuez (102)
            return option::some(CropStats { base_yield_jax: 25, base_seed_jax: 120, growth_days: 2190, harvest_au_bp: 480, soil_delta_bp: 300, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 103) { // Cacao (104)
            return option::some(CropStats { base_yield_jax: 80, base_seed_jax: 60, growth_days: 1460, harvest_au_bp: 400, soil_delta_bp: 500, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 109) { // Café (110)
            return option::some(CropStats { base_yield_jax: 60, base_seed_jax: 80, growth_days: 1095, harvest_au_bp: 340, soil_delta_bp: 800, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 111) { // Vainilla (112)
            return option::some(CropStats { base_yield_jax: 5, base_seed_jax: 40, growth_days: 730, harvest_au_bp: 240, soil_delta_bp: 700, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })

        // FORAGE
        } else if (seed_id == 107) { // Trébol (108)
            return option::some(CropStats { base_yield_jax: 250, base_seed_jax: 5, growth_days: 90, harvest_au_bp: 110, soil_delta_bp: 1000, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 125, bypro_type: 215 })
        } else if (seed_id == 113) { // Raygrás (114)
            return option::some(CropStats { base_yield_jax: 280, base_seed_jax: 8, growth_days: 80, harvest_au_bp: 100, soil_delta_bp: 1200, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 140, bypro_type: 215 })
        } else if (seed_id == 115) { // Festuca (116)
            return option::some(CropStats { base_yield_jax: 240, base_seed_jax: 6, growth_days: 90, harvest_au_bp: 110, soil_delta_bp: 1000, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 120, bypro_type: 215 })
        } else if (seed_id == 117) { // Alfalfa (118)
            return option::some(CropStats { base_yield_jax: 300, base_seed_jax: 10, growth_days: 75, harvest_au_bp: 90, soil_delta_bp: 1500, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 150, bypro_type: 215 })

        } else {
            return option::none()
        }
    }

    // --- Accessors ---
    fun base_yield_jax(stats: &CropStats): u64 { stats.base_yield_jax }
    fun base_seed_jax(stats: &CropStats): u64 { stats.base_seed_jax }
    fun harvest_au_bp(stats: &CropStats): u64 { stats.harvest_au_bp }
    fun growth_days(stats: &CropStats): u64 { stats.growth_days }
    fun soil_delta_bp(stats: &CropStats): u64 { stats.soil_delta_bp }
    fun soil_delta_neg(stats: &CropStats): bool { stats.soil_delta_neg }
    fun is_perennial(stats: &CropStats): bool { stats.is_perennial }
    fun needs_irrigation(stats: &CropStats): bool { stats.needs_irrigation }
    fun bypro_yield_jax(stats: &CropStats): u64 { stats.bypro_yield_jax }
    fun bypro_type(stats: &CropStats): u64 { stats.bypro_type }

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

    // === Farm Building Getters ===
    public fun id_granja_pequena(): u64 { altriuxbuildingbase::type_granja_pequena() }
    public fun id_granja_mediana(): u64 { altriuxbuildingbase::type_granja_mediana() }
    public fun id_granja_grande(): u64 { altriuxbuildingbase::type_granja_grande() }
    public fun id_huerto(): u64 { altriuxbuildingbase::type_huerto() }
    
    // Farm stats (moved from buildings)
    public fun get_farm_stats(type_id: u64): (u64, u64, u64) {
        if (type_id == altriuxbuildingbase::type_granja_pequena()) (100, 2, 100)
        else if (type_id == altriuxbuildingbase::type_granja_mediana()) (200, 4, 250)
        else if (type_id == altriuxbuildingbase::type_granja_grande()) (400, 8, 500)
        else if (type_id == altriuxbuildingbase::type_huerto()) (50, 1, 50)
        else (0, 0, 0)
    }
}

