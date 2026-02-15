module altriux::altriuxreligion {
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use std::option::{Self, Option};

    // === TIPOS DE RELIGIONES ===
    const RELIGION_CRIX: u8 = 1;  
    const RELIGION_IMLAX: u8 = 2;  
    const RELIGION_YAX: u8 = 3;    
    const RELIGION_SHIX: u8 = 4;   
    const RELIGION_DRAX: u8 = 5;   
    const RELIGION_SUX: u8 = 6;    

    // === ESTRUCTURAS DE DATOS ===
    public struct ReligionRegistry has key {
        id: UID,
        religions: Table<u8, Religion>,
        followers_count: Table<u8, u64>,
    }

    public struct Religion has key, store {
        id: UID,
        religion_type: u8,
        name: vector<u8>,
        description: vector<u8>,
        founding_date: u64,
        holy_books: vector<vector<u8>>,
        benefits: Table<u8, u64>, 
    }

    public struct FaithRecord has key, store {
        id: UID,
        owner: address,
        religion_type: u8,
        faith_level: u8, 
        conversion_date: u64,
        last_prayer: u64,
        offerings_made: u64,
        blessings_received: u64,
    }

    // === EVENTOS ===
    public struct ReligionFounded has copy, drop {
        religion_type: u8,
        founder: address,
        founding_date: u64,
    }

    public struct Conversion has copy, drop {
        believer: address,
        old_religion: Option<u8>,
        new_religion: u8,
        conversion_date: u64,
    }

    public struct OfferingMade has copy, drop {
        believer: address,
        religion_type: u8,
        offering_amount: u64,
        offering_date: u64,
    }

    // ... keeping others as before but fixed imports
    public fun create_religion_registry(ctx: &mut TxContext): ReligionRegistry {
        ReligionRegistry {
            id: object::new(ctx),
            religions: table::new(ctx),
            followers_count: table::new(ctx),
        }
    }
}
