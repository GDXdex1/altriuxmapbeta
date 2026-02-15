#[allow(duplicate_alias, unused_use)]
module altriux::altriuxmovement {
    use sui::object::{Self, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use altriux::altriuxlocation::{Self, ResourceLocation};
    use altriux::altriuxland::{Self, LandRegistry};
    use altriux::altriuxactionpoints::{Self, ActionPointRegistry};
    use altriux::altriuxhero::{Self, Hero};

    const E_ALREADY_TRAVELING: u64 = 102;
    const E_NOT_TRAVELING: u64 = 103;
    const E_NOT_ARRIVED: u64 = 104;

    const AU_COST_PER_HEX: u64 = 1;
    const MS_PER_HEX: u64 = 1728000; // ~28.8 minutes per hex (1,728,000 ms)

    public fun initiate_travel(
        hero: &mut Hero,
        t_hq: u64, t_hr: u64, t_hq_neg: bool, t_hr_neg: bool,
        t_sq: u64, t_sr: u64, t_sq_neg: bool, t_sr_neg: bool,
        target_tile_id: u64,
        au_reg: &mut ActionPointRegistry,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // 1. Error if already traveling
        let travel_status = altriuxhero::get_travel_status(hero);
        assert!(option::is_none(travel_status), E_ALREADY_TRAVELING);

        // 2. Get current coordinates
        let (h_q, h_r, h_q_n, h_r_n, s_q, s_r, s_q_n, s_r_n) = altriuxhero::get_hero_coords(hero);
        
        // 3. Calculate distance
        let dist = altriuxlocation::calculate_combined_distance_signed(
            h_q, h_r, h_q_n, h_r_n, s_q, s_r, s_q_n, s_r_n,
            t_hq, t_hr, t_hq_neg, t_hr_neg, t_sq, t_sr, t_sq_neg, t_sr_neg
        );

        // 4. Calculate cost and time
        let au_cost = if (dist == 0) 1 else dist * AU_COST_PER_HEX;
        let travel_time_ms = dist * MS_PER_HEX;
        let now = clock::timestamp_ms(clock);
        let arrival_time = now + travel_time_ms;

        // 5. Consume AU
        let hero_id = object::id(hero);
        altriuxactionpoints::consume_au(au_reg, hero_id, au_cost, b"travel", clock, ctx);

        // 6. Set Travel Status
        let status = altriuxhero::new_travel_status(
            altriuxhero::get_current_tile(hero),
            target_tile_id,
            now,
            arrival_time,
            t_hq, t_hr, t_hq_neg, t_hr_neg,
            t_sq, t_sr, t_sq_neg, t_sr_neg
        );
        altriuxhero::start_hero_travel(hero, status, ctx);
    }

    public fun complete_travel(
        hero: &mut Hero,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let travel_status_opt = altriuxhero::get_travel_status(hero);
        assert!(option::is_some(travel_status_opt), E_NOT_TRAVELING);
        
        let status = option::borrow(travel_status_opt);
        let (_, dest_tile, _, arrival_time) = altriuxhero::get_travel_details(status);
        
        let now = clock::timestamp_ms(clock);
        assert!(now >= arrival_time, E_NOT_ARRIVED);

        // Get locked destination coordinates
        let (t_hq, t_hr, t_hq_n, t_hr_n, t_sq, t_sr, t_sq_n, t_sr_n) = altriuxhero::get_travel_dest_coords(status);

        // Update Position
        altriuxhero::update_hero_position(hero, dest_tile, ctx);
        altriuxhero::update_hero_coords(hero, t_hq, t_hr, t_hq_n, t_hr_n, t_sq, t_sr, t_sq_n, t_sr_n, ctx);
        
        // Clear Status
        altriuxhero::clear_travel_status(hero, ctx);
    }

    public fun cancel_travel(
        hero: &mut Hero,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let travel_status_opt = altriuxhero::get_travel_status(hero);
        assert!(option::is_some(travel_status_opt), E_NOT_TRAVELING);
        
        let status = option::borrow(travel_status_opt);
        let (_, _, start_time, arrival_time) = altriuxhero::get_travel_details(status);
        let (t_hq, t_hr, t_hq_n, t_hr_n, t_sq, t_sr, t_sq_n, t_sr_n) = altriuxhero::get_travel_dest_coords(status);
        
        let now = clock::timestamp_ms(clock);

        // Calculate intermediate position
        let (h_q, h_r, h_q_n, h_r_n, s_q, s_r, s_q_n, s_r_n) = altriuxhero::get_hero_coords(hero);
        
        let (i_hq, i_hr, i_hqn, i_hrn, i_sq, i_sr, i_sqn, i_srn) = altriuxlocation::get_intermediate_position(
            h_q, h_r, h_q_n, h_r_n, s_q, s_r, s_q_n, s_r_n,
            t_hq, t_hr, t_hq_n, t_hr_n, t_sq, t_sr, t_sq_n, t_sr_n,
            start_time, arrival_time, now
        );

        // Update hero to intermediate position
        altriuxhero::update_hero_position(hero, 0, ctx); // Reset tile ID
        altriuxhero::update_hero_coords(hero, i_hq, i_hr, i_hqn, i_hrn, i_sq, i_sr, i_sqn, i_srn, ctx);

        altriuxhero::clear_travel_status(hero, ctx);
    }
}
