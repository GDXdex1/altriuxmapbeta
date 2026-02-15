module altriux::altriuxhero {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::table::{Self, Table};
    use altriux::altriuxclothing::{Self, Clothing};
    use altriux::altriuxmilitaryitems::{Self, MilitaryItem};
    use std::vector;
    const DRANTIUM: u8 = 1;
    const BRONTIUM: u8 = 2;
    const IMLAX: u8 = 3;

    const MALE: u8 = 0;
    const FEMALE: u8 = 1;

    const E_INVALID_GENDER: u64 = 10;
    const E_INVALID_TRIBE: u64 = 11;

    public struct Hero has key {
        id: UID,
        name: vector<u8>,
        gender: u8,        // 0: Male, 1: Female (Immutable)
        tribe: u8,         // 1: Drantium, 2: Brontium, 3: Imlax (Immutable)
        level: u64,
        experience: u64,
        stats: Table<u8, u64>, 
        equipped_clothing: vector<Clothing>,
        equipped_weapon: vector<MilitaryItem>,
        
        // --- New Systems ---
        science_points: Table<u8, u64>,    // branch_id -> points
        mastered_science: Table<u8, bool>, // branch_id -> true
        professions: Table<u8, u8>,        // profession_id -> level (1-4, soldier 1-6)
        work_time_ms: Table<u8, u64>,      // profession_id -> total worked
        study_lock_until: u64,             // timestamp
        current_tile: u64,                 // unique tile id
        religion: u8,                      // 0: Secular/None, 1+: Aligned
    }

    public fun create_hero(name: vector<u8>, gender: u8, tribe: u8, religion: u8, ctx: &mut TxContext): Hero {
        assert!(gender == MALE || gender == FEMALE, E_INVALID_GENDER);
        assert!(tribe == DRANTIUM || tribe == BRONTIUM || tribe == IMLAX, E_INVALID_TRIBE);
        
        let mut stats = table::new<u8, u64>(ctx);
        table::add(&mut stats, 1, 10); 
        Hero {
            id: object::new(ctx),
            name,
            gender,
            tribe,
            level: 1,
            experience: 0,
            stats,
            equipped_clothing: vector::empty(),
            equipped_weapon: vector::empty(),
            science_points: table::new(ctx),
            mastered_science: table::new(ctx),
            professions: table::new(ctx),
            work_time_ms: table::new(ctx),
            study_lock_until: 0,
            current_tile: 0, 
            religion,
        }
    }

    public fun add_profession(hero: &mut Hero, prof_id: u8) {
        assert!(table::length(&hero.professions) < 4, 101); // Limit of 4
        if (!table::contains(&hero.professions, prof_id)) {
            table::add(&mut hero.professions, prof_id, 1);
            table::add(&mut hero.work_time_ms, prof_id, 0);
        }
    }

    public fun get_masteries(hero: &Hero): &Table<u8, bool> {
        &hero.mastered_science
    }
    
    public fun get_science_points_mut(hero: &mut Hero): &mut Table<u8, u64> {
        &mut hero.science_points
    }

    public fun get_masteries_mut(hero: &mut Hero): &mut Table<u8, bool> {
        &mut hero.mastered_science
    }

    public fun get_professions_mut(hero: &mut Hero): &mut Table<u8, u8> {
        &mut hero.professions
    }

    public fun set_study_lock(hero: &mut Hero, lock_until: u64) {
        hero.study_lock_until = lock_until;
    }

    public fun is_locked(hero: &Hero, now: u64): bool {
        now < hero.study_lock_until
    }

    public fun get_current_tile(hero: &Hero): u64 {
        hero.current_tile
    }

    public fun update_hero_position(hero: &mut Hero, new_tile: u64) {
        hero.current_tile = new_tile;
    }

    public fun get_equipped_weapons(hero: &Hero): &vector<MilitaryItem> {
        &hero.equipped_weapon
    }

    public fun get_religion(hero: &Hero): u8 {
        hero.religion
    }

    public fun get_gender(hero: &Hero): u8 {
        hero.gender
    }

    public fun get_tribe(hero: &Hero): u8 {
        hero.tribe
    }

    public fun drantium(): u8 { DRANTIUM }
    public fun brontium(): u8 { BRONTIUM }
    public fun imlax(): u8 { IMLAX }
    public fun male(): u8 { MALE }
    public fun female(): u8 { FEMALE }

    // === NOBILITY LABOR RESTRICTIONS ===
    
    /// Check if hero can perform manual labor (farming, mining, logging)
    /// Heroes WITH nobility titles (Knight+) CANNOT perform manual labor
    /// Only commoners can work the land
    public fun can_perform_manual_labor(hero_id: ID, nobility_titles: &vector<ID>): bool {
        // Check if hero has any nobility title
        let mut i = 0;
        let len = vector::length(nobility_titles);
        while (i < len) {
            let title_hero_id = *vector::borrow(nobility_titles, i);
            if (title_hero_id == hero_id) {
                return false  // Has nobility title, CANNOT work
            };
            i = i + 1;
        };
        true  // No nobility title, CAN work
    }
    
    /// Check if hero can supervise workers (nobles can command)
    public fun can_supervise_workers(hero_id: ID, nobility_titles: &vector<ID>): bool {
        !can_perform_manual_labor(hero_id, nobility_titles)
    }

    // === HERO ACTIONS (Centralized) ===

    public fun mount_animal(_hero: &mut Hero, _animal_id: ID, _ctx: &mut TxContext) {
        // TODO: Mount logic
    }

    public fun travel(hero: &mut Hero, target_tile: u64, _ctx: &mut TxContext) {
        hero.current_tile = target_tile;
    }

    public fun sow_field(_hero: &mut Hero, _land_reg: &altriux::altriuxland::LandRegistry, _land_id: ID, _ctx: &mut TxContext) {
        // TODO: Nobility check + sow logic
    }

    public fun trade(_hero: &mut Hero, _target: address, _ctx: &mut TxContext) {
        // TODO: Trade logic
    }

    #[test_only]
    public fun destroy_hero_for_testing(hero: Hero) {
        let Hero {
            id,
            name: _,
            gender: _,
            tribe: _,
            level: _,
            experience: _,
            stats,
            equipped_clothing,
            equipped_weapon,
            science_points,
            mastered_science,
            professions,
            work_time_ms,
            study_lock_until: _,
            current_tile: _,
            religion: _,
        } = hero;
        
        // Tables must be empty
        if (sui::table::contains(&stats, 1)) {
            sui::table::remove(&mut stats, 1);
        };
        sui::table::destroy_empty(stats);
        
        if (sui::table::contains(&science_points, 2)) {
            sui::table::remove(&mut science_points, 2);
        };
        sui::table::destroy_empty(science_points);
        
        if (sui::table::contains(&mastered_science, 2)) {
            sui::table::remove(&mut mastered_science, 2);
        };
        sui::table::destroy_empty(mastered_science);
        
        sui::table::destroy_empty(professions);
        sui::table::destroy_empty(work_time_ms);

        while (!vector::is_empty(&equipped_clothing)) {
            altriuxclothing::destroy_clothing_for_testing(vector::pop_back(&mut equipped_clothing));
        };
        vector::destroy_empty(equipped_clothing);

        while (!vector::is_empty(&equipped_weapon)) {
            altriuxmilitaryitems::destroy_weapon_for_testing(vector::pop_back(&mut equipped_weapon));
        };
        vector::destroy_empty(equipped_weapon);
        
        sui::object::delete(id);
    }
}
