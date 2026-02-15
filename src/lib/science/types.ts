export type TechnologyCategory = 
  | 'trades'
  | 'basic_sciences'
  | 'literature'
  | 'geography'
  | 'history'
  | 'mathematics'
  | 'physics'
  | 'chemistry'
  | 'religion'
  | 'philosophy';

export type ReligionType = 
  | 'imlax'      // Analogous to Islam
  | 'cris'       // Analogous to Christianity
  | 'shix'       // Hindu Polytheism
  | 'yax'        // Analogous to Judaism
  | 'drox'       // Pre-Hispanic Indigenous Polytheism
  | 'sox';       // Analogous to Buddhism

export interface Technology {
  id: string;
  name: string;
  description: string;
  category: TechnologyCategory;
  requiredTech: string[]; // Prerequisites
  leadsTo: string[]; // Technologies this unlocks
  researchCost: number; // Knowledge points needed
  icon: string;
  unlocks?: string[]; // What this tech unlocks (trades, buildings, etc.)
  religion?: ReligionType; // Only for religion techs
}

export interface PlayerProgress {
  wallet: string; // Sui wallet address
  researchedTechs: string[]; // Array of technology IDs
  currentResearch: string | null; // Currently researching tech ID
  researchProgress: number; // Progress on current research (0-100)
  knowledgePoints: number; // Accumulated knowledge points
  knowledgePerTick: number; // Knowledge gained per game tick
}

export interface Trade {
  id: string;
  name: string;
  description: string;
  requiredTech: string;
  benefits: string[];
}

export interface Religion {
  id: ReligionType;
  name: string;
  description: string;
  beliefs: string[];
  bonuses: string[];
}
