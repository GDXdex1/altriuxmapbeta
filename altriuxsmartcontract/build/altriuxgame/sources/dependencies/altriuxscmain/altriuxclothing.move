module altriux::altriuxclothing {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use altriux::altriuxresources::{Inventory, consume_jax};
    use sui::clock::Clock;

    public struct Clothing has key, store {
        id: UID,
        type_id: u64,
        culture: u8,
        insulation: u8, // Protection from cold
        prestige: u8,
        durability: u64,
    }

    public struct Wardrobe has key {
        id: UID,
        items: vector<Clothing>,
    }

    public fun craft_clothing(
        type_id: u64,
        culture: u8,
        inv: &mut Inventory,
        clock: &Clock,
        ctx: &mut TxContext
    ): Clothing {
        consume_jax(inv, 155, 10, clock); // Alginate/Fabric placeholder
        Clothing {
            id: object::new(ctx),
            type_id,
            culture,
            insulation: 10,
            prestige: 5,
            durability: 100,
        }
    }
    #[test_only]
    public fun destroy_clothing_for_testing(c: Clothing) {
        let Clothing { id, type_id: _, culture: _, insulation: _, prestige: _, durability: _ } = c;
        sui::object::delete(id);
    }
}
