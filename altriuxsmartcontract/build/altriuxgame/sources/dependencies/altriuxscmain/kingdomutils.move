module altriux::kingdomutils {
    use sui::clock::{Self, Clock};
    use sui::tx_context::TxContext;
    
    const JIX_WEIGHT_KG: u64 = 20;
    const JIX_VOLUME_L: u64 = 20;

    const GENESIS_TS: u64 = 1731628800000; // 2025-11-15T00:00:00Z
    const GAME_SPEED: u64 = 4;             // 1 hora real = 4 horas juego
    const DAY_MS: u64 = 86400000;          // 24 horas en ms
    const MONTH_DAYS: u64 = 28;            // 28 días por mes juego

    public fun get_game_date(now: u64): (u64, u64) {
        let elapsed = if (now > GENESIS_TS) now - GENESIS_TS else 0;
        let game_day_ms = DAY_MS / GAME_SPEED;
        let total_game_days = elapsed / game_day_ms;
        
        let month = (total_game_days / MONTH_DAYS) % 14 + 1;
        let day = (total_game_days % MONTH_DAYS) + 1;
        
        (month, day)
    }

    public fun get_game_time(clock: &Clock): u64 {
        clock::timestamp_ms(clock)
    }

    /// Pseudo-random number generator for legacy support.
    /// In production, use sui::random or verifiable randomness.
    public fun random(min: u64, max: u64, ctx: &mut TxContext): u64 {
        let uid = sui::object::new(ctx);
        let id_bytes = sui::object::uid_to_bytes(&uid);
        let first_byte = *std::vector::borrow(&id_bytes, 0);
        sui::object::delete(uid);
        
        let range = max - min + 1;
        if (range == 0) return min;
        
        min + ((first_byte as u64) % range)
    }

    public fun get_next_id(ctx: &mut TxContext): u64 {
        random(1000000, 9999999, ctx)
    }

    public fun jix_weight(): u64 { JIX_WEIGHT_KG }
    public fun jix_volume(): u64 { JIX_VOLUME_L }
}
