#[test_only]
module altriux::test_au_integration {
    use sui::test_scenario::{Self};
    use sui::clock::{Self};
    use altriux::altriuxactionpoints::{Self, ActionPointRegistry};

    const ADMIN: address = @0xAD;

    #[test]
    fun test_au_registry_flow() {
        let scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;
        let clock = clock::create_for_testing(test_scenario::ctx(scenario));
        
        // 1. Init AU Registry
        altriuxactionpoints::init_au_registry(test_scenario::ctx(scenario));
        
        test_scenario::next_tx(scenario, ADMIN);
        
        // 2. Verify Registry Exists
        let reg = test_scenario::take_shared<ActionPointRegistry>(scenario);
        
        // 3. Create a mock worker pool (if possible without Worker object)
        // create_worker_pool requires worker_id: ID. We can fake it.
        let worker_id = sui::object::id_from_address(@0xCAFE);
        
        altriuxactionpoints::create_worker_pool(&mut reg, worker_id, &clock, test_scenario::ctx(scenario));
        
        // 4. Test Accumulation Logic
        // initial AU should be 0.
        // Advance clock 1 day (standard game day = 3 hours real = 10800000 ms)
        clock::set_for_testing(&mut clock, 10800000);
        
        altriuxactionpoints::accumulate_au(&mut reg, worker_id, &clock, test_scenario::ctx(scenario));
        
        // Check balance (need a getter in altriuxactionpoints? or view reg)
        // get_pool_stats returns (available, total_earned, total_consumed)
        let (avail, earned, consumed) = altriuxactionpoints::get_pool_stats(&reg, worker_id);
        
        // 1 day = 2 AU.
        // wait, AU_PER_WORKER_DAY = 2.
        assert!(avail == 2, 101);
        assert!(earned == 2, 102);
        
        // 5. Cleanup
        test_scenario::return_shared(reg);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }
}
