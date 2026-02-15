/**
 * River System Types for Altriux Tribal
 * Defines the complete structure for river generation and management
 */

import type { HexCoordinates } from './types';

/**
 * Direction of river flow from source to mouth
 */
export type RiverFlowDirection = 'downstream' | 'upstream';

/**
 * River segment represents one hexagon in a river's path
 */
export interface RiverSegment {
  coordinates: HexCoordinates;
  elevation: number; // Used for flow direction calculation
  flowDirection: RiverFlowDirection;
  distanceFromSource: number; // In hexagons
  distanceToMouth: number; // In hexagons
}

/**
 * Edge ID for river crossing between two hexagons
 * Format: "q1,r1:q2,r2" (always sorted to ensure uniqueness)
 */
export type RiverEdgeId = string;

/**
 * River edge crossing information
 * When a river crosses the border between two duchy hexagons,
 * both hexagons will have special SubLand hexagons along that edge
 */
export interface RiverEdge {
  edgeId: RiverEdgeId;
  hex1: HexCoordinates; // First hexagon
  hex2: HexCoordinates; // Second hexagon (neighbor)
  direction: number; // 0-5 representing which edge (flat-top hexagon)
  riverId: string;
}

/**
 * Complete river definition
 */
export interface River {
  id: string;
  source: HexCoordinates; // Must be a mountain_range (cordillera) hexagon
  mouth: HexCoordinates; // End point (MUST be coast, NOT ocean)
  segments: RiverSegment[]; // All hexagons in the river path
  edges: RiverEdge[]; // All edges where river crosses hexagon borders
  length: number; // Total length in hexagons (must be >= 15)
  flowDirection: 'downstream'; // Rivers always flow downstream from source
}

/**
 * SubLand river hexagon configuration
 * These are special hexagons in SubLands (1km x 1km) that are split by a river
 */
export interface SubLandRiverHex {
  parentQ: number; // Parent duchy hexagon q
  parentR: number; // Parent duchy hexagon r
  subQ: number; // SubLand hexagon q within parent
  subR: number; // SubLand hexagon r within parent
  isRiverBank: boolean; // Is this hexagon split by river?
  riverSide: 'north' | 'south' | 'east' | 'west' | 'northeast' | 'northwest' | null;
  // Half of the hexagon is river, half is river bank (cuenca)
  allowsRiverBuildings: boolean; // Can build river port, river shipyard, etc.
}

/**
 * River building types that can only be built on river banks
 */
export type RiverBuildingType =
  | 'river_port' // Puerto Fluvial
  | 'river_shipyard' // Astillero Fluvial
  | 'river_dock' // Muelle Fluvial
  | 'fishing_hut' // Cabaña de Pesca
  | 'water_mill'; // Molino de Agua

/**
 * Configuration for river generation
 */
export interface RiverGenerationConfig {
  minLength: number; // Minimum river length (default: 15)
  maxAttempts: number; // Max attempts to generate valid river
  flowToOcean: boolean; // Should rivers flow to ocean?
  allowLakes: boolean; // Can rivers end in lakes (not implemented yet)
}

/**
 * River pathfinding result
 */
export interface RiverPath {
  isValid: boolean;
  path: HexCoordinates[];
  length: number;
  reason?: string; // Reason if invalid
}

/**
 * Helper function to create a unique edge ID from two hexagons
 * Always sorts coordinates to ensure uniqueness regardless of order
 */
export function createRiverEdgeId(hex1: HexCoordinates, hex2: HexCoordinates): RiverEdgeId {
  const key1 = `${hex1.q},${hex1.r}`;
  const key2 = `${hex2.q},${hex2.r}`;
  
  // Sort to ensure uniqueness
  return key1 < key2 ? `${key1}:${key2}` : `${key2}:${key1}`;
}

/**
 * Helper function to parse edge ID back to coordinates
 */
export function parseRiverEdgeId(edgeId: RiverEdgeId): { hex1: HexCoordinates; hex2: HexCoordinates } {
  const [key1, key2] = edgeId.split(':');
  if (!key1 || !key2) {
    throw new Error(`Invalid edge ID: ${edgeId}`);
  }
  
  const [q1, r1] = key1.split(',').map(Number);
  const [q2, r2] = key2.split(',').map(Number);
  
  return {
    hex1: { q: q1, r: r1, x: q1, y: r1 },
    hex2: { q: q2, r: r2, x: q2, y: r2 }
  };
}
