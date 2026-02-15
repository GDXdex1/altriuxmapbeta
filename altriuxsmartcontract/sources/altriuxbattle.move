module altriux::altriuxbattle {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};
    use std::vector;
    use altriux::altriuxarmy::{Self, ArmyNFT, Soldier};
    use altriux::altriuxlocation::{Self, ResourceLocation, is_adjacent};
    use altriux::kingdomutils;
    use altriux::altriuxhero::{Hero};
    use altriux::altriuxactionpoints::{Self, ActionPointRegistry};
    use sui::event;

    // === COSTOS AU ===
    const AU_COST_BATTLE: u64 = 10; // Costo por iniciar batalla

    // === CONSTANTES DE COMBATE ===
    const BATTLE_DURATION_MS: u64 = 1 * 60 * 60 * 1000; // 1 hora blockchain

    // === ESTRATEGIAS DE ATAQUE (12) ===
    const STRAT_STEALTH_GALLOP: u8 = 1;
    const STRAT_ARROW_CURTAIN: u8 = 2;
    const STRAT_MOUNTED_JAVELIN: u8 = 3;
    const STRAT_PHALANX_CHARGE: u8 = 4;
    const STRAT_FLANKING: u8 = 5;
    const STRAT_FEIGNED_RETREAT: u8 = 6;
    const STRAT_TESTUDO: u8 = 7;
    const STRAT_SWARM: u8 = 8;
    const STRAT_SIEGE_RUSH: u8 = 9;
    const STRAT_AMBUSH: u8 = 10;
    const STRAT_RAPID_MARCH: u8 = 11;
    const STRAT_PATROL_MARCH: u8 = 12;

    // === ESTRATEGIAS DE DEFENSA (12) ===
    const STRAT_PIKE_WALL: u8 = 1;
    const STRAT_SIEGE_CAMP: u8 = 2;
    const STRAT_HILL_FORT: u8 = 3;
    const STRAT_DESERT_HIDE: u8 = 4;
    const STRAT_ICE_BARRIER: u8 = 5;
    const STRAT_FOREST_AMBUSH: u8 = 6;
    const STRAT_RIVER_DEFENSE: u8 = 7;
    const STRAT_CASTLE_WALLS: u8 = 8;
    const STRAT_TRENCHES: u8 = 9;
    const STRAT_RESERVE: u8 = 10;
    const STRAT_EXTREME_VIGILANCE: u8 = 11;
    const STRAT_SUPPLY_LINE: u8 = 12;

    // === TIPOS DE UNIDAD PARA COMBATE ===
    const UNIT_INFANTRY_LIGHT: u8 = 1;
    const UNIT_INFANTRY_MEDIUM: u8 = 2;
    const UNIT_INFANTRY_HEAVY: u8 = 3;
    const UNIT_LANCER: u8 = 4;
    const UNIT_PHALANX: u8 = 5;
    const UNIT_HALBERDIER: u8 = 6;
    const UNIT_PIKEMAN: u8 = 7;
    const UNIT_ARCHER_LIGHT: u8 = 8;
    const UNIT_ARCHER_HEAVY: u8 = 9;
    const UNIT_CAVALRY_LIGHT: u8 = 10;
    const UNIT_CAVALRY_MEDIUM: u8 = 11;
    const UNIT_CAVALRY_HEAVY: u8 = 12;
    const UNIT_SIEGE: u8 = 13;
    const UNIT_SPECIAL: u8 = 14;

    // === ERRORES ===
    const E_INVALID_ARMY: u64 = 101;
    const E_NOT_ADJACENT: u64 = 102;
    const E_STRATEGY_MISMATCH: u64 = 103;
    const E_AMBUSH_DETECTED: u64 = 104;

    // === STRUCTS ===
    public struct BattleRegistry has key {
        id: UID,
        active_battles: Table<ID, BattleInstance>,
    }

    public struct BattleInstance has key, store {
        id: UID,
        attacker_army_id: ID,
        defender_army_id: ID,
        location: ResourceLocation,
        start_time: u64,
        attacker_strategy: u8,
        defender_strategy: u8,
        is_resolved: bool,
    }

    // === EVENTS ===
    public struct BattleStarted has copy, drop {
        battle_id: ID,
        attacker_army: ID,
        defender_army: ID,
        attacker_strategy: u8,
        defender_strategy: u8,
        location: ResourceLocation,
        timestamp: u64,
    }

    public struct BattleResult has copy, drop {
        battle_id: ID,
        winner: address,
        loser: address,
        attacker_losses: u64,
        defender_losses: u64,
        location: ResourceLocation,
        timestamp: u64,
    }

    public struct AmbushDetected has copy, drop {
        battle_id: ID,
        ambushing_army: ID,
        target_army: ID,
        success_chance: u8,
        timestamp: u64,
    }

    // === INICIALIZACIÓN ===
    public fun init_battle_registry(ctx: &mut TxContext) {
        let registry = BattleRegistry {
            id: object::new(ctx),
            active_battles: table::new(ctx),
        };
        sui::transfer::share_object(registry);
    }

    // === INICIAR BATALLA ===
    public fun start_battle(
        registry: &mut BattleRegistry,
        attacker: &ArmyNFT,
        defender: &ArmyNFT,
        commander: &Hero,
        au_reg: &mut ActionPointRegistry,
        attacker_strategy: u8,
        defender_strategy: u8,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        // Validar ubicaciones adyacentes
        let attacker_loc = altriuxarmy::get_army_location(attacker);
        let defender_loc = altriuxarmy::get_army_location(defender);
        assert!(altriuxlocation::is_adjacent(
            altriuxlocation::get_hq(&attacker_loc), 
            altriuxlocation::get_hr(&attacker_loc), 
            altriuxlocation::get_hq(&defender_loc), 
            altriuxlocation::get_hr(&defender_loc)
        ), E_NOT_ADJACENT);
        
        // Validar que el sender es dueño del ejercito atacante
        assert!(altriuxarmy::get_army_owner(attacker) == tx_context::sender(ctx), E_INVALID_ARMY);
        
        // === CONSUMO AU ===
        altriuxactionpoints::consume_au(au_reg, object::id(commander), AU_COST_BATTLE, b"start_battle", clock, ctx);

        // Validar estrategias compatibles
        validate_strategy_pair(attacker_strategy, defender_strategy);
        
        let battle = BattleInstance {
            id: object::new(ctx),
            attacker_army_id: object::id(attacker),
            defender_army_id: object::id(defender),
            location: defender_loc,
            start_time: clock::timestamp_ms(clock),
            attacker_strategy,
            defender_strategy,
            is_resolved: false,
        };
        
        let battle_id = object::id(&battle);
        table::add(&mut registry.active_battles, battle_id, battle);
        
        event::emit(BattleStarted {
            battle_id,
            attacker_army: object::id(attacker),
            defender_army: object::id(defender),
            attacker_strategy,
            defender_strategy,
            location: defender_loc,
            timestamp: clock::timestamp_ms(clock),
        });
        
        battle_id
    }

    // === RESOLVER BATALLA ===
    public fun resolve_battle(
        registry: &mut BattleRegistry,
        battle_id: ID,
        attacker_army: &mut ArmyNFT,
        defender_army: &mut ArmyNFT,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let battle = table::borrow_mut(&mut registry.active_battles, battle_id);
        assert!(!battle.is_resolved, E_INVALID_ARMY);
        assert!(clock::timestamp_ms(clock) >= battle.start_time + BATTLE_DURATION_MS, E_INVALID_ARMY);
        
        // Calcular poder de ataque y defensa con todas las bonificaciones
        let attacker_power = calculate_army_power(attacker_army, battle.attacker_strategy, battle.defender_strategy, true);
        let defender_power = calculate_army_power(defender_army, battle.defender_strategy, battle.attacker_strategy, false);
        
        // Determinar resultado
        let total_power = attacker_power + defender_power;
        let attacker_win_chance = (attacker_power * 100) / total_power;
        let rand = kingdomutils::random(1, 100, ctx);
        
        let attacker_count = altriuxarmy::get_army_soldier_count(attacker_army);
        let defender_count = altriuxarmy::get_army_soldier_count(defender_army);
        
        let (attacker_losses, defender_losses) = if (rand <= attacker_win_chance) {
            // Atacante gana
            let att_losses = attacker_count * defender_power / total_power;
            let def_losses = defender_count * attacker_power * 2 / total_power;
            (att_losses, def_losses)
        } else {
            // Defensor gana
            let att_losses = attacker_count * defender_power * 2 / total_power;
            let def_losses = defender_count * attacker_power / total_power;
            (att_losses, def_losses)
        };
        
        // Aplicar bajas
        apply_losses(attacker_army, attacker_losses, ctx);
        apply_losses(defender_army, defender_losses, ctx);
        
        // Marcar batalla como resuelta
        battle.is_resolved = true;
        
        let attacker_owner = altriuxarmy::get_army_owner(attacker_army);
        let defender_owner = altriuxarmy::get_army_owner(defender_army);
        
        event::emit(BattleResult {
            battle_id,
            winner: if (rand <= attacker_win_chance) attacker_owner else defender_owner,
            loser: if (rand <= attacker_win_chance) defender_owner else attacker_owner,
            attacker_losses,
            defender_losses,
            location: battle.location,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // === DETECCIÓN DE EMBOSCADA ===
    public fun detect_ambush(
        attacker_army: &ArmyNFT,
        defender_army: &ArmyNFT,
        clock: &Clock,
        ctx: &mut TxContext
    ): bool {
        // Estrategia de defensa: Vigilancia Extrema (+50% detección)
        let def_strategy = altriuxarmy::get_army_strategy_defense(defender_army);
        let march_strategy = altriuxarmy::get_army_march_strategy(defender_army);
        let base_detection = if (def_strategy == STRAT_EXTREME_VIGILANCE) 50 else 15;
        
        // Bonificación por caballería en patrulla (20% requerido)
        let cavalry_ratio = get_cavalry_ratio(defender_army);
        let patrol_bonus = if (cavalry_ratio >= 20 && march_strategy == STRAT_PATROL_MARCH) 15 else 0;
        
        let total_detection = base_detection + patrol_bonus;
        let rand = kingdomutils::random(1, 100, ctx);
        
        if (rand <= total_detection) {
            event::emit(AmbushDetected {
                battle_id: object::id_from_address(@0x0), // No hay battle_id aún
                ambushing_army: object::id(attacker_army),
                target_army: object::id(defender_army),
                success_chance: total_detection as u8,
                timestamp: clock::timestamp_ms(clock),
            });
            true
        } else {
            false
        }
    }

    // === LÓGICA DE PODER DE EJÉRCITO ===
    fun calculate_army_power(army: &ArmyNFT, strategy: u8, enemy_strategy: u8, is_attacker: bool): u64 {
        let mut total_power = 0;
        let mut i = 0;
        let soldier_count = altriuxarmy::get_army_soldier_count(army);
        let army_location = altriuxarmy::get_army_location(army);
        
        while (i < soldier_count) {
            // Obtener stats del soldado usando getters
            let hp = altriuxarmy::get_soldier_hp(army, i);
            let energy = altriuxarmy::get_soldier_energy(army, i);
            let strength = altriuxarmy::get_soldier_strength(army, i);
            let tribe_type = altriuxarmy::get_soldier_tribe_type(army, i);
            let unit_class = altriuxarmy::get_soldier_unit_class(army, i);
            let rank = altriuxarmy::get_soldier_rank(army, i);
            let contract_period = altriuxarmy::get_soldier_contract_period(army, i);
            
            // Poder base según stats
            let base_power = (hp + energy + strength) / 3;
            
            // Bonificación por tribu según bioma
            let biome_bonus = altriux::altriuxarmy::get_biome_bonus(tribe_type, army_location);
            
            // Bonificación por estrategia
            let strategy_bonus = get_strategy_bonus(strategy, enemy_strategy, unit_class, is_attacker);
            
            // Bonificación por rango
            let rank_bonus = (rank as u64) * 5;
            
            // Bonificación por contrato largo
            let contract_bonus = if (contract_period > 25) 25 else contract_period;
            
            let final_power = base_power * 
                (100 + biome_bonus + strategy_bonus + rank_bonus + contract_bonus) / 100;
            
            total_power = total_power + final_power;
            i = i + 1;
        };
        
        // Bonificación especial para formaciones (falange, muro de picas)
        total_power = apply_formation_bonus(total_power, army, strategy);
        
        total_power
    }

    // === BONIFICACIONES DE ESTRATEGIA (24 tácticas) ===
    fun get_strategy_bonus(strategy: u8, enemy_strategy: u8, unit_class: u8, is_attacker: bool): u64 {
        // Bonificaciones base por estrategia
        let base_bonus = if (strategy == STRAT_STEALTH_GALLOP) 30
            else if (strategy == STRAT_ARROW_CURTAIN) 25
            else if (strategy == STRAT_MOUNTED_JAVELIN) 20
            else if (strategy == STRAT_PHALANX_CHARGE) 35
            else if (strategy == STRAT_FLANKING) 15
            else if (strategy == STRAT_FEIGNED_RETREAT) 10
            else if (strategy == STRAT_TESTUDO) 40
            else if (strategy == STRAT_SWARM) 20
            else if (strategy == STRAT_SIEGE_RUSH) 25
            else if (strategy == STRAT_AMBUSH) 30
            else if (strategy == STRAT_RAPID_MARCH) 50
            else if (strategy == STRAT_PATROL_MARCH) 15
            else if (strategy == STRAT_PIKE_WALL) 50
            else if (strategy == STRAT_SIEGE_CAMP) 40
            else if (strategy == STRAT_HILL_FORT) 35
            else if (strategy == STRAT_DESERT_HIDE) 30
            else if (strategy == STRAT_ICE_BARRIER) 45
            else if (strategy == STRAT_FOREST_AMBUSH) 35
            else if (strategy == STRAT_RIVER_DEFENSE) 25
            else if (strategy == STRAT_CASTLE_WALLS) 60
            else if (strategy == STRAT_TRENCHES) 20
            else if (strategy == STRAT_RESERVE) 15
            else if (strategy == STRAT_EXTREME_VIGILANCE) 50
            else if (strategy == STRAT_SUPPLY_LINE) 30
            else 0;
        
        // Penalizaciones por contras
        let penalty = if (strategy == STRAT_STEALTH_GALLOP && enemy_strategy == STRAT_PIKE_WALL) 80
            else if (strategy == STRAT_ARROW_CURTAIN && enemy_strategy == STRAT_STEALTH_GALLOP) 50
            else if (strategy == STRAT_MOUNTED_JAVELIN && enemy_strategy == STRAT_PIKE_WALL) 60
            else if (strategy == STRAT_PHALANX_CHARGE && enemy_strategy == STRAT_TESTUDO) 40
            else if (strategy == STRAT_SWARM && enemy_strategy == STRAT_ARROW_CURTAIN) 70
            else if (strategy == STRAT_RAPID_MARCH && enemy_strategy == STRAT_AMBUSH) 100
            else if (strategy == STRAT_AMBUSH && enemy_strategy == STRAT_EXTREME_VIGILANCE) 70
            else 0;
        
        (base_bonus * 100 / (100 + penalty)) as u64
    }

    // === BONIFICACIONES DE FORMACIÓN ===
    fun apply_formation_bonus(base_power: u64, army: &ArmyNFT, strategy: u8): u64 {
        let soldier_count = altriuxarmy::get_army_soldier_count(army);
        if (soldier_count == 0) return base_power;
        
        // Bonificación para falange (requiere 70% lanceros/phalanges)
        let phalanx_ratio = get_phalanx_ratio(army);
        if (strategy == STRAT_PHALANX_CHARGE && phalanx_ratio >= 70) {
            return base_power * 135 / 100; // +35%
        };
        
        // Bonificación para muro de picas (requiere 20% piqueros/alabarderos)
        let pike_ratio = get_pike_ratio(army);
        if (strategy == STRAT_PIKE_WALL && pike_ratio >= 20) {
            return base_power * 150 / 100; // +50% vs caballería
        };
        
        base_power
    }

    // === VALIDACIÓN DE ESTRATEGIAS ===
    fun validate_strategy_pair(attacker_strategy: u8, defender_strategy: u8) {
        // Algunas estrategias son incompatibles
        if (attacker_strategy == STRAT_RAPID_MARCH && defender_strategy == STRAT_AMBUSH) {
            // Marcha rápida extremadamente vulnerable a emboscada
        };
        // Otras validaciones según necesidad
    }

    // === HELPERS ===
    fun get_cavalry_ratio(army: &ArmyNFT): u64 {
        let mut cavalry = 0;
        let mut i = 0;
        let soldier_count = altriuxarmy::get_army_soldier_count(army);
        
        while (i < soldier_count) {
            let unit_class = altriuxarmy::get_soldier_unit_class(army, i);
            if (unit_class >= UNIT_CAVALRY_LIGHT && unit_class <= UNIT_CAVALRY_HEAVY) {
                cavalry = cavalry + 1;
            };
            i = i + 1;
        };
        if (soldier_count == 0) 0 else (cavalry * 100) / soldier_count
    }

    fun get_phalanx_ratio(army: &ArmyNFT): u64 {
        let mut phalanx = 0;
        let mut i = 0;
        let soldier_count = altriuxarmy::get_army_soldier_count(army);
        
        while (i < soldier_count) {
            let unit_class = altriuxarmy::get_soldier_unit_class(army, i);
            if (unit_class == UNIT_LANCER || unit_class == UNIT_PHALANX) {
                phalanx = phalanx + 1;
            };
            i = i + 1;
        };
        if (soldier_count == 0) 0 else (phalanx * 100) / soldier_count
    }

    fun get_pike_ratio(army: &ArmyNFT): u64 {
        let mut pike = 0;
        let mut i = 0;
        let soldier_count = altriuxarmy::get_army_soldier_count(army);
        
        while (i < soldier_count) {
            let unit_class = altriuxarmy::get_soldier_unit_class(army, i);
            if (unit_class == UNIT_PIKEMAN || unit_class == UNIT_HALBERDIER) {
                pike = pike + 1;
            };
            i = i + 1;
        };
        if (soldier_count == 0) 0 else (pike * 100) / soldier_count
    }

    fun apply_losses(army: &mut ArmyNFT, losses: u64, ctx: &mut TxContext) {
        if (losses == 0) return;
        let mut removed = 0;
        let mut soldier_count = altriuxarmy::get_army_soldier_count(army);
        
        while (removed < losses && soldier_count > 0) {
            let idx = (kingdomutils::random(0, soldier_count - 1, ctx) as u64);
            altriuxarmy::remove_random_soldier(army, idx);
            removed = removed + 1;
            soldier_count = soldier_count - 1;
        };
    }

    // === GETTERS PÚBLICOS ===
    public fun id_strat_stealth_gallop(): u8 { STRAT_STEALTH_GALLOP }
    public fun id_strat_pike_wall(): u8 { STRAT_PIKE_WALL }
    public fun id_strat_extreme_vigilance(): u8 { STRAT_EXTREME_VIGILANCE }
    public fun id_unit_lancer(): u8 { UNIT_LANCER }
    public fun id_unit_phalanx(): u8 { UNIT_PHALANX }
    public fun id_unit_halberdier(): u8 { UNIT_HALBERDIER }
    public fun id_unit_pikeman(): u8 { UNIT_PIKEMAN }
}