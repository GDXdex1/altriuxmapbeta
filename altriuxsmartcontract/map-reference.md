# Altriux Map Reference Guide

## Quick Reference

### World Center
- **Coordinates**: (0, 0)
- **Latitude**: 0° (Equator)
- **Location**: Central ocean between continents

### Map Dimensions
- **Total Size**: 420 × 220 hexes
- **Playable Area**: ~92,400 hex tiles
- **Scale**: 100 km per hex
- **Real-world analogue**: Earth-sized

## Continental Boundaries

### Drantium (Western Continent)
```
Center: (-70, -17)
Bounds:
  Min q: -105  |  Max q: -35
  Min r: -52   |  Max r: +18
  
Approximate Width: 70 hexes (7,000 km)
Approximate Height: 70 hexes (7,000 km)
```

**Major Features**:
- C-shaped mountain range enclosing central desert
- Tropical jungle in warm regions (hills terrain)
- East-west river system crossing continent
- Western coastline: q ≈ -105
- Eastern coastline: q ≈ -35

### Brontium (Eastern Continent)
```
Center: (70, 0)
Bounds:
  Min q: +35   |  Max q: +105
  Min r: -35   |  Max r: +35
  
Approximate Width: 70 hexes (7,000 km)
Approximate Height: 70 hexes (7,000 km)
```

**Major Features**:
- C-shaped mountain range
- Temperate forests in mid-latitudes (hills terrain)
- Central mountains (formerly tundra)
- Western coastline: q ≈ +35
- Eastern coastline: q ≈ +105

## Forest & Jungle Boundaries

### Forests (Bosque) - Brontium Only
**Location Criteria**:
- Continent: q > 0 (east of meridian)
- Terrain: Hills only
- Temperature: 5°C to 25°C
- Rainfall: > 50%
- Latitude: Temperate zones (≈30° to 60°)

**Approximate Coordinates**:
- q: +35 to +105  
- r: -60 to -20 (Northern Brontium)
- r: +20 to +60 (Southern Brontium, if applicable)

**Probability**: 70% of eligible hills tiles

### Jungles (Selva) - Drantium Only
**Location Criteria**:
- Continent: q < 0 (west of meridian)
- Terrain: Hills only  
- Temperature: > 20°C
- Rainfall: > 60%
- Latitude: Tropical zones (≈0° to 30°)

**Approximate Coordinates**:
- q: -105 to -35
- r: -30 to +18 (warm latitudes in Drantium)

**Probability**: 70% of eligible hills tiles

## Desert Regions

### Drantium Desert
- **Location**: Central Drantium, enclosed by C-shaped mountains
- **Coordinates**: q ≈ -80 to -60, r ≈ -30 to +10
- **Features**: 8% have oases

### Brontium Desert  
- **Location**: Eastern/central Brontium
- **Coordinates**: q ≈ +60 to +90, r ≈ -20 to +20
- **Size**: Half the size of Drantium's desert
- **Features**: 8% have oases

## Mountain Ranges

### Drantium Mountains
- **Shape**: C-shaped, enclosing desert
- **Western Arm**: q ≈ -100, r ≈ -40 to +10
- **Northern Arm**: q ≈ -90 to -60, r ≈ -45
- **Eastern Arm**: q ≈ -55, r ≈ -40 to +10

### Brontium Mountains
- **Shape**: C-shaped
- **Location**: Central-western Brontium
- **Coordinates**: q ≈ +50 to +80, r ≈ -30 to +30

### Polar Mountains
- **Northern**: r < -80 (mountain features on tundra/ice)
- **Southern**: r > +80 (mountain features on tundra/ice)

## Coastlines

### Ocean (Oceano)
- **Central Ocean**: q ≈ -35 to +35
- **Northern Ocean**: r < -100
- **Southern Ocean**: r > +100

### Coast Terrain
- **Definition**: 1-2 hexes from ocean bordering land
- **Coordinates**: Perimeter of continents
- **Features**: Fish, whales, crabs resources

## Climate Zones by Latitude

### Polar (Ice)
- **North**: r < -88, latitude > 80°N
- **South**: r > +88, latitude > 80°S

### Subpolar (Tundra)
- **North**: r = -76 to -88, latitude 60°-80°N
- **South**: r = +76 to +88, latitude 60°-80°S

### Temperate
- **North**: r = -20 to -76, latitude 20°-60°N
- **South**: r = +20 to +76, latitude 20°-60°S

### Tropical
- **Equatorial**: r = -20 to +20, latitude 20°S to 20°N

## Island Distribution

### Tundra Islands
- **Count**: 40 islands
- **Latitude**: 70° to 88° (both hemispheres)
- **Coordinates**: r < -77 or r > +77

### Jungle Islands
- **Count**: 40 islands
- **Side**: Drantium (q < 0)
- **Latitude**: -20° to +20°
- **Coordinates**: q < -35, r = -20 to +20

### Forest Islands
- **Count**: 40 islands
- **Side**: Brontium (q > 0)
- **Latitude**: 30° to 60°
- **Coordinates**: q > +35, r = -60 to -30 or +30 to +60

### Mountain Islands
- **Count**: 40 islands
- **Distribution**: Global, volcanic
- **Coordinates**: Scattered across all latitudes

## Resource Distribution

### Wood
- Forests (Brontium hills)
- Jungle (Drantium hills)
- Boreal forests (tundra)

### Fish/Marine
- Coast tiles
- Ocean tiles near continents

### Agriculture
- **Wheat**: Temperate meadows (Brontium)
- **Corn**: Tropical/temperate meadows (Drantium)
- **Dates**: Desert oases
- **Flax**: Temperate plains (Brontium)

### Minerals
- **Gold/Silver/Gems**: Mountain ranges
- **Iron/Copper/Tin**: Hills and mountains
- **Stone**: Mountains and hills

## Navigation Helpers

### Finding Equator
- r = 0 is the equator
- All tiles with r between -5 and +5 are near-equatorial

### Finding Center of Drantium
- Navigate to (-70, -17)
- This is the continental heartland

### Finding Center of Brontium
- Navigate to (70, 0)
- This is the continental heartland

### Crossing the Ocean
- Shortest crossing: q = -35 to q = +35 (70 hexes, 7,000 km)
- at equator (r ≈ 0)

## Special Coordinate Notes

### Meridian (q = 0)
- Divides world into Western (Drantium) and Eastern (Brontium) hemispheres
- Runs through central ocean
- All q < 0 is Drantium side
- All q > 0 is Brontium side

### Equator (r = 0)
- Divides world into Northern and Southern hemispheres
- Runs through or near both continents
- Maximum diversity of biomes

### Prime Coordinate (0, 0)
- Exact center of the world
- Ocean hex
- Equator and Meridian intersection
