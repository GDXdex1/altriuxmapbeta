module altriux::est {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::clock::{Self, Clock};
    use sui::event;
    use std::option;
    use altriux::altriuxresources::{Self, Inventory};

    public struct EST has drop {}
    

    const ADMIN: address = @0x554a2392980b0c3e4111c9a0e8897e632d41847d04cbd41f9e081e49ba2eb04a;

    const DECIMALS: u8 = 0;
    const MAX_SUPPLY: u128 = 200_000_000_000; // 200B

    public struct AdminCap has key, store { id: UID }

    public struct ESTTreasury has key {
        id: UID,
        cap: TreasuryCap<EST>,
        minted: u128,
        remint_pool: u128, // Pool of burned tokens available for reminting
        paused: bool,
    }

    public struct TokensMinted has copy, drop {
        amount: u128,
        recipient: address,
        timestamp: u64,
    }

    fun init(witness: EST, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<EST>(
            witness,
            DECIMALS,
            b"EST",
            b"Esterlix Silver Coin",
            b"Silver coin (18.5g Ag, 1.5g Cu)",
            option::none(),
            ctx
        );
        transfer::public_freeze_object(metadata);
        let treasury = ESTTreasury {
            id: object::new(ctx),
            cap: treasury_cap,
            minted: 0,
            remint_pool: 0,
            paused: false,
        };
        transfer::share_object(treasury);
        transfer::transfer(AdminCap { id: object::new(ctx) }, ADMIN);
    }
    public fun mint(
        _: &AdminCap, 
        treasury: &mut ESTTreasury, 
        inv: &mut Inventory,
        amount: u64, 
        recipient: address, 
        clock: &Clock, 
        ctx: &mut TxContext
    ) {
        assert!(!treasury.paused, 1);
        let amount_u128 = (amount as u128);
        assert!(treasury.minted + amount_u128 <= MAX_SUPPLY, 2);
        
        let sender = tx_context::sender(ctx);
        let is_admin = (sender == @0x554a2392980b0c3e4111c9a0e8897e632d41847d04cbd41f9e081e49ba2eb04a || sender == @0xf2a0919d5a077df0fe4317f008729072fd9e39076b8b087ef8f48bacf00ded0c);

        if (!is_admin) {
            // EST: 18.5g Silver, 1.5g Copper per unit
            // EST: 18.5g Silver, 1.5g Copper per unit
            let ag_grams = amount * 1850 / 100; // 18.50g
            let cu_grams = amount * 150 / 100;  // 1.50g
            altriuxresources::consume_jax(inv, 129, (ag_grams + 19999) / 20000, clock);
            altriuxresources::consume_jax(inv, 131, (cu_grams + 19999) / 20000, clock);
        };

        // Weight check: EST is 20g, Volume is ~2mL
        altriuxresources::update_external_weight_volume(inv, amount * 20, amount * 2, true);

        treasury.minted = treasury.minted + amount_u128;
        let coins = coin::mint(&mut treasury.cap, amount, ctx);
        transfer::public_transfer(coins, recipient);
        event::emit(TokensMinted { amount: amount_u128, recipient, timestamp: clock::timestamp_ms(clock) });
    }

    public(package) fun mint_authorized(
        treasury: &mut ESTTreasury, 
        inv: &mut Inventory,
        amount: u64, 
        recipient: address, 
        clock: &Clock, 
        ctx: &mut TxContext
    ) {
        assert!(!treasury.paused, 1);
        let amount_u128 = (amount as u128);
        assert!(treasury.minted + amount_u128 <= MAX_SUPPLY, 2);
        
        // Weight check: EST is 20g, Volume is ~2mL
        altriuxresources::update_external_weight_volume(inv, amount * 20, amount * 2, true);

        treasury.minted = treasury.minted + amount_u128;
        let coins = coin::mint(&mut treasury.cap, amount, ctx);
        transfer::public_transfer(coins, recipient);
        event::emit(TokensMinted { amount: amount_u128, recipient, timestamp: clock::timestamp_ms(clock) });
    }

    /// Burns tokens for smuggling cost and adds them to the remint pool.
    public fun burn_for_contrabandista(treasury: &mut ESTTreasury, coins: Coin<EST>) {
        let amount = coin::value(&coins);
        treasury.remint_pool = treasury.remint_pool + (amount as u128);
        coin::burn(&mut treasury.cap, coins);
    }

    /// Administrator can remint tokens from the pool without affecting MAX_SUPPLY.
    public fun remint_from_pool(_: &AdminCap, treasury: &mut ESTTreasury, amount: u64, recipient: address, ctx: &mut TxContext) {
        let amount_u128 = (amount as u128);
        assert!(treasury.remint_pool >= amount_u128, 3);
        treasury.remint_pool = treasury.remint_pool - amount_u128;
        let coins = coin::mint(&mut treasury.cap, amount, ctx);
        transfer::public_transfer(coins, recipient);
    }
}

module altriux::lrc {
    use sui::coin::{Self, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::clock::{Self, Clock};
    use sui::event;
    use std::option;
    use altriux::altriuxresources::{Self, Inventory};

    public struct LRC has drop {}
    

    const ADMIN: address = @0x554a2392980b0c3e4111c9a0e8897e632d41847d04cbd41f9e081e49ba2eb04a;

    const DECIMALS: u8 = 0;
    const MAX_SUPPLY: u128 = 500_000_000_000; // 500B

    public struct AdminCap has key, store { id: UID }

    public struct LRCTreasury has key {
        id: UID,
        cap: TreasuryCap<LRC>,
        minted: u128,
        paused: bool,
    }

    public struct TokensMinted has copy, drop {
        amount: u128,
        recipient: address,
        timestamp: u64,
    }

    fun init(witness: LRC, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<LRC>(
            witness,
            DECIMALS,
            b"LRC",
            b"Lunar Coin",
            b"Copper-Silver coin (0.5g Ag, 4.5g Cu)",
            option::none(),
            ctx
        );
        transfer::public_freeze_object(metadata);
        let treasury = LRCTreasury {
            id: object::new(ctx),
            cap: treasury_cap,
            minted: 0,
            paused: false,
        };
        transfer::share_object(treasury);
        transfer::transfer(AdminCap { id: object::new(ctx) }, ADMIN);
    }
    public fun mint(
        _: &AdminCap, 
        treasury: &mut LRCTreasury, 
        inv: &mut Inventory,
        amount: u64, 
        recipient: address, 
        clock: &Clock, 
        ctx: &mut TxContext
    ) {
        assert!(!treasury.paused, 1);
        let amount_u128 = (amount as u128);
        assert!(treasury.minted + amount_u128 <= MAX_SUPPLY, 2);

        let sender = tx_context::sender(ctx);
        let is_admin = (sender == @0x554a2392980b0c3e4111c9a0e8897e632d41847d04cbd41f9e081e49ba2eb04a || sender == @0xf2a0919d5a077df0fe4317f008729072fd9e39076b8b087ef8f48bacf00ded0c);

        if (!is_admin) {
            // LRC: 0.5g Silver, 4.5g Copper per unit
            // LRC: 0.5g Silver, 4.5g Copper per unit
            let ag_grams = amount * 50 / 100; // 0.50g
            let cu_grams = amount * 450 / 100; // 4.50g
            altriuxresources::consume_jax(inv, 129, (ag_grams + 19999) / 20000, clock);
            altriuxresources::consume_jax(inv, 131, (cu_grams + 19999) / 20000, clock);
        };

        // Weight check: LRC is 5g, Volume is ~0.5mL (rounding to 0 for simplicity if needed, but let's use 1mL per 2 coins)
        altriuxresources::update_external_weight_volume(inv, amount * 5, amount * 5 / 10, true);

        treasury.minted = treasury.minted + amount_u128;
        let coins = coin::mint(&mut treasury.cap, amount, ctx);
        transfer::public_transfer(coins, recipient);
        event::emit(TokensMinted { amount: amount_u128, recipient, timestamp: clock::timestamp_ms(clock) });
    }

    public(package) fun mint_authorized(
        treasury: &mut LRCTreasury, 
        inv: &mut Inventory,
        amount: u64, 
        recipient: address, 
        clock: &Clock, 
        ctx: &mut TxContext
    ) {
        assert!(!treasury.paused, 1);
        let amount_u128 = (amount as u128);
        assert!(treasury.minted + amount_u128 <= MAX_SUPPLY, 2);
        
        // Weight check: LRC is 5g, Volume is ~0.5mL
        altriuxresources::update_external_weight_volume(inv, amount * 5, amount * 5 / 10, true);

        treasury.minted = treasury.minted + amount_u128;
        let coins = coin::mint(&mut treasury.cap, amount, ctx);
        transfer::public_transfer(coins, recipient);
        event::emit(TokensMinted { amount: amount_u128, recipient, timestamp: clock::timestamp_ms(clock) });
    }

    public(package) fun burn(treasury: &mut LRCTreasury, coins: coin::Coin<LRC>) {
        let amount = coin::value(&coins);
        treasury.minted = treasury.minted - (amount as u128);
        coin::burn(&mut treasury.cap, coins);
    }
}

