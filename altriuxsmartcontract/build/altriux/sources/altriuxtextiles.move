module altriux::altriuxtextiles {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use altriux::altriuxresources::{Inventory, consume_jax, add_jax};
    use sui::clock::Clock;
    use sui::dynamic_field;
    use sui::bcs;
    use std::vector;

    // === PRODUCCIÓN DE HILOS (1 JAX fibra → X JAX hilo) ===
    public fun hilar_fibra(
        inv: &mut Inventory, 
        fibra_id: u64, 
        cantidad_fibra_bp: u64, // Basis points: 100 bp = 1 JAX
        clock: &Clock,
        ctx: &mut TxContext
    ): u64 {
        // Consumir fibra (ej: 100 bp = 1 JAX de lino sin hilar)
        consume_jax_bp(inv, fibra_id, cantidad_fibra_bp, clock);
        
        // Rendimiento histórico: 70-80% de fibra → hilo útil
        let rendimiento_bp = if (fibra_id == 156) 75 // Lino: 75% rendimiento
            else if (fibra_id == 159) 80 // Lana: 80%
            else if (fibra_id == 161) 85 // Yak fino: 85%
            else if (fibra_id == 162) 70 // Yak grueso: 70%
            else if (fibra_id == 163) 90 // Cachemira: 90%
            else 75;
        
        let hilo_bp = (cantidad_fibra_bp * rendimiento_bp) / 100;
        hilo_bp
    }

    // === TEJIDO DE TELA (100 bp hilo → 90 bp tela) ===
    public fun tejer_tela(
        inv: &mut Inventory,
        hilo_id: u64,
        cantidad_hilo_bp: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): u64 {
        consume_jax_bp(inv, hilo_id, cantidad_hilo_bp, clock);
        
        // Pérdida histórica por desperdicio en telar vertical
        let tela_bp = (cantidad_hilo_bp * 90) / 100;
        tela_bp
    }

    // === TEÑIDO DE TELA (requiere mordiente para fijación) ===
    public fun tenir_tela(
        inv: &mut Inventory,
        tela_base_id: u64,
        cantidad_tela_bp: u64,
        tinte_id: u64,
        mordiente: bool,
        clock: &Clock,
        ctx: &mut TxContext
    ): u64 {
        consume_jax_bp(inv, tela_base_id, cantidad_tela_bp, clock);
        consume_jax(inv, tinte_id, 1, clock); // 1 JAX tinte por 100 bp tela
        
        if (mordiente) {
            consume_jax(inv, altriux::altriuxresources::id_mordiente_hierro(), 1, clock);
        };
        
        // Pérdida por proceso de teñido
        (cantidad_tela_bp * 95) / 100
    }

    // === Helper: Consumir JAX en basis points ===
    fun consume_jax_bp(inv: &mut Inventory, jax_id: u64, amount_bp: u64, clock: &Clock) {
        let whole_jax = amount_bp / 100;
        let fractional = amount_bp % 100;
        
        if (whole_jax > 0) {
            consume_jax(inv, jax_id, whole_jax, clock);
        };
        
        // Trackear fracciones en campo dinámico
        if (fractional > 0) {
            let mut debt_key = b"textile_debt_";
            vector::append(&mut debt_key, bcs::to_bytes(&jax_id));
            
            let mut consume_whole = false;
            let mut updated_debt = 0;

            {
                let uid_mut = altriux::altriuxresources::borrow_uid_mut(inv);
                
                if (!dynamic_field::exists_(uid_mut, debt_key)) {
                    dynamic_field::add(uid_mut, debt_key, 0u64);
                };

                let current_debt = *dynamic_field::borrow<vector<u8>, u64>(uid_mut, debt_key);
                let new_debt = current_debt + fractional;
                
                if (new_debt >= 100) {
                    consume_whole = true;
                    updated_debt = new_debt - 100;
                } else {
                    updated_debt = new_debt;
                };

                let val = dynamic_field::borrow_mut<vector<u8>, u64>(uid_mut, debt_key);
                *val = updated_debt;
                *dynamic_field::borrow_mut<vector<u8>, u64>(uid_mut, debt_key) = updated_debt;
            };

            if (consume_whole) {
                consume_jax(inv, jax_id, 1, clock);
            };
        };
    }
}