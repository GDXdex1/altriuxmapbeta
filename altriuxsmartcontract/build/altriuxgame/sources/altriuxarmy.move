module altriux::altriuxarmy {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};
    use sui::dynamic_field;
    use std::vector;
    use std::string::{Self, String};
    use std::option::{Self, Option};
    use altriux::lrc::{LRC};
    use altriux::altriuxpopulation::{Self, PopulationRegistry};
    use altriux::altriuxlocation::{Self, ResourceLocation, is_adjacent};
    use altriux::altriuxresources::{Self, Inventory, consume_jax, has_jax};
    use altriux::kingdomutils;
    use altriux::altriuxactionpoints::{Self, ActionPointRegistry};
    use altriux::altriuxhero::{Hero};
    use sui::event;

    // === COSTOS AU ===
    const AU_COST_MARCH_ORDER: u64 = 5; // Costo por orden de marcha

    // === TIPOS TRIBALES/RELIGIOSOS CORREGIDOS (5 tipos) ===
    const TRIBE_IMLAX: u8 = 1;     // +25% desierto (Hombres sobre Camellos)
    const TRIBE_CRIS: u8 = 2;      // +25% colinas (Guerreros Celtas)
    const TRIBE_SUX: u8 = 3;       // +25% montañas (Hombres con Elefantes)
    const TRIBE_SHIX: u8 = 4;      // -1 moneda de oro en reclutamiento (Cazadores)
    const TRIBE_YAX: u8 = 5;       // +25% montañas (Caballería Ligera - ventaja Shix compartida)

    // === TIPOS ESTÁNDAR (2 tipos) ===
    const TYPE_DANTIUM: u8 = 8;    // Caballería Pesada
    const TYPE_BRONTIUM: u8 = 9;   // Caballería Pesada

    // === MERCENARIOS (7 tipos) ===
    const MERC_SULTRIUM: u8 = 10;  // +35% desierto (Camellos Tuareg)
    const MERC_XILITRIX: u8 = 11;  // +35% montañas (Cabras Himalayas)
    const MERC_TRONIUM: u8 = 12;   // +30% llanuras (Caballería Sármata)
    const MERC_DRAX: u8 = 13;      // +40% túneles (Infantería Enana)
    const MERC_DRUX: u8 = 14;      // +35% costa (Anfibios Fenicios)
    const MERC_NOIX: u8 = 15;      // +30% tundra (Infantería sobre Trineos)
    const MERC_SOIX: u8 = 16;      // +30% tundra (Infantería sobre Trineos)

    // === CLASES DE UNIDAD ESPECIALIZADAS ===
    // === CLASES DE UNIDAD ESPECIALIZADAS ===
    const UNIT_INFANTRY_LIGHT: u8 = 1;    // Infante ligero (Tier 1)
    const UNIT_INFANTRY_MEDIUM: u8 = 2;   // Infante medio (Tier 2)
    const UNIT_INFANTRY_HEAVY: u8 = 3;    // Infante pesado (Tier 3)
    
    // Chain: Lancer -> Phalanx -> Pikeman -> Halberdier
    const UNIT_LANCER: u8 = 4;            // Tier 1
    const UNIT_PHALANX: u8 = 5;           // Tier 2
    const UNIT_PIKEMAN: u8 = 6;           // Tier 3
    const UNIT_HALBERDIER: u8 = 7;        // Tier 4

    const UNIT_ARCHER_LIGHT: u8 = 8;      // Arquero ligero (Tier 1)
    const UNIT_ARCHER_HEAVY: u8 = 9;      // Arquero pesado (Tier 2)

    // Chain: Light -> Medium -> Heavy
    const UNIT_CAVALRY_LIGHT: u8 = 10;    // Caballería (Tier 1)
    const UNIT_CAVALRY_MEDIUM: u8 = 11;   // Caballería (Tier 2)
    const UNIT_CAVALRY_HEAVY: u8 = 12;    // Caballería (Tier 3)

    const UNIT_SIEGE: u8 = 13;             
    const UNIT_RAM_LIGHT: u8 = 14;     // Ariete ligero
    const UNIT_RAM_HEAVY: u8 = 15;     // Ariete pesado
    const UNIT_CATAPULT: u8 = 16;      // Lanzapiedras / Petrabolos
    const UNIT_SIEGE_TOWER: u8 = 17;   // Torre de asedio


    // === RANGOS MEDIEVALES ===
    const RANK_RECRUIT: u8 = 0;   // Recluta (espada + traje cuero / arco normal)
    const RANK_SOLDIER: u8 = 1;   // Soldado (mejor armadura)
    const RANK_VETERAN: u8 = 2;   // Veterano (armadura completa + arco compuesto si arquero)
    const RANK_CORPORAL: u8 = 3;  // Cabo medieval ("Lance Sergeant")
    const RANK_SERGEANT: u8 = 4;  // Sargento medieval ("Master Sergeant")
    const RANK_ENSIGN: u8 = 5;    // Alférez (porta estandarte)

    // === ESTRATEGIAS DE ATAQUE (12 tipos) ===
    const STRAT_STEALTH_GALLOP: u8 = 1;      // Galope furtivo (100% caballería, -80% vs Muro de Picas)
    const STRAT_ARROW_CURTAIN: u8 = 2;       // Cortina de flechas (40% arqueros, -50% vs Galope Furtivo)
    const STRAT_MOUNTED_JAVELIN: u8 = 3;     // Jabalina montada (60% cab. ligera)
    const STRAT_PHALANX_CHARGE: u8 = 4;      // Carga de falange (70% falanges/lanceros)
    const STRAT_FLANKING: u8 = 5;            // Ataque flanqueante (terreno abierto)
    const STRAT_FEIGNED_RETREAT: u8 = 6;     // Retirada fingida (50% caballería)
    const STRAT_TESTUDO: u8 = 7;             // Tortuga romana (80% inf. media/pesada)
    const STRAT_SWARM: u8 = 8;               // Enjambre (90% inf. ligera)
    const STRAT_SIEGE_RUSH: u8 = 9;          // Asalto de asedio (requiere escuadrones)
    const STRAT_AMBUSH: u8 = 10;             // Emboscada (bosque/montaña)
    const STRAT_RAPID_MARCH: u8 = 11;        // Marcha rápida (+50% velocidad, +100% vulnerable a emboscada)
    const STRAT_PATROL_MARCH: u8 = 12;       // Marcha con patrulla (-30% velocidad, +15% detección emboscada)

    // === ESTRATEGIAS DE DEFENSA (12 tipos) ===
    const STRAT_PIKE_WALL: u8 = 1;           // Muro de picas (20% piqueros/alabarderos, +200% vs caballería)
    const STRAT_SIEGE_CAMP: u8 = 2;          // Campamento de asedio (junto a ciudad)
    const STRAT_HILL_FORT: u8 = 3;           // Fortificación en colina (requiere colina)
    const STRAT_DESERT_HIDE: u8 = 4;         // Escondite en desierto (requiere desierto)
    const STRAT_ICE_BARRIER: u8 = 5;         // Barrera de hielo (requiere tundra/hielo)
    const STRAT_FOREST_AMBUSH: u8 = 6;       // Emboscada en bosque (requiere bosque)
    const STRAT_RIVER_DEFENSE: u8 = 7;       // Defensa de río (requiere río)
    const STRAT_CASTLE_WALLS: u8 = 8;        // Murallas de castillo (requiere castillo)
    const STRAT_TRENCHES: u8 = 9;            // Trincheras (30% inf. ligera)
    const STRAT_RESERVE: u8 = 10;            // Reserva estratégica (40% unidades sin asignar)
    const STRAT_EXTREME_VIGILANCE: u8 = 11;  // Vigilancia extrema (20% caballería, +50% detección emboscada)
    const STRAT_SUPPLY_LINE: u8 = 12;        // Línea de suministro (requiere campamento de batalla)

    // === TIPOS DE CAMPAMENTO ===
    const CAMP_PATROL: u8 = 1;      // Patrulla (máx 150 hombres, 1 día blockchain)
    const CAMP_MOBILE: u8 = 2;      // Campamento móvil (>150 hombres, requiere tiendas)
    const CAMP_BATTLE: u8 = 3;      // Campamento de batalla (línea de suministro activa)

    // === PERIODOS DE CONTRATO ===
    const PERIOD_1_DAY: u64 = 1;
    const PERIOD_10_DAYS: u64 = 10;
    const PERIOD_30_DAYS: u64 = 30;
    const PERIOD_80_DAYS: u64 = 80;
    const PERIOD_90_DAYS: u64 = 90;

    // === RECURSOS ===
    const GOLD_COIN: u64 = 226;     // MONEDA_ORO
    const JAX_WHEAT: u64 = 2;       // Trigo
    const JAX_MEAT: u64 = 227;      // Carne
    const JAX_VEGETABLES: u64 = 56; // Cebolla/verduras
    const TENT_COMMON: u64 = 350;   // Tienda militar común (1 por 10 soldados)
    const TENT_OFFICER: u64 = 351;  // Tienda de oficial (1 por alférez)
    const TENT_LORD: u64 = 352;     // Tienda señorial (1 si héroe presente)

    // === ERRORES ===
    const E_NOT_OWNER: u64 = 101;
    const E_INSUFFICIENT_FUNDS: u64 = 102;
    const E_EXPIRED: u64 = 103;
    const E_INVALID_LOCATION: u64 = 104;
    const E_HUNGRY_SOLDIER: u64 = 105;
    const E_MUTINY: u64 = 106;
    const E_INVALID_STRATEGY: u64 = 107;
    const E_STRATEGY_REQUIREMENT: u64 = 108;
    const E_NO_MOUNT: u64 = 109;
    const E_INSUFFICIENT_TENTS: u64 = 110;
    const E_INSUFFICIENT_FOOD: u64 = 111;
    const E_PATROL_TOO_LARGE: u64 = 112;

    // === STRUCTS ===
    public struct ArmyRegistry has key {
        id: UID,
        armies: Table<ID, ArmyNFT>,
        free_soldiers: Table<u8, vector<Soldier>>,
    }

    public struct ArmyNFT has key, store {
        id: UID,
        owner: address,
        location: ResourceLocation,
        soldiers: vector<Soldier>,
        strategy_attack: u8,
        strategy_defense: u8,
        camp_type: u8,            // CAMP_PATROL, CAMP_MOBILE, CAMP_BATTLE
        camp_expiry: u64,         // Timestamp fin del campamento
        supply_line_active: bool, // Línea de suministro activa (solo CAMP_BATTLE)
        is_marching: bool,
        march_target: Option<ResourceLocation>,
        march_end_time: u64,
        march_strategy: u8,       // STRAT_RAPID_MARCH o STRAT_PATROL_MARCH
    }

    public struct Soldier has store, drop {
        soldier_id: u64,
        tribe_type: u8,
        unit_class: u8,
        rank: u8,
        level: u8,
        hp: u64,
        energy: u64,
        strength: u64,
        experience: u64,
        contract_expiry: u64,
        contract_period: u64,
        last_fed: u64,
        hunger_state: u8,
        weapon_id: Option<ID>,
        armor_id: Option<ID>,
        mount_id: Option<ID>,
        banner_id: Option<ID>,
    }

    // === EVENTS ===
    public struct SoldierRecruited has copy, drop {
        soldier_id: u64,
        tribe_type: u8,
        unit_class: u8,
        rank: u8,
        location: ResourceLocation,
        owner: address,
        contract_days: u64,
        payment_lrc: u64,
        timestamp: u64,
    }

    public struct PatrolOrdered has copy, drop {
        army_id: ID,
        soldier_count: u64,
        duration_days: u64,
        food_consumed: u64,
        start_location: ResourceLocation,
        end_location: ResourceLocation,
        timestamp: u64,
    }

    public struct MobileCampCreated has copy, drop {
        army_id: ID,
        soldier_count: u64,
        common_tents: u64,
        officer_tents: u64,
        lord_tents: u64,
        duration_days: u64,
        timestamp: u64,
    }

    public struct BattleCampCreated has copy, drop {
        army_id: ID,
        soldier_count: u64,
        supply_line_active: bool,
        daily_food_required: u64,
        location: ResourceLocation,
        timestamp: u64,
    }

    public struct SupplyLineDeducted has copy, drop {
        army_id: ID,
        soldier_count: u64,
        food_deducted: u64,
        timestamp: u64,
    }

    public struct MutinyOccurred has copy, drop {
        soldier_id: u64,
        location: ResourceLocation,
        damage_caused: u64,
        timestamp: u64,
    }

    fun create_random_soldier(tribe_type: u8, ctx: &mut TxContext): Soldier {
        let unit_class = UNIT_INFANTRY_LIGHT; 
        let rank = RANK_SOLDIER;
        let (hp, energy, strength) = get_base_stats(unit_class, tribe_type);
        Soldier {
            soldier_id: altriux::kingdomutils::get_next_id(ctx),
            tribe_type,
            unit_class,
            rank,
            level: 1,
            hp,
            energy,
            strength,
            experience: 0,
            contract_expiry: 0, 
            contract_period: 365,
            last_fed: 0,
            hunger_state: 0,
            weapon_id: option::none(),
            armor_id: option::none(),
            mount_id: option::none(),
            banner_id: option::none(),
        }
    }

    // === INICIALIZACIÓN ===
    public fun init_army_registry(ctx: &mut TxContext) {
        let mut registry = ArmyRegistry {
            id: object::new(ctx),
            armies: table::new(ctx),
            free_soldiers: table::new(ctx),
        };
        
        // Crear pool inicial de 500 soldados libres distribuidos por tribu
        let mut tribe = 1;
        while (tribe <= 9) {
            let count = if (tribe <= 5) 60 else 40;
            let mut i = 0;
            while (i < count) {
                let soldier = create_random_soldier(tribe, ctx);
                if (!table::contains(&registry.free_soldiers, tribe)) {
                    table::add(&mut registry.free_soldiers, tribe, vector::empty());
                };
                let pool = table::borrow_mut(&mut registry.free_soldiers, tribe);
                vector::push_back(pool, soldier);
                i = i + 1;
            };
            tribe = tribe + 1;
        };
        
        transfer::share_object(registry);
    }

    fun get_base_recruit_cost(_tribe: u8, _class: u8, rank: u8): u64 {
        if (rank == RANK_RECRUIT) 20
        else if (rank == RANK_SOLDIER) 50
        else if (rank == RANK_VETERAN) 150
        else if (rank == RANK_CORPORAL) 300
        else 500
    }

    // === RECLUTAMIENTO CORREGIDO (Draxiux para tundra) ===
    public fun recruit_soldier(
        registry: &mut ArmyRegistry,
        reg: &mut PopulationRegistry,
        mut payment: Coin<LRC>,
        tribe_type: u8,
        unit_class: u8,
        rank: u8,
        location: ResourceLocation,
        land_id: ID,
        contract_days: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        let sender = tx_context::sender(ctx);
        
        // Validar período de contrato válido
        assert!(
            contract_days == PERIOD_1_DAY || 
            contract_days == PERIOD_10_DAYS || 
            contract_days == PERIOD_30_DAYS || 
            contract_days == PERIOD_80_DAYS || 
            contract_days == PERIOD_90_DAYS,
            E_INVALID_STRATEGY
        );
        
        // Calcular costo según tribu y rango
        let base_cost = get_base_recruit_cost(tribe_type, unit_class, rank);
        let period_multiplier = if (contract_days == PERIOD_1_DAY) 1 
                               else if (contract_days == PERIOD_10_DAYS) 3 
                               else if (contract_days == PERIOD_30_DAYS) 8 
                               else if (contract_days == PERIOD_80_DAYS) 20 
                               else 25;
        let total_cost = base_cost * period_multiplier;
        
        // Aplicar descuentos/recargos por tribu
        let final_cost = if (tribe_type == TRIBE_SHIX || tribe_type == TRIBE_YAX) {
            total_cost - 20 // -1 moneda de oro = -20 LRC
        } else if (tribe_type == TYPE_DANTIUM || tribe_type == TYPE_BRONTIUM) {
            total_cost + 20 // +1 moneda de oro = +20 LRC
        } else {
            total_cost
        };
        
        assert!(coin::value(&payment) >= final_cost, E_INSUFFICIENT_FUNDS);
        
        // Para tribus religiosas: deducir población
        if (tribe_type <= TRIBE_YAX) { // No mercenarios
            altriuxpopulation::deduct_civilian(
                reg, 
                altriuxlocation::get_hq(&location), 
                altriuxlocation::get_hr(&location), 
                1, 
                b"recruit_soldier", 
                clock, 
                ctx
            );
        };
        
        // Quemar pago (80% economía NPC, 20% beneficiario)
        let beneficiary_share = (final_cost * 20) / 100;
        let beneficiary_coin = coin::split(&mut payment, beneficiary_share, ctx);
        transfer::public_transfer(beneficiary_coin, @0x947a1db4d9be4bd4a07a0d6e5ad8372b0c90268a28752c96f2d0d7b71bc591f);
        
        if (coin::value(&payment) > 0) {
            transfer::public_transfer(payment, @0x554a2392980b0c3e4111c9a0e8897e632d41847d04cbd41f9e081e49ba2eb04a);
        } else {
            coin::destroy_zero(payment);
        };
        
        // Crear soldado
        let (hp, energy, strength) = get_base_stats(unit_class, tribe_type);
        let soldier_id = altriux::kingdomutils::get_next_id(ctx);
        let soldier = Soldier {
            soldier_id,
            tribe_type,
            unit_class,
            rank,
            level: 1,
            hp,
            energy,
            strength,
            experience: 0,
            contract_expiry: clock::timestamp_ms(clock) + (contract_days * 24 * 60 * 60 * 1000),
            contract_period: contract_days,
            last_fed: clock::timestamp_ms(clock),
            hunger_state: 0,
            weapon_id: option::none(),
            armor_id: option::none(),
            mount_id: option::none(),
            banner_id: option::none(),
        };
        
        // Crear ejército si no existe, o añadir a existente en misma ubicación
        let army_id = find_or_create_army_at_location(registry, sender, location, ctx);
        let army = table::borrow_mut(&mut registry.armies, army_id);
        
        vector::push_back(&mut army.soldiers, soldier);
        
        event::emit(SoldierRecruited {
            soldier_id,
            tribe_type,
            unit_class,
            rank,
            location,
            owner: sender,
            contract_days,
            payment_lrc: final_cost,
            timestamp: clock::timestamp_ms(clock),
        });
        
        army_id
    }

    // === PATRULLA (Máx 150 hombres, 1 día blockchain, requiere comida) ===
    public fun order_patrol(
        registry: &mut ArmyRegistry,
        army_id: ID,
        target_location: ResourceLocation,
        food_inv: &mut Inventory,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let army = table::borrow_mut(&mut registry.armies, army_id);
        
        assert!(army.owner == sender, E_NOT_OWNER);
        assert!(army.camp_type == CAMP_PATROL || army.camp_type == 0, E_INVALID_STRATEGY);
        
        let soldier_count = vector::length(&army.soldiers);
        assert!(soldier_count <= 150, E_PATROL_TOO_LARGE); // Máx 150 hombres
        
        // Validar adyacencia (patrulla solo a tiles adyacentes)
        // Validar adyacencia (patrulla solo a tiles adyacentes)
        assert!(altriuxlocation::is_adjacent(
            altriuxlocation::get_hq(&army.location), 
            altriuxlocation::get_hr(&army.location), 
            altriuxlocation::get_hq(&target_location), 
            altriuxlocation::get_hr(&target_location)
        ), E_INVALID_LOCATION);
        
        // Requerir 1 JAX de comida variada por soldado (trigo + carne + verduras)
        let food_required = soldier_count * 3; // 1 JAX de cada tipo
        assert!(has_jax(food_inv, JAX_WHEAT, soldier_count), E_INSUFFICIENT_FOOD);
        assert!(has_jax(food_inv, JAX_MEAT, soldier_count), E_INSUFFICIENT_FOOD);
        assert!(has_jax(food_inv, JAX_VEGETABLES, soldier_count), E_INSUFFICIENT_FOOD);
        
        consume_jax(food_inv, JAX_WHEAT, soldier_count, clock);
        consume_jax(food_inv, JAX_MEAT, soldier_count, clock);
        consume_jax(food_inv, JAX_VEGETABLES, soldier_count, clock);
        
        // Iniciar patrulla (1 día blockchain = 24 horas reales)
        army.camp_expiry = clock::timestamp_ms(clock) + (24 * 60 * 60 * 1000);
        army.location = target_location;
        army.camp_type = CAMP_PATROL;
        
        event::emit(PatrolOrdered {
            army_id,
            soldier_count: soldier_count as u64,
            duration_days: 1,
            food_consumed: food_required,
            start_location: army.location,
            end_location: target_location,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // === CAMPAMENTO MÓVIL (>150 hombres, requiere tiendas) ===
    public fun create_mobile_camp(
        registry: &mut ArmyRegistry,
        army_id: ID,
        duration_days: u64,
        tent_inv: &mut Inventory,
        food_inv: &mut Inventory,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let army = table::borrow_mut(&mut registry.armies, army_id);
        
        assert!(army.owner == sender, E_NOT_OWNER);
        let soldier_count = vector::length(&army.soldiers);
        assert!(soldier_count > 150, E_PATROL_TOO_LARGE); // Requiere >150 para campamento móvil
        
        // Calcular tiendas requeridas
        let common_tents = (soldier_count + 9) / 10; // 1 tienda por 10 soldados
        let officer_tents = count_ensigns(&army.soldiers);
        let lord_tents = if (has_hero_with_army(army_id)) 1 else 0;
        
        // Validar tiendas suficientes
        assert!(has_jax(tent_inv, TENT_COMMON, common_tents), E_INSUFFICIENT_TENTS);
        if (officer_tents > 0) {
            assert!(has_jax(tent_inv, TENT_OFFICER, officer_tents), E_INSUFFICIENT_TENTS);
        };
        if (lord_tents > 0) {
            assert!(has_jax(tent_inv, TENT_LORD, lord_tents), E_INSUFFICIENT_TENTS);
        };
        
        // Consumir tiendas
        consume_jax(tent_inv, TENT_COMMON, common_tents, clock);
        if (officer_tents > 0) {
            consume_jax(tent_inv, TENT_OFFICER, officer_tents, clock);
        };
        if (lord_tents > 0) {
            consume_jax(tent_inv, TENT_LORD, lord_tents, clock);
        };
        
        // Requerir 1.3 JAX comida variada por soldado por día
        let daily_food = (soldier_count * 13) / 10; // 1.3 JAX por soldado
        let total_food = daily_food * duration_days;
        assert!(has_jax(food_inv, JAX_WHEAT, total_food), E_INSUFFICIENT_FOOD);
        assert!(has_jax(food_inv, JAX_MEAT, total_food), E_INSUFFICIENT_FOOD);
        assert!(has_jax(food_inv, JAX_VEGETABLES, total_food), E_INSUFFICIENT_FOOD);
        
        consume_jax(food_inv, JAX_WHEAT, total_food, clock);
        consume_jax(food_inv, JAX_MEAT, total_food, clock);
        consume_jax(food_inv, JAX_VEGETABLES, total_food, clock);
        
        // Crear campamento móvil
        army.camp_type = CAMP_MOBILE;
        army.camp_expiry = clock::timestamp_ms(clock) + (duration_days * 24 * 60 * 60 * 1000);
        
        event::emit(MobileCampCreated {
            army_id,
            soldier_count: soldier_count as u64,
            common_tents,
            officer_tents,
            lord_tents,
            duration_days,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // === CAMPAMENTO DE BATALLA (Línea de suministro) ===
    public fun create_battle_camp(
        registry: &mut ArmyRegistry,
        army_id: ID,
        activate_supply_line: bool,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let army = table::borrow_mut(&mut registry.armies, army_id);
        
        assert!(army.owner == sender, E_NOT_OWNER);
        
        // Crear campamento de batalla
        army.camp_type = CAMP_BATTLE;
        army.camp_expiry = clock::timestamp_ms(clock) + (90 * 24 * 60 * 60 * 1000); // 90 días máximo
        army.supply_line_active = activate_supply_line;
        
        let soldier_count = vector::length(&army.soldiers) as u64;
        let daily_food = (soldier_count * 13) / 10; // 1.3 JAX por soldado
        
        event::emit(BattleCampCreated {
            army_id,
            soldier_count,
            supply_line_active: activate_supply_line,
            daily_food_required: daily_food,
            location: army.location,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // === DEDUCCIÓN AUTOMÁTICA DE LÍNEA DE SUMINISTRO ===
    public fun deduct_supply_line(
        registry: &mut ArmyRegistry,
        army_id: ID,
        food_inv: &mut Inventory,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let army = table::borrow_mut(&mut registry.armies, army_id);
        
        // Solo aplica a campamentos de batalla con línea activa
        if (army.camp_type != CAMP_BATTLE || !army.supply_line_active) {
            return;
        };
        
        let soldier_count = vector::length(&army.soldiers) as u64;
        let daily_food = (soldier_count * 13) / 10; // 1.3 JAX por soldado
        
        // Validar comida suficiente
        if (!has_jax(food_inv, JAX_WHEAT, daily_food) ||
            !has_jax(food_inv, JAX_MEAT, daily_food) ||
            !has_jax(food_inv, JAX_VEGETABLES, daily_food)) {
            // ¡MOTÍN POR FALTA DE SUMINISTROS!
            trigger_mutiny(army, clock, ctx);
            return;
        };
        
        // Consumir comida
        consume_jax(food_inv, JAX_WHEAT, daily_food, clock);
        consume_jax(food_inv, JAX_MEAT, daily_food, clock);
        consume_jax(food_inv, JAX_VEGETABLES, daily_food, clock);
        
        event::emit(SupplyLineDeducted {
            army_id,
            soldier_count,
            food_deducted: daily_food * 3, // Total de los 3 tipos
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // === EVOLUCIÓN DE UNIDADES ===
    public fun get_evolution_target(class: u8): u8 {
        if (class == UNIT_INFANTRY_LIGHT) UNIT_INFANTRY_MEDIUM
        else if (class == UNIT_INFANTRY_MEDIUM) UNIT_INFANTRY_HEAVY
        else if (class == UNIT_LANCER) UNIT_PHALANX
        else if (class == UNIT_PHALANX) UNIT_PIKEMAN
        else if (class == UNIT_PIKEMAN) UNIT_HALBERDIER
        else if (class == UNIT_ARCHER_LIGHT) UNIT_ARCHER_HEAVY
        else if (class == UNIT_CAVALRY_LIGHT) UNIT_CAVALRY_MEDIUM
        else if (class == UNIT_CAVALRY_MEDIUM) UNIT_CAVALRY_HEAVY
        else 0 // No evolution
    }

    public fun upgrade_unit(
        registry: &mut ArmyRegistry,
        army_id: ID,
        soldier_idx: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let army = table::borrow_mut(&mut registry.armies, army_id);
        assert!(army.owner == sender, E_NOT_OWNER);
        
        // TODO: Requirements (check cost, training, etc.) - Placeholder free for now
        
        let soldier = vector::borrow_mut(&mut army.soldiers, soldier_idx);
        let current_class = soldier.unit_class;
        let next_class = get_evolution_target(current_class);
        
        assert!(next_class != 0, E_INVALID_STRATEGY); // "Invalid Evolution" reused error
        
        soldier.unit_class = next_class;
        
        // Recalculate stats based on new class (keeping experience/level bonus if any?)
        // For simplicity, reset base stats + level bonus
        let (new_hp, new_energy, new_str) = get_base_stats(next_class, soldier.tribe_type);
        // Apply level bonus (e.g. +5% per level)
        let level_growth = (soldier.level as u64) * 5; 
        soldier.hp = new_hp * (100 + level_growth) / 100;
        soldier.energy = new_energy * (100 + level_growth) / 100;
        soldier.strength = new_str * (100 + level_growth) / 100;
    }

    // === MOVER CAMPAMENTO (Marcha con estrategia) ===
    // === MOVER CAMPAMENTO (Marcha con estrategia) ===
    public fun move_camp(
        registry: &mut ArmyRegistry,
        army_id: ID,
        target_location: ResourceLocation,
        march_strategy: u8, // STRAT_RAPID_MARCH o STRAT_PATROL_MARCH
        commander: &Hero,
        au_reg: &mut ActionPointRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let army = table::borrow_mut(&mut registry.armies, army_id);
        
        assert!(army.owner == sender, E_NOT_OWNER);
        assert!(march_strategy == STRAT_RAPID_MARCH || march_strategy == STRAT_PATROL_MARCH, E_INVALID_STRATEGY);
        
        // === CONSUMO AU ===
        altriuxactionpoints::consume_au(au_reg, object::id(commander), AU_COST_MARCH_ORDER, b"move_army", clock, ctx);
        
        // Calcular tiempo de marcha según estrategia y distancia
        let distance = calculate_distance(&army.location, &target_location);
        
        // Velocidad: 50 tiles/día para montados, 20 tiles/día para infantería
        let speed = if (is_army_mounted(army)) 50 else 20;
        
        // base_days = (distancia / velocidad)
        // Usamos factor 100 para precisión: days = (dist * 100) / speed
        let base_days_scaled = (distance * 100) / speed; 
        
        let march_days_scaled = if (march_strategy == STRAT_RAPID_MARCH) {
            base_days_scaled * 70 / 100 // +30% velocidad (-30% tiempo)
        } else {
            base_days_scaled * 130 / 100 // -30% velocidad (+30% tiempo)
        };
        
        // Iniciar marcha
        army.is_marching = true;
        army.march_target = option::some(target_location);
        // Convertir days_scaled (100 = 1 día) a milisegundos
        army.march_end_time = clock::timestamp_ms(clock) + (march_days_scaled * 24 * 60 * 60 * 10); // * 1000 / 100
        army.march_strategy = march_strategy;
        
        // Si estrategia de patrulla: 15% chance de detectar emboscada durante marcha
        if (march_strategy == STRAT_PATROL_MARCH) {
            let rand = kingdomutils::random(1, 100, ctx);
            if (rand <= 15) {
                // ¡Emboscada detectada! Aplicar penalización menor
                apply_ambush_penalty(army, 20); // -20% moral
            };
        };
    }

    // === FUNCIONES AUXILIARES ===
    fun is_army_mounted(army: &ArmyNFT): bool {
        let len = vector::length(&army.soldiers);
        if (len == 0) return false;
        
        let mut mounted_count = 0;
        let mut i = 0;
        while (i < len) {
            let soldier = vector::borrow(&army.soldiers, i);
            if (
                soldier.unit_class == UNIT_CAVALRY_LIGHT || 
                soldier.unit_class == UNIT_CAVALRY_MEDIUM || 
                soldier.unit_class == UNIT_CAVALRY_HEAVY
            ) {
                mounted_count = mounted_count + 1;
            };
            i = i + 1;
        };
        
        // Se considera montado si más del 80% tiene montura
        (mounted_count * 100 / len) >= 80
    }

    fun find_or_create_army_at_location(
        registry: &mut ArmyRegistry,
        owner: address,
        location: ResourceLocation,
        ctx: &mut TxContext
    ): ID {
        // En una implementación real, buscaríamos en el registry
        // Por ahora, creamos un nuevo ejército siempre para simplificar el flujo inicial
        let army = ArmyNFT {
            id: object::new(ctx),
            owner,
            location,
            soldiers: vector::empty(),
            strategy_attack: 1, // DEFAULT
            strategy_defense: 1, // DEFAULT
            camp_type: 0,
            camp_expiry: 0,
            supply_line_active: false,
            is_marching: false,
            march_target: option::none(),
            march_end_time: 0,
            march_strategy: 1, // DEFAULT
        };
        let army_id = object::id(&army);
        table::add(&mut registry.armies, army_id, army);
        army_id
    }

    fun count_ensigns(soldiers: &vector<Soldier>): u64 {
        let mut count = 0;
        let mut i = 0;
        let len = vector::length(soldiers);
        while (i < len) {
            let soldier = vector::borrow(soldiers, i);
            if (soldier.rank == RANK_ENSIGN) {
                count = count + 1;
            };
            i = i + 1;
        };
        count
    }

    fun has_hero_with_army(army_id: ID): bool {
        // En producción real: verificar si héroe del dueño está en misma ubicación
        false
    }

    fun trigger_mutiny(army: &mut ArmyNFT, clock: &Clock, ctx: &mut TxContext) {
        // Destruir 10% de los soldados al azar
        let soldier_count = vector::length(&army.soldiers);
        let losses = soldier_count * 10 / 100;
        
        let mut i = 0;
        while (i < losses && vector::length(&army.soldiers) > 0) {
            let idx = kingdomutils::random(0, vector::length(&army.soldiers) - 1, ctx) as u64;
            let _ = vector::remove(&mut army.soldiers, idx);
            i = i + 1;
        };
        
        event::emit(MutinyOccurred {
            soldier_id: 0, // No hay ID específico para motín colectivo
            location: army.location,
            damage_caused: losses * 100, // Daño simbólico
            timestamp: clock::timestamp_ms(clock),
        });
    }

    fun apply_ambush_penalty(army: &mut ArmyNFT, penalty_percent: u64) {
        let mut i = 0;
        while (i < vector::length(&army.soldiers)) {
            let soldier = vector::borrow_mut(&mut army.soldiers, i);
            soldier.energy = soldier.energy * (100 - penalty_percent) / 100;
            if (soldier.energy < 10) soldier.energy = 10;
            i = i + 1;
        };
    }

    fun calculate_distance(loc1: &ResourceLocation, loc2: &ResourceLocation): u64 {
        altriuxlocation::calculate_combined_distance(
            altriuxlocation::get_hq(loc1), altriuxlocation::get_hr(loc1), altriuxlocation::get_sq(loc1), altriuxlocation::get_sr(loc1),
            altriuxlocation::get_hq(loc2), altriuxlocation::get_hr(loc2), altriuxlocation::get_sq(loc2), altriuxlocation::get_sr(loc2)
        )
    }

    // === STATS BASE POR CLASE Y TRIBU CORREGIDO ===
    fun get_base_stats(unit_class: u8, tribe_type: u8): (u64, u64, u64) {
        let (hp, energy, strength) = if (unit_class == UNIT_INFANTRY_LIGHT) (80, 70, 60)
            else if (unit_class == UNIT_INFANTRY_MEDIUM) (100, 60, 80)
            else if (unit_class == UNIT_INFANTRY_HEAVY) (120, 50, 100)
            else if (unit_class == UNIT_LANCER) (90, 65, 75)
            else if (unit_class == UNIT_PHALANX) (110, 55, 95)
            else if (unit_class == UNIT_HALBERDIER) (120, 60, 100)
            else if (unit_class == UNIT_PIKEMAN) (105, 60, 85)
            else if (unit_class == UNIT_ARCHER_LIGHT) (70, 90, 50)
            else if (unit_class == UNIT_ARCHER_HEAVY) (80, 80, 70)
            else if (unit_class == UNIT_CAVALRY_LIGHT) (90, 100, 70)
            else if (unit_class == UNIT_CAVALRY_MEDIUM) (110, 90, 90)
            else if (unit_class == UNIT_CAVALRY_HEAVY) (140, 80, 120)
            else if (unit_class == UNIT_SIEGE) (60, 40, 120)
            else if (unit_class == UNIT_RAM_LIGHT) (200, 30, 150)
            else if (unit_class == UNIT_RAM_HEAVY) (350, 20, 300)
            else if (unit_class == UNIT_CATAPULT) (150, 15, 400)
            else if (unit_class == UNIT_SIEGE_TOWER) (500, 10, 50)
            else (80, 70, 60);
        
        // Bonificaciones tribales
        let hp_bonus = if (tribe_type == TRIBE_SUX || tribe_type == MERC_XILITRIX) 10 else 0; // Mountain toughness
        let energy_bonus = if (tribe_type == TRIBE_IMLAX || tribe_type == MERC_SULTRIUM || tribe_type == TRIBE_YAX) 20 else 0; // Desert/Light Cav Stamina
        let strength_bonus = if (tribe_type == TRIBE_CRIS || tribe_type == MERC_TRONIUM || tribe_type == TYPE_DANTIUM || tribe_type == TYPE_BRONTIUM) 15 else 0;
        let tundra_bonus = if (tribe_type == MERC_NOIX || tribe_type == MERC_SOIX) 30 else 0; // Tundra adaptation
        
        (
            hp * (100 + hp_bonus + tundra_bonus) / 100,
            energy * (100 + energy_bonus + tundra_bonus) / 100,
            strength * (100 + strength_bonus + tundra_bonus) / 100
        )
    }

    // === BONIFICACIONES GEOGRÁFICAS POR TRIBU (CORREGIDO) ===
    fun get_biome_from_location(_location: ResourceLocation): u8 {
        // TODO: Implement real biome lookup from LocationRegistry
        0
    }

    public fun get_biome_bonus(tribe_type: u8, location: ResourceLocation): u64 {
        let biome = get_biome_from_location(location);
        
        if (tribe_type == TRIBE_IMLAX && biome == 4) 25
        else if (tribe_type == TRIBE_CRIS && biome == 8) 25
        else if (tribe_type == TRIBE_SUX && biome == 6) 25
        else if (tribe_type == MERC_NOIX && biome == 2) 30
        else if (tribe_type == MERC_SOIX && biome == 2) 30
        else if (tribe_type == MERC_SULTRIUM && biome == 4) 35
        else if (tribe_type == MERC_XILITRIX && biome == 1) 35
        else if (tribe_type == MERC_TRONIUM && biome == 6) 30
        else if (tribe_type == MERC_DRAX && biome == 6) 40
        else if (tribe_type == MERC_DRUX && biome == 7) 35
        else 0
    }

    // === GETTERS PÚBLICOS ===
    public fun id_tribe_imlax(): u8 { TRIBE_IMLAX }
    public fun id_tribe_cris(): u8 { TRIBE_CRIS }
    public fun id_tribe_sux(): u8 { TRIBE_SUX }
    public fun id_tribe_shix(): u8 { TRIBE_SHIX }
    public fun id_tribe_yax(): u8 { TRIBE_YAX }
    public fun id_merc_noix(): u8 { MERC_NOIX }
    public fun id_merc_soix(): u8 { MERC_SOIX }
    public fun id_unit_ram_light(): u8 { UNIT_RAM_LIGHT }
    public fun id_unit_ram_heavy(): u8 { UNIT_RAM_HEAVY }
    public fun id_unit_catapult(): u8 { UNIT_CATAPULT }
    public fun id_unit_siege_tower(): u8 { UNIT_SIEGE_TOWER }
    public fun id_type_dantium(): u8 { TYPE_DANTIUM }
    public fun id_type_brontium(): u8 { TYPE_BRONTIUM }
    public fun id_unit_lancer(): u8 { UNIT_LANCER }
    public fun id_unit_phalanx(): u8 { UNIT_PHALANX }
    public fun id_unit_halberdier(): u8 { UNIT_HALBERDIER }
    public fun id_unit_pikeman(): u8 { UNIT_PIKEMAN }
    public fun id_strat_extreme_vigilance(): u8 { STRAT_EXTREME_VIGILANCE }
    public fun id_strat_supply_line(): u8 { STRAT_SUPPLY_LINE }
    public fun id_camp_patrol(): u8 { CAMP_PATROL }
    public fun id_camp_mobile(): u8 { CAMP_MOBILE }
    public fun id_camp_battle(): u8 { CAMP_BATTLE }

    // === HELPER FUNCTIONS FOR BATTLE MODULE ===
    public fun get_army_owner(army: &ArmyNFT): address {
        army.owner
    }

    public fun get_army_location(army: &ArmyNFT): ResourceLocation {
        army.location
    }

    public fun get_army_strategy_defense(army: &ArmyNFT): u8 {
        army.strategy_defense
    }

    public fun get_army_march_strategy(army: &ArmyNFT): u8 {
        army.march_strategy
    }

    public fun get_army_soldier_count(army: &ArmyNFT): u64 {
        vector::length(&army.soldiers)
    }

    public fun get_soldier_hp(army: &ArmyNFT, idx: u64): u64 {
        let soldier = vector::borrow(&army.soldiers, idx);
        soldier.hp
    }

    public fun get_soldier_energy(army: &ArmyNFT, idx: u64): u64 {
        let soldier = vector::borrow(&army.soldiers, idx);
        soldier.energy
    }

    public fun get_soldier_strength(army: &ArmyNFT, idx: u64): u64 {
        let soldier = vector::borrow(&army.soldiers, idx);
        soldier.strength
    }

    public fun get_soldier_tribe_type(army: &ArmyNFT, idx: u64): u8 {
        let soldier = vector::borrow(&army.soldiers, idx);
        soldier.tribe_type
    }

    public fun get_soldier_unit_class(army: &ArmyNFT, idx: u64): u8 {
        let soldier = vector::borrow(&army.soldiers, idx);
        soldier.unit_class
    }

    public fun get_soldier_rank(army: &ArmyNFT, idx: u64): u8 {
        let soldier = vector::borrow(&army.soldiers, idx);
        soldier.rank
    }

    public fun get_soldier_contract_period(army: &ArmyNFT, idx: u64): u64 {
        let soldier = vector::borrow(&army.soldiers, idx);
        soldier.contract_period
    }

    public fun remove_random_soldier(army: &mut ArmyNFT, idx: u64) {
        let _ = vector::remove(&mut army.soldiers, idx);
    }
}