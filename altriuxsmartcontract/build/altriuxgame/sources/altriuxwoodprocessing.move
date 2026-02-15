module altriux::altriuxwoodprocessing {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::transfer;
    use sui::table::{Self, Table};
    use std::vector;
    use altriux::altriuxresources::{Self, Inventory, add_jax, consume_jax, has_jax};
    use altriux::altriuxlocation::{Self, LocationRegistry};
    use altriux::kingdomutils;
    use sui::event;

    // === TIPOS DE PROCESAMIENTO ===
    const PROCESS_SAWMILL: u8 = 1;      // Troncos → Tablones
    const PROCESS_CHARCOAL_KILN: u8 = 2; // Madera → Carbón vegetal (15% rendimiento)
    const PROCESS_LUMBER_YARD: u8 = 3;   // Tablones → Vigas

    // === CALIDADES DE MADERA ===
    const QUALITY_PREMIUM: u8 = 1;  // Roble/nogal/ébano
    const QUALITY_FIRST: u8 = 2;    // Pino/abeto/fresno
    const QUALITY_SECOND: u8 = 3;   // Abedul/álamo/sauce
    const QUALITY_WASTE: u8 = 4;    // Leña/astillas

    // === RECURSOS (IDs de altriuxresources) ===
    const JAX_TRONCO_PREMIUM: u64 = 137;
    const JAX_TRONCO_ESTANDAR: u64 = 138;
    const JAX_TRONCO_ALTO: u64 = 139;
    const JAX_TABLON_ANCHO: u64 = 140;
    const JAX_TABLON_SEGUNDA: u64 = 141;
    const JAX_VIGA_LARGA: u64 = 142;
    const JAX_CARBON_MADERA: u64 = 143;
    const JAX_LENA_SECA: u64 = 144;
    const JAX_ASTILLAS_MADERA: u64 = 145;

    // === ERRORES ===
    const E_INSUFFICIENT_WOOD: u64 = 101;
    const E_INVALID_PROCESS: u64 = 102;
    const E_NO_WORKERS: u64 = 103;
    const E_NOT_OWNER: u64 = 104;

    // === STRUCTS ===
    public struct WoodProcessingRegistry has key {
        id: UID,
        // Registro de instalaciones de procesamiento
        facilities: Table<ID, WoodFacility>,
    }

    public struct WoodFacility has key, store {
        id: UID,
        owner: address,
        facility_type: u8,      // PROCESS_*
        location_key: u64,      // Coordenada codificada
        level: u8,              // Nivel 1-5 (afecta eficiencia)
        workers: u64,           // Trabajadores asignados
        last_processed: u64,    // Timestamp último procesamiento
    }

    // === EVENTS ===
    public struct WoodProcessed has copy, drop {
        facility_id: ID,
        input_type: u64,
        input_amount: u64,
        output_type: u64,
        output_amount: u64,
        workers: u64,
        timestamp: u64,
    }

    // === INICIALIZACIÓN ===
    public fun create_woodprocessing_registry(ctx: &mut TxContext) {
        let registry = WoodProcessingRegistry {
            id: object::new(ctx),
            facilities: table::new(ctx),
        };
        transfer::share_object(registry);
    }

    // === CREACIÓN DE INSTALACIÓN ===
    public fun build_facility(
        reg: &mut WoodProcessingRegistry,
        facility_type: u8,
        location_key: u64,
        level: u8,
        owner: address,
        ctx: &mut TxContext
    ): ID {
        assert!(
            facility_type == PROCESS_SAWMILL || 
            facility_type == PROCESS_CHARCOAL_KILN || 
            facility_type == PROCESS_LUMBER_YARD,
            E_INVALID_PROCESS
        );
        assert!(level >= 1 && level <= 5, E_INVALID_PROCESS);
        
        let facility = WoodFacility {
            id: object::new(ctx),
            owner,
            facility_type,
            location_key,
            level,
            workers: 0,
            last_processed: 0,
        };
        
        let id = object::id(&facility);
        table::add(&mut reg.facilities, id, facility);
        id
    }

    // === ASIGNACIÓN DE TRABAJADORES ===
    public fun assign_workers(
        reg: &mut WoodProcessingRegistry,
        facility_id: ID,
        num_workers: u64,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let facility = table::borrow_mut(&mut reg.facilities, facility_id);
        assert!(facility.owner == sender, E_NOT_OWNER);
        facility.workers = num_workers;
    }

    // === PROCESAMIENTO DE MADERA ===
    public fun process_wood(
        reg: &mut WoodProcessingRegistry,
        facility_id: ID,
        input_type: u64,
        input_amount: u64,
        inv: &mut Inventory,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let facility = table::borrow_mut(&mut reg.facilities, facility_id);
        let now = kingdomutils::get_game_time(clock);
        
        // Validar propiedad
        assert!(facility.owner == sender, E_NOT_OWNER);
        
        // Validar trabajadores
        assert!(facility.workers > 0, E_NO_WORKERS);
        
        // Validar cooldown (24 horas blockchain)
        assert!(now >= facility.last_processed + (24 * 60 * 60 * 1000), E_NO_WORKERS);
        
        // Validar recursos suficientes
        assert!(has_jax(inv, input_type, input_amount), E_INSUFFICIENT_WOOD);
        
        // Determinar calidad de madera
        let quality = if (input_type == JAX_TRONCO_PREMIUM) {
            QUALITY_PREMIUM
        } else if (input_type == JAX_TRONCO_ESTANDAR) {
            QUALITY_FIRST
        } else if (input_type == JAX_TRONCO_ALTO) {
            QUALITY_SECOND
        } else if (input_type == JAX_LENA_SECA || input_type == JAX_ASTILLAS_MADERA) {
            QUALITY_WASTE
        } else {
            QUALITY_SECOND // Por defecto
        };
        
        // Procesamiento según tipo de instalación
        let (output_type, output_amount) = if (facility.facility_type == PROCESS_SAWMILL) {
            // Serrería: troncos → tablones
            // Rendimiento: 70% para premium, 60% para primera, 50% para segunda
            let efficiency = if (quality == QUALITY_PREMIUM) { 70 }
                           else if (quality == QUALITY_FIRST) { 60 }
                           else if (quality == QUALITY_SECOND) { 50 }
                           else { 40 };
            let output = (input_amount * efficiency) / 100;
            if (quality == QUALITY_PREMIUM) {
                (JAX_TABLON_ANCHO, output)
            } else {
                (JAX_TABLON_SEGUNDA, output)
            }
        } else if (facility.facility_type == PROCESS_CHARCOAL_KILN) {
            // Horno de carbón: madera → carbón vegetal (15% rendimiento histórico)
            let output = (input_amount * 15) / 100;
            (JAX_CARBON_MADERA, output)
        } else if (facility.facility_type == PROCESS_LUMBER_YARD) {
            // Patio de madera: tablones → vigas
            assert!(input_type == JAX_TABLON_ANCHO, E_INSUFFICIENT_WOOD);
            let efficiency = 40 + (facility.level as u64) * 5;
            let output = (input_amount * efficiency) / 100;
            (JAX_VIGA_LARGA, output)
        } else {
            abort E_INVALID_PROCESS
        };
        
        // Consumir input
        consume_jax(inv, input_type, input_amount, clock);
        
        // Producir output
        add_jax(inv, output_type, output_amount, 0, clock);
        
        // Actualizar timestamp
        facility.last_processed = now;
        
        event::emit(WoodProcessed {
            facility_id,
            input_type,
            input_amount,
            output_type,
            output_amount,
            workers: facility.workers,
            timestamp: now,
        });
    }

    // === GETTERS RPC ===
    public fun get_facility_info(reg: &WoodProcessingRegistry, facility_id: ID): (u8, u8, u64) {
        let facility = table::borrow(&reg.facilities, facility_id);
        (facility.facility_type, facility.level, facility.workers)
    }

    public fun id_process_sawmill(): u8 { PROCESS_SAWMILL }
    public fun id_process_charcoal_kiln(): u8 { PROCESS_CHARCOAL_KILN }
    public fun id_process_lumber_yard(): u8 { PROCESS_LUMBER_YARD }
    public fun id_quality_premium(): u8 { QUALITY_PREMIUM }
    public fun id_quality_first(): u8 { QUALITY_FIRST }
    public fun id_quality_second(): u8 { QUALITY_SECOND }
    public fun id_quality_waste(): u8 { QUALITY_WASTE }
}
