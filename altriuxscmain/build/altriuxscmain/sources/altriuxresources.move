#[allow(unused_const, duplicate_alias, unused_use)]
module altriux::altriuxresources {
    use sui::object::{UID};
    use sui::tx_context::TxContext;
    use sui::bag::{Self, Bag};
    use sui::table::{Self, Table};
    use sui::clock::{Clock};
    use altriux::altriuxutils;
// use altriux::altriuxtextiles; // MOVED TO GAMEPLAY

    use sui::dynamic_field;


// use altriux::altriuxitems; // MOVED TO GAMEPLAY


    const E_EXPIRED: u64 = 101;
    const E_INSUFFICIENT: u64 = 102;
    const E_OVERWEIGHT: u64 = 103;
    const E_OVERVOLUME: u64 = 104;

    const JAX_WEIGHT_KG: u64 = 20;
    const JIX_VOLUME_L: u64 = 20;
    
    const GRAMS_PER_JAX: u64 = 20000;
    const ML_PER_JIX: u64 = 20000;
    
    const MAX_WEIGHT_GRAMS: u64 = 100000000; // 5,000 Jax
    const MAX_VOLUME_ML: u64 = 100000000;    // 5,000 Jix

    // --- Wood Resources (135-154) ---
    const MADERA_PRIMERA: u64 = 135;
    const MADERA_SEGUNDA: u64 = 136;
    const TRONCO_PREMIUM: u64 = 137;
    const TRONCO_ESTANDAR: u64 = 138;
    const TRONCO_ALTO: u64 = 139;
    const MADERA_DURA: u64 = 153;
    const MADERA_BLANDA: u64 = 154;
    // (Processed wood moved to gameplay)


    // --- Vegetable Extracts & Resin (209-210) ---
    const BREA_VEGETAL: u64 = 209;
    const TANINO: u64 = 210;
    const JAX_STRAW: u64 = 215; // Heno/Paja
    const JAX_PULP: u64 = 216;  // Rastrojo/Pulpa

    // (Ship, Writing Materials, and Industrial items moved to gameplay)


    // === Textile IDs (155-207) ===
    const ALGODON_SIN_HILAR: u64 = 155;
    const LINO_SIN_HILAR: u64 = 156;
    const CANAMO_SIN_HILAR: u64 = 157;
    const ESTOPAS_SEGUNDA: u64 = 158;
    const LANA_SIN_HILAR: u64 = 159;
    const SEDA_SIN_HILAR: u64 = 160;
    const YAK_SIN_HILAR_FINO: u64 = 161;
    const YAK_SIN_HILAR_GRUESO: u64 = 162;
    const CACHMIRA_SIN_HILAR: u64 = 163;
    const ALPACA_SIN_HILAR: u64 = 164;
    const LANA_BURRO: u64 = 165;
    // (Hilo and Tela moved to gameplay)


    
    const TINTE_OCRE_ROJO: u64 = 201;
    const MORDIENTE_HIERRO: u64 = 205;

    // --- Special items (raw) ---
    const MONEDA_ORO: u64 = 226;
    // (Meat moved to gameplay)


    public struct Inventory has key, store {
        id: UID,
        owner: address,
        items: Bag,  
        expiry: Table<u64, u64>,
        total_weight_grams: u64,
        total_volume_ml: u64,
    }

    public struct Sail has key, store {
        id: UID,
        durability: u64,
        size: u64, // Small, Medium, Large
    }

    public fun create_sail(size: u64, ctx: &mut TxContext): Sail {
        Sail {
            id: object::new(ctx),
            durability: 100,
            size
        }
    }

    public fun create_inventory(owner: address, ctx: &mut TxContext): Inventory {
        Inventory {
            id: object::new(ctx),
            owner,
            items: bag::new(ctx),
            expiry: table::new(ctx),
            total_weight_grams: 0,
            total_volume_ml: 0,
        }
    }

    public fun add_jax(inv: &mut Inventory, type_id: u64, amount: u64, expiry_days: u64, clock: &Clock) {
        if (!bag::contains(&inv.items, type_id)) {
             bag::add(&mut inv.items, type_id, 0u64);
             table::add(&mut inv.expiry, type_id, 0u64);
        };
        
        let (w_unit, v_unit) = if (type_id == MONEDA_ORO) {
            (20, 1)
        } else {
            (GRAMS_PER_JAX, ML_PER_JIX)
        };

        let weight_to_add = amount * w_unit;
        let volume_to_add = amount * v_unit;
        
        assert!(inv.total_weight_grams + weight_to_add <= MAX_WEIGHT_GRAMS, E_OVERWEIGHT);
        assert!(inv.total_volume_ml + volume_to_add <= MAX_VOLUME_ML, E_OVERVOLUME);
        
        let current = bag::borrow_mut<u64, u64>(&mut inv.items, type_id);
        *current = *current + amount;
        inv.total_weight_grams = inv.total_weight_grams + weight_to_add;
        inv.total_volume_ml = inv.total_volume_ml + volume_to_add;
        
        let now = altriuxutils::get_timestamp(clock);
        let expiry = if (expiry_days > 0) { now + (expiry_days * 86400) } else { 0 };
        
        let exp_mut = table::borrow_mut(&mut inv.expiry, type_id);
        *exp_mut = expiry;
    }

    public fun consume_jax(inv: &mut Inventory, type_id: u64, amount: u64, clock: &Clock) {
        if (!bag::contains(&inv.items, type_id)) {
            abort E_INSUFFICIENT
        };
        let expiry = *table::borrow(&inv.expiry, type_id);
        assert!(altriuxutils::get_timestamp(clock) < expiry || expiry == 0, E_EXPIRED);
        
        let current = bag::borrow_mut<u64, u64>(&mut inv.items, type_id);
        assert!(*current >= amount, E_INSUFFICIENT);
        *current = *current - amount;

        let (w_unit, v_unit) = if (type_id == MONEDA_ORO) {
            (20, 1)
        } else {
            (GRAMS_PER_JAX, ML_PER_JIX)
        };

        let weight_to_remove = amount * w_unit;
        let volume_to_remove = amount * v_unit;
        
        if (inv.total_weight_grams >= weight_to_remove) {
            inv.total_weight_grams = inv.total_weight_grams - weight_to_remove;
        } else {
            inv.total_weight_grams = 0;
        };
        
        if (inv.total_volume_ml >= volume_to_remove) {
            inv.total_volume_ml = inv.total_volume_ml - volume_to_remove;
        } else {
            inv.total_volume_ml = 0;
        };
    }

    public fun update_external_weight_volume(inv: &mut Inventory, weight_grams: u64, volume_ml: u64, is_addition: bool) {
        if (is_addition) {
            assert!(inv.total_weight_grams + weight_grams <= MAX_WEIGHT_GRAMS, E_OVERWEIGHT);
            assert!(inv.total_volume_ml + volume_ml <= MAX_VOLUME_ML, E_OVERVOLUME);
            inv.total_weight_grams = inv.total_weight_grams + weight_grams;
            inv.total_volume_ml = inv.total_volume_ml + volume_ml;
        } else {
            if (inv.total_weight_grams >= weight_grams) {
                inv.total_weight_grams = inv.total_weight_grams - weight_grams;
            } else {
                inv.total_weight_grams = 0;
            };
            if (inv.total_volume_ml >= volume_ml) {
                inv.total_volume_ml = inv.total_volume_ml - volume_ml;
            } else {
                inv.total_volume_ml = 0;
            };
        };
    }

    public(package) fun transfer_jax(from: &mut Inventory, to: &mut Inventory, type_id: u64, amount: u64, clock: &Clock) {
        consume_jax(from, type_id, amount, clock);
        let expiry = *table::borrow(&from.expiry, type_id);
        add_jax(to, type_id, amount, 0, clock);
        if (expiry > 0) {
            let now = altriuxutils::get_timestamp(clock);
            let days_left = if (expiry > now) (expiry - now) / 86400 else 0;
            let exp_to = table::borrow_mut(&mut to.expiry, type_id);
            *exp_to = if (days_left > 0) now + (days_left * 86400) else 0;
        }
    }
    
    public fun total_weight(inv: &Inventory): u64 { inv.total_weight_grams }
    public fun total_volume(inv: &Inventory): u64 { inv.total_volume_ml }
    public fun max_weight(): u64 { MAX_WEIGHT_GRAMS }
    public fun max_volume(): u64 { MAX_VOLUME_ML }
    public fun grams_per_jax(): u64 { GRAMS_PER_JAX }
    public fun ml_per_jix(): u64 { ML_PER_JIX }

    // (Production logic and book id getters moved to gameplay)


    #[test_only]
    public fun destroy_inventory_for_testing(inv: Inventory) {
        let Inventory {
            id,
            owner: _,
            items,
            expiry,
            total_weight_grams: _,
            total_volume_ml: _,
        } = inv;
        
        let i = 1u64;
        while (i <= 362) {
            if (sui::bag::contains(&items, i)) {
                sui::bag::remove<u64, u64>(&mut items, i);
            };
            if (sui::table::contains(&expiry, i)) {
                sui::table::remove<u64, u64>(&mut expiry, i);
            };
            i = i + 1;
        };
        
        sui::bag::destroy_empty(items);
        sui::table::destroy_empty(expiry);
        object::delete(id);
    }
    public fun has_jax(inv: &Inventory, resource_id: u64, amount: u64): bool {
        if (!bag::contains(&inv.items, resource_id)) {
            return false
        };
        let current_amount = *bag::borrow<u64, u64>(&inv.items, resource_id);
        current_amount >= amount
    }

    public fun get_total_weight(inv: &Inventory): u64 {
        inv.total_weight_grams
    }

    public fun get_total_volume(inv: &Inventory): u64 {
        inv.total_volume_ml
    }

    public fun get_item_expiry(inv: &Inventory, resource_id: u64): u64 {
        if (!table::contains(&inv.expiry, resource_id)) {
            return 0
        };
        *table::borrow(&inv.expiry, resource_id)
    }

    public fun borrow_uid(inv: &Inventory): &UID {
        &inv.id
    }

    public fun borrow_uid_mut(inv: &mut Inventory): &mut UID {
        &mut inv.id
    }

    // Getters for textiles (raw only)
    public fun id_lino_sin_hilar(): u64 { LINO_SIN_HILAR }
    public fun id_lana_sin_hilar(): u64 { LANA_SIN_HILAR }
    public fun id_mordiente_hierro(): u64 { MORDIENTE_HIERRO }
}
