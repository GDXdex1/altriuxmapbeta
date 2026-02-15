import React, { useState } from 'react';
import type { CoatOfArms } from '@/types/heraldry';
import { SHIELD_PATHS } from './shield-paths';

interface CoatOfArmsSVGProps {
  coatOfArms: CoatOfArms;
  width?: number;
  height?: number;
  className?: string;
}

// Image mappings for all charge types
const CENTRAL_CHARGE_IMAGES: Record<string, string | null> = {
  none: null,
  // Animals
  lion_rampant: '/symbols/animals/lion_rampant.png',
  eagle_displayed: '/symbols/animals/eagle_displayed.png',
  dragon_passant: '/symbols/animals/dragon_passant.png',
  griffin_segurant: '/symbols/animals/griffin_segurant.png',
  unicorn_rampant: '/symbols/animals/unicorn_rampant.png',
  bear_rampant: '/symbols/animals/bear_rampant.png',
  wolf_passant: '/symbols/animals/wolf_passant.png',
  stag_gaze: '/symbols/animals/stag_gaze.png',
  horse_rampant: '/symbols/animals/horse_rampant.png',
  bull_passant: '/symbols/animals/bull_passant.png',
  leopard_passant: '/symbols/animals/leopard_passant.png',
  tiger_rampant: '/symbols/animals/tiger_rampant.png',
  elephant_statant: '/symbols/animals/elephant_statant.png',
  camel_statant: '/symbols/animals/camel_statant.png',
  dolphin_naiant: '/symbols/animals/dolphin_naiant.png',
  falcon_close: '/symbols/animals/falcon_close.png',
  swan_naiant: '/symbols/animals/swan_naiant.png',
  phoenix_rising: '/symbols/animals/phoenix_rising.png',
  serpent_nowed: '/symbols/animals/serpent_nowed.png',
  boar_statant: '/symbols/animals/boar_statant.png',
  hare_salient: '/symbols/animals/hare_salient.png',
  raven_close: '/symbols/animals/raven_close.png',
  peacock_pride: '/symbols/animals/peacock_pride.png',
  salamander_flames: '/symbols/animals/salamander_flames.png',
  wyvern_statant: '/symbols/animals/wyvern_statant.png',
  // New animals
  yak_statant: '/symbols/new_animals/yak.png',
  alpaca_statant: '/symbols/new_animals/alpaca.png',
  llama_statant: '/symbols/new_animals/llama.png',
  mammoth_statant: '/symbols/new_animals/mammoth.png',
  bison_statant: '/symbols/new_animals/bison.png',
  husky_statant: '/symbols/new_animals/husky.png',
  kraken_rising: '/symbols/new_animals/kraken.png',
  // Celestial
  sun_splendor: '/symbols/celestial/sun_splendor.png',
  moon_crescent: '/symbols/celestial/moon_crescent.png',
  star_eight: '/symbols/celestial/star_eight.png',
  star_five: '/symbols/celestial/star_five.png',
  comet: '/symbols/celestial/comet.png',
  // Nature
  oak_tree: '/symbols/nature/oak_tree.png',
  rose: '/symbols/nature/rose.png',
  fleur_de_lis: '/symbols/nature/fleur_de_lis.png',
  palm_tree: '/symbols/nature/palm_tree.png',
  wheat_sheaf: '/symbols/nature/wheat_sheaf.png',
  // Buildings
  castle: '/symbols/buildings/castle.png',
  tower: '/symbols/buildings/tower.png',
  church: '/symbols/buildings/church.png',
  bridge: '/symbols/buildings/bridge.png',
  // Objects
  sword: '/symbols/objects/sword.png',
  anchor: '/symbols/objects/anchor.png',
  crown: '/symbols/objects/crown.png',
  key: '/symbols/objects/key.png',
  bell: '/symbols/objects/bell.png',
  scimitar: '/symbols/objects/scimitar.png',
  bow: '/symbols/objects/sword.png',
  longbow: '/symbols/objects/sword.png',
  // Religious
  cross_pattee: '/symbols/religious/cross_pattee.png',
  cross_fleury: '/symbols/religious/cross_fleury.png',
  chalice: '/symbols/religious/chalice.png',
  angel: '/symbols/religious/angel.png',
  // Hindu
  om_symbol: '/symbols/hindu/om.png',
  swastika_hindu: '/symbols/hindu/swastika.png',
  trishula: '/symbols/naval/trident.png',
  kalash: '/symbols/religious/chalice.png',
  shankha: '/symbols/buddhist/conch.png',
  // Geometric
  chevron: '/symbols/geometric/chevron.png',
  bend: '/symbols/geometric/bend.png',
  fess: '/symbols/geometric/fess.png',
  pale: '/symbols/geometric/pale.png',
  saltire: '/symbols/geometric/saltire.png',
  bordure: '/symbols/geometric/bordure.png',
  // Islamic
  crescent_star: '/symbols/islamic/crescent_star.png',
  rub_el_hizb: '/symbols/islamic/rub_el_hizb.png',
  shahada: '/symbols/islamic/shahada.png',
  scimitar_sword: '/symbols/islamic/scimitar_sword.png',
  turban: '/symbols/islamic/turban.png',
  mosque: '/symbols/islamic/mosque.png',
  // Buddhist
  dharma_wheel: '/symbols/buddhist/dharma_wheel.png',
  lotus: '/symbols/buddhist/lotus.png',
  endless_knot: '/symbols/buddhist/endless_knot.png',
  conch: '/symbols/buddhist/conch.png',
  // Naval
  galleon: '/symbols/naval/galleon.png',
  ship_wheel: '/symbols/naval/ship_wheel.png',
  trident: '/symbols/naval/trident.png',
  compass_rose: '/symbols/naval/compass_rose.png',
  anchor_chain: '/symbols/naval/anchor_chain.png',
  trireme: '/symbols/naval/galleon.png',
  // Agriculture
  plow: '/symbols/agriculture/plow.png',
  sickle: '/symbols/agriculture/sickle.png',
  cornucopia: '/symbols/agriculture/cornucopia.png',
  grapes: '/symbols/agriculture/grapes.png',
  olive_branch: '/symbols/agriculture/olive_branch.png',
  // Warfare
  battle_axe: '/symbols/warfare/battle_axe.png',
  mace: '/symbols/warfare/mace.png',
  war_hammer: '/symbols/warfare/war_hammer.png',
  spear: '/symbols/warfare/spear.png',
  bow_arrow: '/symbols/warfare/bow_arrow.png',
  shield_boss: '/symbols/warfare/shield_boss.png',
  banner: '/symbols/warfare/banner.png',
  drum: '/symbols/warfare/drum.png',
  horn: '/symbols/warfare/horn.png',
  gauntlet: '/symbols/warfare/gauntlet.png',
  crossed_pikes: '/symbols/crossed_background/crossed_pikes.png',
  // New dragons
  red_dragon: '/symbols/new_dragons/red_dragon.png',
  black_dragon: '/symbols/new_dragons/black_dragon.png',
  gold_dragon: '/symbols/new_dragons/gold_dragon.png',
};

const UPPER_CHARGE_IMAGES: Record<string, string | null> = {
  none: null,
  horizontal_scimitar: '/symbols/upper_charges/horizontal_scimitar.png',
  horizontal_lightning: '/symbols/upper_charges/horizontal_lightning.png',
  horizontal_sword: '/symbols/upper_charges/horizontal_sword.png',
  horizontal_arrow: '/symbols/upper_charges/horizontal_arrow.png',
  horizontal_spear: '/symbols/upper_charges/horizontal_spear.png',
  horizontal_axe: '/symbols/upper_charges/horizontal_axe.png',
  crown_small: '/symbols/upper_charges/crown_small.png',
  star_crown: '/symbols/celestial/star_eight.png',
  laurel_wreath: '/symbols/agriculture/olive_branch.png',
  banner_small: '/symbols/warfare/banner.png',
  lightning_triple: '/symbols/upper_charges/horizontal_lightning.png',
  arrow_barrage: '/symbols/upper_charges/horizontal_arrow.png',
  sword_pair: '/symbols/upper_charges/horizontal_sword.png',
};

const LOWER_CHARGE_IMAGES: Record<string, string | null> = {
  none: null,
  horizontal_scimitar: '/symbols/upper_charges/horizontal_scimitar.png',
  horizontal_lightning: '/symbols/upper_charges/horizontal_lightning.png',
  horizontal_sword: '/symbols/upper_charges/horizontal_sword.png',
  horizontal_arrow: '/symbols/upper_charges/horizontal_arrow.png',
  ribbon: '/symbols/warfare/banner.png',
  chain: '/symbols/naval/anchor_chain.png',
  flame_bar: '/symbols/upper_charges/horizontal_lightning.png',
  wave_pattern: '/symbols/naval/trident.png',
  dagger_pair: '/symbols/objects/sword.png',
  arrow_pair: '/symbols/upper_charges/horizontal_arrow.png',
  sword_dagger: '/symbols/objects/sword.png',
};

const CROSSED_BACKGROUND_IMAGES: Record<string, string | null> = {
  none: null,
  crossed_swords: '/symbols/crossed_background/crossed_swords.png',
  crossed_spears: '/symbols/crossed_background/crossed_spears.png',
  crossed_axes: '/symbols/crossed_background/crossed_axes.png',
  crossed_halberds: '/symbols/crossed_background/crossed_halberds.png',
  crossed_maces: '/symbols/crossed_background/crossed_maces.png',
  crossed_banners: '/symbols/crossed_background/crossed_banners.png',
  crossed_pikes: '/symbols/crossed_background/crossed_pikes.png',
  crossed_scimitars: '/symbols/crossed_background/crossed_scimitars.png',
  crossed_lances: '/symbols/crossed_background/crossed_lances.png',
  laurel_wreath: '/symbols/crossed_background/laurel_wreath.png',
  oak_wreath: '/symbols/crossed_background/oak_wreath.png',
  palm_branches: '/symbols/crossed_background/palm_branches.png',
};

const SUPPORTER_IMAGES: Record<string, string | null> = {
  none: null,
  lion_left: '/symbols/supporters/lion_left.png',
  lion_right: '/symbols/supporters/lion_right.png',
  griffin_left: '/symbols/supporters/griffin_left.png',
  griffin_right: '/symbols/supporters/griffin_right.png',
  unicorn_left: '/symbols/supporters/unicorn_left.png',
  unicorn_right: '/symbols/supporters/unicorn_right.png',
  dragon_left: '/symbols/supporters/dragon.png',
  dragon_right: '/symbols/supporters/dragon.png',
  eagle_left: '/symbols/supporters/eagle.png',
  eagle_right: '/symbols/supporters/eagle.png',
  stag_left: '/symbols/supporters/stag.png',
  stag_right: '/symbols/supporters/stag.png',
  bear_left: '/symbols/supporters/bear.png',
  bear_right: '/symbols/supporters/bear.png',
  wolf_left: '/symbols/supporters/wolf.png',
  wolf_right: '/symbols/supporters/wolf.png',
  yak_left: '/symbols/new_animals/yak.png',
  yak_right: '/symbols/new_animals/yak.png',
  alpaca_left: '/symbols/new_animals/alpaca.png',
  alpaca_right: '/symbols/new_animals/alpaca.png',
  llama_left: '/symbols/new_animals/llama.png',
  llama_right: '/symbols/new_animals/llama.png',
  horse_left: '/symbols/animals/horse_rampant.png',
  horse_right: '/symbols/animals/horse_rampant.png',
  husky_left: '/symbols/new_animals/husky.png',
  husky_right: '/symbols/new_animals/husky.png',
  bison_left: '/symbols/new_animals/bison.png',
  bison_right: '/symbols/new_animals/bison.png',
  mammoth_left: '/symbols/new_animals/mammoth.png',
  mammoth_right: '/symbols/new_animals/mammoth.png',
};

const HELM_IMAGES: Record<string, string | null> = {
  none: null,
  drakhelm: '/symbols/helmets/knight_helm.png',
  sylvhelm: '/symbols/helmets/knight_helm.png',
  barbhelm: '/symbols/helmets/knight_helm.png',
  burghelm: '/symbols/helmets/knight_helm.png',
  armhelm: '/symbols/helmets/knight_helm.png',
  closehelm: '/symbols/helmets/knight_helm.png',
  knighthelm: '/symbols/helmets/knight_helm.png',
  royalhelm: '/symbols/crests/royal_crown.png',
  barbhelm2: '/symbols/helmets/knight_helm.png',
  imperialhelm: '/symbols/crests/royal_crown.png',
};

const CREST_IMAGES: Record<string, string | null> = {
  none: null,
  plume: '/symbols/crests/royal_crown.png',
  wings: '/symbols/crests/royal_crown.png',
  horns: '/symbols/crests/royal_crown.png',
  crown: '/symbols/crests/royal_crown.png',
  royal_crown: '/symbols/crests/royal_crown.png',
  lion: '/symbols/animals/lion_rampant.png',
  eagle: '/symbols/animals/eagle_displayed.png',
  dragon: '/symbols/animals/dragon_passant.png',
  unicorn: '/symbols/animals/unicorn_rampant.png',
  griffin: '/symbols/animals/griffin_segurant.png',
  phoenix: '/symbols/animals/phoenix_rising.png',
  laurel: '/symbols/agriculture/olive_branch.png',
};

export const CoatOfArmsSVG = React.forwardRef<SVGSVGElement, CoatOfArmsSVGProps>(
  ({ coatOfArms, width = 400, height = 500, className = '' }, ref) => {
    const [_imageLoaded, setImageLoaded] = useState(false);
    const shieldPath = SHIELD_PATHS[coatOfArms.shield.shape] || SHIELD_PATHS.drantium;
    
    const centralChargeImage = CENTRAL_CHARGE_IMAGES[coatOfArms.centralCharge.type];
    const upperChargeImage = UPPER_CHARGE_IMAGES[coatOfArms.upperCharge.type];
    const lowerChargeImage = LOWER_CHARGE_IMAGES[coatOfArms.lowerCharge.type];
    const crossedBgImage = CROSSED_BACKGROUND_IMAGES[coatOfArms.crossedBackground.type];
    const leftSupporter = SUPPORTER_IMAGES[coatOfArms.supporters.left];
    const rightSupporter = SUPPORTER_IMAGES[coatOfArms.supporters.right];
    const helmImage = HELM_IMAGES[coatOfArms.helm.type];
    const crestImage = CREST_IMAGES[coatOfArms.crest.type];

    // Render field pattern
    const renderFieldPattern = () => {
      const { fieldPattern, fieldColor, secondaryColor } = coatOfArms.shield;
      
      switch (fieldPattern) {
        case 'party_per_pale':
          return (
            <>
              <rect x="0" y="0" width="100" height="200" fill={fieldColor} />
              <rect x="100" y="0" width="100" height="200" fill={secondaryColor} />
            </>
          );
        case 'party_per_fess':
          return (
            <>
              <rect x="0" y="0" width="200" height="100" fill={fieldColor} />
              <rect x="0" y="100" width="200" height="100" fill={secondaryColor} />
            </>
          );
        case 'party_per_bend':
          return (
            <>
              <polygon points="0,0 200,200 200,0" fill={fieldColor} />
              <polygon points="0,0 0,200 200,200" fill={secondaryColor} />
            </>
          );
        case 'quarterly':
          return (
            <>
              <rect x="0" y="0" width="100" height="100" fill={fieldColor} />
              <rect x="100" y="0" width="100" height="100" fill={secondaryColor} />
              <rect x="0" y="100" width="100" height="100" fill={secondaryColor} />
              <rect x="100" y="100" width="100" height="100" fill={fieldColor} />
            </>
          );
        case 'chequy':
          const squares = [];
          for (let i = 0; i < 8; i++) {
            for (let j = 0; j < 8; j++) {
              squares.push(
                <rect
                  key={`${i}-${j}`}
                  x={i * 25}
                  y={j * 25}
                  width="25"
                  height="25"
                  fill={(i + j) % 2 === 0 ? fieldColor : secondaryColor}
                />
              );
            }
          }
          return <>{squares}</>;
        case 'gyronny':
          return (
            <>
              <polygon points="100,0 200,0 200,100 100,100" fill={fieldColor} />
              <polygon points="0,0 100,0 100,100 0,100" fill={secondaryColor} />
              <polygon points="0,100 100,100 100,200 0,200" fill={fieldColor} />
              <polygon points="100,100 200,100 200,200 100,200" fill={secondaryColor} />
            </>
          );
        case 'paly':
          const stripes = [];
          for (let i = 0; i < 8; i++) {
            stripes.push(
              <rect
                key={i}
                x={i * 25}
                y="0"
                width="25"
                height="200"
                fill={i % 2 === 0 ? fieldColor : secondaryColor}
              />
            );
          }
          return <>{stripes}</>;
        case 'bendy':
          return (
            <>
              <rect x="0" y="0" width="200" height="200" fill={fieldColor} />
              {[0, 1, 2, 3, 4].map((i) => (
                <polygon
                  key={i}
                  points={`${i * 50},0 ${(i + 1) * 50},0 ${i * 50 + 25},200 ${i * 50 - 25},200`}
                  fill={secondaryColor}
                  opacity="0.5"
                />
              ))}
            </>
          );
        case 'lozengy':
          const diamonds = [];
          for (let i = -2; i < 6; i++) {
            for (let j = -2; j < 6; j++) {
              diamonds.push(
                <polygon
                  key={`${i}-${j}`}
                  points={`${i * 35 + 17.5},${j * 35} ${i * 35 + 35},${j * 35 + 17.5} ${i * 35 + 17.5},${j * 35 + 35} ${i * 35},${j * 35 + 17.5}`}
                  fill={(i + j) % 2 === 0 ? fieldColor : secondaryColor}
                />
              );
            }
          }
          return <>{diamonds}</>;
        case 'fretty':
          return (
            <>
              <rect x="0" y="0" width="200" height="200" fill={fieldColor} />
              {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => (
                <g key={i}>
                  <line x1={i * 25} y1="0" x2={i * 25} y2="200" stroke={secondaryColor} strokeWidth="3" />
                  <line x1="0" y1={i * 25} x2="200" y2={i * 25} stroke={secondaryColor} strokeWidth="3" />
                </g>
              ))}
            </>
          );
        case 'masoned':
          return (
            <>
              <rect x="0" y="0" width="200" height="200" fill={fieldColor} />
              {[0, 1, 2, 3, 4, 5, 6, 7].map((row) => (
                <g key={row}>
                  {[0, 1, 2, 3].map((col) => (
                    <rect
                      key={col}
                      x={col * 50 + (row % 2) * 25}
                      y={row * 25}
                      width="50"
                      height="25"
                      fill="none"
                      stroke={secondaryColor}
                      strokeWidth="2"
                    />
                  ))}
                </g>
              ))}
            </>
          );
        default:
          return <rect x="0" y="0" width="200" height="200" fill={fieldColor} />;
      }
    };

    // Render mantling
    const renderMantling = () => {
      if (coatOfArms.mantling.type === 'none') return null;
      
      const { primaryColor, secondaryColor } = coatOfArms.mantling;
      
      return (
        <g>
          <path
            d="M 20 20 Q 5 50 15 80 Q 25 110 10 140 L 45 130 Q 35 100 40 70 Q 45 40 50 20 Z"
            fill={primaryColor}
            stroke={secondaryColor}
            strokeWidth="2"
          />
          <path
            d="M 180 20 Q 195 50 185 80 Q 175 110 190 140 L 155 130 Q 165 100 160 70 Q 155 40 150 20 Z"
            fill={primaryColor}
            stroke={secondaryColor}
            strokeWidth="2"
          />
        </g>
      );
    };

    // Render supporters
    const renderSupporters = () => {
      return (
        <g>
          {leftSupporter && (
            <image
              href={leftSupporter}
              x="-70"
              y="60"
              width="90"
              height="120"
              preserveAspectRatio="xMidYMid meet"
              transform="scale(-1, 1) translate(-20, 0)"
              onLoad={() => setImageLoaded(true)}
            />
          )}
          {rightSupporter && (
            <image
              href={rightSupporter}
              x="180"
              y="60"
              width="90"
              height="120"
              preserveAspectRatio="xMidYMid meet"
              onLoad={() => setImageLoaded(true)}
            />
          )}
        </g>
      );
    };

    // Render crossed background
    const renderCrossedBackground = () => {
      if (!crossedBgImage) return null;
      
      const { opacity } = coatOfArms.crossedBackground;
      
      return (
        <image
          href={crossedBgImage}
          x="25"
          y="25"
          width="150"
          height="150"
          preserveAspectRatio="xMidYMid meet"
          opacity={opacity}
          onLoad={() => setImageLoaded(true)}
        />
      );
    };

    // Render helm
    const renderHelm = () => {
      if (!helmImage || coatOfArms.helm.type === 'none') return null;
      
      return (
        <image
          href={helmImage}
          x="70"
          y="-50"
          width="60"
          height="60"
          preserveAspectRatio="xMidYMid meet"
          onLoad={() => setImageLoaded(true)}
        />
      );
    };

    // Render crest
    const renderCrest = () => {
      if (!crestImage || coatOfArms.crest.type === 'none') return null;
      
      return (
        <image
          href={crestImage}
          x="80"
          y="-75"
          width="40"
          height="40"
          preserveAspectRatio="xMidYMid meet"
          onLoad={() => setImageLoaded(true)}
        />
      );
    };

    // Render central charge
    const renderCentralCharge = () => {
      if (!centralChargeImage) return null;
      
      const { position, scale } = coatOfArms.centralCharge;
      const x = (position.x / 100) * 200 - 40 * scale;
      const y = (position.y / 100) * 200 - 40 * scale;
      
      return (
        <image
          href={centralChargeImage}
          x={x}
          y={y}
          width={80 * scale}
          height={80 * scale}
          preserveAspectRatio="xMidYMid meet"
          onLoad={() => setImageLoaded(true)}
        />
      );
    };

    // Render upper charge
    const renderUpperCharge = () => {
      if (!upperChargeImage || coatOfArms.upperCharge.type === 'none') return null;
      
      const { scale } = coatOfArms.upperCharge;
      
      return (
        <image
          href={upperChargeImage}
          x={50}
          y="5"
          width={100 * scale}
          height={30 * scale}
          preserveAspectRatio="xMidYMid meet"
          onLoad={() => setImageLoaded(true)}
        />
      );
    };

    // Render lower charge
    const renderLowerCharge = () => {
      if (!lowerChargeImage || coatOfArms.lowerCharge.type === 'none') return null;
      
      const { scale } = coatOfArms.lowerCharge;
      
      return (
        <image
          href={lowerChargeImage}
          x={50}
          y="165"
          width={100 * scale}
          height={30 * scale}
          preserveAspectRatio="xMidYMid meet"
          onLoad={() => setImageLoaded(true)}
        />
      );
    };

    // Render motto with different styles
    const renderMotto = () => {
      if (!coatOfArms.motto.text) return null;
      
      const { style, color, text, backgroundColor } = coatOfArms.motto;
      
      switch (style) {
        case 'simple':
          return (
            <g transform="translate(100, 220)">
              <text
                x="0"
                y="0"
                textAnchor="middle"
                fill={color}
                fontSize="14"
                fontFamily="serif"
                fontWeight="bold"
              >
                {text}
              </text>
            </g>
          );
        case 'ribbon':
          return (
            <g transform="translate(100, 215)">
              <path
                d="M -90 0 Q -90 -15 0 -15 Q 90 -15 90 0 Q 90 20 0 20 Q -90 20 -90 0"
                fill={backgroundColor}
                stroke={color}
                strokeWidth="2"
              />
              <text
                x="0"
                y="5"
                textAnchor="middle"
                fill={color}
                fontSize="12"
                fontFamily="serif"
                fontWeight="bold"
              >
                {text}
              </text>
            </g>
          );
        case 'banner':
          return (
            <g transform="translate(100, 215)">
              <rect x="-85" y="-12" width="170" height="28" rx="4" fill={backgroundColor} stroke={color} strokeWidth="2" />
              <rect x="-90" y="-8" width="10" height="20" fill={color} />
              <rect x="80" y="-8" width="10" height="20" fill={color} />
              <text
                x="0"
                y="5"
                textAnchor="middle"
                fill={color}
                fontSize="11"
                fontFamily="serif"
                fontWeight="bold"
              >
                {text}
              </text>
            </g>
          );
        case 'scroll':
          return (
            <g transform="translate(100, 215)">
              <path
                d="M -85 -10 Q -95 -5 -85 0 Q -95 5 -85 10 L 85 10 Q 95 5 85 0 Q 95 -5 85 -10 Z"
                fill={backgroundColor}
                stroke={color}
                strokeWidth="2"
              />
              <text
                x="0"
                y="4"
                textAnchor="middle"
                fill={color}
                fontSize="11"
                fontFamily="serif"
                fontWeight="bold"
              >
                {text}
              </text>
            </g>
          );
        case 'tribal':
          return (
            <g transform="translate(100, 215)">
              <path
                d="M -90 -15 L -80 -10 L -90 -5 L -80 0 L -90 5 L -80 10 L -90 15 L 90 15 L 80 10 L 90 5 L 80 0 L 90 -5 L 80 -10 L 90 -15 Z"
                fill={backgroundColor}
                stroke={color}
                strokeWidth="2"
              />
              <text
                x="0"
                y="5"
                textAnchor="middle"
                fill={color}
                fontSize="11"
                fontFamily="serif"
                fontWeight="bold"
              >
                {text}
              </text>
            </g>
          );
        case 'royal':
          return (
            <g transform="translate(100, 215)">
              <path
                d="M -85 -12 L -70 -18 L -55 -12 L -40 -18 L -25 -12 L 0 -18 L 25 -12 L 40 -18 L 55 -12 L 70 -18 L 85 -12 L 85 15 L -85 15 Z"
                fill={backgroundColor}
                stroke={color}
                strokeWidth="2"
              />
              <text
                x="0"
                y="5"
                textAnchor="middle"
                fill={color}
                fontSize="11"
                fontFamily="serif"
                fontWeight="bold"
              >
                {text}
              </text>
            </g>
          );
        case 'ornate':
          return (
            <g transform="translate(100, 215)">
              <ellipse cx="0" cy="0" rx="90" ry="18" fill={backgroundColor} stroke={color} strokeWidth="2" />
              <ellipse cx="0" cy="0" rx="80" ry="12" fill="none" stroke={color} strokeWidth="1" strokeDasharray="4,2" />
              <text
                x="0"
                y="5"
                textAnchor="middle"
                fill={color}
                fontSize="11"
                fontFamily="serif"
                fontWeight="bold"
              >
                {text}
              </text>
            </g>
          );
        case 'shield':
          return (
            <g transform="translate(100, 215)">
              <path
                d="M -70 -10 L 70 -10 L 70 5 Q 70 18 0 22 Q -70 18 -70 5 Z"
                fill={backgroundColor}
                stroke={color}
                strokeWidth="2"
              />
              <text
                x="0"
                y="8"
                textAnchor="middle"
                fill={color}
                fontSize="10"
                fontFamily="serif"
                fontWeight="bold"
              >
                {text}
              </text>
            </g>
          );
        default:
          return null;
      }
    };

    return (
      <svg
        ref={ref}
        width={width}
        height={height}
        viewBox="-80 -90 360 340"
        className={className}
        xmlns="http://www.w3.org/2000/svg"
      >
        <defs>
          <clipPath id="shield-clip">
            <path d={shieldPath} />
          </clipPath>
          <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
            <feDropShadow dx="2" dy="2" stdDeviation="3" floodOpacity="0.5" />
          </filter>
          <linearGradient id="metal-gradient" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#e8e8e8" />
            <stop offset="50%" stopColor="#a0a0a0" />
            <stop offset="100%" stopColor="#606060" />
          </linearGradient>
        </defs>
        
        <g filter="url(#shadow)">
          {/* Supporters (behind shield) */}
          {renderSupporters()}
          
          {/* Mantling (behind shield) */}
          {renderMantling()}
          
          {/* Helm */}
          {renderHelm()}
          
          {/* Crest */}
          {renderCrest()}
          
          {/* Shield with field */}
          <g>
            {/* Field pattern clipped to shield */}
            <g clipPath="url(#shield-clip)">
              {renderFieldPattern()}
              
              {/* Crossed background inside shield */}
              {renderCrossedBackground()}
              
              {/* Upper charge */}
              {renderUpperCharge()}
              
              {/* Central charge */}
              {renderCentralCharge()}
              
              {/* Lower charge */}
              {renderLowerCharge()}
            </g>
            
            {/* Shield outline with customizable border */}
            <path 
              d={shieldPath}
              fill="none"
              stroke={coatOfArms.shield.borderColor}
              strokeWidth={coatOfArms.shield.borderWidth}
            />
            
            {/* Bordure if selected */}
            {coatOfArms.centralCharge.type === 'bordure' && (
              <path 
                d={shieldPath}
                fill="none"
                stroke={coatOfArms.centralCharge.color}
                strokeWidth="8"
              />
            )}
          </g>
          
          {/* Motto */}
          {renderMotto()}
        </g>
      </svg>
    );
  }
);

CoatOfArmsSVG.displayName = 'CoatOfArmsSVG';

export default CoatOfArmsSVG;
