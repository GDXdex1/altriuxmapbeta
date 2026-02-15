module altriux::altriuxagbiome {

    /// Returns (multiplier_bp, is_impossible)
    /// Multiplier: 10000 = 1.0x (Optimal), 5000 = 0.5x (Marginal)
    public fun get_agriculture_biome_rules(seed_id: u64, ag_biome: u8, has_oasis: bool): (u64, bool) {
        // Biomes: Mountain(1), Plains(2), Forest(3), Jungle(4), Desert(5), Coast(6), Meadow(7), Hills(8), Tundra(9)
        
        // CEREALS
        if (seed_id == 1) { // Trigo
            if (ag_biome==2 || ag_biome==6 || ag_biome==3 || ag_biome==8) return (10000, false); // Optimal
            if (ag_biome==1) return (5000, false); // Marginal
            return (0, true) // Impossible
        } else if (seed_id == 3) { // Maíz
            if (ag_biome==4 || ag_biome==2) return (10000, false);
            if (ag_biome==3) return (5000, false);
            return (0, true)
        } else if (seed_id == 5) { // Arroz
            if (ag_biome==2 || has_oasis) return (10000, false);
            if (ag_biome==7) return (5000, false);
            return (0, true)
        } else if (seed_id == 7) { // Cebada
            if (ag_biome==2 || ag_biome==7 || ag_biome==8) return (10000, false);
            if (ag_biome==1 || ag_biome==9) return (5000, false);
            return (0, true)
        } else if (seed_id == 9) { // Sorgo
            if (ag_biome==2 || ag_biome==5) return (10000, false);
            if (ag_biome==3) return (5000, false);
            return (0, true)
        } else if (seed_id == 11) { // Mijo
            if (ag_biome==2 || ag_biome==5) return (10000, false);
            if (ag_biome==7) return (5000, false);
            return (0, true)
        } else if (seed_id == 13) { // Avena
            if (ag_biome==7 || ag_biome==2) return (10000, false);
            if (ag_biome==8 || ag_biome==9) return (5000, false);
            return (0, true)
        } else if (seed_id == 15) { // Centeno
            if (ag_biome==8 || ag_biome==1) return (10000, false);
            if (ag_biome==9) return (5000, false);
            return (0, true)

        // TUBERS
        } else if (seed_id == 17) { // Papa
            if (ag_biome==1 || ag_biome==7) return (10000, false);
            if (ag_biome==3 || ag_biome==9) return (5000, false);
            return (0, true)
        } else if (seed_id == 19) { // Camote
            if (ag_biome==4 || ag_biome==2) return (10000, false);
            if (ag_biome==3) return (5000, false);
            return (0, true)
        } else if (seed_id == 21) { // Yuca
            if (ag_biome==4 || ag_biome==2) return (10000, false);
            if (ag_biome==3) return (5000, false);
            return (0, true)
        } else if (seed_id == 23) { // Ñame
            if (ag_biome==4) return (10000, false);
            if (ag_biome==3) return (5000, false);
            return (0, true)
        } else if (seed_id == 47) { // Remolacha
            if (ag_biome==7 || ag_biome==2) return (10000, false);
            if (ag_biome==1) return (5000, false);
            return (0, true)

        // LEGUMES
        } else if (seed_id == 25) { // Soya
            if (ag_biome==7 || ag_biome==2) return (10000, false);
            if (ag_biome==4) return (5000, false);
            return (0, true)
        } else if (seed_id == 27) { // Maní
            if (ag_biome==4 || ag_biome==2) return (10000, false);
            if (ag_biome==3) return (5000, false);
            return (0, true)
        } else if (seed_id == 29) { // Frijol
            if (ag_biome==4 || ag_biome==2) return (10000, false);
            if (ag_biome==3) return (5000, false);
            return (0, true)
        } else if (seed_id == 31) { // Garbanzo
            if (ag_biome==2 || ag_biome==5) return (10000, false);
            if (ag_biome==3) return (5000, false);
            return (0, true)
        } else if (seed_id == 33) { // Lenteja
            if (ag_biome==2 || ag_biome==8) return (10000, false);
            if (ag_biome==1) return (5000, false);
            return (0, true)
        } else if (seed_id == 35) { // Guisante
            if (ag_biome==7 || ag_biome==2) return (10000, false);
            if (ag_biome==8 || ag_biome==9) return (5000, false);
            return (0, true)

        // OILSEEDS/TEXTILES
        } else if (seed_id == 37) { // Girasol
            if (ag_biome==7 || ag_biome==2) return (10000, false);
            if (ag_biome==3) return (5000, false);
            return (0, true)
        } else if (seed_id == 39) { // Sésamo
            if (ag_biome==2 || ag_biome==5) return (10000, false);
            if (ag_biome==3) return (5000, false);
            return (0, true)
        } else if (seed_id == 41) { // Lino Textil
            if (ag_biome==7 || ag_biome==6) return (10000, false);
            if (ag_biome==2) return (5000, false);
            return (0, true)
        } else if (seed_id == 43) { // Cáñamo
            if (ag_biome==7 || ag_biome==2) return (10000, false);
            if (ag_biome==8) return (5000, false);
            return (0, true)
        } else if (seed_id == 45) { // Caña
            if (ag_biome==4 || has_oasis) return (10000, false);
            if (ag_biome==7) return (5000, false);
            return (0, true)
        } else if (seed_id == 105) { // Algodón
            if (ag_biome==2 || ag_biome==5) return (10000, false);
            if (ag_biome==4) return (5000, false);
            return (0, true)
        } else if (seed_id == 119) { // Lino Aceite
            if (ag_biome==7 || ag_biome==2) return (10000, false);
            if (ag_biome==3) return (5000, false);
            return (0, true)

        // HORTALIZAS
        } else if (seed_id == 49 || seed_id == 51 || seed_id == 53 || seed_id == 64) { // Tomate, Pimiento, Chile, Calabaza
            if (ag_biome==4 || ag_biome==2) return (10000, false);
            if (ag_biome==3) return (5000, false);
            return (0, true)
        } else if (seed_id == 55 || seed_id == 60 || seed_id == 62) { // Cebolla, Zanahoria, Repollo
            if (ag_biome==7 || ag_biome==2) return (10000, false);
            if (ag_biome==8 || ag_biome==9) return (5000, false);
            return (0, true)
        } else if (seed_id == 58) { // Ajo
            if (ag_biome==7 || ag_biome==2) return (10000, false);
            if (ag_biome==8) return (5000, false);
            return (0, true)

        // FRUTALES
        } else if (seed_id == 65 || seed_id == 67) { // Manzana, Pera
            if (ag_biome==3 || ag_biome==7) return (10000, false);
            if (ag_biome==8) return (5000, false);
            return (0, true)
        } else if (seed_id == 69) { // Durazno
            if (ag_biome==3 || ag_biome==2) return (10000, false);
            if (ag_biome==7) return (5000, false);
            return (0, true)
        } else if (seed_id == 71 || seed_id == 73) { // Banana, Plátano
            if (ag_biome==4) return (10000, false);
            return (0, true)
        } else if (seed_id == 75 || seed_id == 84) { // Naranja, Aguacate
            if (ag_biome==4 || has_oasis) return (10000, false);
            if (ag_biome==2) return (5000, false);
            return (0, true)
        } else if (seed_id == 77 || seed_id == 80 || seed_id == 82) { // Mango, Papaya, Piña
            if (ag_biome==4) return (10000, false);
            if (ag_biome==3 || ag_biome==2) return (5000, false);
            return (0, true)
        } else if (seed_id == 86) { // Coco
            if (ag_biome==6) return (10000, false);
            if (ag_biome==4) return (5000, false);
            return (0, true)
        } else if (seed_id == 88 || seed_id == 100) { // Oliva, Almendra
            if (ag_biome==3 || ag_biome==2) return (10000, false);
            if (ag_biome==5) return (5000, false);
            return (0, true)
        } else if (seed_id == 90) { // Dátil
            if (has_oasis) return (10000, false);
            if (ag_biome==2) return (5000, false);
            return (0, true)
        } else if (seed_id == 92 || seed_id == 94 || seed_id == 102) { // Uva, Fresa, Nuez
            if (ag_biome==3 || ag_biome==2) return (10000, false);
            if (ag_biome==8 || ag_biome==6 || ag_biome==9) return (5000, false);
            return (0, true)

        // LUXURY / FORAGE
        } else if (seed_id == 104 || seed_id == 112) { // Cacao, Vainilla
            if (ag_biome==4) return (10000, false);
            if (seed_id == 104 && ag_biome == 3) return (5000, false);
            return (0, true)
        } else if (seed_id == 110) { // Café
            if (ag_biome==4) return (10000, false); // User: "Jungle montañosa", let's use Jungle for now
            if (ag_biome==3) return (5000, false);
            return (0, true)
        } else if (seed_id >= 107 && seed_id <= 118) { // Forajes
            if (ag_biome==7 || ag_biome==2) return (10000, false);
            if (ag_biome==8 || has_oasis || ag_biome==9) return (5000, false);
            return (0, true)
        } else {
            return (10000, false) // Default allow for unknown seeds
        }
    }

    public fun get_biome_bonus(_seed_id: u64, _ag_biome: u8): (u64, bool) {
        // Legacy function, keeping signature but returning 0
        (0, false)
    }
    public fun is_compatible(_parcel_biome: u8, _ideal_biome: u8): bool {
        // For now, allow all biomes to attempt planting, penalties handled by yield
        true 
    }
}
