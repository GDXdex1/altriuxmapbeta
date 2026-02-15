module altriux::altriuxitems {
    
    // --- Tools & Items IDs (300+) ---
    const ARADO: u64 = 301;
    const HACHA: u64 = 302;
    const HOZ: u64 = 303;
    const PICO: u64 = 304;
    const PALA: u64 = 305;
    const RASTRILLO: u64 = 306;
    const CUCHILLO: u64 = 307;
    const TOBO: u64 = 308;
    const SERRUCHO: u64 = 309;
    const MARTILLO: u64 = 310;
    const CINCEL: u64 = 311;
    const TENAZAS: u64 = 312;
    const YUNQUE: u64 = 313;
    const LIMA: u64 = 314;
    const ESCOFINA: u64 = 315;
    const AZADA: u64 = 316;
    const HORCA: u64 = 317;
    const GUADANA: u64 = 318;
    const MAZO: u64 = 319;
    const BARRENA: u64 = 320;
    const LEZNA: u64 = 321;
    const AGUJA: u64 = 322;
    const GARLOPA: u64 = 323;
    const COMPAS: u64 = 324;
    const ESCUADRA: u64 = 325;
    const PLOMADA: u64 = 326;
    const NIVEL: u64 = 327;
    const ALAMBIQUE: u64 = 328;
    const MORTERO: u64 = 329;
    const PRENSA: u64 = 330;

    // --- Monturas & Equipamiento Animal (331-335) ---
    const MONTURA_CABALLO: u64 = 331;
    const HERRADURAS_X4: u64 = 332;
    const ARNES_CARGA: u64 = 333;
    const BRIDA_CUERO: u64 = 334;
    const ALBARD_BUEY: u64 = 335;

    // --- Transporte Terrestre (336-342) ---
    const CARRETILLO_P: u64 = 336;
    const CARRETILLO_G: u64 = 337;
    const CARRETILLO_LUX: u64 = 338;
    const CARRETA_1C: u64 = 339;
    const CARRETA_2C: u64 = 340;
    const CARRETA_4B: u64 = 341;
    const TRINEO: u64 = 342;

    // --- Navegación & Observación (343-347) ---
    const ASTROLABIO: u64 = 343;
    const BRUJULA: u64 = 344;
    const TELESCOPIO: u64 = 345;
    const CARTA_NAUT: u64 = 346;
    const BITACORA: u64 = 347;

    // --- Estructuras & Señalización (348-349) ---
    const CAMPANA_P: u64 = 348;
    const CAMPANA_G: u64 = 349;

    // --- Iluminación (350-352) ---
    const FAROL: u64 = 350;
    const LINTERNA: u64 = 351;
    const ANTORCHA: u64 = 352;

    // --- Fuego (353-357) ---
    const PEDERNAL: u64 = 353;
    const VELA_X10: u64 = 354;
    const LAMPARA: u64 = 355;
    const MECHERO: u64 = 356;
    const HOGUERA_PORT: u64 = 357;

    // --- Almacenamiento & Logística (358-362) ---
    const SACO_ESTO: u64 = 358;
    const BARRIL_20L: u64 = 359;
    const COFRE_MAD: u64 = 360;
    const COFRE_HIERRO: u64 = 361;
    const MOCHILA: u64 = 362;

    /// Returns (weight_grams, volume_ml) for a given item ID.
    /// 1 Jax = 20,000g, 1 Jix = 20,000ml.
    public fun get_item_metrics(type_id: u64): (u64, u64) {
        if (type_id == ARADO) return (60000, 40000);        // 3 Jax, 2 Jix (Large iron/wood)
        if (type_id == HACHA) return (2000, 500);           // 0.1 Jax, 0.025 Jix
        if (type_id == HOZ) return (500, 200);              // Small
        if (type_id == PICO) return (4000, 1000);           // 0.2 Jax
        if (type_id == PALA) return (2500, 1500);
        if (type_id == RASTRILLO) return (1500, 3000);      // High volume, low weight
        if (type_id == CUCHILLO) return (200, 50);
        if (type_id == TOBO) return (1000, 20000);          // 20L volume (1 Jix)
        if (type_id == SERRUCHO) return (800, 600);
        if (type_id == MARTILLO) return (1200, 300);
        if (type_id == CINCEL) return (300, 100);
        if (type_id == TENAZAS) return (1000, 400);
        if (type_id == YUNQUE) return (100000, 13000);      // 5 Jax, very dense (100kg/13L)
        if (type_id == LIMA) return (200, 50);
        if (type_id == ESCOFINA) return (200, 50);
        if (type_id == AZADA) return (1800, 1000);
        if (type_id == HORCA) return (1500, 2500);
        if (type_id == GUADANA) return (2500, 2000);
        if (type_id == MAZO) return (3000, 1500);
        if (type_id == BARRENA) return (500, 200);
        if (type_id == LEZNA) return (100, 20);
        if (type_id == AGUJA) return (5, 1);
        if (type_id == GARLOPA) return (2000, 1500);
        if (type_id == COMPAS) return (300, 150);
        if (type_id == ESCUADRA) return (400, 300);
        if (type_id == PLOMADA) return (500, 100);
        if (type_id == NIVEL) return (600, 1000);
        if (type_id == ALAMBIQUE) return (15000, 40000);    // 2 Jix
        if (type_id == MORTERO) return (5000, 2000);
        if (type_id == PRENSA) return (50000, 60000);      // 3 Jix

        // New Items
        if (type_id == MONTURA_CABALLO) return (3500, 4500);
        if (type_id == HERRADURAS_X4) return (1200, 300);
        if (type_id == ARNES_CARGA) return (2800, 3200);
        if (type_id == BRIDA_CUERO) return (450, 350);
        if (type_id == ALBARD_BUEY) return (4200, 5000);
        if (type_id == CARRETILLO_P) return (8500, 15000);
        if (type_id == CARRETILLO_G) return (18000, 35000);
        if (type_id == CARRETILLO_LUX) return (12000, 25000);
        if (type_id == CARRETA_1C) return (35000, 65000);
        if (type_id == CARRETA_2C) return (42000, 75000);
        if (type_id == CARRETA_4B) return (55000, 95000);
        if (type_id == TRINEO) return (22000, 40000);
        if (type_id == ASTROLABIO) return (1500, 900);
        if (type_id == BRUJULA) return (300, 250);
        if (type_id == TELESCOPIO) return (950, 1200);
        if (type_id == CARTA_NAUT) return (120, 80);
        if (type_id == BITACORA) return (450, 600);
        if (type_id == CAMPANA_P) return (15000, 8000);
        if (type_id == CAMPANA_G) return (85000, 40000);
        if (type_id == FAROL) return (850, 1100);
        if (type_id == LINTERNA) return (350, 400);
        if (type_id == ANTORCHA) return (400, 300);
        if (type_id == PEDERNAL) return (180, 120);
        if (type_id == VELA_X10) return (350, 400);
        if (type_id == LAMPARA) return (450, 600);
        if (type_id == MECHERO) return (120, 90);
        if (type_id == HOGUERA_PORT) return (2200, 3000);
        if (type_id == SACO_ESTO) return (250, 1800);
        if (type_id == BARRIL_20L) return (4500, 22000);
        if (type_id == COFRE_MAD) return (3800, 28000);
        if (type_id == COFRE_HIERRO) return (12000, 32000);
        if (type_id == MOCHILA) return (650, 12000);

        (0, 0)
    }

    // --- Getters ---
    public fun arado(): u64 { ARADO }
    public fun hacha(): u64 { HACHA }
    public fun hoz(): u64 { HOZ }
    public fun pico(): u64 { PICO }
    public fun pala(): u64 { PALA }
    public fun rastrillo(): u64 { RASTRILLO }
    public fun cuchillo(): u64 { CUCHILLO }
    public fun tobo(): u64 { TOBO }
    public fun serrucho(): u64 { SERRUCHO }
    public fun martillo(): u64 { MARTILLO }
    public fun cincel(): u64 { CINCEL }
    public fun tenazas(): u64 { TENAZAS }
    public fun yunque(): u64 { YUNQUE }
    public fun lima(): u64 { LIMA }
    public fun escofina(): u64 { ESCOFINA }
    public fun azada(): u64 { AZADA }
    public fun horca(): u64 { HORCA }
    public fun guadana(): u64 { GUADANA }
    public fun mazo(): u64 { MAZO }
    public fun barrena(): u64 { BARRENA }
    public fun lezna(): u64 { LEZNA }
    public fun aguja(): u64 { AGUJA }
    public fun garlopa(): u64 { GARLOPA }
    public fun compas(): u64 { COMPAS }
    public fun escuadra(): u64 { ESCUADRA }
    public fun plomada(): u64 { PLOMADA }
    public fun nivel(): u64 { NIVEL }
    public fun alambique(): u64 { ALAMBIQUE }
    public fun mortero(): u64 { MORTERO }
    public fun prensa(): u64 { PRENSA }

    public fun montura_caballo(): u64 { MONTURA_CABALLO }
    public fun herraduras_x4(): u64 { HERRADURAS_X4 }
    public fun arnes_carga(): u64 { ARNES_CARGA }
    public fun brida_cuero(): u64 { BRIDA_CUERO }
    public fun albard_buey(): u64 { ALBARD_BUEY }
    public fun carretillo_p(): u64 { CARRETILLO_P }
    public fun carretillo_g(): u64 { CARRETILLO_G }
    public fun carretillo_lux(): u64 { CARRETILLO_LUX }
    public fun carreta_1c(): u64 { CARRETA_1C }
    public fun carreta_2c(): u64 { CARRETA_2C }
    public fun carreta_4b(): u64 { CARRETA_4B }
    public fun trineo(): u64 { TRINEO }
    public fun astrolabio(): u64 { ASTROLABIO }
    public fun brujula(): u64 { BRUJULA }
    public fun telescopio(): u64 { TELESCOPIO }
    public fun carta_naut(): u64 { CARTA_NAUT }
    public fun bitacora(): u64 { BITACORA }
    public fun campana_p(): u64 { CAMPANA_P }
    public fun campana_g(): u64 { CAMPANA_G }
    public fun farol(): u64 { FAROL }
    public fun linterna(): u64 { LINTERNA }
    public fun antorcha(): u64 { ANTORCHA }
    public fun pedernal(): u64 { PEDERNAL }
    public fun vela_x10(): u64 { VELA_X10 }
    public fun lampara(): u64 { LAMPARA }
    public fun mechero(): u64 { MECHERO }
    public fun hoguera_port(): u64 { HOGUERA_PORT }
    public fun saco_esto(): u64 { SACO_ESTO }
    public fun barril_20l(): u64 { BARRIL_20L }
    public fun cofre_mad(): u64 { COFRE_MAD }
    public fun cofre_hierro(): u64 { COFRE_HIERRO }
    public fun mochila(): u64 { MOCHILA }
}
