module altriux::altriuxmining {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::transfer;
    use sui::table::{Self, Table};
    use sui::dynamic_field;
    use std::vector;
    use altriux::altriuxresources::{Self, Inventory, add_jax, consume_jax, has_jax};
    use altriux::altriuxlocation::{Self, LocationRegistry, encode_coordinates, decode_coordinates, get_terrain_type, get_hemisphere, hemisphere_northern, hemisphere_southern, hemisphere_equatorial, get_continent, continent_drantium, continent_brontium};
    use altriux::altriuxworkers::{Self, WorkerRegistry, WorkerContract};
    use altriux::altriuxactionpoints::{Self, ActionPointRegistry};
    use altriux::altriuxminerals;
    use altriux::kingdomutils;
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
    const MINE_TYPE_GALENA: u8 = 1; // Única fuente de plomo/plata (PbS con 0.3% Ag)

    // === RESERVA EXACTA DE GALENA (Cálculo matemático preciso) ===
    const TOTAL_GALENA_RESERVE_JAX: u64 = 16851851852; // 16,851,851,852 JAX

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

    // === CREACIÓN DE MINA DE GALENA (Reserva exacta) ===
    public fun spawn_galena_mine(
        reg: &mut MiningRegistry,
        q: u64,
        r: u64,
        owner: address,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        // Validar coordenadas (rango offset [0, 419] y [0, 219])
        assert!(q <= 419, E_INVALID_LOCATION);
        assert!(r <= 219, E_INVALID_LOCATION);
        
        // Validar bioma adecuado (montañas o colinas para vetas de galena)
        // En producción real: consultar LocationRegistry
        // Aquí: asumimos ubicación válida para demostración
        
        let location_key = encode_coordinates(q, r);
        
        let mine = MineNFT {
            id: object::new(ctx),
            owner,
            location_key,
            mine_type: MINE_TYPE_GALENA,
            reserves_jax: TOTAL_GALENA_RESERVE_JAX, // ¡RESERVA EXACTA!
            total_extracted_jax: 0,
            initial_reserves_jax: TOTAL_GALENA_RESERVE_JAX,
            last_mined_ts: 0,
            is_active: true,
        };
        
        let id = object::id(&mine);
        table::add(&mut reg.mines, id, mine);
        
        event::emit(MineSpawned {
            mine_id: id,
            location_key,
            reserves_jax: TOTAL_GALENA_RESERVE_JAX,
            owner,
            timestamp: clock::timestamp_ms(clock),
        });
        
        id
    }

    // === EXTRACCIÓN DIARIA CON HALVING DINÁMICO ===
    public fun mine_galena(
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
        
        // === VALIDACIÓN 1: Propiedad ===
        assert!(mine.owner == sender, E_NOT_OWNER);

        // === VALIDACIÓN 2: Restricción de Nobleza (Supervisión) ===
        // Solo los nobles pueden comandar trabajadores (mineros)
        assert!(altriuxhero::can_supervise_workers(object::id(hero), nobility_titles), E_WORKERS_NOT_BLOCKED); // Reusing error or creating new one?
        
        // === VALIDACIÓN 3: Cooldown (3 horas blockchain = 1 jornada laboral) ===
        // 3 horas reales × 4x velocidad = 12 horas juego = 0.5 día juego
        // Pero el requisito dice "3 horas blockchain" para una jornada, así que:
        let cooldown_ms = 3 * 60 * 60 * 1000; // 3 horas reales
        assert!(now >= mine.last_mined_ts + cooldown_ms, E_TOO_SOON);
        
        // === VALIDACIÓN 4: Mineros asignados ===
        let worker_count = vector::length(&worker_ids);
        assert!(worker_count > 0, E_NO_MINERS);
        
        // === VALIDACIÓN 5: Comida suficiente (5 JAX trigo por minero) ===
        let food_required = worker_count * 5;
        assert!(has_jax(food_inv, 2, food_required), E_INSUFFICIENT_FOOD);
        consume_jax(food_inv, 2, food_required, clock); // JAX_WHEAT
        
        // === VALIDACIÓN 6: Salario suficiente (100 AGC por minero) ===
        let salary_required = worker_count * 100;
        assert!(coin::value(&salary_payment) >= salary_required, E_INSUFFICIENT_PAYMENT);
        
        // Distribuir salario: 80% economía NPC, 20% beneficiario
        let beneficiary_share = (salary_required * 20) / 100;
        let beneficiary_coin = coin::split(&mut salary_payment, beneficiary_share, ctx);
        transfer::public_transfer(beneficiary_coin, @0x947a1db4d9be4bd4a07a0d6e5ad8372b0c90268a28752c96f2d0d7b71bc591f);
        
        transfer::public_transfer(salary_payment, @0x554a2392980b0c3e4111c9a0e8897e632d41847d04cbd41f9e081e49ba2eb04a);
        
        // === VALIDACIÓN 7: Action Points (2 AU por minero) ===
        let total_au = (worker_count as u64) * AU_COST_MINING;
        altriuxactionpoints::consume_au_from_workers(au_reg, &worker_ids, total_au, b"mine_galena", clock, ctx);
        
        // === CÁLCULO DE RENDIMIENTO CON HALVING DINÁMICO ===
        // Factor de agotamiento: rendimiento disminuye según % extraído
        // Fórmula realista: rendimiento = base × (1 - √(extraído/total))
        // Esto simula la necesidad de excavar más profundo con menor concentración
        let depletion_ratio = if (mine.initial_reserves_jax > 0) {
            (mine.total_extracted_jax * 10000) / mine.initial_reserves_jax // En basis points
        } else {
            0
        };
        let depletion_sqrt = integer_sqrt(depletion_ratio); // √(depletion_ratio)
        let depletion_factor = depletion_sqrt * 100 / 100; // Normalizar a 0-100
        
        // Rendimiento base: 5 JAX galena por minero por jornada
        let base_yield = 5;
        let yield_after_depletion = base_yield * (10000 - depletion_factor * 100) / 10000;
        
        // Bonificación por experiencia de mineros (nivel 0-5: +0% a +25%)
        let exp_bonus = calculate_miner_experience_bonus(worker_reg, &worker_ids);
        let yield_with_exp = yield_after_depletion * (10000 + exp_bonus * 100) / 10000;
        
        // Penalización estacional según hemisferio y mes actual
        let (q, r) = decode_coordinates(mine.location_key);
        let season_penalty = get_seasonal_mining_penalty(q, r, clock);
        let final_yield_per_worker = yield_with_exp * (100 - season_penalty) / 100;
        
        // Extracción total
        let extracted = final_yield_per_worker * (worker_count as u64);
        assert!(mine.reserves_jax >= extracted, E_DEPLETED);
        
        // === PRODUCCIÓN DE SUBPRODUCTOS ===
        // Plata desplazada: 0.3% del peso de la galena (documentado en minas romanas)
        let silver_displaced = (extracted * 3) / 1000; // 0.3%
        
        // Azufre natural: 2% en fundición industrial (proceso de tostación de galena)
        // Solo se produce cuando la galena es procesada en FUNDICION_INDUSTRIAL
        // Aquí solo extraemos galena; el azufre se genera en el edificio de fundición
        
        // === ACTUALIZAR ESTADO DE LA MINA ===
        mine.total_extracted_jax = mine.total_extracted_jax + extracted;
        mine.reserves_jax = mine.reserves_jax - extracted;
        mine.last_mined_ts = now;
        
        // Verificar agotamiento total
        if (mine.reserves_jax == 0) {
            mine.is_active = false;
            event::emit(MineDepleted {
                mine_id,
                owner: sender,
                timestamp: now,
            });
        };
        
        // === AÑADIR GALENA AL INVENTARIO ===
        add_jax(raw_inv, altriuxminerals::JAX_MINERAL_GALENA(), extracted, 0, clock);
        
        event::emit(MineProduction {
            mine_id,
            galena_extracted: extracted,
            silver_displaced,
            sulfur_produced: 0, // Se genera en fundición, no en mina
            workers: worker_count as u64,
            depletion_factor,
            season_penalty,
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

    // === PENALIZACIÓN ESTACIONAL EN MINERÍA ===
    fun get_seasonal_mining_penalty(q: u64, r: u64, clock: &Clock): u64 {
        let season = get_current_season(q, r, clock);
        let hemisphere = get_hemisphere(r);
        
        // Penalizaciones realistas basadas en condiciones históricas
        if (hemisphere == hemisphere_northern() && season == SEASON_WINTER) {
            20 // Nieve y hielo dificultan el acceso a minas
        } else if (hemisphere == hemisphere_southern() && season == SEASON_WINTER) {
            20 // Mismo efecto en hemisferio sur
        } else if (hemisphere == hemisphere_equatorial() && season == SEASON_MONSOON) {
            15 // Inundaciones en minas a cielo abierto
        } else if (season == SEASON_DRY && get_terrain_type_from_coords(q, r) == 7) { // Desierto
            10 // Calor extremo reduce jornada laboral
        } else {
            0 // Sin penalización
        }
    }

    // === FUNCIÓN AUXILIAR: Obtener terreno desde coordenadas ===
    fun get_terrain_type_from_coords(q: u64, r: u64): u8 {
        // En producción real: consultar LocationRegistry
        // Aquí: valor por defecto para demostración
        2 // Plains
    }

    // === FUNDICIÓN DE GALENA (Con subproductos) ===
    public fun smelt_galena(
        inv: &mut Inventory,
        amount: u64,
        is_industrial: bool, // True = FUNDICION_INDUSTRIAL, False = FUNDICION_TRIBAL
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Validar galena suficiente
        assert!(has_jax(inv, altriuxminerals::JAX_MINERAL_GALENA(), amount), E_INSUFFICIENT_FOOD);
        
        // Consumir galena
        consume_jax(inv, altriuxminerals::JAX_MINERAL_GALENA(), amount, clock);
        
        // Producción de plomo refinado (50% rendimiento histórico)
        let lead_output = (amount * 50) / 100;
        add_jax(inv, altriuxminerals::PLOMO_REFINADO(), lead_output, 0, clock);
        
        // Plata desplazada (0.3% - documentado en procesos romanos de cupelación)
        let silver_output = (amount * 3) / 1000;
        if (silver_output > 0) {
            add_jax(inv, altriuxminerals::PLATA_DESPLAZADA(), silver_output, 0, clock);
        };
        
        // Azufre natural (2% SOLO en fundición industrial mediante tostación)
        if (is_industrial) {
            let sulfur_output = (amount * 2) / 100;
            if (sulfur_output > 0) {
                add_jax(inv, altriuxminerals::AZUFRE_NATURAL(), sulfur_output, 0, clock);
            };
        };
        
        // Escoria (30% - residuo de fundición)
        let slag_output = (amount * 30) / 100;
        add_jax(inv, altriuxminerals::ESCORIA_COBRE(), slag_output, 0, clock);
    }

    // === VERIFICACIÓN MATEMÁTICA EXACTA ===
    public fun verify_silver_production(): (u64, u64, u64) {
        // Cálculo exacto de producción total de plata
        let total_galena = TOTAL_GALENA_RESERVE_JAX;
        let total_silver = (total_galena * 3) / 1000; // 0.3%
        let est_coins = (total_silver * 1000) / 10;    // 0.5g por moneda (10g = 1 JAX → 0.5g = 0.05 JAX)
        let lrc_coins = (total_silver * 1000) / 90;   // 4.5g por moneda (90g = 1 JAX → 4.5g = 0.225 JAX)
        
        // Con 10% pérdida en acuñación:
        let est_after_loss = est_coins * 90 / 100;
        let lrc_after_loss = lrc_coins * 90 / 100;
        
        (est_after_loss, lrc_after_loss, total_silver)
    }

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
    public fun total_galena_reserve(): u64 { TOTAL_GALENA_RESERVE_JAX }
}