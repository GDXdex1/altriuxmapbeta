#[allow(unused_variable, duplicate_alias, unused_use)]
module altriux::altriuxtrade {
    use sui::object::{Self, UID, ID};
    use sui::clock::{Self, Clock};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::table::{Self, Table};
    use sui::event;
    use sui::dynamic_object_field as dof;
    use sui::dynamic_field as df;
    use altriux::altriuxresources::{Self, Inventory, consume_jax};
    use altriux::altriuxbuildingbase::{Self, BuildingNFT};
    use altriux::altriuxlocation::{Self, ResourceLocation};
    use altriux::lrc::{Self, LRC, LRCTreasury};
    use altriux::altriuxutils;

    // === ERRORS ===
    const E_INVALID_MARKET: u64 = 101;
    const E_LOCATIONS_MISMATCH: u64 = 102;
    const E_INSUFFICIENT_FUNDS: u64 = 103;
    const E_PACKAGE_NOT_FOUND: u64 = 104;
    const E_NOT_READY: u64 = 105;
    const E_NOT_RECIPIENT: u64 = 106;
    const E_NOT_SENDER: u64 = 107;

    // === CONSTANTS ===
    const TRANSIT_HOURS_PER_50KM: u64 = 3;
    const HOUR_MS: u64 = 3600000;
    const DISTANCE_UNIT: u64 = 50;

    // === STRUCTS ===

    /// Shared registry for all in-transit packages
    public struct TransitRegistry has key {
        id: UID,
        pending_jax: Table<ID, TransitPackageJAX>,
        next_package_id: u64
    }

    /// Package for JAX resources in transit
    public struct TransitPackageJAX has store {
        package_id: u64,
        resource_id: u64,
        amount: u64,
        from: address,
        to: address,
        unlock_time: u64,
        distance: u64
    }

    /// Event emitted when a transit transfer is initiated
    public struct TransitInitiated has copy, drop {
        package_id: u64,
        from: address,
        to: address,
        resource_id: u64,
        amount: u64,
        unlock_time: u64,
        distance: u64,
        lrc_paid: u64
    }

    /// Event emitted when a package is claimed
    public struct TransitClaimed has copy, drop {
        package_id: u64,
        recipient: address,
        resource_id: u64,
        amount: u64
    }

    /// Event emitted when a package is cancelled
    public struct TransitCancelled has copy, drop {
        package_id: u64,
        sender: address,
        resource_id: u64,
        amount: u64
    }

    // === INIT ===
    
    fun init(ctx: &mut TxContext) {
        let registry = TransitRegistry {
            id: object::new(ctx),
            pending_jax: table::new(ctx),
            next_package_id: 1
        };
        transfer::share_object(registry);
    }

    // === HELPER FUNCTIONS ===

    /// Calculate transit time in milliseconds based on distance
    fun calculate_transit_time(distance: u64): u64 {
        let units = distance / DISTANCE_UNIT;
        units * TRANSIT_HOURS_PER_50KM * HOUR_MS
    }

    // === TRANSIT FUNCTIONS ===

    /// Initiate a transit transfer with time lock and LRC penalty
    public fun init_transit_transfer(
        registry: &mut TransitRegistry,
        from: &mut Inventory,
        from_loc: &ResourceLocation,
        to_loc: &ResourceLocation,
        to_address: address,
        resource_id: u64,
        amount: u64,
        lrc_treasury: &mut LRCTreasury,
        mut lrc_payment: Coin<LRC>,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        let sender = tx_context::sender(ctx);
        
        // Calculate distance
        let dist = (altriuxlocation::hex_distance(
            altriuxlocation::get_hq(from_loc), altriuxlocation::get_hr(from_loc),
            altriuxlocation::get_hq(to_loc), altriuxlocation::get_hr(to_loc)
        ) as u64);

        // Calculate LRC penalty: 1 LRC per JAX per 50 hexes
        let penalty_ratio = dist / DISTANCE_UNIT;
        let lrc_cost = penalty_ratio * amount;

        if (lrc_cost > 0) {
            assert!(coin::value(&lrc_payment) >= lrc_cost, E_INSUFFICIENT_FUNDS);
            let to_burn = coin::split(&mut lrc_payment, lrc_cost, ctx);
            lrc::burn(lrc_treasury, to_burn);
        };

        // Return remaining LRC
        if (coin::value(&lrc_payment) > 0) {
            transfer::public_transfer(lrc_payment, sender);
        } else {
            coin::destroy_zero(lrc_payment);
        };

        // Calculate transit time
        let transit_time = calculate_transit_time(dist);
        let now = altriuxutils::get_timestamp(clock);
        let unlock_time = now + transit_time;

        // Create package
        let package_id = registry.next_package_id;
        registry.next_package_id = package_id + 1;

        let package = TransitPackageJAX {
            package_id,
            resource_id,
            amount,
            from: sender,
            to: to_address,
            unlock_time,
            distance: dist
        };

        let pkg_uid = object::new(ctx);
        let pkg_id = object::uid_to_inner(&pkg_uid);
        
        // Lock resources in transit
        altriuxresources::consume_jax(from, resource_id, amount, clock);
        
        // Store package
        table::add(&mut registry.pending_jax, pkg_id, package);
        object::delete(pkg_uid);

        // Emit event
        event::emit(TransitInitiated {
            package_id,
            from: sender,
            to: to_address,
            resource_id,
            amount,
            unlock_time,
            distance: dist,
            lrc_paid: lrc_cost
        });

        pkg_id
    }

    /// Claim a transit package after unlock time
    public fun claim_transit_package(
        registry: &mut TransitRegistry,
        to: &mut Inventory,
        package_id: ID,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(table::contains(&registry.pending_jax, package_id), E_PACKAGE_NOT_FOUND);
        
        let TransitPackageJAX {
            package_id: event_package_id,
            resource_id,
            amount,
            from: _,
            to: recipient,
            unlock_time,
            distance: _
        } = table::remove(&mut registry.pending_jax, package_id);
        
        let sender = tx_context::sender(ctx);
        
        // Verify recipient
        assert!(recipient == sender, E_NOT_RECIPIENT);
        
        // Verify time
        let now = altriuxutils::get_timestamp(clock);
        assert!(now >= unlock_time, E_NOT_READY);

        // Transfer resources to recipient
        altriuxresources::add_jax(to, resource_id, amount, 0, clock);

        // Emit event
        event::emit(TransitClaimed {
            package_id: event_package_id,
            recipient: sender,
            resource_id,
            amount
        });
    }

    /// Cancel a transit transfer (sender only, before claim)
    public fun cancel_transit_transfer(
        registry: &mut TransitRegistry,
        from: &mut Inventory,
        package_id: ID,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(table::contains(&registry.pending_jax, package_id), E_PACKAGE_NOT_FOUND);
        
        let TransitPackageJAX {
            package_id: event_package_id,
            resource_id,
            amount,
            from: pkg_sender,
            to: _,
            unlock_time: _,
            distance: _
        } = table::remove(&mut registry.pending_jax, package_id);
        
        let sender = tx_context::sender(ctx);
        
        // Verify sender
        assert!(pkg_sender == sender, E_NOT_SENDER);

        // Return resources to sender (LRC penalty is NOT refunded)
        altriuxresources::add_jax(from, resource_id, amount, 0, clock);

        // Emit event
        event::emit(TransitCancelled {
            package_id: event_package_id,
            sender,
            resource_id,
            amount
        });
    }

    // === OBJECT TRANSIT (Dynamic Fields) ===

    public struct TransitMetadata has store, drop {
        package_id: u64,
        from: address,
        to: address,
        unlock_time: u64,
        distance: u64
    }

    public struct ObjectTransitInitiated has copy, drop {
        package_id: u64,
        object_id: ID,
        from: address,
        to: address,
        unlock_time: u64,
        lrc_paid: u64
    }

    public struct ObjectTransitClaimed has copy, drop {
        package_id: u64,
        object_id: ID,
        recipient: address
    }

    /// Initiate transit for any object (T must have store)
    public fun init_object_transit<T: key + store>(
        registry: &mut TransitRegistry,
        obj: T,
        from_loc: &ResourceLocation,
        to_loc: &ResourceLocation,
        to_address: address,
        lrc_cost_per_unit: u64, // Usually passed as 0 if handle by caller, but here we calculate based on "weight" logic if needed?
        // Actually, objects usually pay flat rate or based on weight. 
        // For simplicity and to match plan: "Apply LRC penalties based on distance".
        // Let's assume passed amount of LRC is sufficient for the object "weight" or "value".
        // But implementation plan says "Use dynamic fields on shared TransitRegistry".
        lrc_treasury: &mut LRCTreasury,
        mut lrc_payment: Coin<LRC>,
        clock: &Clock,
        ctx: &mut TxContext
    ): u64 {
        let sender = tx_context::sender(ctx);
        let obj_id = object::id(&obj);
        
        // Calculate distance
        let dist = (altriuxlocation::hex_distance(
            altriuxlocation::get_hq(from_loc), altriuxlocation::get_hr(from_loc),
            altriuxlocation::get_hq(to_loc), altriuxlocation::get_hr(to_loc)
        ) as u64);

        // Calculate LRC penalty
        let penalty_ratio = if (dist < DISTANCE_UNIT) 1 else dist / DISTANCE_UNIT;
        let lrc_cost = penalty_ratio * lrc_cost_per_unit; 

        if (lrc_cost > 0) {
            assert!(coin::value(&lrc_payment) >= lrc_cost, E_INSUFFICIENT_FUNDS);
            let to_burn = coin::split(&mut lrc_payment, lrc_cost, ctx);
            lrc::burn(lrc_treasury, to_burn);
        };

        if (coin::value(&lrc_payment) > 0) {
            transfer::public_transfer(lrc_payment, sender);
        } else {
            coin::destroy_zero(lrc_payment);
        };

        let transit_time = calculate_transit_time(dist);
        let now = altriuxutils::get_timestamp(clock);
        let unlock_time = now + transit_time;

        let package_id = registry.next_package_id;
        registry.next_package_id = package_id + 1;

        let metadata = TransitMetadata {
            package_id,
            from: sender,
            to: to_address,
            unlock_time,
            distance: dist
        };

        // Add to registry via dynamic field
        // Key: package_id (u64) -> Value: Object
        // We need a stable key. Let's use package_id.
        // Wait, standard `init_transit_transfer` uses `ID` of a deleted UID as key in table?
        // No, it uses `pkg_id` (ID) as key.
        // For objects, we can use `package_id` (u64) wrapped in a struct or just u64 if we use dof.
        // But `pending_jax` is Table<ID, ...>. 
        // Let's use `dof` on `registry.id`.
        
        // We attach the object T
        
        dof::add(&mut registry.id, package_id, obj);
        // We attach metadata
        // Key: vector<u8> b"meta" + package_id? No, simple Wrapper
        df::add(&mut registry.id, package_id, metadata);

        event::emit(ObjectTransitInitiated {
            package_id,
            object_id: obj_id,
            from: sender,
            to: to_address,
            unlock_time,
            lrc_paid: lrc_cost
        });

        package_id
    }

    public fun claim_object_transit<T: key + store>(
        registry: &mut TransitRegistry,
        package_id: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): T {
        use sui::dynamic_object_field as dof;
        
        assert!(df::exists_(&registry.id, package_id), E_PACKAGE_NOT_FOUND);

        let metadata: TransitMetadata = df::remove(&mut registry.id, package_id);
        let obj: T = dof::remove(&mut registry.id, package_id);
        
        let sender = tx_context::sender(ctx);
        assert!(metadata.to == sender, E_NOT_RECIPIENT);
        
        let now = altriuxutils::get_timestamp(clock);
        assert!(now >= metadata.unlock_time, E_NOT_READY);

        event::emit(ObjectTransitClaimed {
            package_id,
            object_id: object::id(&obj),
            recipient: sender
        });

        obj
    }

    /// Direct smuggled transfer (instant, with LRC penalty)
    public fun transfer_smuggled(
        from: &mut Inventory,
        to: &mut Inventory,
        from_loc: &ResourceLocation,
        to_loc: &ResourceLocation,
        resource_id: u64,
        amount: u64,
        lrc_treasury: &mut LRCTreasury,
        mut lrc_payment: Coin<LRC>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Calculate distance
        let dist = (altriuxlocation::hex_distance(
            altriuxlocation::get_hq(from_loc), altriuxlocation::get_hr(from_loc),
            altriuxlocation::get_hq(to_loc), altriuxlocation::get_hr(to_loc)
        ) as u64);

        // LRC penalty: 1 LRC per JAX per 50 hexes
        let penalty_ratio = dist / DISTANCE_UNIT;
        let lrc_cost = penalty_ratio * amount;

        if (lrc_cost > 0) {
            assert!(coin::value(&lrc_payment) >= lrc_cost, E_INSUFFICIENT_FUNDS);
            let to_burn = coin::split(&mut lrc_payment, lrc_cost, ctx);
            lrc::burn(lrc_treasury, to_burn);
        };

        // Return remaining LRC
        if (coin::value(&lrc_payment) > 0) {
            transfer::public_transfer(lrc_payment, tx_context::sender(ctx));
        } else {
            coin::destroy_zero(lrc_payment);
        };

        // Instant transfer
        altriuxresources::transfer_jax(from, to, resource_id, amount, clock);
    }

    /// Market-based trade (no penalty, instant)
    public fun trade_via_market(
        from: &mut Inventory,
        to: &mut Inventory,
        resource_id: u64,
        amount: u64,
        market_building: &BuildingNFT,
        clock: &Clock,
        _ctx: &mut TxContext
    ) {
        let type_id = altriuxbuildingbase::get_building_type(market_building);
        let valid_type = type_id == altriuxbuildingbase::type_mercado() || 
                         type_id == altriuxbuildingbase::type_gran_mercado();
        
        assert!(valid_type, E_INVALID_MARKET);
        
        altriuxresources::transfer_jax(from, to, resource_id, amount, clock);
    }

    /// Local transfer (same tile, no penalty, instant)
    public fun transfer_local(
        from: &mut Inventory,
        to: &mut Inventory,
        from_loc: ResourceLocation,
        to_loc: ResourceLocation,
        resource_id: u64,
        amount: u64,
        clock: &Clock,
        _ctx: &mut TxContext
    ) {
        // Verify same coordinates
        assert!(
            altriuxlocation::get_hq(&from_loc) == altriuxlocation::get_hq(&to_loc) &&
            altriuxlocation::get_hr(&from_loc) == altriuxlocation::get_hr(&to_loc) &&
            altriuxlocation::get_sq(&from_loc) == altriuxlocation::get_sq(&to_loc) &&
            altriuxlocation::get_sr(&from_loc) == altriuxlocation::get_sr(&to_loc),
            E_LOCATIONS_MISMATCH
        );

        altriuxresources::transfer_jax(from, to, resource_id, amount, clock);
    }

    // === GETTERS ===

    public fun get_package_unlock_time(registry: &TransitRegistry, package_id: ID): u64 {
        let package = table::borrow(&registry.pending_jax, package_id);
        package.unlock_time
    }

    public fun get_package_recipient(registry: &TransitRegistry, package_id: ID): address {
        let package = table::borrow(&registry.pending_jax, package_id);
        package.to
    }

    public fun get_package_amount(registry: &TransitRegistry, package_id: ID): u64 {
        let package = table::borrow(&registry.pending_jax, package_id);
        package.amount
    }
}
