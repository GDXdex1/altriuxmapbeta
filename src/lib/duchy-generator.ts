import type { DuchyInfo } from '@/types/game';

/**
 * Generate duchy name based on coordinates
 * Format: "Duchy #[id]" where id is derived from q,r coordinates
 */
export function generateDuchyName(q: number, r: number): string {
  // Create unique ID from coordinates
  // Offset by 200 to avoid negative numbers
  const id = (q + 200) * 1000 + (r + 100);
  return `Duchy #${id}`;
}

/**
 * Generate duchy info from hex coordinates
 */
export function generateDuchyInfo(q: number, r: number): DuchyInfo {
  const id = `duchy-${q}-${r}`;
  const name = generateDuchyName(q, r);
  
  return {
    id,
    name,
    q,
    r,
    buildings: [] // Will be populated as players build
  };
}

/**
 * Calculate distance between two duchies (hex grid distance)
 */
export function calculateDuchyDistance(
  fromQ: number,
  fromR: number,
  toQ: number,
  toR: number
): number {
  // Axial distance formula for hexagons
  const dq = toQ - fromQ;
  const dr = toR - fromR;
  
  // Convert to cube coordinates for easier calculation
  const ds = -dq - dr;
  
  return (Math.abs(dq) + Math.abs(dr) + Math.abs(ds)) / 2;
}
