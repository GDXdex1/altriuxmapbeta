module altriux::altriuxsmelting {
    use sui::tx_context::{TxContext};
    use sui::clock::{Clock};
    use altriux::altriuxresources::{Inventory, add_jax, consume_jax, has_jax};
    use altriux::altriuxminerals;
    use altriux::altriuxmanufactured;

    const E_INSUFFICIENT_GALENA: u64 = 101;
    const E_INSUFFICIENT_NIQUELITA: u64 = 102;

    // === FUNDICIÓN DE GALENA (Con subproductos) ===
    public fun smelt_galena(
        inv: &mut Inventory,
        amount: u64,
        is_industrial: bool, // True = FUNDICION_INDUSTRIAL, False = FUNDICION_TRIBAL
        clock: &Clock,
        _ctx: &mut TxContext
    ) {
        // Validar galena suficiente
        assert!(has_jax(inv, altriuxminerals::JAX_MINERAL_GALENA(), amount), E_INSUFFICIENT_GALENA);
        
        // Consumir galena
        consume_jax(inv, altriuxminerals::JAX_MINERAL_GALENA(), amount, clock);
        
        // Producción de plomo refinado (50% rendimiento histórico)
        let lead_output = (amount * 50) / 100;
        add_jax(inv, altriuxmanufactured::PLOMO_REFINADO(), lead_output, 0, clock);
        
        // Plata desplazada (0.3% - documentado en procesos romanos de cupelación)
        let silver_output = (amount * 3) / 1000;
        if (silver_output > 0) {
            add_jax(inv, altriuxmanufactured::PLATA_DESPLAZADA(), silver_output, 0, clock);
        };
        
        // Azufre natural (2% SOLO en fundición industrial mediante tostación)
        if (is_industrial) {
            let sulfur_output = (amount * 2) / 100;
            if (sulfur_output > 0) {
                add_jax(inv, altriuxmanufactured::AZUFRE_NATURAL(), sulfur_output, 0, clock);
            };
        };
        
        // Escoria (30% - residuo de fundición)
        let slag_output = (amount * 30) / 100;
        add_jax(inv, altriuxmanufactured::ESCORIA_COBRE(), slag_output, 0, clock);
    }

    // === FUNDICIÓN DE NIQUELITA (NiAs) ===
    public fun smelt_niquelita(
        inv: &mut Inventory,
        amount: u64,
        clock: &Clock,
        _ctx: &mut TxContext
    ) {
        // Validar niquelita suficiente
        assert!(has_jax(inv, altriuxminerals::MINERAL_NIQUELITA(), amount), E_INSUFFICIENT_NIQUELITA);
        
        // Consumir niquelita
        consume_jax(inv, altriuxminerals::MINERAL_NIQUELITA(), amount, clock);
        
        // Producción de Níquel Refinado (40% rendimiento)
        let nickel_output = (amount * 40) / 100;
        add_jax(inv, altriuxmanufactured::NIQUEL_REFINADO(), nickel_output, 0, clock);
        
        // Producción de Cobalto Refinado (10% rendimiento)
        let cobalt_output = (amount * 10) / 100;
        add_jax(inv, altriuxmanufactured::COBALTO_REFINADO(), cobalt_output, 0, clock);
        
        // Escoria/Arsenico (50% residuo)
        let slag_output = (amount * 50) / 100;
        add_jax(inv, altriuxmanufactured::ESCORIA_COBRE(), slag_output, 0, clock); // Reusing copper slag for simplicity
    }

    public fun verify_silver_production(): (u64, u64, u64) {
        // Cálculo exacto de producción total de plata
        let total_galena = 16851851852; // TOTAL_GALENA_RESERVE_JAX
        let total_silver = (total_galena * 3) / 1000; // 0.3%
        let est_coins = (total_silver * 1000) / 10;    // 0.5g por moneda (10g = 1 JAX → 0.5g = 0.05 JAX)
        let lrc_coins = (total_silver * 1000) / 90;   // 4.5g por moneda (90g = 1 JAX → 4.5g = 0.225 JAX)
        
        // Con 10% pérdida en acuñación:
        let est_after_loss = est_coins * 90 / 100;
        let lrc_after_loss = lrc_coins * 90 / 100;
        
        (est_after_loss, lrc_after_loss, total_silver)
    }
}
