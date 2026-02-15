// Heraldry Types for Altriux Tribal - Fantasy Names Edition

// Shield shapes with fantasy names
export type ShieldShape = 
  | 'drantium'      // Heater (Classic)
  | 'brontium'      // French
  | 'draux'         // Spanish
  | 'druxiux'       // English
  | 'dreix'         // German
  | 'sultrium'      // Italian
  | 'vortix'        // Swiss
  | 'krantor'       // Polish
  | 'imlax'         // Ottoman
  | 'shiex'         // Renaissance
  | 'xaldrin'       // Baroque
  | 'zynthor';      // Modern

// Helm types with fantasy names
export type HelmType = 
  | 'none'
  | 'drakhelm'      // Great Helm
  | 'sylvhelm'      // Sallet
  | 'barbhelm'      // Barbute
  | 'burghelm'      // Burgonet
  | 'armhelm'       // Armet
  | 'closehelm'     // Close Helm
  | 'knighthelm'    // Knight Helm
  | 'royalhelm'     // Royal Helm
  | 'barbhelm2'     // Barbarian Helm
  | 'imperialhelm'; // Imperial Helm

// Crest types
export type CrestType = 
  | 'none'
  | 'plume'
  | 'wings'
  | 'horns'
  | 'crown'
  | 'royal_crown'
  | 'lion'
  | 'eagle'
  | 'dragon'
  | 'unicorn'
  | 'griffin'
  | 'phoenix'
  | 'laurel';

// Mantling types
export type MantlingType = 
  | 'none'
  | 'simple'
  | 'elaborate'
  | 'royal'
  | 'knightly'
  | 'tribal'
  | 'warrior';

// Supporter types
export type SupporterType = 
  | 'none'
  | 'lion_left'
  | 'lion_right'
  | 'griffin_left'
  | 'griffin_right'
  | 'unicorn_left'
  | 'unicorn_right'
  | 'dragon_left'
  | 'dragon_right'
  | 'eagle_left'
  | 'eagle_right'
  | 'stag_left'
  | 'stag_right'
  | 'bear_left'
  | 'bear_right'
  | 'wolf_left'
  | 'wolf_right'
  | 'yak_left'
  | 'yak_right'
  | 'alpaca_left'
  | 'alpaca_right'
  | 'llama_left'
  | 'llama_right'
  | 'horse_left'
  | 'horse_right'
  | 'husky_left'
  | 'husky_right'
  | 'bison_left'
  | 'bison_right'
  | 'mammoth_left'
  | 'mammoth_right';

// Field patterns
export type FieldPattern = 
  | 'solid'
  | 'party_per_pale'
  | 'party_per_fess'
  | 'party_per_bend'
  | 'quarterly'
  | 'chequy'
  | 'gyronny'
  | 'paly'
  | 'bendy'
  | 'lozengy'
  | 'fretty'
  | 'masoned';

// Motto styles
export type MottoStyle =
  | 'simple'
  | 'ribbon'
  | 'banner'
  | 'scroll'
  | 'tribal'
  | 'royal'
  | 'ornate'
  | 'shield';

// Central charge types
export type CentralChargeType =
  | 'none'
  // Animals
  | 'lion_rampant' | 'eagle_displayed' | 'dragon_passant' | 'griffin_segurant'
  | 'unicorn_rampant' | 'bear_rampant' | 'wolf_passant' | 'stag_gaze'
  | 'horse_rampant' | 'bull_passant' | 'leopard_passant' | 'tiger_rampant'
  | 'elephant_statant' | 'camel_statant' | 'dolphin_naiant' | 'falcon_close'
  | 'swan_naiant' | 'phoenix_rising' | 'serpent_nowed' | 'boar_statant'
  | 'hare_salient' | 'raven_close' | 'peacock_pride' | 'salamander_flames'
  | 'wyvern_statant' | 'yak_statant' | 'alpaca_statant' | 'llama_statant'
  | 'mammoth_statant' | 'bison_statant' | 'husky_statant' | 'kraken_rising'
  // Celestial
  | 'sun_splendor' | 'moon_crescent' | 'star_eight' | 'star_five' | 'comet'
  // Nature
  | 'oak_tree' | 'rose' | 'fleur_de_lis' | 'palm_tree' | 'wheat_sheaf'
  // Buildings
  | 'castle' | 'tower' | 'church' | 'bridge'
  // Objects
  | 'sword' | 'anchor' | 'crown' | 'key' | 'bell' | 'scimitar' | 'bow' | 'longbow'
  // Religious
  | 'cross_pattee' | 'cross_fleury' | 'chalice' | 'angel' | 'om' | 'swastika' | 'trishula'
  // Geometric
  | 'chevron' | 'bend' | 'fess' | 'pale' | 'saltire' | 'bordure'
  // Islamic
  | 'crescent_star' | 'rub_el_hizb' | 'shahada' | 'scimitar_sword' | 'turban' | 'mosque'
  // Buddhist
  | 'dharma_wheel' | 'lotus' | 'endless_knot' | 'conch'
  // Hindu
  | 'om_symbol' | 'swastika_hindu' | 'trishula' | 'kalash' | 'shankha'
  // Naval
  | 'galleon' | 'ship_wheel' | 'trident' | 'compass_rose' | 'anchor_chain' | 'trireme'
  // Agriculture
  | 'plow' | 'sickle' | 'cornucopia' | 'grapes' | 'olive_branch'
  // Warfare
  | 'battle_axe' | 'mace' | 'war_hammer' | 'spear' | 'bow_arrow'
  | 'shield_boss' | 'banner' | 'drum' | 'horn' | 'gauntlet' | 'crossed_pikes';

// Upper charge types
export type UpperChargeType =
  | 'none'
  | 'horizontal_scimitar'
  | 'horizontal_lightning'
  | 'horizontal_sword'
  | 'horizontal_arrow'
  | 'horizontal_spear'
  | 'horizontal_axe'
  | 'crown_small'
  | 'star_crown'
  | 'laurel_wreath'
  | 'banner_small'
  | 'lightning_triple'
  | 'arrow_barrage'
  | 'sword_pair';

// Lower charge types
export type LowerChargeType =
  | 'none'
  | 'horizontal_scimitar'
  | 'horizontal_lightning'
  | 'horizontal_sword'
  | 'horizontal_arrow'
  | 'horizontal_spear'
  | 'ribbon'
  | 'chain'
  | 'flame_bar'
  | 'wave_pattern'
  | 'dagger_pair'
  | 'arrow_pair'
  | 'sword_dagger';

// Crossed background types
export type CrossedBackgroundType =
  | 'none'
  | 'crossed_swords'
  | 'crossed_spears'
  | 'crossed_axes'
  | 'crossed_halberds'
  | 'crossed_maces'
  | 'crossed_banners'
  | 'crossed_pikes'
  | 'crossed_scimitars'
  | 'crossed_lances'
  | 'laurel_wreath'
  | 'oak_wreath'
  | 'palm_branches';

export interface CoatOfArms {
  shield: {
    shape: ShieldShape;
    fieldColor: string;
    fieldPattern: FieldPattern;
    secondaryColor: string;
    borderColor: string;
    borderWidth: number;
  };
  helm: {
    type: HelmType;
    color: string;
  };
  crest: {
    type: CrestType;
    color: string;
  };
  mantling: {
    type: MantlingType;
    primaryColor: string;
    secondaryColor: string;
  };
  supporters: {
    left: SupporterType;
    right: SupporterType;
    color: string;
  };
  centralCharge: {
    type: CentralChargeType;
    color: string;
    position: { x: number; y: number };
    scale: number;
  };
  upperCharge: {
    type: UpperChargeType;
    color: string;
    scale: number;
  };
  lowerCharge: {
    type: LowerChargeType;
    color: string;
    scale: number;
  };
  crossedBackground: {
    type: CrossedBackgroundType;
    color: string;
    opacity: number;
  };
  motto: {
    text: string;
    color: string;
    backgroundColor: string;
    style: MottoStyle;
  };
}

export const DEFAULT_COAT_OF_ARMS: CoatOfArms = {
  shield: {
    shape: 'drantium',
    fieldColor: '#1a1a1a',
    fieldPattern: 'solid',
    secondaryColor: '#f97316',
    borderColor: '#f97316',
    borderWidth: 3,
  },
  helm: {
    type: 'knighthelm',
    color: '#c0c0c0',
  },
  crest: {
    type: 'royal_crown',
    color: '#fbbf24',
  },
  mantling: {
    type: 'tribal',
    primaryColor: '#1a1a1a',
    secondaryColor: '#f97316',
  },
  supporters: {
    left: 'lion_left',
    right: 'lion_right',
    color: '#fbbf24',
  },
  centralCharge: {
    type: 'lion_rampant',
    color: '#fbbf24',
    position: { x: 50, y: 50 },
    scale: 1,
  },
  upperCharge: {
    type: 'none',
    color: '#fbbf24',
    scale: 0.8,
  },
  lowerCharge: {
    type: 'none',
    color: '#fbbf24',
    scale: 0.8,
  },
  crossedBackground: {
    type: 'none',
    color: '#f97316',
    opacity: 0.3,
  },
  motto: {
    text: 'Altriux Tribal',
    color: '#f97316',
    backgroundColor: '#1a1a1a',
    style: 'tribal',
  },
};

// Shield shapes with fantasy names
export const SHIELD_SHAPES: { value: ShieldShape; label: string }[] = [
  { value: 'drantium', label: 'Drantium (Classic)' },
  { value: 'brontium', label: 'Brontium' },
  { value: 'draux', label: 'Draux' },
  { value: 'druxiux', label: 'Druxiux' },
  { value: 'dreix', label: 'Dreix' },
  { value: 'sultrium', label: 'Sultrium' },
  { value: 'vortix', label: 'Vortix' },
  { value: 'krantor', label: 'Krantor' },
  { value: 'imlax', label: 'Imlax' },
  { value: 'shiex', label: 'Shiex' },
  { value: 'xaldrin', label: 'Xaldrin' },
  { value: 'zynthor', label: 'Zynthor' },
];

// Helm types
export const HELM_TYPES: { value: HelmType; label: string }[] = [
  { value: 'none', label: 'None' },
  { value: 'drakhelm', label: 'Drakhelm' },
  { value: 'sylvhelm', label: 'Sylvhelm' },
  { value: 'barbhelm', label: 'Barbhelm' },
  { value: 'burghelm', label: 'Burghelm' },
  { value: 'armhelm', label: 'Armhelm' },
  { value: 'closehelm', label: 'Closehelm' },
  { value: 'knighthelm', label: 'Knighthelm' },
  { value: 'royalhelm', label: 'Royalhelm' },
  { value: 'barbhelm2', label: 'Barbhelm II' },
  { value: 'imperialhelm', label: 'Imperialhelm' },
];

// Crest types
export const CREST_TYPES: { value: CrestType; label: string }[] = [
  { value: 'none', label: 'None' },
  { value: 'plume', label: 'Plume' },
  { value: 'wings', label: 'Wings' },
  { value: 'horns', label: 'Horns' },
  { value: 'crown', label: 'Crown' },
  { value: 'royal_crown', label: 'Royal Crown' },
  { value: 'lion', label: 'Lion' },
  { value: 'eagle', label: 'Eagle' },
  { value: 'dragon', label: 'Dragon' },
  { value: 'unicorn', label: 'Unicorn' },
  { value: 'griffin', label: 'Griffin' },
  { value: 'phoenix', label: 'Phoenix' },
  { value: 'laurel', label: 'Laurel Wreath' },
];

// Mantling types
export const MANTLING_TYPES: { value: MantlingType; label: string }[] = [
  { value: 'none', label: 'None' },
  { value: 'simple', label: 'Simple' },
  { value: 'elaborate', label: 'Elaborate' },
  { value: 'royal', label: 'Royal' },
  { value: 'knightly', label: 'Knightly' },
  { value: 'tribal', label: 'Tribal' },
  { value: 'warrior', label: 'Warrior' },
];

// Supporter types
export const SUPPORTER_TYPES: { value: SupporterType; label: string }[] = [
  { value: 'none', label: 'None' },
  { value: 'lion_left', label: 'Lion (Left)' },
  { value: 'lion_right', label: 'Lion (Right)' },
  { value: 'griffin_left', label: 'Griffin (Left)' },
  { value: 'griffin_right', label: 'Griffin (Right)' },
  { value: 'unicorn_left', label: 'Unicorn (Left)' },
  { value: 'unicorn_right', label: 'Unicorn (Right)' },
  { value: 'dragon_left', label: 'Dragon (Left)' },
  { value: 'dragon_right', label: 'Dragon (Right)' },
  { value: 'eagle_left', label: 'Eagle (Left)' },
  { value: 'eagle_right', label: 'Eagle (Right)' },
  { value: 'stag_left', label: 'Stag (Left)' },
  { value: 'stag_right', label: 'Stag (Right)' },
  { value: 'bear_left', label: 'Bear (Left)' },
  { value: 'bear_right', label: 'Bear (Right)' },
  { value: 'wolf_left', label: 'Wolf (Left)' },
  { value: 'wolf_right', label: 'Wolf (Right)' },
  { value: 'yak_left', label: 'Yak (Left)' },
  { value: 'yak_right', label: 'Yak (Right)' },
  { value: 'alpaca_left', label: 'Alpaca (Left)' },
  { value: 'alpaca_right', label: 'Alpaca (Right)' },
  { value: 'llama_left', label: 'Llama (Left)' },
  { value: 'llama_right', label: 'Llama (Right)' },
  { value: 'horse_left', label: 'Horse (Left)' },
  { value: 'horse_right', label: 'Horse (Right)' },
  { value: 'husky_left', label: 'Husky (Left)' },
  { value: 'husky_right', label: 'Husky (Right)' },
  { value: 'bison_left', label: 'Bison (Left)' },
  { value: 'bison_right', label: 'Bison (Right)' },
  { value: 'mammoth_left', label: 'Mammoth (Left)' },
  { value: 'mammoth_right', label: 'Mammoth (Right)' },
];

// Field patterns
export const FIELD_PATTERNS = [
  { value: 'solid', label: 'Solid' },
  { value: 'party_per_pale', label: 'Per Pale (Vertical)' },
  { value: 'party_per_fess', label: 'Per Fess (Horizontal)' },
  { value: 'party_per_bend', label: 'Per Bend (Diagonal)' },
  { value: 'quarterly', label: 'Quarterly' },
  { value: 'chequy', label: 'Chequy (Checkered)' },
  { value: 'gyronny', label: 'Gyronny' },
  { value: 'paly', label: 'Paly (Striped)' },
  { value: 'bendy', label: 'Bendy (Diagonal Stripes)' },
  { value: 'lozengy', label: 'Lozengy (Diamonds)' },
  { value: 'fretty', label: 'Fretty (Lattice)' },
  { value: 'masoned', label: 'Masoned (Bricks)' },
];

// Motto styles
export const MOTTO_STYLES: { value: MottoStyle; label: string }[] = [
  { value: 'simple', label: 'Simple' },
  { value: 'ribbon', label: 'Ribbon' },
  { value: 'banner', label: 'Banner' },
  { value: 'scroll', label: 'Scroll' },
  { value: 'tribal', label: 'Tribal' },
  { value: 'royal', label: 'Royal' },
  { value: 'ornate', label: 'Ornate' },
  { value: 'shield', label: 'Shield' },
];

// Central charges organized by category
export const CENTRAL_CHARGES = {
  'None': [{ value: 'none', label: 'None' }],
  'Animals': [
    { value: 'lion_rampant', label: 'Lion Rampant' },
    { value: 'eagle_displayed', label: 'Eagle Displayed' },
    { value: 'dragon_passant', label: 'Dragon Passant' },
    { value: 'griffin_segurant', label: 'Griffin Segurant' },
    { value: 'unicorn_rampant', label: 'Unicorn Rampant' },
    { value: 'bear_rampant', label: 'Bear Rampant' },
    { value: 'wolf_passant', label: 'Wolf Passant' },
    { value: 'stag_gaze', label: 'Stag' },
    { value: 'horse_rampant', label: 'Horse Rampant' },
    { value: 'bull_passant', label: 'Bull Passant' },
    { value: 'leopard_passant', label: 'Leopard Passant' },
    { value: 'tiger_rampant', label: 'Tiger Rampant' },
    { value: 'elephant_statant', label: 'Elephant' },
    { value: 'camel_statant', label: 'Camel' },
    { value: 'dolphin_naiant', label: 'Dolphin' },
    { value: 'falcon_close', label: 'Falcon' },
    { value: 'swan_naiant', label: 'Swan' },
    { value: 'phoenix_rising', label: 'Phoenix' },
    { value: 'serpent_nowed', label: 'Serpent' },
    { value: 'boar_statant', label: 'Boar' },
    { value: 'hare_salient', label: 'Hare' },
    { value: 'raven_close', label: 'Raven' },
    { value: 'peacock_pride', label: 'Peacock' },
    { value: 'salamander_flames', label: 'Salamander' },
    { value: 'wyvern_statant', label: 'Wyvern' },
    { value: 'yak_statant', label: 'Yak' },
    { value: 'alpaca_statant', label: 'Alpaca' },
    { value: 'llama_statant', label: 'Llama' },
    { value: 'mammoth_statant', label: 'Mammoth' },
    { value: 'bison_statant', label: 'Bison' },
    { value: 'husky_statant', label: 'Husky' },
    { value: 'kraken_rising', label: 'Kraken' },
  ],
  'Celestial': [
    { value: 'sun_splendor', label: 'Sun' },
    { value: 'moon_crescent', label: 'Crescent Moon' },
    { value: 'star_eight', label: 'Eight-Pointed Star' },
    { value: 'star_five', label: 'Five-Pointed Star' },
    { value: 'comet', label: 'Comet' },
  ],
  'Nature': [
    { value: 'oak_tree', label: 'Oak Tree' },
    { value: 'rose', label: 'Rose' },
    { value: 'fleur_de_lis', label: 'Fleur-de-lis' },
    { value: 'palm_tree', label: 'Palm Tree' },
    { value: 'wheat_sheaf', label: 'Wheat Sheaf' },
  ],
  'Buildings': [
    { value: 'castle', label: 'Castle' },
    { value: 'tower', label: 'Tower' },
    { value: 'church', label: 'Church' },
    { value: 'bridge', label: 'Bridge' },
  ],
  'Objects': [
    { value: 'sword', label: 'Sword' },
    { value: 'anchor', label: 'Anchor' },
    { value: 'crown', label: 'Crown' },
    { value: 'key', label: 'Key' },
    { value: 'bell', label: 'Bell' },
    { value: 'scimitar', label: 'Scimitar' },
    { value: 'bow', label: 'Bow' },
    { value: 'longbow', label: 'Longbow' },
  ],
  'Religious': [
    { value: 'cross_pattee', label: 'Cross Pattee' },
    { value: 'cross_fleury', label: 'Cross Fleury' },
    { value: 'chalice', label: 'Chalice' },
    { value: 'angel', label: 'Angel' },
  ],
  'Hindu': [
    { value: 'om_symbol', label: 'Om' },
    { value: 'swastika_hindu', label: 'Swastika' },
    { value: 'trishula', label: 'Trishula' },
    { value: 'kalash', label: 'Kalash' },
    { value: 'shankha', label: 'Shankha' },
  ],
  'Geometric': [
    { value: 'chevron', label: 'Chevron' },
    { value: 'bend', label: 'Bend' },
    { value: 'fess', label: 'Fess' },
    { value: 'pale', label: 'Pale' },
    { value: 'saltire', label: 'Saltire' },
    { value: 'bordure', label: 'Bordure' },
  ],
  'Islamic': [
    { value: 'crescent_star', label: 'Crescent & Star' },
    { value: 'rub_el_hizb', label: 'Rub el Hizb' },
    { value: 'shahada', label: 'Shahada Banner' },
    { value: 'scimitar_sword', label: 'Scimitar' },
    { value: 'turban', label: 'Turban' },
    { value: 'mosque', label: 'Mosque' },
  ],
  'Buddhist': [
    { value: 'dharma_wheel', label: 'Dharma Wheel' },
    { value: 'lotus', label: 'Lotus' },
    { value: 'endless_knot', label: 'Endless Knot' },
    { value: 'conch', label: 'Conch Shell' },
  ],
  'Naval': [
    { value: 'galleon', label: 'Galleon' },
    { value: 'ship_wheel', label: 'Ship Wheel' },
    { value: 'trident', label: 'Trident' },
    { value: 'compass_rose', label: 'Compass Rose' },
    { value: 'anchor_chain', label: 'Anchor with Chain' },
    { value: 'trireme', label: 'Trireme' },
  ],
  'Agriculture': [
    { value: 'plow', label: 'Plow' },
    { value: 'sickle', label: 'Sickle' },
    { value: 'cornucopia', label: 'Cornucopia' },
    { value: 'grapes', label: 'Grapes' },
    { value: 'olive_branch', label: 'Olive Branch' },
  ],
  'Warfare': [
    { value: 'battle_axe', label: 'Battle Axe' },
    { value: 'mace', label: 'Mace' },
    { value: 'war_hammer', label: 'War Hammer' },
    { value: 'spear', label: 'Spear' },
    { value: 'bow_arrow', label: 'Bow & Arrow' },
    { value: 'shield_boss', label: 'Shield Boss' },
    { value: 'banner', label: 'Banner' },
    { value: 'drum', label: 'War Drum' },
    { value: 'horn', label: 'Horn' },
    { value: 'gauntlet', label: 'Gauntlet' },
    { value: 'crossed_pikes', label: 'Crossed Pikes' },
  ],
};

// Upper charges
export const UPPER_CHARGES: { value: UpperChargeType; label: string }[] = [
  { value: 'none', label: 'None' },
  { value: 'horizontal_scimitar', label: 'Horizontal Scimitar' },
  { value: 'horizontal_lightning', label: 'Lightning Bolt' },
  { value: 'horizontal_sword', label: 'Horizontal Sword' },
  { value: 'horizontal_arrow', label: 'Horizontal Arrow' },
  { value: 'horizontal_spear', label: 'Horizontal Spear' },
  { value: 'horizontal_axe', label: 'Horizontal Axe' },
  { value: 'crown_small', label: 'Small Crown' },
  { value: 'star_crown', label: 'Star Crown' },
  { value: 'laurel_wreath', label: 'Laurel Wreath' },
  { value: 'banner_small', label: 'Small Banner' },
  { value: 'lightning_triple', label: 'Triple Lightning' },
  { value: 'arrow_barrage', label: 'Arrow Barrage' },
  { value: 'sword_pair', label: 'Sword Pair' },
];

// Lower charges
export const LOWER_CHARGES: { value: LowerChargeType; label: string }[] = [
  { value: 'none', label: 'None' },
  { value: 'horizontal_scimitar', label: 'Horizontal Scimitar' },
  { value: 'horizontal_lightning', label: 'Lightning Bolt' },
  { value: 'horizontal_sword', label: 'Horizontal Sword' },
  { value: 'horizontal_arrow', label: 'Horizontal Arrow' },
  { value: 'horizontal_spear', label: 'Horizontal Spear' },
  { value: 'ribbon', label: 'Ribbon' },
  { value: 'chain', label: 'Chain' },
  { value: 'flame_bar', label: 'Flame Bar' },
  { value: 'wave_pattern', label: 'Wave Pattern' },
  { value: 'dagger_pair', label: 'Dagger Pair' },
  { value: 'arrow_pair', label: 'Arrow Pair' },
  { value: 'sword_dagger', label: 'Sword & Dagger' },
];

// Crossed background elements
export const CROSSED_BACKGROUNDS: { value: CrossedBackgroundType; label: string }[] = [
  { value: 'none', label: 'None' },
  { value: 'crossed_swords', label: 'Crossed Swords' },
  { value: 'crossed_spears', label: 'Crossed Spears' },
  { value: 'crossed_axes', label: 'Crossed Axes' },
  { value: 'crossed_halberds', label: 'Crossed Halberds' },
  { value: 'crossed_maces', label: 'Crossed Maces' },
  { value: 'crossed_banners', label: 'Crossed Banners' },
  { value: 'crossed_pikes', label: 'Crossed Pikes' },
  { value: 'crossed_scimitars', label: 'Crossed Scimitars' },
  { value: 'crossed_lances', label: 'Crossed Lances' },
  { value: 'laurel_wreath', label: 'Laurel Wreath' },
  { value: 'oak_wreath', label: 'Oak Wreath' },
  { value: 'palm_branches', label: 'Palm Branches' },
];

// Shield export utility for game integration
export interface ShieldExport {
  id: string;
  timestamp: number;
  coatOfArms: CoatOfArms;
  pngDataUrl: string;
  metadata: {
    name: string;
    description: string;
    registered: boolean;
    registrationCost: number;
  };
}

export const exportShieldForGame = (coatOfArms: CoatOfArms, pngDataUrl: string): ShieldExport => {
  return {
    id: `shield_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    timestamp: Date.now(),
    coatOfArms,
    pngDataUrl,
    metadata: {
      name: coatOfArms.motto.text || 'Unnamed Shield',
      description: `Heraldic shield with ${coatOfArms.centralCharge.type} charge`,
      registered: false,
      registrationCost: 10,
    },
  };
};
