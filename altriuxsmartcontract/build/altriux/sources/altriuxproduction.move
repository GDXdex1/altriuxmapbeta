module altriux::altriuxproduction {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use altriux::altriuxresources::{Inventory, consume_jax};
    use sui::clock::Clock;

    public struct ProductionBatch has key, store {
        id: UID,
        product_id: u64,
        quantity: u64,
        finish_time: u64,
    }

    public fun start_production(
        product_id: u64,
        quantity: u64,
        inv: &mut Inventory,
        clock: &Clock,
        ctx: &mut TxContext
    ): ProductionBatch {
        consume_jax(inv, 135, quantity * 2, clock); // Wood cost
        ProductionBatch {
            id: object::new(ctx),
            product_id,
            quantity,
            finish_time: 0,
        }
    }
}
