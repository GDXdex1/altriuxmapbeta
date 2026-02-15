module altriux::altriuxutils {
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use std::vector;

    public fun get_game_time(clock: &Clock): u64 {
        clock::timestamp_ms(clock) * 4 / 86400000 
    }

    public fun random(min: u64, max: u64, ctx: &TxContext): u64 {
        let digest = tx_context::digest(ctx);
        // Simplified "random" based on digest bytes without needing sha3 if problematic
        let val = (*vector::borrow(digest, 0) as u64);
        min + (val % (max - min + 1))
    }
}
