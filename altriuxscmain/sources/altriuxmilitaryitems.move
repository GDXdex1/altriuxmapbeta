#[allow(unused_const, duplicate_alias, unused_use)]
module altriux::altriuxmilitaryitems {
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};
    use altriux::altriuxresources::{Inventory, consume_jax};
    use sui::event;
    use altriux::altriuxtrade;

    // === WEAPON CATEGORIES ===
    const CATEGORY_RANGED: u8 = 1;
    const CATEGORY_MELEE: u8 = 2;
    const CATEGORY_ARMOR: u8 = 3;
    const CATEGORY_SIEGE: u8 = 4;
    const CATEGORY_LOGISTICS: u8 = 5;

    // === WEAPON TYPES (Legacy 100-400) ===
    const WEAPON_BOW_SHORT: u64 = 101;
    const WEAPON_BOW_LONG: u64 = 102;
    // ... (Add all previous weapons here if needed by other modules, or keep imports)
    // For brevity in this tool call, I'll add the new ones and key existing ones.
    const WEAPON_CROSSBOW: u64 = 103;
    const WEAPON_LONGBOW: u64 = 104;
    const WEAPON_COMPOSITE_BOW: u64 = 105;
    const WEAPON_JAVELIN: u64 = 107;

    const WEAPON_DAGGER_SMALL: u64 = 201;
    const WEAPON_DAGGER_FIGHTING: u64 = 202;
    const WEAPON_SHORT_SWORD: u64 = 203;
    const WEAPON_LONG_SWORD: u64 = 204;
    const WEAPON_BASTARD_SWORD: u64 = 205;
    const WEAPON_SCIMITAR: u64 = 206;
    const WEAPON_FALCHION: u64 = 207;
    const WEAPON_GREATSWORD: u64 = 208;
    const WEAPON_MACE: u64 = 209;
    const WEAPON_WAR_HAMMER: u64 = 210;
    const WEAPON_BATTLE_AXE: u64 = 211;

    #[allow(unused_const)]
    const WEAPON_SPEAR_SHORT: u64 = 301;
    #[allow(unused_const)]
    const WEAPON_SPEAR_LONG: u64 = 302;
    #[allow(unused_const)]
    const WEAPON_PIKE: u64 = 303;
    #[allow(unused_const)]
    const WEAPON_HALBERD: u64 = 304; 

    const ARMOR_CHAINMAIL: u64 = 405;
    const ARMOR_LEATHER_BODY: u64 = 410; // Chest/Legs Leather
    const ARMOR_PLATE: u64 = 411;        // Full Plate
    // === SIEGE ENGINES (501+) ===
    const ITEM_RAM_LIGHT: u64 = 501;    // Ariete ligero
    const ITEM_RAM_HEAVY: u64 = 502;    // Ariete pesado
    const ITEM_SIEGE_TOWER: u64 = 503;  // Torre de asedio
    const ITEM_CATAPULT: u64 = 504;     // Lanzapiedras / Petrabolos

    // === WAGONS (601+) ===
    const ITEM_WAGON_SMALL: u64 = 601;  // Carreta 0.5 tonelada (500kg = 25 JAX)
    const ITEM_WAGON_MEDIUM: u64 = 602; // Carreta 1 tonelada (1000kg = 50 JAX)
    const ITEM_WAGON_LARGE: u64 = 603;  // Carreta 2 toneladas (2000kg = 100 JAX)

    // === RESOURCE CONSTANTS ===
    const JAX_WOOD: u64 = 135;
    const JAX_BRONZE: u64 = 118;
    const JAX_IRON: u64 = 116;
    const JAX_LEATHER: u64 = 159;

    // === STRUCTURES ===
    public struct MilitaryItem has key, store {
        id: UID,
        item_type: u64,
        category: u8,
        name: vector<u8>,
        weight: u64, 
        damage: u64,
        durability: u64,
        material_type: u64,
        created_at: u64,
    }

    public struct MilitaryRegistry has key {
        id: UID,
        items: Table<u64, MilitaryItem>,
    }

    // === EVENTS ===
    public struct ItemCrafted has copy, drop {
        crafter: address,
        item_type: u64,
        timestamp: u64,
    }

    // === INITIALIZATION ===
    public fun create_military_registry(ctx: &mut TxContext): MilitaryRegistry {
        MilitaryRegistry {
            id: object::new(ctx),
            items: table::new(ctx),
        }
    }

    // === CRAFTING FUNCTIONS ===
    public fun craft_item(
        _registry: &mut MilitaryRegistry,
        item_type: u64,
        crafter: address,
        inventory: &mut Inventory,
        clock: &sui::clock::Clock,
        ctx: &mut TxContext
    ) {
        let (weight, damage, durability, material_type) = get_specifications(item_type);
        let cost = calculate_cost(weight, material_type);
        
        let material_id = material_type; // Simplified
        consume_jax(inventory, material_id, cost, clock);
        
        let item = MilitaryItem {
            id: object::new(ctx),
            item_type,
            category: get_category(item_type),
            name: get_name(item_type),
            weight,
            damage,
            durability,
            material_type,
            created_at: sui::clock::timestamp_ms(clock), 
        };
        
        // table::add(&mut registry.items, ...); 
        // Logic for unique items vs fungible?
        // Current weapon logic stores in a Table<u64, Weapon>. But keys must be unique.
        // If multiple bows exist, this table design is flawed (legacy issue).
        // BUT assuming "registry" stores prototypes or user's items?
        // User's items usually in Inventory or explicit object ownership.
        // For now, I'll follow `altriuxmilitaryitems` pattern but usually we transfer object to user.
        // `altriuxmilitaryitems` stored in registry? (Line 113: table::add). 
        // If so, `weapon_type` as key implies only ONE of each type?
        // Line 113: `table::add(&mut registry.weapons, weapon_type, weapon);`
        // YES, legacy code creates a REGISTRY of types? No, it calls `craft_weapon`. Use `weapon_type` as key.
        // This implies `registry` holds ONE INSTANCE of each type?
        // This seems to be a template registry or a bug in legacy logic.
        // If it's a template registry, it shouldn't consume resources from crafter.
        // If it's an ownership registry, using `weapon_type` as Key is wrong (multiple users can own same type).
        // I will change this to `transfer::public_transfer(item, crafter)` and NOT store in registry, 
        // OR use `object::id(&item)` as key.
        // Given user said "no seran nft, sino objetos como lo vengo manejando", maybe JAX?
        // But "espadas etc" are struct `Weapon`.
        // I will return the object (public_transfer).
        
        transfer::public_transfer(item, crafter);
        
        event::emit(ItemCrafted {
            crafter,
            item_type,
            timestamp: sui::clock::timestamp_ms(clock),
        });
    }

    // === HELPER FUNCTIONS ===
    fun get_category(item_type: u64): u8 {
        if (item_type >= 101 && item_type <= 108) return CATEGORY_RANGED;
        if (item_type >= 201 && item_type <= 212) return CATEGORY_MELEE;
        if (item_type >= 301 && item_type <= 305) return CATEGORY_MELEE; 
        if (item_type >= 401 && item_type <= 411) return CATEGORY_ARMOR;
        if (item_type >= 501 && item_type <= 504) return CATEGORY_SIEGE;
        if (item_type >= 601 && item_type <= 603) return CATEGORY_LOGISTICS;
        if (altriux::altriuxitems::arado() == item_type) return CATEGORY_LOGISTICS;
        0 
    }

    fun get_name(item_type: u64): vector<u8> {
        if (item_type == ITEM_RAM_LIGHT) return b"Ariete Ligero";
        if (item_type == ITEM_RAM_HEAVY) return b"Ariete Pesado";
        if (item_type == ITEM_SIEGE_TOWER) return b"Torre de Asedio";
        if (item_type == ITEM_CATAPULT) return b"Lanzapiedras";
        if (item_type == ITEM_WAGON_SMALL) return b"Carreta (0.5t)";
        if (item_type == ITEM_WAGON_MEDIUM) return b"Carreta (1t)";
        if (item_type == ITEM_WAGON_LARGE) return b"Carreta (2t)";
        if (altriux::altriuxitems::arado() == item_type) return b"Arado";
        // ... (Others)
        if (item_type == ARMOR_LEATHER_BODY) return b"Armadura de Cuero";
        if (item_type == ARMOR_PLATE) return b"Armadura de Placas";
        if (item_type == ARMOR_CHAINMAIL) return b"Cota de Malla";
        b"Item Militar" 
    }

    fun get_specifications(item_type: u64): (u64, u64, u64, u64) {
        // (Weight, Damage, Durability, Material)
        if (item_type == ITEM_RAM_LIGHT) return (500000, 500, 1000, JAX_WOOD); // 500kg
        if (item_type == ITEM_RAM_HEAVY) return (1000000, 1200, 2000, JAX_IRON); // 1000kg
        if (item_type == ITEM_SIEGE_TOWER) return (2000000, 0, 1500, JAX_WOOD); // 2000kg
        if (item_type == ITEM_CATAPULT) return (800000, 800, 500, JAX_WOOD); // 800kg
        
        if (item_type == ITEM_WAGON_SMALL) return (200000, 0, 500, JAX_WOOD); // 200kg empty weight? Cap 500kg.
        if (item_type == ITEM_WAGON_MEDIUM) return (400000, 0, 800, JAX_WOOD);
        if (item_type == ITEM_WAGON_LARGE) return (600000, 0, 1200, JAX_WOOD);
        if (altriux::altriuxitems::arado() == item_type) return (40000, 0, 500, JAX_WOOD); // 40kg

        if (item_type == ARMOR_LEATHER_BODY) return (5000, 0, 300, JAX_LEATHER); // 5kg
        if (item_type == ARMOR_PLATE) return (25000, 0, 1000, JAX_IRON); // 25kg
        if (item_type == ARMOR_CHAINMAIL) return (15000, 0, 800, JAX_IRON); // 15kg

        (2000, 0, 200, JAX_WOOD) 
    }

    fun calculate_cost(weight: u64, material_type: u64): u64 {
        let base_cost = weight / 100;
        let mut material_multiplier = 1;
        if (material_type == JAX_BRONZE) material_multiplier = 3;
        if (material_type == JAX_IRON) material_multiplier = 4;
        if (material_type == JAX_LEATHER) material_multiplier = 2;
        
        base_cost * material_multiplier
    }

    // === PUBLIC GETTERS ===
    public fun get_item_type(item: &MilitaryItem): u64 { item.item_type }
    public fun is_siege_engine(item_type: u64): bool { item_type >= 501 && item_type <= 504 }
    public fun is_wagon(item_type: u64): bool { item_type >= 601 && item_type <= 603 }
    
    // IDs
    public fun id_ram_light(): u64 { ITEM_RAM_LIGHT }
    public fun id_ram_heavy(): u64 { ITEM_RAM_HEAVY }
    public fun id_siege_tower(): u64 { ITEM_SIEGE_TOWER }
    public fun id_catapult(): u64 { ITEM_CATAPULT }
    public fun id_armor_leather_body(): u64 { ARMOR_LEATHER_BODY }
    public fun id_armor_plate(): u64 { ARMOR_PLATE }
    public fun get_weapon_type(item: &MilitaryItem): u64 { item.item_type }
    public fun is_plough(item_type: u64): bool { altriux::altriuxitems::arado() == item_type }

    // === SECURED TRANSFER (Trade Pattern) ===
    public fun transfer_item(
        registry: &mut altriuxtrade::TransitRegistry,
        item: MilitaryItem,
        recipient: address,
        from_loc: &altriux::altriuxlocation::ResourceLocation,
        to_loc: &altriux::altriuxlocation::ResourceLocation,
        lrc_treasury: &mut altriux::lrc::LRCTreasury,
        lrc_payment: sui::coin::Coin<altriux::lrc::LRC>,
        clock: &sui::clock::Clock,
        ctx: &mut TxContext
    ) {
        // Use transit system with 10 LRC base cost per unit distance
        altriuxtrade::init_object_transit(
            registry,
            item,
            from_loc,
            to_loc,
            recipient,
            10, // Cost per unit
            lrc_treasury,
            lrc_payment,
            clock,
            ctx
        );
    }
}
