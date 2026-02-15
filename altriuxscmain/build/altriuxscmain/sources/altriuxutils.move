module altriux::altriuxutils {
    use sui::clock::{Self, Clock};

    const GENESIS_TS: u64 = 1731628800000; // 2025-11-15T00:00:00Z
    const GAME_SPEED: u64 = 4;             // 1 hora real = 4 horas juego
    const DAY_MS: u64 = 86400000;          // 24 horas en ms
    const MONTH_DAYS: u64 = 28;            // 28 días por mes juego
    const JIX_WEIGHT_KG: u64 = 20;
    const JIX_VOLUME_L: u64 = 20;

    /// Returns (month, day) in game calendar.
    public fun get_game_date(now: u64): (u64, u64) {
        let elapsed = if (now > GENESIS_TS) now - GENESIS_TS else 0;
        let game_day_ms = DAY_MS / GAME_SPEED;
        let total_game_days = elapsed / game_day_ms;
        
        let month = (total_game_days / MONTH_DAYS) % 14 + 1;
        let day = (total_game_days % MONTH_DAYS) + 1;
        
        (month, day)
    }

    /// Legacy support for getting raw ms.
    public fun get_timestamp(clock: &Clock): u64 {
        clock::timestamp_ms(clock)
    }

    /// Returns calculated game date-time or day count.
    /// Existing altriuxutils used raw timestamp * 4 / 86400000.
    public fun get_game_time(clock: &Clock): u64 {
        clock::timestamp_ms(clock) * GAME_SPEED / DAY_MS 
    }

    /// Optimized pseudo-random number generator.
    public fun random(min: u64, max: u64, ctx: &TxContext): u64 {
        let digest = tx_context::digest(ctx);
        let val = (*vector::borrow(digest, 0) as u64);
        min + (val % (max - min + 1))
    }

    public fun get_next_id(ctx: &TxContext): u64 {
        random(1000000, 9999999, ctx)
    }

    public fun jix_weight(): u64 { JIX_WEIGHT_KG }
    public fun jix_volume(): u64 { JIX_VOLUME_L }
}
