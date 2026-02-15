module altriux::altriuxwildanimal {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::clock::Clock;
    use altriux::altriuxhero::{Self, Hero};
    use altriux::altriuxresources::{Self, Inventory, add_jax};
    use altriux::kingdomutils;
    use altriux::altriuxmilitaryitems;
    use std::vector;
    use altriux::altriuxanimal;
    use altriux::altriuxland::{Self, LandRegistry};
    use sui::table::{Self, Table};

    // --- Species Constants ---
    const MUFLON: u8 = 1;
    const CABRA_MONTES: u8 = 2;
    const URO: u8 = 3;           
    const BUFALO: u8 = 4;        
    const CABALLO_SALVAJE: u8 = 5; 
    const CAMELLO_SALVAJE: u8 = 6;
    const YAK_SALVAJE: u8 = 7;
    const GUANACO: u8 = 8;
    const VICUNA: u8 = 9;
    const PATO_REAL: u8 = 10;
    const GALLO_BANKIVA: u8 = 11;
    const JABALI: u8 = 12;
    const LOBO: u8 = 13;
    const CHACAL: u8 = 14;
    const GATO_MONTES: u8 = 15;
    const PERRO_SALVAJE: u8 = 16;
    const ASNO_SALVAJE: u8 = 17;

    const CONEJO_SALVAJE: u8 = 32;
    const GANSO_SALVAJE: u8 = 33;
    const CEBU_SALVAJE: u8 = 34;
    const ELEFANTE_SALVAJE: u8 = 35;

    // --- Errors ---
    const E_NOT_ON_TILE: u64 = 107;
    const E_HERD_EMPTY: u64 = 108;
    const E_CAPTURE_FAILED: u64 = 110;
    const E_TOO_MANY_WORKERS: u64 = 111;
    const E_NO_HUNTING_WEAPON: u64 = 112;

    // --- Resources ---
    const JAX_MEAT: u64 = 227;

    public struct WildHerd has key {
        id: UID,
        animal_type: u8,
        count: u64,
        tile_id: u64,
        is_migratory: bool,
    }

    public struct PopulationRegistry has key {
        id: UID,
        current_pop: Table<u8, u64>,
        max_pop: Table<u8, u64>,
    }

    public fun init_registry(ctx: &mut TxContext) {
        let mut current_pop = table::new(ctx);
        let mut max_pop = table::new(ctx);

        // Apogeo Limits
        table::add(&mut max_pop, MUFLON, 4000000);
        table::add(&mut max_pop, CABRA_MONTES, 6000000);
        table::add(&mut max_pop, URO, 1000000);
        table::add(&mut max_pop, BUFALO, 2000000);
        table::add(&mut max_pop, CABALLO_SALVAJE, 10000000);
        table::add(&mut max_pop, CAMELLO_SALVAJE, 1000000);
        table::add(&mut max_pop, YAK_SALVAJE, 400000);
        table::add(&mut max_pop, LOBO, 2000000);
        table::add(&mut max_pop, CHACAL, 1000000);
        table::add(&mut max_pop, JABALI, 20000000);
        table::add(&mut max_pop, GATO_MONTES, 4000000);
        table::add(&mut max_pop, GALLO_BANKIVA, 10000000);
        table::add(&mut max_pop, PATO_REAL, 100000000);
        table::add(&mut max_pop, GUANACO, 2000000);
        table::add(&mut max_pop, VICUNA, 3000000);
        table::add(&mut max_pop, ASNO_SALVAJE, 1500000);
        table::add(&mut max_pop, CONEJO_SALVAJE, 50000000);
        table::add(&mut max_pop, GANSO_SALVAJE, 10000000);
        table::add(&mut max_pop, CEBU_SALVAJE, 2000000);
        table::add(&mut max_pop, ELEFANTE_SALVAJE, 500000);

        // Current Pop (Initial state) - could be 100% or less
        table::add(&mut current_pop, MUFLON, 4000000);
        table::add(&mut current_pop, CABRA_MONTES, 6000000);
        table::add(&mut current_pop, URO, 1000000);
        table::add(&mut current_pop, BUFALO, 2000000);
        table::add(&mut current_pop, CABALLO_SALVAJE, 10000000);
        table::add(&mut current_pop, CAMELLO_SALVAJE, 1000000);
        table::add(&mut current_pop, YAK_SALVAJE, 400000);
        table::add(&mut current_pop, LOBO, 2000000);
        table::add(&mut current_pop, CHACAL, 1000000);
        table::add(&mut current_pop, JABALI, 20000000);
        table::add(&mut current_pop, GATO_MONTES, 4000000);
        table::add(&mut current_pop, GALLO_BANKIVA, 10000000);
        table::add(&mut current_pop, PATO_REAL, 100000000);
        table::add(&mut current_pop, GUANACO, 2000000);
        table::add(&mut current_pop, VICUNA, 3000000);
        table::add(&mut current_pop, ASNO_SALVAJE, 1500000);
        table::add(&mut current_pop, CONEJO_SALVAJE, 50000000);
        table::add(&mut current_pop, GANSO_SALVAJE, 10000000);
        table::add(&mut current_pop, CEBU_SALVAJE, 2000000);
        table::add(&mut current_pop, ELEFANTE_SALVAJE, 500000);

        transfer::share_object(PopulationRegistry {
            id: object::new(ctx),
            current_pop,
            max_pop,
        });
    }

    public fun spawn_wild_herd(animal_type: u8, count: u64, tile_id: u64, is_migratory: bool, ctx: &mut TxContext) {
        let herd = WildHerd {
            id: object::new(ctx),
            animal_type,
            count,
            tile_id,
            is_migratory,
        };
        transfer::share_object(herd);
    }

    public fun capture_to_domestic(
        hero: &Hero, 
        herd: &mut WildHerd, 
        reg: &mut PopulationRegistry,
        inv: &mut Inventory,
        land_reg: &altriux::altriuxland::LandRegistry,
        is_mounted: bool,
        workers_count: u64,
        workers_mounted: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(altriuxhero::get_current_tile(hero) == herd.tile_id, E_NOT_ON_TILE);
        assert!(herd.count > 0, E_HERD_EMPTY);
        assert!(workers_count <= 7, E_TOO_MANY_WORKERS); 

        let prob = calculate_prob(herd.animal_type, is_mounted, workers_count, workers_mounted);
        let mut captures = prob / 100;
        let remaining_prob = prob % 100;
        
        let rand = kingdomutils::random(1, 100, ctx);
        if (rand <= remaining_prob) {
            captures = captures + 1;
        };

        if (captures == 0) abort E_CAPTURE_FAILED;
        if (captures > herd.count) captures = herd.count;

        herd.count = herd.count - captures;
        update_current_pop(reg, herd.animal_type, captures, false);

        let mut domestic_types = vector::empty<u8>();
        let mut genders = vector::empty<u8>();
        let mut i = 0;
        while (i < captures) {
            let gender_rand = kingdomutils::random(1, 100, ctx);
            let gender = if (gender_rand <= 50) 0 else 1; // 0=MALE, 1=FEMALE
            let domestic_type = get_domestic_type_from_wild(herd.animal_type, gender);
            
            vector::push_back(&mut domestic_types, domestic_type);
            vector::push_back(&mut genders, gender);
            i = i + 1;
        };

        altriuxanimal::create_domesticated_from_capture(domestic_types, genders, herd.tile_id, inv, clock, land_reg, ctx);
    }

    public fun hunt_wild_animal(
        hero: &Hero, 
        herd: &mut WildHerd, 
        reg: &mut PopulationRegistry,
        inv: &mut Inventory,
        is_mounted: bool,
        workers_count: u64,
        workers_mounted: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(altriuxhero::get_current_tile(hero) == herd.tile_id, E_NOT_ON_TILE);
        assert!(herd.count > 0, E_HERD_EMPTY);
        assert!(check_hunting_weapon(hero), E_NO_HUNTING_WEAPON);

        let prob = calculate_prob(herd.animal_type, is_mounted, workers_count, workers_mounted) * 2;
        let mut captures = prob / 100;
        let remaining_prob = prob % 100;
        
        let rand = kingdomutils::random(1, 100, ctx);
        if (rand <= remaining_prob) {
            captures = captures + 1;
        };

        if (captures == 0) abort E_CAPTURE_FAILED;
        if (captures > herd.count) captures = herd.count;

        herd.count = herd.count - captures;
        update_current_pop(reg, herd.animal_type, captures, false);

        let mut total_meat = 0;
        let mut i = 0;
        while (i < captures) {
            let gender_rand = kingdomutils::random(1, 100, ctx);
            let gender = if (gender_rand <= 50) 0 else 1;
            let (_, meat_yield) = get_wild_stats(herd.animal_type, gender);
            total_meat = total_meat + meat_yield;
            i = i + 1;
        };

        add_jax(inv, JAX_MEAT, total_meat, 0, clock);
    }

    fun update_current_pop(reg: &mut PopulationRegistry, t: u8, amount: u64, increase: bool) {
        if (table::contains(&reg.current_pop, t)) {
            let current = table::borrow_mut(&mut reg.current_pop, t);
            if (increase) {
                *current = *current + amount;
            } else {
                if (*current >= amount) {
                    *current = *current - amount;
                } else {
                    *current = 0;
                }
            }
        }
    }

    fun calculate_prob(animal_type: u8, hero_mounted: bool, workers: u64, workers_mounted: u64): u64 {
        let is_diff = is_difficult(animal_type);
        let base_foot = if (is_diff) 5 else 10;
        let base_mounted = if (is_diff) 25 else 50;
        let mut total_prob = if (hero_mounted) base_mounted else base_foot;
        total_prob = total_prob + (workers_mounted * base_mounted) + ((workers - workers_mounted) * base_foot);
        total_prob
    }

    fun is_difficult(t: u8): bool {
        t == URO || t == BUFALO || t == CABALLO_SALVAJE || t == CAMELLO_SALVAJE || t == YAK_SALVAJE || t == JABALI || t == LOBO || t == PERRO_SALVAJE || t == ELEFANTE_SALVAJE
    }

    fun check_hunting_weapon(hero: &Hero): bool {
        let weapons = altriuxhero::get_equipped_weapons(hero);
        let mut i = 0;
        let len = vector::length(weapons);
        while (i < len) {
            let w = vector::borrow(weapons, i);
            let t = altriuxmilitaryitems::get_weapon_type(w);
            if ((t >= 101 && t <= 108) || (t >= 301 && t <= 305)) {
                return true
            };
            i = i + 1;
        };
        false
    }

    // --- Stats & Mapping ---

    fun get_wild_stats(t: u8, _gender: u8): (u64, u64) {
        if (t == MUFLON) (60000, 25)
        else if (t == CABRA_MONTES) (85000, 35)
        else if (t == URO) (900000, 400)
        else if (t == BUFALO) (800000, 350)
        else if (t == CABALLO_SALVAJE) (350000, 160)
        else if (t == CAMELLO_SALVAJE) (600000, 280)
        else if (t == YAK_SALVAJE) (600000, 270)
        else if (t == GUANACO) (120000, 50)
        else if (t == VICUNA) (60000, 25)
        else if (t == PATO_REAL) (1400, 1)
        else if (t == GALLO_BANKIVA) (1200, 1)
        else if (t == JABALI) (100000, 45)
        else if (t == LOBO) (50000, 20)
        else if (t == CHACAL) (12000, 5)
        else if (t == GATO_MONTES) (6000, 2)
        else if (t == PERRO_SALVAJE) (25000, 10)
        else if (t == ASNO_SALVAJE) (250000, 100)
        else if (t == CONEJO_SALVAJE) (3000, 1)
        else if (t == GANSO_SALVAJE) (6000, 2)
        else if (t == CEBU_SALVAJE) (800000, 300)
        else if (t == ELEFANTE_SALVAJE) (2000000, 600)
        else (0, 0)
    }

    fun get_domestic_type_from_wild(wild_species: u8, gender: u8): u8 {
        if (wild_species == 1) { if (gender == 0) altriuxanimal::id_oveja_macho() else altriuxanimal::id_oveja_hembra() }
        else if (wild_species == 2) { if (gender == 0) altriuxanimal::id_cabra_macho() else altriuxanimal::id_cabra_hembra() }
        else if (wild_species == 3) { if (gender == 0) altriuxanimal::id_toro() else altriuxanimal::id_vaca() }
        else if (wild_species == 4) { if (gender == 0) altriuxanimal::id_bufalo_macho() else altriuxanimal::id_bufalo_hembra() }
        else if (wild_species == 5) { if (gender == 0) altriuxanimal::id_caballo() else altriuxanimal::id_yegua() }
        else if (wild_species == 6) { if (gender == 0) altriuxanimal::id_camello() else altriuxanimal::id_camella() }
        else if (wild_species == 7) { if (gender == 0) altriuxanimal::id_yak_macho() else altriuxanimal::id_yak_hembra() }
        else if (wild_species == 10) { if (gender == 0) altriuxanimal::id_pato() else altriuxanimal::id_pata() }
        else if (wild_species == 11) { if (gender == 0) altriuxanimal::id_gallo() else altriuxanimal::id_gallina() }
        else if (wild_species == 12) { if (gender == 0) altriuxanimal::id_cerdo() else altriuxanimal::id_cerda() }
        else if (wild_species == 16) { if (gender == 0) altriuxanimal::id_perro_m() else altriuxanimal::id_perro_f() }
        else if (wild_species == 17) { if (gender == 0) altriuxanimal::id_burro() else altriuxanimal::id_burra() }
        else if (wild_species == 8) { if (gender == 0) altriuxanimal::id_llama_macho() else  altriuxanimal::id_llama_hembra() }
        else if (wild_species == 9) { if (gender == 0)  altriuxanimal::id_alpaca_macho() else  altriuxanimal::id_alpaca_hembra() }
        else if (wild_species == 32) { if (gender == 0)  altriuxanimal::id_conejo() else  altriuxanimal::id_coneja() }
        else if (wild_species == 33) { if (gender == 0)  altriuxanimal::id_ganso() else  altriuxanimal::id_gansa() }
        else if (wild_species == 34) { if (gender == 0)  altriuxanimal::id_cebu_macho() else  altriuxanimal::id_cebu_hembra() }
        else if (wild_species == 35) { if (gender == 0) altriuxanimal::id_elefante() else altriuxanimal::id_elefanta() }
        else 0
    }
}
