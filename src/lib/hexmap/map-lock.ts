/**
 * Map Lock System
 * Prevents automatic map regeneration to preserve manual edits
 */

const MAP_LOCK_KEY = 'altriux_map_locked';
const MAP_SEED_KEY = 'altriux_map_seed';

/**
 * Check if the map is locked (prevents automatic regeneration)
 */
export function isMapLocked(): boolean {
    try {
        const locked = localStorage.getItem(MAP_LOCK_KEY);
        return locked === 'true';
    } catch (error) {
        console.error('Error checking map lock:', error);
        return false;
    }
}

/**
 * Lock the map to prevent automatic regeneration
 */
export function lockMap(): void {
    try {
        localStorage.setItem(MAP_LOCK_KEY, 'true');
    } catch (error) {
        console.error('Error locking map:', error);
    }
}

/**
 * Unlock the map to allow automatic regeneration
 */
export function unlockMap(): void {
    try {
        localStorage.removeItem(MAP_LOCK_KEY);
    } catch (error) {
        console.error('Error unlocking map:', error);
    }
}

/**
 * Save the current map seed (when locking)
 */
export function saveMapSeed(seed: number): void {
    try {
        localStorage.setItem(MAP_SEED_KEY, seed.toString());
    } catch (error) {
        console.error('Error saving map seed:', error);
    }
}

/**
 * Get the saved map seed
 */
export function getSavedMapSeed(): number | null {
    try {
        const seed = localStorage.getItem(MAP_SEED_KEY);
        return seed ? parseInt(seed, 10) : null;
    } catch (error) {
        console.error('Error getting saved map seed:', error);
        return null;
    }
}

/**
 * Toggle map lock state
 */
export function toggleMapLock(): boolean {
    const currentState = isMapLocked();
    if (currentState) {
        unlockMap();
    } else {
        lockMap();
    }
    return !currentState;
}
