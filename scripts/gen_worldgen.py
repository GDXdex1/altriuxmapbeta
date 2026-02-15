#!/usr/bin/env python3
"""Generate altriuxworldgen.move with all city/city-state coordinates and mine placements."""

# Map: q in [-210,+209], r in [-110,+109]
# SC offset: q_off = q+210, r_off = r+110
# Drantium center: q=-70, r=-17 | Brontium center: q=70, r=0

# City-state names (60)
CS_NAMES = [
    "Draxpolis","Draxium","Draxburg","Draxheim","Draxford","Draxmouth","Draxia","Draxville","Draxton","Draxgrad",
    "Bronpolis","Bronium","Bronburg","Bronheim","Bronford","Bronmouth","Bronia","Bronville","Bronton","Brongrad",
    "Noixpolis","Noixium","Noixburg","Noixheim","Noixford","Noixmouth","Noixia","Noixville","Noixton","Noixgrad",
    "Soixpolis","Soixium","Soixburg","Soixheim","Soixford","Soixmouth","Soixia","Soixville","Soixton","Soixgrad",
    "Altriuxia","Cascadia","Nexuria","Tribalia","Galinor","Vexmont","Luxoria","Keldara","Mythros","Zarenthia",
    "Orixpolis","Velantia","Drakonium","Solheim","Lunaris","Aethon","Pyralis","Thalassia","Verdantum","Glacium",
]

# City-state coords: spread across both continents, varied biomes
# 30 in Drantium, 30 in Brontium
CS_COORDS = [
    # Drantium city-states (q, r, continent_id)
    (-90,-30,1),(-85,-20,1),(-80,-10,1),(-75,0,1),(-70,-25,1),
    (-65,-15,1),(-60,-5,1),(-55,5,1),(-95,-10,1),(-100,-20,1),
    (-50,-25,1),(-45,-15,1),(-105,0,1),(-110,-10,1),(-85,10,1),
    (-75,15,1),(-65,10,1),(-55,-20,1),(-90,5,1),(-80,-35,1),
    (-100,-35,1),(-70,-40,1),(-60,-30,1),(-50,-10,1),(-95,10,1),
    (-110,5,1),(-85,-40,1),(-75,-45,1),(-65,-35,1),(-55,15,1),
    # Brontium city-states
    (50,-10,2),(55,0,2),(60,10,2),(65,-5,2),(70,15,2),
    (75,5,2),(80,-10,2),(85,0,2),(90,10,2),(95,-5,2),
    (100,5,2),(105,-10,2),(45,5,2),(50,15,2),(55,-20,2),
    (60,-15,2),(65,20,2),(70,-20,2),(75,-15,2),(80,15,2),
    (85,20,2),(90,-15,2),(95,15,2),(100,-20,2),(105,10,2),
    (45,-15,2),(50,-25,2),(55,20,2),(60,25,2),(65,-25,2),
]

def gen_cities_by_biome():
    """Generate 50 cities per biome, 6 biomes = 300 cities."""
    cities = {}

    # 1. TUNDRA (50): North pole r:[82,97], South pole r:[-97,-82]
    tundra = []
    for i in range(25):
        q = -100 + i * 8
        r = 82 + (i % 4) * 4
        tundra.append((q, r, 1 if q < 0 else 2))
    for i in range(25):
        q = -100 + i * 8
        r = -(82 + (i % 4) * 4)
        tundra.append((q, r, 1 if q < 0 else 2))
    cities["tundra"] = tundra

    # 2. PLAINS (50): Interior lowlands
    plains = []
    # 25 in Drantium
    for i in range(25):
        q = -100 + (i % 5) * 8
        r = -30 + (i // 5) * 10
        plains.append((q, r, 1))
    # 25 in Brontium
    for i in range(25):
        q = 45 + (i % 5) * 8
        r = -30 + (i // 5) * 10
        plains.append((q, r, 2))
    cities["plains"] = plains

    # 3. MEADOW (50): Central fertile areas
    meadow = []
    for i in range(25):
        q = -90 + (i % 5) * 7
        r = -18 + (i // 5) * 7
        meadow.append((q, r, 1))
    for i in range(25):
        q = 50 + (i % 5) * 7
        r = -18 + (i // 5) * 7
        meadow.append((q, r, 2))
    cities["meadow"] = meadow

    # 4. CORDILLERA (50): Along mountain arcs
    cordillera = []
    # Drantium C-arc (west side of desert)
    for i in range(25):
        angle_step = 3.14159 / 25 * i
        import math
        cx, cy = -50, 10
        rad = 18
        q = int(cx - rad + math.cos(angle_step) * 3)
        r = int(cy - 15 + i * 1.2)
        q = max(-130, min(130, q))
        r = max(-100, min(100, r))
        cordillera.append((q, r, 1))
    # Brontium C-arc
    for i in range(25):
        cx, cy = 50, 15
        q = int(cx + 15 - (i % 5) * 3)
        r = int(cy - 12 + (i // 5) * 5)
        cordillera.append((q, r, 2))
    cities["cordillera"] = cordillera

    # 5. DESERT+OASIS (50): Near oases in desert zones
    desert = []
    # Drantium desert: q:[-50,-30], r:[5,25]
    for i in range(25):
        q = -50 + (i % 5) * 4
        r = 5 + (i // 5) * 4
        desert.append((q, r, 1))
    # Brontium desert: q:[40,60], r:[10,25]
    for i in range(25):
        q = 40 + (i % 5) * 4
        r = 10 + (i // 5) * 3
        desert.append((q, r, 2))
    cities["desert"] = desert

    # 6. HILLS (50): Foothills
    hills = []
    for i in range(25):
        q = -95 + (i % 5) * 6
        r = -45 + (i // 5) * 8
        hills.append((q, r, 1))
    for i in range(25):
        q = 40 + (i % 5) * 6
        r = -30 + (i // 5) * 8
        hills.append((q, r, 2))
    cities["hills"] = hills

    return cities

def gen_city_names(biome, count, start_idx):
    prefixes = {
        "tundra": ["Frost","Ice","Snow","Glac","Nord","Polar","Cryo","Hiel","Niev","Bor"],
        "plains": ["Sol","Llano","Camp","Prad","Dorad","Trigo","Verd","Sab","Aur","Llan"],
        "meadow": ["Flor","Prim","Bloom","Herb","Petal","Rosal","Jard","Vega","Prat","Sem"],
        "cordillera": ["Pico","Cima","Roca","Mont","Crest","Cumbre","Pedr","Alp","Sierr","Cerr"],
        "desert": ["Aren","Oasis","Dunas","Solt","Miraj","Khar","Sahel","Eremo","Seco","Calid"],
        "hills": ["Colin","Loma","Cerro","Alto","Cuesta","Ladera","Ondul","Mojon","Otero","Pend"],
    }
    suffixes = ["ia","um","polis","ton","burg","ville","grad","heim","ford","haven"]
    names = []
    pref = prefixes.get(biome, ["City"])
    for i in range(count):
        name = f"{pref[i % len(pref)]}{suffixes[(start_idx + i) % len(suffixes)]}"
        names.append(name)
    return names

def generate_move_code():
    cities = gen_cities_by_biome()
    
    lines = []
    lines.append("module altriux::altriuxworldgen {")
    lines.append("    use altriux::altriuxpopulation::{Self, PopulationRegistry};")
    lines.append("    use altriux::altriuxmining::{Self, MiningRegistry};")
    lines.append("    use altriux::altriuxlocation;")
    lines.append("    use sui::clock::Clock;")
    lines.append("    use sui::tx_context::TxContext;")
    lines.append("")
    lines.append("    const ADMIN: address = @0x554a2392980b0c3e4111c9a0e8897e632d41847d04cbd41f9e081e49ba2eb04a;")
    lines.append("")
    lines.append("    // === GENESIS: Spawn all cities, city-states, and mines ===")
    lines.append("    public fun genesis_spawn_all_cities(")
    lines.append("        pop_reg: &mut PopulationRegistry,")
    lines.append("        mining_reg: &mut MiningRegistry,")
    lines.append("        clock: &Clock,")
    lines.append("        ctx: &mut TxContext")
    lines.append("    ) {")
    lines.append("        spawn_tundra_cities(pop_reg, mining_reg, clock, ctx);")
    lines.append("        spawn_plains_cities(pop_reg, mining_reg, clock, ctx);")
    lines.append("        spawn_meadow_cities(pop_reg, mining_reg, clock, ctx);")
    lines.append("        spawn_cordillera_cities(pop_reg, mining_reg, clock, ctx);")
    lines.append("        spawn_desert_cities(pop_reg, mining_reg, clock, ctx);")
    lines.append("        spawn_hills_cities(pop_reg, mining_reg, clock, ctx);")
    lines.append("        spawn_city_states(pop_reg, mining_reg, clock, ctx);")
    lines.append("        distribute_resource_mines(mining_reg, clock, ctx);")
    lines.append("    }")
    lines.append("")

    # Helper: spawn city + adjacent iron mine
    lines.append("    fun sc(pop: &mut PopulationRegistry, m: &mut MiningRegistry, q: u64, r: u64, n: vector<u8>, ct: u8, ctype: u8, clock: &Clock, ctx: &mut TxContext) {")
    lines.append("        altriuxpopulation::spawn_city_with_type(pop, q, r, n, @0x0, ct, ctype, ctx);")
    lines.append("        let mq = if (q < 419) { q + 1 } else { q - 1 };")
    lines.append("        altriuxmining::spawn_mine(m, mq, r, altriuxmining::id_mine_type_hierro(), altriuxmining::reserve_iron(), @0x0, clock, ctx);")
    lines.append("    }")
    lines.append("")

    # Generate each biome function
    idx = 0
    for biome, coords in cities.items():
        names = gen_city_names(biome, len(coords), idx)
        fn_name = f"spawn_{biome}_cities"
        lines.append(f"    fun {fn_name}(pop: &mut PopulationRegistry, m: &mut MiningRegistry, clock: &Clock, ctx: &mut TxContext) {{")
        for i, (q, r, cont) in enumerate(coords):
            # Convert to offset encoding
            oq = q + 210
            or_ = r + 110
            oq = max(0, min(419, oq))
            or_ = max(0, min(219, or_))
            ct = "altriuxpopulation::id_city()"
            lines.append(f'        sc(pop, m, {oq}, {or_}, b"{names[i]}", {ct}, {cont}, clock, ctx);')
        lines.append("    }")
        lines.append("")
        idx += len(coords)

    # City-states function
    lines.append("    fun spawn_city_states(pop: &mut PopulationRegistry, m: &mut MiningRegistry, clock: &Clock, ctx: &mut TxContext) {")
    for i, (q, r, cont) in enumerate(CS_COORDS):
        oq = q + 210
        or_ = r + 110
        oq = max(0, min(419, oq))
        or_ = max(0, min(219, or_))
        name = CS_NAMES[i]
        ct = "altriuxpopulation::id_city_state()"
        lines.append(f'        sc(pop, m, {oq}, {or_}, b"{name}", {ct}, {cont}, clock, ctx);')
    lines.append("    }")
    lines.append("")

    # Resource mines distribution
    lines.append("    fun distribute_resource_mines(m: &mut MiningRegistry, clock: &Clock, ctx: &mut TxContext) {")
    lines.append("        // Gold mines (30): Desert mountains near oases")
    
    # Gold mines in desert zones
    gold_coords = []
    for i in range(15):
        q = -48 + i * 2
        r = 8 + (i % 3) * 3
        gold_coords.append((q + 210, r + 110, 1))
    for i in range(15):
        q = 42 + i * 2
        r = 12 + (i % 3) * 3
        gold_coords.append((q + 210, r + 110, 2))
    for oq, or_, _ in gold_coords:
        lines.append(f"        altriuxmining::spawn_mine(m, {oq}, {or_}, altriuxmining::id_mine_type_oro(), altriuxmining::reserve_gold() / 30, @0x0, clock, ctx);")
    
    lines.append("")
    lines.append("        // Galena mines (100): Cordillera + desert mountains")
    # Galena along mountain arcs
    for i in range(50):
        q = -65 + i
        r = -5 + (i % 10)
        oq = max(0, min(419, q + 210))
        or_ = max(0, min(219, r + 110))
        lines.append(f"        altriuxmining::spawn_mine(m, {oq}, {or_}, altriuxmining::id_mine_type_galena(), altriuxmining::reserve_galena() / 100, @0x0, clock, ctx);")
    for i in range(50):
        q = 35 + i
        r = 0 + (i % 10)
        oq = max(0, min(419, q + 210))
        or_ = max(0, min(219, r + 110))
        lines.append(f"        altriuxmining::spawn_mine(m, {oq}, {or_}, altriuxmining::id_mine_type_galena(), altriuxmining::reserve_galena() / 100, @0x0, clock, ctx);")
    
    lines.append("")
    lines.append("        // Nickelite mines (30): Tundra zones")
    for i in range(15):
        q = -90 + i * 12
        r = 85 + (i % 3) * 2
        oq = max(0, min(419, q + 210))
        or_ = max(0, min(219, r + 110))
        lines.append(f"        altriuxmining::spawn_mine(m, {oq}, {or_}, altriuxmining::id_mine_type_niquelita(), altriuxmining::reserve_nickelite(), @0x0, clock, ctx);")
    for i in range(15):
        q = -90 + i * 12
        r = -(85 + (i % 3) * 2)
        oq = max(0, min(419, q + 210))
        or_ = max(0, min(219, r + 110))
        lines.append(f"        altriuxmining::spawn_mine(m, {oq}, {or_}, altriuxmining::id_mine_type_niquelita(), altriuxmining::reserve_nickelite(), @0x0, clock, ctx);")

    lines.append("")
    lines.append("        // Copper mines (200): Hills + cordillera")
    for i in range(100):
        q = -100 + i * 2
        r = -40 + (i % 20)
        oq = max(0, min(419, q + 210))
        or_ = max(0, min(219, r + 110))
        lines.append(f"        altriuxmining::spawn_mine(m, {oq}, {or_}, altriuxmining::id_mine_type_cobre(), altriuxmining::reserve_copper(), @0x0, clock, ctx);")
    for i in range(100):
        q = 30 + i * 1
        r = -20 + (i % 20)
        oq = max(0, min(419, q + 210))
        or_ = max(0, min(219, r + 110))
        lines.append(f"        altriuxmining::spawn_mine(m, {oq}, {or_}, altriuxmining::id_mine_type_cobre(), altriuxmining::reserve_copper(), @0x0, clock, ctx);")

    lines.append("")
    lines.append("        // Tin mines (50): River systems, forest/jungle")
    for i in range(25):
        q = -85 + i * 3
        r = -25 + i
        oq = max(0, min(419, q + 210))
        or_ = max(0, min(219, r + 110))
        lines.append(f"        altriuxmining::spawn_mine(m, {oq}, {or_}, altriuxmining::id_mine_type_estano(), altriuxmining::reserve_tin(), @0x0, clock, ctx);")
    for i in range(25):
        q = 45 + i * 3
        r = -10 + i
        oq = max(0, min(419, q + 210))
        or_ = max(0, min(219, r + 110))
        lines.append(f"        altriuxmining::spawn_mine(m, {oq}, {or_}, altriuxmining::id_mine_type_estano(), altriuxmining::reserve_tin(), @0x0, clock, ctx);")

    lines.append("    }")
    lines.append("}")
    lines.append("")
    
    return "\n".join(lines)

if __name__ == "__main__":
    code = generate_move_code()
    out = "/home/jhonny/Downloads/altriuxtribalcascade/altriuxscmain/sources/altriuxworldgen.move"
    with open(out, "w") as f:
        f.write(code)
    print(f"Generated {out} ({len(code)} bytes, {code.count(chr(10))} lines)")
