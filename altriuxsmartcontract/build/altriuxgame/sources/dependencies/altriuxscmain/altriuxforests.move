module altriux::altriuxforests {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::transfer;
    use sui::table::{Self, Table};
    use sui::dynamic_field;
    use std::vector;
    use altriux::altriuxresources::{Self, Inventory, add_jax, consume_jax, has_jax};
    use altriux::altriuxlocation::{Self, LocationRegistry, ResourceLocation, encode_coordinates, decode_coordinates, hex_distance, is_adjacent, get_terrain_type, terrain_forest, terrain_jungle, terrain_boreal_forest};
    use altriux::altriuxanimal::{Self, Animal};
    use altriux::kingdomutils;
    use altriux::altriuxactionpoints::{Self, ActionPointRegistry};
    use altriux::altriuxworkers::{Self, WorkerRegistry};
    use altriux::altriuxhero::{Self, Hero};
    use sui::event;

    // === TIPOS DE BOSQUE (Basado en bioma) ===
    const FOREST_TYPE_TEMPERATE: u8 = 1;   // Bosque templado (Europa/EE.UU.) - Bioma FOREST (11)
    const FOREST_TYPE_TROPICAL: u8 = 2;    // Selva tropical (Amazonas/Congo) - Bioma JUNGLE (9)
    const FOREST_TYPE_BOREAL: u8 = 3;      // Taiga boreal (Siberia/Canadá) - Bioma BOREAL_FOREST (10)

    // === DENSIDADES DE ÁRBOLES POR HECTÁREA (Basado en estudios ecológicos) ===
    // Temperado: 500-700 árboles/ha (promedio 600)
    // Tropical: 400-600 árboles/ha (promedio 500, pero mayor diversidad)
    // Boreal: 800-1,200 árboles/ha (promedio 1,000, coníferas densas)
    const DENSITY_TEMPERATE: u64 = 600;
    const DENSITY_TROPICAL: u64 = 500;
    const DENSITY_BOREAL: u64 = 1000;

    // === CALIDAD DE MADERA (Por árbol talado) ===
    const WOOD_PREMIUM: u8 = 1;    // Roble, nogal, ébano (10% de árboles)
    const WOOD_FIRST: u8 = 2;      // Pino, abeto, fresno (40% de árboles)
    const WOOD_SECOND: u8 = 3;     // Abedul, álamo, sauce (35% de árboles)
    const WOOD_WASTE: u8 = 4;      // Ramas, hojas, árboles enfermos (15% de árboles)

    // === RECURSOS DE MADERA (IDs de altriuxresources) ===
    const JAX_TRONCO_PREMIUM: u64 = 137;   // Roble/nogal/ébano
    const JAX_TRONCO_ESTANDAR: u64 = 138;  // Pino/abeto/fresno
    const JAX_TRONCO_ALTO: u64 = 139;      // Abedul/álamo/sauce
    const JAX_TABLON_ANCHO: u64 = 140;     // Madera procesada
    const JAX_TABLON_SEGUNDA: u64 = 141;   // Madera de segunda
    const JAX_VIGA_LARGA: u64 = 142;       // Vigas para construcción
    const JAX_CARBON_MADERA: u64 = 143;    // Carbón vegetal
    const JAX_LENA_SECA: u64 = 144;        // Leña seca
    const JAX_ASTILLAS_MADERA: u64 = 145;  // Astillas
    const JAX_VIRUTAS_MADERA: u64 = 146;   // Virutas

    // === COSTOS AU ===
    const AU_COST_LOGGING: u64 = 2; // Costo por minero por jornada (1 día juego = 3h)

    // === ERRORES ===
    const E_INVALID_FOREST: u64 = 101;
    const E_NO_WORKERS: u64 = 102;
    const E_INSUFFICIENT_ANIMALS: u64 = 103;
    const E_NOT_OWNER: u64 = 104;
    const E_TOO_SOON: u64 = 105;
    const E_FOREST_DEPLETED: u64 = 106;
    const E_INVALID_LOCATION: u64 = 107;
    const E_NO_FOREST_AT_LOCATION: u64 = 108;
    const E_NOBILITY_LABOR_RESTRICTION: u64 = 109;

    // === STRUCTS ===
    public struct ForestRegistry has key {
        id: UID,
        // Bosques gestionados (propiedad privada)
        forests: Table<ID, ForestNFT>,
        // Montones de madera públicos (cualquiera puede reclamar)
        wood_piles: Table<ID, WoodPile>,
    }

    public struct ForestNFT has key, store {
        id: UID,
        owner: address,
        location_key: u64,        // Coordenada codificada (q,r)
        forest_type: u8,          // FOREST_TYPE_*
        total_area_ha: u64,       // Área total en hectáreas
        remaining_area_ha: u64,   // Área restante sin talar
        last_logged_ts: u64,      // Último tala (timestamp)
        is_protected: bool,       // True = reserva natural (no se puede talar)
    }

    public struct WoodPile has key, store {
        id: UID,
        location_key: u64,        // Coordenada exacta del montón
        wood_type: u8,            // WOOD_PREMIUM, WOOD_FIRST, etc.
        amount_jax: u64,          // Cantidad en JAX
        logged_ts: u64,           // Timestamp de tala
        owner: address,           // Dueño actual (@0x0 = público)
    }

    // === EVENTS ===
    public struct ForestCreated has copy, drop {
        forest_id: ID,
        forest_type: u8,
        location_key: u64,
        total_area_ha: u64,
        owner: address,
        timestamp: u64,
    }

    public struct WoodLogged has copy, drop {
        forest_id: ID,
        wood_type: u8,
        amount_jax: u64,
        workers: u64,
        animals: u64,
        timestamp: u64,
    }

    public struct WoodClaimed has copy, drop {
        wood_id: ID,
        wood_type: u8,
        amount_jax: u64,
        claimer: address,
        timestamp: u64,
    }

    public struct WoodTransported has copy, drop {
        wood_id: ID,
        from_location: u64,
        to_location: u64,
        animals_used: u64,
        timestamp: u64,
    }

    // === INICIALIZACIÓN ===
    public fun create_forest_registry(ctx: &mut TxContext) {
        let registry = ForestRegistry {
            id: object::new(ctx),
            forests: table::new(ctx),
            wood_piles: table::new(ctx),
        };
        transfer::share_object(registry);
    }

    // === CREACIÓN DE BOSQUE (Basado en bioma existente) ===
    public fun create_forest_from_location(
        reg: &mut ForestRegistry,
        loc_reg: &LocationRegistry,
        q: u64,
        r: u64,
        owner: address,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        // Validar que existe bosque en esta ubicación
        let terrain = get_terrain_type(loc_reg, q, r);
        let forest_type: u8 = if (terrain == terrain_forest()) {
            FOREST_TYPE_TEMPERATE
        } else if (terrain == terrain_jungle()) {
            FOREST_TYPE_TROPICAL
        } else if (terrain == terrain_boreal_forest()) {
            FOREST_TYPE_BOREAL
        } else {
            abort E_NO_FOREST_AT_LOCATION
        };
        
        // Área estándar: 100 hectáreas (1 km²)
        let forest = ForestNFT {
            id: object::new(ctx),
            owner,
            location_key: encode_coordinates(q, r),
            forest_type,
            total_area_ha: 100,
            remaining_area_ha: 100,
            last_logged_ts: 0,
            is_protected: false,
        };
        
        let id = object::id(&forest);
        table::add(&mut reg.forests, id, forest);
        
        event::emit(ForestCreated {
            forest_id: id,
            forest_type,
            location_key: encode_coordinates(q, r),
            total_area_ha: 100,
            owner,
            timestamp: clock::timestamp_ms(clock),
        });
        
        id
    }

    // === TALADO DE BOSQUE (0.1 ha/día por trabajador) ===
    // === TALADO DE BOSQUE (0.1 ha/día por trabajador) ===
    public fun log_wood(
        reg: &mut ForestRegistry,
        forest_id: ID,
        worker_ids: vector<ID>, // Replaces num_workers: u64
        num_animals: u64, // Bueyes/caballos para transporte inicial
        hero: &Hero,
        nobility_titles: &vector<ID>,
        au_reg: &mut ActionPointRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let now = kingdomutils::get_game_time(clock);
        let (location_key, trees_logged, area_logged_ha) = {
            let forest = table::borrow_mut(&mut reg.forests, forest_id);
            // Validar propiedad
            assert!(forest.owner == sender, E_NOT_OWNER);
            
            // Validar Nobleza (Supervisión)
            assert!(altriuxhero::can_supervise_workers(object::id(hero), nobility_titles), E_NOBILITY_LABOR_RESTRICTION);

            // Validar bosque no protegido
            assert!(!forest.is_protected, E_FOREST_DEPLETED);
            // Validar cooldown (3 horas blockchain = 12 horas juego = 1 día jornada)
            assert!(now >= forest.last_logged_ts + 10800000, E_TOO_SOON); // 3 hours (10,800,000 ms)
            
            // Calcular área talada (0.1 ha por trabajador por día)
            let area_logged_ha = (vector::length(&worker_ids) as u64) * 1 / 10; // 0.1 ha por trabajador
            assert!(area_logged_ha > 0, E_NO_WORKERS);
            assert!(forest.remaining_area_ha >= area_logged_ha, E_FOREST_DEPLETED);
            
            // Calcular árboles talados según densidad
            let density = if (forest.forest_type == FOREST_TYPE_TEMPERATE) DENSITY_TEMPERATE
                else if (forest.forest_type == FOREST_TYPE_TROPICAL) DENSITY_TROPICAL
                else if (forest.forest_type == FOREST_TYPE_BOREAL) DENSITY_BOREAL
                else DENSITY_TEMPERATE;
            let trees_logged = area_logged_ha * density;
            (forest.location_key, trees_logged, area_logged_ha)
        };
        
        // Distribuir calidad de madera según probabilidades históricas
        let premium_trees = trees_logged * 10 / 100;   // 10% premium
        let first_trees = trees_logged * 40 / 100;     // 40% primera
        let second_trees = trees_logged * 35 / 100;    // 35% segunda
        let waste_trees = trees_logged * 15 / 100;     // 15% desecho
        
        // === VALIDACIÓN Action Points ===
        let worker_count = vector::length(&worker_ids) as u64;
        let total_au = worker_count * AU_COST_LOGGING;
        altriuxactionpoints::consume_au_from_workers(au_reg, &worker_ids, total_au, b"log_wood", clock, ctx);
        
        // Crear montones de madera pública (cualquiera puede reclamar)
        if (premium_trees > 0) {
            create_wood_pile(reg, location_key, WOOD_PREMIUM, premium_trees * 5, now, ctx); // 5 JAX por árbol premium
        };
        if (first_trees > 0) {
            create_wood_pile(reg, location_key, WOOD_FIRST, first_trees * 3, now, ctx); // 3 JAX por árbol primera
        };
        if (second_trees > 0) {
            create_wood_pile(reg, location_key, WOOD_SECOND, second_trees * 2, now, ctx); // 2 JAX por árbol segunda
        };
        if (waste_trees > 0) {
            create_wood_pile(reg, location_key, WOOD_WASTE, waste_trees * 1, now, ctx); // 1 JAX por árbol desecho (leña)
        };
        
        // Actualizar estado del bosque
        {
            let forest = table::borrow_mut(&mut reg.forests, forest_id);
            forest.remaining_area_ha = forest.remaining_area_ha - area_logged_ha;
            forest.last_logged_ts = now;
        };
        
        event::emit(WoodLogged {
            forest_id,
            wood_type: WOOD_PREMIUM, // Representativo
            amount_jax: (premium_trees * 5) + (first_trees * 3) + (second_trees * 2) + (waste_trees * 1),
            workers: vector::length(&worker_ids) as u64,
            animals: num_animals,
            timestamp: now,
        });
    }

    // === CREAR MONTÓN DE MADERA PÚBLICO ===
    fun create_wood_pile(
        reg: &mut ForestRegistry,
        location_key: u64,
        wood_type: u8,
        amount_jax: u64,
        logged_ts: u64,
        ctx: &mut TxContext
    ) {
        let pile = WoodPile {
            id: object::new(ctx),
            location_key,
            wood_type,
            amount_jax,
            logged_ts,
            owner: @0x0, // Público (cualquiera puede reclamar)
        };
        let id = object::id(&pile);
        table::add(&mut reg.wood_piles, id, pile);
    }

    // === RECLAMAR MADERA PÚBLICA ===
    public fun claim_wood(
        reg: &mut ForestRegistry,
        wood_id: ID,
        target_inv: &mut Inventory,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(table::contains(&reg.wood_piles, wood_id), E_INVALID_FOREST);
        
        // Remover montón y desestructurar (no tiene drop)
        let WoodPile { 
            id, 
            location_key: _, 
            wood_type, 
            amount_jax, 
            logged_ts: _, 
            owner: pile_owner 
        } = table::remove(&mut reg.wood_piles, wood_id);
        
        // Validar que es público o del reclamante
        assert!(pile_owner == @0x0 || pile_owner == sender, E_NOT_OWNER);
        
        // Determinar tipo de recurso según calidad
        let resource_id = if (wood_type == WOOD_PREMIUM) { JAX_TRONCO_PREMIUM }
                        else if (wood_type == WOOD_FIRST) { JAX_TRONCO_ESTANDAR }
                        else if (wood_type == WOOD_SECOND) { JAX_TRONCO_ALTO }
                        else if (wood_type == WOOD_WASTE) { JAX_LENA_SECA }
                        else { JAX_TRONCO_ESTANDAR };
        
        // Añadir madera al inventario
        add_jax(target_inv, resource_id, amount_jax, 0, clock);
        
        event::emit(WoodClaimed {
            wood_id,
            wood_type,
            amount_jax,
            claimer: sender,
            timestamp: clock::timestamp_ms(clock),
        });

        object::delete(id);
    }

    // === TRANSPORTE DE MADERA (Requiere animales de carga) ===
    public fun transport_wood(
        reg: &mut ForestRegistry,
        wood_id: ID,
        animal_ids: vector<ID>, // Bueyes/caballos para transporte
        target_q: u64,
        target_r: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(table::contains(&reg.wood_piles, wood_id), E_INVALID_FOREST);
        
        let pile = table::borrow_mut(&mut reg.wood_piles, wood_id);
        
        // Validar propiedad
        assert!(pile.owner == sender || pile.owner == @0x0, E_NOT_OWNER);
        
        // Obtener coordenadas actuales
        let (current_q, current_r) = decode_coordinates(pile.location_key);
        
        // Validar distancia (máximo 5 hexágonos por día de transporte)
        let distance = hex_distance(current_q, current_r, target_q, target_r);
        assert!(distance <= 5, E_INVALID_LOCATION);
        
        // Validar animales suficientes (1 animal por 500 JAX de madera)
        let required_animals = (pile.amount_jax + 499) / 500;
        assert!(vector::length(&animal_ids) >= required_animals, E_INSUFFICIENT_ANIMALS);
        
        // Actualizar ubicación del montón
        pile.location_key = encode_coordinates(target_q, target_r);
        pile.owner = sender; // Ahora es propiedad privada
        
        event::emit(WoodTransported {
            wood_id,
            from_location: encode_coordinates(current_q, current_r),
            to_location: encode_coordinates(target_q, target_r),
            animals_used: vector::length(&animal_ids) as u64,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // === GETTERS RPC ===
    public fun get_forest_info(reg: &ForestRegistry, forest_id: ID): (u8, u64, u64, bool) {
        let forest = table::borrow(&reg.forests, forest_id);
        (forest.forest_type, forest.total_area_ha, forest.remaining_area_ha, forest.is_protected)
    }

    public fun get_forest_location(reg: &ForestRegistry, forest_id: ID): (u64, u64) {
        let forest = table::borrow(&reg.forests, forest_id);
        decode_coordinates(forest.location_key)
    }

    public fun id_forest_temperate(): u8 { FOREST_TYPE_TEMPERATE }
    public fun id_forest_tropical(): u8 { FOREST_TYPE_TROPICAL }
    public fun id_forest_boreal(): u8 { FOREST_TYPE_BOREAL }
    public fun id_wood_premium(): u8 { WOOD_PREMIUM }
    public fun id_wood_first(): u8 { WOOD_FIRST }
    public fun id_wood_second(): u8 { WOOD_SECOND }
    public fun id_wood_waste(): u8 { WOOD_WASTE }
}
