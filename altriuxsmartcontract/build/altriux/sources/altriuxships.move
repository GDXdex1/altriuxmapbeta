module altriux::altriuxships {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::transfer;
    use sui::table::{Self, Table};
    use sui::dynamic_field;
    use std::option::{Self, Option};
    use altriux::altriuxresources::{Self, Inventory, Sail, consume_jax, create_inventory, has_jax};
    use altriux::altriuxlocation::{Self, LocationRegistry, encode_coordinates, decode_coordinates, get_terrain_type, terrain_coast};
    use altriux::altriuxworkers::{Self, WorkerRegistry, WorkerContract};
    use altriux::altriuxbuildings::{Self, BuildingRegistry, BuildingNFT};
    use altriux::kingdomutils;
    use sui::event;

    // === TIPOS DE BARCO (Conservados del original) ===
    // Merchant (1-20)
    const SHIP_BARGE: u8 = 1;
    const SHIP_COASTER: u8 = 2;
    const SHIP_COG: u8 = 3;
    const SHIP_HULK: u8 = 4;
    const SHIP_KNOCK: u8 = 5;
    const SHIP_LUMBER: u8 = 6;
    const SHIP_GRAIN: u8 = 7;
    const SHIP_WINE: u8 = 8;
    const SHIP_SALT: u8 = 9;
    const SHIP_TEXTILE: u8 = 10;
    const SHIP_FLUYT: u8 = 11;
    const SHIP_CARAVEL: u8 = 12;
    const SHIP_NAO: u8 = 13;
    const SHIP_GALLEON: u8 = 14;
    const SHIP_MERCHANTMAN: u8 = 15;
    const SHIP_EAST_INDIAMAN: u8 = 16;
    const SHIP_WEST_INDIAMAN: u8 = 17;
    const SHIP_TREASURE_SHIP: u8 = 18;
    const SHIP_SUPPLY_SHIP: u8 = 19;
    const SHIP_COLONIAL: u8 = 20;

    // Warships (21-40)
    const SHIP_GALLEY: u8 = 21;
    const SHIP_QUINQUEREME: u8 = 22;
    const SHIP_TRIREME: u8 = 23;
    const SHIP_LIBURNIAN: u8 = 24;
    const SHIP_DROMON: u8 = 25;
    const SHIP_LONGSHIP: u8 = 26;
    const SHIP_DRAGONSHIP: u8 = 27;
    const SHIP_KNARR: u8 = 28;
    const SHIP_BALINGER: u8 = 29;
    const SHIP_CARRACK_WAR: u8 = 30;
    const SHIP_GALLEASS: u8 = 31;
    const SHIP_WAR_GALLEON: u8 = 32;
    const SHIP_FRIGATE: u8 = 33;
    const SHIP_SHIP_OF_THE_LINE: u8 = 34;
    const SHIP_RATE_OF_THE_LINE: u8 = 35;
    const SHIP_CORVETTE: u8 = 36;
    const SHIP_SLOOP_OF_WAR: u8 = 37;
    const SHIP_BRIG: u8 = 38;
    const SHIP_CUTTER: u8 = 39;
    const SHIP_BOMB_VESSEL: u8 = 40;

    // === NIVELES DE ASTILLERO ===
    const SHIPYARD_RUDIMENTARY: u8 = 1;  // 1 mástil máximo, 1 slot
    const SHIPYARD_COMMUNAL: u8 = 2;     // 1-3 mástiles, 2 slots
    const SHIPYARD_INDUSTRIAL: u8 = 3;   // 1-4 mástiles, 3 slots

    // === RECURSOS (IDs de altriuxresources) ===
    const JAX_MADERA_DURA: u64 = 153;
    const JAX_VIGA_LARGA: u64 = 142;
    const JAX_BREA_VEGETAL: u64 = 209;
    const JAX_CLAVOS: u64 = 219;
    const JAX_JARCIAS: u64 = 215;
    const JAX_FOQUE: u64 = 216;
    const JAX_CONTRAFOQUE: u64 = 217;
    const JAX_BAUPRES: u64 = 218;

    // === ERRORES ===
    const E_NOT_OWNER: u64 = 101;
    const E_INVALID_LOCATION: u64 = 102;
    const E_NO_BLUEPRINT: u64 = 103;
    const E_INSUFFICIENT_RESOURCES: u64 = 104;
    const E_SHIPYARD_FULL: u64 = 105;
    const E_INVALID_SHIPYARD_LEVEL: u64 = 106;
    const E_NOT_COASTAL: u64 = 107;
    const E_NO_WORKERS: u64 = 108;
    const E_WORKERS_NOT_BLOCKED: u64 = 109;
    const E_CONSTRUCTION_INCOMPLETE: u64 = 110;
    const E_INVALID_SLOT: u64 = 111;

    // === STRUCTS ===
    public struct ShipRegistry has key {
        id: UID,
        ships: Table<ID, Ship>,
        blueprints: Table<ID, ShipBlueprint>,
        shipyards: Table<ID, Shipyard>,
    }

    public struct ShipBlueprint has key, store {
        id: UID,
        ship_type: u8,
        owner: address,
    }

    public struct Shipyard has key, store {
        id: UID,
        owner: address,
        location_key: u64,          // Coordenada codificada (q,r)
        shipyard_level: u8,         // 1=Rudimentary, 2=Communal, 3=Industrial
        slots: vector<Option<ShipUnderConstruction>>, // 1-3 slots según nivel
    }

    public struct ShipUnderConstruction has store, copy, drop {
        ship_type: u8,
        required_action_points: u64,
        current_action_points: u64,
        workers_assigned: u64,
        start_time: u64,
        last_update: u64,
    }

    public struct Ship has key, store {
        id: UID,
        owner: address,
        location_key: u64,          // ¡UBICACIÓN OBLIGATORIA ON-CHAIN!
        ship_type: u8,
        name: vector<u8>,
        hp: u64,
        max_hp: u64,
        displacement_jax: u64,
        volume_capacity_jix: u64,
        masts: u8,
        sails: vector<Sail>,
        speed_kmh: u8,
        crew_needed: u16,
        passenger_cap: u16,
    }

    // === EVENTS ===
    public struct BlueprintMinted has copy, drop {
        blueprint_id: ID,
        ship_type: u8,
        owner: address,
        timestamp: u64,
    }

    public struct ShipyardBuilt has copy, drop {
        shipyard_id: ID,
        level: u8,
        location_key: u64,
        owner: address,
        timestamp: u64,
    }

    public struct ConstructionStarted has copy, drop {
        shipyard_id: ID,
        slot_index: u64,
        ship_type: u8,
        required_ua: u64,
        timestamp: u64,
    }

    public struct ConstructionProgress has copy, drop {
        shipyard_id: ID,
        slot_index: u64,
        ua_added: u64,
        total_ua: u64,
        timestamp: u64,
    }

    public struct ShipLaunched has copy, drop {
        ship_id: ID,
        ship_type: u8,
        owner: address,
        location_key: u64,
        timestamp: u64,
    }

    // === INICIALIZACIÓN ===
    public fun init_ship_registry(ctx: &mut TxContext) {
        let registry = ShipRegistry {
            id: object::new(ctx),
            ships: table::new(ctx),
            blueprints: table::new(ctx),
            shipyards: table::new(ctx),
        };
        transfer::share_object(registry);
    }

    // === CREACIÓN DE PLANO NFT (Requisito para construcción) ===
    public fun mint_blueprint(
        reg: &mut ShipRegistry,
        ship_type: u8,
        recipient: address,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        let blueprint = ShipBlueprint {
            id: object::new(ctx),
            ship_type,
            owner: recipient,
        };
        let id = object::id(&blueprint);
        table::add(&mut reg.blueprints, id, blueprint);
        
        event::emit(BlueprintMinted {
            blueprint_id: id,
            ship_type,
            owner: recipient,
            timestamp: clock::timestamp_ms(clock),
        });
        
        id
    }

    // === CONSTRUCCIÓN DE ASTILLERO (Requiere ubicación costera) ===
    public fun build_shipyard(
        reg: &mut ShipRegistry,
        loc_reg: &LocationRegistry,
        _building_reg: &BuildingRegistry,
        shipyard_level: u8,
        q: u64,
        r: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        let sender = tx_context::sender(ctx);
        let location_key = encode_coordinates(q, r);
        
        // Validar coordenadas (offset encoding: q ∈ [0, 419], r ∈ [0, 219])
        assert!(q < 420, E_INVALID_LOCATION);
        assert!(r < 220, E_INVALID_LOCATION);
        
        // Validar terreno costero
        let terrain = get_terrain_type(loc_reg, q, r);
        assert!(terrain == terrain_coast(), E_NOT_COASTAL);
        
        // Validar nivel de astillero válido
        assert!(shipyard_level >= 1 && shipyard_level <= 3, E_INVALID_SHIPYARD_LEVEL);
        
        // Crear slots según nivel
        let mut slots = vector::empty<Option<ShipUnderConstruction>>();
        let slot_count = if (shipyard_level == SHIPYARD_RUDIMENTARY) 1 
                       else if (shipyard_level == SHIPYARD_COMMUNAL) 2 
                       else 3;
        let mut i = 0;
        while (i < slot_count) {
            vector::push_back(&mut slots, option::none());
            i = i + 1;
        };
        
        let shipyard = Shipyard {
            id: object::new(ctx),
            owner: sender,
            location_key,
            shipyard_level,
            slots,
        };
        
        let id = object::id(&shipyard);
        table::add(&mut reg.shipyards, id, shipyard);
        
        event::emit(ShipyardBuilt {
            shipyard_id: id,
            level: shipyard_level,
            location_key,
            owner: sender,
            timestamp: clock::timestamp_ms(clock),
        });
        
        id
    }

    // === INICIO DE CONSTRUCCIÓN (Consume plano + recursos) ===
    public fun start_ship_construction(
        reg: &mut ShipRegistry,
        loc_reg: &LocationRegistry,
        worker_reg: &mut WorkerRegistry,
        blueprint_id: ID,
        shipyard_id: ID,
        worker_ids: vector<ID>,
        resource_inv: &mut Inventory,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let now = clock::timestamp_ms(clock);
        
        // Validar plano
        assert!(table::contains(&reg.blueprints, blueprint_id), E_NO_BLUEPRINT);
        let blueprint = table::borrow(&reg.blueprints, blueprint_id);
        assert!(blueprint.owner == sender, E_NOT_OWNER);
        let ship_type = blueprint.ship_type;
        
        // Validar astillero
        assert!(table::contains(&reg.shipyards, shipyard_id), E_INVALID_LOCATION);
        let shipyard = table::borrow_mut(&mut reg.shipyards, shipyard_id);
        assert!(shipyard.owner == sender, E_NOT_OWNER);
        
        // Validar ubicación costera (doble verificación)
        let (q, r) = decode_coordinates(shipyard.location_key);
        let terrain = get_terrain_type(loc_reg, q, r);
        assert!(terrain == terrain_coast(), E_NOT_COASTAL);
        
        // Validar nivel de astillero vs mástiles del barco
        let (_, _, _, masts, _, _, _) = get_all_specs(ship_type);
        assert!(masts <= shipyard.shipyard_level + 1, E_INVALID_SHIPYARD_LEVEL); // Rudimentary=1 mástil, Industrial=4 mástiles
        
        // Encontrar slot libre
        let mut slot_index = 0;
        let mut found = false;
        let mut i = 0;
        while (i < vector::length(&shipyard.slots)) {
            if (option::is_none(vector::borrow(&shipyard.slots, i))) {
                slot_index = i;
                found = true;
                break;
            };
            i = i + 1;
        };
        assert!(found, E_SHIPYARD_FULL);
        
        // Validar recursos suficientes
        let (displ, _, _, _, _, _, _) = get_all_specs(ship_type);
        let wood_required = displ * 10;
        let nails_required = displ;
        let tar_required = displ / 2;
        let beams_required = (masts as u64);
        let ropes_required = (masts as u64) * 2;
        
        assert!(has_jax(resource_inv, JAX_MADERA_DURA, wood_required), E_INSUFFICIENT_RESOURCES);
        assert!(has_jax(resource_inv, JAX_CLAVOS, nails_required), E_INSUFFICIENT_RESOURCES);
        assert!(has_jax(resource_inv, JAX_BREA_VEGETAL, tar_required), E_INSUFFICIENT_RESOURCES);
        assert!(has_jax(resource_inv, JAX_VIGA_LARGA, beams_required), E_INSUFFICIENT_RESOURCES);
        assert!(has_jax(resource_inv, JAX_JARCIAS, ropes_required), E_INSUFFICIENT_RESOURCES);
        assert!(has_jax(resource_inv, JAX_BAUPRES, 1), E_INSUFFICIENT_RESOURCES);
        assert!(has_jax(resource_inv, JAX_FOQUE, 1), E_INSUFFICIENT_RESOURCES);
        assert!(has_jax(resource_inv, JAX_CONTRAFOQUE, 1), E_INSUFFICIENT_RESOURCES);
        
        // Consumir recursos
        consume_jax(resource_inv, JAX_MADERA_DURA, wood_required, clock);
        consume_jax(resource_inv, JAX_CLAVOS, nails_required, clock);
        consume_jax(resource_inv, JAX_BREA_VEGETAL, tar_required, clock);
        consume_jax(resource_inv, JAX_VIGA_LARGA, beams_required, clock);
        consume_jax(resource_inv, JAX_JARCIAS, ropes_required, clock);
        consume_jax(resource_inv, JAX_BAUPRES, 1, clock);
        consume_jax(resource_inv, JAX_FOQUE, 1, clock);
        consume_jax(resource_inv, JAX_CONTRAFOQUE, 1, clock);
        
        // Consumir plano
        let ShipBlueprint { id: blueprint_uid, ship_type: _, owner: _ } = table::remove(&mut reg.blueprints, blueprint_id);
        object::delete(blueprint_uid);
        
        // Validar trabajadores
        let worker_count = vector::length(&worker_ids);
        assert!(worker_count > 0, E_NO_WORKERS);
        
        // Bloquear trabajadores
        let mut j = 0;
        while (j < worker_count) {
            let wid = *vector::borrow(&worker_ids, j);
            assert!(altriux::altriuxworkers::is_worker_registered(worker_reg, wid), E_WORKERS_NOT_BLOCKED);
            assert!(altriux::altriuxworkers::get_worker_owner(worker_reg, wid) == sender, E_NOT_OWNER);
            assert!(altriux::altriuxworkers::is_worker_active(worker_reg, wid), E_WORKERS_NOT_BLOCKED);
            
            // Bloquear por duración de construcción (máx 90 días blockchain)
            let worker_uid = altriux::altriuxworkers::borrow_worker_id_mut(worker_reg, wid);
            dynamic_field::add(worker_uid, b"blocked_until", now + (90 * 24 * 60 * 60 * 1000));
            j = j + 1;
        };
        
        // Calcular unidades de acción requeridas
        let required_ua = get_required_action_points(ship_type, shipyard.shipyard_level);
        
        // Crear objeto de construcción
        let construction = ShipUnderConstruction {
            ship_type,
            required_action_points: required_ua,
            current_action_points: 0,
            workers_assigned: worker_count as u64,
            start_time: now,
            last_update: now,
        };
        
        // Asignar a slot
        *vector::borrow_mut(&mut shipyard.slots, slot_index) = option::some(construction);
        
        event::emit(ConstructionStarted {
            shipyard_id,
            slot_index,
            ship_type,
            required_ua,
            timestamp: now,
        });
    }

    // === PROGRESO DE CONSTRUCCIÓN (Aplica unidades de acción) ===
    public fun apply_construction_progress(
        reg: &mut ShipRegistry,
        shipyard_id: ID,
        slot_index: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let now = clock::timestamp_ms(clock);
        
        assert!(table::contains(&reg.shipyards, shipyard_id), E_INVALID_LOCATION);
        let shipyard = table::borrow_mut(&mut reg.shipyards, shipyard_id);
        assert!(shipyard.owner == sender, E_NOT_OWNER);
        
        // Validar slot
        assert!(slot_index < vector::length(&shipyard.slots), E_INVALID_SLOT);
        let slot = vector::borrow_mut(&mut shipyard.slots, slot_index);
        assert!(option::is_some(slot), E_INVALID_SLOT);
        
        let mut construction = option::extract(slot);
        
        // Calcular progreso (2 UA por trabajador por día blockchain)
        let days_elapsed = (now - construction.last_update) / (24 * 60 * 60 * 1000);
        let ua_earned = construction.workers_assigned * 2 * days_elapsed;
        
        construction.current_action_points = construction.current_action_points + ua_earned;
        construction.last_update = now;
        
        // Verificar completado
        if (construction.current_action_points >= construction.required_action_points) {
            // Lanzar barco (mint NFT)
            let (displ, vol, hp, masts, speed, crew, pass) = get_all_specs(construction.ship_type);
            
            let ship = Ship {
                id: object::new(ctx),
                owner: sender,
                location_key: shipyard.location_key,
                ship_type: construction.ship_type,
                name: b"Unnamed Ship",
                hp,
                max_hp: hp,
                displacement_jax: displ,
                volume_capacity_jix: vol,
                masts,
                sails: vector::empty(),
                speed_kmh: speed,
                crew_needed: crew,
                passenger_cap: pass,
            };
            
            let ship_id = object::id(&ship);
            table::add(&mut reg.ships, ship_id, ship);
            
            // Liberar slot
            *slot = option::none();
            
            event::emit(ShipLaunched {
                ship_id,
                ship_type: construction.ship_type,
                owner: sender,
                location_key: shipyard.location_key,
                timestamp: now,
            });
        } else {
            // Actualizar construcción
            *slot = option::some(construction);
            
            event::emit(ConstructionProgress {
                shipyard_id,
                slot_index,
                ua_added: ua_earned,
                total_ua: construction.current_action_points,
                timestamp: now,
            });
        };
    }

    // === CARGA/DESCARGA CON VALIDACIÓN DE PROPIEDAD ===
    public fun load_cargo(
        reg: &mut ShipRegistry,
        ship_id: ID,
        type_id: u64,
        amount: u64,
        from_inv: &mut Inventory,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(table::contains(&reg.ships, ship_id), E_INVALID_LOCATION);
        let ship = table::borrow_mut(&mut reg.ships, ship_id);
        assert!(ship.owner == sender, E_NOT_OWNER); // ¡VALIDACIÓN CRÍTICA!
        
        let ship_inv = dynamic_field::borrow_mut<vector<u8>, Inventory>(&mut ship.id, b"inventory");
        altriuxresources::transfer_jax(from_inv, ship_inv, type_id, amount, clock);
    }

    public fun unload_cargo(
        reg: &mut ShipRegistry,
        ship_id: ID,
        type_id: u64,
        amount: u64,
        to_inv: &mut Inventory,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(table::contains(&reg.ships, ship_id), E_INVALID_LOCATION);
        let ship = table::borrow_mut(&mut reg.ships, ship_id);
        assert!(ship.owner == sender, E_NOT_OWNER); // ¡VALIDACIÓN CRÍTICA!
        
        let ship_inv = dynamic_field::borrow_mut<vector<u8>, Inventory>(&mut ship.id, b"inventory");
        altriuxresources::transfer_jax(ship_inv, to_inv, type_id, amount, clock);
    }

    // === UNIDADES DE ACCIÓN REQUERIDAS (Cálculo histórico preciso) ===
    fun get_required_action_points(ship_type: u8, shipyard_level: u8): u64 {
        // Base UA según desplazamiento (1 UA por 10 JAX de desplazamiento por día)
        // Multiplicador por complejidad histórica
        let base_ua = if (ship_type == SHIP_BARGE) 100
            else if (ship_type == SHIP_COASTER) 200
            else if (ship_type == SHIP_COG) 400
            else if (ship_type == SHIP_HULK) 600
            else if (ship_type == SHIP_KNOCK) 150
            else if (ship_type == SHIP_LUMBER) 500
            else if (ship_type == SHIP_GRAIN) 450
            else if (ship_type == SHIP_WINE) 300
            else if (ship_type == SHIP_SALT) 220
            else if (ship_type == SHIP_TEXTILE) 350
            else if (ship_type == SHIP_FLUYT) 1200
            else if (ship_type == SHIP_CARAVEL) 2400
            else if (ship_type == SHIP_NAO) 1400
            else if (ship_type == SHIP_GALLEON) 2400
            else if (ship_type == SHIP_MERCHANTMAN) 2000
            else if (ship_type == SHIP_EAST_INDIAMAN) 3000
            else if (ship_type == SHIP_WEST_INDIAMAN) 2600
            else if (ship_type == SHIP_TREASURE_SHIP) 4000
            else if (ship_type == SHIP_SUPPLY_SHIP) 1000
            else if (ship_type == SHIP_COLONIAL) 1800
            else if (ship_type == SHIP_GALLEY) 500
            else if (ship_type == SHIP_QUINQUEREME) 700
            else if (ship_type == SHIP_TRIREME) 600
            else if (ship_type == SHIP_LIBURNIAN) 400
            else if (ship_type == SHIP_DROMON) 900
            else if (ship_type == SHIP_LONGSHIP) 300
            else if (ship_type == SHIP_DRAGONSHIP) 360
            else if (ship_type == SHIP_KNARR) 800
            else if (ship_type == SHIP_BALINGER) 560
            else if (ship_type == SHIP_CARRACK_WAR) 1000
            else if (ship_type == SHIP_GALLEASS) 1300
            else if (ship_type == SHIP_WAR_GALLEON) 1600
            else if (ship_type == SHIP_FRIGATE) 1200
            else if (ship_type == SHIP_SHIP_OF_THE_LINE) 2000
            else if (ship_type == SHIP_RATE_OF_THE_LINE) 1800
            else if (ship_type == SHIP_CORVETTE) 700
            else if (ship_type == SHIP_SLOOP_OF_WAR) 400
            else if (ship_type == SHIP_BRIG) 500
            else if (ship_type == SHIP_CUTTER) 250
            else if (ship_type == SHIP_BOMB_VESSEL) 1100
            else 100;
        
        // Bonificación por nivel de astillero (más eficiente = menos UA)
        let efficiency = if (shipyard_level == SHIPYARD_RUDIMENTARY) 100 
                       else if (shipyard_level == SHIPYARD_COMMUNAL) 85 
                       else 75; // Industrial = 25% más rápido
        
        (base_ua * efficiency) / 100
    }

    // === ESPECIFICACIONES DE BARCOS (Conservadas del original) ===
    fun get_all_specs(ship_type: u8): (u64, u64, u64, u8, u8, u16, u16) {
        if (ship_type <= 20) {
            get_merchant_specs(ship_type)
        } else {
            get_warship_specs(ship_type)
        }
    }

    fun get_merchant_specs(ship_type: u8): (u64, u64, u64, u8, u8, u16, u16) {
        if (ship_type == SHIP_BARGE) { (15, 50, 100, 1, 8, 4, 8) }
        else if (ship_type == SHIP_COASTER) { (25, 80, 200, 2, 10, 6, 12) }
        else if (ship_type == SHIP_COG) { (40, 120, 300, 2, 12, 8, 20) }
        else if (ship_type == SHIP_HULK) { (60, 200, 400, 1, 6, 10, 30) }
        else if (ship_type == SHIP_KNOCK) { (20, 60, 150, 1, 9, 5, 10) }
        else if (ship_type == SHIP_LUMBER) { (50, 150, 350, 2, 7, 8, 15) }
        else if (ship_type == SHIP_GRAIN) { (45, 180, 350, 2, 8, 9, 18) }
        else if (ship_type == SHIP_WINE) { (30, 90, 250, 2, 10, 6, 12) }
        else if (ship_type == SHIP_SALT) { (22, 70, 200, 1, 9, 5, 10) }
        else if (ship_type == SHIP_TEXTILE) { (35, 100, 250, 2, 11, 7, 15) }
        else if (ship_type == SHIP_FLUYT) { (80, 300, 500, 3, 13, 12, 40) }
        else if (ship_type == SHIP_CARAVEL) { (40, 150, 400, 3, 15, 8, 25) }
        else if (ship_type == SHIP_NAO) { (70, 250, 600, 3, 12, 15, 50) }
        else if (ship_type == SHIP_GALLEON) { (120, 400, 1000, 3, 10, 20, 80) }
        else if (ship_type == SHIP_MERCHANTMAN) { (100, 350, 800, 3, 11, 18, 70) }
        else if (ship_type == SHIP_EAST_INDIAMAN) { (150, 500, 1200, 3, 9, 25, 100) }
        else if (ship_type == SHIP_WEST_INDIAMAN) { (130, 450, 1100, 3, 9, 22, 90) }
        else if (ship_type == SHIP_TREASURE_SHIP) { (200, 600, 1500, 4, 8, 30, 120) }
        else if (ship_type == SHIP_SUPPLY_SHIP) { (50, 200, 400, 2, 14, 10, 30) }
        else if (ship_type == SHIP_COLONIAL) { (90, 320, 700, 3, 10, 16, 60) }
        else { (0, 0, 0, 0, 0, 0, 0) }
    }

    fun get_warship_specs(ship_type: u8): (u64, u64, u64, u8, u8, u16, u16) {
        if (ship_type == SHIP_GALLEY) { (25, 10, 300, 1, 20, 50, 20) }
        else if (ship_type == SHIP_QUINQUEREME) { (35, 15, 400, 1, 18, 80, 30) }
        else if (ship_type == SHIP_TRIREME) { (30, 12, 350, 1, 22, 70, 25) }
        else if (ship_type == SHIP_LIBURNIAN) { (20, 8, 250, 1, 25, 40, 15) }
        else if (ship_type == SHIP_DROMON) { (45, 20, 500, 2, 15, 60, 30) }
        else if (ship_type == SHIP_LONGSHIP) { (15, 6, 200, 1, 28, 30, 12) }
        else if (ship_type == SHIP_DRAGONSHIP) { (18, 8, 250, 1, 26, 35, 15) }
        else if (ship_type == SHIP_KNARR) { (40, 25, 400, 2, 16, 15, 40) }
        else if (ship_type == SHIP_BALINGER) { (28, 18, 350, 2, 18, 25, 20) }
        else if (ship_type == SHIP_CARRACK_WAR) { (50, 30, 600, 3, 14, 40, 50) }
        else if (ship_type == SHIP_GALLEASS) { (65, 40, 800, 3, 12, 60, 80) }
        else if (ship_type == SHIP_WAR_GALLEON) { (80, 35, 1000, 3, 11, 80, 100) }
        else if (ship_type == SHIP_FRIGATE) { (60, 25, 900, 3, 13, 70, 90) }
        else if (ship_type == SHIP_SHIP_OF_THE_LINE) { (100, 20, 2000, 3, 10, 100, 120) }
        else if (ship_type == SHIP_RATE_OF_THE_LINE) { (90, 18, 1800, 3, 9, 90, 110) }
        else if (ship_type == SHIP_CORVETTE) { (35, 12, 500, 2, 15, 50, 60) }
        else if (ship_type == SHIP_SLOOP_OF_WAR) { (20, 8, 400, 1, 16, 30, 40) }
        else if (ship_type == SHIP_BRIG) { (25, 15, 450, 2, 14, 40, 50) }
        else if (ship_type == SHIP_CUTTER) { (12, 5, 250, 1, 18, 20, 25) }
        else if (ship_type == SHIP_BOMB_VESSEL) { (55, 30, 700, 2, 8, 80, 60) }
        else { (0, 0, 0, 0, 0, 0, 0) }
    }

    // === GETTERS RPC ===
    public fun id_ship_caravel(): u8 { SHIP_CARAVEL }
    public fun id_shipy_rudimentary(): u8 { SHIPYARD_RUDIMENTARY }
    public fun id_shipy_communal(): u8 { SHIPYARD_COMMUNAL }
    public fun id_shipy_industrial(): u8 { SHIPYARD_INDUSTRIAL }
}