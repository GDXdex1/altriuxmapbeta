'use client';

import { createContext, useContext, useState, type ReactNode } from 'react';
import type { HexCoordinates } from '@/lib/hexmap/types';

export type TravelLevel = 'duchy' | 'subland' | null;

export interface DuchyTravel {
  id: string;
  level: 'duchy';
  origin: HexCoordinates;
  destination: HexCoordinates;
  path: HexCoordinates[];
  currentPosition: HexCoordinates;
  currentHexIndex: number;
  totalTravelTime: number; // in game days
  elapsedTime: number; // in game days
  startTime: Date;
  estimatedArrival: Date;
  terrainType: string;
}

export interface SublandTravel {
  id: string;
  level: 'subland';
  parentQ: number;
  parentR: number;
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

export type ActiveTravel = DuchyTravel | SublandTravel | null;

interface TravelContextType {
  activeTravel: ActiveTravel;
  startDuchyTravel: (travel: Omit<DuchyTravel, 'level'>) => void;
  startSublandTravel: (travel: Omit<SublandTravel, 'level'>) => void;
  updateTravel: (updater: (prev: ActiveTravel) => ActiveTravel) => void;
  cancelTravel: () => void;
}

const TravelContext = createContext<TravelContextType | undefined>(undefined);

export function TravelProvider({ children }: { children: ReactNode }): JSX.Element {
  const [activeTravel, setActiveTravel] = useState<ActiveTravel>(null);

  const startDuchyTravel = (travel: Omit<DuchyTravel, 'level'>): void => {
    // Cancel any existing travel (from any level)
    setActiveTravel({
      ...travel,
      level: 'duchy'
    });
  };

  const startSublandTravel = (travel: Omit<SublandTravel, 'level'>): void => {
    // Cancel any existing travel (from any level)
    setActiveTravel({
      ...travel,
      level: 'subland'
    });
  };

  const updateTravel = (updater: (prev: ActiveTravel) => ActiveTravel): void => {
    setActiveTravel(updater);
  };

  const cancelTravel = (): void => {
    setActiveTravel(null);
  };

  return (
    <TravelContext.Provider value={{
      activeTravel,
      startDuchyTravel,
      startSublandTravel,
      updateTravel,
      cancelTravel
    }}>
      {children}
    </TravelContext.Provider>
  );
}

export function useTravel(): TravelContextType {
  const context = useContext(TravelContext);
  if (context === undefined) {
    throw new Error('useTravel must be used within a TravelProvider');
  }
  return context;
}
