module altriux::altriuxtrade {
    use sui::object::{Self, ID};
    use sui::clock::{Clock};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use altriux::altriuxresources::{Self, Inventory};
    use altriux::altriuxbuildingbase::{Self, BuildingNFT};
    use altriux::altriuxlocation::{Self, ResourceLocation};
    use altriux::lrc::{Self, LRC, LRCTreasury};

    // Errors
    const E_INVALID_MARKET: u64 = 101;
    const E_LOCATIONS_MISMATCH: u64 = 102;
    const E_INSUFFICIENT_FUNDS: u64 = 103;

    // === 1. TRANSFERENCIA DE CONTRABANDO (Penalización por distancia en LRC) ===
    // "1 lrc por jax o jix enviado por cada 50 casillas grandes"
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
        // Cálculo de distancia entre Hexágonos Grandes (h_q, h_r)
        let dist = (altriuxlocation::hex_distance(
            altriuxlocation::get_hq(from_loc), altriuxlocation::get_hr(from_loc),
            altriuxlocation::get_hq(to_loc), altriuxlocation::get_hr(to_loc)
        ) as u64);

        // Penalización: 1 LRC por cada 50 casillas (por unidad de recurso)
        let penalty_ratio = dist / 50;
        let lrc_cost = penalty_ratio * amount;

        if (lrc_cost > 0) {
            assert!(coin::value(&lrc_payment) >= lrc_cost, E_INSUFFICIENT_FUNDS);
            let to_burn = coin::split(&mut lrc_payment, lrc_cost, ctx);
            lrc::burn(lrc_treasury, to_burn);
        };

        // Devolver lo que quede del pago (o todo si el costo fue 0)
        if (coin::value(&lrc_payment) > 0) {
            transfer::public_transfer(lrc_payment, tx_context::sender(ctx));
        } else {
            coin::destroy_zero(lrc_payment);
        };

        // Transferencia de recursos (sin reducción de cantidad, la penalización se paga en LRC)
        altriuxresources::transfer_jax(from, to, resource_id, amount, clock);
    }

    // === 2. INTERCAMBIO DE MERCADO (Sin penalización) ===
    // Requiere estar en un MERCADO o GRAN_MERCADO
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
        
        // Transferencia completa sin penalización
        altriuxresources::transfer_jax(from, to, resource_id, amount, clock);
    }

    // === 3. TRANSFERENCIA LOCAL (Sin penalización si misma coordenada Xland) ===
    // "Ceder recursos a otra wallet pero deben estar en la misma casilla xland"
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
        // Verificar que las coordenadas coincidan (H y S)
        assert!(
            altriuxlocation::get_hq(&from_loc) == altriuxlocation::get_hq(&to_loc) &&
            altriuxlocation::get_hr(&from_loc) == altriuxlocation::get_hr(&to_loc) &&
            altriuxlocation::get_sq(&from_loc) == altriuxlocation::get_sq(&to_loc) &&
            altriuxlocation::get_sr(&from_loc) == altriuxlocation::get_sr(&to_loc),
            E_LOCATIONS_MISMATCH
        );

        // Transferencia completa sin penalización
        altriuxresources::transfer_jax(from, to, resource_id, amount, clock);
    }
}
