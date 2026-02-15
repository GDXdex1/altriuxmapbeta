module altriux::altriuxagbiome {

    /// Returns (bonus_bp, is_negative): Biome bonus in Basis Points (1500 = 15%)
    public fun get_biome_bonus(seed_id: u64, ag_biome: u8): (u64, bool) {
        // Biomes: Mountain(1), Plains(2), Forest(3), Jungle(4), Desert(5), Coast(6), Meadow(7), Hills(8), Tundra(9)
        
        // Cereals
        if (seed_id == 1) { // Trigo
            if (ag_biome==9) return (800, true); if (ag_biome==1) return (4000, true); if (ag_biome==8) return (2500, true); 
            if (ag_biome==7) return (0, false); if (ag_biome==2) return (1500, false); if (ag_biome==5) return (10000, true);
        };
        if (seed_id == 3) { // Maíz
            if (ag_biome==9) return (1000, true); if (ag_biome==1) return (10000, true); if (ag_biome==8) return (6000, true); 
            if (ag_biome==7) return (3000, true); if (ag_biome==2) return (500, false); if (ag_biome==5) return (8000, true);
        };
        if (seed_id == 5) { // Arroz
            if (ag_biome==9) return (1200, true); if (ag_biome==1) return (10000, true); if (ag_biome==8) return (10000, true); 
            if (ag_biome==7) return (5000, true); if (ag_biome==2) return (2000, true); if (ag_biome==5) return (10000, true);
        };
        if (seed_id == 7) { // Cebada
            if (ag_biome==9) return (700, true); if (ag_biome==1) return (1500, true); if (ag_biome==8) return (1000, true); 
            if (ag_biome==7) return (500, false); if (ag_biome==2) return (1000, false); if (ag_biome==5) return (4000, true);
        };
        if (seed_id == 9 || seed_id == 11) { // Sorgo / Mijo
            if (ag_biome==9) return (500, true); if (ag_biome==1) return (7000, true); if (ag_biome==8) return (4000, true); 
            if (ag_biome==7) return (2000, true); if (ag_biome==2) return (0, false); if (ag_biome==5) return (0, false);
        };
        if (seed_id == 13) { // Avena
            if (ag_biome==9) return (600, true); if (ag_biome==1) return (1000, true); if (ag_biome==8) return (500, true); 
            if (ag_biome==7) return (500, false); if (ag_biome==2) return (1000, false); if (ag_biome==5) return (7000, true);
        };
        if (seed_id == 15) { // Centeno
            if (ag_biome==9) return (400, true); if (ag_biome==1) return (500, false); if (ag_biome==8) return (1000, false); 
            if (ag_biome==7) return (500, false); if (ag_biome==2) return (0, false); if (ag_biome==5) return (9000, true);
        };
        
        // Tubers
        if (seed_id == 17) { // Papa
            if (ag_biome==9) return (900, true); if (ag_biome==1) return (2000, true); if (ag_biome==8) return (1000, true); 
            if (ag_biome==7) return (1000, false); if (ag_biome==2) return (500, false); if (ag_biome==5) return (10000, true);
        };
        if (seed_id == 19) { // Camote
            if (ag_biome==9) return (800, true); if (ag_biome==1) return (10000, true); if (ag_biome==8) return (6000, true); 
            if (ag_biome==7) return (3000, true); if (ag_biome==2) return (1000, true); if (ag_biome==5) return (4000, true);
        };
        if (seed_id == 21 || seed_id == 23) { // Yuca / Ñame
            if (ag_biome==9) return (700, true); if (ag_biome==1) return (10000, true); if (ag_biome==8) return (9000, true); 
            if (ag_biome==7) return (5000, true); if (ag_biome==2) return (2500, true); if (ag_biome==5) return (2500, true);
        };
        if (seed_id == 47) { // Remolacha
            if (ag_biome==9) return (1000, true); if (ag_biome==1) return (6000, true); if (ag_biome==8) return (4000, true); 
            if (ag_biome==7) return (1000, true); if (ag_biome==2) return (500, false); if (ag_biome==5) return (7000, true);
        };

        // Legumes
        if (seed_id == 25 || seed_id == 27 || seed_id == 29 || seed_id == 31 || seed_id == 33 || seed_id == 35) {
            if (ag_biome==9) return (500, false); if (ag_biome==1) return (5000, true); if (ag_biome==8) return (2000, true); 
            if (ag_biome==7) return (500, false); if (ag_biome==2) return (500, false); if (ag_biome==5) return (4000, true);
        };

        // Vegetables
        if (seed_id >= 49 && seed_id <= 63) {
            if (ag_biome==9) return (500, true); if (ag_biome==1) return (5000, true); if (ag_biome==8) return (1000, true); 
            if (ag_biome==7) return (500, false); if (ag_biome==2) return (500, false); if (ag_biome==5) return (5000, true);
        };

        // Perennials and others (Simplified default)
        if (ag_biome == 1) return (5000, true);
        if (ag_biome == 9) return (1000, true);
        if (ag_biome == 5) return (8000, true);
        
        (0, false)
    }
    public fun is_compatible(_parcel_biome: u8, _ideal_biome: u8): bool {
        // For now, allow all biomes to attempt planting, penalties handled by yield
        true 
    }
}
