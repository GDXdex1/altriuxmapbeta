module altriux::altriuxagstats {
    use std::option::{Self, Option};

    public struct CropStats has copy, drop {
        base_yield_bp: u64,      // 1 jak = 100 bp. 
        seed_cost_bp: u64,       
        growth_days: u64,
        soil_delta_bp: u64,      
        soil_delta_neg: bool,   
        is_perennial: bool,
        needs_irrigation: bool,
    }

    public fun get_crop_stats(seed_id: u64): Option<CropStats> {
        // Cereals
        if (seed_id == 1) { // Trigo (Montaña, 15 jax -> 1500 bp)
            return option::some(CropStats { base_yield_bp: 1500, seed_cost_bp: 300, growth_days: 180, soil_delta_bp: 800, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 3) { // Maíz (Selva, 20 jax -> 2000 bp)
            return option::some(CropStats { base_yield_bp: 2000, seed_cost_bp: 400, growth_days: 120, soil_delta_bp: 1000, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 5) { // Arroz (Llanura, 25 jax -> 2500 bp)
            return option::some(CropStats { base_yield_bp: 2500, seed_cost_bp: 500, growth_days: 150, soil_delta_bp: 1200, soil_delta_neg: true, is_perennial: false, needs_irrigation: true })
        } else if (seed_id == 7) { // Cebada (Montaña, 18 jax -> 1800 bp)
            return option::some(CropStats { base_yield_bp: 1800, seed_cost_bp: 360, growth_days: 140, soil_delta_bp: 700, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 9) { // Sorgo (Llanura, 15 jax -> 1500 bp)
            return option::some(CropStats { base_yield_bp: 1500, seed_cost_bp: 300, growth_days: 110, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 11) { // Mijo (Llanura, 12 jax -> 1200 bp)
            return option::some(CropStats { base_yield_bp: 1200, seed_cost_bp: 240, growth_days: 90, soil_delta_bp: 500, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 13) { // Avena (Montaña, 15 jax -> 1500 bp)
            return option::some(CropStats { base_yield_bp: 1500, seed_cost_bp: 300, growth_days: 130, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 15) { // Centeno (Tundra, 10 jax -> 1000 bp)
            return option::some(CropStats { base_yield_bp: 1000, seed_cost_bp: 200, growth_days: 160, soil_delta_bp: 400, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        
        // Tubers
        } else if (seed_id == 17) { // Papa (Selva, 150 jax -> 15000 bp)
            return option::some(CropStats { base_yield_bp: 15000, seed_cost_bp: 1500, growth_days: 100, soil_delta_bp: 900, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 19) { // Camote (Selva, 150 jax -> 15000 bp)
            return option::some(CropStats { base_yield_bp: 15000, seed_cost_bp: 1500, growth_days: 120, soil_delta_bp: 800, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 21) { // Yuca (Selva, 200 jax -> 20000 bp)
            return option::some(CropStats { base_yield_bp: 20000, seed_cost_bp: 2000, growth_days: 270, soil_delta_bp: 700, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 23) { // Ñame (Selva, 150 jax -> 15000 bp)
            return option::some(CropStats { base_yield_bp: 15000, seed_cost_bp: 1500, growth_days: 240, soil_delta_bp: 800, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        
        // Legumes
        } else if (seed_id == 25) { // Soya (Llanura, 10 jax -> 1000 bp)
            return option::some(CropStats { base_yield_bp: 1000, seed_cost_bp: 200, growth_days: 120, soil_delta_bp: 600, soil_delta_neg: false, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 27) { // Maní (Selva, 10 jax -> 1000 bp)
            return option::some(CropStats { base_yield_bp: 1000, seed_cost_bp: 200, growth_days: 130, soil_delta_bp: 500, soil_delta_neg: false, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 29) { // Frijol (Selva, 8 jax -> 800 bp)
            return option::some(CropStats { base_yield_bp: 800, seed_cost_bp: 160, growth_days: 90, soil_delta_bp: 700, soil_delta_neg: false, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 31) { // Garbanzo (Llanura, 8 jax -> 800 bp)
            return option::some(CropStats { base_yield_bp: 800, seed_cost_bp: 160, growth_days: 110, soil_delta_bp: 600, soil_delta_neg: false, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 33) { // Lenteja (Llanura, 8 jax -> 800 bp)
            return option::some(CropStats { base_yield_bp: 800, seed_cost_bp: 160, growth_days: 100, soil_delta_bp: 800, soil_delta_neg: false, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 35) { // Guisante (Llanura, 10 jax -> 1000 bp)
            return option::some(CropStats { base_yield_bp: 1000, seed_cost_bp: 200, growth_days: 110, soil_delta_bp: 700, soil_delta_neg: false, is_perennial: false, needs_irrigation: false })
        
        // Oilseeds / Textiles / Industrial
        } else if (seed_id == 37) { // Girasol (Selva, 12 jax -> 1200 bp)
            return option::some(CropStats { base_yield_bp: 1200, seed_cost_bp: 240, growth_days: 110, soil_delta_bp: 700, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 39) { // Sésamo (Llanura, 10 jax -> 1000 bp)
            return option::some(CropStats { base_yield_bp: 1000, seed_cost_bp: 200, growth_days: 90, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 41) { // Lino (Montaña, 15 jax -> 1500 bp)
            return option::some(CropStats { base_yield_bp: 1500, seed_cost_bp: 300, growth_days: 120, soil_delta_bp: 500, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 43) { // Cáñamo (Llanura, 15 jax -> 1500 bp)
            return option::some(CropStats { base_yield_bp: 1500, seed_cost_bp: 300, growth_days: 130, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 45) { // Caña Azúcar (Selva, 500 jax -> 50000 bp)
            return option::some(CropStats { base_yield_bp: 50000, seed_cost_bp: 5000, growth_days: 360, soil_delta_bp: 1500, soil_delta_neg: true, is_perennial: false, needs_irrigation: true })
        } else if (seed_id == 47) { // Remolacha (Montaña, 150 jax -> 15000 bp)
            return option::some(CropStats { base_yield_bp: 15000, seed_cost_bp: 1500, growth_days: 150, soil_delta_bp: 1000, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 105) { // Algodón (Llanura, 20 jax -> 2000 bp)
            return option::some(CropStats { base_yield_bp: 2000, seed_cost_bp: 400, growth_days: 180, soil_delta_bp: 900, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        
        // Vegetables
        } else if (seed_id == 49) { // Tomate (Selva, 200 jax -> 20000 bp)
            return option::some(CropStats { base_yield_bp: 20000, seed_cost_bp: 2000, growth_days: 90, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 51) { // Pimiento (Selva, 150 jax -> 15000 bp)
            return option::some(CropStats { base_yield_bp: 15000, seed_cost_bp: 1500, growth_days: 100, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 53) { // Ají (Selva, 150 jax -> 15000 bp)
            return option::some(CropStats { base_yield_bp: 15000, seed_cost_bp: 1500, growth_days: 110, soil_delta_bp: 500, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 55) { // Cebolla (Bosque, 200 jax -> 20000 bp)
            return option::some(CropStats { base_yield_bp: 20000, seed_cost_bp: 2000, growth_days: 120, soil_delta_bp: 500, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 57) { // Ajo (Bosque, 150 jax -> 15000 bp)
            return option::some(CropStats { base_yield_bp: 15000, seed_cost_bp: 1500, growth_days: 180, soil_delta_bp: 600, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 59) { // Zanahoria (Bosque, 200 jax -> 20000 bp)
            return option::some(CropStats { base_yield_bp: 20000, seed_cost_bp: 2000, growth_days: 110, soil_delta_bp: 400, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 61) { // Repollo (Bosque, 250 jax -> 25000 bp)
            return option::some(CropStats { base_yield_bp: 25000, seed_cost_bp: 2500, growth_days: 100, soil_delta_bp: 500, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 63) { // Calabaza (Selva, 200 jax -> 20000 bp)
            return option::some(CropStats { base_yield_bp: 20000, seed_cost_bp: 2000, growth_days: 110, soil_delta_bp: 400, soil_delta_neg: true, is_perennial: false, needs_irrigation: false })
        
        // Fruits (Perennials)
        } else if (seed_id == 65) { // Manzana (Bosque, 100 jax -> 10000 bp)
             return option::some(CropStats { base_yield_bp: 10000, seed_cost_bp: 1000, growth_days: 1460, soil_delta_bp: 300, soil_delta_neg: false, is_perennial: true, needs_irrigation: false }) 
        } else if (seed_id == 67) { // Pera (Bosque, 100 jax -> 10000 bp)
             return option::some(CropStats { base_yield_bp: 10000, seed_cost_bp: 1000, growth_days: 1460, soil_delta_bp: 300, soil_delta_neg: false, is_perennial: true, needs_irrigation: false }) 
        } else if (seed_id == 69) { // Durazno (Bosque, 75 jax -> 7500 bp)
             return option::some(CropStats { base_yield_bp: 7500, seed_cost_bp: 750, growth_days: 1095, soil_delta_bp: 200, soil_delta_neg: false, is_perennial: true, needs_irrigation: false }) 
        } else if (seed_id == 71) { // Banana (Selva, 150 jax -> 15000 bp)
             return option::some(CropStats { base_yield_bp: 15000, seed_cost_bp: 1500, growth_days: 365, soil_delta_bp: 400, soil_delta_neg: false, is_perennial: true, needs_irrigation: false }) 
        } else if (seed_id == 73) { // Plátano (Selva, 150 jax -> 15000 bp)
             return option::some(CropStats { base_yield_bp: 15000, seed_cost_bp: 1500, growth_days: 365, soil_delta_bp: 500, soil_delta_neg: false, is_perennial: true, needs_irrigation: false }) 
        } else if (seed_id == 75) { // Naranja (Selva, 100 jax -> 10000 bp)
             return option::some(CropStats { base_yield_bp: 10000, seed_cost_bp: 1000, growth_days: 1825, soil_delta_bp: 300, soil_delta_neg: false, is_perennial: true, needs_irrigation: false }) 
        } else if (seed_id == 77) { // Mango (Selva, 100 jax -> 10000 bp)
             return option::some(CropStats { base_yield_bp: 10000, seed_cost_bp: 1000, growth_days: 1825, soil_delta_bp: 400, soil_delta_neg: false, is_perennial: true, needs_irrigation: false }) 
        } else if (seed_id == 79) { // Papaya (Selva, 150 jax -> 15000 bp)
             return option::some(CropStats { base_yield_bp: 15000, seed_cost_bp: 1500, growth_days: 547, soil_delta_bp: 300, soil_delta_neg: false, is_perennial: true, needs_irrigation: false }) 
        } else if (seed_id == 81) { // Piña (Selva, 100 jax -> 10000 bp)
             return option::some(CropStats { base_yield_bp: 10000, seed_cost_bp: 1000, growth_days: 547, soil_delta_bp: 200, soil_delta_neg: false, is_perennial: true, needs_irrigation: false }) 
        } else if (seed_id == 83) { // Aguacate (Selva, 75 jax -> 7500 bp)
             return option::some(CropStats { base_yield_bp: 7500, seed_cost_bp: 750, growth_days: 1825, soil_delta_bp: 300, soil_delta_neg: false, is_perennial: true, needs_irrigation: false }) 
        } else if (seed_id == 85) { // Coco (Selva, 50 jax -> 5000 bp)
             return option::some(CropStats { base_yield_bp: 5000, seed_cost_bp: 500, growth_days: 2190, soil_delta_bp: 200, soil_delta_neg: false, is_perennial: true, needs_irrigation: false }) 
        } else if (seed_id == 87) { // Aceituna (Bosque, 100 jax -> 10000 bp)
             return option::some(CropStats { base_yield_bp: 10000, seed_cost_bp: 1000, growth_days: 2555, soil_delta_bp: 400, soil_delta_neg: false, is_perennial: true, needs_irrigation: false }) 
        } else if (seed_id == 89) { // Dátil (Llanura, 75 jax -> 7500 bp)
             return option::some(CropStats { base_yield_bp: 7500, seed_cost_bp: 750, growth_days: 2190, soil_delta_bp: 300, soil_delta_neg: false, is_perennial: true, needs_irrigation: false }) 
        } else if (seed_id == 91) { // Uva (Bosque, 100 jax -> 10000 bp)
             return option::some(CropStats { base_yield_bp: 10000, seed_cost_bp: 1000, growth_days: 1095, soil_delta_bp: 500, soil_delta_neg: false, is_perennial: true, needs_irrigation: false }) 
        } else if (seed_id == 93) { // Fresa (Bosque, 75 jax -> 7500 bp)
             return option::some(CropStats { base_yield_bp: 7500, seed_cost_bp: 750, growth_days: 180, soil_delta_bp: 600, soil_delta_neg: false, is_perennial: false, needs_irrigation: false }) 
        
        // Nuts / Spices
        } else if (seed_id == 99) { // Almendra (Bosque, 25 jax -> 2500 bp)
             return option::some(CropStats { base_yield_bp: 2500, seed_cost_bp: 250, growth_days: 1825, soil_delta_bp: 400, soil_delta_neg: false, is_perennial: true, needs_irrigation: false }) 
        } else if (seed_id == 101) { // Nuez (Bosque, 25 jax -> 2500 bp)
             return option::some(CropStats { base_yield_bp: 2500, seed_cost_bp: 250, growth_days: 1460, soil_delta_bp: 300, soil_delta_neg: false, is_perennial: true, needs_irrigation: false }) 
        } else if (seed_id == 103) { // Cacao (Selva, 15 jax -> 1500 bp)
             return option::some(CropStats { base_yield_bp: 1500, seed_cost_bp: 150, growth_days: 1095, soil_delta_bp: 500, soil_delta_neg: false, is_perennial: true, needs_irrigation: false }) 
        } else if (seed_id == 109) { // Café (Selva, 15 jax -> 1500 bp)
             return option::some(CropStats { base_yield_bp: 1500, seed_cost_bp: 150, growth_days: 80, soil_delta_bp: 800, soil_delta_neg: false, is_perennial: false, needs_irrigation: false }) 
        } else if (seed_id == 111) { // Vainilla (Selva, 5 jax -> 500 bp)
             return option::some(CropStats { base_yield_bp: 500, seed_cost_bp: 50, growth_days: 85, soil_delta_bp: 700, soil_delta_neg: false, is_perennial: false, needs_irrigation: false }) 
        
        // Forage
        } else if (seed_id == 107) { // Trébol (Montaña, 100 jax -> 10000 bp)
             return option::some(CropStats { base_yield_bp: 10000, seed_cost_bp: 1000, growth_days: 90, soil_delta_bp: 1000, soil_delta_neg: false, is_perennial: false, needs_irrigation: false }) 
        } else if (seed_id == 113) { // Ryegrass (Llanura, 150 jax -> 15000 bp)
             return option::some(CropStats { base_yield_bp: 15000, seed_cost_bp: 1500, growth_days: 80, soil_delta_bp: 1200, soil_delta_neg: false, is_perennial: false, needs_irrigation: false }) 
        } else if (seed_id == 115) { // Fescue (Montaña, 100 jax -> 10000 bp) -- (User: Fescue, Seed guessed as 115)
             return option::some(CropStats { base_yield_bp: 10000, seed_cost_bp: 1000, growth_days: 90, soil_delta_bp: 1000, soil_delta_neg: false, is_perennial: false, needs_irrigation: false })
        } else if (seed_id == 117) { // Alfalfa (Selva, 200 jax -> 20000 bp) -- (User: Alfalfa, Seed guessed as 117)
             return option::some(CropStats { base_yield_bp: 20000, seed_cost_bp: 2000, growth_days: 90, soil_delta_bp: 1500, soil_delta_neg: false, is_perennial: false, needs_irrigation: false })
        } else {
            return option::none()
        }
    }

    public fun is_biome_allowed(seed_id: u64, ag_biome: u8): bool {
        // Biomes: Mountain(1), Plains(2), Forest(3), Jungle(4), Desert(5), Coast(6), Meadow(7), Hills(8), Tundra(9)
        if (ag_biome == 0) return false;
        
        // Cereals
        if (seed_id == 1) return (ag_biome == 1 || ag_biome == 8); // Trigo - Montaña (User) + Hills (Logic)
        if (seed_id == 3) return (ag_biome == 4); // Maíz - Selva
        if (seed_id == 5) return (ag_biome == 2); // Arroz - Llanura
        if (seed_id == 7) return (ag_biome == 1); // Cebada - Montaña
        if (seed_id == 9) return (ag_biome == 2); // Sorgo - Llanura
        if (seed_id == 11) return (ag_biome == 2); // Mijo - Llanura
        if (seed_id == 13) return (ag_biome == 1); // Avena - Montaña
        if (seed_id == 15) return (ag_biome == 9); // Centeno - Tundra
        
        // Tubers
        if (seed_id == 17) return (ag_biome == 4); // Papa - Selva
        if (seed_id == 19) return (ag_biome == 4); // Camote - Selva
        if (seed_id == 21) return (ag_biome == 4); // Yuca - Selva
        if (seed_id == 23) return (ag_biome == 4); // Ñame - Selva
        if (seed_id == 47) return (ag_biome == 1); // Remolacha - Montaña
        
        // Legumes
        if (seed_id == 25) return (ag_biome == 2); // Soya - Llanura
        if (seed_id == 27) return (ag_biome == 4); // Maní - Selva
        if (seed_id == 29) return (ag_biome == 4); // Frijol - Selva
        if (seed_id == 31) return (ag_biome == 2); // Garbanzo - Llanura
        if (seed_id == 33) return (ag_biome == 2); // Lenteja - Llanura
        if (seed_id == 35) return (ag_biome == 2); // Guisante - Llanura
        
        // Oilseeds/Fiber
        if (seed_id == 37) return (ag_biome == 4); // Girasol - Selva
        if (seed_id == 39) return (ag_biome == 2); // Sésamo - Llanura
        if (seed_id == 41) return (ag_biome == 1); // Lino - Montaña
        if (seed_id == 43) return (ag_biome == 2); // Cáñamo - Llanura
        if (seed_id == 45) return (ag_biome == 4); // Caña - Selva
        if (seed_id == 105) return (ag_biome == 2); // Algodón - Llanura
        
        // Veggies
        if (seed_id == 49) return (ag_biome == 4); // Tomate - Selva
        if (seed_id == 51) return (ag_biome == 4); // Pimiento - Selva
        if (seed_id == 53) return (ag_biome == 4); // Chile - Selva
        if (seed_id == 55) return (ag_biome == 3); // Cebolla - Bosque
        if (seed_id == 57) return (ag_biome == 3); // Ajo - Bosque
        if (seed_id == 59) return (ag_biome == 3); // Zanahoria - Bosque
        if (seed_id == 61) return (ag_biome == 3); // Repollo - Bosque
        if (seed_id == 63) return (ag_biome == 4); // Calabaza - Selva
        
        // Fruits
        if (seed_id == 65) return (ag_biome == 3); // Manzana - Bosque
        if (seed_id == 67) return (ag_biome == 3); // Pera - Bosque
        if (seed_id == 69) return (ag_biome == 3); // Durazno - Bosque
        if (seed_id == 71) return (ag_biome == 4); // Banana - Selva
        if (seed_id == 73) return (ag_biome == 4); // Plátano - Selva
        if (seed_id == 75) return (ag_biome == 4); // Naranja - Selva
        if (seed_id == 77) return (ag_biome == 4); // Mango - Selva
        if (seed_id == 79) return (ag_biome == 4); // Papaya - Selva
        if (seed_id == 81) return (ag_biome == 4); // Piña - Selva
        if (seed_id == 83) return (ag_biome == 4); // Aguacate - Selva
        if (seed_id == 85) return (ag_biome == 4); // Coco - Selva
        if (seed_id == 87) return (ag_biome == 3); // Aceituna - Bosque
        if (seed_id == 89) return (ag_biome == 2); // Dátil - Llanura
        if (seed_id == 91) return (ag_biome == 3); // Uva - Bosque
        if (seed_id == 93) return (ag_biome == 3); // Fresa - Bosque
        
        // Nuts
        if (seed_id == 99) return (ag_biome == 3); // Almendra - Bosque
        if (seed_id == 101) return (ag_biome == 3); // Nuez - Bosque
        if (seed_id == 103) return (ag_biome == 4); // Cacao - Selva
        if (seed_id == 109) return (ag_biome == 4); // Café - Selva
        if (seed_id == 111) return (ag_biome == 4); // Vainilla - Selva
        
        // Forage
        if (seed_id == 107) return (ag_biome == 1); // Trébol - Montaña
        if (seed_id == 113) return (ag_biome == 2); // Ryegrass - Llanura
        if (seed_id == 115) return (ag_biome == 1); // Fescue - Montaña
        if (seed_id == 117) return (ag_biome == 4); // Alfalfa - Selva

        true
    }

    // --- Accessors ---
    public fun base_yield_bp(stats: &CropStats): u64 { stats.base_yield_bp }
    public fun seed_cost_bp(stats: &CropStats): u64 { stats.seed_cost_bp }
    public fun growth_days(stats: &CropStats): u64 { stats.growth_days }
    public fun soil_delta_bp(stats: &CropStats): u64 { stats.soil_delta_bp }
    public fun soil_delta_neg(stats: &CropStats): bool { stats.soil_delta_neg }
    public fun is_perennial(stats: &CropStats): bool { stats.is_perennial }
    public fun needs_irrigation(stats: &CropStats): bool { stats.needs_irrigation }
}
