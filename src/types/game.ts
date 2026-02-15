// Game types for Altriux Tribal

export interface PlayerLocation {
  duchyId: string;
  q: number;
  r: number;
  walletAddress: string;
}

export interface TransportItem {
  id: string;
  name: string;
  type: 'ship' | 'horse' | 'camel' | 'cart';
  speed: number; // tiles per day
  icon: string;
  weightCapacity: number; // in Jax
  nftId?: string;
}

export interface TravelCalculation {
  fromDuchy: string;
  toDuchy: string;
  distance: number; // in tiles
  selectedTransport: TransportItem;
  travelTime: number; // in game days
  arrivalDate: Date;
}

export interface DuchyInfo {
  id: string;
  name: string;
  q: number;
  r: number;
  owner?: string; // wallet address
  nftId?: string;
  buildings: BuildingNFT[];
}

export interface BuildingNFT {
  id: string;
  name: string;
  type: string;
  icon: string;
  nftId: string;
  effects: string[];
}

export interface ForumPost {
  id: string;
  author: string;
  authorWallet: string;
  authorTitle?: string; // NFT title
  content: string;
  timestamp: Date;
  likes: number;
  replies: ForumReply[];
}

export interface ForumReply {
  id: string;
  author: string;
  authorWallet: string;
  authorTitle?: string;
  content: string;
  timestamp: Date;
}

export interface ForumCategory {
  id: string;
  name: string;
  description: string;
  icon: string;
  postCount: number;
}

export const JAX_TO_KG = 20;
export const GAME_SPEED_MULTIPLIER = 4;

// SubLand Travel System
export interface ActiveTravel {
  id: string;
  origin: { q: number; r: number };
  destination: { q: number; r: number };
  path: Array<{ q: number; r: number }>;
  currentPosition: { q: number; r: number };
  currentHexIndex: number;
  totalTravelTime: number; // in hours
  elapsedTime: number; // in hours
  startTime: Date;
  estimatedArrival: Date;
  biomeType: string;
}
