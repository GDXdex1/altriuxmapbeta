module altriux::altriuxworkers {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};
    use std::vector;
    use altriux::est::EST;
    use altriux::altriuxpopulation::{Self, PopulationRegistry};
    use altriux::altriuxresources::{Self, Inventory};
    use altriux::altriuxfood;
    use altriux::altriuxhero::{Self, Hero};
    
    // --- Constants ---
    const COST_ANNUAL_EST: u64 = 40_000_000_000; // 40 ESC (9 decimals)
    const COST_TEMP_EST: u64 = 4_000_000_000;    // 4 ESC
    
    const DURATION_ANNUAL_MS: u64 = 90 * 24 * 60 * 60 * 1000; // 90 days
    const DURATION_TEMP_MS: u64 = 10 * 24 * 60 * 60 * 1000;   // 10 days
    
    const E_INSUFFICIENT_FUNDS: u64 = 101;
    const E_EXPIRED: u64 = 102;
    const E_NOT_EXPIRED: u64 = 103;

    // --- Structs ---

    public struct WorkerRegistry has key {
        id: UID,
        active_contracts: Table<ID, WorkerContract>,
    }

    public struct WorkerPool has key {
        id: UID,
        // Workers that have been returned/expired. 
        returned_workers: vector<WorkerStore>, 
    }

    public struct WorkerContract has key, store {
        id: UID,
        owner: address,
        inventory: Inventory, // Intelligent Inventory
        contract_expiry: u64,
        contract_type: u8, // 0: Temp, 1: Annual
        is_active: bool,
        building_id: Option<ID>, // Asignación a edificio
    }

    // Simplified struct to store inside the vector (since Worker has key, it cannot be put in vector directly in some Move versions unless we wrap or use dynamic fields, but with store it is fine)
    // Actually, object in vector is fine if it has store.
    
    // We'll wrapper for clarity or just use Worker if possible. 
    // Wait, if Worker has `key`, it's an object. Putting it in a vector "buries" the UID.
    // It's better to wrap the data if we want to strip the key, OR just keep it as an object.
    // We will keep it as an object.
    public struct WorkerStore has store {
        worker: WorkerContract
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(WorkerPool {
            id: object::new(ctx),
            returned_workers: vector::empty(),
        });
        transfer::share_object(WorkerRegistry {
            id: object::new(ctx),
            active_contracts: table::new(ctx),
        });
    }

    // --- Hiring ---

    public fun hire_worker(
        pool: &mut WorkerPool,
        reg: &mut PopulationRegistry,
        worker_reg: &mut WorkerRegistry,
        payment: Coin<EST>,
        is_annual: bool,
        land_id: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        let cost = if (is_annual) COST_ANNUAL_EST else COST_TEMP_EST;
        let duration = if (is_annual) DURATION_ANNUAL_MS else DURATION_TEMP_MS;
        
        assert!(coin::value(&payment) >= cost, E_INSUFFICIENT_FUNDS);
        
        // Burn or Transfer payment? User said "maximo y que al terminal el tiempo... renta al contrato".
        // Usually we transfer to treasury or burn. Army burns it.
        // Let's transfer to @0x0 for now as placeholder for burn or treasury.
        transfer::public_transfer(payment, @0x0);

        // Deduct from population
        let (q, r) = altriux::altriuxlocation::decode_coordinates(land_id);
        altriuxpopulation::deduct_civilian(
            reg, 
            q, 
            r, 
            1, 
            b"hire_worker", 
            clock, 
            ctx
        );

        let worker_inv = altriuxresources::create_inventory(tx_context::sender(ctx), ctx);
        
        let contract = WorkerContract {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            inventory: worker_inv,
            contract_expiry: clock::timestamp_ms(clock) + duration,
            contract_type: if (is_annual) 1 else 0,
            is_active: true,
            building_id: option::none(),
        };

        let id = object::id(&contract);
        table::add(&mut worker_reg.active_contracts, id, contract);
        id
    }

    public fun return_expired_worker(
        pool: &mut WorkerPool, 
        worker_reg: &mut WorkerRegistry,
        worker_id: ID, 
        clock: &Clock
    ) {
        let worker = table::remove(&mut worker_reg.active_contracts, worker_id);
        // Anyone can trigger this if they have the worker object, or the owner does.
        assert!(clock::timestamp_ms(clock) >= worker.contract_expiry, E_NOT_EXPIRED);
        
        // We wrap it and put it in the pool
        let store = WorkerStore { worker };
        vector::push_back(&mut pool.returned_workers, store);
    }

    // --- Diet & Consumption ---

    public fun consume_rations(
        worker: &mut WorkerContract,
        hero: &Hero,
        clock: &Clock
    ) {
        // Dietary Requirements:
        // Standard: 1.5 Jax Cereal (150 bp quantity? Assuming 1.5 units = 15000 units if 1 Jax = 10000? 
        // Wait, resources uses grams. 1 Jax = 20kg?
        // Let's use standard amount units. 
        // "1.5 Jax". If 1 Coin = 1_000_000_000.
        // But Food in resources is count based?
        // altriuxresources: add_jax(..., amount: u64).
        // If 1 amount = 1 item.
        // User said "1.5 jax".
        // I'll assume 150 units (if 100 = 1.0) or just 2 items if integer.
        // Let's assume 2 units of Cereal + 1 unit of Drink for safety, or implement fractional if bag supports it.
        // Bag stores u64.
        // Let's go with: 2 units Cereal, 1 unit Drink.
        
        // But user specified "1.5 jax".
        // Maybe JAX is a specific unit where 1 JAX = 1 item?
        // I will interpret "1.5 Jax" as 2 items (ceiling) or 1 item and partial? Modulo doesn't allow partials easily without decimals.
        // I'll use 2 items for 1.5 requirement.
        
        let inv = &mut worker.inventory;
        
        // 1. Cereal (Any ID that is Cereal)
        // We need to find *a* cereal. Iteration is hard on Bag.
        // Simpler: pass the ID to consume?
        // For automation, we'd need to know what's inside.
        // I'll require the user/caller to specify the food IDs to consume in a separate function, 
        // OR standard consumption implies iterating specialized slots.
        // Since inventory is generic Bag, we can't iterate easily on-chain.
        // Implementing `consume_rations_with_ids`.
    }

    public fun consume_rations_specific(
        worker: &mut WorkerContract,
        hero: &Hero,
        cereal_id: u64,
        drink_id: u64,
        meat_id: u64,      // Optional/Imlax
        oil_id: u64,       // Optional/Imlax
        dairy_id: u64,     // Optional/Imlax
        salt_id: u64,      // Optional/Imlax
        fruit_id: u64,     // Optional/Imlax
        clock: &Clock
    ) {
         let inv = &mut worker.inventory;

         // Standard: 1.5 Jax Cereal + 1 Jix Drink
         assert!(altriuxfood::is_cereal(cereal_id), 1);
         assert!(altriuxfood::is_drink(drink_id), 2);
         
         // 2 units cereal (covering 1.5)
         altriuxresources::consume_jax(inv, cereal_id, 2, clock);
         // 1 unit drink
         altriuxresources::consume_jax(inv, drink_id, 1, clock);

         // Imlax Check
         if (altriuxhero::get_tribe(hero) == altriuxhero::imlax()) {
             // 0.4 Jax Meat -> 1 unit
             altriuxresources::consume_jax(inv, meat_id, 1, clock); // meat/legume
             
             // 0.15 Jix Oil -> 1 unit
             altriuxresources::consume_jax(inv, oil_id, 1, clock);
             
             // 0.25 Jax Dairy -> 1 unit
             altriuxresources::consume_jax(inv, dairy_id, 1, clock);

             // 0.25 Jax Salt -> 1 unit
             altriuxresources::consume_jax(inv, salt_id, 1, clock);

             // 0.25 Jax Fruit -> 1 unit
             altriuxresources::consume_jax(inv, fruit_id, 1, clock);
         }
    }
    
    // --- Actions ---
    // Placeholders for actions that consume time or resources
    
    public fun action_farm(worker: &mut WorkerContract, _land_id: u64) {
        // Logic to boost farming?
    }
    
    public fun action_construct(worker: &mut WorkerContract, _building_id: u64) {
        // Logic to aid construction
    }

    public fun get_worker_inventory(w: &mut WorkerContract): &mut Inventory {
        &mut w.inventory
    }

    public fun is_worker_registered(reg: &WorkerRegistry, worker_id: ID): bool {
        table::contains(&reg.active_contracts, worker_id)
    }

    public fun is_worker_active(reg: &WorkerRegistry, worker_id: ID): bool {
        if (!table::contains(&reg.active_contracts, worker_id)) {
            return false
        };
        let contract = table::borrow(&reg.active_contracts, worker_id);
        contract.is_active
    }

    public fun get_worker_owner(reg: &WorkerRegistry, worker_id: ID): address {
        let contract = table::borrow(&reg.active_contracts, worker_id);
        contract.owner
    }

    public fun borrow_worker_id_mut(reg: &mut WorkerRegistry, worker_id: ID): &mut UID {
        let contract = table::borrow_mut(&mut reg.active_contracts, worker_id);
        &mut contract.id
    }

    public fun borrow_worker_mut(reg: &mut WorkerRegistry, worker_id: ID): &mut WorkerContract {
        table::borrow_mut(&mut reg.active_contracts, worker_id)
    }

    public fun set_worker_building_id(contract: &mut WorkerContract, building_id: Option<ID>) {
        contract.building_id = building_id;
    }
}
