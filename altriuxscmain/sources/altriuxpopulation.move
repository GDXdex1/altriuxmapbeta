#[allow(unused_variable, unused_use, unused_const, duplicate_alias, unused_function, dead_code)]
module altriux::altriuxpopulation {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self};
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};
    use altriux::altriuxlocation::{Self, LocationRegistry, encode_coordinates, decode_coordinates, get_terrain_type, terrain_plains, terrain_meadow, terrain_hills, terrain_coast, get_continent, continent_drantium, continent_brontium, get_hemisphere, hemisphere_northern, hemisphere_southern, has_feature, feature_oasis};
    use altriux::altriuxresources::{Self, Inventory, add_jax, consume_jax, has_jax};
    use altriux::altriuxworkers::{Self, ROLE_MINERO}; // Adjusted as per project roles
    use altriux::altriuxfood;
    use altriux::altriuxbuildingbase;
    use altriux::altriuxutils;
    use sui::event;
    use std::option::{Self};

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
    const E_INSUFFICIENT_POP: u64 = 102;   // Población insuficiente para fundar
    const E_INVALID_LOCATION: u64 = 103;   // Coordenadas fuera de rango
    const E_NOT_OWNER: u64 = 104;          // Sin control de la ciudad
    const E_CITY_NOT_FOUND: u64 = 105;     // Ciudad no existe
    const E_NO_BATTLE_WIN: u64 = 106;      // No hay victoria reciente para reclamar
    const E_GROWTH_TOO_SOON: u64 = 107;    // Crecimiento aplicado recientemente
    const E_INSUFFICIENT_ARMY: u64 = 108;  // Ejército insuficiente para reclamar
    const E_ALREADY_OWNED: u64 = 109;      // Ciudad ya tiene dueño
    const E_NO_FREE_POP: u64 = 110;        // No hay población libre para reclamar siervos
    const E_INSUFFICIENT_FOOD: u64 = 111;  // No hay suficiente comida para mantener siervos
    const E_NO_AU: u64 = 112;              // No hay AU suficiente para usar siervos
    const E_NOT_CITY_OWNER: u64 = 113;     // No eres dueño de la ciudad para usar siervos

    // === STRUCTS ===
    public struct PopulationRegistry has key {
        id: UID,
        // Población global (para estadísticas)
        global_male: u64,
        global_female: u64,
        // Población por hexágono (coordenada codificada → población)
        hex_male: Table<u64, u64>,      // q,r codificado → hombres
        hex_female: Table<u64, u64>,    // q,r codificado → mujeres
        // Población libre vs. siervos por hex
        free_male: Table<u64, u64>,
        free_female: Table<u64, u64>,
        serf_male: Table<u64, u64>,
        serf_female: Table<u64, u64>,
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
        inventory: Inventory,           // Inventario propio de la ciudad
        serf_inventory: Inventory,      // Recursos generados por siervos
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

    public struct SerfsReclaimed has copy, drop {
        city_id: ID,
        male_serfs: u64,
        female_serfs: u64,
        timestamp: u64,
    }

    public struct SerfsStarved has copy, drop {
        city_id: ID,
        male_lost: u64,
        female_lost: u64,
        timestamp: u64,
    }

    public struct WorkersAssigned has copy, drop {
        city_id: ID,
        building_id: ID,
        serfs_assigned: u64,
        au_spent: u64,
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
            free_male: table::new(ctx),
            free_female: table::new(ctx),
            serf_male: table::new(ctx),
            serf_female: table::new(ctx),
            free_cities: table::new(ctx),
            last_global_growth: 0,
        };
        
        // Create specific cities (Manually configured)
        create_specific_cities(&mut registry, ctx);
        
        transfer::share_object(registry);
    }

    // === GENERACIÓN DE CIUDADES (Delegada a altriuxworldgen) ===
    fun create_specific_cities(_reg: &mut PopulationRegistry, _ctx: &mut TxContext) {
        // Cities are now spawned via altriuxworldgen::genesis_spawn_all_cities()
        // This function is kept as a no-op for backward compatibility.
    }

    /// Spawn a city or city-state at a specific coordinate. Called by altriuxworldgen.
    public(package) fun spawn_city_with_type(
        reg: &mut PopulationRegistry,
        q: u64,
        r: u64,
        name: vector<u8>,
        owner: address,
        city_type: u8,
        continent: u8,
        ctx: &mut TxContext
    ) {
        let location_key = encode_coordinates(q, r);
        let (pop, _) = get_settlement_info(city_type);
        let pop_male = pop * 51 / 100;
        let pop_female = pop - pop_male;

        let city = FreeCity {
            id: object::new(ctx),
            name,
            owner,
            city_type,
            population_male: pop_male,
            population_female: pop_female,
            growth_rate_bp: 2000,
            last_growth_timestamp: 0,
            location_key,
            continent,
            soldier_count: 0,
            ruler: if (owner == @0x0) { option::none() } else { option::some(owner) },
            last_battle_win: 0,
            battle_winner: @0x0,
            inventory: altriuxresources::create_inventory(@0x0, ctx),
            serf_inventory: altriuxresources::create_inventory(@0x0, ctx),
        };
        table::add(&mut reg.free_cities, object::id(&city), city);
        register_population_at_hex(reg, location_key, pop_male, pop_female);
    }

    /// Spawns a full settlement cluster: 1 City + 3 Towns + 6 Villages
    fun spawn_settlement_cluster(
        reg: &mut PopulationRegistry,
        q: u64,
        r: u64,
        name: vector<u8>,
        owner: address,
        continent: u8,
        ctx: &mut TxContext
    ) {
        let city_key = encode_coordinates(q, r);

        // 1. Spawn City (Center)
        let city = FreeCity {
            id: object::new(ctx),
            name,
            owner, // Initially owned by region wallet or @0x0 if claimable
            city_type: TYPE_CITY, // Claimable City
            population_male: POP_CITY * 51 / 100,
            population_female: POP_CITY * 49 / 100,
            growth_rate_bp: 2000,
            last_growth_timestamp: 0,
            location_key: city_key,
            continent,
            soldier_count: 0,
            ruler: option::none(),
            last_battle_win: 0,
            battle_winner: @0x0,
            inventory: altriuxresources::create_inventory(@0x0, ctx),
            serf_inventory: altriuxresources::create_inventory(@0x0, ctx),
        };
        table::add(&mut reg.free_cities, object::id(&city), city);
        register_population_at_hex(reg, city_key, POP_CITY * 51 / 100, POP_CITY * 49 / 100);

        // 2. Spawn 3 Towns in adjacent tiles (q+1, r-1, s+1 logic simulation)
        // Neighbors: (q+1, r), (q-1, r+1), (q, r-1) - spread out
        spawn_town(reg, q + 1, r, owner, continent, ctx);
        spawn_town(reg, q - 1, r + 1, owner, continent, ctx);
        spawn_town(reg, q, r - 1, owner, continent, ctx);

        // 3. Spawn 6 Villages (2 per Town nominal location, spread in duchy)
        // We place them in the outer ring or same tiles as towns (allowed)
        // Village 1-2 at Town 1 location
        spawn_village(reg, q + 1, r, owner, continent, ctx);
        spawn_village(reg, q + 1, r, owner, continent, ctx);
        
        // Village 3-4 at Town 2 location
        spawn_village(reg, q - 1, r + 1, owner, continent, ctx);
        spawn_village(reg, q - 1, r + 1, owner, continent, ctx);

        // Village 5-6 at Town 3 location
        spawn_village(reg, q, r - 1, owner, continent, ctx);
        spawn_village(reg, q, r - 1, owner, continent, ctx);
    }

    fun spawn_town(reg: &mut PopulationRegistry, q: u64, r: u64, owner: address, continent: u8, ctx: &mut TxContext) {
        let key = encode_coordinates(q, r);
        let town = FreeCity {
            id: object::new(ctx),
            name: b"Town", // Generic name, updated in gameplay
            owner,
            city_type: TYPE_TOWN,
            population_male: POP_TOWN * 51 / 100,
            population_female: POP_TOWN * 49 / 100,
            growth_rate_bp: 1500,
            last_growth_timestamp: 0,
            location_key: key,
            continent,
            soldier_count: 0,
            ruler: option::none(),
            last_battle_win: 0,
            battle_winner: @0x0,
            inventory: altriuxresources::create_inventory(@0x0, ctx),
            serf_inventory: altriuxresources::create_inventory(@0x0, ctx),
        };
        table::add(&mut reg.free_cities, object::id(&town), town);
        register_population_at_hex(reg, key, POP_TOWN * 51 / 100, POP_TOWN * 49 / 100);
    }

    fun spawn_village(reg: &mut PopulationRegistry, q: u64, r: u64, owner: address, continent: u8, ctx: &mut TxContext) {
        let key = encode_coordinates(q, r);
        let village = FreeCity {
            id: object::new(ctx),
            name: b"Village",
            owner,
            city_type: TYPE_VILLAGE,
            population_male: POP_VILLAGE * 51 / 100,
            population_female: POP_VILLAGE * 49 / 100,
            growth_rate_bp: 1000,
            last_growth_timestamp: 0,
            location_key: key,
            continent,
            soldier_count: 0,
            ruler: option::none(),
            last_battle_win: 0,
            battle_winner: @0x0,
            inventory: altriuxresources::create_inventory(@0x0, ctx),
            serf_inventory: altriuxresources::create_inventory(@0x0, ctx),
        };
        table::add(&mut reg.free_cities, object::id(&village), village);
        register_population_at_hex(reg, key, POP_VILLAGE * 51 / 100, POP_VILLAGE * 49 / 100);
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
        assert!(is_suitable_terrain(loc_reg, q, r, settlement_type), E_INVALID_LOCATION);
        
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
        let now = altriuxutils::get_timestamp(clock);
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
        
        city.last_battle_win = altriuxutils::get_timestamp(clock);
        city.battle_winner = winner;
    }

    // === RECLAMO DE CIUDAD (JUGABILIDAD) ===
    // Requisito: 300 soldados (50 caballería) y 60 trabajadores
    public fun claim_free_city(
        reg: &mut PopulationRegistry,
        city_id: ID,
        soldier_count: u64,
        cavalry_count: u64,
        worker_count: u64,
        ctx: &mut TxContext
    ) {
        assert!(table::contains(&reg.free_cities, city_id), E_CITY_NOT_FOUND);
        let city = table::borrow_mut(&mut reg.free_cities, city_id);
        let sender = tx_context::sender(ctx);

        // 1. Validar que no tenga dueño (o sea @0x0)
        assert!(city.owner == @0x0, E_ALREADY_OWNED);

        // 2. Validar requisitos de reclamo
        assert!(soldier_count >= 300, E_INSUFFICIENT_ARMY);
        assert!(cavalry_count >= 50, E_INSUFFICIENT_ARMY);
        assert!(worker_count >= 60, E_INSUFFICIENT_ARMY); // Requisito de trabajadores para logística

        // 3. Asignar nuevo dueño (Gobernante)
        city.owner = sender;
        city.ruler = option::some(sender);
        
        // 4. Actualizar guarnición inicial (Se asume que los soldados se mueven aquí)
        city.soldier_count = soldier_count;

        event::emit(CityClaimed {
            city_id,
            old_owner: @0x0,
            new_owner: sender,
            timestamp: 0, // Timestamp no disponible aquí, usar reloj si crítico
        });
    }

    // === MILITARY SERVICE REGISTRATION (Placeholder) ===
    // Commented out due to undefined Person/Settlement type
    /*
    public fun register_military_service(
        _person: &mut Settlement,
        _duration_days: u64,
        _clock: &Clock
    ) {
        abort 999
    }
    */
    // Implementation pending

    // === PÉRDIDA DE CIUDAD POR DERROTA ===
    public fun lose_city_ownership(
        reg: &mut PopulationRegistry,
        city_id: ID,
        clock: &Clock
    ) {
        assert!(table::contains(&reg.free_cities, city_id), E_CITY_NOT_FOUND);
        let city = table::borrow_mut(&mut reg.free_cities, city_id);
        
        // Si la guarnición llega a 0, el gobernante pierde el control
        if (city.soldier_count == 0) {
            let old_owner = city.owner;
            city.owner = @0x0; // Se vuelve neutral/libre
            city.ruler = option::none();
            
            event::emit(CityClaimed {
                city_id,
                old_owner,
                new_owner: @0x0, // Neutral
                timestamp: altriuxutils::get_timestamp(clock),
            });
        };
    }

    // === CRECIMIENTO POBLACIONAL DIARIO ===
    public fun apply_daily_growth(
        reg: &mut PopulationRegistry,
        loc_reg: &LocationRegistry,
        clock: &Clock,
        _ctx: &mut TxContext
    ) {
        let now = altriuxutils::get_timestamp(clock);
        
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
        _ctx: &mut TxContext
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
        _duration_days: u64,
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
        if (!table::contains(&reg.free_male, location_key)) {
            table::add(&mut reg.free_male, location_key, 0);
        };
        if (!table::contains(&reg.free_female, location_key)) {
            table::add(&mut reg.free_female, location_key, 0);
        };
        if (!table::contains(&reg.serf_male, location_key)) {
            table::add(&mut reg.serf_male, location_key, 0);
        };
        if (!table::contains(&reg.serf_female, location_key)) {
            table::add(&mut reg.serf_female, location_key, 0);
        };
        
        let male_mut = table::borrow_mut(&mut reg.hex_male, location_key);
        let female_mut = table::borrow_mut(&mut reg.hex_female, location_key);
        let free_male_mut = table::borrow_mut(&mut reg.free_male, location_key);
        let free_female_mut = table::borrow_mut(&mut reg.free_female, location_key);
        
        *male_mut = *male_mut + male;
        *female_mut = *female_mut + female;
        *free_male_mut = *free_male_mut + male; // Initially registered as free
        *free_female_mut = *free_female_mut + female;
        
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

    fun is_suitable_terrain(reg: &LocationRegistry, q: u64, r: u64, settlement_type: u8): bool {
        let terrain = get_terrain_type(reg, q, r);
        let has_oasis = has_feature(reg, q, r, feature_oasis());
        // Ciudades-estado requieren llanuras o colinas fértiles, o oasis en desierto
        if (settlement_type == TYPE_CITY_STATE) {
            terrain == terrain_plains() || terrain == terrain_meadow() || terrain == terrain_hills() || (terrain == altriuxlocation::terrain_desert() && has_oasis)
        } 
        // Villas pueden estar en costa o colinas
        else if (settlement_type == TYPE_TOWN) {
            terrain == terrain_coast() || terrain == terrain_hills() || terrain == terrain_plains() || (terrain == altriuxlocation::terrain_desert() && has_oasis)
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
        _army_registry: &Table<address, u64>,  // address -> soldier count in city
        _ctx: &mut TxContext
    ) {
        assert!(table::contains(&reg.free_cities, city_id), E_CITY_NOT_FOUND);
        let city = table::borrow_mut(&mut reg.free_cities, city_id);
        
        // Encontrar quien tiene más soldados
        let mut max_soldiers: u64 = 0;
        let mut ruler_address = @0x0;
        
        // En producción real: iterar sobre army_registry
        
        if (max_soldiers > 0) {
            city.ruler = option::some(ruler_address);
            city.owner = ruler_address;
        } else {
            city.ruler = option::none();
        };
    }

    // === RECLAMAR SIERVOS DE POBLACIÓN LIBRE ===
    public fun reclaim_serfs(
        reg: &mut PopulationRegistry,
        city_id: ID,
        male_serfs: u64,
        female_serfs: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(table::contains(&reg.free_cities, city_id), E_CITY_NOT_FOUND);
        let city = table::borrow_mut(&mut reg.free_cities, city_id);
        assert!(city.owner == tx_context::sender(ctx), E_NOT_CITY_OWNER);

        let free_male = *table::borrow(&reg.free_male, city.location_key);
        let free_female = *table::borrow(&reg.free_female, city.location_key);
        assert!(free_male >= male_serfs && free_female >= female_serfs, E_NO_FREE_POP);

        let serf_male_mut = table::borrow_mut(&mut reg.serf_male, city.location_key);
        *serf_male_mut = *serf_male_mut + male_serfs;
        let serf_female_mut = table::borrow_mut(&mut reg.serf_female, city.location_key);
        *serf_female_mut = *serf_female_mut + female_serfs;

        let free_male_mut = table::borrow_mut(&mut reg.free_male, city.location_key);
        *free_male_mut = *free_male_mut - male_serfs;
        let free_female_mut = table::borrow_mut(&mut reg.free_female, city.location_key);
        *free_female_mut = *free_female_mut - female_serfs;

        event::emit(SerfsReclaimed {
            city_id,
            male_serfs,
            female_serfs,
            timestamp: altriuxutils::get_timestamp(clock),
        });
    }

    // === MANTENIMIENTO DIARIO DE SIERVOS (Consumo Alimentación) ===
    public fun maintain_serfs(
        reg: &mut PopulationRegistry,
        city_id: ID,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(table::contains(&reg.free_cities, city_id), E_CITY_NOT_FOUND);
        let city = table::borrow_mut(&mut reg.free_cities, city_id);
        assert!(city.owner == tx_context::sender(ctx), E_NOT_CITY_OWNER);

        let serf_male = *table::borrow(&reg.serf_male, city.location_key);
        let serf_female = *table::borrow(&reg.serf_female, city.location_key);
        let total_serfs = serf_male + serf_female;

        let food_needed = total_serfs * 5;  // 5 Jax/persona/día
        
        // Usar Trigo (ID 2) como comida genérica base o buscar en inventario
        let food_id = altriuxfood::JAX_WHEAT();
        
        if (altriuxresources::has_jax(&city.inventory, food_id, food_needed)) {
            altriuxresources::consume_jax(&mut city.inventory, food_id, food_needed, clock);
        } else {
            let loss_male = serf_male / 10;  // 10% pérdida por hambre
            let loss_female = serf_female / 10;
            let serf_male_mut = table::borrow_mut(&mut reg.serf_male, city.location_key);
            *serf_male_mut = *serf_male_mut - loss_male;
            let serf_female_mut = table::borrow_mut(&mut reg.serf_female, city.location_key);
            *serf_female_mut = *serf_female_mut - loss_female;

            event::emit(SerfsStarved {
                city_id,
                male_lost: loss_male,
                female_lost: loss_female,
                timestamp: altriuxutils::get_timestamp(clock),
            });
        }
    }

    // === USAR SIERVOS COMO WORKERS PARA EDIFICIOS ===
    public fun assign_serfs_to_building(
        reg: &mut PopulationRegistry,
        city_id: ID,
        building_id: ID,
        serfs_assigned: u64,
        au_needed: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(table::contains(&reg.free_cities, city_id), E_CITY_NOT_FOUND);
        let city = table::borrow_mut(&mut reg.free_cities, city_id);
        assert!(city.owner == tx_context::sender(ctx), E_NOT_CITY_OWNER);

        let serf_male = *table::borrow(&reg.serf_male, city.location_key);
        let serf_female = *table::borrow(&reg.serf_female, city.location_key);
        assert!(serf_male + serf_female >= serfs_assigned, E_NO_FREE_POP);

        // Asumir worker contract para siervos (crear uno si necesario)
        // Por ahora, solo emitimos el evento ya que la lógica de producción de edificios
        // debe ser implementada en altriuxbuildingbase o un módulo de gestión de producción.
        
        // altriuxbuildingbase::produce_building_internal(building_id, &mut city.serf_inventory, clock);

        event::emit(WorkersAssigned {
            city_id,
            building_id,
            serfs_assigned,
            au_spent: au_needed,
            timestamp: altriuxutils::get_timestamp(clock),
        });
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
