module altriux::altriuxproduction {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::TxContext;
    use std::option::{Option};
    use altriux::altriuxlocation::{ResourceLocation};

    public struct ProductionBatch has key, store {
        id: UID,
        creator_id: ID,          // ID of building or herd
        product_id: u64,
        quantity: u64,
        start_time: u64,
        finish_time: u64,        // Also serves as birth/slaughter time
        location: Option<ResourceLocation>,
    }

    public fun new_batch(
        creator_id: ID,
        product_id: u64,
        quantity: u64,
        start_time: u64,
        finish_time: u64,
        location: Option<ResourceLocation>,
        ctx: &mut TxContext
    ): ProductionBatch {
        ProductionBatch {
            id: object::new(ctx),
            creator_id,
            product_id,
            quantity,
            start_time,
            finish_time,
            location,
        }
    }

    public fun product_id(batch: &ProductionBatch): u64 { batch.product_id }
    public fun quantity(batch: &ProductionBatch): u64 { batch.quantity }
    public fun finish_time(batch: &ProductionBatch): u64 { batch.finish_time }
    public fun creator_id(batch: &ProductionBatch): ID { batch.creator_id }

    public fun destroy_batch(batch: ProductionBatch) {
        let ProductionBatch { id, .. } = batch;
        object::delete(id);
    }
}
