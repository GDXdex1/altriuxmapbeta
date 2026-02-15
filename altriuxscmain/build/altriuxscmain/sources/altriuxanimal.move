module altriux::altriuxanimal {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::clock::Clock;
    use altriux::altriuxresources::{Self, Inventory, add_jax, create_inventory, consume_jax};
    use altriux::altriuxutils;
    use altriux::altriuxland::{Self, LandRegistry};
    use altriux::altriuxlocation;
    use sui::dynamic_field;
    use std::vector;
    use std::option::{Self, Option};
    use altriux::altriuxproduction::{Self, ProductionBatch};
    use altriux::altriuxfood;
    use altriux::altriuxtrade;

 
    const BURRO: u8 = 18;
    const BURRA: u8 = 19;
    const ALPACA_MACHO: u8 = 20;
    const ALPACA_HEMBRA: u8 = 21;
    const LLAMA_MACHO: u8 = 22;
    const LLAMA_HEMBRA: u8 = 23;
    const CONEJO: u8 = 24;
    const CONEJA: u8 = 25;
    const GANSO: u8 = 26;
    const GANSA: u8 = 27;
    const CEBU_MACHO: u8 = 28;
    const CEBU_HEMBRA: u8 = 29;
    const MULO: u8 = 30;
    const MULA: u8 = 31;
    const OVEJA_MACHO: u8 = 40;   // from MUFLON
    const OVEJA_HEMBRA: u8 = 41;
    const CABRA_MACHO: u8 = 42;   // from CABRA_MONTES
    const CABRA_HEMBRA: u8 = 43;
    const TORO: u8 = 44;           // from URO
    const VACA: u8 = 45;
    const BUFALO_MACHO: u8 = 46;   
    const BUFALO_HEMBRA: u8 = 47;
    const CABALLO: u8 = 48;        // from CABALLO_SALVAJE
    const YEGUA: u8 = 49;
    const CAMELLO: u8 = 50;        // from CAMELLO_SALVAJE
    const CAMELLA: u8 = 51;
    const YAK_MACHO: u8 = 52;      // from YAK_SALVAJE
    const YAK_HEMBRA: u8 = 53;
    const PATO: u8 = 54;           // from PATO_REAL
    const PATA: u8 = 55;
    const GALLO: u8 = 56;          // from GALLO_BANKIVA
    const GALLINA: u8 = 57;
    const CERDO: u8 = 58;          // from JABALI
    const CERDA: u8 = 59;
    const PERRO_M: u8 = 60;        
    const PERRO_F: u8 = 61;
    const GATO_M: u8 = 62;
    const GATO_F: u8 = 63;
    const ELEFANTE: u8 = 64;
    const ELEFANTA: u8 = 65;
    const CAPIBARA_MACHO: u8 = 66;
    const CAPIBARA_HEMBRA: u8 = 67;

    // --- Gender ---
    const MALE: u8 = 0;
    const FEMALE: u8 = 1;

    // --- Resources ---
    const JAX_ROPE: u64 = 215; 
    const JAX_MEAT: u64 = 227;
    const JAX_FORAGE: u64 = 215; // Heno

    // --- Units of Measurement ---
    const UNIT_WEIGHT_JAX: u64 = 20000; // 20kg in grams (base weight unit)
    const UNIT_VOLUME_JIX: u64 = 20;    // 20 Liters
    const UNIT_AREA_JEX: u64 = 10000;   // 1m2 (cm2? 100x100=10000)

    // --- Error Codes ---
    const E_NOT_OLD_ENOUGH: u64 = 101;
    const E_ALREADY_GELDING: u64 = 102;
    const E_WRONG_SPECIES: u64 = 103;
    const E_INVALID_BIOME_FOR_YAK: u64 = 104; 

    // --- Equipment Types ---
    const EQUIP_NONE: u8 = 0;
    const EQUIP_CART: u8 = 1;
    const EQUIP_PLOUGH: u8 = 2;

    public struct Animal has key, store {
        id: UID,
        animal_type: u8,
        gender: u8, 
        birth_timestamp: u64,
        health: u8,        // 0-100
        energy: u8,        // 0-100
        owner: address,
        tile_id: u64, 
        weight: u64,       // Current weight in grams
        last_fed_ms: u64,
        last_update_ms: u64,
        is_gestating: bool,
        gestation_end: u64,
        // --- Logistics ---
        is_gelding: bool,  
        load_capacity: u64, // In JAX (20kg units)
        draft_capacity: u64, 
        current_load: u64,  
        attached_wagon_id: Option<ID>, 
    }

    public struct DomesticatedHerd has key, store {
        id: UID,
        owner: address,
        tile_id: u64,
        animals: vector<Animal>,
    }

    // Called by WildAnimal module
    public fun create_domesticated_from_capture(
        domestic_types: vector<u8>,
        genders: vector<u8>,
        tile_id: u64, 
        hero_inv: &mut Inventory, 
        clock: &Clock, 
        land_reg: &LandRegistry,
        ctx: &mut TxContext
    ) {
        let count = vector::length(&domestic_types);
        
        let mut j = 0;
        let biome = altriuxland::get_land_biome_by_id(land_reg, tile_id);
        while (j < count) {
            let domestic_type = *vector::borrow(&domestic_types, j);
            if (domestic_type == YAK_MACHO || domestic_type == YAK_HEMBRA) {
                assert!(biome == 2 || biome == 8, E_INVALID_BIOME_FOR_YAK);
            };
            j = j + 1;
        };

        let mut domesticated = DomesticatedHerd {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            tile_id,
            animals: vector::empty(),
        };

        let mut herd_inv = create_inventory(tx_context::sender(ctx), ctx);
        altriuxresources::transfer_jax(hero_inv, &mut herd_inv, JAX_ROPE, count, clock);
        dynamic_field::add(&mut domesticated.id, b"inventory", herd_inv);

        let mut i = 0;
        let now = sui::clock::timestamp_ms(clock);
        while (i < count) {
            let domestic_type = *vector::borrow(&domestic_types, i);
            let gender = *vector::borrow(&genders, i);
            let (adult_weight, _) = get_adult_weight_range(domestic_type);
            
            let (load_cap, draft_cap) = get_default_capacities(domestic_type, gender, false);
            
            let animal = Animal {
                id: object::new(ctx),
                animal_type: domestic_type,
                gender,
                birth_timestamp: now - (365 * 24 * 3600 * 1000 / 4), 
                health: 100,
                energy: 100,
                owner: tx_context::sender(ctx),
                tile_id,
                weight: adult_weight, 
                last_fed_ms: now,
                last_update_ms: now,
                is_gestating: false,
                gestation_end: 0,
                is_gelding: false,
                load_capacity: load_cap,
                draft_capacity: draft_cap,
                current_load: 0,
                attached_wagon_id: option::none(),
            };
            vector::push_back(&mut domesticated.animals, animal);
            i = i + 1;
        };

        transfer::share_object(domesticated);
    }

    // --- Metabolism & Feeding ---

    public fun process_metabolism(animal: &mut Animal, clock: &Clock) {
        let now = sui::clock::timestamp_ms(clock);
        let elapsed_ms = now - animal.last_update_ms;
        let day_ms = 24 * 3600 * 1000;
        
        if (elapsed_ms < day_ms) return;

        let full_days = elapsed_ms / day_ms;
        
        let time_since_fed = now - animal.last_fed_ms;
        if (time_since_fed > (7 * day_ms)) {
            let hp_penalty = (10 * full_days as u64);
            if (hp_penalty >= (animal.health as u64)) {
                animal.health = 0;
            } else {
                animal.health = animal.health - (hp_penalty as u8);
            };

            let energy_penalty = (20 * full_days as u64);
            if (energy_penalty >= (animal.energy as u64)) {
                animal.energy = 0;
            } else {
                animal.energy = animal.energy - (energy_penalty as u8);
            };
        };

        if (time_since_fed > (2 * day_ms)) {
            let loss_rate = get_weight_loss_rate(animal.animal_type);
            let total_loss = loss_rate * full_days;
            if (total_loss >= animal.weight) {
                animal.weight = 0;
            } else {
                animal.weight = animal.weight - total_loss;
            };

            let (adult_weight, _) = get_adult_weight_range(animal.animal_type);
            if (animal.weight < (adult_weight * 40 / 100)) {
                animal.health = 0;
            };
        };

        animal.last_update_ms = now;
    }

    public fun is_bird(animal_type: u8): bool {
        animal_type == GALLO || animal_type == GALLINA ||
        animal_type == PATO || animal_type == PATA ||
        animal_type == GANSO || animal_type == GANSA
    }

    public fun is_draft_animal(animal_type: u8): bool {
        animal_type == TORO || animal_type == CABALLO || animal_type == YEGUA ||
        animal_type == BURRO || animal_type == BURRA ||
        animal_type == MULO || animal_type == MULA ||
        animal_type == YAK_MACHO || animal_type == YAK_HEMBRA ||
        animal_type == CEBU_MACHO || animal_type == CEBU_HEMBRA
    }

    public fun feed_animal(animal: &mut Animal, inv: &mut Inventory, amount_jax: u64, clock: &Clock) {
        process_metabolism(animal, clock);
        
        let required_scaled = get_daily_requirement_jax(animal.animal_type); 
        let amount_needed_scaled = required_scaled * 7;
        // Convert back to JAX (Divide by 10)
        let amount_needed = (amount_needed_scaled + 9) / 10; // Round up
        assert!(amount_jax >= amount_needed, 101); 

        consume_jax(inv, JAX_FORAGE, amount_needed, clock);
        
        let now = sui::clock::timestamp_ms(clock);
        animal.last_fed_ms = now;
        
        if (animal.health <= 80) animal.health = animal.health + 20 else animal.health = 100;
        if (animal.energy <= 80) animal.energy = animal.energy + 20 else animal.energy = 100;

        let (adult_weight, _) = get_adult_weight_range(animal.animal_type);
        if (animal.weight < adult_weight) {
            animal.weight = animal.weight + (adult_weight / 100); 
            if (animal.weight > adult_weight) animal.weight = adult_weight;
        };
    }

    public fun feed_poultry(herd: &mut DomesticatedHerd, inv: &mut Inventory, grain_id: u64, clock: &Clock, ctx: &mut TxContext) {
        assert!(altriuxfood::is_cereal(grain_id) || altriuxfood::get_category(grain_id) == 3, 101); // Cereals or Legumes (Grains)
        
        let mut bird_count = 0;
        let mut i = 0;
        let len = vector::length(&herd.animals);
        while (i < len) {
            let animal = vector::borrow_mut(&mut herd.animals, i);
            process_metabolism(animal, clock);
            if (is_bird(animal.animal_type)) {
                bird_count = bird_count + 1;
            };
            i = i + 1;
        };

        if (bird_count == 0) return;

        // 0.15 JAX per 7 days per bird
        let total_grain_needed = (bird_count * 15) / 100; // Simplified for JAX units if 1 unit = 0.01 JAX?
        // Wait, if I can't do decimals, I'll use 15 as 0.15. 
        // Let's assume the user accepts 1 JAX = 100 units for grains? 
        // Or if 1 JAX = 1 unit, then 60 birds need 9 JAX. (60 * 0.15 = 9).
        // Let's use the formula: (bird_count * 15 + 99) / 100 to round up.
        let amount_to_consume = (bird_count * 15 + 99) / 100;
        consume_jax(inv, grain_id, amount_to_consume, clock);

        // Update last_fed_ms for all birds
        let now = sui::clock::timestamp_ms(clock);
        let mut j = 0;
        while (j < len) {
            let animal = vector::borrow_mut(&mut herd.animals, j);
            if (is_bird(animal.animal_type)) {
                animal.last_fed_ms = now;
                if (animal.health <= 80) animal.health = animal.health + 20 else animal.health = 100;
                if (animal.energy <= 80) animal.energy = animal.energy + 20 else animal.energy = 100;
            };
            j = j + 1;
        };
    }

    public fun claim_eggs(herd: &mut DomesticatedHerd, inv: &mut Inventory, clock: &Clock, ctx: &mut TxContext) {
        let mut female_birds = 0;
        let now = sui::clock::timestamp_ms(clock);
        let mut i = 0;
        let len = vector::length(&herd.animals);
        while (i < len) {
            let animal = vector::borrow(&herd.animals, i);
            if (is_bird(animal.animal_type) && animal.gender == FEMALE) {
                // Check if fed recently (within 7 days)
                if (now <= animal.last_fed_ms + (7 * 24 * 3600 * 1000)) {
                    female_birds = female_birds + 1;
                };
            };
            i = i + 1;
        };

        if (female_birds == 0) return;

        // 65% yield postural
        let eggs_count = (female_birds * 65) / 100;
        if (eggs_count > 0) {
            // As discussed, 1 JAX of eggs is a lot. But using it for consistency.
            add_jax(inv, altriuxfood::JAX_EGG(), eggs_count, 0, clock);
        };
    }

    // --- Breeding System ---

    public fun mate(male: &Animal, female: &mut Animal, clock: &Clock) {
        assert!(female.gender == FEMALE, 201);
        assert!(male.gender == MALE, 202);
        assert!(!female.is_gestating, 203);
        
        let m_species = get_species_from_type(male.animal_type);
        let f_species = get_species_from_type(female.animal_type);
        assert!(m_species == f_species && m_species != 0, 204);

        let now = sui::clock::timestamp_ms(clock);
        let (_, _, _, _, bio_gest_days) = get_biological_stats(female.animal_type, FEMALE);
        assert!(bio_gest_days > 0, 205);

        let game_gest_duration_ms = (bio_gest_days * 24 * 3600 * 1000) / 4;
        
        female.is_gestating = true;
        female.gestation_end = now + game_gest_duration_ms;
    }

    public fun claim_offspring(mother: &mut Animal, clock: &Clock, ctx: &mut TxContext): Animal {
        let now = sui::clock::timestamp_ms(clock);
        assert!(mother.is_gestating, 206);
        assert!(now >= mother.gestation_end, 207);

        mother.is_gestating = false;
        let birth_time = mother.gestation_end; 

        let species = get_species_from_type(mother.animal_type);
        let gender_rand = altriuxutils::random(1, 100, ctx);
        let gender = if (gender_rand <= 50) MALE else FEMALE;
        let offspring_type = get_type_from_species_gender(species, gender);

        let (adult_weight, _) = get_adult_weight_range(offspring_type);
        let (load_cap, draft_cap) = get_default_capacities(offspring_type, gender, false);

        Animal {
            id: object::new(ctx),
            animal_type: offspring_type,
            gender,
            birth_timestamp: birth_time,
            health: 100,
            energy: 100,
            owner: tx_context::sender(ctx),
            tile_id: mother.tile_id,
            weight: adult_weight / 10, 
            last_fed_ms: now,
            last_update_ms: now,
            is_gestating: false,
            gestation_end: 0,
            is_gelding: false,
            load_capacity: load_cap,
            draft_capacity: draft_cap,
            current_load: 0,
            attached_wagon_id: option::none(),
        }
    }

    public fun slaughter_animal(
        herd: &mut DomesticatedHerd,
        animal_idx: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): ProductionBatch {
        let animal = vector::remove(&mut herd.animals, animal_idx);
        let now = sui::clock::timestamp_ms(clock);
        
        // Calculate yield: ~50% of weight. 1 JAX = 20kg (20000g)
        let yield_jax = (animal.weight * 50 / 100) / 20000;
        let meat_type = get_meat_quality_tier(animal.animal_type);
        
        let batch = altriuxproduction::new_batch(
            object::id(herd),
            meat_type,
            yield_jax,
            now,
            now,
            option::some(altriuxlocation::new_location_simple(object::id_from_address(@0x0), animal.tile_id, 0)),
            ctx
        );

        destroy_animal(animal);
        batch
    }

    fun get_meat_quality_tier(t: u8): u64 {
        if (t == CABALLO || t == YEGUA || t == MULO || t == MULA) {
            altriuxfood::JAX_MEAT_FRESH_THIRD()
        } else if (
            t == TORO || t == VACA || t == BUFALO_MACHO || t == BUFALO_HEMBRA ||
            t == OVEJA_MACHO || t == OVEJA_HEMBRA || t == CABRA_MACHO || t == CABRA_HEMBRA ||
            t == CERDO || t == CERDA || t == YAK_MACHO || t == YAK_HEMBRA ||
            t == CAMELLO || t == CAMELLA || t == CEBU_MACHO || t == CEBU_HEMBRA ||
            t == ALPACA_MACHO || t == ALPACA_HEMBRA || t == LLAMA_MACHO || t == LLAMA_HEMBRA ||
            t == BURRO || t == BURRA
        ) {
            altriuxfood::JAX_MEAT_FRESH_BASIC()
        } else {
            altriuxfood::JAX_MEAT_FRESH_BASIC()
        }
    }

    fun destroy_animal(a: Animal) {
        let Animal { 
            id, animal_type: _, gender: _, birth_timestamp: _, health: _, energy: _, owner: _, 
            tile_id: _, weight: _, last_fed_ms: _, last_update_ms: _, is_gestating: _, gestation_end: _,
            is_gelding: _, load_capacity: _, draft_capacity: _, current_load: _, attached_wagon_id: _
        } = a;
        sui::object::delete(id);
    }

    fun get_species_from_type(t: u8): u8 {
        if (t == BURRO || t == BURRA) 18
        else if (t == ALPACA_MACHO || t == ALPACA_HEMBRA) 20
        else if (t == LLAMA_MACHO || t == LLAMA_HEMBRA) 22
        else if (t == CONEJO || t == CONEJA) 24
        else if (t == GANSO || t == GANSA) 26
        else if (t == CEBU_MACHO || t == CEBU_HEMBRA) 28
        else if (t == MULO || t == MULA) 30
        else if (t == OVEJA_MACHO || t == OVEJA_HEMBRA) 1
        else if (t == CABRA_MACHO || t == CABRA_HEMBRA) 2
        else if (t == TORO || t == VACA) 3
        else if (t == BUFALO_MACHO || t == BUFALO_HEMBRA) 4
        else if (t == CABALLO || t == YEGUA) 5
        else if (t == CAMELLO || t == CAMELLA) 6
        else if (t == YAK_MACHO || t == YAK_HEMBRA) 7
        else if (t == PATO || t == PATA) 10
        else if (t == GALLO || t == GALLINA) 11
        else if (t == CERDO || t == CERDA) 12
        else if (t == CAPIBARA_MACHO || t == CAPIBARA_HEMBRA) 19
        else 0
    }

    fun get_type_from_species_gender(species: u8, gender: u8): u8 {
        if (species == 18) { if (gender == MALE) BURRO else BURRA }
        else if (species == 20) { if (gender == MALE) ALPACA_MACHO else ALPACA_HEMBRA }
        else if (species == 22) { if (gender == MALE) LLAMA_MACHO else LLAMA_HEMBRA }
        else if (species == 24) { if (gender == MALE) CONEJO else CONEJA }
        else if (species == 26) { if (gender == MALE) GANSO else GANSA }
        else if (species == 28) { if (gender == MALE) CEBU_MACHO else CEBU_HEMBRA }
        else if (species == 30) { if (gender == MALE) MULO else MULA }
        else if (species == 1) { if (gender == MALE) OVEJA_MACHO else OVEJA_HEMBRA }
        else if (species == 2) { if (gender == MALE) CABRA_MACHO else CABRA_HEMBRA }
        else if (species == 3) { if (gender == MALE) TORO else VACA }
        else if (species == 4) { if (gender == MALE) BUFALO_MACHO else BUFALO_HEMBRA }
        else if (species == 5) { if (gender == MALE) CABALLO else YEGUA }
        else if (species == 6) { if (gender == MALE) CAMELLO else CAMELLA }
        else if (species == 7) { if (gender == MALE) YAK_MACHO else YAK_HEMBRA }
        else if (species == 10) { if (gender == MALE) PATO else PATA }
        else if (species == 11) { if (gender == MALE) GALLO else GALLINA }
        else if (species == 12) { if (gender == MALE) CERDO else CERDA }
        else if (species == 19) { if (gender == MALE) CAPIBARA_MACHO else CAPIBARA_HEMBRA }
        else species
    }

    // --- Loading & Transport ---

    public struct AnimalCargo has store {
        items: Inventory,
        current_weight_jax: u64,
        max_weight_jax: u64,
        equipment: u8, 
    }

    public fun load_animal(animal: &mut Animal, inv: &mut Inventory, jax_id: u64, amount: u64, clock: &Clock, ctx: &mut TxContext) {
        process_metabolism(animal, clock);
        init_cargo_if_needed(animal, ctx);
        
        let cargo = dynamic_field::borrow_mut<vector<u8>, AnimalCargo>(&mut animal.id, b"cargo");
        
        let mut capacity = cargo.max_weight_jax;
        if (cargo.equipment == EQUIP_CART) {
            capacity = capacity * 150 / 100; 
        };

        assert!(cargo.current_weight_jax + amount <= capacity, 102); 

        altriuxresources::transfer_jax(inv, &mut cargo.items, jax_id, amount, clock);
        cargo.current_weight_jax = cargo.current_weight_jax + amount;
    }

    public fun unload_animal(animal: &mut Animal, inv: &mut Inventory, jax_id: u64, amount: u64, clock: &Clock, ctx: &mut TxContext) {
        process_metabolism(animal, clock);
        let cargo = dynamic_field::borrow_mut<vector<u8>, AnimalCargo>(&mut animal.id, b"cargo");
        altriuxresources::transfer_jax(&mut cargo.items, inv, jax_id, amount, clock);
        cargo.current_weight_jax = cargo.current_weight_jax - amount;
    }

    // --- Mounting & Equipment ---

    public fun mount_animal(animal: &mut Animal, hero_id: &mut UID) {
        // process_metabolism(animal, clock_stub()); 
        assert!(animal.energy > 0, 103); 
        let t = animal.animal_type;
        assert!(
            t == CABALLO || t == YEGUA || 
            t == BURRO || t == BURRA || 
            t == CAMELLO || t == CAMELLA ||
            t == MULO || t == MULA, 
            104
        ); 
        
        if (dynamic_field::exists_(hero_id, b"mounted_animal")) {
            dynamic_field::remove<vector<u8>, u8>(hero_id, b"mounted_animal");
        };
        dynamic_field::add(hero_id, b"mounted_animal", animal.animal_type);
    }


    public fun equip_draft_tool(animal: &mut Animal, tool_type: u8, ctx: &mut TxContext) {
        let t = animal.animal_type;
        assert!(
            t == TORO || t == VACA || 
            t == CABALLO || t == YEGUA || 
            t == YAK_MACHO || t == YAK_HEMBRA || 
            t == BUFALO_MACHO || t == BUFALO_HEMBRA ||
            t == CEBU_MACHO || t == CEBU_HEMBRA, 
            105
        ); 
        assert!(tool_type == EQUIP_CART || tool_type == EQUIP_PLOUGH, 106);

        init_cargo_if_needed(animal, ctx);
        let cargo = dynamic_field::borrow_mut<vector<u8>, AnimalCargo>(&mut animal.id, b"cargo");
        cargo.equipment = tool_type;
    }

    fun init_cargo_if_needed(animal: &mut Animal, ctx: &mut TxContext) {
        if (!dynamic_field::exists_(&animal.id, b"cargo")) {
            let cargo_capacity = get_load_capacity_jax(animal.animal_type);
            let cargo_inv = create_inventory(animal.owner, ctx);
            dynamic_field::add(&mut animal.id, b"cargo", AnimalCargo {
                items: cargo_inv,
                current_weight_jax: 0,
                max_weight_jax: cargo_capacity,
                equipment: EQUIP_NONE,
            });
        };
    }

    // --- Helper Stats ---

    fun get_weight_loss_rate(t: u8): u64 {
        if (t == OVEJA_MACHO || t == OVEJA_HEMBRA) 40
        else if (t == CABRA_MACHO || t == CABRA_HEMBRA) 55
        else if (t == TORO || t == VACA) 500
        else if (t == BUFALO_MACHO || t == BUFALO_HEMBRA) 425
        else if (t == CABALLO || t == YEGUA) 325
        else if (t == CAMELLO || t == CAMELLA) 250
        else if (t == YAK_MACHO || t == YAK_HEMBRA) 375
        else if (t == PATO || t == PATA || t == GALLO || t == GALLINA) 10
        else if (t == CERDO || t == CERDA) 75
        else if (t == BURRO || t == BURRA) 200
        else if (t == ALPACA_MACHO || t == ALPACA_HEMBRA) 150
        else if (t == LLAMA_MACHO || t == LLAMA_HEMBRA) 180
        else if (t == CONEJO || t == CONEJA) 15
        else if (t == GANSO || t == GANSA) 20
        else if (t == CEBU_MACHO || t == CEBU_HEMBRA) 450
        else if (t == MULO || t == MULA) 300
        else if (t == CAPIBARA_MACHO || t == CAPIBARA_HEMBRA) 50
        else 10
    }

    fun get_adult_weight_range(t: u8): (u64, u64) {
        if (t == TORO || t == VACA) (600000, 800000)
        else if (t == BUFALO_MACHO || t == BUFALO_HEMBRA) (500000, 500000)
        else if (t == CABALLO || t == YEGUA) (300000, 350000)
        else if (t == OVEJA_MACHO || t == OVEJA_HEMBRA) (40000, 50000)
        else if (t == CABRA_MACHO || t == CABRA_HEMBRA) (50000, 75000)
        else if (t == CERDO || t == CERDA) (70000, 90000)
        else if (t == CAMELLO || t == CAMELLA) (500000, 600000)
        else if (t == YAK_MACHO || t == YAK_HEMBRA) (350000, 450000)
        else if (t == BURRO || t == BURRA) (150000, 250000)
        else if (t == ALPACA_MACHO || t == ALPACA_HEMBRA) (50000, 70000)
        else if (t == LLAMA_MACHO || t == LLAMA_HEMBRA) (100000, 150000)
        else if (t == CONEJO || t == CONEJA) (2000, 4000)
        else if (t == GANSO || t == GANSA) (4000, 8000)
        else if (t == CEBU_MACHO || t == CEBU_HEMBRA) (500000, 700000)
        else if (t == MULO || t == MULA) (300000, 450000)
        else if (t == CAPIBARA_MACHO || t == CAPIBARA_HEMBRA) (35000, 65000)
        else (50000, 50000)
    }

    fun get_daily_requirement_jax(t: u8): u64 {
        // Scaling: 1 unit = 2kg (1/10th of a JAX)
        if (t == TORO || t == VACA || t == BUFALO_MACHO || t == BUFALO_HEMBRA || t == CABALLO || t == YEGUA || t == CEBU_MACHO || t == CEBU_HEMBRA || t == CAMELLO || t == CAMELLA || t == YAK_MACHO || t == YAK_HEMBRA) 10 // 20kg
        else if (t == OVEJA_MACHO || t == OVEJA_HEMBRA || t == CABRA_MACHO || t == CABRA_HEMBRA || t == BURRO || t == BURRA || t == ALPACA_MACHO || t == ALPACA_HEMBRA || t == LLAMA_MACHO || t == LLAMA_HEMBRA || t == CAPIBARA_MACHO || t == CAPIBARA_HEMBRA) 1 // 2kg
        else 1
    }

    fun get_load_capacity_jax(t: u8): u64 {
        if (t == TORO || t == VACA) 20 
        else if (t == BURRO || t == BURRA) 5
        else if (t == CABALLO || t == YEGUA) 4 
        else if (t == CAMELLO || t == CAMELLA) 12 
        else if (t == YAK_MACHO || t == YAK_HEMBRA) 7 
        else if (t == LLAMA_MACHO || t == LLAMA_HEMBRA) 3
        else if (t == CEBU_MACHO || t == CEBU_HEMBRA) 15
        else if (t == MULO || t == MULA) 8
        else if (t == CAPIBARA_MACHO || t == CAPIBARA_HEMBRA) 1
        else 0
    }

    // --- Legacy Bridge ---


    public fun get_biological_stats(t: u8, gender: u8): (u64, u64, u64, u64, u64) {
        if (t == OVEJA_MACHO || t == OVEJA_HEMBRA) {
            if (gender == MALE) (180, 900, 2400, 3650, 0)
            else (180, 540, 3600, 4380, 150)
        } else if (t == CABRA_MACHO || t == CABRA_HEMBRA) {
            (180, 1260, 4000, 5475, 150)
        } else if (t == TORO || t == VACA) {
            (300, 1260, 6000, 9125, 280)
        } else if (t == BUFALO_MACHO || t == BUFALO_HEMBRA) {
            (240, 720, 6000, 9125, 310)
        } else if (t == CABALLO || t == YEGUA) {
            (360, 1440, 6000, 9125, 340)
        } else if (t == CAMELLO || t == CAMELLA) {
            (540, 1800, 8000, 14600, 400)
        } else if (t == YAK_MACHO || t == YAK_HEMBRA) {
            (300, 1440, 6000, 9125, 260)
        } else if (t == GALLO || t == GALLINA) {
            (120, 180, 1000, 1825, 21)
        } else if (t == PATO || t == PATA) {
            (60, 300, 1500, 2555, 28)
        } else if (t == CERDO || t == CERDA) {
            (120, 720, 2500, 3650, 114)
        } else if (t == BURRO || t == BURRA) {
            (180, 1260, 4000, 9125, 365)
        } else if (t == ALPACA_MACHO || t == ALPACA_HEMBRA) {
            (150, 900, 3000, 7300, 345)
        } else if (t == LLAMA_MACHO || t == LLAMA_HEMBRA) {
            (150, 900, 3000, 5475, 330)
        } else if (t == CONEJO || t == CONEJA) {
            (30, 120, 200, 1825, 31)
        } else if (t == GANSO || t == GANSA) {
            (30, 150, 400, 3650, 30)
        } else if (t == CEBU_MACHO || t == CEBU_HEMBRA) {
            (240, 1000, 6000, 9125, 285)
        } else if (t == MULO || t == MULA) {
            (300, 1440, 7000, 10950, 365)
        } else if (t == CAPIBARA_MACHO || t == CAPIBARA_HEMBRA) {
            (120, 365, 2000, 3650, 150)
        } else {
            (0, 0, 0, 0, 0)
        }
    }

    public fun get_ug_value(t: u8): u64 {
        if (t == TORO || t == VACA || t == BUFALO_MACHO || t == BUFALO_HEMBRA || t == CABALLO || t == YEGUA || t == CAMELLO || t == CAMELLA || t == YAK_MACHO || t == YAK_HEMBRA || t == CEBU_MACHO || t == CEBU_HEMBRA || t == MULO || t == MULA) return 1000; 
        if (t == OVEJA_MACHO || t == OVEJA_HEMBRA || t == CABRA_MACHO || t == CABRA_HEMBRA || t == BURRO || t == BURRA || t == ALPACA_MACHO || t == ALPACA_HEMBRA || t == LLAMA_MACHO || t == LLAMA_HEMBRA) return 250; 
        if (t == CERDO || t == CERDA) return 500; 
        if (t == PATO || t == PATA || t == GALLO || t == GALLINA || t == GANSO || t == GANSA || t == CONEJO || t == CONEJA) return 50; 
        if (t == CAPIBARA_MACHO || t == CAPIBARA_HEMBRA) return 250;
        100
    }

    #[test_only]
    public fun create_animal_for_testing(animal_type: u8, gender: u8, tile_id: u64, ctx: &mut TxContext): Animal {
        Animal {
            id: object::new(ctx),
            animal_type,
            gender,
            birth_timestamp: 0,
            health: 100,
            energy: 100,
            owner: tx_context::sender(ctx),
            tile_id,
            weight: 1000,
            last_fed_ms: 0,
            last_update_ms: 0,
            is_gestating: false,
            gestation_end: 0,
            is_gelding: false,
            load_capacity: 0,
            draft_capacity: 0,
            current_load: 0,
            attached_wagon_id: option::none(),
        }
    }

    #[test_only]
    public fun destroy_animal_for_testing(a: Animal) {
        let Animal { 
            id, animal_type: _, gender: _, birth_timestamp: _, health: _, energy: _, owner: _, 
            tile_id: _, weight: _, last_fed_ms: _, last_update_ms: _, is_gestating: _, gestation_end: _,
            is_gelding: _, load_capacity: _, draft_capacity: _, current_load: _, attached_wagon_id: _
        } = a;
        sui::object::delete(id);
    }

    #[test_only]
    public fun get_tile_id(a: &Animal): u64 { a.tile_id }

    #[test_only]
    public fun get_animal_gender(a: &Animal): u8 { a.gender }

    // --- ID Getters ---
    public fun id_burro(): u8 { BURRO }
    public fun id_burra(): u8 { BURRA }
    public fun id_alpaca_macho(): u8 { ALPACA_MACHO }
    public fun id_alpaca_hembra(): u8 { ALPACA_HEMBRA }
    public fun id_llama_macho(): u8 { LLAMA_MACHO }
    public fun id_llama_hembra(): u8 { LLAMA_HEMBRA }
    public fun id_conejo(): u8 { CONEJO }
    public fun id_coneja(): u8 { CONEJA }
    public fun id_ganso(): u8 { GANSO }
    public fun id_gansa(): u8 { GANSA }
    public fun id_cebu_macho(): u8 { CEBU_MACHO }
    public fun id_cebu_hembra(): u8 { CEBU_HEMBRA }
    public fun id_elefante(): u8 { ELEFANTE }
    public fun id_elefanta(): u8 { ELEFANTA }
    public fun id_mulo(): u8 { MULO }
    public fun id_mula(): u8 { MULA }
    public fun id_oveja_macho(): u8 { OVEJA_MACHO }
    public fun id_oveja_hembra(): u8 { OVEJA_HEMBRA }
    public fun id_cabra_macho(): u8 { CABRA_MACHO }
    public fun id_cabra_hembra(): u8 { CABRA_HEMBRA }
    public fun id_toro(): u8 { TORO }
    public fun id_vaca(): u8 { VACA }
    public fun id_bufalo_macho(): u8 { BUFALO_MACHO }
    public fun id_bufalo_hembra(): u8 { BUFALO_HEMBRA }
    public fun id_caballo(): u8 { CABALLO }
    public fun id_yegua(): u8 { YEGUA }
    public fun id_camello(): u8 { CAMELLO }
    public fun id_camella(): u8 { CAMELLA }
    public fun id_yak_macho(): u8 { YAK_MACHO }
    public fun id_yak_hembra(): u8 { YAK_HEMBRA }
    public fun id_pato(): u8 { PATO }
    public fun id_pata(): u8 { PATA }
    public fun id_gallo(): u8 { GALLO }
    public fun id_gallina(): u8 { GALLINA }
    public fun id_cerdo(): u8 { CERDO }
    public fun id_cerda(): u8 { CERDA }
    public fun id_perro_m(): u8 { PERRO_M }
    public fun id_perro_f(): u8 { PERRO_F }
    public fun id_gato_m(): u8 { GATO_M }
    public fun id_gato_f(): u8 { GATO_F }
    public fun id_capibara_m(): u8 { CAPIBARA_MACHO }
    public fun id_capibara_f(): u8 { CAPIBARA_HEMBRA }

    // === LOGISTICS FUNCTIONS ===

    public fun get_default_capacities(species: u8, _gender: u8, is_gelding: bool): (u64, u64) {
        if (species == CABALLO) {
            if (is_gelding) {
                return (12, 25)
            } else {
                return (7, 0)
            }
        };

        if (species == TORO || species == CEBU_MACHO || species == BUFALO_MACHO || species == CEBU_HEMBRA || species == BUFALO_HEMBRA || species == VACA) {
             return (10, 30)
        };
        
        if (species == MULO || species == MULA) {
            return (8, 15)
        };
        
        if (species == BURRO || species == BURRA) {
            return (6, 7)
        };

        if (species == YAK_MACHO || species == YAK_HEMBRA) {
            return (7, 15)
        };
        
        if (species == CAMELLO || species == CAMELLA) {
             return (12, 20)
        };
        
        if (species == LLAMA_MACHO || species == LLAMA_HEMBRA || species == ALPACA_MACHO || species == ALPACA_HEMBRA) {
             return (3, 0)
        };

        (0, 0)
    }

    public fun castrate_horse(
        herd: &mut DomesticatedHerd,
        animal_idx: u64,
        clock: &sui::clock::Clock,
        _ctx: &mut TxContext
    ) {
        let animal = vector::borrow_mut(&mut herd.animals, animal_idx);
        let now = sui::clock::timestamp_ms(clock);
        
        assert!(animal.animal_type == CABALLO, E_WRONG_SPECIES);
        assert!(animal.gender == MALE, E_WRONG_SPECIES);
        assert!(!animal.is_gelding, E_ALREADY_GELDING);

        let six_months_ms = 180 * 24 * 3600 * 1000;
        let age = now - animal.birth_timestamp;
        assert!(age >= six_months_ms, E_NOT_OLD_ENOUGH);

        animal.is_gelding = true;
        
        let (load, draft) = get_default_capacities(animal.animal_type, animal.gender, true);
        animal.load_capacity = load;
        animal.draft_capacity = draft;
    }

    public fun get_animal_logistics(animal: &Animal): (u64, u64, bool) {
        (animal.load_capacity, animal.draft_capacity, animal.is_gelding)
    }

    public fun get_animal_type(animal: &Animal): u8 {
        animal.animal_type
    }

    // === SECURED TRANSFER (Trade Pattern) ===
    public fun transfer_animal(
        registry: &mut altriuxtrade::TransitRegistry,
        animal: Animal,
        recipient: address,
        from_loc: &altriux::altriuxlocation::ResourceLocation,
        to_loc: &altriux::altriuxlocation::ResourceLocation,
        lrc_treasury: &mut altriux::lrc::LRCTreasury,
        lrc_payment: sui::coin::Coin<altriux::lrc::LRC>,
        clock: &sui::clock::Clock,
        ctx: &mut TxContext
    ) {
        // Use transit system with 10 LRC base cost per unit distance
        altriuxtrade::init_object_transit(
            registry,
            animal,
            from_loc,
            to_loc,
            recipient,
            10, // Cost per unit
            lrc_treasury,
            lrc_payment,
            clock,
            ctx
        );
    }
}
