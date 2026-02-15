module altriux::altriuxprofessions {
    use altriux::altriuxhero::{Self, Hero};
    use altriux::altriuxscience;
    use sui::table;

    // 20 oficios masculinos
    const MALE_SMITH: u8 = 1;
    const MALE_CARPENTER: u8 = 2;
    const MALE_FARMER: u8 = 3;
    const MALE_MINER: u8 = 4;
    const MALE_SOLDIER: u8 = 5;
    const MALE_MERCHANT: u8 = 6;
    const MALE_FISHERMAN: u8 = 7;
    const MALE_LUMBERJACK: u8 = 8;
    const MALE_MASON: u8 = 9;
    const MALE_TANNER: u8 = 10;
    const MALE_BAKER: u8 = 11;
    const MALE_BREWER: u8 = 12;
    const MALE_WEAVER: u8 = 13;
    const MALE_HUNTER: u8 = 14;
    const MALE_SHEPHERD: u8 = 15;
    const MALE_COOK: u8 = 16;
    const MALE_GUARD: u8 = 17;
    const MALE_ARCHITECT: u8 = 18;
    const MALE_SAILOR: u8 = 19;
    const MALE_FOREMAN: u8 = 20;

    // 20 oficios femeninos
    const FEMALE_WEAVER: u8 = 21;
    const FEMALE_COOK: u8 = 22;
    const FEMALE_MIDWIFE: u8 = 23;
    const FEMALE_HERBALIST: u8 = 24;
    const FEMALE_MILKMAID: u8 = 25;
    const FEMALE_SEAMSTRESS: u8 = 26;
    const FEMALE_BAKER: u8 = 27;
    const FEMALE_TANNER: u8 = 28;
    const FEMALE_SPINNER: u8 = 29;
    const FEMALE_DYER: u8 = 30;
    const FEMALE_INNKEEPER: u8 = 31;
    const FEMALE_TEACHER: u8 = 32;
    const FEMALE_HEALER: u8 = 33;
    const FEMALE_FARMER: u8 = 34;
    const FEMALE_SHEPHERDESS: u8 = 35;
    const FEMALE_POTTER: u8 = 36;
    const FEMALE_LAUNDRESS: u8 = 37;
    const FEMALE_BREWER: u8 = 38;
    const FEMALE_ARTISAN: u8 = 39;
    const FEMALE_MERCHANT: u8 = 40;

    const ONE_MONTH_WORK_MS: u64 = 30 * 24 * 60 * 60 * 1000 / 4; 
    const E_LOW_SCIENCE: u64 = 1;

    public fun promote(hero: &mut Hero, prof_id: u8) {
        let professions = altriuxhero::get_professions_mut(hero);
        assert!(table::contains(professions, prof_id), 102);
        
        let current_lvl = *table::borrow(professions, prof_id);
        let next_lvl = current_lvl + 1;
        
        let masteries = altriuxhero::get_masteries(hero);
        
        // Soldiers go up to Level 6
        if (prof_id == MALE_SOLDIER) {
            assert!(next_lvl <= 6, 103);
            if (next_lvl == 2) assert!(table::contains(masteries, altriuxscience::mil_2()), E_LOW_SCIENCE);
            if (next_lvl == 3) assert!(table::contains(masteries, altriuxscience::mil_3()), E_LOW_SCIENCE);
            if (next_lvl == 4) assert!(table::contains(masteries, altriuxscience::mil_4()), E_LOW_SCIENCE);
            if (next_lvl == 5) assert!(table::contains(masteries, altriuxscience::mil_5()), E_LOW_SCIENCE);
            if (next_lvl == 6) assert!(table::contains(masteries, altriuxscience::mil_6()), E_LOW_SCIENCE);
        } else {
            // Others go up to Level 4
            assert!(next_lvl <= 4, 103);
            // General mapping based on Semester hierarchy
            if (next_lvl == 2) assert!(table::contains(masteries, altriuxscience::sem_2_req(prof_id)), E_LOW_SCIENCE);
            if (next_lvl == 3) assert!(table::contains(masteries, altriuxscience::sem_3_req(prof_id)), E_LOW_SCIENCE);
            if (next_lvl == 4) assert!(table::contains(masteries, altriuxscience::sem_4_req(prof_id)), E_LOW_SCIENCE);
        };
        
        let professions_mut = altriuxhero::get_professions_mut(hero);
        let lvl_mut = table::borrow_mut(professions_mut, prof_id);
        *lvl_mut = next_lvl;
    }

    public fun get_training_cost(profession: u8): u64 {
        if (profession <= 20) { 15 } else { 12 }
    }
}