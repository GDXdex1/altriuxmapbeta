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
    use altriux::altriuxbuildingbase::{Self, BuildingNFT, BuildingRegistry, ResourceCost};
    use altriux::altriuxmanufactured;
    use altriux::altriuxlocation::{Self, ResourceLocation, is_adjacent};
    use altriux::altriuxminerals;
    use altriux::altriuxfood;
    use altriux::altriuxproduction::{Self, ProductionBatch};
    use altriux::kingdomutils;
    use altriux::altriuxactionpoints::{Self, ActionPointRegistry};
    use altriux::altriuxtrade;
    use sui::event;



    // === TIPOS DE EDIFICIO (52 tipos realistas) ===
    // Agricultura (Farms moved to core/agriculture)
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
    const MERCADO: u64 = 5;             // 500 m² - intercambio de bienes (Updated to ID 5)
    const GRAN_MERCADO: u64 = 6;        // 1000 m² - Gran Mercado (No tax)
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
    const E_INVALID_RESOURCES: u64 = 119;

    // (Building structs moved to Core: altriuxbuildingbase)

    // (BuildingNFT fields moved to base)


    // === Production Batch (Moved to Core: altriuxproduction) ===

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
        let used_jex = altriuxbuildingbase::get_land_used_jex(reg, land_obj_id);
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
            assert!(has_jax(inv, altriuxbuildingbase::cost_id(res_cost), altriuxbuildingbase::cost_amount(res_cost)), E_INSUFFICIENT_RESOURCES);
            i = i + 1;
        };
        
        // === CONSUMO DE RECURSOS ===
        let mut j = 0;
        while (j < cost_len) {
            let res_cost = vector::borrow(&costs, j);
            consume_jax(inv, altriuxbuildingbase::cost_id(res_cost), altriuxbuildingbase::cost_amount(res_cost), clock);
            j = j + 1;
        };

        
        // === CONSUMO AU (Construcción) ===
        let worker_count = vector::length(&worker_ids);
        assert!(worker_count > 0, E_INVALID_WORKERS);
        let total_au = (worker_count as u64) * AU_COST_CONSTRUCTION;
        altriuxactionpoints::consume_au_from_workers(au_reg, &worker_ids, total_au, b"build_building", clock, ctx);
        
        // === CREACIÓN DEL EDIFICIO CON UBICACIÓN OBLIGATORIA ===
        let location = altriuxlocation::new_location_simple(land_obj_id, tile_id, parcel_idx);
        
        let mut building = altriuxbuildingbase::new_building_nft(
            type_id,
            size_jex,
            location,
            1, // Level 1
            stats.max_workers,
            kingdomutils::get_game_time(clock), // last_production
            sender,
            is_building_protected(type_id),
            stats.storage_capacity,
            ctx
        );

        
        // ¡INICIALIZAR FUNCIÓN DE MOLINO SI APLICA!
        if (is_mill_type(type_id)) {
            // Por defecto: molienda de trigo
            dynamic_field::add(altriuxbuildingbase::get_building_uid_mut(&mut building), b"mill_function", MOLINO_FUNC_TRIGO);
        };

        
        let id = object::id(&building);
        altriuxbuildingbase::add_building_to_registry(reg, building);

        
        // Registrar uso de espacio en el terreno
        altriuxbuildingbase::register_land_usage(reg, land_obj_id, size_jex);
        
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
        let building = altriuxbuildingbase::remove_building_from_registry(reg, building_id);

        
        // === VALIDACIÓN DE PROPIEDAD Y PROTECCIÓN ===
        // Validar propiedad
        assert!(altriuxbuildingbase::get_building_owner(&building) == sender, E_NOT_OWNER);
        assert!(!altriuxbuildingbase::is_protected(&building), E_DEMOLISH_PROTECTED);

        
        // === RECUPERACIÓN DE RECURSOS (30-50% según tipo de edificio) ===
        let stats = get_building_stats(altriuxbuildingbase::get_building_type(&building));
        let recovery_rate = stats.demolition_rate;
        let (costs, _) = get_construction_costs(altriuxbuildingbase::get_building_type(&building), altriuxbuildingbase::get_building_level(&building));

        
        let mut resources_returned = vector::empty<ResourceCost>();
        let mut i = 0;
        let cost_len = vector::length(&costs);
        while (i < cost_len) {
            let res_cost = vector::borrow(&costs, i);
            let recovered = (altriuxbuildingbase::cost_amount(res_cost) * recovery_rate) / 100;
            if (recovered > 0) {
                add_jax(inv, altriuxbuildingbase::cost_id(res_cost), recovered, 0, clock);
                vector::push_back(&mut resources_returned, altriuxbuildingbase::new_resource_cost(altriuxbuildingbase::cost_id(res_cost), recovered));
            };
            i = i + 1;
        };
        
        // Liberar espacio en el terreno
        altriuxbuildingbase::unregister_land_usage(reg, altriux::altriuxlocation::get_land_id(altriuxbuildingbase::get_building_location(&building)), altriuxbuildingbase::get_building_size(&building));

        
        event::emit(BuildingDemolished {
            id: building_id,
            type_id: altriuxbuildingbase::get_building_type(&building),

            resources_returned,
            owner: sender,
            timestamp: clock::timestamp_ms(clock),
        });

        // Destruir el objeto
        let id_del = altriuxbuildingbase::get_building_uid(&building);
        // ... (Manual destruction not possible for foreign structs unless helper provided, but UID can be handled)
        // Actually, core must provide a destroyer if it's not 'drop'.
        altriuxbuildingbase::destroy_building(building);
    }


    // === INICIAR CICLO DE PRODUCCIÓN (BLOQUEA TRABAJADORES) ===
    public fun start_production_cycle(
        reg: &mut BuildingRegistry,
        worker_reg: &mut WorkerRegistry,
        building_id: ID,
        worker_ids: vector<ID>,
        inv: &mut Inventory, // Agregado parámetro faltante
        period_days: u64,
        au_reg: &mut ActionPointRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let building = altriuxbuildingbase::borrow_building_mut(reg, building_id);
        
        // ... (validaciones iguales)
        assert!(altriuxbuildingbase::get_building_owner(building) == sender, E_NOT_OWNER);
        assert!(
            period_days == PERIOD_1_DAY || 
            period_days == PERIOD_10_DAYS || 
            period_days == PERIOD_30_DAYS || 
            period_days == PERIOD_80_DAYS || 
            period_days == PERIOD_90_DAYS,
            E_INVALID_PERIOD
        );
        assert!(!altriuxbuildingbase::is_production_in_progress(building), E_PRODUCTION_IN_PROGRESS);
        let worker_count = vector::length(&worker_ids);
        assert!(worker_count > 0 && (worker_count as u64) <= altriuxbuildingbase::get_max_workers(building), E_INVALID_WORKERS);

        // Role Checks
        let type_id = altriuxbuildingbase::get_building_type(building);
        if (type_id == FORJA || type_id == TALLER_ARMAS || type_id == TALLER_HERRAMIENTAS) {
            check_workers_role(worker_reg, &worker_ids, altriuxworkers::ROLE_HERRERO());
        } else if (type_id == PANADERIA) {
            check_workers_role(worker_reg, &worker_ids, altriuxworkers::ROLE_PANADERO());
        } else if (type_id == CARNICERIA) {
            check_workers_role(worker_reg, &worker_ids, altriuxworkers::ROLE_CARNICERO());
        } else if (type_id == ALFARERIA || type_id == altriuxbuildingbase::type_taller_cereales()) {
            check_workers_role(worker_reg, &worker_ids, altriuxworkers::ROLE_ARTESANO());
        } else if (type_id == TALLER_TEXTIL) {
            check_workers_role(worker_reg, &worker_ids, altriuxworkers::ROLE_TEJEDOR());
        };

        // Bloquear trabajadores (lógica resumida para brevedad o mantener original)
        let mut l = 0;
        while (l < worker_count) {
            let wid = *vector::borrow(&worker_ids, l);
            let contract = altriuxworkers::borrow_worker_mut(worker_reg, wid);
            altriuxworkers::set_worker_building_id(contract, option::some(building_id));
            let contract_id_mut = altriuxworkers::borrow_worker_id_mut(worker_reg, wid);
            dynamic_field::add(contract_id_mut, b"blocked_until", clock::timestamp_ms(clock) + (period_days * 24 * 60 * 60 * 1000));
            l = l + 1;
        };
        
        // Consumir materias primas (CORREGIDO)
        let (input_resource, input_amount) = get_production_input(altriuxbuildingbase::get_building_type(building), altriuxbuildingbase::get_building_level(building));
        if (input_resource != 0) {
            altriuxresources::consume_jax(inv, input_resource, input_amount * period_days, clock);
        };


        // Calcular producción estimada

        let (output_resource, base_output) = get_production_output(altriuxbuildingbase::get_building_type(building), altriuxbuildingbase::get_building_level(building));
        let worker_bonus = (worker_count as u64) * 5; // +5% por trabajador
        let estimated_output = base_output * (100 + worker_bonus) / 100;

        
        // === CONSUMO AU (Inicio Producción) ===
        let total_au = (worker_count as u64) * AU_COST_PRODUCTION_START;
        altriuxactionpoints::consume_au_from_workers(au_reg, &worker_ids, total_au, b"production_start", clock, ctx);
        
        // Iniciar producción
        altriuxbuildingbase::set_production_state(
            building,
            true,
            clock::timestamp_ms(clock) + (period_days * 24 * 60 * 60 * 1000),
            period_days,
            worker_count as u64
        );

        
        event::emit(ProductionStarted {
            building_id,
            period_days,
            worker_count: worker_count as u64,
            output_resource,
            estimated_output,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // === ADVANCED PRODUCTION: MILLING (Cereals -> Flour/Oil) ===
    public fun start_milling_cycle(
        reg: &mut BuildingRegistry,
        worker_reg: &mut WorkerRegistry,
        building_id: ID,
        worker_ids: vector<ID>,
        inv: &mut Inventory,
        input_resource: u64, // JAX_WHEAT, JAX_MAIZE, JAX_RYE, JAX_BARLEY
        period_days: u64,
        au_reg: &mut ActionPointRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let building = altriuxbuildingbase::borrow_building_mut(reg, building_id);
        let type_id = altriuxbuildingbase::get_building_type(building);
        
        assert!(altriuxbuildingbase::get_building_owner(building) == sender, E_NOT_OWNER);
        assert!(is_mill_type(type_id), E_INVALID_MILL_FUNC);
        assert!(!altriuxbuildingbase::is_production_in_progress(building), E_PRODUCTION_IN_PROGRESS);
        
        let worker_count = vector::length(&worker_ids);
        assert!(worker_count > 0 && (worker_count as u64) <= altriuxbuildingbase::get_max_workers(building), E_INVALID_WORKERS);

        // Consumo de AU (Mill requires more work)
        let au_multiplier = if (input_resource == altriuxfood::JAX_CASSAVA()) 3 else 2;
        let total_au = (worker_count as u64) * AU_COST_PRODUCTION_START * au_multiplier;
        altriuxactionpoints::consume_au_from_workers(au_reg, &worker_ids, total_au, b"milling_start", clock, ctx);

        // Role Checks for Mills
        if (type_id == altriuxbuildingbase::type_hiladero() || type_id == altriuxbuildingbase::type_tejedero()) {
            check_workers_role(worker_reg, &worker_ids, altriuxworkers::ROLE_TEJEDOR());
        } else {
            check_workers_role(worker_reg, &worker_ids, altriuxworkers::ROLE_ARTESANO());
        };

        // Define output based on input
        let (output_res, _) = if (input_resource == altriuxfood::JAX_WHEAT()) (altriuxfood::JAX_HARINA_INTEGRAL(), 0)
            else if (input_resource == altriuxfood::JAX_BARLEY()) (altriuxfood::JAX_MALTA(), 0)
            else if (input_resource == altriuxfood::JAX_OATS()) (altriuxfood::JAX_AVENA_HOJUELAS(), 0)
            else if (input_resource == altriuxfood::JAX_MAIZE()) (altriuxfood::JAX_HARINA_MAIZ_V2(), 0)
            else if (input_resource == altriuxfood::JAX_RICE()) (altriuxfood::JAX_ARROZ_DESCASCARILLADO(), 0)
            else if (input_resource == altriuxfood::JAX_RYE()) (altriuxfood::JAX_HARINA_CENTENO_V2(), 0)
            else if (input_resource == altriuxfood::JAX_MALTA()) (altriuxfood::JAX_BEER(), 0)
            else if (input_resource == altriuxfood::JAX_SOYBEAN()) (altriuxfood::JAX_TOFU(), 0)
            else if (input_resource == altriuxfood::JAX_PEANUT()) (altriuxfood::JAX_MANTEQUILLA_MANI(), 0)
            else if (input_resource == altriuxfood::JAX_CHICKPEA()) (altriuxfood::JAX_HUMMUS(), 0)
            else if (input_resource == altriuxfood::JAX_LENTIL()) (altriuxfood::JAX_LENTEJAS_SECAS(), 0)
            else if (input_resource == altriuxfood::JAX_COMMON_BEAN()) (altriuxfood::JAX_FRIJOLES_SECOS(), 0)
            else if (input_resource == altriuxfood::JAX_SUNFLOWER()) (altriuxfood::JAX_ACEITE_GIRASOL(), 0)
            else if (input_resource == altriuxfood::JAX_SESAME()) (altriuxfood::JAX_ACEITE_SESAMO(), 0)
            else if (input_resource == altriuxfood::JAX_LINO_ACEITE()) (altriuxfood::JAX_ACEITE_LINO_V2(), 0)
            else if (input_resource == altriuxfood::JAX_OLIVE()) (altriuxfood::JAX_ACEITE_OLIVA_V2(), 0)
            else if (input_resource == altriuxfood::JAX_COCONUT()) (altriuxfood::JAX_ACEITE_COCO_V2(), 0)
            else if (input_resource == altriuxfood::JAX_FLAX()) (altriuxfood::JAX_LINO_HILADO(), 0)
            else if (input_resource == altriuxfood::JAX_HEMP()) (altriuxfood::JAX_CANAMO_HILADO(), 0)
            else if (input_resource == altriuxfood::JAX_COTTON()) (altriuxfood::JAX_HILO_ALGODON_V2(), 0)
            else if (input_resource == altriuxfood::JAX_CASSAVA()) (altriuxfood::JAX_TAPIOCA(), 0)
            else if (input_resource == altriuxfood::JAX_COFFEE()) (altriuxfood::JAX_COFFEE_SECADO(), 0)
            else if (input_resource == altriuxfood::JAX_COFFEE_SECADO()) (altriuxfood::JAX_COFFEE_MOLIDO(), 0)
            else if (input_resource == altriuxfood::JAX_TABACO()) (altriuxfood::JAX_TABACO_BULTOS(), 0)
            else (0, 0);

        assert!(output_res != 0, E_INVALID_RESOURCES);
        
        // Consumir entrada (10 unidades por día)
        altriuxresources::consume_jax(inv, input_resource, 10 * period_days, clock);

        altriuxbuildingbase::set_production_state(
            building,
            true,
            clock::timestamp_ms(clock) + (period_days * 24 * 60 * 60 * 1000),
            period_days,
            worker_count as u64
        );

        // Store active input as dynamic field for yield calculation
        dynamic_field::add(altriuxbuildingbase::get_building_uid_mut(building), b"active_input", input_resource);
    }

    // === ADVANCED PRODUCTION: TRAPICHE (Sugar Extraction) ===
    public fun start_trapiche_cycle(
        reg: &mut BuildingRegistry,
        worker_reg: &mut WorkerRegistry,
        building_id: ID,
        worker_ids: vector<ID>,
        inv: &mut Inventory,
        input_resource: u64, // JAX_SUGAR_CANE, JAX_SUGAR_BEET
        period_days: u64,
        au_reg: &mut ActionPointRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let building = altriuxbuildingbase::borrow_building_mut(reg, building_id);
        let type_id = altriuxbuildingbase::get_building_type(building);
        
        assert!(altriuxbuildingbase::get_building_owner(building) == sender, E_NOT_OWNER);
        assert!(type_id == altriuxbuildingbase::type_trapiche(), E_NOT_OWNER); // Re-use error
        
        let worker_count = vector::length(&worker_ids);
        assert!(worker_count > 0 && (worker_count as u64) <= altriuxbuildingbase::get_max_workers(building), E_INVALID_WORKERS);

        // Consumo de AU
        let total_au = (worker_count as u64) * AU_COST_PRODUCTION_START * 3; // Hard work
        altriuxactionpoints::consume_au_from_workers(au_reg, &worker_ids, total_au, b"trapiche_start", clock, ctx);

        assert!(input_resource == altriuxfood::JAX_SUGAR_CANE() || input_resource == altriuxfood::JAX_SUGAR_BEET(), E_INVALID_RESOURCES);
        
        // Consumir entrada (20 unidades por día)
        altriuxresources::consume_jax(inv, input_resource, 20 * period_days, clock);

        altriuxbuildingbase::set_production_state(
            building,
            true,
            clock::timestamp_ms(clock) + (period_days * 24 * 60 * 60 * 1000),
            period_days,
            worker_count as u64
        );

        dynamic_field::add(altriuxbuildingbase::get_building_uid_mut(building), b"active_input", input_resource);
    }

    // === ADVANCED PRODUCTION: FERMENTATION (Juice -> Cider/Alcohol) ===
    public fun start_fermentation_cycle(
        reg: &mut BuildingRegistry,
        worker_reg: &mut WorkerRegistry,
        building_id: ID,
        worker_ids: vector<ID>,
        inv: &mut Inventory,
        input_resource: u64, // JAX_JUGO_MANZANA, etc.
        period_days: u64,
        au_reg: &mut ActionPointRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let building = altriuxbuildingbase::borrow_building_mut(reg, building_id);
        let type_id = altriuxbuildingbase::get_building_type(building);
        
        assert!(altriuxbuildingbase::get_building_owner(building) == sender, E_NOT_OWNER);
        assert!(type_id == BODEGA, E_INVALID_MILL_FUNC); // Bodega handles fermentation
        assert!(period_days >= 30, E_INVALID_PERIOD); // Fermentation takes at least 1 month
        
        let worker_count = vector::length(&worker_ids);
        assert!(worker_count > 0 && (worker_count as u64) <= altriuxbuildingbase::get_max_workers(building), E_INVALID_WORKERS);

        // AU cost is low for fermentation (passive but needs setup)
        let total_au = (worker_count as u64) * AU_COST_PRODUCTION_START;
        altriuxactionpoints::consume_au_from_workers(au_reg, &worker_ids, total_au, b"fermentation_start", clock, ctx);

        assert!(
            input_resource == altriuxmanufactured::JAX_JUGO_UVA() || 
            input_resource == altriuxmanufactured::JAX_JUGO_MANZANA() || 
            input_resource == altriuxmanufactured::JAX_JUGO_PERA(), 
            E_INVALID_RESOURCES
        );
        
        // Consumir entrada (10 unidades por bloque de tiempo)
        altriuxresources::consume_jax(inv, input_resource, 10 * period_days, clock);

        altriuxbuildingbase::set_production_state(
            building,
            true,
            clock::timestamp_ms(clock) + (period_days * 24 * 60 * 60 * 1000),
            period_days,
            worker_count as u64
        );

        dynamic_field::add(altriuxbuildingbase::get_building_uid_mut(building), b"active_input", input_resource);
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
        let building = altriuxbuildingbase::borrow_building_mut(reg, building_id);
        
        // Validar propiedad
        assert!(altriuxbuildingbase::get_building_owner(building) == sender, E_NOT_OWNER);
        
        // Validar producción completada
        assert!(altriuxbuildingbase::is_production_in_progress(building), E_NO_PRODUCTION);
        assert!(clock::timestamp_ms(clock) >= altriuxbuildingbase::get_production_end_time(building), E_PRODUCTION_IN_PROGRESS);
        
        // Calcular producción real
        let type_id = altriuxbuildingbase::get_building_type(building);
        let level = altriuxbuildingbase::get_building_level(building);
        
        let mut actual_output = 0;
        let mut secondary_output = 0;
        let mut secondary_res_id = 0;
        let mut output_resource = 0;

        if (dynamic_field::exists_(altriuxbuildingbase::get_building_uid(building), b"active_input")) {
            let input_res = dynamic_field::remove<vector<u8>, u64>(altriuxbuildingbase::get_building_uid_mut(building), b"active_input");
            let period = altriuxbuildingbase::get_production_period(building);
            
            // Recipe Mapping for Industrial Production
            if (input_res == altriuxfood::JAX_WHEAT()) {
                if (level >= 2) {
                    output_resource = altriuxfood::JAX_HARINA_BLANCA();
                    actual_output = 12 * period * 9 / 12; // 75%
                    secondary_res_id = altriuxfood::BYPRO_SALVADO_C();
                    secondary_output = 12 * period * 3 / 12; // 25%
                } else {
                    output_resource = altriuxfood::JAX_HARINA_INTEGRAL();
                    actual_output = 10 * period * 8 / 10; // 80%
                    secondary_res_id = altriuxfood::BYPRO_SALVADO_B();
                    secondary_output = 10 * period * 2 / 10; // 20%
                }
            } else if (input_res == altriuxfood::JAX_BARLEY()) {
                output_resource = altriuxfood::JAX_MALTA();
                actual_output = 10 * period * 7 / 10; // 70%
                secondary_res_id = altriuxfood::BYPRO_SALVADO_B();
                secondary_output = 10 * period * 3 / 10; // 30%
            } else if (input_res == altriuxfood::JAX_OATS()) {
                output_resource = altriuxfood::JAX_AVENA_HOJUELAS();
                actual_output = 8 * period * 6 / 8; // 75%
                secondary_res_id = altriuxfood::BYPRO_SALVADO_A();
                secondary_output = 8 * period * 2 / 8; // 25%
            } else if (input_res == altriuxfood::JAX_MAIZE()) {
                output_resource = altriuxfood::JAX_HARINA_MAIZ_V2();
                actual_output = 10 * period * 8 / 10; // 80%
                secondary_res_id = altriuxfood::BYPRO_TOTOMOXTLE();
                secondary_output = 10 * period * 2 / 10; // 20%
            } else if (input_res == altriuxfood::JAX_RICE()) {
                output_resource = altriuxfood::JAX_ARROZ_DESCASCARILLADO();
                actual_output = 12 * period * 8 / 12; // 67%
                secondary_res_id = altriuxfood::BYPRO_CASCARILLA();
                secondary_output = 12 * period * 4 / 12; // 33%
            } else if (input_res == altriuxfood::JAX_RYE()) {
                output_resource = altriuxfood::JAX_HARINA_CENTENO_V2();
                actual_output = 10 * period * 7 / 10; // 70%
                secondary_res_id = altriuxfood::BYPRO_SALVADO_C();
                secondary_output = 10 * period * 3 / 10; // 30%
            } else if (input_res == altriuxfood::JAX_MALTA()) {
                output_resource = altriuxfood::JAX_BEER();
                actual_output = 5 * period * 4 / 5; 
                secondary_res_id = altriuxfood::BYPRO_LEVADURA_RESIDUIAL();
                secondary_output = 5 * period * 2 / 5;
            } else if (input_res == altriuxfood::JAX_SOYBEAN()) {
                if (type_id == altriuxbuildingbase::type_taller_soya()) {
                    output_resource = altriuxfood::JAX_TOFU();
                    actual_output = 6 * period * 4 / 6; 
                    secondary_res_id = altriuxfood::BYPRO_OKARA_A_PLUS();
                    secondary_output = 6 * period * 2 / 6;
                } else {
                    output_resource = altriuxfood::JAX_ACEITE_SOYA();
                    actual_output = 10 * period * 2 / 10;
                    secondary_res_id = altriuxfood::BYPRO_HARINA_SOYA_A_PLUS();
                    secondary_output = 10 * period * 8 / 10;
                }
            } else if (input_res == altriuxfood::JAX_PEANUT()) {
                output_resource = altriuxfood::JAX_MANTEQUILLA_MANI();
                actual_output = 8 * period * 5 / 8;
                secondary_res_id = altriuxfood::BYPRO_TORTA_MANI_A();
                secondary_output = 8 * period * 3 / 8;
            } else if (input_res == altriuxfood::JAX_CHICKPEA()) {
                output_resource = altriuxfood::JAX_HUMMUS();
                actual_output = 6 * period * 4 / 6;
                secondary_res_id = altriuxfood::BYPRO_PIEL_RESIDUAL();
                secondary_output = 6 * period * 2 / 6;
            } else if (input_res == altriuxfood::JAX_LENTIL()) {
                output_resource = altriuxfood::JAX_LENTEJAS_SECAS();
                actual_output = 8 * period * 6 / 8;
                secondary_res_id = altriuxfood::BYPRO_HOJARASCA_B();
                secondary_output = 8 * period * 2 / 8;
            } else if (input_res == altriuxfood::JAX_COMMON_BEAN()) {
                output_resource = altriuxfood::JAX_FRIJOLES_SECOS();
                actual_output = 8 * period * 6 / 8;
                secondary_res_id = altriuxfood::BYPRO_VAINAS_A();
                secondary_output = 8 * period * 2 / 8;
            } else if (input_res == altriuxfood::JAX_SUNFLOWER()) {
                output_resource = altriuxfood::JAX_ACEITE_GIRASOL();
                actual_output = 10 * period * 3 / 10;
                secondary_res_id = altriuxfood::BYPRO_TORTA_A();
                secondary_output = 10 * period * 7 / 10;
            } else if (input_res == altriuxfood::JAX_SESAME()) {
                output_resource = altriuxfood::JAX_ACEITE_SESAMO();
                actual_output = 8 * period * 3 / 8;
                secondary_res_id = altriuxfood::BYPRO_TORTA_B();
                secondary_output = 8 * period * 5 / 8;
            } else if (input_res == altriuxfood::JAX_LINO_ACEITE()) {
                output_resource = altriuxfood::JAX_ACEITE_LINO_V2();
                actual_output = 10 * period * 2 / 10;
                secondary_res_id = altriuxfood::BYPRO_TORTA_B();
                secondary_output = 10 * period * 8 / 10;
            } else if (input_res == altriuxfood::JAX_OLIVE()) {
                output_resource = altriuxfood::JAX_ACEITE_OLIVA_V2();
                actual_output = 15 * period * 3 / 15;
                secondary_res_id = altriuxfood::BYPRO_ORUJO_C();
                secondary_output = 15 * period * 12 / 15;
            } else if (input_res == altriuxfood::JAX_COCONUT()) {
                output_resource = altriuxfood::JAX_ACEITE_COCO_V2();
                actual_output = 12 * period * 4 / 12;
                secondary_res_id = altriuxfood::BYPRO_TORTA_B();
                secondary_output = 12 * period * 8 / 12;
            } else if (input_res == altriuxfood::JAX_FLAX()) {
                output_resource = altriuxfood::JAX_LINO_HILADO();
                actual_output = 10 * period * 6 / 10;
                secondary_res_id = altriuxfood::BYPRO_LINAZA_C();
                secondary_output = 10 * period * 4 / 10;
            } else if (input_res == altriuxfood::JAX_HEMP()) {
                output_resource = altriuxfood::JAX_CANAMO_HILADO();
                actual_output = 12 * period * 7 / 12;
                secondary_res_id = altriuxfood::BYPRO_TALLOS_RESIDUALES_B();
                secondary_output = 12 * period * 5 / 12;
            } else if (input_res == altriuxfood::JAX_COTTON()) {
                output_resource = altriuxfood::JAX_HILO_ALGODON_V2();
                actual_output = 10 * period * 85 / 100; // Hiladero: 85% yield
                secondary_res_id = altriuxfood::BYPRO_SEMILLAS_ALGODON_B();
                secondary_output = 10 * period * 15 / 100;
            } else if (input_res == altriuxfood::JAX_FLAX()) {
                output_resource = altriuxfood::JAX_LINO_HILADO();
                actual_output = 10 * period * 85 / 100; // 85% yield
                secondary_res_id = altriuxfood::BYPRO_LINAZA_C();
                secondary_output = 10 * period * 15 / 100;
            } else if (input_res == altriuxfood::JAX_HEMP()) {
                output_resource = altriuxfood::JAX_CANAMO_HILADO();
                actual_output = 12 * period * 85 / 100; // 85% yield
                secondary_res_id = altriuxfood::BYPRO_TALLOS_RESIDUALES_B();
                secondary_output = 12 * period * 15 / 100;
            } else if (altriuxfood::is_textile_yarn(input_res)) {
                // Tejedero: Yarn -> Tela (90% yield)
                output_resource = altriuxfood::JAX_TELA();
                actual_output = 10 * period * 90 / 100;
            } else if (input_res == altriuxfood::JAX_TELA()) {
                // Sastreria: Tela -> Ropa (95% yield)
                output_resource = altriuxfood::JAX_ROPA();
                actual_output = 5 * period * 95 / 100; // Less throughput for tailoring
            } else if (input_res == altriuxfood::JAX_SUGAR_BEET()) {
                output_resource = altriuxmanufactured::JAX_AZUCAR();
                actual_output = 20 * period * 20 / 100;
                secondary_res_id = altriuxmanufactured::JAX_PIENSO_ANIMAL();
                secondary_output = 20 * period * 50 / 100;
            } else if (input_res == altriuxfood::JAX_SUGAR_CANE()) {
                output_resource = altriuxmanufactured::JAX_AZUCAR();
                actual_output = 20 * period * 10 / 100;
                secondary_res_id = altriuxmanufactured::JAX_PIENSO_ANIMAL();
                secondary_output = 20 * period * 10 / 100;
            } else if (input_res == altriuxmanufactured::JAX_JUGO_MANZANA() || input_res == altriuxmanufactured::JAX_JUGO_PERA()) {
                output_resource = altriuxmanufactured::JAX_CIDER();
                actual_output = 10 * period;
            } else if (input_res == altriuxmanufactured::JAX_JUGO_UVA()) {
                output_resource = altriuxmanufactured::JAX_WINE();
                actual_output = 10 * period;
            } else if (input_res == altriuxfood::JAX_CASSAVA()) {
                output_resource = altriuxfood::JAX_TAPIOCA();
                actual_output = 10 * period * 30 / 100; // 30% starch yield
                secondary_res_id = altriuxmanufactured::JAX_PIENSO_ANIMAL(); // Pulp residue
                secondary_output = 10 * period * 50 / 100;
            } else if (input_res == altriuxfood::JAX_COFFEE()) {
                output_resource = altriuxfood::JAX_COFFEE_SECADO();
                actual_output = 10 * period * 25 / 100; // 25% dry yield from cherry
                secondary_res_id = altriuxfood::BYPRO_CASCARILLA();
                secondary_output = 10 * period * 60 / 100;
            } else if (input_res == altriuxfood::JAX_COFFEE_SECADO()) {
                output_resource = altriuxfood::JAX_COFFEE_MOLIDO();
                actual_output = 10 * period * 90 / 100; // 90% yield after grinding/roasting
            } else if (input_res == altriuxfood::JAX_TABACO()) {
                output_resource = altriuxfood::JAX_TABACO_BULTOS();
                actual_output = 10 * period * 20 / 100; // 20% dry yield
            } else {
                let (res, base) = get_production_output(type_id, level);
                output_resource = res;
                actual_output = base * period;
            }
        } else {
            let (res, base) = get_production_output(type_id, level);
            output_resource = res;
            actual_output = base * altriuxbuildingbase::get_production_period(building);
        };
        let worker_count = altriuxbuildingbase::get_building_workers(building);
        let worker_bonus = worker_count * 5; // +5% por trabajador
        let period_bonus = altriuxbuildingbase::get_production_period(building) / 10; // +1% por cada 10 días de ciclo
        let total_bonus = worker_bonus + period_bonus;
        actual_output = actual_output * (100 + total_bonus) / 100;
        if (secondary_output > 0) {
            secondary_output = secondary_output * (100 + total_bonus) / 100;
        };
        
        // Aplicar bonificación de experiencia a trabajadores (+1% por día trabajado, máx +25%)
        let xp_per_worker = if (altriuxbuildingbase::get_production_period(building) > 25) 25 else altriuxbuildingbase::get_production_period(building);
        
        // Verificar capacidad de almacenamiento
        let current_storage = altriuxbuildingbase::get_current_storage(building);
        let storage_cap = altriuxbuildingbase::get_storage_capacity(building);
        if (current_storage + actual_output > storage_cap) {
            // ¡OVERFLOW! Pérdida de recursos excedentes
            let overflow = current_storage + actual_output - storage_cap;
            altriuxbuildingbase::update_storage(building, storage_cap);
            
            event::emit(StorageOverflow {
                building_id,
                resource_id: output_resource,
                overflow_amount: overflow,
                timestamp: clock::timestamp_ms(clock),
            });
        } else {
            altriuxbuildingbase::update_storage(building, current_storage + actual_output);
        };

        if (secondary_output > 0) {
            // Add secondary output directly to inventory or separate batch. 
            // For now, let's put it in inventory if provided, or another storage?
            // User requested "derivado procesado", let's use another batch for secondary.
            let s_batch = altriuxproduction::new_batch(
                building_id,
                secondary_res_id,
                secondary_output,
                altriuxbuildingbase::get_last_production(building),
                clock::timestamp_ms(clock),
                std::option::some(*altriuxbuildingbase::get_building_location(building)),
                ctx
            );
            transfer::public_transfer(s_batch, sender);
        };

        
        // Crear ProductionBatch para auditoría (con ubicación heredada)
        let batch = altriuxproduction::new_batch(
            building_id,
            output_resource,
            actual_output,
            altriuxbuildingbase::get_last_production(building),
            clock::timestamp_ms(clock),
            std::option::some(*altriuxbuildingbase::get_building_location(building)),
            ctx
        );

        transfer::public_transfer(batch, sender);
        
        // Liberar trabajadores (remover bloqueo)
        // En producción real: iterar contratos y remover campo dinámico "blocked_until"
        
        // Actualizar timestamp
        altriuxbuildingbase::reset_production(building, clock::timestamp_ms(clock));

        
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
        let building = altriuxbuildingbase::borrow_building_mut(reg, building_id);
        
        // Validar propiedad
        assert!(altriuxbuildingbase::get_building_owner(building) == sender, E_NOT_OWNER);
        
        // Validar suficientes recursos en almacenamiento
        let current_storage = altriuxbuildingbase::get_current_storage(building);
        assert!(current_storage >= amount_jax, E_INSUFFICIENT_RESOURCES);
        
        // Retirar recursos
        altriuxbuildingbase::update_storage(building, current_storage - amount_jax);
        
        // Añadir recursos al inventario del jugador
        add_jax(target_inv, resource_id, amount_jax, 0, clock);
    }

    // === TRADE AT MARKET (NO PENALTY) ===
    public fun trade_resources(
        reg: &mut BuildingRegistry,
        building_id: ID,
        from_inv: &mut Inventory,
        to_inv: &mut Inventory,
        resource_id: u64,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // We borrow the building to valid existence and ownership/presence
        // The sender doesn't necessarily need to own the market, just be AT it?
        // User said: "aplique a este edificio en buil" and "crea un gran mercado para el que aplique la misma funcion".
        // Assuming the owner of the market facilitates the trade or the trade happens via the building.
        // For simplicity reusing 'borrow_building' logic.
        let building = altriuxbuildingbase::borrow_building(reg, building_id);
        
        // Pass to trade module
        altriuxtrade::trade_via_market(from_inv, to_inv, resource_id, amount, building, clock, ctx);
    }


    // === LÓGICA DE PRODUCCIÓN REALISTA POR EDIFICIO ===
    fun get_production_output(type_id: u64, _level: u8): (u64, u64) {
        if (type_id == MINA_SUPERFICIAL) (altriuxminerals::PIEDRA_ARENOSA(), 20)
        else if (type_id == MINA_SUBTERRANEA) (altriuxminerals::GRANITO(), 15)
        else if (type_id == FUNDICION_TRIBAL) (altriuxmanufactured::HIERRO_FUNDIDO(), 1)
        else if (type_id == FUNDICION_INDUSTRIAL) (altriuxmanufactured::ACERO(), 1)
        else if (type_id == FORJA) (altriuxmanufactured::HIERRO_FORJADO(), 2)
        else if (type_id == MOLINO_FLUVIAL_GRANDE) (altriuxmanufactured::JAX_HARINA_TRIGO(), 10)
        else if (type_id == MOLINO_SANGRE_GRANDE) (altriuxmanufactured::JAX_HARINA_CEBADA(), 8)
        else if (type_id == CARBONERA) (altriuxmanufactured::CARBON_MADERA(), 2)
        else if (type_id == TALLER_TEXTIL) (altriuxmanufactured::HILO_ALGODON(), 12)
        else if (type_id == PANADERIA) (altriuxmanufactured::PAN(), 15)
        else if (type_id == CARNICERIA) (altriuxmanufactured::JAX_MEAT_PROCESSED(), 10)
        else if (type_id == altriuxbuildingbase::type_trapiche()) (altriuxmanufactured::JAX_AZUCAR(), 1)
        else if (type_id == altriuxbuildingbase::type_secadero()) (altriuxfood::JAX_COFFEE_SECADO(), 10)
        else (2, 5) // Default raw grain?
    }

    fun get_production_input(type_id: u64, _level: u8): (u64, u64) {
        if (type_id == MINA_SUPERFICIAL || type_id == MINA_SUBTERRANEA) (0, 0)
        else if (type_id == FUNDICION_TRIBAL) (altriuxminerals::MINERAL_COBRE(), 5)
        else if (type_id == FUNDICION_INDUSTRIAL) (altriuxminerals::MINERAL_HIERRO(), 10)
        else if (type_id == FORJA) (altriuxmanufactured::HIERRO_FUNDIDO(), 1)
        else if (type_id == MOLINO_FLUVIAL_GRANDE) (altriuxfood::JAX_WHEAT(), 12)
        else if (type_id == MOLINO_SANGRE_GRANDE) (altriuxfood::JAX_BARLEY(), 10)
        else if (type_id == CARBONERA) (135, 10) // 135 = MADERA_PRIMERA
        else if (type_id == TALLER_TEXTIL) (155, 10) // 155 = ALGODON_SIN_HILAR 
        else if (type_id == PANADERIA) (altriuxmanufactured::JAX_HARINA_TRIGO(), 1)
        else if (type_id == CARNICERIA) (0, 0)
        else if (type_id == AHUMADERO) (0, 0)
        else if (type_id == altriuxbuildingbase::type_trapiche()) (altriuxfood::JAX_SUGAR_CANE(), 10)
        else if (type_id == altriuxbuildingbase::type_taller_cereales()) (altriuxfood::JAX_WHEAT(), 10)
        else if (type_id == altriuxbuildingbase::type_prensa_aceite()) (altriuxfood::JAX_SUNFLOWER(), 10)
        else if (type_id == altriuxbuildingbase::type_taller_soya()) (altriuxfood::JAX_SOYBEAN(), 10)
        else if (type_id == altriuxbuildingbase::type_secadero()) (altriuxfood::JAX_COFFEE(), 10)
        else (0, 0)
    }

    // === MEAT PROCESSING & SPOILAGE ===
    public fun salt_meat(
        reg: &mut BuildingRegistry,
        building_id: ID,
        fresh_meat_batch: ProductionBatch,
        inv: &mut Inventory,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let building = altriuxbuildingbase::borrow_building_mut(reg, building_id);
        let type_id = altriuxbuildingbase::get_building_type(building);
        
        // 1. Validate building (Ahumadero or Carnicería)
        assert!(type_id == AHUMADERO || type_id == CARNICERIA, E_NOT_OWNER);
        assert!(altriuxbuildingbase::get_building_owner(building) == sender, E_NOT_OWNER);
        
        // 2. Validate Spoilage (10 hours = 36,000,000 ms)
        let now = clock::timestamp_ms(clock);
        let finish_time = altriuxproduction::finish_time(&fresh_meat_batch);
        assert!(now <= finish_time + 36000000, E_TOO_SOON); // Re-using error for spoilage
        
        // 3. Consume Salt & Wood (Medieval logic: burn salt/wood for preserving)
        let quantity = altriuxproduction::quantity(&fresh_meat_batch);
        let salt_needed = (quantity + 4) / 5; // 1 Salt per 5 Meat
        let wood_needed = (quantity + 9) / 10; // 1 Wood per 10 Meat
        
        consume_jax(inv, altriuxfood::JAX_SALT(), salt_needed, clock);
        consume_jax(inv, 135, wood_needed, clock); // Raw Wood (135)
        
        // 4. Map Fresh Output to Salted Output
        let fresh_id = altriuxproduction::product_id(&fresh_meat_batch);
        let salted_id = if (fresh_id == altriuxfood::JAX_MEAT_FRESH_LUXURY()) {
            altriuxfood::JAX_MEAT_SALTED_LUXURY()
        } else if (fresh_id == altriuxfood::JAX_MEAT_FRESH_BASIC()) {
            altriuxfood::JAX_MEAT_SALTED_BASIC()
        } else {
            altriuxfood::JAX_MEAT_SALTED_THIRD()
        };
        
        // 5. Add to building storage or return as item? User wants salted meat.
        // Let's add it to building storage.
        let current_storage = altriuxbuildingbase::get_current_storage(building);
        let storage_cap = altriuxbuildingbase::get_storage_capacity(building);
        
        if (current_storage + quantity > storage_cap) {
            altriuxbuildingbase::update_storage(building, storage_cap);
        } else {
            altriuxbuildingbase::update_storage(building, current_storage + quantity);
        };
        
        // 6. Finalize
        altriuxproduction::destroy_batch(fresh_meat_batch);
        
        event::emit(ProductionClaimed {
            building_id,
            resource_id: salted_id,
            amount_jax: quantity,
            worker_xp_gained: 5, // Fixed XP for salting
            timestamp: now,
        });
    }

    public fun start_weaving_cycle(
        reg: &mut BuildingRegistry,
        worker_reg: &mut WorkerRegistry,
        building_id: ID,
        worker_ids: vector<ID>,
        inv: &mut Inventory,
        input_resource: u64,
        period_days: u64,
        au_reg: &mut ActionPointRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let building = altriuxbuildingbase::borrow_building_mut(reg, building_id);
        let type_id = altriuxbuildingbase::get_building_type(building);
        
        assert!(altriuxbuildingbase::get_building_owner(building) == sender, E_NOT_OWNER);
        assert!(type_id == altriuxbuildingbase::type_tejedero(), E_INVALID_MILL_FUNC);
        assert!(!altriuxbuildingbase::is_production_in_progress(building), E_PRODUCTION_IN_PROGRESS);
        
        let worker_count = vector::length(&worker_ids);
        assert!(worker_count > 0 && (worker_count as u64) <= altriuxbuildingbase::get_max_workers(building), E_INVALID_WORKERS);

        // Role Check: Tejedor
        check_workers_role(worker_reg, &worker_ids, altriuxworkers::ROLE_TEJEDOR());

        // AU Logic: 2 AU per day per worker
        let total_au = (worker_count as u64) * 2 * period_days;
        altriuxactionpoints::consume_au_from_workers(au_reg, &worker_ids, total_au, b"weaving_start", clock, ctx);

        assert!(altriuxfood::is_textile_yarn(input_resource), E_INVALID_RESOURCES);
        
        altriuxresources::consume_jax(inv, input_resource, 10 * period_days, clock);

        dynamic_field::add(altriuxbuildingbase::get_building_uid_mut(building), b"active_input", input_resource);

        altriuxbuildingbase::set_production_state(
            building,
            true,
            clock::timestamp_ms(clock) + (period_days * 24 * 60 * 60 * 1000),
            period_days,
            (worker_count as u64)
        );
    }

    public fun start_tailoring_cycle(
        reg: &mut BuildingRegistry,
        worker_reg: &mut WorkerRegistry,
        building_id: ID,
        worker_ids: vector<ID>,
        inv: &mut Inventory,
        input_resource: u64,
        period_days: u64,
        au_reg: &mut ActionPointRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let building = altriuxbuildingbase::borrow_building_mut(reg, building_id);
        let type_id = altriuxbuildingbase::get_building_type(building);
        
        assert!(altriuxbuildingbase::get_building_owner(building) == sender, E_NOT_OWNER);
        assert!(type_id == altriuxbuildingbase::type_sastreria(), E_INVALID_MILL_FUNC);
        assert!(!altriuxbuildingbase::is_production_in_progress(building), E_PRODUCTION_IN_PROGRESS);
        
        let worker_count = vector::length(&worker_ids);
        assert!(worker_count > 0 && (worker_count as u64) <= altriuxbuildingbase::get_max_workers(building), E_INVALID_WORKERS);

        // Role Check: Sastre
        check_workers_role(worker_reg, &worker_ids, altriuxworkers::ROLE_SASTRE());

        // AU Logic: 2 AU per day per worker
        let total_au = (worker_count as u64) * 2 * period_days;
        altriuxactionpoints::consume_au_from_workers(au_reg, &worker_ids, total_au, b"tailoring_start", clock, ctx);

        assert!(input_resource == altriuxfood::JAX_TELA(), E_INVALID_RESOURCES);
        
        altriuxresources::consume_jax(inv, input_resource, 5 * period_days, clock);

        dynamic_field::add(altriuxbuildingbase::get_building_uid_mut(building), b"active_input", input_resource);

        altriuxbuildingbase::set_production_state(
            building,
            true,
            clock::timestamp_ms(clock) + (period_days * 24 * 60 * 60 * 1000),
            period_days,
            (worker_count as u64)
        );
    }

    public fun start_shipbuilding_cycle(
        reg: &mut BuildingRegistry,
        worker_reg: &mut WorkerRegistry,
        building_id: ID,
        worker_ids: vector<ID>,
        inv: &mut Inventory,
        input_resource: u64, // Madera_Primera
        period_days: u64,
        au_reg: &mut ActionPointRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let building = altriuxbuildingbase::borrow_building_mut(reg, building_id);
        let type_id = altriuxbuildingbase::get_building_type(building);
        
        assert!(altriuxbuildingbase::get_building_owner(building) == sender, E_NOT_OWNER);
        assert!(type_id == altriuxbuildingbase::type_astillero(), E_INVALID_MILL_FUNC);
        assert!(!altriuxbuildingbase::is_production_in_progress(building), E_PRODUCTION_IN_PROGRESS);
        
        let worker_count = vector::length(&worker_ids);
        assert!(worker_count >= 3, E_INVALID_WORKERS); // Requiere equipo mínimo

        // Specialized Team Check: equipo variado
        let mut roles = vector::empty();
        vector::push_back(&mut roles, altriuxworkers::ROLE_HERRERO());
        vector::push_back(&mut roles, altriuxworkers::ROLE_CARPINTERO());
        vector::push_back(&mut roles, altriuxworkers::ROLE_CONSTRUCTOR());
        
        check_workers_roles_any(worker_reg, &worker_ids, roles);

        // AU Logic: 2 AU per day per worker
        let total_au = (worker_count as u64) * 2 * period_days;
        altriuxactionpoints::consume_au_from_workers(au_reg, &worker_ids, total_au, b"shipbuilding_start", clock, ctx);

        // Madera_Primera (135)
        assert!(input_resource == 135, E_INVALID_RESOURCES);
        
        altriuxresources::consume_jax(inv, input_resource, 50 * period_days, clock); // Much wood

        dynamic_field::add(altriuxbuildingbase::get_building_uid_mut(building), b"active_input", input_resource);

        altriuxbuildingbase::set_production_state(
            building,
            true,
            clock::timestamp_ms(clock) + (period_days * 24 * 60 * 60 * 1000),
            period_days,
            (worker_count as u64)
        );
    }

    public fun start_mining_cycle(
        reg: &mut BuildingRegistry,
        worker_reg: &mut WorkerRegistry,
        building_id: ID,
        worker_ids: vector<ID>,
        _inv: &mut Inventory,
        _input_resource: u64, 
        period_days: u64,
        au_reg: &mut ActionPointRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let building = altriuxbuildingbase::borrow_building_mut(reg, building_id);
        let type_id = altriuxbuildingbase::get_building_type(building);
        
        assert!(altriuxbuildingbase::get_building_owner(building) == sender, E_NOT_OWNER);
        assert!(type_id == MINA_SUPERFICIAL || type_id == MINA_SUBTERRANEA, E_INVALID_MILL_FUNC);
        assert!(!altriuxbuildingbase::is_production_in_progress(building), E_PRODUCTION_IN_PROGRESS);
        
        let worker_count = vector::length(&worker_ids);
        assert!(worker_count > 0 && (worker_count as u64) <= altriuxbuildingbase::get_max_workers(building), E_INVALID_WORKERS);

        // Role Check: Minero
        check_workers_role(worker_reg, &worker_ids, altriuxworkers::ROLE_MINERO());

        // AU Logic: 2 AU per day per worker
        let total_au = (worker_count as u64) * 2 * period_days;
        altriuxactionpoints::consume_au_from_workers(au_reg, &worker_ids, total_au, b"mining_start", clock, ctx);

        altriuxbuildingbase::set_production_state(
            building,
            true,
            clock::timestamp_ms(clock) + (period_days * 24 * 60 * 60 * 1000),
            period_days,
            (worker_count as u64)
        );
    }





    // === COSTOS DE CONSTRUCCIÓN REALISTAS (OPTIMIZADO) ===
    fun get_construction_costs(type_id: u64, level: u8): (vector<ResourceCost>, vector<u64>) {
        let costs = if (type_id == altriuxbuildingbase::type_granja_pequena() && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(135, 50));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(203, 20));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(200, 10));
            v
        } else if (type_id == altriuxbuildingbase::type_granja_mediana() && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(198, 100));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(204, 80));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(200, 50));
            v
        } else if (type_id == FUNDICION_TRIBAL && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(198, 100));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(204, 80));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(200, 50));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(219, 30));
            v
        } else if (type_id == FUNDICION_INDUSTRIAL && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(198, 250));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(204, 150));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(200, 100));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(219, 80));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(130, 40));
            v
        } else if (type_id == MOLINO_FLUVIAL_GRANDE && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(137, 200));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(198, 150));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(204, 100));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(148, 60));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(130, 20));
            v
        } else if (type_id == MOLINO_SANGRE_GRANDE && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(135, 140));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(196, 90));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(204, 70));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(220, 25));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(130, 15));
            v
        } else if (type_id == CARBONERA && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(135, 80));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(196, 40));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(204, 30));
            v
        } else if (type_id == TALLER_TEXTIL && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(135, 120));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(196, 60));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(220, 30));
            v
        } else if (type_id == PANADERIA && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(135, 60));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(196, 40));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(200, 20));
            v
        } else if (type_id == altriuxbuildingbase::type_mesquita_imlax_pequena() && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(196, 200));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(135, 100));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(200, 50));
            v
        } else if (type_id == altriuxbuildingbase::type_mesquita_imlax_grande() && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(198, 500));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(199, 200));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(137, 150));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(213, 50));
            v
        } else if (type_id == altriuxbuildingbase::type_madrasa_imlax() && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(196, 150));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(135, 120));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(206, 40));
            v
        } else if (type_id == altriuxbuildingbase::type_iglesia_cris_pequena() && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(135, 180));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(196, 100));
            v
        } else if (type_id == altriuxbuildingbase::type_catedral_cris() && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(196, 600));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(199, 100));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(213, 80));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(130, 50));
            v
        } else if (type_id == ESCUELA_DRAXIUX && level == 1) {
             let mut v = vector::empty<ResourceCost>();
             vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(198, 250));
             vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(130, 60));
             v
        } else if (type_id == MONASTERIO_DRAXIUX && level == 1) {
             let mut v = vector::empty<ResourceCost>();
             vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(198, 400));
             vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(130, 100));
             vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(148, 100));
             v
        } else if (type_id == TEMPLO_SHIX && level == 1) {
             let mut v = vector::empty<ResourceCost>();
             vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(137, 400));
             vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(200, 200));
             vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(212, 50));
             v
        } else if (type_id == altriuxbuildingbase::type_escuela_shix() && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(135, 200));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(196, 50));
            v
        } else if (type_id == altriuxbuildingbase::type_sinagoga_yax() && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(196, 300));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(137, 100));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(220, 40));
            v
        } else if (type_id == altriuxbuildingbase::type_escuela_yax() && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(196, 150));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(135, 100));
            v
        } else if (type_id == altriuxbuildingbase::type_templo_sux() && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(200, 400));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(202, 100));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(119, 20));
            v
        } else if (type_id == altriuxbuildingbase::type_escuela_astronomica_sux() && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(200, 300));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(202, 50));
            v
        } else if (type_id == altriuxbuildingbase::type_trapiche() && level == 1) {
             let mut v = vector::empty<ResourceCost>();
             vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(198, 300));
             vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(204, 150));
             vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(130, 80));
             vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(219, 50));
             v
        } else if (type_id == altriuxbuildingbase::type_muralla_piedra() && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(198, 120));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(204, 80));
            v
        } else if (type_id == altriuxbuildingbase::type_torre_vigia() && level == 1) {
            let mut v = vector::empty<ResourceCost>();
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(137, 100));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(198, 150));
            vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(204, 90));
            v
        } else if (type_id == GRAN_MERCADO && level == 1) {
             let mut v = vector::empty<ResourceCost>();
             vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(198, 400)); // Stone
             vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(137, 200)); // Premium Logs
             vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(204, 100)); // Iron
             v
        } else {
             let mut v = vector::empty<ResourceCost>();
             vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(135, 100));
             vector::push_back(&mut v, altriuxbuildingbase::new_resource_cost(196, 50));
             v
        };
        
        (costs, vector::empty<u64>())
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
            if (type_id == altriuxbuildingbase::type_granja_pequena()) (2500, 5, 100, 50)
            else if (type_id == altriuxbuildingbase::type_granja_mediana()) (5000, 5, 250, 40)
            else if (type_id == altriuxbuildingbase::type_granja_grande()) (10000, 12, 500, 40)
            else if (type_id == altriuxbuildingbase::type_huerto()) (500, 5, 200, 50)
            else if (type_id == altriuxbuildingbase::type_ahumadero()) (250, 5, 250, 35)
            // Nuevos edificios religiosos
            else if (type_id == altriuxbuildingbase::type_mesquita_imlax_pequena()) (300, 5, 200, 25)
            else if (type_id == altriuxbuildingbase::type_mesquita_imlax_grande()) (800, 5, 200, 25)
            else if (type_id == altriuxbuildingbase::type_madrasa_imlax()) (400, 5, 200, 25)
            else if (type_id == altriuxbuildingbase::type_iglesia_cris_pequena()) (250, 5, 200, 25)
            else if (type_id == altriuxbuildingbase::type_catedral_cris()) (1000, 5, 200, 25)
            else if (type_id == altriuxbuildingbase::type_escuela_draxiux()) (350, 5, 200, 25)
            else if (type_id == altriuxbuildingbase::type_monasterio_draxiux()) (500, 5, 200, 25)
            else if (type_id == altriuxbuildingbase::type_templo_shix()) (450, 5, 200, 25)
            else if (type_id == altriuxbuildingbase::type_escuela_shix()) (300, 5, 200, 25)
            else if (type_id == altriuxbuildingbase::type_sinagoga_yax()) (400, 5, 200, 25)
            else if (type_id == altriuxbuildingbase::type_escuela_yax()) (300, 5, 200, 25)
            else if (type_id == altriuxbuildingbase::type_templo_sux()) (600, 5, 200, 25)
            else if (type_id == altriuxbuildingbase::type_escuela_astronomica_sux()) (400, 5, 200, 25)
            
            else if (type_id == MURALLA_MADERA) (100, 5, 200, 35)
            else if (type_id == MURALLA_PIEDRA) (120, 5, 200, 35)
            else if (type_id == TORRE_VIGIA) (80, 5, 200, 35)
            else if (type_id == FOSO) (50, 5, 200, 35)
            else if (type_id == GRANJA_ANIMALES) (1500, 5, 200, 35)
            else if (type_id == PESQUERIA) (300, 5, 200, 35)
            else if (type_id == TALLER_MADERA) (350, 5, 200, 35)
            else if (type_id == TALLER_PIEDRA) (400, 5, 200, 35)
            else if (type_id == TALLER_PIEDRA) (400, 5, 200, 35)
            else if (type_id == MERCADO) (500, 5, 500, 35)
            else if (type_id == GRAN_MERCADO) (1000, 10, 2000, 35)
            
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
            
            else if (type_id == altriuxbuildingbase::type_trapiche()) (600, 10, 500, 35)
            
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

    fun check_workers_role(worker_reg: &WorkerRegistry, worker_ids: &vector<ID>, required_role: u8) {
        let mut i = 0;
        let len = vector::length(worker_ids);
        while (i < len) {
            let w_id = *vector::borrow(worker_ids, i);
            let worker = altriuxworkers::borrow_worker(worker_reg, w_id);
            assert!(altriuxworkers::get_worker_role(worker) == required_role, E_INVALID_WORKERS);
            i = i + 1;
        }
    }

    /// Checks if the worker group contains any of the required roles (for complex buildings)
    fun check_workers_roles_any(worker_reg: &WorkerRegistry, worker_ids: &vector<ID>, required_roles: vector<u8>) {
        let mut i = 0;
        let len = vector::length(worker_ids);
        while (i < len) {
            let w_id = *vector::borrow(worker_ids, i);
            let worker = altriuxworkers::borrow_worker(worker_reg, w_id);
            let role = altriuxworkers::get_worker_role(worker);
            assert!(vector::contains(&required_roles, &role), E_INVALID_WORKERS);
            i = i + 1;
        }
    }

    fun is_mill_type(type_id: u64): bool {
        type_id == MOLINO_FLUVIAL_PEQUENO || type_id == MOLINO_FLUVIAL_GRANDE || 
        type_id == MOLINO_SANGRE_PEQUENO || type_id == MOLINO_SANGRE_GRANDE ||
        type_id == altriuxbuildingbase::type_molino_piedra() || type_id == altriuxbuildingbase::type_descascarilladora() ||
        type_id == altriuxbuildingbase::type_prensa_aceite() || type_id == altriuxbuildingbase::type_taller_soya() ||
        type_id == altriuxbuildingbase::type_molino_mani() || type_id == altriuxbuildingbase::type_molino_legumbres() ||
        type_id == altriuxbuildingbase::type_secadero() || type_id == altriuxbuildingbase::type_molino_aceitunas() ||
        type_id == altriuxbuildingbase::type_prensa_tropical() ||
        type_id == altriuxbuildingbase::type_hiladero() || type_id == altriuxbuildingbase::type_tejedero()
    }

    // === RESTORED PUBLIC GETTERS ===
    public fun id_market(): u64 { MERCADO }
    
    public fun get_building_type(building: &BuildingNFT): u64 {
        altriuxbuildingbase::get_building_type(building)

    }
    
    public fun get_building_tile(building: &BuildingNFT): u64 {
        altriuxbuildingbase::get_building_tile(building)
    }

    public fun get_building_coords(building: &BuildingNFT): (u64, u64) {
        let loc = altriuxbuildingbase::get_building_location(building);
        (
            altriux::altriuxlocation::get_hq(loc), 
            altriux::altriuxlocation::get_hr(loc)
        )
    }

    
    // Legacy getters removed, need to update callsites in build/demolish/claim

}