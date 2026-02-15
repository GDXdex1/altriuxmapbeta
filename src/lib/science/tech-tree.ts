import type { Technology, Trade, Religion } from './types';

// Technology Tree Data
export const TECHNOLOGIES: Technology[] = [
  // === TRADES ===
  {
    id: 'basic_tools',
    name: 'Basic Tools',
    description: 'Learn to craft simple tools from stone and wood',
    category: 'trades',
    requiredTech: [],
    leadsTo: ['blacksmithing', 'carpentry', 'mining'],
    researchCost: 50,
    icon: '🔨',
    unlocks: ['Basic crafting']
  },
  {
    id: 'blacksmithing',
    name: 'Blacksmithing',
    description: 'Master the art of metalworking and weapon crafting',
    category: 'trades',
    requiredTech: ['basic_tools', 'fire_mastery'],
    leadsTo: ['advanced_metalwork'],
    researchCost: 100,
    icon: '⚒️',
    unlocks: ['Blacksmith trade', 'Metal tools', 'Weapons']
  },
  {
    id: 'carpentry',
    name: 'Carpentry',
    description: 'Learn to work with wood and create structures',
    category: 'trades',
    requiredTech: ['basic_tools'],
    leadsTo: ['shipbuilding', 'architecture'],
    researchCost: 80,
    icon: '🪚',
    unlocks: ['Carpenter trade', 'Wooden buildings']
  },
  {
    id: 'shipbuilding',
    name: 'Shipbuilding',
    description: 'Construct vessels to traverse the seas',
    category: 'trades',
    requiredTech: ['carpentry'],
    leadsTo: ['advanced_navigation'],
    researchCost: 150,
    icon: '⛵',
    unlocks: ['Shipwright trade', 'Sea travel', 'Trade ships']
  },
  {
    id: 'textile_work',
    name: 'Textile Work',
    description: 'Create cloth and garments from natural fibers',
    category: 'trades',
    requiredTech: [],
    leadsTo: ['advanced_textiles'],
    researchCost: 60,
    icon: '🧵',
    unlocks: ['Textile worker trade', 'Clothing', 'Banners']
  },
  {
    id: 'mining',
    name: 'Mining',
    description: 'Extract valuable resources from the earth',
    category: 'trades',
    requiredTech: ['basic_tools'],
    leadsTo: ['advanced_mining', 'metallurgy'],
    researchCost: 90,
    icon: '⛏️',
    unlocks: ['Miner trade', 'Ore extraction', 'Quarries']
  },
  {
    id: 'architecture',
    name: 'Architecture',
    description: 'Design and plan complex structures',
    category: 'trades',
    requiredTech: ['carpentry', 'mathematics_basic'],
    leadsTo: ['masonry', 'advanced_architecture'],
    researchCost: 120,
    icon: '🏛️',
    unlocks: ['Architect trade', 'Large buildings', 'City planning']
  },
  {
    id: 'masonry',
    name: 'Masonry',
    description: 'Work with stone to create lasting structures',
    category: 'trades',
    requiredTech: ['architecture', 'mining'],
    leadsTo: ['fortification'],
    researchCost: 100,
    icon: '🧱',
    unlocks: ['Mason trade', 'Stone buildings', 'Walls']
  },
  {
    id: 'medicine',
    name: 'Medicine',
    description: 'Heal the sick and treat injuries',
    category: 'trades',
    requiredTech: ['herbalism', 'biology_basic'],
    leadsTo: ['advanced_medicine'],
    researchCost: 130,
    icon: '⚕️',
    unlocks: ['Physician trade', 'Healing', 'Hospitals']
  },
  {
    id: 'teaching',
    name: 'Teaching',
    description: 'Pass knowledge to the next generation',
    category: 'trades',
    requiredTech: ['writing'],
    leadsTo: ['universities'],
    researchCost: 110,
    icon: '👨‍🏫',
    unlocks: ['Teacher trade', 'Schools', '+1 knowledge/tick']
  },

  // === BASIC SCIENCES ===
  {
    id: 'fire_mastery',
    name: 'Fire Mastery',
    description: 'Control and use fire for various purposes',
    category: 'basic_sciences',
    requiredTech: [],
    leadsTo: ['cooking', 'blacksmithing', 'pottery'],
    researchCost: 40,
    icon: '🔥',
    unlocks: ['Fire usage', 'Light at night']
  },
  {
    id: 'agriculture',
    name: 'Agriculture',
    description: 'Cultivate crops and domesticate animals',
    category: 'basic_sciences',
    requiredTech: [],
    leadsTo: ['advanced_farming', 'irrigation'],
    researchCost: 50,
    icon: '🌾',
    unlocks: ['Farming', 'Food surplus', 'Population growth']
  },
  {
    id: 'herbalism',
    name: 'Herbalism',
    description: 'Understand the properties of plants',
    category: 'basic_sciences',
    requiredTech: ['agriculture'],
    leadsTo: ['medicine', 'alchemy'],
    researchCost: 70,
    icon: '🌿',
    unlocks: ['Herbal remedies', 'Poisons', 'Dyes']
  },
  {
    id: 'astronomy',
    name: 'Astronomy',
    description: 'Study the stars and celestial bodies',
    category: 'basic_sciences',
    requiredTech: ['mathematics_basic'],
    leadsTo: ['navigation', 'calendar'],
    researchCost: 100,
    icon: '🔭',
    unlocks: ['Star charts', 'Time keeping']
  },
  {
    id: 'biology_basic',
    name: 'Biology',
    description: 'Understand living organisms',
    category: 'basic_sciences',
    requiredTech: ['herbalism'],
    leadsTo: ['medicine', 'anatomy'],
    researchCost: 90,
    icon: '🧬',
    unlocks: ['Understanding of life']
  },

  // === MATHEMATICS ===
  {
    id: 'mathematics_basic',
    name: 'Basic Mathematics',
    description: 'Count, add, subtract - the foundation of calculation',
    category: 'mathematics',
    requiredTech: [],
    leadsTo: ['geometry', 'astronomy', 'architecture'],
    researchCost: 60,
    icon: '➕',
    unlocks: ['Counting', 'Trade calculations']
  },
  {
    id: 'geometry',
    name: 'Geometry',
    description: 'Understand shapes, angles, and spatial relationships',
    category: 'mathematics',
    requiredTech: ['mathematics_basic'],
    leadsTo: ['architecture', 'engineering'],
    researchCost: 100,
    icon: '📐',
    unlocks: ['Advanced construction', 'Land surveying']
  },

  // === PHYSICS ===
  {
    id: 'mechanics',
    name: 'Mechanics',
    description: 'Understand forces, motion, and simple machines',
    category: 'physics',
    requiredTech: ['mathematics_basic'],
    leadsTo: ['engineering', 'siege_weapons'],
    researchCost: 110,
    icon: '⚙️',
    unlocks: ['Levers', 'Pulleys', 'Wheels']
  },

  // === CHEMISTRY ===
  {
    id: 'alchemy',
    name: 'Alchemy',
    description: 'Transform materials through chemical processes',
    category: 'chemistry',
    requiredTech: ['herbalism', 'fire_mastery'],
    leadsTo: ['metallurgy', 'explosives'],
    researchCost: 120,
    icon: '🧪',
    unlocks: ['Potions', 'Metal purification']
  },
  {
    id: 'metallurgy',
    name: 'Metallurgy',
    description: 'Extract and refine metals from ore',
    category: 'chemistry',
    requiredTech: ['alchemy', 'mining'],
    leadsTo: ['advanced_metalwork'],
    researchCost: 130,
    icon: '🏭',
    unlocks: ['Better metals', 'Alloys']
  },

  // === LITERATURE ===
  {
    id: 'oral_tradition',
    name: 'Oral Tradition',
    description: 'Pass down stories and knowledge through speech',
    category: 'literature',
    requiredTech: [],
    leadsTo: ['writing'],
    researchCost: 30,
    icon: '🗣️',
    unlocks: ['Cultural identity', 'Story telling']
  },
  {
    id: 'writing',
    name: 'Writing',
    description: 'Record knowledge and communicate across time',
    category: 'literature',
    requiredTech: ['oral_tradition'],
    leadsTo: ['literature_advanced', 'teaching', 'law'],
    researchCost: 80,
    icon: '✍️',
    unlocks: ['Written records', 'Contracts', '+1 knowledge/tick']
  },
  {
    id: 'literature_advanced',
    name: 'Advanced Literature',
    description: 'Create complex works of poetry, drama, and prose',
    category: 'literature',
    requiredTech: ['writing'],
    leadsTo: ['philosophy_ethics'],
    researchCost: 110,
    icon: '📚',
    unlocks: ['Cultural works', '+1 knowledge/tick', 'Cultural influence']
  },

  // === GEOGRAPHY ===
  {
    id: 'cartography',
    name: 'Cartography',
    description: 'Create maps of the known world',
    category: 'geography',
    requiredTech: ['writing', 'mathematics_basic'],
    leadsTo: ['navigation', 'exploration'],
    researchCost: 90,
    icon: '🗺️',
    unlocks: ['Maps', 'Trade routes']
  },
  {
    id: 'navigation',
    name: 'Navigation',
    description: 'Find your way across land and sea',
    category: 'geography',
    requiredTech: ['cartography', 'astronomy'],
    leadsTo: ['advanced_navigation'],
    researchCost: 100,
    icon: '🧭',
    unlocks: ['Long-distance travel', 'Exploration']
  },

  // === HISTORY ===
  {
    id: 'record_keeping',
    name: 'Record Keeping',
    description: 'Document events and maintain archives',
    category: 'history',
    requiredTech: ['writing'],
    leadsTo: ['history_advanced'],
    researchCost: 70,
    icon: '📜',
    unlocks: ['Historical records', 'Genealogy']
  },
  {
    id: 'history_advanced',
    name: 'Historical Analysis',
    description: 'Learn from the past to shape the future',
    category: 'history',
    requiredTech: ['record_keeping'],
    leadsTo: ['philosophy_political'],
    researchCost: 100,
    icon: '📖',
    unlocks: ['Learn from mistakes', '+1 knowledge/tick']
  },

  // === RELIGION ===
  {
    id: 'religion_imlax',
    name: 'Imlax',
    description: 'Follow the path of Imlax - submission to divine will',
    category: 'religion',
    requiredTech: ['oral_tradition'],
    leadsTo: [],
    researchCost: 80,
    icon: '☪️',
    unlocks: ['Imlax temples', 'Religious unity'],
    religion: 'imlax'
  },
  {
    id: 'religion_cris',
    name: 'Cris',
    description: 'Embrace Cris - faith through love and redemption',
    category: 'religion',
    requiredTech: ['oral_tradition'],
    leadsTo: [],
    researchCost: 80,
    icon: '✝️',
    unlocks: ['Cris churches', 'Missionary work'],
    religion: 'cris'
  },
  {
    id: 'religion_shix',
    name: 'Shix',
    description: 'Honor the many gods of Shix polytheism',
    category: 'religion',
    requiredTech: ['oral_tradition'],
    leadsTo: [],
    researchCost: 80,
    icon: '🕉️',
    unlocks: ['Shix temples', 'Divine karma'],
    religion: 'shix'
  },
  {
    id: 'religion_yax',
    name: 'Yax',
    description: 'Follow Yax - the covenant with the chosen',
    category: 'religion',
    requiredTech: ['oral_tradition'],
    leadsTo: [],
    researchCost: 80,
    icon: '✡️',
    unlocks: ['Yax synagogues', 'Sacred law'],
    religion: 'yax'
  },
  {
    id: 'religion_drox',
    name: 'Drox',
    description: 'Worship the ancient spirits of Drox',
    category: 'religion',
    requiredTech: ['oral_tradition'],
    leadsTo: [],
    researchCost: 80,
    icon: '🌞',
    unlocks: ['Drox pyramids', 'Blood rituals', 'Sun worship'],
    religion: 'drox'
  },
  {
    id: 'religion_sox',
    name: 'Sox',
    description: 'Seek enlightenment through Sox teachings',
    category: 'religion',
    requiredTech: ['oral_tradition'],
    leadsTo: [],
    researchCost: 80,
    icon: '☸️',
    unlocks: ['Sox monasteries', 'Meditation', 'Inner peace'],
    religion: 'sox'
  },

  // === PHILOSOPHY ===
  {
    id: 'philosophy_ethics',
    name: 'Ethics',
    description: 'Question what is right and wrong',
    category: 'philosophy',
    requiredTech: ['literature_advanced'],
    leadsTo: ['philosophy_political'],
    researchCost: 120,
    icon: '⚖️',
    unlocks: ['Moral codes', 'Justice system']
  },
  {
    id: 'philosophy_political',
    name: 'Political Philosophy',
    description: 'Understand governance and power',
    category: 'philosophy',
    requiredTech: ['philosophy_ethics', 'history_advanced'],
    leadsTo: ['democracy', 'republic'],
    researchCost: 150,
    icon: '🏛️',
    unlocks: ['Government reforms', 'Political systems']
  }
];

// Trade Definitions
export const TRADES: Trade[] = [
  {
    id: 'blacksmith',
    name: 'Blacksmith',
    description: 'Forge weapons, tools, and armor from metal',
    requiredTech: 'blacksmithing',
    benefits: ['Produce metal goods', 'Repair equipment', '+10% military strength']
  },
  {
    id: 'carpenter',
    name: 'Carpenter',
    description: 'Work with wood to create buildings and furniture',
    requiredTech: 'carpentry',
    benefits: ['Build wooden structures', '-20% building cost', 'Produce furniture']
  },
  {
    id: 'textile_worker',
    name: 'Textile Worker',
    description: 'Create cloth and garments',
    requiredTech: 'textile_work',
    benefits: ['Produce clothing', '+15% trade income', 'Luxury goods']
  },
  {
    id: 'shipwright',
    name: 'Shipwright',
    description: 'Build ships for travel and trade',
    requiredTech: 'shipbuilding',
    benefits: ['Construct ships', 'Enable sea trade', '+30% naval movement']
  },
  {
    id: 'miner',
    name: 'Miner',
    description: 'Extract valuable resources from the earth',
    requiredTech: 'mining',
    benefits: ['Mine resources', '+50% ore yield', 'Discover rare materials']
  },
  {
    id: 'architect',
    name: 'Architect',
    description: 'Design complex and beautiful structures',
    requiredTech: 'architecture',
    benefits: ['Plan cities', '+25% building efficiency', 'Wonder construction']
  },
  {
    id: 'mason',
    name: 'Mason',
    description: 'Build with stone and create fortifications',
    requiredTech: 'masonry',
    benefits: ['Stone construction', '+40% defense', 'Durable buildings']
  },
  {
    id: 'physician',
    name: 'Physician',
    description: 'Heal the sick and wounded',
    requiredTech: 'medicine',
    benefits: ['Heal units', '+20% population growth', 'Disease prevention']
  },
  {
    id: 'teacher',
    name: 'Teacher',
    description: 'Educate and spread knowledge',
    requiredTech: 'teaching',
    benefits: ['Increase knowledge gain', '+2 knowledge/tick', 'Faster research']
  }
];

// Religion Definitions
export const RELIGIONS: Religion[] = [
  {
    id: 'imlax',
    name: 'Imlax',
    description: 'Submission to the one divine will. Unity through faith.',
    beliefs: ['Five pillars of devotion', 'Daily prayer', 'Pilgrimage to holy sites'],
    bonuses: ['+10% faith generation', '+5% cultural influence', 'Unity bonus in cities']
  },
  {
    id: 'cris',
    name: 'Cris',
    description: 'Salvation through love, faith, and redemption.',
    beliefs: ['Love thy neighbor', 'Forgiveness', 'Sacred texts'],
    bonuses: ['+15% diplomatic relations', '+10% healing', 'Missionary spread bonus']
  },
  {
    id: 'shix',
    name: 'Shix',
    description: 'Balance through many gods. Karma guides your path.',
    beliefs: ['Dharma and karma', 'Reincarnation', 'Many paths to divinity'],
    bonuses: ['+20% knowledge gain', '+10% food production', 'Peaceful expansion']
  },
  {
    id: 'yax',
    name: 'Yax',
    description: 'The chosen people, bound by sacred covenant.',
    beliefs: ['The covenant', 'Sacred law', 'Promised land'],
    bonuses: ['+15% science output', '+10% gold from trade', 'Cultural resilience']
  },
  {
    id: 'drox',
    name: 'Drox',
    description: 'Ancient spirits of sun, rain, and earth. Blood nourishes the gods.',
    beliefs: ['Sun worship', 'Sacred rituals', 'Cosmic balance'],
    bonuses: ['+25% military strength', '+15% construction speed', 'Sacrifice bonuses']
  },
  {
    id: 'sox',
    name: 'Sox',
    description: 'Enlightenment through meditation. Escape the cycle of suffering.',
    beliefs: ['Noble truths', 'Eightfold path', 'Inner peace'],
    bonuses: ['+30% knowledge gain', '+20% happiness', '-10% war weariness']
  }
];

// Helper functions
export function getTechnologyById(id: string): Technology | undefined {
  return TECHNOLOGIES.find(tech => tech.id === id);
}

export function getTechnologiesByCategory(category: string): Technology[] {
  return TECHNOLOGIES.filter(tech => tech.category === category);
}

export function canResearchTech(tech: Technology, researchedTechs: string[]): boolean {
  return tech.requiredTech.every(reqId => researchedTechs.includes(reqId));
}

export function getAvailableTechs(researchedTechs: string[]): Technology[] {
  return TECHNOLOGIES.filter(tech => 
    !researchedTechs.includes(tech.id) && 
    canResearchTech(tech, researchedTechs)
  );
}
