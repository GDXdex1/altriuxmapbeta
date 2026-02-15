module altriux::altriuxagstats {
    use std::option::{Self, Option};

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

    public fun get_crop_stats(seed_id: u64): Option<CropStats> {
        // IDs: Seeds are Odd (Food-1)
        // CEREALS
        if (seed_id == 1) { // Trigo (2)
            return option::some(CropStats { base_yield_jax: 35, base_seed_jax: 4, growth_days: 130, harvest_au_bp: 150, soil_delta_bp: 800, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 35, bypro_type: 215 })
        } else if (seed_id == 3) { // Maíz (4)
            return option::some(CropStats { base_yield_jax: 50, base_seed_jax: 12, growth_days: 120, harvest_au_bp: 140, soil_delta_bp: 1000, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 50, bypro_type: 215 })
        } else if (seed_id == 5) { // Arroz (6)
            return option::some(CropStats { base_yield_jax: 60, base_seed_jax: 80, growth_days: 150, harvest_au_bp: 180, soil_delta_bp: 1200, soil_delta_neg: true, is_perennial: false, needs_irrigation: true, bypro_yield_jax: 60, bypro_type: 216 })
        } else if (seed_id == 7) { // Cebada (8)
            return option::some(CropStats { base_yield_jax: 40, base_seed_jax: 4, growth_days: 110, harvest_au_bp: 130, soil_delta_bp: 700, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 40, bypro_type: 215 })
        } else if (seed_id == 9) { // Sorgo (10)
            return option::some(CropStats { base_yield_jax: 45, base_seed_jax: 5, growth_days: 90, harvest_au_bp: 110, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 45, bypro_type: 215 })
        } else if (seed_id == 11) { // Mijo (12)
            return option::some(CropStats { base_yield_jax: 30, base_seed_jax: 3, growth_days: 80, harvest_au_bp: 100, soil_delta_bp: 500, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 30, bypro_type: 216 })
        } else if (seed_id == 13) { // Avena (14)
            return option::some(CropStats { base_yield_jax: 32, base_seed_jax: 5, growth_days: 100, harvest_au_bp: 120, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 32, bypro_type: 215 })
        } else if (seed_id == 15) { // Centeno (16)
            return option::some(CropStats { base_yield_jax: 28, base_seed_jax: 3, growth_days: 120, harvest_au_bp: 140, soil_delta_bp: 400, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 28, bypro_type: 216 })
        
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

        // VEGETABLES
        } else if (seed_id == 49) { // Tomate (50)
            return option::some(CropStats { base_yield_jax: 120, base_seed_jax: 1, growth_days: 110, harvest_au_bp: 130, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 51) { // Pimiento (52)
            return option::some(CropStats { base_yield_jax: 100, base_seed_jax: 1, growth_days: 120, harvest_au_bp: 140, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 53) { // Chile (54)
            return option::some(CropStats { base_yield_jax: 90, base_seed_jax: 1, growth_days: 130, harvest_au_bp: 160, soil_delta_bp: 500, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 55) { // Cebolla (56)
            return option::some(CropStats { base_yield_jax: 180, base_seed_jax: 200, growth_days: 120, harvest_au_bp: 140, soil_delta_bp: 500, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 57) { // Ajo (58)
            return option::some(CropStats { base_yield_jax: 150, base_seed_jax: 150, growth_days: 150, harvest_au_bp: 180, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 59) { // Zanahoria (60)
            return option::some(CropStats { base_yield_jax: 160, base_seed_jax: 1, growth_days: 110, harvest_au_bp: 130, soil_delta_bp: 400, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 61) { // Repollo (62)
            return option::some(CropStats { base_yield_jax: 200, base_seed_jax: 1, growth_days: 90, harvest_au_bp: 110, soil_delta_bp: 500, soil_delta_neg: true, is_perennial: false, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
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
            return option::some(CropStats { base_yield_jax: 250, base_seed_jax: 5, growth_days: 90, harvest_au_bp: 110, soil_delta_bp: 1000, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 113) { // Raygrás (114)
            return option::some(CropStats { base_yield_jax: 280, base_seed_jax: 8, growth_days: 80, harvest_au_bp: 100, soil_delta_bp: 1200, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 115) { // Festuca (116)
            return option::some(CropStats { base_yield_jax: 240, base_seed_jax: 6, growth_days: 90, harvest_au_bp: 110, soil_delta_bp: 1000, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })
        } else if (seed_id == 117) { // Alfalfa (118)
            return option::some(CropStats { base_yield_jax: 300, base_seed_jax: 10, growth_days: 75, harvest_au_bp: 90, soil_delta_bp: 1500, soil_delta_neg: false, is_perennial: true, needs_irrigation: false, bypro_yield_jax: 0, bypro_type: 0 })

        } else {
            return option::none()
        }
    }


    // --- Accessors ---
    public fun base_yield_jax(stats: &CropStats): u64 { stats.base_yield_jax }
    public fun base_seed_jax(stats: &CropStats): u64 { stats.base_seed_jax }
    public fun harvest_au_bp(stats: &CropStats): u64 { stats.harvest_au_bp }
    public fun growth_days(stats: &CropStats): u64 { stats.growth_days }
    public fun soil_delta_bp(stats: &CropStats): u64 { stats.soil_delta_bp }
    public fun soil_delta_neg(stats: &CropStats): bool { stats.soil_delta_neg }
    public fun is_perennial(stats: &CropStats): bool { stats.is_perennial }
    public fun needs_irrigation(stats: &CropStats): bool { stats.needs_irrigation }
    public fun bypro_yield_jax(stats: &CropStats): u64 { stats.bypro_yield_jax }
    public fun bypro_type(stats: &CropStats): u64 { stats.bypro_type }
}
