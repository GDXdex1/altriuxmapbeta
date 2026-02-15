module altriux::altriuxpopulation {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};
    use std::vector;
    use altriux::altriuxlocation::{Self, LocationRegistry, encode_coordinates, decode_coordinates, get_terrain_type, terrain_plains, terrain_meadow, terrain_hills, terrain_coast, get_continent, continent_drantium, continent_brontium, get_hemisphere, hemisphere_northern, hemisphere_southern};
    use altriux::kingdomutils;
    use sui::event;

    // === WALLETS PROVISIONALES PARA CIUDADES LIBRES ===
    // NOTA: Reemplazar con wallets reales antes de producción
    // Drantium (20 ciudades): @0x554a2392980b0c3e4111c9a0e8897e632d41847d04cbd41f9e081e49ba2eb04a
    // Brontium (20 ciudades): @0x9e7aaf5f56ae094eadf9ca7f2856f533bcbf12fcc9bb9578e43ca770599a5dce
    // Noix (10 ciudades): @0x3a5e8d8c7b6f4a2e1d9c0b8a7f6e5d4c3b2a1908
    // Soix (10 ciudades): @0x7b6f4a2e1d9c0b8a7f6e5d4c3b2a19083a5e8d8c

    const WALLET_DRANTIUM: address = @0x554a2392980b0c3e4111c9a0e8897e632d41847d04cbd41f9e081e49ba2eb04a;
    const WALLET_BRONTIUM: address = @0x9e7aaf5f56ae094eadf9ca7f2856f533bcbf12fcc9bb9578e43ca770599a5dce;
    const WALLET_NOIX: address = @0x3a5e8d8c7b6f4a2e1d9c0b8a7f6e5d4c3b2a1908;
    const WALLET_SOIX: address = @0x7b6f4a2e1d9c0b8a7f6e5d4c3b2a19083a5e8d8c;

    // === TIPOS DE ASENTAMIENTO ===
    const TYPE_CITY_STATE: u8 = 1;  // Ciudad-estado (independiente, 1M+ habitantes)
    const TYPE_CITY: u8 = 2;        // Ciudad (provincial, 100k habitantes)
    const TYPE_TOWN: u8 = 3;        // Villa (comarcal, 10k habitantes)
    const TYPE_VILLAGE: u8 = 4;     // Aldea (rural, 500 habitantes)

    // === POBLACIÓN INICIAL POR TIPO ===
    const POP_CITY_STATE: u64 = 1000000;
    const POP_CITY: u64 = 100000;
    const POP_TOWN: u64 = 10000;
    const POP_VILLAGE: u64 = 500;

    // === FACTORES DE CRECIMIENTO POR BIOMA ===
    const GROWTH_RATE_PLAINS: u64 = 45;    // 0.45% diario (tierras fértiles)
    const GROWTH_RATE_MEADOW: u64 = 42;    // 0.42% diario
    const GROWTH_RATE_HILLS: u64 = 38;     // 0.38% diario (terreno menos fértil)
    const GROWTH_RATE_COAST: u64 = 40;     // 0.40% diario (pesca + comercio)
    const GROWTH_RATE_DESERT: u64 = 25;    // 0.25% diario (escasez de agua)
    const GROWTH_RATE_TUNDRA: u64 = 30;    // 0.30% diario (clima frío)
    const GROWTH_RATE_MOUNTAIN: u64 = 32;  // 0.32% diario (terreno difícil)

    // === ERRORES ===
    const E_LIMIT_REACHED: u64 = 101;      // Límite de asentamientos en hexágono
    const E_INSUFFICIENT_POP: u64 = 102;   // Población insuficiente para fundar
    const E_INVALID_LOCATION: u64 = 103;   // Coordenadas fuera de rango
    const E_NOT_OWNER: u64 = 104;          // Sin control de la ciudad
    const E_CITY_NOT_FOUND: u64 = 105;     // Ciudad no existe
    const E_NO_BATTLE_WIN: u64 = 106;      // No hay victoria reciente para reclamar
    const E_GROWTH_TOO_SOON: u64 = 107;    // Crecimiento aplicado recientemente

    // === STRUCTS ===
    public struct PopulationRegistry has key {
        id: UID,
        // Población global (para estadísticas)
        global_male: u64,
        global_female: u64,
        // Población por hexágono (coordenada codificada → población)
        hex_male: Table<u64, u64>,      // q,r codificado → hombres
        hex_female: Table<u64, u64>,    // q,r codificado → mujeres
        // Ciudades-estado libres (60 iniciales)
        free_cities: Table<ID, FreeCity>,
        // Último timestamp de crecimiento global
        last_global_growth: u64,
    }

    public struct FreeCity has key, store {
        id: UID,
        name: vector<u8>,               // Nombre de la ciudad
        owner: address,                 // Wallet controladora actual
        city_type: u8,                  // TYPE_CITY_STATE
        population_male: u64,           // Población masculina
        population_female: u64,         // Población femenina
        growth_rate_bp: u64,            // Tasa de crecimiento (2000 = 20% anual)
        last_growth_timestamp: u64,     // Último crecimiento aplicado
        location_key: u64,              // Coordenada codificada (q,r)
        continent: u8,                  // CONTINENT_DRANTIUM/BRONTIUM/NOIX/SOIX
        soldier_count: u64,             // Soldados estacionados (desde altriuxarmy)
        ruler: Option<address>,         // Gobernante actual (quien tiene más soldados)
        last_battle_win: u64,           // Timestamp de última victoria en batalla
        battle_winner: address,         // Ganador de la última batalla (para reclamo)
    }

    // === EVENTS ===
    public struct CityFounded has copy, drop {
        city_id: ID,
        name: vector<u8>,
        owner: address,
        population: u64,
        location_key: u64,
        continent: u8,
        timestamp: u64,
    }

    public struct CityClaimed has copy, drop {
        city_id: ID,
        old_owner: address,
        new_owner: address,
        timestamp: u64,
    }

    public struct PopulationGrowth has copy, drop {
        location_key: u64,
        male_growth: u64,
        female_growth: u64,
        timestamp: u64,
    }

    public struct PopulationDeducted has copy, drop {
        location_key: u64,
        male_deducted: u64,
        female_deducted: u64,
        reason: vector<u8>,
        timestamp: u64,
    }

    // === INICIALIZACIÓN DEL REGISTRO ===
    public fun init_population_registry(ctx: &mut TxContext) {
        let mut registry = PopulationRegistry {
            id: object::new(ctx),
            global_male: 0,
            global_female: 0,
            hex_male: table::new(ctx),
            hex_female: table::new(ctx),
            free_cities: table::new(ctx),
            last_global_growth: 0,
        };
        
        // Crear 60 ciudades-estado libres iniciales
        create_initial_free_cities(&mut registry, ctx);
        
        transfer::share_object(registry);
    }

    // === CREACIÓN DE 60 CIUDADES LIBRES INICIALES ===
    fun create_initial_free_cities(reg: &mut PopulationRegistry, ctx: &mut TxContext) {
        // Drantium: 20 ciudades en llanuras/colinas del oeste (original q ∈ [-150, -50], r ∈ [-50, 50])
        create_city_batch(reg, 20, WALLET_DRANTIUM, continent_drantium(), 60, 160, 60, 160, ctx);
        
        // Brontium: 20 ciudades en llanuras/colinas del este (original q ∈ [50, 150], r ∈ [-50, 50])
        create_city_batch(reg, 20, WALLET_BRONTIUM, continent_brontium(), 260, 360, 60, 160, ctx);
        
        // Noix: 10 ciudades en tundra del norte (original q ∈ [-100, 100], r ∈ [70, 100])
        create_city_batch(reg, 10, WALLET_NOIX, 3, 110, 310, 180, 210, ctx); // Continente 3 = Noix (tundra)
        
        // Soix: 10 ciudades en tundra del sur (original q ∈ [-100, 100], r ∈ [-100, -70])
        create_city_batch(reg, 10, WALLET_SOIX, 4, 110, 310, 10, 40, ctx); // Continente 4 = Soix (tundra sur)
    }

    fun create_city_batch(
        reg: &mut PopulationRegistry,
        count: u64,
        owner: address,
        continent: u8,
        q_min: u64,
        q_max: u64,
        r_min: u64,
        r_max: u64,
        ctx: &mut TxContext
    ) {
        let mut created = 0;
        let mut q = q_min;
        while (q <= q_max && created < count) {
            let mut r = r_min;
            while (r <= r_max && created < count) {
                // Verificar que es un bioma adecuado para ciudad (llanuras, colinas, costa)
                // En producción real: consultar LocationRegistry para validar terreno
                // Aquí: asumimos coordenadas válidas para demostración
                
                let location_key = encode_coordinates(q, r);
                let city_name = generate_city_name(continent, created);
                
                let city = FreeCity {
                    id: object::new(ctx),
                    name: city_name,
                    owner,
                    city_type: TYPE_CITY_STATE,
                    population_male: POP_CITY_STATE * 51 / 100,    // 51% hombres
                    population_female: POP_CITY_STATE * 49 / 100,  // 49% mujeres
                    growth_rate_bp: 2000,                           // 20% anual
                    last_growth_timestamp: 0,
                    location_key,
                    continent,
                    soldier_count: 0,
                    ruler: option::none(),
                    last_battle_win: 0,
                    battle_winner: @0x0,
                };
                
                let city_id = object::id(&city);
                table::add(&mut reg.free_cities, city_id, city);
                
                // Registrar población inicial en el hexágono
                register_population_at_hex(reg, location_key, POP_CITY_STATE * 51 / 100, POP_CITY_STATE * 49 / 100);
                
                created = created + 1;
                r = r + 10; // Espaciado entre ciudades
            };
            q = q + 10;
        };
    }

    fun generate_city_name(continent: u8, index: u64): vector<u8> {
        let base = if (continent == continent_drantium()) {
            b"Drax"
        } else if (continent == continent_brontium()) {
            b"Bron"
        } else if (continent == 3) { // Noix
            b"Noix"
        } else {
            b"Soix"
        };
        
        let mut name = base;
        let suffix = if (index == 0) b"ia"
                 else if (index == 1) b"um"
                 else if (index == 2) b"polis"
                 else if (index == 3) b"ton"
                 else if (index == 4) b"burg"
                 else if (index == 5) b"ville"
                 else if (index == 6) b"grad"
                 else if (index == 7) b"heim"
                 else if (index == 8) b"ford"
                 else b"mouth";
        
        vector::append(&mut name, suffix);
        name
    }

    // === FUNDACIÓN DE NUEVO ASENTAMIENTO ===
    public fun found_settlement(
        reg: &mut PopulationRegistry,
        loc_reg: &LocationRegistry,
        settlement_type: u8,
        q: u64,
        r: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let location_key = encode_coordinates(q, r);
        
        // Validar coordenadas (offset encoding: q ∈ [0, 419], r ∈ [0, 219])
        assert!(q < 420, E_INVALID_LOCATION);
        assert!(r < 220, E_INVALID_LOCATION);
        
        // Obtener información del asentamiento
        let (target_pop, _) = get_settlement_info(settlement_type);
        
        // Validar población suficiente en el hexágono (30% para fundación)
        let required_pop = target_pop * 30 / 100;
        assert!(get_population_at_hex(reg, location_key) >= required_pop, E_INSUFFICIENT_POP);
        
        // Validar bioma adecuado para el tipo de asentamiento
        let terrain = get_terrain_type(loc_reg, q, r);
        assert!(is_suitable_terrain(terrain, settlement_type), E_INVALID_LOCATION);
        
        // Deducir población del hexágono
        deduct_population_at_hex(reg, location_key, required_pop, b"settlement_founding");
        
        // Crear asentamiento (en producción real: objeto Settlement)
        // Aquí: solo registramos la fundación para demostración
        event::emit(CityFounded {
            city_id: object::id_from_address(@0x0), // Placeholder
            name: b"New Settlement",
            owner: sender,
            population: required_pop,
            location_key,
            continent: get_continent(q),
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // === RECLAMAR CIUDAD TRAS VICTORIA EN BATALLA ===
    public fun claim_city_after_battle(
        reg: &mut PopulationRegistry,
        city_id: ID,
        battle_winner: address,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(table::contains(&reg.free_cities, city_id), E_CITY_NOT_FOUND);
        let city = table::borrow_mut(&mut reg.free_cities, city_id);
        
        // Validar que hay una victoria reciente (últimas 24 horas blockchain)
        let now = kingdomutils::get_game_time(clock);
        assert!(city.last_battle_win > 0, E_NO_BATTLE_WIN);
        assert!(now <= city.last_battle_win + (24 * 60 * 60 * 1000), E_NO_BATTLE_WIN);
        assert!(city.battle_winner == battle_winner, E_NO_BATTLE_WIN);
        
        // Transferir propiedad
        let old_owner = city.owner;
        city.owner = battle_winner;
        city.last_battle_win = 0;
        city.battle_winner = @0x0;
        
        event::emit(CityClaimed {
            city_id,
            old_owner,
            new_owner: battle_winner,
            timestamp: now,
        });
    }

    // === REGISTRAR VICTORIA EN BATALLA (Para futura reclamación) ===
    public fun register_battle_victory(
        reg: &mut PopulationRegistry,
        city_id: ID,
        winner: address,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(table::contains(&reg.free_cities, city_id), E_CITY_NOT_FOUND);
        let city = table::borrow_mut(&mut reg.free_cities, city_id);
        
        // Solo el dueño actual puede registrar una batalla (defensa)
        // O cualquier jugador si la ciudad está sin dueño (@0x0)
        assert!(city.owner == tx_context::sender(ctx) || city.owner == @0x0, E_NOT_OWNER);
        
        city.last_battle_win = kingdomutils::get_game_time(clock);
        city.battle_winner = winner;
    }

    // === CRECIMIENTO POBLACIONAL DIARIO ===
    public fun apply_daily_growth(
        reg: &mut PopulationRegistry,
        loc_reg: &LocationRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let now = kingdomutils::get_game_time(clock);
        
        // Crecimiento global (cada 24 horas)
        if (now >= reg.last_global_growth + (24 * 60 * 60 * 1000)) {
            // Crecimiento global fijo (0.4% diario)
            let growth_rate = 40; // 0.4%
            reg.global_male = reg.global_male * (10000 + growth_rate) / 10000;
            reg.global_female = reg.global_female * (10000 + growth_rate) / 10000;
            reg.last_global_growth = now;
        };
        
        // Crecimiento local por hexágono (basado en bioma y recursos)
        // En producción real: iterar sobre hexágonos con población
        // Aquí: ejemplo para un hexágono específico
        let example_q = 0;
        let example_r = 0;
        let location_key = encode_coordinates(example_q, example_r);
        
        if (table::contains(&reg.hex_male, location_key) || table::contains(&reg.hex_female, location_key)) {
            let terrain = get_terrain_type(loc_reg, example_q, example_r);
            let growth_rate = get_growth_rate_by_terrain(terrain);
            
            let current_male = if (table::contains(&reg.hex_male, location_key)) { *table::borrow(&reg.hex_male, location_key) } else { 0 };
            let current_female = if (table::contains(&reg.hex_female, location_key)) { *table::borrow(&reg.hex_female, location_key) } else { 0 };
            
            let male_growth = (current_male * growth_rate) / 10000;
            let female_growth = (current_female * growth_rate) / 10000;
            
            if (male_growth > 0 || female_growth > 0) {
                register_population_at_hex(reg, location_key, male_growth, female_growth);
                
                event::emit(PopulationGrowth {
                    location_key,
                    male_growth,
                    female_growth,
                    timestamp: now,
                });
            };
        };
    }

    // === DEDUCCIÓN DE POBLACIÓN (Para reclutamiento, construcción, etc.) ===
    public fun deduct_civilian(
        reg: &mut PopulationRegistry,
        q: u64,
        r: u64,
        amount: u64,
        reason: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let location_key = encode_coordinates(q, r);
        let current_male = if (table::contains(&reg.hex_male, location_key)) { *table::borrow(&reg.hex_male, location_key) } else { 0 };
        let current_female = if (table::contains(&reg.hex_female, location_key)) { *table::borrow(&reg.hex_female, location_key) } else { 0 };
        let total = current_male + current_female;
        
        assert!(total >= amount, E_INSUFFICIENT_POP);
        
        // Distribuir deducción proporcionalmente (51% hombres, 49% mujeres)
        let mut male_deduct = amount * 51 / 100;
        let mut female_deduct = amount - male_deduct;
        
        // Ajustar si no hay suficientes hombres/mujeres
        if (current_male < male_deduct) {
            female_deduct = female_deduct + (male_deduct - current_male);
            male_deduct = current_male;
        };
        if (current_female < female_deduct) {
            male_deduct = male_deduct + (female_deduct - current_female);
            female_deduct = current_female;
        };
        
        // Aplicar deducción
        if (male_deduct > 0) {
            let male = table::borrow_mut(&mut reg.hex_male, location_key);
            *male = *male - male_deduct;
            reg.global_male = reg.global_male - male_deduct;
        };
        if (female_deduct > 0) {
            let female = table::borrow_mut(&mut reg.hex_female, location_key);
            *female = *female - female_deduct;
            reg.global_female = reg.global_female - female_deduct;
        };
        
        event::emit(PopulationDeducted {
            location_key,
            male_deducted: male_deduct,
            female_deducted: female_deduct,
            reason,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // === BLOQUEO DE TRABAJADORES PARA CONSTRUCCIÓN ===
    public fun block_workers_for_construction(
        reg: &mut PopulationRegistry,
        q: u64,
        r: u64,
        workers: u64,
        duration_days: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // En producción real: crear un objeto WorkerBlock con timestamp de expiración
        // Aquí: solo deducir población temporalmente (simulación)
        deduct_civilian(reg, q, r, workers, b"construction_block", clock, ctx);
        
        // En producción real: programar evento de liberación tras duration_days
        // sui::event::emit(WorkerBlockCreated { ... });
    }

    // === HELPERS ===
    fun register_population_at_hex(reg: &mut PopulationRegistry, location_key: u64, male: u64, female: u64) {
        if (!table::contains(&reg.hex_male, location_key)) {
            table::add(&mut reg.hex_male, location_key, 0);
        };
        if (!table::contains(&reg.hex_female, location_key)) {
            table::add(&mut reg.hex_female, location_key, 0);
        };
        
        let male_mut = table::borrow_mut(&mut reg.hex_male, location_key);
        let female_mut = table::borrow_mut(&mut reg.hex_female, location_key);
        
        *male_mut = *male_mut + male;
        *female_mut = *female_mut + female;
        
        reg.global_male = reg.global_male + male;
        reg.global_female = reg.global_female + female;
    }

    fun deduct_population_at_hex(reg: &mut PopulationRegistry, location_key: u64, amount: u64, _reason: vector<u8>) {
        let current_male = if (table::contains(&reg.hex_male, location_key)) { *table::borrow(&reg.hex_male, location_key) } else { 0 };
        let current_female = if (table::contains(&reg.hex_female, location_key)) { *table::borrow(&reg.hex_female, location_key) } else { 0 };
        let total = current_male + current_female;
        
        assert!(total >= amount, E_INSUFFICIENT_POP);
        
        let m_deduct = (amount * current_male) / total;
        let f_deduct = amount - m_deduct;
        
        let male_mut = table::borrow_mut(&mut reg.hex_male, location_key);
        let female_mut = table::borrow_mut(&mut reg.hex_female, location_key);
        
        *male_mut = *male_mut - m_deduct;
        *female_mut = *female_mut - f_deduct;
        
        reg.global_male = reg.global_male - m_deduct;
        reg.global_female = reg.global_female - f_deduct;
    }

    fun get_population_at_hex(reg: &PopulationRegistry, location_key: u64): u64 {
        let male = if (table::contains(&reg.hex_male, location_key)) { *table::borrow(&reg.hex_male, location_key) } else { 0 };
        let female = if (table::contains(&reg.hex_female, location_key)) { *table::borrow(&reg.hex_female, location_key) } else { 0 };
        male + female
    }

    fun get_settlement_info(t: u8): (u64, bool) {
        if (t == TYPE_CITY_STATE) { (POP_CITY_STATE, false) }
        else if (t == TYPE_CITY) { (POP_CITY, false) }
        else if (t == TYPE_TOWN) { (POP_TOWN, false) }
        else { (POP_VILLAGE, true) }
    }

    fun is_suitable_terrain(terrain: u8, settlement_type: u8): bool {
        // Ciudades-estado requieren llanuras o colinas fértiles
        if (settlement_type == TYPE_CITY_STATE) {
            terrain == terrain_plains() || terrain == terrain_meadow() || terrain == terrain_hills()
        } 
        // Villas pueden estar en costa o colinas
        else if (settlement_type == TYPE_TOWN) {
            terrain == terrain_coast() || terrain == terrain_hills() || terrain == terrain_plains()
        } 
        // Aldeas pueden estar en casi cualquier bioma excepto océano
        else if (settlement_type == TYPE_VILLAGE) {
            terrain != 0 // No océano
        } 
        else {
            true
        }
    }

    fun get_growth_rate_by_terrain(terrain: u8): u64 {
        if (terrain == 2) GROWTH_RATE_PLAINS
        else if (terrain == 3) GROWTH_RATE_MEADOW
        else if (terrain == 4) GROWTH_RATE_HILLS
        else if (terrain == 1) GROWTH_RATE_COAST
        else if (terrain == 7) GROWTH_RATE_DESERT
        else if (terrain == 6) GROWTH_RATE_TUNDRA
        else if (terrain == 5) GROWTH_RATE_MOUNTAIN
        else 35
    }

    // === GETTERS RPC ===
    public fun get_city_info(reg: &PopulationRegistry, city_id: ID): (vector<u8>, address, u8, u64, u64, u8) {
        assert!(table::contains(&reg.free_cities, city_id), E_CITY_NOT_FOUND);
        let city = table::borrow(&reg.free_cities, city_id);
        let total_pop = city.population_male + city.population_female;
        (city.name, city.owner, city.city_type, total_pop, city.location_key, city.continent)
    }

    public fun get_population_at_location(reg: &PopulationRegistry, q: u64, r: u64): (u64, u64) {
        let location_key = encode_coordinates(q, r);
        let male = if (table::contains(&reg.hex_male, location_key)) { *table::borrow(&reg.hex_male, location_key) } else { 0 };
        let female = if (table::contains(&reg.hex_female, location_key)) { *table::borrow(&reg.hex_female, location_key) } else { 0 };
        (male, female)
    }

    public fun get_global_population(reg: &PopulationRegistry): (u64, u64) {
        (reg.global_male, reg.global_female)
    }

    // === CRECIMIENTO POBLACIONAL (20% ANUAL) ===
    public fun apply_city_population_growth(
        reg: &mut PopulationRegistry,
        city_id: ID,
        clock: &Clock,
        _ctx: &mut TxContext
    ) {
        assert!(table::contains(&reg.free_cities, city_id), E_CITY_NOT_FOUND);
        let city = table::borrow_mut(&mut reg.free_cities, city_id);
        
        let now = clock::timestamp_ms(clock);
        let elapsed_ms = now - city.last_growth_timestamp;
        
        // Crecimiento anual = 20% (2000 bp)
        // Por día blockchain (24h) = 20% / 365 = 0.0548% = 54.8 bp
        let days_elapsed = elapsed_ms / 86400000;  // 24 horas en ms
        
        if (days_elapsed > 0) {
            let growth_bp_per_day = city.growth_rate_bp / 365;
            let total_growth_bp = growth_bp_per_day * days_elapsed;
            
            // Aplicar crecimiento
            let male_growth = city.population_male * total_growth_bp / 10000;
            let female_growth = city.population_female * total_growth_bp / 10000;
            
            city.population_male = city.population_male + male_growth;
            city.population_female = city.population_female + female_growth;
            city.last_growth_timestamp = now;
            
            // Actualizar población global
            reg.global_male = reg.global_male + male_growth;
            reg.global_female = reg.global_female + female_growth;
            
            // Actualizar población en hexágono
            if (table::contains(&reg.hex_male, city.location_key)) {
                let hex_male = table::borrow_mut(&mut reg.hex_male, city.location_key);
                *hex_male = *hex_male + male_growth;
            };
            if (table::contains(&reg.hex_female, city.location_key)) {
                let hex_female = table::borrow_mut(&mut reg.hex_female, city.location_key);
                *hex_female = *hex_female + female_growth;
            };
        };
    }

    // === CONTRATAR POBLACIÓN DE CIUDAD (Integración con altriuxworkers) ===
    public fun hire_from_city_population(
        reg: &mut PopulationRegistry,
        city_id: ID,
        amount: u64,
        _ctx: &mut TxContext
    ) {
        assert!(table::contains(&reg.free_cities, city_id), E_CITY_NOT_FOUND);
        let city = table::borrow_mut(&mut reg.free_cities, city_id);
        
        let total_pop = city.population_male + city.population_female;
        assert!(total_pop >= amount, E_INSUFFICIENT_POP);
        
        // Deducir proporcionalmente
        let male_ratio = city.population_male * 10000 / total_pop;
        let male_deduct = amount * male_ratio / 10000;
        let female_deduct = amount - male_deduct;
        
        city.population_male = city.population_male - male_deduct;
        city.population_female = city.population_female - female_deduct;
        
        // Actualizar global
        reg.global_male = reg.global_male - male_deduct;
        reg.global_female = reg.global_female - female_deduct;
    }

    // === ACTUALIZAR CONTEO DE SOLDADOS (Desde altriuxarmy) ===
    public fun update_city_soldier_count(
        reg: &mut PopulationRegistry,
        city_id: ID,
        new_count: u64,
        _ctx: &mut TxContext
    ) {
        assert!(table::contains(&reg.free_cities, city_id), E_CITY_NOT_FOUND);
        let city = table::borrow_mut(&mut reg.free_cities, city_id);
        city.soldier_count = new_count;
    }

    // === DETERMINAR GOBERNANTE POR CONTROL MILITAR ===
    public fun determine_city_ruler(
        reg: &mut PopulationRegistry,
        city_id: ID,
        army_registry: &Table<address, u64>,  // address -> soldier count in city
        _ctx: &mut TxContext
    ) {
        assert!(table::contains(&reg.free_cities, city_id), E_CITY_NOT_FOUND);
        let city = table::borrow_mut(&mut reg.free_cities, city_id);
        
        // Encontrar quien tiene más soldados
        let mut max_soldiers = 0;
        let mut ruler_address = @0x0;
        
        // En producción real: iterar sobre army_registry
        // Por ahora: simplificado para compilación
        // El módulo altriuxarmy debería llamar esta función cuando cambie el balance militar
        
        if (max_soldiers > 0) {
            city.ruler = option::some(ruler_address);
            city.owner = ruler_address;
        } else {
            city.ruler = option::none();
        };
    }

    // === GETTERS EXTENDIDOS ===
    public fun get_city_population(reg: &PopulationRegistry, city_id: ID): (u64, u64, u64) {
        assert!(table::contains(&reg.free_cities, city_id), E_CITY_NOT_FOUND);
        let city = table::borrow(&reg.free_cities, city_id);
        (city.population_male, city.population_female, city.population_male + city.population_female)
    }

    public fun get_city_ruler(reg: &PopulationRegistry, city_id: ID): Option<address> {
        assert!(table::contains(&reg.free_cities, city_id), E_CITY_NOT_FOUND);
        let city = table::borrow(&reg.free_cities, city_id);
        city.ruler
    }


    public fun get_city_soldiers(reg: &PopulationRegistry, city_id: ID): u64 {
        assert!(table::contains(&reg.free_cities, city_id), E_CITY_NOT_FOUND);
        let city = table::borrow(&reg.free_cities, city_id);
        city.soldier_count
    }

    public fun id_city_state(): u8 { TYPE_CITY_STATE }
    public fun id_city(): u8 { TYPE_CITY }
    public fun id_town(): u8 { TYPE_TOWN }
    public fun id_village(): u8 { TYPE_VILLAGE }
}
