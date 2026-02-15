#[allow(duplicate_alias, unused_use)]
module altriux::altriuxhero {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext, sender};
    use sui::table::{Self, Table};
    use altriux::altriuxclothing::{Self, Clothing};
    use altriux::altriuxmilitaryitems::{Self, MilitaryItem};
    use std::vector;
    use std::string::{Self};
    use sui::event;
    use altriux::altriuxutils;
    use sui::clock::Clock;
    use altriux::esc::ESC;
    use sui::coin::{Self, Coin};
    const DRANTIUM: u8 = 1;
    const BRONTIUM: u8 = 2;
    const IMLAX: u8 = 3;

    const MALE: u8 = 0;
    const FEMALE: u8 = 1;

    const E_INVALID_GENDER: u64 = 10;
    const E_INVALID_TRIBE: u64 = 11;
    const E_NOT_OWNER: u64 = 12;
    const E_NOBILITY_RESTRICTION: u64 = 13;

    public struct TravelStatus has store, copy, drop {
        origin_tile: u64,
        destination_tile: u64,
        start_time: u64,
        arrival_time: u64,
        // Target coordinates for safe completion
        dest_hq: u64,
        dest_hr: u64,
        dest_hq_neg: bool,
        dest_hr_neg: bool,
        dest_sq: u64,
        dest_sr: u64,
        dest_sq_neg: bool,
        dest_sr_neg: bool,
    }

    public struct Hero has key {
        id: UID,
        owner: address,  // Added for security
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
        travel_status: Option<TravelStatus>,
        // Detailed coordinates for precision movement
        hq: u64,
        hr: u64,
        hq_neg: bool,
        hr_neg: bool,
        sq: u64,
        sr: u64,
        sq_neg: bool,
        sr_neg: bool,
    }

    public struct HeroCreated has copy, drop { 
        id: ID, 
        owner: address, 
        tribe: u8, 
        timestamp: u64 
    }

    public fun create_hero(
        name: vector<u8>, 
        gender: u8, 
        tribe: u8, 
        religion: u8, 
        payment: Coin<ESC>,
        clock: &Clock, 
        ctx: &mut TxContext
    ): Hero {
        assert!(coin::value(&payment) >= 10, 100); // Costo base: 10 ESC
        transfer::public_transfer(payment, @0x0);

        assert!(gender == MALE || gender == FEMALE, E_INVALID_GENDER);
        assert!(tribe == DRANTIUM || tribe == BRONTIUM || tribe == IMLAX, E_INVALID_TRIBE);
        
        let mut stats = table::new<u8, u64>(ctx);
        table::add(&mut stats, 1, 10); 
        let hero = Hero {
            id: object::new(ctx),
            owner: sender(ctx),
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
            travel_status: option::none(),
            hq: 0,
            hr: 0,
            hq_neg: false,
            hr_neg: false,
            sq: 0,
            sr: 0,
            sq_neg: false,
            sr_neg: false,
        };
        event::emit(HeroCreated { 
            id: object::id(&hero), 
            owner: sender(ctx), 
            tribe, 
            timestamp: altriuxutils::get_game_time(clock) 
        });
        hero
    }

    public fun add_profession(hero: &mut Hero, prof_id: u8, ctx: &mut TxContext) {
        assert!(sender(ctx) == hero.owner, E_NOT_OWNER);
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

    public fun set_study_lock(hero: &mut Hero, lock_until: u64, ctx: &mut TxContext) {
        assert!(sender(ctx) == hero.owner, E_NOT_OWNER);
        hero.study_lock_until = lock_until;
    }

    public fun is_locked(hero: &Hero, now: u64): bool {
        now < hero.study_lock_until
    }

    public fun get_current_tile(hero: &Hero): u64 {
        hero.current_tile
    }

    public fun get_owner(hero: &Hero): address {
        hero.owner
    }

    public fun update_hero_position(hero: &mut Hero, new_tile: u64, ctx: &mut TxContext) {
        assert!(sender(ctx) == hero.owner, E_NOT_OWNER);
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

    public fun get_travel_status(hero: &Hero): &Option<TravelStatus> {
        &hero.travel_status
    }

    public fun start_hero_travel(hero: &mut Hero, status: TravelStatus, ctx: &mut TxContext) {
        assert!(sender(ctx) == hero.owner, E_NOT_OWNER);
        hero.travel_status = option::some(status);
    }

    public fun clear_travel_status(hero: &mut Hero, ctx: &mut TxContext) {
        assert!(sender(ctx) == hero.owner, E_NOT_OWNER);
        hero.travel_status = option::none();
    }

    public fun new_travel_status(
        origin: u64, dest: u64, start: u64, arrival: u64,
        t_hq: u64, t_hr: u64, t_hq_neg: bool, t_hr_neg: bool,
        t_sq: u64, t_sr: u64, t_sq_neg: bool, t_sr_neg: bool
    ): TravelStatus {
        TravelStatus { 
            origin_tile: origin, destination_tile: dest, start_time: start, arrival_time: arrival,
            dest_hq: t_hq, dest_hr: t_hr, dest_hq_neg: t_hq_neg, dest_hr_neg: t_hr_neg,
            dest_sq: t_sq, dest_sr: t_sr, dest_sq_neg: t_sq_neg, dest_sr_neg: t_sr_neg
        }
    }

    public fun get_travel_details(status: &TravelStatus): (u64, u64, u64, u64) {
        (status.origin_tile, status.destination_tile, status.start_time, status.arrival_time)
    }

    public fun get_travel_dest_coords(status: &TravelStatus): (u64, u64, bool, bool, u64, u64, bool, bool) {
        (status.dest_hq, status.dest_hr, status.dest_hq_neg, status.dest_hr_neg, status.dest_sq, status.dest_sr, status.dest_sq_neg, status.dest_sr_neg)
    }

    public fun get_hero_coords(hero: &Hero): (u64, u64, bool, bool, u64, u64, bool, bool) {
        (hero.hq, hero.hr, hero.hq_neg, hero.hr_neg, hero.sq, hero.sr, hero.sq_neg, hero.sr_neg)
    }

    public fun update_hero_coords(
        hero: &mut Hero, 
        hq: u64, hr: u64, hq_neg: bool, hr_neg: bool,
        sq: u64, sr: u64, sq_neg: bool, sr_neg: bool,
        ctx: &mut TxContext
    ) {
        assert!(sender(ctx) == hero.owner, E_NOT_OWNER);
        hero.hq = hq;
        hero.hr = hr;
        hero.hq_neg = hq_neg;
        hero.hr_neg = hr_neg;
        hero.sq = sq;
        hero.sr = sr;
        hero.sq_neg = sq_neg;
        hero.sr_neg = sr_neg;
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

    public fun mount_animal(hero: &mut Hero, _animal_id: ID, ctx: &mut TxContext) {
        assert!(sender(ctx) == hero.owner, E_NOT_OWNER);
        // TODO: Mount logic
    }

    public fun travel(hero: &mut Hero, target_tile: u64, ctx: &mut TxContext) {
        assert!(sender(ctx) == hero.owner, E_NOT_OWNER);
        hero.current_tile = target_tile;
    }

    public fun sow_field(
        hero: &mut Hero, 
        _land_reg: &altriux::altriuxland::LandRegistry, 
        _land_id: ID, 
        nobility_titles: &vector<ID>,
        ctx: &mut TxContext
    ) {
        assert!(sender(ctx) == hero.owner, E_NOT_OWNER);
        assert!(can_perform_manual_labor(object::id(hero), nobility_titles), E_NOBILITY_RESTRICTION);
        // TODO: sow logic
    }

    public fun trade(hero: &mut Hero, _target: address, ctx: &mut TxContext) {
        assert!(sender(ctx) == hero.owner, E_NOT_OWNER);
        // TODO: Trade logic
    }

    #[test_only]
    public fun destroy_hero_for_testing(hero: Hero) {
        let Hero {
            id,
            owner: _,
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
