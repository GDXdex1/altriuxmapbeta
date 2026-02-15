#[allow(duplicate_alias, unused_const)]
module altriux::agc {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::clock::{Self, Clock};
    use sui::event;
    use std::option;

    public struct AGC has drop {}

    const ADMIN_1: address = @0x554a2392980b0c3e4111c9a0e8897e632d41847d04cbd41f9e081e49ba2eb04a;
    const ADMIN_2: address = @0x9e7aaf5f56ae094eadf9ca7f2856f533bcbf12fcc9bb9578e43ca770599a5dce;

    const DECIMALS: u8 = 0;
    const MAX_SUPPLY: u128 = 10_000_000_000; // 10B with 0 decimals
    const MAX_MINT_PER_TX: u128 = 5_000_000_000;

    const EExceededMaxSupply: u64 = 1;
    const EOverflowU64: u64 = 2;
    const EExceededMintPerTx: u64 = 3;
    const ETreasuryPaused: u64 = 4;
    const EZeroAmount: u64 = 6;

    public struct AdminCap has key, store { id: UID }

    public struct AGCTreasury has key {
        id: UID,
        cap: TreasuryCap<AGC>,
        minted: u128,
        remint_pool: u128,
        paused: bool,
    }

    public struct TokensMinted has copy, drop {
        admin: address,
        amount: u128,
        recipient: address,
        remaining_supply: u128,
        timestamp: u64,
    }

    public struct TreasuryPaused has copy, drop { admin: address, timestamp: u64 }
    public struct TreasuryResumed has copy, drop { admin: address, timestamp: u64 }

    #[allow(deprecated_usage)]
    fun init(witness: AGC, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<AGC>(
            witness,
            DECIMALS,
            b"AGC",
            b"Altriux Gold Coin",
            b"Official gold coin of Altriux (20g Au)",
            option::none(),
            ctx
        );

        transfer::public_freeze_object(metadata);

        let treasury = AGCTreasury {
            id: object::new(ctx),
            cap: treasury_cap,
            minted: 0,
            remint_pool: 0,
            paused: false,
        };

        transfer::share_object(treasury);
        transfer::transfer(AdminCap { id: object::new(ctx) }, ADMIN_1);
        transfer::transfer(AdminCap { id: object::new(ctx) }, ADMIN_2);
    }

    public fun pause_treasury(_: &AdminCap, treasury: &mut AGCTreasury, clock: &Clock, ctx: &mut TxContext) {
        treasury.paused = true;
        event::emit(TreasuryPaused { admin: tx_context::sender(ctx), timestamp: clock::timestamp_ms(clock) });
    }

    public fun resume_treasury(_: &AdminCap, treasury: &mut AGCTreasury, clock: &Clock, ctx: &mut TxContext) {
        treasury.paused = false;
        event::emit(TreasuryResumed { admin: tx_context::sender(ctx), timestamp: clock::timestamp_ms(clock) });
    }

    public fun mint(
        _: &AdminCap,
        treasury: &mut AGCTreasury,
        amount: u128,
        recipient: address,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(!treasury.paused, ETreasuryPaused);
        assert!(amount > 0, EZeroAmount);
        assert!(amount <= MAX_MINT_PER_TX, EExceededMintPerTx);
        assert!(treasury.minted + amount <= MAX_SUPPLY, EExceededMaxSupply);

        treasury.minted = treasury.minted + amount;

        let coins = coin::mint(&mut treasury.cap, (amount as u64), ctx);
        transfer::public_transfer(coins, recipient);

        event::emit(TokensMinted {
            admin: tx_context::sender(ctx),
            amount,
            recipient,
            remaining_supply: MAX_SUPPLY - treasury.minted,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    public fun burn(
        coins: Coin<AGC>,
        treasury: &mut AGCTreasury,
        _clock: &Clock,
        _ctx: &mut TxContext
    ) {
        assert!(!treasury.paused, ETreasuryPaused);
        coin::burn(&mut treasury.cap, coins);
    }

    /// Burns for contraband cost and adds to remint pool.
    public fun burn_for_contrabandista(treasury: &mut AGCTreasury, coins: Coin<AGC>) {
        let amount = coin::value(&coins);
        treasury.remint_pool = treasury.remint_pool + (amount as u128);
        coin::burn(&mut treasury.cap, coins);
    }

    /// Burns for land purchase and adds to remint pool.
    public fun burn_for_land(treasury: &mut AGCTreasury, coins: Coin<AGC>) {
        let amount = coin::value(&coins);
        treasury.remint_pool = treasury.remint_pool + (amount as u128);
        coin::burn(&mut treasury.cap, coins);
    }

    /// Administrator remints from the pool.
    public fun remint_from_pool(_: &AdminCap, treasury: &mut AGCTreasury, amount: u64, recipient: address, ctx: &mut TxContext) {
        let amount_u128 = (amount as u128);
        assert!(treasury.remint_pool >= amount_u128, 6); // Reuse EZeroAmount as EInsufficientRemint? Let's use 6.
        treasury.remint_pool = treasury.remint_pool - amount_u128;
        let coins = coin::mint(&mut treasury.cap, amount, ctx);
        transfer::public_transfer(coins, recipient);
    }
}
