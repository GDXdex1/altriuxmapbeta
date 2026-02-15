module altriux::altriuxscience {
    use sui::table::{Self, Table};

    // --- Semester 1 (Basic) ---
    const S1_GEN_1: u8 = 1;
    const S1_AGRO_1: u8 = 10;
    const S1_MATH_1: u8 = 20;
    const S1_ASTRO_1: u8 = 60;
    const S1_MAT_1: u8 = 40;
    const S1_THEO_1: u8 = 70;
    const S1_MIL_1: u8 = 90;

    // --- Semester 2 ---
    const S2_GEN_2: u8 = 2; // Pre: S1_GEN_1
    const S2_AGRO_2: u8 = 11; // Pre: S1_AGRO_1
    const S2_MATH_2: u8 = 21; // Pre: S1_MATH_1
    const S2_ASTRO_2: u8 = 61; // Pre: S1_ASTRO_1
    const S2_MAT_2: u8 = 41; // Pre: S1_MAT_1
    const S2_PHIL_2: u8 = 71; // Pre: S1_GEN_2
    const S2_MIL_2: u8 = 91; // Pre: S1_MIL_1

    // --- Semester 3 ---
    const S3_GEN_3: u8 = 3; // Pre: S2_GEN_2
    const S3_MATH_3: u8 = 22; // Pre: S2_MATH_2
    const S3_PHYS_1: u8 = 30; // Pre: S1_MATH_1
    const S3_CHEM_1: u8 = 50; // Pre: S1_MAT_1
    const S3_CONST_1: u8 = 42; // Pre: S2_MAT_2
    const S3_ASTRO_3: u8 = 62; // Pre: S2_ASTRO_2
    const S3_MIL_3: u8 = 92; // Pre: S2_MIL_2

    // --- Semester 4 ---
    const S4_GEN_4: u8 = 4; // Pre: S3_GEN_3
    const S4_PHYS_2: u8 = 31; // Pre: S3_PHYS_1 && S2_MATH_2
    const S4_CHEM_2: u8 = 51; // Pre: S3_CHEM_1
    const S4_CONST_2: u8 = 43; // Pre: S3_CONST_1
    const S4_CART_1: u8 = 63; // Pre: S2_ASTRO_2
    const S4_PHIL_APP: u8 = 72; // Pre: S2_PHIL_2
    const S4_MIL_4: u8 = 93; // Pre: S3_MIL_3

    // --- Semester 5 ---
    const S5_PHYS_3: u8 = 32; // Pre: S4_PHYS_2 && S3_MATH_3
    const S5_HYDRAUL_1: u8 = 45; // Pre: S4_PHYS_2
    const S5_METALL_1: u8 = 52; // Pre: S4_CHEM_2
    const S5_MEDICINE_1: u8 = 82; // Pre: S4_GEN_4
    const S5_CURRENCY: u8 = 83; // Pre: S2_MATH_2
    const S5_ARCH: u8 = 80; // Pre: S4_CONST_2, S5_PHYS_3, S4_GEN_4
    const S5_MIL_5: u8 = 94; // Pre: S4_MIL_4

    // --- Semester 6 ---
    const S6_CONST_3: u8 = 44; // Pre: S4_CONST_2, S5_PHYS_3, S4_GEN_4
    const S6_SHIP_ARCH: u8 = 81; // Pre: S5_ARCH
    const S6_SOILS_MECH: u8 = 85; // Pre: S5_ARCH
    const S6_MEDICINE_2: u8 = 84; // Pre: S5_MEDICINE_1
    const S6_PHIL_POL: u8 = 74; // Pre: S4_PHIL_APP
    const S6_STRATEGY: u8 = 96; // Pre: S5_MIL_5
    const S6_MIL_6: u8 = 95; // Pre: S5_MIL_5

    // --- Master Thresholds ---
    const REQ_POINTS_BASIC: u64 = 20; // S1-S2
    const REQ_POINTS_MED: u64 = 25; // S3-S4
    const REQ_POINTS_ADV: u64 = 30; // S5-S6

    public fun get_points_req(branch: u8): u64 {
        if (branch < 20) return REQ_POINTS_BASIC;
        if (branch < 80) return REQ_POINTS_MED;
        REQ_POINTS_ADV
    }

    public fun check_prerequisite(branch: u8, m: &Table<u8, bool>): bool {
        // Semester 1
        if (branch == S1_GEN_1) return true;
        if (branch == S1_AGRO_1 || branch == S1_MATH_1 || branch == S1_ASTRO_1 || 
            branch == S1_MAT_1 || branch == S1_THEO_1 || branch == S1_MIL_1) {
            return table::contains(m, S1_GEN_1)
        };

        // Semester 2
        if (branch == S2_GEN_2) return table::contains(m, S1_GEN_1);
        if (branch == S2_AGRO_2) return table::contains(m, S1_AGRO_1);
        if (branch == S2_MATH_2) return table::contains(m, S1_MATH_1);
        if (branch == S2_ASTRO_2) return table::contains(m, S1_ASTRO_1);
        if (branch == S2_MAT_2) return table::contains(m, S1_MAT_1);
        if (branch == S2_PHIL_2) return table::contains(m, S2_GEN_2) && table::contains(m, S1_THEO_1);
        if (branch == S2_MIL_2) return table::contains(m, S1_MIL_1);

        // Semester 3
        if (branch == S3_GEN_3) return table::contains(m, S2_GEN_2);
        if (branch == S3_MATH_3) return table::contains(m, S2_MATH_2);
        if (branch == S3_PHYS_1) return table::contains(m, S1_MATH_1);
        if (branch == S3_CHEM_1) return table::contains(m, S1_MAT_1);
        if (branch == S3_CONST_1) return table::contains(m, S2_MAT_2);
        if (branch == S3_ASTRO_3) return table::contains(m, S2_ASTRO_2);
        if (branch == S3_MIL_3) return table::contains(m, S2_MIL_2);

        // Semester 4
        if (branch == S4_GEN_4) return table::contains(m, S3_GEN_3);
        if (branch == S4_PHYS_2) return table::contains(m, S3_PHYS_1) && table::contains(m, S2_MATH_2);
        if (branch == S4_CHEM_2) return table::contains(m, S3_CHEM_1);
        if (branch == S4_CONST_2) return table::contains(m, S3_CONST_1);
        if (branch == S4_CART_1) return table::contains(m, S2_ASTRO_2);
        if (branch == S4_PHIL_APP) return table::contains(m, S2_PHIL_2);
        if (branch == S4_MIL_4) return table::contains(m, S3_MIL_3);

        // Semester 5
        if (branch == S5_PHYS_3) return table::contains(m, S4_PHYS_2) && table::contains(m, S3_MATH_3);
        if (branch == S5_HYDRAUL_1) return table::contains(m, S4_PHYS_2);
        if (branch == S5_METALL_1) return table::contains(m, S4_CHEM_2);
        if (branch == S5_MEDICINE_1) return table::contains(m, S4_GEN_4);
        if (branch == S5_CURRENCY) return table::contains(m, S2_MATH_2);
        if (branch == S5_ARCH) return table::contains(m, S4_CONST_2) && table::contains(m, S5_PHYS_3) && table::contains(m, S4_GEN_4);
        if (branch == S5_MIL_5) return table::contains(m, S4_MIL_4);

        // Semester 6
        if (branch == S6_CONST_3) return table::contains(m, S4_CONST_2) && table::contains(m, S5_PHYS_3) && table::contains(m, S4_GEN_4);
        if (branch == S6_SHIP_ARCH) return table::contains(m, S5_ARCH);
        if (branch == S6_SOILS_MECH) return table::contains(m, S5_ARCH);
        if (branch == S6_MEDICINE_2) return table::contains(m, S5_MEDICINE_1);
        if (branch == S6_PHIL_POL) return table::contains(m, S4_PHIL_APP);
        if (branch == S6_STRATEGY) return table::contains(m, S5_MIL_5);
        if (branch == S6_MIL_6) return table::contains(m, S5_MIL_5);

        false
    }

    public fun mil_1(): u8 { S1_MIL_1 }
    public fun mil_2(): u8 { S2_MIL_2 }
    public fun mil_3(): u8 { S3_MIL_3 }
    public fun mil_4(): u8 { S4_MIL_4 }
    public fun mil_5(): u8 { S5_MIL_5 }
    public fun mil_6(): u8 { S6_MIL_6 }

    public fun sem_2_req(prof_id: u8): u8 {
        if (prof_id == 3 || prof_id == 34 || prof_id == 11 || prof_id == 27 || prof_id == 12 || prof_id == 38 || prof_id == 15 || prof_id == 35) return S2_AGRO_2;
        if (prof_id == 1 || prof_id == 9 || prof_id == 10 || prof_id == 28 || prof_id == 13 || prof_id == 21) return S2_MAT_2;
        if (prof_id == 2 || prof_id == 18) return S2_MAT_2;
        if (prof_id == 7 || prof_id == 19) return S2_MATH_2;
        S2_GEN_2
    }

    public fun sem_3_req(prof_id: u8): u8 {
        if (prof_id == 3 || prof_id == 34 || prof_id == 11 || prof_id == 27 || prof_id == 12 || prof_id == 38 || prof_id == 15 || prof_id == 35) return S3_GEN_3;
        if (prof_id == 1 || prof_id == 9) return S3_CHEM_1;
        if (prof_id == 2 || prof_id == 18) return S3_CONST_1;
        if (prof_id == 7 || prof_id == 19) return S3_ASTRO_3;
        S3_GEN_3
    }

    public fun sem_4_req(prof_id: u8): u8 {
        if (prof_id == 1 || prof_id == 9) return S4_CHEM_2;
        if (prof_id == 2 || prof_id == 18) return S4_CONST_2;
        if (prof_id == 7 || prof_id == 19) return S4_CART_1;
        S4_GEN_4
    }

    public fun branch_gen_1(): u8 { S1_GEN_1 }
    public fun branch_gen_2(): u8 { S2_GEN_2 }
    public fun branch_construction_3(): u8 { S6_CONST_3 }
    public fun branch_architecture(): u8 { S5_ARCH }
}
