module altriux::altriuxactionpoints {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use sui::clock::{Self, Clock};
    use sui::transfer;
    use sui::event;

    // === CONSTANTES DE TIEMPO ===
    const MS_PER_AU: u64 = 10800000;              // 180 minutos = 1 AU
    const AU_PER_WORKER_DAY: u64 = 2;             // 2 AU por día de juego (3 horas blockchain)
    const MS_PER_GAME_DAY: u64 = 10800000;        // 3 horas blockchain = 1 día juego (4x velocidad)
    const MS_PER_BLOCKCHAIN_DAY: u64 = 86400000;  // 24 horas blockchain

    // === ERRORES ===
    const E_INSUFFICIENT_AU: u64 = 201;
    const E_INVALID_WORKER: u64 = 202;
    const E_POOL_NOT_FOUND: u64 = 203;

    // === STRUCTS ===
    public struct ActionPointRegistry has key {
        id: UID,
        pools: Table<ID, ActionPointPool>,  // worker_id -> pool
    }

    public struct ActionPointPool has store {
        worker_id: ID,
        owner: address,
        available_au: u64,                   // AU acumulados disponibles
        last_accumulation: u64,              // Timestamp última acumulación
        total_earned: u64,                   // Total AU ganados (estadística)
        total_consumed: u64,                 // Total AU consumidos (estadística)
    }

    // === EVENTS ===
    public struct AUAccumulated has copy, drop {
        worker_id: ID,
        amount: u64,
        new_balance: u64,
        timestamp: u64,
    }

    public struct AUConsumed has copy, drop {
        worker_id: ID,
        amount: u64,
        task_type: vector<u8>,
        remaining: u64,
        timestamp: u64,
    }

    // === INICIALIZACIÓN ===
    public fun init_au_registry(ctx: &mut TxContext) {
        let registry = ActionPointRegistry {
            id: object::new(ctx),
            pools: table::new(ctx),
        };
        transfer::share_object(registry);
    }

    // === CREAR POOL PARA TRABAJADOR ===
    public fun create_worker_pool(
        reg: &mut ActionPointRegistry,
        worker_id: ID,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let now = clock::timestamp_ms(clock);
        
        let pool = ActionPointPool {
            worker_id,
            owner: sender,
            available_au: 0,
            last_accumulation: now,
            total_earned: 0,
            total_consumed: 0,
        };
        
        table::add(&mut reg.pools, worker_id, pool);
    }

    // === ACUMULAR AU (Llamar periódicamente o antes de usar) ===
    public fun accumulate_au(
        reg: &mut ActionPointRegistry,
        worker_id: ID,
        clock: &Clock,
        _ctx: &mut TxContext
    ) {
        let now = clock::timestamp_ms(clock);
        
        assert!(table::contains(&reg.pools, worker_id), E_POOL_NOT_FOUND);
        let pool = table::borrow_mut(&mut reg.pools, worker_id);
        
        // Calcular AU ganados desde última acumulación
        let elapsed_ms = now - pool.last_accumulation;
        let game_days_elapsed = elapsed_ms / MS_PER_GAME_DAY;
        let au_earned = game_days_elapsed * AU_PER_WORKER_DAY;
        
        if (au_earned > 0) {
            pool.available_au = pool.available_au + au_earned;
            pool.total_earned = pool.total_earned + au_earned;
            pool.last_accumulation = now;
            
            event::emit(AUAccumulated {
                worker_id,
                amount: au_earned,
                new_balance: pool.available_au,
                timestamp: now,
            });
        };
    }

    // === CONSUMIR AU (Para tareas) ===
    public fun consume_au(
        reg: &mut ActionPointRegistry,
        worker_id: ID,
        amount: u64,
        task_type: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let now = clock::timestamp_ms(clock);
        
        assert!(table::contains(&reg.pools, worker_id), E_POOL_NOT_FOUND);
        let pool = table::borrow_mut(&mut reg.pools, worker_id);
        
        assert!(pool.owner == sender, E_INVALID_WORKER);
        assert!(pool.available_au >= amount, E_INSUFFICIENT_AU);
        
        pool.available_au = pool.available_au - amount;
        pool.total_consumed = pool.total_consumed + amount;
        
        event::emit(AUConsumed {
            worker_id,
            amount,
            task_type,
            remaining: pool.available_au,
            timestamp: now,
        });
    }

    // === CONSUMIR AU DE MÚLTIPLES TRABAJADORES ===
    public fun consume_au_from_workers(
        reg: &mut ActionPointRegistry,
        worker_ids: &vector<ID>,
        total_au_needed: u64,
        task_type: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let worker_count = vector::length(worker_ids);
        let au_per_worker = total_au_needed / worker_count;
        
        let mut i = 0;
        while (i < worker_count) {
            let wid = *vector::borrow(worker_ids, i);
            consume_au(reg, wid, au_per_worker, task_type, clock, ctx);
            i = i + 1;
        };
    }

    // === GETTERS ===
    public fun get_available_au(reg: &ActionPointRegistry, worker_id: ID): u64 {
        if (!table::contains(&reg.pools, worker_id)) {
            return 0
        };
        let pool = table::borrow(&reg.pools, worker_id);
        pool.available_au
    }

    public fun get_pool_stats(reg: &ActionPointRegistry, worker_id: ID): (u64, u64, u64) {
        assert!(table::contains(&reg.pools, worker_id), E_POOL_NOT_FOUND);
        let pool = table::borrow(&reg.pools, worker_id);
        (pool.available_au, pool.total_earned, pool.total_consumed)
    }

    // === HELPERS ===
    public fun calculate_au_for_time(duration_ms: u64): u64 {
        (duration_ms + MS_PER_AU - 1) / MS_PER_AU  // Redondear hacia arriba
    }

    public fun calculate_time_for_au(au_amount: u64): u64 {
        au_amount * MS_PER_AU
    }
}
