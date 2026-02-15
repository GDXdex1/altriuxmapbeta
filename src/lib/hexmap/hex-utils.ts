import type { HexCoordinates } from './types';

/**
 * Axial to pixel coordinates conversion for flat-top hexagons
 */
export function axialToPixel(q: number, r: number, size: number): { x: number; y: number } {
  const x = size * (3 / 2 * q);
  const y = size * (Math.sqrt(3) / 2 * q + Math.sqrt(3) * r);
  return { x, y };
}

/**
 * Pixel to axial coordinates conversion for flat-top hexagons
 */
export function pixelToAxial(x: number, y: number, size: number): HexCoordinates {
  const q = (2 / 3 * x) / size;
  const r = (-1 / 3 * x + Math.sqrt(3) / 3 * y) / size;
  const rounded = axialRound(q, r);
  
  // Add cartesian-like coordinates for display
  return {
    ...rounded,
    x: rounded.q,
    y: rounded.r
  };
}

/**
 * Round fractional axial coordinates to nearest hex
 */
export function axialRound(q: number, r: number): HexCoordinates {
  const s = -q - r;
  
  let rq = Math.round(q);
  let rr = Math.round(r);
  let rs = Math.round(s);
  
  const qDiff = Math.abs(rq - q);
  const rDiff = Math.abs(rr - r);
  const sDiff = Math.abs(rs - s);
  
  if (qDiff > rDiff && qDiff > sDiff) {
    rq = -rr - rs;
  } else if (rDiff > sDiff) {
    rr = -rq - rs;
  }
  
  return { 
    q: rq, 
    r: rr,
    x: rq, // Horizontal display coordinate
    y: rr  // Vertical display coordinate
  };
}

/**
 * Create full hex coordinates with cartesian display coordinates
 */
export function createHexCoordinates(q: number, r: number): HexCoordinates {
  return {
    q,
    r,
    x: q, // X axis = horizontal (West to East)
    y: r  // Y axis = vertical (North to South)
  };
}

/**
 * Calculate distance between two hexes
 */
export function hexDistance(a: HexCoordinates, b: HexCoordinates): number {
  return (Math.abs(a.q - b.q) + Math.abs(a.q + a.r - b.q - b.r) + Math.abs(a.r - b.r)) / 2;
}

/**
 * Get all neighbors of a hex
 */
export function getNeighbors(hex: HexCoordinates): HexCoordinates[] {
  const directions = [
    { q: 1, r: 0 }, { q: 1, r: -1 }, { q: 0, r: -1 },
    { q: -1, r: 0 }, { q: -1, r: 1 }, { q: 0, r: 1 }
  ];
  
  return directions.map(dir => createHexCoordinates(
    hex.q + dir.q,
    hex.r + dir.r
  ));
}

/**
 * Check if coordinates are within map bounds
 */
export function isInBounds(q: number, r: number, width: number, height: number): boolean {
  // Convert to offset coordinates for bounds checking
  const col = q;
  const row = r + Math.floor(q / 2);
  
  return col >= -width / 2 && col < width / 2 && row >= -height / 2 && row < height / 2;
}

/**
 * Generate hex key for map storage
 */
export function getHexKey(q: number, r: number): string {
  return `${q},${r}`;
}

/**
 * Get terrain color for rendering
 */
export function getTerrainColor(terrain: string): string {
  const colors: Record<string, string> = {
    ocean: '#1e40af',
    coast: '#3b82f6',
    ice: '#e0f2fe',
    plains: '#84cc16',
    jungle: '#166534',
    forest: '#15803d',
    mountain: '#78716c',
    tundra: '#cbd5e1',
    desert: '#fbbf24'
  };
  return colors[terrain] || '#6b7280';
}

/**
 * Parse hex key back to coordinates
 */
export function parseHexKey(key: string): HexCoordinates {
  const [q, r] = key.split(',').map(Number);
  return createHexCoordinates(q, r);
}

/**
 * Calculate latitude from r coordinate
 * Returns latitude in degrees (-90 to +90)
 */
export function calculateLatitude(r: number, mapHeight: number): number {
  return (r / mapHeight) * 180;
}

/**
 * Determine hemisphere from latitude
 */
export function getHemisphere(latitude: number): 'northern' | 'southern' | 'equatorial' {
  if (Math.abs(latitude) <= 10) return 'equatorial';
  return latitude > 0 ? 'northern' : 'southern';
}

/**
 * Wrap q coordinate for east-west continuity (horizontal wrap-around)
 * The map is continuous horizontally but limited vertically (north-south)
 */
export function wrapCoordinates(q: number, mapWidth: number): number {
  const halfWidth = mapWidth / 2;
  // Wrap q coordinate to range [-halfWidth, halfWidth)
  let wrappedQ = q % mapWidth;
  if (wrappedQ >= halfWidth) wrappedQ -= mapWidth;
  if (wrappedQ < -halfWidth) wrappedQ += mapWidth;
  return wrappedQ;
}
