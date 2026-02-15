module altriux::altriuxnobility {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use std::vector;
    use altriux::altriuxland::Land;
    use altriux::altriuxhero::{Self, Hero};

    // --- Ranks ---
    const RANK_KNIGHT: u8 = 1;
    const RANK_BARONET: u8 = 2;
    const RANK_COUNT: u8 = 3;
    const RANK_DUKE: u8 = 4;
    const RANK_PRINCE: u8 = 5;
    const RANK_KING: u8 = 6;

    // --- Requirements (Lands) ---
    const REQ_KNIGHT: u64 = 1;
    const REQ_BARONET: u64 = 10;
    const REQ_COUNT: u64 = 150;
    const REQ_DUKE: u64 = 600;
    const REQ_PRINCE: u64 = 1500;
    const REQ_KING: u64 = 5000;

    public struct NobilityTitle has key, store {
        id: UID,
        rank: u8,
        lordship: vector<u8>,
        formatted_title: vector<u8>,
        religion: u8,
        owner: address,
    }

    /// Mints a nobility title if the sender provides proof of land ownership.
    /// The VM ensures that all Land objects in the vector are owned by the sender.
    public fun mint_title(
        lands: &vector<Land>,
        lordship: vector<u8>,
        hero: &Hero,
        rank: u8,
        ctx: &mut TxContext
    ) {
        let land_count = vector::length(lands);
        let req = get_requirement(rank);
        assert!(land_count >= req, 101); // Insufficient land

        let formatted_title = generate_title(rank, lordship);
        let religion = altriuxhero::get_religion(hero);

        let title_nft = NobilityTitle {
            id: object::new(ctx),
            rank,
            lordship,
            formatted_title,
            religion,
            owner: tx_context::sender(ctx),
        };

        transfer::public_transfer(title_nft, tx_context::sender(ctx));
    }

    // --- Helper Functions ---

    fun get_requirement(rank: u8): u64 {
        if (rank == RANK_KNIGHT) return REQ_KNIGHT;
        if (rank == RANK_BARONET) return REQ_BARONET;
        if (rank == RANK_COUNT) return REQ_COUNT;
        if (rank == RANK_DUKE) return REQ_DUKE;
        if (rank == RANK_PRINCE) return REQ_PRINCE;
        if (rank == RANK_KING) return REQ_KING;
        999999
    }

    fun generate_title(rank: u8, lordship: vector<u8>): vector<u8> {
        let prefix = if (rank == RANK_KNIGHT) b"Caballero de "
        else if (rank == RANK_BARONET) b"Baronet de "
        else if (rank == RANK_COUNT) b"Conde de "
        else if (rank == RANK_DUKE) b"Duque de "
        else if (rank == RANK_PRINCE) b"Pr\xC3\xADncipe de " // UTF-8 for í
        else if (rank == RANK_KING) b"Rey de "
        else b"Noble de ";

        let mut title = vector::empty<u8>();
        vector::append(&mut title, prefix);
        vector::append(&mut title, lordship);
        title
    }

    // --- Getters ---

    public fun get_title_name(nft: &NobilityTitle): vector<u8> {
        nft.formatted_title
    }

    public fun get_rank(nft: &NobilityTitle): u8 {
        nft.rank
    }
}
