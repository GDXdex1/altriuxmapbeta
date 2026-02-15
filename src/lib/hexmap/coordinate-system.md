# Altriux Hexagonal Coordinate System

## Overview
The Altriux world map uses an **axial coordinate system** (also called "offset coordinates") for hexagonal tiles. This is the standard system for hex grids and provides efficient pathfinding and distance calculations.

## Coordinate System Details

### Axial Coordinates
Each hex tile is identified by two coordinates:
- **q** (column): Horizontal position along the main axis
- **r** (row): Vertical position along the secondary axis

### Cartesian Display Coordinates
For rendering, each tile also has display coordinates:
- **x**: Horizontal pixel position
- **y**: Vertical pixel position

These are calculated from (q, r) using hex geometry.

## World Center

The map is centered at:
- **Coordinates**: `(0, 0)`
- **Location**: Near the equator between the two main continents
- **Latitude**: 0° (equator)

## Map Dimensions

- **Width**: 420 hexes (east-west)
- **Height**: 220 hexes (north-south)
- **Range q**: -210 to +210
- **Range r**: -110 to +110
- **Hex Size**: 100 km per hex

## Continent Locations

### Drantium (Western Continent)
- **Center**: `(-70, -17)`
- **Type**: Jungle-based (analogous to Americas)
- **Dimensions**: 70 hexes wide × 70 hexes tall
- **Approximate Bounds**:
  - q: -105 to -35
  - r: -52 to +18

### Brontium (Eastern Continent)
- **Center**: `(70, 0)`
- **Type**: Forest-based (analogous to Europe/Asia)
- **Dimensions**: 70 hexes wide × 70 hexes tall
- **Approximate Bounds**:
  - q: +35 to +105
  - r: -35 to +35

### Ocean Separation
- **Central Ocean Width**: ~140 hexes (14,000 km)
- **Meridian**: q = 0 (divides Drantium west from Brontium east)

## Biome Distribution by Coordinates

### Polar Regions
**North Pole** (r < -88):
- Ice terrain
- Latitude: 80°+ North

**South Pole** (r > +88):
- Ice terrain
- Latitude: 80°+ South

### Tundra Zones
**Northern Tundra** (r: -76 to -88):
- Tundra terrain with boreal forests
- Latitude: 60°-80° North

**Southern Tundra** (r: +76 to +88):
- Tundra terrain with boreal forests
- Latitude: 60°-80° South

### Temperate Zones
**Northern Temperate** (r: -20 to -76):
- Hills, meadows, forests (Brontium)
- Latitude: 20°-60° North

**Southern Temperate** (r: +20 to +76):
- Hills, meadows, forests
- Latitude: 20°-60° South

### Tropical/Equatorial Zone (r: -20 to +20)
- Jungle features (Drantium)
- Desert terrain
- Latitude: 20°N to 20°S

## Special Features by Location

### Forests (Brontium only)
- **Continent**: Brontium (q > 0)
- **Terrain**: Hills
- **Coordinates**: Temperate latitudes in Brontium continent
- **Feature Type**: `'forest'`

### Jungles (Drantium only)
- **Continent**: Drantium (q < 0)
- **Terrain**: Hills
- **Coordinates**: Tropical/equatorial latitudes in Drantium continent
- **Feature Type**: `'jungle'`

### Oases
- **Terrain**: Desert only
- **Probability**: 8% of desert tiles
- **Location**: Both continents in dry regions
- **Feature Type**: `'oasis'`

### Mountains
- **Primary**: Mountain range terrain (`'mountain_range'`)
- **Secondary**: Mountain features on tundra, desert, ice
- **C-shaped Ranges**: Enclosing deserts in both continents

## Navigation Examples

### Distance Calculation
To calculate distance between two hexes (q1,r1) and (q2,r2):
```
distance = (abs(q1 - q2) + abs(q1 + r1 - q2 - r2) + abs(r1 - r2)) / 2
```

### Neighbors
A hex at (q, r) has 6 neighbors:
- (q+1, r) - East
- (q-1, r) - West  
- (q, r+1) - Southeast
- (q, r-1) - Northwest
- (q+1, r-1) - Northeast
- (q-1, r+1) - Southwest

## Latitude Calculation

Latitude is calculated from the r coordinate:
```
latitude = (r / mapHeight) ×180
```
- r = -110 → 90°S (South Pole)
- r = 0 → 0° (Equator)
- r = +110 → 90°N (North Pole)

## Hemisphere Assignment

- **Northern** (r < -15): North of 15°S
- **Equatorial** (-15 ≤ r ≤ +15): Between 15°S and 15°N
- **Southern** (r > +15): South of 15°N

## Season System

Seasons are opposite between hemispheres:
- When Northern = Summer, Southern = Winter
- When Northern = Winter, Southern = Summer
- Equatorial zone has minimal seasonal variation

## Coordinate Integration with Smart Contracts

See [Smart Contract Integration Guide](./smart-contract-integration.md) for details on using these coordinates in Move contracts for:
- Location-based gameplay
- Movement validation
- Resource distribution
- Biome checks
