module altriux::altriuxlogistics {
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::clock::Clock;
    use std::option::{Self, Option};

    use altriux::altriuxresources::{Self, Inventory, transfer_jax};
    use altriux::altriuxhero::{Hero, get_current_tile};
    use altriux::altriuxland::{Self, LandRegistry};
    use altriux::altriuxbuildingbase::{BuildingNFT, type_mercado, get_building_tile, get_building_type};

    use altriux::est::{Self, EST, ESTTreasury};
    use altriux::lrc::{Self, LRC};
    use altriux::agc::{Self, AGC, AGCTreasury};
    use altriux::altriuxactionpoints::{Self, ActionPointRegistry};
    use sui::object;

    const AU_COST_TRANSPORT: u64 = 1; // 1 AU per hex

    const E_INSUFFICIENT_FEE: u64 = 101;
    const E_NOT_A_MARKET: u64 = 102;
    const E_MARKET_NOT_HERE: u64 = 103;
    const E_MUST_BE_COLOCATED: u64 = 104;

    // --- Resource Transfers ---

    public fun transfer_jax_contrabandista(
        from_inv: &mut Inventory,
        to_inv: &mut Inventory,
        from_hero: &Hero,
        to_hero: &Hero,
        type_id: u64,
        amount: u64,
        mut payment: Coin<EST>,
        est_treasury: &mut ESTTreasury,
        land_reg: &LandRegistry,
        au_reg: &mut ActionPointRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let from_tile = get_current_tile(from_hero);
        let to_tile = get_current_tile(to_hero);

        let (l1, _, _) = altriuxland::decompose_tile_id(from_tile);
        let (l2, _, _) = altriuxland::decompose_tile_id(to_tile);
        let dist = altriuxland::get_distance_by_ids(land_reg, l1, l2);
        
        let cost = dist * amount;
        
        // === CONSUMO AU ===
        if (dist > 0) {
            let au_cost = dist * AU_COST_TRANSPORT;
            let hero_id = object::id(from_hero);
            altriuxactionpoints::consume_au(au_reg, hero_id, au_cost, b"transport", clock, ctx);
        };
        
        if (cost > 0) {
            assert!(coin::value(&payment) >= cost, E_INSUFFICIENT_FEE);
            let fee_coin = coin::split(&mut payment, cost, ctx);
            est::burn_for_contrabandista(est_treasury, fee_coin);
        };
        
        if (coin::value(&payment) > 0) {
            transfer::public_transfer(payment, tx_context::sender(ctx));
        } else {
            coin::destroy_zero(payment);
        };

        transfer_jax(from_inv, to_inv, type_id, amount, clock);
    }

    public fun transfer_jax_at_market(
        from_inv: &mut Inventory,
        to_inv: &mut Inventory,
        from_hero: &Hero,
        to_hero: &Hero,
        market: &BuildingNFT,
        type_id: u64,
        amount: u64,
        au_reg: &mut ActionPointRegistry,
        clock: &Clock
    ) {
        let from_tile = get_current_tile(from_hero);
        let to_tile = get_current_tile(to_hero);

        assert!(get_building_type(market) == type_mercado(), E_NOT_A_MARKET);
        assert!(get_building_tile(market) == from_tile, E_MARKET_NOT_HERE);
        assert!(from_tile == to_tile, E_MUST_BE_COLOCATED);

        assert!(from_tile == to_tile, E_MUST_BE_COLOCATED);

        // No AU cost for local market transfer?
        // Or small cost? Let's say 0 for local.

        transfer_jax(from_inv, to_inv, type_id, amount, clock);
    }

    // --- Token Transfers (EST) ---

    public fun transfer_est_contrabandista(
        coins: &mut Coin<EST>,
        amount: u64,
        recipient: address,
        from_hero: &Hero,
        to_hero: &Hero,
        treasury: &mut ESTTreasury,
        land_reg: &LandRegistry,
        ctx: &mut TxContext
    ) {
        let from_tile = get_current_tile(from_hero);
        let to_tile = get_current_tile(to_hero);

        let (l1, _, _) = altriuxland::decompose_tile_id(from_tile);
        let (l2, _, _) = altriuxland::decompose_tile_id(to_tile);
        let dist = altriuxland::get_distance_by_ids(land_reg, l1, l2);
        
        let cost = dist * amount;
        
        if (cost > 0) {
            let fee_coin = coin::split(coins, cost, ctx);
            est::burn_for_contrabandista(treasury, fee_coin);
        };

        let transfer_coin = coin::split(coins, amount, ctx);
        transfer::public_transfer(transfer_coin, recipient);
    }

    public fun transfer_est_at_market(
        coins: &mut Coin<EST>,
        amount: u64,
        recipient: address,
        from_hero: &Hero,
        to_hero: &Hero,
        market: &BuildingNFT,
        ctx: &mut TxContext
    ) {
        let from_tile = get_current_tile(from_hero);
        let to_tile = get_current_tile(to_hero);

        assert!(get_building_type(market) == type_mercado(), E_NOT_A_MARKET);
        assert!(get_building_tile(market) == from_tile, E_MARKET_NOT_HERE);
        assert!(from_tile == to_tile, E_MUST_BE_COLOCATED);

        let transfer_coin = coin::split(coins, amount, ctx);
        transfer::public_transfer(transfer_coin, recipient);
    }

    // --- Token Transfers (LRC) ---

    public fun transfer_lrc_contrabandista(
        coins: &mut Coin<LRC>,
        amount: u64,
        recipient: address,
        fee_coins: &mut Coin<EST>,
        from_hero: &Hero,
        to_hero: &Hero,
        est_treasury: &mut ESTTreasury,
        land_reg: &LandRegistry,
        ctx: &mut TxContext
    ) {
        let from_tile = get_current_tile(from_hero);
        let to_tile = get_current_tile(to_hero);

        let (l1, _, _) = altriuxland::decompose_tile_id(from_tile);
        let (l2, _, _) = altriuxland::decompose_tile_id(to_tile);
        let dist = altriuxland::get_distance_by_ids(land_reg, l1, l2);
        
        let cost = dist * amount;
        
        if (cost > 0) {
            let fee_coin = coin::split(fee_coins, cost, ctx);
            est::burn_for_contrabandista(est_treasury, fee_coin);
        };

        let transfer_coin = coin::split(coins, amount, ctx);
        transfer::public_transfer(transfer_coin, recipient);
    }

    public fun transfer_lrc_at_market(
        coins: &mut Coin<LRC>,
        amount: u64,
        recipient: address,
        from_hero: &Hero,
        to_hero: &Hero,
        market: &BuildingNFT,
        ctx: &mut TxContext
    ) {
        let from_tile = get_current_tile(from_hero);
        let to_tile = get_current_tile(to_hero);

        assert!(get_building_type(market) == type_mercado(), E_NOT_A_MARKET);
        assert!(get_building_tile(market) == from_tile, E_MARKET_NOT_HERE);
        assert!(from_tile == to_tile, E_MUST_BE_COLOCATED);

        let transfer_coin = coin::split(coins, amount, ctx);
        transfer::public_transfer(transfer_coin, recipient);
    }

    // --- Token Transfers (AGC) ---

    public fun transfer_agc_contrabandista(
        coins: &mut Coin<AGC>,
        amount: u128,
        recipient: address,
        fee_coins: &mut Coin<EST>,
        from_hero: &Hero,
        to_hero: &Hero,
        est_treasury: &mut ESTTreasury,
        land_reg: &LandRegistry,
        ctx: &mut TxContext
    ) {
        let from_tile = get_current_tile(from_hero);
        let to_tile = get_current_tile(to_hero);

        let (l1, _, _) = altriuxland::decompose_tile_id(from_tile);
        let (l2, _, _) = altriuxland::decompose_tile_id(to_tile);
        let dist = (altriuxland::get_distance_by_ids(land_reg, l1, l2) as u128);
        
        let cost = dist * amount;
        
        if (cost > 0) {
            let fee_coin = coin::split(fee_coins, (cost as u64), ctx);
            est::burn_for_contrabandista(est_treasury, fee_coin);
        };

        let transfer_coin = coin::split(coins, (amount as u64), ctx);
        transfer::public_transfer(transfer_coin, recipient);
    }

    public fun transfer_agc_at_market(
        coins: &mut Coin<AGC>,
        amount: u128,
        recipient: address,
        from_hero: &Hero,
        to_hero: &Hero,
        market: &BuildingNFT,
        ctx: &mut TxContext
    ) {
        let from_tile = get_current_tile(from_hero);
        let to_tile = get_current_tile(to_hero);

        assert!(get_building_type(market) == type_mercado(), E_NOT_A_MARKET);
        assert!(get_building_tile(market) == from_tile, E_MARKET_NOT_HERE);
        assert!(from_tile == to_tile, E_MUST_BE_COLOCATED);

        let transfer_coin = coin::split(coins, (amount as u64), ctx);
        transfer::public_transfer(transfer_coin, recipient);
    }
}
