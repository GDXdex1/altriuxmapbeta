#[allow(unused_const, unused_use, unused_function, unused_variable, duplicate_alias)]
module altriux::altriuxmining {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self};
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};
    use sui::dynamic_field;
    use altriux::altriuxresources::{Self, Inventory, add_jax, consume_jax, has_jax};
    use altriux::altriuxlocation::{Self, LocationRegistry, encode_coordinates, decode_coordinates, get_terrain_type, get_hemisphere, hemisphere_northern, hemisphere_southern, hemisphere_equatorial, get_continent, continent_drantium, continent_brontium};
    use altriux::altriuxworkers::{Self, WorkerRegistry, WorkerContract};
    use altriux::altriuxactionpoints::{Self, ActionPointRegistry};
    use altriux::altriuxminerals;
    use altriux::altriuxutils;
    use altriux::altriuxhero::{Self, Hero};
    use sui::coin::{Self, Coin};
    use altriux::agc::{AGC};
    use sui::event;

    // === CONFIGURACIÓN TEMPORAL (Sincronización App) ===
    const GENESIS_TS: u64 = 1731628800000; // 2025-11-15T00:00:00Z
    const GAME_SPEED: u64 = 4;             // 1 hora real = 4 horas juego
    const DAY_MS: u64 = 86400000;          // 24 horas en ms
    const MONTH_DAYS: u64 = 28;            // 28 días por mes juego
    const YEAR_DAYS: u64 = 392;            // 14 meses × 28 días

    // === ESTACIONES (Según especificación técnica) ===
    const SEASON_WINTER: u8 = 1;   // Invierno (Norte: meses 1-3, Sur: meses 8-10)
    const SEASON_SPRING: u8 = 2;   // Primavera (Norte: meses 4-7, Sur: meses 11-14)
    const SEASON_SUMMER: u8 = 3;   // Verano (Norte: meses 8-10, Sur: meses 1-3)
    const SEASON_AUTUMN: u8 = 4;   // Otoño (Norte: meses 11-14, Sur: meses 4-7)
    const SEASON_DRY: u8 = 5;      // Estación seca (Ecuador: meses 1-7)
    const SEASON_MONSOON: u8 = 6;  // Monzón (Ecuador: meses 8-14)

    // === COSTOS AU ===
    const AU_COST_MINING: u64 = 2; // Costo por minero por jornada (1 día juego)

    // === TIPOS DE MINA ===
    const MINE_TYPE_GALENA: u8 = 1;    // Lead/Silver
    const MINE_TYPE_NIQUELITA: u8 = 2; // Nickel/Cobalt
    const MINE_TYPE_ORO: u8 = 3;       // Gold
    const MINE_TYPE_HIERRO: u8 = 4;    // Iron
    const MINE_TYPE_COBRE: u8 = 5;     // Copper
    const MINE_TYPE_ESTANO: u8 = 6;    // Tin

    // === RESERVAS EXACTAS (Cálculo matemático preciso) ===
    const TOTAL_GALENA_RESERVE_JAX: u64 = 16851851852; 
    const TOTAL_GOLD_RESERVE_JAX: u64 = 20000000000;   // 20B JAX = 10B 20g coins
    const TOTAL_NICKELITE_RESERVE_JAX: u64 = 100000000; // 100M/mine (30 mines)
    const TOTAL_IRON_MINE_RESERVE_JAX: u64 = 300000000; // 300M/mine (600 mines)
    const TOTAL_COPPER_MINE_RESERVE_JAX: u64 = 150000000; // 150M/mine (200 mines)
    const TOTAL_TIN_MINE_RESERVE_JAX: u64 = 100000000; // 100M/mine (50 mines)

    // === CONFIGURACIÓN DE DIFICULTAD (HALVING) ===
    const GOLD_HALVING_THRESHOLD_BP: u64 = 8500; // 85%

    // === ERRORES ===
    const E_NOT_OWNER: u64 = 101;
    const E_TOO_SOON: u64 = 102;
    const E_DEPLETED: u64 = 103;
    const E_INVALID_LOCATION: u64 = 104;
    const E_INSUFFICIENT_PAYMENT: u64 = 105;
    const E_INSUFFICIENT_FOOD: u64 = 106;
    const E_NO_MINERS: u64 = 107;
    const E_WORKERS_NOT_BLOCKED: u64 = 108;
    const E_INVALID_HEMISPHERE: u64 = 109;

    // === STRUCTS ===
    public struct MiningRegistry has key {
        id: UID,
        mines: Table<ID, MineNFT>,
    }

    public struct MineNFT has key, store {
        id: UID,
        owner: address,
        location_key: u64,          // Coordenada codificada (q,r)
        mine_type: u8,              // MINE_TYPE_GALENA
        reserves_jax: u64,          // Reservas restantes (inicia: 16,851,851,852 JAX)
        total_extracted_jax: u64,   // Total extraído históricamente
        initial_reserves_jax: u64,  // Reservas iniciales (para cálculo de halving)
        last_mined_ts: u64,         // Última extracción (timestamp)
        is_active: bool,            // True = operativa, False = agotada
    }

    // === EVENTS ===
    public struct MineSpawned has copy, drop {
        mine_id: ID,
        location_key: u64,
        reserves_jax: u64,
        owner: address,
        timestamp: u64,
    }

    public struct MineProduction has copy, drop {
        mine_id: ID,
        galena_extracted: u64,
        silver_displaced: u64,      // Plata desplazada (0.3%)
        sulfur_produced: u64,       // Azufre natural (2% en industrial)
        workers: u64,
        depletion_factor: u64,      // Factor de agotamiento (0-100)
        season_penalty: u64,        // Penalización estacional (0-20)
        timestamp: u64,
    }

    public struct MineDepleted has copy, drop {
        mine_id: ID,
        owner: address,
        timestamp: u64,
    }

    // === INICIALIZACIÓN ===
    public fun create_mining_registry(ctx: &mut TxContext) {
        let registry = MiningRegistry {
            id: object::new(ctx),
            mines: table::new(ctx),
        };
        transfer::share_object(registry);
    }

    // === CREACIÓN DE MINA GENÉRICA ===
    public(package) fun spawn_mine(
        reg: &mut MiningRegistry,
        q: u64,
        r: u64,
        mine_type: u8,
        reserves: u64,
        owner: address,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        assert!(q <= 419, E_INVALID_LOCATION);
        assert!(r <= 219, E_INVALID_LOCATION);
        
        let location_key = encode_coordinates(q, r);
        
        let mine = MineNFT {
            id: object::new(ctx),
            owner,
            location_key,
            mine_type,
            reserves_jax: reserves,
            total_extracted_jax: 0,
            initial_reserves_jax: reserves,
            last_mined_ts: 0,
            is_active: true,
        };
        
        let id = object::id(&mine);
        table::add(&mut reg.mines, id, mine);
        
        event::emit(MineSpawned {
            mine_id: id,
            location_key,
            reserves_jax: reserves,
            owner,
            timestamp: clock::timestamp_ms(clock),
        });
        
        id
    }

    public fun spawn_galena_mine(reg: &mut MiningRegistry, q: u64, r: u64, owner: address, clock: &Clock, ctx: &mut TxContext): ID {
        spawn_mine(reg, q, r, MINE_TYPE_GALENA, TOTAL_GALENA_RESERVE_JAX, owner, clock, ctx)
    }

    public fun spawn_gold_mine(reg: &mut MiningRegistry, q: u64, r: u64, owner: address, clock: &Clock, ctx: &mut TxContext): ID {
        spawn_mine(reg, q, r, MINE_TYPE_ORO, TOTAL_GOLD_RESERVE_JAX, owner, clock, ctx)
    }

    public fun spawn_niquelita_mine(reg: &mut MiningRegistry, q: u64, r: u64, owner: address, clock: &Clock, ctx: &mut TxContext): ID {
        spawn_mine(reg, q, r, MINE_TYPE_NIQUELITA, TOTAL_NICKELITE_RESERVE_JAX, owner, clock, ctx)
    }

    // Spawn 30 mines of Nickeline as requested
    public fun spawn_batch_niquelita_mines(
        reg: &mut MiningRegistry, 
        base_q: u64, 
        base_r: u64, 
        owner: address, 
        clock: &Clock, 
        ctx: &mut TxContext
    ) {
        let mut i = 0;
        while (i < 30) {
            // Distribute them slightly around base coords
            spawn_mine(reg, base_q + i, base_r, MINE_TYPE_NIQUELITA, TOTAL_NICKELITE_RESERVE_JAX, owner, clock, ctx);
            i = i + 1;
        };
    }

    // Spawn exactly 30 Gold mines (Configured per request)
    public fun spawn_batch_gold_mines(
        reg: &mut MiningRegistry, 
        base_q: u64, 
        base_r: u64, 
        owner: address, 
        clock: &Clock, 
        ctx: &mut TxContext
    ) {
        let count = 30; // Fixed configuration
        let reserves_per_mine = TOTAL_GOLD_RESERVE_JAX / count;
        let mut i = 0;
        while (i < count) {
            spawn_mine(reg, base_q, base_r + i, MINE_TYPE_ORO, reserves_per_mine, owner, clock, ctx);
            i = i + 1;
        };
    }

    // Spawn exactly 100 Galena mines (Configured per request)
    public fun spawn_batch_galena_mines(
        reg: &mut MiningRegistry, 
        base_q: u64, 
        base_r: u64, 
        owner: address, 
        clock: &Clock, 
        ctx: &mut TxContext
    ) {
        let count = 100; // Fixed configuration
        let reserves_per_mine = TOTAL_GALENA_RESERVE_JAX / count;
        let mut i = 0;
        while (i < count) {
            spawn_mine(reg, base_q + i, base_r, MINE_TYPE_GALENA, reserves_per_mine, owner, clock, ctx);
            i = i + 1;
        };
    }

    // Spawn 600 Iron mines
    public fun spawn_batch_iron_mines(reg: &mut MiningRegistry, base_q: u64, base_r: u64, owner: address, clock: &Clock, ctx: &mut TxContext) {
        let mut i = 0;
        while (i < 600) {
            spawn_mine(reg, base_q + i, base_r, MINE_TYPE_HIERRO, TOTAL_IRON_MINE_RESERVE_JAX, owner, clock, ctx);
            i = i + 1;
        };
    }

    // Spawn 200 Copper mines
    public fun spawn_batch_copper_mines(reg: &mut MiningRegistry, base_q: u64, base_r: u64, owner: address, clock: &Clock, ctx: &mut TxContext) {
        let mut i = 0;
        while (i < 200) {
            spawn_mine(reg, base_q, base_r + i, MINE_TYPE_COBRE, TOTAL_COPPER_MINE_RESERVE_JAX, owner, clock, ctx);
            i = i + 1;
        };
    }

    // Spawn 50 Tin mines near river systems (Logic simulation)
    public fun spawn_batch_tin_mines(reg: &mut MiningRegistry, base_q: u64, base_r: u64, owner: address, clock: &Clock, ctx: &mut TxContext) {
        let mut i = 0;
        while (i < 50) {
            // Tin follows river logic (simulated by +i)
            spawn_mine(reg, base_q + i, base_r + i, MINE_TYPE_ESTANO, TOTAL_TIN_MINE_RESERVE_JAX, owner, clock, ctx);
            i = i + 1;
        };
    }

    // === RECURSOS PARA CIUDADES (IRON MINES) ===
    // Spawns an Iron mine adjacent to a city (q+1, r)
    public fun spawn_city_nearby_resources(
        reg: &mut MiningRegistry,
        city_q: u64,
        city_r: u64,
        owner: address, // Usually @0x0 or city owner
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Regla: Mina de hierro en casilla adyacente (q+1)
        spawn_mine(
            reg, 
            city_q + 1, 
            city_r, 
            MINE_TYPE_HIERRO, 
            TOTAL_IRON_MINE_RESERVE_JAX, 
            owner, 
            clock, 
            ctx
        );
    }

    // === RECURSOS PARA CLUSTERS DE ASENTAMIENTOS ===
    // Spawns resources for a full cluster (City + 3 Towns + 6 Villages)
    public fun spawn_cluster_resources(
        reg: &mut MiningRegistry,
        city_q: u64,
        city_r: u64,
        owner: address,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // 1. City always gets Iron Mine at q+1
        spawn_city_nearby_resources(reg, city_q, city_r, owner, clock, ctx);

        // 2. Towns (simulated positions: q+1,r; q-1,r+1; q,r-1)
        // Town 1 (q+1, r)
        // Town 2 (q-1, r+1) - Copper Mine nearby
        spawn_mine(reg, city_q - 1, city_r + 2, MINE_TYPE_COBRE, TOTAL_COPPER_MINE_RESERVE_JAX, owner, clock, ctx);

        // 3. Villages (scattered)
        // Village at q, r-2 - Tin Mine nearby
        spawn_mine(reg, city_q, city_r - 2, MINE_TYPE_ESTANO, TOTAL_TIN_MINE_RESERVE_JAX, owner, clock, ctx);
    }

    // === RECURSOS DE DESIERTO (GOLD/SILVER) ===
    // Spawn mines in desert mountains (10% chance logic simulated)
    public fun spawn_desert_mountain_resources(
        reg: &mut MiningRegistry,
        q: u64,
        r: u64,
        is_near_oasis: bool,
        owner: address,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // En desierto sin oasis -> Montañas (Gold/Silver)
        // Cerca de oasis -> Prioridad (Trade routes)
        
        let mine_type = if (is_near_oasis) MINE_TYPE_ORO else MINE_TYPE_GALENA;
        let reserves = if (is_near_oasis) TOTAL_GOLD_RESERVE_JAX / 100 else TOTAL_GALENA_RESERVE_JAX / 200;
        
        spawn_mine(reg, q, r, mine_type, reserves, owner, clock, ctx);
    }

    // === EXTRACCIÓN DIARIA CON DIFICULTAD DINÁMICA ===
    public fun mine_resource(
        reg: &mut MiningRegistry,
        worker_reg: &WorkerRegistry,
        mine_id: ID,
        worker_ids: vector<ID>,
        hero: &Hero,
        nobility_titles: &vector<ID>,
        food_inv: &mut Inventory,
        mut salary_payment: Coin<AGC>,
        raw_inv: &mut Inventory,
        au_reg: &mut ActionPointRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let mine = table::borrow_mut(&mut reg.mines, mine_id);
        let now = clock::timestamp_ms(clock);
        
        // === SEGURIDAD RIGIDA: VALIDACIONES ANTI-EXPLOIT ===
        assert!(mine.is_active, E_DEPLETED);
        assert!(mine.owner == sender, E_NOT_OWNER);
        
        // Cooldown estricto: 1 jornada (12h juego / 3h real)
        let cooldown_ms = 3 * 60 * 60 * 1000;
        assert!(now >= mine.last_mined_ts + cooldown_ms, E_TOO_SOON);

        // Especialización de trabajadores
        let worker_count = vector::length(&worker_ids);
        assert!(worker_count > 0, E_NO_MINERS);
        
        // Verificar Roles y Nobleza (Supervisión)
        assert!(altriuxhero::can_supervise_workers(object::id(hero), nobility_titles), E_WORKERS_NOT_BLOCKED);
        
        // Validar que TODOS los trabajadores sean mineros (Dificultad técnica medieval)
        let mut i = 0;
        while (i < worker_count) {
            let wid = *vector::borrow(&worker_ids, i);
            let worker = altriuxworkers::borrow_worker(worker_reg, wid);
            assert!(altriuxworkers::get_worker_role(worker) == altriuxworkers::ROLE_MINERO(), E_NO_MINERS);
            i = i + 1;
        };

        // === COSTOS AU Y RECURSOS ===
        let total_au = (worker_count as u64) * AU_COST_MINING;
        altriuxactionpoints::consume_au_from_workers(au_reg, &worker_ids, total_au, b"mining_cycle", clock, ctx);

        let food_required = worker_count * 5;
        assert!(has_jax(food_inv, 2, food_required), E_INSUFFICIENT_FOOD); // Trigo (2)
        consume_jax(food_inv, 2, food_required, clock);
        
        let salary_required = worker_count * 100;
        assert!(coin::value(&salary_payment) >= salary_required, E_INSUFFICIENT_PAYMENT);
        transfer::public_transfer(salary_payment, @0x554a2392980b0c3e4111c9a0e8897e632d41847d04cbd41f9e081e49ba2eb04a);

        // === CÁLCULO DE RENDIMIENTO Y DIFICULTAD (HALVING) ===
        let base_yield = 5; // 5 JAX per worker
        let mut final_yield = base_yield * (worker_count as u64);
        
        // === SISTEMA DE HALVING PARA ORO (Seguridad Económica) ===
        if (mine.mine_type == MINE_TYPE_ORO) {
            let current_res_bp = (mine.reserves_jax * 10000) / mine.initial_reserves_jax;
            if (current_res_bp < GOLD_HALVING_THRESHOLD_BP) {
                // Halving dinámico: Cada 5% de agotamiento adicional reduce el rendimiento geométricamente
                // 85% -> 1x, 80% -> 0.5x, 75% -> 0.25x ...
                let exhaustion_factor = (GOLD_HALVING_THRESHOLD_BP - current_res_bp) / 500;
                let mut difficulty_divisor = 1;
                let mut d = 0;
                while (d <= exhaustion_factor) {
                    difficulty_divisor = difficulty_divisor * 2;
                    d = d + 1;
                };
                final_yield = final_yield / difficulty_divisor;
            };
        };

        // Penalización por profundidad (Agotamiento tradicional) para otros minerales
        if (mine.mine_type != MINE_TYPE_ORO) {
            let depletion_ratio = (mine.total_extracted_jax * 10000) / mine.initial_reserves_jax;
            let depletion_factor = integer_sqrt(depletion_ratio); 
            final_yield = final_yield * (10000 - depletion_factor * 100) / 10000;
        };

        // Seguridad: Asegurar que no se extraiga más de lo que queda
        if (final_yield > mine.reserves_jax) {
            final_yield = mine.reserves_jax;
        };
        assert!(final_yield > 0, E_DEPLETED);

        // === ASIGNACIÓN DE RECURSO SEGÚN TIPO DE MINA ===
        let res_id = if (mine.mine_type == MINE_TYPE_GALENA) {
            altriuxminerals::JAX_MINERAL_GALENA()
        } else if (mine.mine_type == MINE_TYPE_ORO) {
            altriuxminerals::MINERAL_ORO()
        } else if (mine.mine_type == MINE_TYPE_NIQUELITA) {
            altriuxminerals::MINERAL_NIQUELITA()
        } else if (mine.mine_type == MINE_TYPE_HIERRO) {
            altriuxminerals::MINERAL_HIERRO()
        } else if (mine.mine_type == MINE_TYPE_COBRE) {
            altriuxminerals::MINERAL_COBRE()
        } else {
            altriuxminerals::MINERAL_ESTANO()
        };

        // Byproduct logic: Tin yields Iron (20%)
        let mut byproduct_id = 0;
        let mut byproduct_amount = 0;
        if (mine.mine_type == MINE_TYPE_ESTANO) {
            byproduct_id = altriuxminerals::MINERAL_HIERRO();
            byproduct_amount = (final_yield * 20) / 100; // 20% Iron yield
        };

        // === ACTUALIZAR ESTADO DE LA MINA (FINITO) ===
        mine.total_extracted_jax = mine.total_extracted_jax + final_yield;
        mine.reserves_jax = mine.reserves_jax - final_yield;
        mine.last_mined_ts = now;
        
        if (mine.reserves_jax == 0) {
            mine.is_active = false;
        };
        
        // === ENTREGA DE RECURSO AL INVENTARIO ===
        add_jax(raw_inv, res_id, final_yield, 0, clock);
        if (byproduct_amount > 0) {
            add_jax(raw_inv, byproduct_id, byproduct_amount, 0, clock);
        };
        
        event::emit(MineProduction {
            mine_id,
            galena_extracted: if (res_id == altriuxminerals::JAX_MINERAL_GALENA()) final_yield else 0,
            silver_displaced: 0, 
            sulfur_produced: 0,
            workers: worker_count as u64,
            depletion_factor: 0, 
            season_penalty: 0,
            timestamp: now,
        });
    }

    // === FUNCIÓN DE HALVING DINÁMICO (Raíz Cuadrada) ===
    fun integer_sqrt(n: u64): u64 {
        if (n == 0) return 0;
        let mut x = n;
        let mut y = (x + 1) / 2;
        while (y < x) {
            x = y;
            y = (x + n / x) / 2;
        };
        x
    }

    // === BONIFICACIÓN POR EXPERIENCIA DE MINEROS ===
    fun calculate_miner_experience_bonus(worker_reg: &WorkerRegistry, worker_ids: &vector<ID>): u64 {
        let mut total_bonus = 0;
        let count = vector::length(worker_ids);
        let mut i = 0;
        while (i < count) {
            let wid = *vector::borrow(worker_ids, i);
            // En producción real: obtener nivel del trabajador desde WorkerRegistry
            // Aquí: simulamos nivel aleatorio para demostración
            let level = (i % 6) as u64; // Niveles 0-5
            total_bonus = total_bonus + (level * 5); // +5% por nivel
            i = i + 1;
        };
        total_bonus / count
    }

    // === SISTEMA DE ESTACIONES GEORGRÁFICAS ===
    public fun get_current_season(q: u64, r: u64, clock: &Clock): u8 {
        // Calcular día del año juego
        let elapsed_real = clock::timestamp_ms(clock) - GENESIS_TS;
        let elapsed_game = elapsed_real * GAME_SPEED;
        let total_days = elapsed_game / DAY_MS;
        let current_year_day = total_days % YEAR_DAYS;
        let month_number = (current_year_day / MONTH_DAYS) + 1; // 1-14
        
        // Determinar hemisferio usando logic de altriuxlocation
        let hemisphere = get_hemisphere(r);
        
        // Mapeo estacional según hemisferio
        if (hemisphere == hemisphere_northern()) {
            if (month_number <= 3) SEASON_WINTER
            else if (month_number <= 7) SEASON_SPRING
            else if (month_number <= 10) SEASON_SUMMER
            else SEASON_AUTUMN
        } else if (hemisphere == hemisphere_southern()) {
            if (month_number <= 3) SEASON_SUMMER
            else if (month_number <= 7) SEASON_AUTUMN
            else if (month_number <= 10) SEASON_WINTER
            else SEASON_SPRING
        } else {
            if (month_number <= 7) SEASON_DRY
            else SEASON_MONSOON
        }
    }


    // === FUNCIÓN AUXILIAR: Obtener terreno desde coordenadas ===
    fun get_terrain_type_from_coords(_q: u64, _r: u64): u8 {
        // Placeholder implementation
        0
    }

    // (Smelting and silver production moved to gameplay)


    // === GETTERS RPC ===
    public fun get_mine_info(reg: &MiningRegistry, mine_id: ID): (u64, u64, u64, bool) {
        let mine = table::borrow(&reg.mines, mine_id);
        (mine.reserves_jax, mine.total_extracted_jax, mine.initial_reserves_jax, mine.is_active)
    }

    public fun get_mine_location(reg: &MiningRegistry, mine_id: ID): (u64, u64) {
        let mine = table::borrow(&reg.mines, mine_id);
        decode_coordinates(mine.location_key)
    }
    public fun id_mine_type_galena(): u8 { MINE_TYPE_GALENA }
    public fun id_mine_type_niquelita(): u8 { MINE_TYPE_NIQUELITA }
    public fun id_mine_type_oro(): u8 { MINE_TYPE_ORO }
    public fun id_mine_type_hierro(): u8 { MINE_TYPE_HIERRO }
    public fun id_mine_type_cobre(): u8 { MINE_TYPE_COBRE }
    public fun id_mine_type_estano(): u8 { MINE_TYPE_ESTANO }
    public fun reserve_galena(): u64 { TOTAL_GALENA_RESERVE_JAX }
    public fun reserve_gold(): u64 { TOTAL_GOLD_RESERVE_JAX }
    public fun reserve_nickelite(): u64 { TOTAL_NICKELITE_RESERVE_JAX }
    public fun reserve_iron(): u64 { TOTAL_IRON_MINE_RESERVE_JAX }
    public fun reserve_copper(): u64 { TOTAL_COPPER_MINE_RESERVE_JAX }
    public fun reserve_tin(): u64 { TOTAL_TIN_MINE_RESERVE_JAX }
}