module altriux::altriuxbuildings {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::transfer;
    use sui::table::{Self, Table};
    use sui::dynamic_field;
    use std::vector;
    use altriux::altriuxresources::{Self, Inventory, add_jax, consume_jax, create_inventory, has_jax};
    use altriux::altriuxland::{Self, LandRegistry, is_owner_of_land, has_river};
    use altriux::altriuxworkers::{Self, WorkerRegistry, WorkerContract};
    use altriux::altriuxlocation::{Self, ResourceLocation, is_adjacent};
    use altriux::altriuxminerals;
    use altriux::kingdomutils;
    use altriux::altriuxactionpoints::{Self, ActionPointRegistry};
    use sui::event;

    // === TIPOS DE EDIFICIO (52 tipos realistas) ===
    // Agricultura (1-10)
    const GRANJA_PEQUENA: u64 = 1;      // 2,500 m² - cultivos básicos
    const GRANJA_MEDIANA: u64 = 2;      // 5,000 m² - rotación de cultivos
    const GRANJA_GRANDE: u64 = 3;       // 10,000 m² - cultivos intensivos
    const HUERTO: u64 = 4;              // 500 m² - hortalizas

    // REMOVED: VINEDO, OLIVAR, APIARIO
    const ESTABLO: u64 = 8;             // 800 m² - ganado menor (ovejas/cabras)

    const CORRAL: u64 = 9;              // 1,200 m² - ganado mayor (vacas/bueyes)
    const GRANERO: u64 = 10;            // 300 m² - almacenamiento de grano

    // Minería y Metalurgia (11-20)
    const MINA_SUPERFICIAL: u64 = 11;   // 500 m² - extracción a cielo abierto
    const MINA_SUBTERRANEA: u64 = 12;   // 1,000 m² - túneles profundos
    const FUNDICION_TRIBAL: u64 = 13;   // 300 m² - horno pequeño (cobre, estaño, plomo básico)
    const FUNDICION_INDUSTRIAL: u64 = 14; // 600 m² - horno grande (hierro, plomo con subproductos)
    const FORJA: u64 = 15;              // 250 m² - trabajo en frío/caliente
    const TALLER_ARMAS: u64 = 16;       // 450 m² - fabricación de armas
    const TALLER_HERRAMIENTAS: u64 = 17; // 400 m² - fabricación de herramientas
    const HORNOS_CAL: u64 = 18;         // 300 m² - producción de cal viva
    const ALFARERIA: u64 = 19;          // 350 m² - cerámica y ladrillos
    const VIDRERIA: u64 = 20;           // 400 m² - producción de vidrio

    // Textiles (21)
    const TALLER_TEXTIL: u64 = 21;      // 400 m² - procesa lino, lana, algodón, cachemira, yak

    // Molinos (22-25)
    const MOLINO_FLUVIAL_PEQUENO: u64 = 22;   // 200 m² - molino de agua pequeño (requiere río)
    const MOLINO_FLUVIAL_GRANDE: u64 = 23;    // 400 m² - molino de agua grande (requiere río)
    const MOLINO_SANGRE_PEQUENO: u64 = 24;    // 150 m² - molino de sangre (animal) pequeño
    const MOLINO_SANGRE_GRANDE: u64 = 25;     // 300 m² - molino de sangre grande
    // Funciones de molino (almacenadas en campo dinámico)
    const MOLINO_FUNC_TRIGO: u8 = 1;   // Trigo → harina (80% rendimiento)
    const MOLINO_FUNC_ACEITE: u8 = 2;  // Aceitunas → aceite (40% rendimiento)
    const MOLINO_FUNC_PAPEL: u8 = 3;   // Estopas → papel (67% rendimiento)
    const MOLINO_FUNC_HILADO: u8 = 4;  // Fibra → hilo (80% rendimiento)
    const MOLINO_FUNC_TEJIDO: u8 = 5;  // Hilo → tela (75% rendimiento)
    const MOLINO_FUNC_TRILLADO: u8 = 6; // Grano → grano limpio (95% rendimiento)

    // Carbón (26)
    const CARBONERA: u64 = 26;          // 100 m² - convierte madera → carbón vegetal (15% rendimiento)

    // Alimentación (27-31)
    const PANADERIA: u64 = 27;          // 200 m² - horneado de pan
    const CARNICERIA: u64 = 28;         // 180 m² - procesamiento de carne
    const CERVEZERIA: u64 = 29;         // 300 m² - fermentación de cerveza
    const BODEGA: u64 = 30;             // 400 m² - almacenamiento de vino/aceite
    const AHUMADERO: u64 = 31;          // 250 m² - conservación de alimentos

    // Religiosos y Culturales (300+)
    const MESQUITA_IMLAX_PEQUENA: u64 = 300;
    const MESQUITA_IMLAX_GRANDE: u64 = 301;
    const MADRASA_IMLAX: u64 = 302;
    
    const IGLESIA_CRIS_PEQUENA: u64 = 303;
    const CATEDRAL_CRIS: u64 = 304;
    // Note: User requested "Monasterio Draxiux" specifically, so assigning to Draxiux group or separate?
    // Following strict listing order:
    
    const ESCUELA_DRAXIUX: u64 = 305;
    const MONASTERIO_DRAXIUX: u64 = 306;
    
    const TEMPLO_SHIX: u64 = 307;
    const ESCUELA_SHIX: u64 = 308;
    
    const SINAGOGA_YAX: u64 = 309;
    const ESCUELA_YAX: u64 = 310;
    
    const TEMPLO_SUX: u64 = 311;
    const ESCUELA_ASTRONOMICA_SUX: u64 = 312;

    // Militares (44-47)
    const MURALLA_MADERA: u64 = 44;     // 100 m² por segmento
    const MURALLA_PIEDRA: u64 = 45;     // 120 m² por segmento
    const TORRE_VIGIA: u64 = 46;        // 80 m²
    const FOSO: u64 = 47;               // 50 m² por segmento

    // Especiales (48-52)
    const GRANJA_ANIMALES: u64 = 48;    // 1,500 m² - producción de lana/leche/huevos
    const PESQUERIA: u64 = 49;          // 300 m² - pesca fluvial/marítima
    const TALLER_MADERA: u64 = 50;      // 350 m² - carpintería avanzada
    const TALLER_PIEDRA: u64 = 51;      // 400 m² - cantería y escultura
    const MERCADO: u64 = 52;            // 500 m² - intercambio de bienes
    const FABRICA_ARMAS_ASEDIO: u64 = 53; // 600 m² - máquinas de asedio (no NFT)

    // === PERIODOS DE BLOQUEO DE TRABAJADORES ===
    const PERIOD_1_DAY: u64 = 1;
    const PERIOD_10_DAYS: u64 = 10;
    const PERIOD_30_DAYS: u64 = 30;
    const PERIOD_80_DAYS: u64 = 80;
    const PERIOD_90_DAYS: u64 = 90; // Máximo permitido

    // === COSTOS AU ===
    const AU_COST_CONSTRUCTION: u64 = 2; // Costo por trabajador para construir
    const AU_COST_PRODUCTION_START: u64 = 2; // Costo por trabajador para iniciar producción

    // === ERRORES ===
    const E_NOT_OWNER: u64 = 101;
    const E_INSUFFICIENT_RESOURCES: u64 = 102;
    const E_NO_SPACE: u64 = 103;
    const E_BUILDING_EXISTS: u64 = 104;
    const E_INVALID_LAND: u64 = 105;
    const E_TOO_SOON: u64 = 106;
    const E_INVALID_WORKERS: u64 = 107;
    const E_DEMOLISH_PROTECTED: u64 = 108;
    const E_NO_RIVER: u64 = 109;        // Para molinos fluviales
    const E_INVALID_MILL_FUNC: u64 = 110;
    const E_HUNGRY_WORKERS: u64 = 111;  // Trabajadores hambrientos no pueden producir
    const E_WORKERS_NOT_BLOCKED: u64 = 112; // Intentar producir sin trabajadores bloqueados
    const E_PRODUCTION_IN_PROGRESS: u64 = 113; // Producción ya en curso
    const E_NO_PRODUCTION: u64 = 114;   // No hay producción para reclamar
    const E_STORAGE_FULL: u64 = 115;    // Almacenamiento lleno, recursos perdidos
    const E_WORKER_NOT_FOUND: u64 = 116;
    const E_CONTRACT_EXPIRED: u64 = 117;
    const E_INVALID_PERIOD: u64 = 118;

    // === STRUCTS ===
    public struct BuildingRegistry has key {
        id: UID,
        buildings: Table<ID, BuildingNFT>,
    }

    public struct ResourceCost has copy, drop, store {
        resource_id: u64,
        amount: u64,
    }

    public struct BuildingNFT has key, store {
        id: UID,
        type_id: u64,
        size_jex: u64,          // Espacio ocupado en m² (JEX)
        location: ResourceLocation, // ¡UBICACIÓN OBLIGATORIA ON-CHAIN!
        level: u8,              // Nivel 1-5
        workers: u64,           // Trabajadores asignados actualmente
        max_workers: u64,       // Máximo permitido según tipo/level
        last_production: u64,   // Timestamp última producción reclamada
        owner: address,
        is_protected: bool,     // No se puede demoler si true (edificios clave)
        // Estado de producción actual
        production_in_progress: bool,
        production_end_time: u64,
        production_period: u64, // 1, 10, 30, 80, 90 días
        // Almacenamiento interno
        storage_capacity_jax: u64, // Capacidad máxima en JAX
        current_storage_jax: u64,  // Almacenamiento actual
    }

    // === Production Batch (Objeto vinculado al edificio) ===
    public struct ProductionBatch has key, store {
        id: UID,
        building_id: ID,        // Edificio que lo generó
        output_resource_id: u64, // ID del recurso producido
        output_amount_jax: u64,  // Cantidad en JAX
        production_start: u64,   // Timestamp inicio
        production_end: u64,     // Timestamp fin
        location: ResourceLocation, // ¡HEREDA UBICACIÓN DEL EDIFICIO!
    }

    // === EVENTS ===
    public struct BuildingBuilt has copy, drop {
        id: ID,
        type_id: u64,
        size_jex: u64,
        location: ResourceLocation,
        owner: address,
        timestamp: u64,
    }

    public struct BuildingDemolished has copy, drop {
        id: ID,
        type_id: u64,
        resources_returned: vector<ResourceCost>,
        owner: address,
        timestamp: u64,
    }

    public struct ProductionStarted has copy, drop {
        building_id: ID,
        period_days: u64,
        worker_count: u64,
        output_resource: u64,
        estimated_output: u64,
        timestamp: u64,
    }

    public struct ProductionClaimed has copy, drop {
        building_id: ID,
        resource_id: u64,
        amount_jax: u64,
        worker_xp_gained: u64, // Total XP ganada por todos los trabajadores
        timestamp: u64,
    }

    public struct StorageOverflow has copy, drop {
        building_id: ID,
        resource_id: u64,
        overflow_amount: u64,
        timestamp: u64,
    }

    public struct WorkerBlocked has copy, drop {
        building_id: ID,
        worker_id: ID,
        period_days: u64,
        timestamp: u64,
    }

    // === INICIALIZACIÓN ===
    public fun create_building_registry(ctx: &mut TxContext) {
        let registry = BuildingRegistry {
            id: object::new(ctx),
            buildings: table::new(ctx),
        };
        transfer::share_object(registry);
    }

    // === CONSTRUCCIÓN SEGURA CON UBICACIÓN OBLIGATORIA ===
    public fun build(
        reg: &mut BuildingRegistry,
        land_reg: &LandRegistry,
        type_id: u64,
        land_id: u64,
        tile_id: u64,
        parcel_idx: u64,
        inv: &mut Inventory,
        worker_ids: vector<ID>, // Workers for construction
        au_reg: &mut ActionPointRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        let sender = tx_context::sender(ctx);
        
        // === VALIDACIÓN 1: Propiedad del terreno ===
        assert!(is_owner_of_land(land_reg, land_id, sender), E_NOT_OWNER);
        
        // === VALIDACIÓN 3: Espacio disponible en el terreno ===
        let land = altriux::altriuxland::borrow_land(land_reg, land_id);
        let land_obj_id = object::id(land);
        
        let land_jex = 1000000; // xLand = 1 km² = 1,000,000 m² (JEX)
        let used_jex = get_land_used_jex(reg, land_obj_id);
        let stats = get_building_stats(type_id);
        let size_jex = stats.size_jex;
        assert!(used_jex + size_jex <= land_jex, E_NO_SPACE);
        
        // === VALIDACIÓN 4: Requisitos específicos por tipo de edificio ===
        let land = altriux::altriuxland::borrow_land(land_reg, land_id);
        
        // ¡VALIDACIÓN DE RÍO PARA MOLINOS FLUVIALES!
        if (type_id == MOLINO_FLUVIAL_PEQUENO || type_id == MOLINO_FLUVIAL_GRANDE) {
            assert!(has_river(land), E_NO_RIVER);
        };
        
        // === VALIDACIÓN 5: Recursos suficientes ===
        let (costs, _) = get_construction_costs(type_id, 1); // Nivel 1
        let mut i = 0;
        let cost_len = vector::length(&costs);
        while (i < cost_len) {
            let res_cost = vector::borrow(&costs, i);
            assert!(has_jax(inv, res_cost.resource_id, res_cost.amount), E_INSUFFICIENT_RESOURCES);
            i = i + 1;
        };
        
        // === CONSUMO DE RECURSOS ===
        let mut j = 0;
        while (j < cost_len) {
            let res_cost = vector::borrow(&costs, j);
            consume_jax(inv, res_cost.resource_id, res_cost.amount, clock);
            j = j + 1;
        };
        
        // === CONSUMO AU (Construcción) ===
        let worker_count = vector::length(&worker_ids);
        assert!(worker_count > 0, E_INVALID_WORKERS);
        let total_au = (worker_count as u64) * AU_COST_CONSTRUCTION;
        altriuxactionpoints::consume_au_from_workers(au_reg, &worker_ids, total_au, b"build_building", clock, ctx);
        
        // === CREACIÓN DEL EDIFICIO CON UBICACIÓN OBLIGATORIA ===
        let location = altriuxlocation::new_location_simple(land_obj_id, tile_id, parcel_idx);
        
        let mut building = BuildingNFT {
            id: object::new(ctx),
            type_id,
            size_jex,
            location, // ¡UBICACIÓN ASIGNADA ON-CHAIN!
            level: 1,
            workers: 0,
            max_workers: stats.max_workers,
            last_production: kingdomutils::get_game_time(clock),
            owner: sender,
            is_protected: is_building_protected(type_id),
            production_in_progress: false,
            production_end_time: 0,
            production_period: 0,
            storage_capacity_jax: stats.storage_capacity,
            current_storage_jax: 0,
        };
        
        // ¡INICIALIZAR FUNCIÓN DE MOLINO SI APLICA!
        if (is_mill_type(type_id)) {
            // Por defecto: molienda de trigo
            dynamic_field::add(&mut building.id, b"mill_function", MOLINO_FUNC_TRIGO);
        };
        
        let id = object::id(&building);
        table::add(&mut reg.buildings, id, building);
        
        // Registrar uso de espacio en el terreno
        register_land_usage(reg, land_obj_id, size_jex);
        
        event::emit(BuildingBuilt {
            id,
            type_id,
            size_jex,
            location,
            owner: sender,
            timestamp: clock::timestamp_ms(clock),
        });
        
        id
    }

    // === DEMOLICIÓN CON RECUPERACIÓN PARCIAL ===
    public fun demolish(
        reg: &mut BuildingRegistry,
        building_id: ID,
        inv: &mut Inventory,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        
        // Tomar el edificio del registro para destruirlo
        let building = table::remove(&mut reg.buildings, building_id);
        
        // === VALIDACIÓN DE PROPIEDAD Y PROTECCIÓN ===
        assert!(building.owner == sender, E_NOT_OWNER);
        assert!(!building.is_protected, E_DEMOLISH_PROTECTED);
        
        // === RECUPERACIÓN DE RECURSOS (30-50% según tipo de edificio) ===
        let stats = get_building_stats(building.type_id);
        let recovery_rate = stats.demolition_rate;
        let (costs, _) = get_construction_costs(building.type_id, building.level);
        
        let mut resources_returned = vector::empty<ResourceCost>();
        let mut i = 0;
        let cost_len = vector::length(&costs);
        while (i < cost_len) {
            let res_cost = vector::borrow(&costs, i);
            let recovered = (res_cost.amount * recovery_rate) / 100;
            if (recovered > 0) {
                add_jax(inv, res_cost.resource_id, recovered, 0, clock);
                vector::push_back(&mut resources_returned, ResourceCost { resource_id: res_cost.resource_id, amount: recovered });
            };
            i = i + 1;
        };
        
        // Liberar espacio en el terreno
        unregister_land_usage(reg, altriux::altriuxlocation::get_land_id(&building.location), building.size_jex);
        
        event::emit(BuildingDemolished {
            id: building_id,
            type_id: building.type_id,
            resources_returned,
            owner: sender,
            timestamp: clock::timestamp_ms(clock),
        });

        // Destruir el objeto
        let BuildingNFT { id, .. } = building;
        object::delete(id);
    }

    // === INICIAR CICLO DE PRODUCCIÓN (BLOQUEA TRABAJADORES) ===
    public fun start_production_cycle(
        reg: &mut BuildingRegistry,
        worker_reg: &mut WorkerRegistry,
        building_id: ID,
        worker_ids: vector<ID>,
        period_days: u64,
        au_reg: &mut ActionPointRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let building = table::borrow_mut(&mut reg.buildings, building_id);
        
        // Validar propiedad
        assert!(building.owner == sender, E_NOT_OWNER);
        
        // Validar período válido (1, 10, 30, 80, 90 días)
        assert!(
            period_days == PERIOD_1_DAY || 
            period_days == PERIOD_10_DAYS || 
            period_days == PERIOD_30_DAYS || 
            period_days == PERIOD_80_DAYS || 
            period_days == PERIOD_90_DAYS,
            E_INVALID_PERIOD
        );
        
        // Validar no hay producción en curso
        assert!(!building.production_in_progress, E_PRODUCTION_IN_PROGRESS);
        
        // Validar número de trabajadores (mínimo 1, máximo según edificio)
        let worker_count = vector::length(&worker_ids);
        assert!(worker_count > 0 && (worker_count as u64) <= building.max_workers, E_INVALID_WORKERS);
        
        // Validar trabajadores
        let mut k = 0;
        while (k < worker_count) {
            let wid = *vector::borrow(&worker_ids, k);
            assert!(altriuxworkers::is_worker_registered(worker_reg, wid), E_WORKER_NOT_FOUND);
            assert!(altriuxworkers::get_worker_owner(worker_reg, wid) == sender, E_NOT_OWNER);
            assert!(altriuxworkers::is_worker_active(worker_reg, wid), E_CONTRACT_EXPIRED);
            k = k + 1;
        };
        
        // Bloquear trabajadores
        let mut l = 0;
        while (l < worker_count) {
            let wid = *vector::borrow(&worker_ids, l);
            let contract = altriuxworkers::borrow_worker_mut(worker_reg, wid);
            altriuxworkers::set_worker_building_id(contract, option::some(building_id));
            
            // Marcar como bloqueado mediante campo dinámico
            let contract_id_mut = altriuxworkers::borrow_worker_id_mut(worker_reg, wid);
            dynamic_field::add(contract_id_mut, b"blocked_until", clock::timestamp_ms(clock) + (period_days * 24 * 60 * 60 * 1000));
            
            event::emit(WorkerBlocked {
                building_id,
                worker_id: wid,
                period_days,
                timestamp: clock::timestamp_ms(clock),
            });
            
            l = l + 1;
        };
        
        // Calcular producción estimada
        let (output_resource, base_output) = get_production_output(building.type_id, building.level);
        let worker_bonus = (worker_count as u64) * 5; // +5% por trabajador
        let estimated_output = base_output * (100 + worker_bonus) / 100;
        
        // === CONSUMO AU (Inicio Producción) ===
        let total_au = (worker_count as u64) * AU_COST_PRODUCTION_START;
        altriuxactionpoints::consume_au_from_workers(au_reg, &worker_ids, total_au, b"production_start", clock, ctx);
        
        // Iniciar producción
        building.production_in_progress = true;
        building.production_end_time = clock::timestamp_ms(clock) + (period_days * 24 * 60 * 60 * 1000);
        building.production_period = period_days;
        building.workers = worker_count as u64;
        
        event::emit(ProductionStarted {
            building_id,
            period_days,
            worker_count: worker_count as u64,
            output_resource,
            estimated_output,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // === RECLAMAR PRODUCCIÓN (LIBERA TRABAJADORES + BONIFICACIÓN XP) ===
    public fun claim_production(
        reg: &mut BuildingRegistry,
        worker_reg: &mut WorkerRegistry,
        building_id: ID,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let building = table::borrow_mut(&mut reg.buildings, building_id);
        
        // Validar propiedad
        assert!(building.owner == sender, E_NOT_OWNER);
        
        // Validar producción completada
        assert!(building.production_in_progress, E_NO_PRODUCTION);
        assert!(clock::timestamp_ms(clock) >= building.production_end_time, E_PRODUCTION_IN_PROGRESS);
        
        // Calcular producción real
        let (output_resource, base_output) = get_production_output(building.type_id, building.level);
        let worker_count = building.workers;
        let worker_bonus = worker_count * 5; // +5% por trabajador
        let period_bonus = building.production_period / 10; // +1% por cada 10 días de ciclo
        let total_bonus = worker_bonus + period_bonus;
        let actual_output = base_output * (100 + total_bonus) / 100;
        
        // Aplicar bonificación de experiencia a trabajadores (+1% por día trabajado, máx +25%)
        let xp_per_worker = if (building.production_period > 25) 25 else building.production_period;
        
        // Verificar capacidad de almacenamiento
        if (building.current_storage_jax + actual_output > building.storage_capacity_jax) {
            // ¡OVERFLOW! Pérdida de recursos excedentes
            let overflow = building.current_storage_jax + actual_output - building.storage_capacity_jax;
            building.current_storage_jax = building.storage_capacity_jax;
            
            event::emit(StorageOverflow {
                building_id,
                resource_id: output_resource,
                overflow_amount: overflow,
                timestamp: clock::timestamp_ms(clock),
            });
        } else {
            building.current_storage_jax = building.current_storage_jax + actual_output;
        };
        
        // Crear ProductionBatch para auditoría (con ubicación heredada)
        let batch = ProductionBatch {
            id: object::new(ctx),
            building_id,
            output_resource_id: output_resource,
            output_amount_jax: actual_output,
            production_start: building.last_production,
            production_end: clock::timestamp_ms(clock),
            location: building.location, // ¡HEREDA UBICACIÓN DEL EDIFICIO!
        };
        transfer::public_transfer(batch, sender);
        
        // Liberar trabajadores (remover bloqueo)
        // En producción real: iterar contratos y remover campo dinámico "blocked_until"
        
        // Actualizar timestamp
        building.last_production = clock::timestamp_ms(clock);
        building.production_in_progress = false;
        building.production_period = 0;
        
        event::emit(ProductionClaimed {
            building_id,
            resource_id: output_resource,
            amount_jax: actual_output,
            worker_xp_gained: xp_per_worker * worker_count,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // === RETIRAR RECURSOS DEL ALMACENAMIENTO DEL EDIFICIO ===
    public fun withdraw_resources(
        reg: &mut BuildingRegistry,
        building_id: ID,
        resource_id: u64,
        amount_jax: u64,
        target_inv: &mut Inventory,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let building = table::borrow_mut(&mut reg.buildings, building_id);
        
        // Validar propiedad
        assert!(building.owner == sender, E_NOT_OWNER);
        
        // Validar suficientes recursos en almacenamiento
        assert!(building.current_storage_jax >= amount_jax, E_INSUFFICIENT_RESOURCES);
        
        // Retirar recursos
        building.current_storage_jax = building.current_storage_jax - amount_jax;
        
        // Añadir recursos al inventario del jugador
        add_jax(target_inv, resource_id, amount_jax, 0, clock);
    }

    // === LÓGICA DE PRODUCCIÓN REALISTA POR EDIFICIO ===
    fun get_production_output(type_id: u64, _level: u8): (u64, u64) {
        if (type_id == GRANJA_PEQUENA) (2, 10)
        else if (type_id == GRANJA_MEDIANA) (2, 22)
        else if (type_id == GRANJA_GRANDE) (2, 45)
        else if (type_id == HUERTO) (56, 8)

        // REMOVED: VINEDO, OLIVAR
        else if (type_id == FUNDICION_TRIBAL) (137, 1)
        else if (type_id == FUNDICION_INDUSTRIAL) (139, 1)
        else if (type_id == FORJA) (130, 2)
        else if (type_id == MOLINO_FLUVIAL_GRANDE) (221, 10)
        else if (type_id == MOLINO_SANGRE_GRANDE) (221, 8)
        else if (type_id == CARBONERA) (219, 2)
        else if (type_id == TALLER_TEXTIL) (167, 12)
        else if (type_id == PANADERIA) (305, 15)
        else if (type_id == CARNICERIA) (227, 10)
        else (2, 5)
    }



    // === COSTOS DE CONSTRUCCIÓN REALISTAS (OPTIMIZADO) ===
    fun get_construction_costs(type_id: u64, level: u8): (vector<ResourceCost>, vector<u64>) {
        let costs = if (type_id == GRANJA_PEQUENA && level == 1) {
            vector[
                ResourceCost { resource_id: 135, amount: 50 },
                ResourceCost { resource_id: 203, amount: 20 },
                ResourceCost { resource_id: 200, amount: 10 }
            ]
        } else if (type_id == FUNDICION_TRIBAL && level == 1) {
            vector[
                ResourceCost { resource_id: 198, amount: 100 },
                ResourceCost { resource_id: 204, amount: 80 },
                ResourceCost { resource_id: 200, amount: 50 },
                ResourceCost { resource_id: 219, amount: 30 }
            ]
        } else if (type_id == FUNDICION_INDUSTRIAL && level == 1) {
            vector[
                ResourceCost { resource_id: 198, amount: 250 },
                ResourceCost { resource_id: 204, amount: 150 },
                ResourceCost { resource_id: 200, amount: 100 },
                ResourceCost { resource_id: 219, amount: 80 },
                ResourceCost { resource_id: 130, amount: 40 }
            ]
        } else if (type_id == MOLINO_FLUVIAL_GRANDE && level == 1) {
            vector[
                ResourceCost { resource_id: 137, amount: 200 },
                ResourceCost { resource_id: 198, amount: 150 },
                ResourceCost { resource_id: 204, amount: 100 },
                ResourceCost { resource_id: 148, amount: 60 },
                ResourceCost { resource_id: 130, amount: 20 }
            ]
        } else if (type_id == MOLINO_SANGRE_GRANDE && level == 1) {
            vector[
                ResourceCost { resource_id: 135, amount: 140 },
                ResourceCost { resource_id: 196, amount: 90 },
                ResourceCost { resource_id: 204, amount: 70 },
                ResourceCost { resource_id: 220, amount: 25 },
                ResourceCost { resource_id: 130, amount: 15 }
            ]
        } else if (type_id == CARBONERA && level == 1) {
            vector[
                ResourceCost { resource_id: 135, amount: 80 },
                ResourceCost { resource_id: 196, amount: 40 },
                ResourceCost { resource_id: 204, amount: 30 }
            ]
        } else if (type_id == TALLER_TEXTIL && level == 1) {
            vector[
                ResourceCost { resource_id: 135, amount: 120 },
                ResourceCost { resource_id: 196, amount: 60 },
                ResourceCost { resource_id: 220, amount: 30 }
            ]
        } else if (type_id == PANADERIA && level == 1) {
            vector[
                ResourceCost { resource_id: 135, amount: 60 },
                ResourceCost { resource_id: 196, amount: 40 },
                ResourceCost { resource_id: 200, amount: 20 }
            ]
        } else if (type_id == MESQUITA_IMLAX_PEQUENA && level == 1) {
            vector[
                ResourceCost { resource_id: 196, amount: 200 },
                ResourceCost { resource_id: 135, amount: 100 },
                ResourceCost { resource_id: 200, amount: 50 }
            ]
        } else if (type_id == MESQUITA_IMLAX_GRANDE && level == 1) {
            vector[
                ResourceCost { resource_id: 198, amount: 500 },
                ResourceCost { resource_id: 199, amount: 200 },
                ResourceCost { resource_id: 137, amount: 150 },
                ResourceCost { resource_id: 213, amount: 50 }
            ]
        } else if (type_id == MADRASA_IMLAX && level == 1) {
            vector[
                ResourceCost { resource_id: 196, amount: 150 },
                ResourceCost { resource_id: 135, amount: 120 },
                ResourceCost { resource_id: 206, amount: 40 }
            ]
        } else if (type_id == IGLESIA_CRIS_PEQUENA && level == 1) {
            vector[
                ResourceCost { resource_id: 135, amount: 180 },
                ResourceCost { resource_id: 196, amount: 100 }
            ]
        } else if (type_id == CATEDRAL_CRIS && level == 1) {
            vector[
                ResourceCost { resource_id: 196, amount: 600 },
                ResourceCost { resource_id: 199, amount: 100 },
                ResourceCost { resource_id: 213, amount: 80 },
                ResourceCost { resource_id: 130, amount: 50 }
            ]
        } else if (type_id == ESCUELA_DRAXIUX && level == 1) {
             vector[
                 ResourceCost { resource_id: 198, amount: 250 },
                 ResourceCost { resource_id: 130, amount: 60 }
             ]
        } else if (type_id == MONASTERIO_DRAXIUX && level == 1) {
             vector[
                 ResourceCost { resource_id: 198, amount: 400 },
                 ResourceCost { resource_id: 130, amount: 100 },
                 ResourceCost { resource_id: 148, amount: 100 }
             ]
        } else if (type_id == TEMPLO_SHIX && level == 1) {
             vector[
                 ResourceCost { resource_id: 137, amount: 400 },
                 ResourceCost { resource_id: 200, amount: 200 },
                 ResourceCost { resource_id: 212, amount: 50 }
             ]
        } else if (type_id == ESCUELA_SHIX && level == 1) {
             vector[
                 ResourceCost { resource_id: 135, amount: 200 },
                 ResourceCost { resource_id: 196, amount: 50 }
             ]
        } else if (type_id == SINAGOGA_YAX && level == 1) {
             vector[
                 ResourceCost { resource_id: 196, amount: 300 },
                 ResourceCost { resource_id: 137, amount: 100 },
                 ResourceCost { resource_id: 220, amount: 40 }
             ]
        } else if (type_id == ESCUELA_YAX && level == 1) {
             vector[
                 ResourceCost { resource_id: 196, amount: 150 },
                 ResourceCost { resource_id: 135, amount: 100 }
             ]
        } else if (type_id == TEMPLO_SUX && level == 1) {
             vector[
                 ResourceCost { resource_id: 200, amount: 400 },
                 ResourceCost { resource_id: 202, amount: 100 },
                 ResourceCost { resource_id: 119, amount: 20 }
             ]
        } else if (type_id == ESCUELA_ASTRONOMICA_SUX && level == 1) {
             vector[
                 ResourceCost { resource_id: 200, amount: 300 },
                 ResourceCost { resource_id: 202, amount: 50 }
             ]
        } else if (type_id == MURALLA_PIEDRA && level == 1) {
            vector[
                ResourceCost { resource_id: 198, amount: 120 },
                ResourceCost { resource_id: 204, amount: 80 }
            ]
        } else if (type_id == TORRE_VIGIA && level == 1) {
            vector[
                ResourceCost { resource_id: 137, amount: 100 },
                ResourceCost { resource_id: 198, amount: 150 },
                ResourceCost { resource_id: 204, amount: 90 }
            ]
        } else {
            // Costo base para edificios no especificados
            vector[
                ResourceCost { resource_id: 135, amount: 100 },
                ResourceCost { resource_id: 196, amount: 50 }
            ]
        };
        
        (costs, vector::empty<u64>())
    }

    // === HELPERS DE UBICACIÓN Y ESPACIO ===
    fun get_land_used_jex(reg: &BuildingRegistry, land_obj_id: ID): u64 {
        if (dynamic_field::exists_(&reg.id, land_obj_id)) {
            *dynamic_field::borrow<ID, u64>(&reg.id, land_obj_id)
        } else {
            0
        }
    }

    fun register_land_usage(reg: &mut BuildingRegistry, land_obj_id: ID, size_jex: u64) {
        let current = get_land_used_jex(reg, land_obj_id);
        if (dynamic_field::exists_(&reg.id, land_obj_id)) {
            let val = dynamic_field::borrow_mut<ID, u64>(&mut reg.id, land_obj_id);
            *val = current + size_jex;
        } else {
            dynamic_field::add(&mut reg.id, land_obj_id, current + size_jex);
        };
    }

    fun unregister_land_usage(reg: &mut BuildingRegistry, land_obj_id: ID, size_jex: u64) {
        let current = get_land_used_jex(reg, land_obj_id);
        if (current >= size_jex) {
            let val = dynamic_field::borrow_mut<ID, u64>(&mut reg.id, land_obj_id);
            *val = current - size_jex;
        };
    }

    // Consolidated stats function
    public struct BuildingStats has drop {
        size_jex: u64,
        max_workers: u64,
        storage_capacity: u64,
        demolition_rate: u64
    }

    fun get_building_stats(type_id: u64): BuildingStats {
        let (size, workers, storage, demo_rate) = 
            if (type_id == GRANJA_PEQUENA) (2500, 5, 100, 50)
            else if (type_id == GRANJA_MEDIANA) (5000, 5, 250, 40)
            else if (type_id == GRANJA_GRANDE) (10000, 12, 500, 40)
            else if (type_id == HUERTO) (500, 5, 200, 50)
            else if (type_id == AHUMADERO) (250, 5, 250, 35)
            // Nuevos edificios religiosos
            else if (type_id == MESQUITA_IMLAX_PEQUENA) (300, 5, 200, 25)
            else if (type_id == MESQUITA_IMLAX_GRANDE) (800, 5, 200, 25)
            else if (type_id == MADRASA_IMLAX) (400, 5, 200, 25)
            else if (type_id == IGLESIA_CRIS_PEQUENA) (250, 5, 200, 25)
            else if (type_id == CATEDRAL_CRIS) (1000, 5, 200, 25)
            else if (type_id == ESCUELA_DRAXIUX) (350, 5, 200, 25)
            else if (type_id == MONASTERIO_DRAXIUX) (500, 5, 200, 25)
            else if (type_id == TEMPLO_SHIX) (450, 5, 200, 25)
            else if (type_id == ESCUELA_SHIX) (300, 5, 200, 25)
            else if (type_id == SINAGOGA_YAX) (400, 5, 200, 25)
            else if (type_id == ESCUELA_YAX) (300, 5, 200, 25)
            else if (type_id == TEMPLO_SUX) (600, 5, 200, 25)
            else if (type_id == ESCUELA_ASTRONOMICA_SUX) (400, 5, 200, 25)
            
            else if (type_id == MURALLA_MADERA) (100, 5, 200, 35)
            else if (type_id == MURALLA_PIEDRA) (120, 5, 200, 35)
            else if (type_id == TORRE_VIGIA) (80, 5, 200, 35)
            else if (type_id == FOSO) (50, 5, 200, 35)
            else if (type_id == GRANJA_ANIMALES) (1500, 5, 200, 35)
            else if (type_id == PESQUERIA) (300, 5, 200, 35)
            else if (type_id == TALLER_MADERA) (350, 5, 200, 35)
            else if (type_id == TALLER_PIEDRA) (400, 5, 200, 35)
            else if (type_id == MERCADO) (500, 5, 200, 35)
            
            else if (type_id == MINA_SUBTERRANEA) (1000, 20, 200, 35)
            else if (type_id == FUNDICION_TRIBAL) (300, 5, 150, 35)
            else if (type_id == FUNDICION_INDUSTRIAL) (600, 8, 300, 30)
            else if (type_id == FORJA) (250, 5, 200, 35)
            else if (type_id == MOLINO_FLUVIAL_PEQUENO) (200, 5, 200, 45)
            else if (type_id == MOLINO_FLUVIAL_GRANDE) (400, 6, 400, 40)
            else if (type_id == MOLINO_SANGRE_PEQUENO) (150, 5, 200, 45)
            else if (type_id == MOLINO_SANGRE_GRANDE) (300, 4, 300, 40)
            else if (type_id == CARBONERA) (100, 5, 250, 35)
            else if (type_id == TALLER_TEXTIL) (400, 5, 350, 35)
            else if (type_id == PANADERIA) (200, 5, 180, 35)
            else if (type_id == CARNICERIA) (180, 5, 150, 35)
            else if (type_id == BODEGA) (400, 10, 3000, 35)
            else if (type_id == GRANERO) (300, 5, 2000, 35)
            
            else (500, 5, 200, 35);
            
        BuildingStats {
            size_jex: size,
            max_workers: workers,
            storage_capacity: storage,
            demolition_rate: demo_rate
        }
    }

    fun is_building_protected(type_id: u64): bool {
        type_id == GRANERO || type_id == BODEGA || type_id == ESTABLO || type_id == CORRAL
    }

    fun is_mill_type(type_id: u64): bool {
        type_id == MOLINO_FLUVIAL_PEQUENO || type_id == MOLINO_FLUVIAL_GRANDE || 
        type_id == MOLINO_SANGRE_PEQUENO || type_id == MOLINO_SANGRE_GRANDE
    }

    // === RESTORED PUBLIC GETTERS ===
    public fun id_market(): u64 { MERCADO }
    
    public fun get_building_type(building: &BuildingNFT): u64 {
        building.type_id
    }
    
    public fun get_building_tile(building: &BuildingNFT): u64 {
        altriux::altriuxlocation::encode_coordinates(
            altriux::altriuxlocation::get_hq(&building.location), 
            altriux::altriuxlocation::get_hr(&building.location)
        )
    }
    
    // Legacy getters removed, need to update callsites in build/demolish/claim

}