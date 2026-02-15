#[allow(duplicate_alias, unused_use)]
module altriux::altriuxbuildingbase {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use sui::clock::Clock;
    use sui::transfer;
    use sui::dynamic_field;
    use std::option;
    use altriux::altriuxlocation::{ResourceLocation};

    const PERIOD_1_DAY: u64 = 1;
    const PERIOD_10_DAYS: u64 = 10;
    const PERIOD_30_DAYS: u64 = 30;
    const PERIOD_80_DAYS: u64 = 80;
    const PERIOD_90_DAYS: u64 = 90;

    // === TIPOS DE EDIFICIO ===
    const GRANJA_PEQUENA: u64 = 1;
    const GRANJA_MEDIANA: u64 = 2;
    const GRANJA_GRANDE: u64 = 3;
    const HUERTO: u64 = 4;
    const MERCADO: u64 = 5;
    const GRAN_MERCADO: u64 = 6;
    const MINA_SUPERFICIAL: u64 = 11;
    const MINA_SUBTERRANEA: u64 = 12;
    const FUNDICION_TRIBAL: u64 = 13;
    const FUNDICION_INDUSTRIAL: u64 = 14;
    const FORJA: u64 = 15;
    const TALLER_TEXTIL: u64 = 21;
    const MOLINO_FLUVIAL_PEQUENO: u64 = 22;
    const MOLINO_FLUVIAL_GRANDE: u64 = 23;
    const MOLINO_SANGRE_PEQUENO: u64 = 24;
    const MOLINO_SANGRE_GRANDE: u64 = 25;
    const CARBONERA: u64 = 26;
    const PANADERIA: u64 = 27;
    const CARNICERIA: u64 = 28;
    const BODEGA: u64 = 30;
    const AHUMADERO: u64 = 31;
    const ESTABLO: u64 = 32;
    const CORRAL: u64 = 33;
    const GRANERO: u64 = 34;
    const MALTERIA: u64 = 35;
    const TALLER_CEREALES: u64 = 36;
    const MOLINO_PIEDRA: u64 = 37;
    const DESCASCARILLADORA: u64 = 38;
    const DESTILERIA_ORIENTAL: u64 = 39;
    const FERMENTADOR_TROPICAL: u64 = 40;
    const TALLER_SOYA: u64 = 41;
    const PRENSA_ACEITE: u64 = 42;
    const MOLINO_MANI: u64 = 43;
    const MOLINO_LEGUMBRES: u64 = 48;

    const MURALLA_MADERA: u64 = 44;
    const MURALLA_PIEDRA: u64 = 45;
    const TORRE_VIGIA: u64 = 46;
    const FOSO: u64 = 47;
    const TRAPICHE: u64 = 54;
    const SECADERO: u64 = 55;
    const MOLINO_ACEITUNAS: u64 = 56;
    const PRENSA_TROPICAL: u64 = 57;
    const HILADERO: u64 = 70;
    const TEJEDERO: u64 = 71;
    const SASTRERIA: u64 = 72;
    const ASTILLERO: u64 = 75;

    const MESQUITA_IMLAX_PEQUENA: u64 = 200;
    const MESQUITA_IMLAX_GRANDE: u64 = 201;
    const MADRASA_IMLAX: u64 = 202;
    const IGLESIA_CRIS_PEQUENA: u64 = 203;
    const CATEDRAL_CRIS: u64 = 204;
    const ESCUELA_DRAXIUX: u64 = 205;
    const MONASTERIO_DRAXIUX: u64 = 206;
    const TEMPLO_SHIX: u64 = 207;
    const ESCUELA_SHIX: u64 = 208;
    const SINAGOGA_YAX: u64 = 209;
    const ESCUELA_YAX: u64 = 210;
    const TEMPLO_SUX: u64 = 211;
    const ESCUELA_ASTRONOMICA_SUX: u64 = 212;

    public struct ResourceCost has copy, drop, store {
        resource_id: u64,
        amount: u64,
    }

    public struct BuildingNFT has key, store {
        id: UID,
        type_id: u64,
        size_jex: u64,
        location: ResourceLocation,
        level: u8,
        workers: u64,
        max_workers: u64,
        last_production: u64,
        owner: address,
        is_protected: bool,
        production_in_progress: bool,
        production_end_time: u64,
        production_period: u64,
        storage_capacity_jax: u64,
        current_storage_jax: u64,
        id_market: option::Option<ID>,
    }

    public struct BuildingRegistry has key {
        id: UID,
        buildings: table::Table<ID, BuildingNFT>,
    }

    // === INICIALIZACIÓN ===
    public fun create_building_registry(ctx: &mut TxContext) {
        let registry = BuildingRegistry {
            id: object::new(ctx),
            buildings: table::new(ctx),
        };
        transfer::share_object(registry);
    }

    // === CONSTRUCTORS ===

    public fun new_resource_cost(resource_id: u64, amount: u64): ResourceCost {
        ResourceCost { resource_id, amount }
    }

    public fun cost_id(cost: &ResourceCost): u64 { cost.resource_id }
    public fun cost_amount(cost: &ResourceCost): u64 { cost.amount }

    public fun new_building_nft(
        type_id: u64,
        size_jex: u64,
        location: ResourceLocation,
        level: u8,
        max_workers: u64,
        last_production: u64,
        owner: address,
        is_protected: bool,
        storage_capacity_jax: u64,
        ctx: &mut TxContext
    ): BuildingNFT {
        BuildingNFT {
            id: object::new(ctx),
            type_id,
            size_jex,
            location,
            level,
            workers: 0,
            max_workers,
            last_production,
            owner,
            is_protected,
            production_in_progress: false,
            production_end_time: 0,
            production_period: 0,
            storage_capacity_jax,
            current_storage_jax: 0,
            id_market: std::option::none(),
        }
    }

    // === GETTERS ===

    public fun get_building_type(building: &BuildingNFT): u64 { building.type_id }
    public fun get_building_level(building: &BuildingNFT): u8 { building.level }
    public fun get_building_location(building: &BuildingNFT): &ResourceLocation { &building.location }
    public fun get_building_tile(building: &BuildingNFT): u64 { altriux::altriuxlocation::get_tile_id(&building.location) }
    public fun get_building_uid(building: &BuildingNFT): &UID { &building.id }
    public fun get_building_uid_mut(building: &mut BuildingNFT): &mut UID { &mut building.id }
    public fun get_building_owner(building: &BuildingNFT): address { building.owner }
    public fun get_building_workers(building: &BuildingNFT): u64 { building.workers }
    public fun get_max_workers(building: &BuildingNFT): u64 { building.max_workers }
    public fun get_last_production(building: &BuildingNFT): u64 { building.last_production }
    public fun is_production_in_progress(building: &BuildingNFT): bool { building.production_in_progress }
    public fun get_production_end_time(building: &BuildingNFT): u64 { building.production_end_time }
    public fun get_current_storage(building: &BuildingNFT): u64 { building.current_storage_jax }
    public fun get_storage_capacity(building: &BuildingNFT): u64 { building.storage_capacity_jax }
    public fun get_production_period(building: &BuildingNFT): u64 { building.production_period }
    public fun id_market(building: &BuildingNFT): Option<ID> { building.id_market }
    public fun is_protected(building: &BuildingNFT): bool { building.is_protected }
    public fun get_building_size(building: &BuildingNFT): u64 { building.size_jex }

    // Building Types Getters
    public fun type_granja_pequena(): u64 { GRANJA_PEQUENA }
    public fun type_granja_mediana(): u64 { GRANJA_MEDIANA }
    public fun type_granja_grande(): u64 { GRANJA_GRANDE }
    public fun type_huerto(): u64 { HUERTO }
    public fun type_mercado(): u64 { MERCADO }
    public fun type_gran_mercado(): u64 { GRAN_MERCADO }
    public fun type_establo(): u64 { ESTABLO }
    public fun type_corral(): u64 { CORRAL }
    public fun type_granero(): u64 { GRANERO }
    public fun type_malteria(): u64 { MALTERIA }
    public fun type_taller_cereales(): u64 { TALLER_CEREALES }
    public fun type_molino_piedra(): u64 { MOLINO_PIEDRA }
    public fun type_descascarilladora(): u64 { DESCASCARILLADORA }
    public fun type_destileria_oriental(): u64 { DESTILERIA_ORIENTAL }
    public fun type_fermentador_tropical(): u64 { FERMENTADOR_TROPICAL }
    public fun type_taller_soya(): u64 { TALLER_SOYA }
    public fun type_prensa_aceite(): u64 { PRENSA_ACEITE }
    public fun type_molino_mani(): u64 { MOLINO_MANI }
    public fun type_molino_legumbres(): u64 { MOLINO_LEGUMBRES }
    public fun type_mina_superficial(): u64 { MINA_SUPERFICIAL }
    public fun type_mina_subterranea(): u64 { MINA_SUBTERRANEA }
    public fun type_fundicion_tribal(): u64 { FUNDICION_TRIBAL }
    public fun type_fundicion_industrial(): u64 { FUNDICION_INDUSTRIAL }
    public fun type_forja(): u64 { FORJA }
    public fun type_molino_fluvial_pequeno(): u64 { MOLINO_FLUVIAL_PEQUENO }
    public fun type_molino_fluvial_grande(): u64 { MOLINO_FLUVIAL_GRANDE }
    public fun type_molino_sangre_pequeno(): u64 { MOLINO_SANGRE_PEQUENO }
    public fun type_molino_sangre_grande(): u64 { MOLINO_SANGRE_GRANDE }
    public fun type_carbonera(): u64 { CARBONERA }
    public fun type_taller_textil(): u64 { TALLER_TEXTIL }
    public fun type_panaderia(): u64 { PANADERIA }
    public fun type_carniceria(): u64 { CARNICERIA }
    public fun type_bodega(): u64 { BODEGA }
    public fun type_ahumadero(): u64 { AHUMADERO }
    public fun type_muralla_madera(): u64 { MURALLA_MADERA }
    public fun type_muralla_piedra(): u64 { MURALLA_PIEDRA }
    public fun type_torre_vigia(): u64 { TORRE_VIGIA }
    public fun type_foso(): u64 { FOSO }
    public fun type_trapiche(): u64 { TRAPICHE }
    public fun type_secadero(): u64 { SECADERO }
    public fun type_molino_aceitunas(): u64 { MOLINO_ACEITUNAS }
    public fun type_prensa_tropical(): u64 { PRENSA_TROPICAL }

    public fun type_mesquita_imlax_pequena(): u64 { MESQUITA_IMLAX_PEQUENA }
    public fun type_mesquita_imlax_grande(): u64 { MESQUITA_IMLAX_GRANDE }
    public fun type_madrasa_imlax(): u64 { MADRASA_IMLAX }
    public fun type_iglesia_cris_pequena(): u64 { IGLESIA_CRIS_PEQUENA }
    public fun type_catedral_cris(): u64 { CATEDRAL_CRIS }
    public fun type_escuela_draxiux(): u64 { ESCUELA_DRAXIUX }
    public fun type_monasterio_draxiux(): u64 { MONASTERIO_DRAXIUX }
    public fun type_templo_shix(): u64 { TEMPLO_SHIX }
    public fun type_escuela_shix(): u64 { ESCUELA_SHIX }
    public fun type_sinagoga_yax(): u64 { SINAGOGA_YAX }
    public fun type_escuela_yax(): u64 { ESCUELA_YAX }
    public fun type_templo_sux(): u64 { TEMPLO_SUX }
    public fun type_escuela_astronomica_sux(): u64 { ESCUELA_ASTRONOMICA_SUX }

    // === SETTERS / MUTATORS ===

    public fun set_production_state(building: &mut BuildingNFT, in_progress: bool, end_time: u64, period: u64, worker_count: u64) {
        building.production_in_progress = in_progress;
        building.production_end_time = end_time;
        building.production_period = period;
        building.workers = worker_count;
    }

    public fun update_storage(building: &mut BuildingNFT, new_amount: u64) {
        building.current_storage_jax = new_amount;
    }

    public fun reset_production(building: &mut BuildingNFT, now: u64) {
        building.last_production = now;
        building.production_in_progress = false;
        building.production_end_time = 0;
        building.production_period = 0;
        building.workers = 0;
    }

    public fun destroy_building(building: BuildingNFT) {
        let BuildingNFT { id, id_market: _, .. } = building;
        object::delete(id);
    }

    // Registry helpers
    public fun get_land_used_jex(reg: &BuildingRegistry, land_id: ID): u64 {
        if (dynamic_field::exists_(&reg.id, land_id)) {
            *dynamic_field::borrow<ID, u64>(&reg.id, land_id)
        } else {
            0
        }
    }

    public fun register_land_usage(reg: &mut BuildingRegistry, land_id: ID, size_jex: u64) {
        let current = get_land_used_jex(reg, land_id);
        if (dynamic_field::exists_(&reg.id, land_id)) {
            let val = dynamic_field::borrow_mut<ID, u64>(&mut reg.id, land_id);
            *val = current + size_jex;
        } else {
            dynamic_field::add(&mut reg.id, land_id, current + size_jex);
        };
    }

    public fun unregister_land_usage(reg: &mut BuildingRegistry, land_id: ID, size_jex: u64) {
        let current = get_land_used_jex(reg, land_id);
        if (current >= size_jex) {
            let val = dynamic_field::borrow_mut<ID, u64>(&mut reg.id, land_id);
            *val = current - size_jex;
        };
    }

    public fun borrow_building(reg: &BuildingRegistry, id: ID): &BuildingNFT {
        table::borrow(&reg.buildings, id)
    }

    public fun borrow_building_mut(reg: &mut BuildingRegistry, id: ID): &mut BuildingNFT {
        table::borrow_mut(&mut reg.buildings, id)
    }

    public fun add_building_to_registry(reg: &mut BuildingRegistry, building: BuildingNFT) {
        table::add(&mut reg.buildings, object::id(&building), building);
    }

    public fun remove_building_from_registry(reg: &mut BuildingRegistry, id: ID): BuildingNFT {
        table::remove(&mut reg.buildings, id)
    }

    public fun period_1_day(): u64 { PERIOD_1_DAY }
    public fun period_10_days(): u64 { PERIOD_10_DAYS }
    public fun period_30_days(): u64 { PERIOD_30_DAYS }
    public fun period_80_days(): u64 { PERIOD_80_DAYS }
    public fun period_90_days(): u64 { PERIOD_90_DAYS }
    
    public fun type_hiladero(): u64 { HILADERO }
    public fun type_tejedero(): u64 { TEJEDERO }
    public fun type_sastreria(): u64 { SASTRERIA }
    public fun type_astillero(): u64 { ASTILLERO }
}
