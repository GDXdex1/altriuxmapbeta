import type { Season } from './types';

/**
 * Calculate current season based on month and hemisphere
 * Game year = 14 months, numbered 1-14
 * 1 real week = 1 game month (28 days)
 * 1 real week × 14 months = 14 weeks real time = 1 game year (392 game days)
 * 
 * Season logic:
 * - Equatorial zone (-10° to +10°): Only winter and summer, alternating
 * - Subpolar zones (beyond ±10°): All four seasons with hemispheric opposition
 *   When it's winter in north, it's summer in south (and vice versa)
 */

export interface SeasonInfo {
  season: Season;
  hemisphere: 'northern' | 'southern' | 'equatorial';
}

/**
 * Get season for a tile based on month (1-14) and latitude
 */
export function getSeasonForTile(monthNumber: number, latitude: number): SeasonInfo {
  const absLat = Math.abs(latitude);
  const isNorthern = latitude > 10;
  const isSouthern = latitude < -10;
  const isEquatorial = absLat <= 10;
  
  // Equatorial zone: Only winter and summer (alternating every 7 months)
  if (isEquatorial) {
    // Months 1-7: Summer, Months 8-14: Winter
    const season: Season = monthNumber <= 7 ? 'summer' : 'winter';
    return { season, hemisphere: 'equatorial' };
  }
  
  // Subpolar zones: Four seasons
  // Northern hemisphere: Months 1-14 cycle through spring → summer → autumn → winter
  // Southern hemisphere: Opposite (when north has winter, south has summer)
  
  if (isNorthern) {
    // Northern hemisphere seasons
    if (monthNumber <= 3) {
      return { season: 'winter', hemisphere: 'northern' };
    } else if (monthNumber <= 7) {
      return { season: 'spring', hemisphere: 'northern' };
    } else if (monthNumber <= 10) {
      return { season: 'summer', hemisphere: 'northern' };
    } else {
      return { season: 'autumn', hemisphere: 'northern' };
    }
  }
  
  if (isSouthern) {
    // Southern hemisphere: opposite seasons
    if (monthNumber <= 3) {
      return { season: 'summer', hemisphere: 'southern' };
    } else if (monthNumber <= 7) {
      return { season: 'autumn', hemisphere: 'southern' };
    } else if (monthNumber <= 10) {
      return { season: 'winter', hemisphere: 'southern' };
    } else {
      return { season: 'spring', hemisphere: 'southern' };
    }
  }
  
  // Fallback (shouldn't reach here)
  return { season: 'spring', hemisphere: 'northern' };
}

/**
 * Get season name in a readable format
 */
export function formatSeason(season: Season): string {
  const names: Record<Season, string> = {
    winter: 'Winter',
    spring: 'Spring',
    summer: 'Summer',
    autumn: 'Autumn'
  };
  return names[season];
}

/**
 * Get dominant season for northern hemisphere based on month
 */
export function getNorthernSeasonByMonth(monthNumber: number): Season {
  if (monthNumber <= 3) return 'winter';
  if (monthNumber <= 7) return 'spring';
  if (monthNumber <= 10) return 'summer';
  return 'autumn';
}

/**
 * Get dominant season for southern hemisphere based on month
 */
export function getSouthernSeasonByMonth(monthNumber: number): Season {
  if (monthNumber <= 3) return 'summer';
  if (monthNumber <= 7) return 'autumn';
  if (monthNumber <= 10) return 'winter';
  return 'spring';
}
