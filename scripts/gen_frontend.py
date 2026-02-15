#!/usr/bin/env python3
"""Generate world-cities.ts and the master catalog document."""
import json

# Reuse same coordinate logic from gen_worldgen.py
CS_NAMES = [
    "Draxpolis","Draxium","Draxburg","Draxheim","Draxford","Draxmouth","Draxia","Draxville","Draxton","Draxgrad",
    "Bronpolis","Bronium","Bronburg","Bronheim","Bronford","Bronmouth","Bronia","Bronville","Bronton","Brongrad",
    "Noixpolis","Noixium","Noixburg","Noixheim","Noixford","Noixmouth","Noixia","Noixville","Noixton","Noixgrad",
    "Soixpolis","Soixium","Soixburg","Soixheim","Soixford","Soixmouth","Soixia","Soixville","Soixton","Soixgrad",
    "Altriuxia","Cascadia","Nexuria","Tribalia","Galinor","Vexmont","Luxoria","Keldara","Mythros","Zarenthia",
    "Orixpolis","Velantia","Drakonium","Solheim","Lunaris","Aethon","Pyralis","Thalassia","Verdantum","Glacium",
]
CS_COORDS = [
    (-90,-30,1),(-85,-20,1),(-80,-10,1),(-75,0,1),(-70,-25,1),(-65,-15,1),(-60,-5,1),(-55,5,1),(-95,-10,1),(-100,-20,1),
    (-50,-25,1),(-45,-15,1),(-105,0,1),(-110,-10,1),(-85,10,1),(-75,15,1),(-65,10,1),(-55,-20,1),(-90,5,1),(-80,-35,1),
    (-100,-35,1),(-70,-40,1),(-60,-30,1),(-50,-10,1),(-95,10,1),(-110,5,1),(-85,-40,1),(-75,-45,1),(-65,-35,1),(-55,15,1),
    (50,-10,2),(55,0,2),(60,10,2),(65,-5,2),(70,15,2),(75,5,2),(80,-10,2),(85,0,2),(90,10,2),(95,-5,2),
    (100,5,2),(105,-10,2),(45,5,2),(50,15,2),(55,-20,2),(60,-15,2),(65,20,2),(70,-20,2),(75,-15,2),(80,15,2),
    (85,20,2),(90,-15,2),(95,15,2),(100,-20,2),(105,10,2),(45,-15,2),(50,-25,2),(55,20,2),(60,25,2),(65,-25,2),
]

BIOME_PREFIXES = {
    "Tundra": ["Frost","Ice","Snow","Glac","Nord","Polar","Cryo","Hiel","Niev","Bor"],
    "Plains": ["Sol","Llano","Camp","Prad","Dorad","Trigo","Verd","Sab","Aur","Llan"],
    "Meadow": ["Flor","Prim","Bloom","Herb","Petal","Rosal","Jard","Vega","Prat","Sem"],
    "Mountain_range": ["Pico","Cima","Roca","Mont","Crest","Cumbre","Pedr","Alp","Sierr","Cerr"],
    "Desert": ["Aren","Oasis","Dunas","Solt","Miraj","Khar","Sahel","Eremo","Seco","Calid"],
    "Hills": ["Colin","Loma","Cerro","Alto","Cuesta","Ladera","Ondul","Mojon","Otero","Pend"],
}
SUFFIXES = ["ia","um","polis","ton","burg","ville","grad","heim","ford","haven"]

def gen_biome_coords():
    biomes = {}
    # Tundra
    t = []
    for i in range(25):
        t.append((-100+i*8, 82+(i%4)*4, "Noix" if -100+i*8<0 else "Brontium"))
    for i in range(25):
        t.append((-100+i*8, -(82+(i%4)*4), "Soix" if -100+i*8<0 else "Brontium"))
    biomes["Tundra"] = t
    # Plains
    p = []
    for i in range(25):
        p.append((-100+(i%5)*8, -30+(i//5)*10, "Drantium"))
    for i in range(25):
        p.append((45+(i%5)*8, -30+(i//5)*10, "Brontium"))
    biomes["Plains"] = p
    # Meadow
    m = []
    for i in range(25):
        m.append((-90+(i%5)*7, -18+(i//5)*7, "Drantium"))
    for i in range(25):
        m.append((50+(i%5)*7, -18+(i//5)*7, "Brontium"))
    biomes["Meadow"] = m
    # Cordillera
    import math
    c = []
    for i in range(25):
        angle_step = 3.14159 / 25 * i
        q = int(-50 - 18 + math.cos(angle_step) * 3)
        r = int(10 - 15 + i * 1.2)
        c.append((max(-130,min(130,q)), max(-100,min(100,r)), "Drantium"))
    for i in range(25):
        q = int(50 + 15 - (i%5)*3)
        r = int(15 - 12 + (i//5)*5)
        c.append((q, r, "Brontium"))
    biomes["Mountain_range"] = c
    # Desert
    d = []
    for i in range(25):
        d.append((-50+(i%5)*4, 5+(i//5)*4, "Drantium"))
    for i in range(25):
        d.append((40+(i%5)*4, 10+(i//5)*3, "Brontium"))
    biomes["Desert"] = d
    # Hills
    h = []
    for i in range(25):
        h.append((-95+(i%5)*6, -45+(i//5)*8, "Drantium"))
    for i in range(25):
        h.append((40+(i%5)*6, -30+(i//5)*8, "Brontium"))
    biomes["Hills"] = h
    return biomes

def gen_ts():
    biomes = gen_biome_coords()
    entries = []
    idx = 0
    for biome, coords in biomes.items():
        pref = BIOME_PREFIXES[biome]
        for i, (q, r, cont) in enumerate(coords):
            idx += 1
            name = f"{pref[i%len(pref)]}{SUFFIXES[(idx)%len(SUFFIXES)]}"
            entries.append(f"  {{ id: 'city-{idx}', name: '{name}', q: {q}, r: {r}, continent: '{cont}', biome: '{biome}', type: 'city' }}")
    # City-states
    for i, (q, r, cont) in enumerate(CS_COORDS):
        idx += 1
        cont_name = "Drantium" if cont == 1 else "Brontium"
        entries.append(f"  {{ id: 'cs-{i+1}', name: '{CS_NAMES[i]}', q: {q}, r: {r}, continent: '{cont_name}', biome: 'Mixed', type: 'city_state' }}")

    ts = f"""
export interface WorldCity {{
  id: string;
  name: string;
  q: number;
  r: number;
  continent: string;
  biome: string;
  type: 'city' | 'city_state';
}}

export const WORLD_CITIES: WorldCity[] = [
{',\\n'.join(entries)}
];
"""
    return ts

def gen_catalog():
    biomes = gen_biome_coords()
    lines = ["# World Locations & Cities Catalog", "",
             "All 300 claimable cities and 60 city-states with coordinates, biomes, and adjacent mines.", ""]

    idx = 0
    for biome, coords in biomes.items():
        pref = BIOME_PREFIXES[biome]
        lines.append(f"## {biome} Cities (50)")
        lines.append("")
        lines.append("| # | Name | q | r | Continent | Iron Mine |")
        lines.append("|---|---|---|---|---|---|")
        for i, (q, r, cont) in enumerate(coords):
            idx += 1
            name = f"{pref[i%len(pref)]}{SUFFIXES[(idx)%len(SUFFIXES)]}"
            mq = q + 1 if q < 209 else q - 1
            lines.append(f"| {idx} | {name} | {q} | {r} | {cont} | ({mq},{r}) |")
        lines.append("")

    lines.append("## City-States (60)")
    lines.append("")
    lines.append("| # | Name | q | r | Continent | Iron Mine |")
    lines.append("|---|---|---|---|---|---|")
    for i, (q, r, cont) in enumerate(CS_COORDS):
        cont_name = "Drantium" if cont == 1 else "Brontium"
        mq = q + 1 if q < 209 else q - 1
        lines.append(f"| {i+1} | {CS_NAMES[i]} | {q} | {r} | {cont_name} | ({mq},{r}) |")
    lines.append("")
    
    lines.append("## Resource Mines Distribution")
    lines.append("")
    lines.append("| Type | Count | Biome/Location |")
    lines.append("|---|---|---|")
    lines.append("| Iron | 360 | Adjacent to every city and city-state |")
    lines.append("| Gold | 30 | Desert mountains near oases |")
    lines.append("| Galena | 100 | Cordillera + desert mountains |")
    lines.append("| Nickelite | 30 | Tundra zones (15 north, 15 south) |")
    lines.append("| Copper | 200 | Hills + cordillera foothills |")
    lines.append("| Tin | 50 | River systems in forest/jungle |")
    
    return "\n".join(lines)

if __name__ == "__main__":
    ts = gen_ts()
    ts_path = "/home/jhonny/Downloads/altriuxtribalcascade/src/lib/data/world-cities.ts"
    with open(ts_path, "w") as f:
        f.write(ts)
    print(f"Generated {ts_path} ({len(ts)} bytes)")

    cat = gen_catalog()
    cat_path = "/home/jhonny/.gemini/antigravity/brain/9b98cfef-34dd-4ca6-ac9d-7a3e1f4b3550/world_locations_and_cities_document.md"
    with open(cat_path, "w") as f:
        f.write(cat)
    print(f"Generated {cat_path} ({len(cat)} bytes)")
