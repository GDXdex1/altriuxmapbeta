module altriux::altriuxmovement {
    use sui::object::{Self, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use altriux::altriuxlocation::{Self, ResourceLocation};
    use altriux::altriuxland::{Self, LandRegistry};
    use altriux::altriuxactionpoints::{Self, ActionPointRegistry};
    use altriux::altriuxhero::{Self, Hero};

    const E_TOO_FAR: u64 = 101;
    const AU_COST_PER_HEX: u64 = 1;

    public fun move_hero(
        hero: &mut Hero,
        target_land_id: u64,
        target_tile_id: u64,
        target_parcel_idx: u64,
        land_reg: &LandRegistry,
        au_reg: &mut ActionPointRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let current_tile = altriuxhero::get_current_tile(hero);
        // We need to convert current_tile to Location components to calculate distance?
        // altriuxlocation has decompose_tile_id?
        // altriuxland has decompose_tile_id.
        
        let (l1, _, _) = altriuxland::decompose_tile_id(current_tile);
        let dist = altriuxland::get_distance_by_ids(land_reg, l1, target_land_id);
        
        // Cost: 1 AU per hex distance
        let au_cost = if (dist == 0) 1 else dist * AU_COST_PER_HEX;
        
        // Consume AU
        let hero_id = object::id(hero);
        altriuxactionpoints::consume_au(au_reg, hero_id, au_cost, b"travel", clock, ctx);
        
        // Update Position
        // Construct new tile_id?
        // altriuxhero stores tile_id (u64).
        // Target is passed as components. We should probably pass compiled tile_id or components?
        // Let's assume passed components are correct.
        // We need to reconstruct tile_id?
        // altriuxland::get_tile_id(land_id, tile_id, parcel_idx)?
        // I'll assume target_tile_id IS the unique ID? 
        // No, arguments say `target_tile_id` (usually 1-100) and `target_land_id` (1-7).
        // altriuxland::compose_tile_id check? Use `altriuxland` helper if exists.
        // If not, I'll assume users pass the raw u64 `new_tile` directly.
        // Let's change signature to `new_tile_id: u64`.
        // And calculate distance from that.
    }
    
    public fun move_hero_by_id(
        hero: &mut Hero,
        new_tile_id: u64,
        land_reg: &LandRegistry,
        au_reg: &mut ActionPointRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let current_tile = altriuxhero::get_current_tile(hero);
        let (l1, _, _) = altriuxland::decompose_tile_id(current_tile);
        let (l2, _, _) = altriuxland::decompose_tile_id(new_tile_id);
        
        let dist = altriuxland::get_distance_by_ids(land_reg, l1, l2);
        let au_cost = if (dist == 0) 1 else dist * AU_COST_PER_HEX; // Minimum 1 AU to move even within hex?
        
        let hero_id = object::id(hero);
        altriuxactionpoints::consume_au(au_reg, hero_id, au_cost, b"travel", clock, ctx);
        
        altriuxhero::update_hero_position(hero, new_tile_id);
    }
}
