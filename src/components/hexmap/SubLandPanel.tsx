'use client';

import type { ReactElement } from 'react';
import { useState, useEffect } from 'react';
import { X, Navigation, Clock, MapPin } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import type { SubLand } from '@/lib/sublands/types';
import { useRouter } from 'next/navigation';
import { findSubLandPath } from '@/lib/hexmap/subland-pathfinding';
import { calculateSubLandTravel } from '@/lib/travel-calculator';

interface SubLandPanelProps {
  subland: SubLand;
  parentQ: number;
  parentR: number;
  onClose: () => void;
  playerPosition: { q: number; r: number } | null;
  onNavigate: (q: number, r: number) => void;
  onStartTravel?: (destination: { q: number; r: number }) => void;
  isCurrentlyTraveling?: boolean;
  sublands?: SubLand[]; // All sublands for terrain/biome data
}

export function SubLandPanel({ 
  subland, 
  parentQ, 
  parentR, 
  onClose,
  playerPosition,
  onNavigate,
  onStartTravel,
  isCurrentlyTraveling = false,
  sublands = []
}: SubLandPanelProps): ReactElement {
  const router = useRouter();
  
  const isPlayerHere = playerPosition?.q === subland.q && playerPosition?.r === subland.r;
  
  // Calculate travel info with terrain costs
  const [travelInfo, setTravelInfo] = useState<{
    timeHours: number;
    timeDays: number;
    distance: number;
    pathLength: number;
  } | null>(null);
  
  useEffect(() => {
    if (!playerPosition || isPlayerHere) {
      setTravelInfo(null);
      return;
    }
    
    try {
      // Calculate path using A*
      const path = findSubLandPath(playerPosition, { q: subland.q, r: subland.r });
      
      if (!path || path.length === 0) {
        setTravelInfo(null);
        return;
      }
      
      // Build biome and feature maps
      const biomeMap = new Map<string, string>();
      const featureMap = new Map<string, string[]>();
      
      for (const hex of path) {
        const sl = sublands.find(s => s.q === hex.q && s.r === hex.r);
        if (sl) {
          const hexKey = `${hex.q},${hex.r}`;
          biomeMap.set(hexKey, sl.biomeType);
          // For now, features are empty - can be extended later
          featureMap.set(hexKey, []);
        }
      }
      
      // Calculate travel time with terrain costs
      const travelCalc = calculateSubLandTravel(path, biomeMap, featureMap);
      const distance = calculateDistance(playerPosition.q, playerPosition.r, subland.q, subland.r);
      
      setTravelInfo({
        timeHours: travelCalc.totalTravelTimeHours,
        timeDays: travelCalc.totalTravelTimeHours / 24,
        distance,
        pathLength: path.length - 1
      });
    } catch (error) {
      console.error('Error calculating travel info:', error);
      setTravelInfo(null);
    }
  }, [playerPosition, subland, isPlayerHere, sublands]);
  
  const handleNavigateToXLand = (): void => {
    // Navigate to xLand overview page for this specific 1km hexagon
    router.push(`/xland-overview/${parentQ}/${parentR}/${subland.q}/${subland.r}`);
  };
  
  return (
    <Card className="absolute top-14 right-4 w-80 lg:w-96 z-40 bg-black/95 backdrop-blur-sm border-amber-500/50 max-h-[70vh] overflow-y-auto">
      <div className="p-3">
        <button
          onClick={onClose}
          className="absolute top-2 right-2 text-white/70 hover:text-white"
        >
          <X className="w-4 h-4" />
        </button>
        
        <h3 className="text-amber-400 font-bold text-sm mb-2">xLand (1km × 1km)</h3>
        
        <div className="space-y-2 text-xs">
          <div className="flex justify-between">
            <span className="text-white/70">Position:</span>
            <span className="text-white">({subland.q}, {subland.r})</span>
          </div>
          
          <div className="flex justify-between">
            <span className="text-white/70">Parent Duchy:</span>
            <span className="text-amber-300">({parentQ}, {parentR})</span>
          </div>
          
          <div className="flex justify-between">
            <span className="text-white/70">Biome:</span>
            <span className="text-green-300 capitalize">{subland.biomeType}</span>
          </div>
          
          <div className="flex justify-between">
            <span className="text-white/70">Resource:</span>
            <span className="text-blue-300">{getResourceName(subland.resourceType)}</span>
          </div>
          
          {isPlayerHere && (
            <div className="bg-green-500/20 p-2 rounded border border-green-500/50">
              <p className="text-green-300 text-xs font-bold">📍 You are here</p>
            </div>
          )}
          
          {!isPlayerHere && travelInfo !== null && (
            <div className="bg-blue-500/20 p-2 rounded border border-blue-500/50">
              <div className="flex items-center gap-1 mb-1">
                <Clock className="w-3 h-3 text-blue-400" />
                <p className="text-blue-300 text-xs font-semibold">
                  Travel Time
                </p>
              </div>
              <div className="space-y-1 text-[10px]">
                <div className="flex justify-between">
                  <span className="text-blue-200">Time:</span>
                  <span className="text-white font-bold">{formatTravelTime(travelInfo.timeHours)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-blue-200">Distance:</span>
                  <span className="text-white">{travelInfo.distance} hex ({travelInfo.pathLength} km)</span>
                </div>
                <div className="text-blue-100/60 italic">
                  * Terrain affects travel speed
                </div>
              </div>
            </div>
          )}
        </div>
        
        <div className="mt-3 space-y-2">
          {isPlayerHere ? (
            <Button
              onClick={handleNavigateToXLand}
              className="w-full bg-gradient-to-r from-purple-600 to-indigo-600 text-xs h-8"
            >
              🔍 Enter xLand Overview
            </Button>
          ) : (
            <>
              {isCurrentlyTraveling ? (
                <Button
                  disabled
                  className="w-full bg-gray-600 text-xs h-8 cursor-not-allowed"
                >
                  🚶 Already Traveling
                </Button>
              ) : (
                <Button
                  onClick={() => onStartTravel && onStartTravel({ q: subland.q, r: subland.r })}
                  className="w-full bg-gradient-to-r from-blue-600 to-cyan-600 text-xs h-8"
                >
                  <Navigation className="w-3 h-3 mr-1" />
                  Travel Here
                </Button>
              )}
            </>
          )}
        </div>
      </div>
    </Card>
  );
}

function getResourceName(resourceType: string): string {
  if (resourceType === 'standard') return 'Standard Land';
  if (resourceType === 'coastal_land') return 'Coastal Land';
  if (resourceType === 'coastal_inland') return 'Coastal Inland';
  if (resourceType.startsWith('mine_')) {
    const mineral = resourceType.split('_')[1];
    return `${mineral.charAt(0).toUpperCase()}${mineral.slice(1)} Mine`;
  }
  if (resourceType.startsWith('farmland_')) {
    const crop = resourceType.split('_')[1];
    return `${crop.charAt(0).toUpperCase()}${crop.slice(1)} Farmland`;
  }
  return resourceType;
}

function calculateDistance(q1: number, r1: number, q2: number, r2: number): number {
  // Hexagonal distance calculation
  return (Math.abs(q1 - q2) + Math.abs(r1 - r2) + Math.abs((q1 + r1) - (q2 + r2))) / 2;
}

function formatTravelTime(hours: number): string {
  if (hours < 1) {
    return `${Math.round(hours * 60)} min`;
  } else if (hours < 24) {
    const h = Math.floor(hours);
    const m = Math.round((hours - h) * 60);
    return m > 0 ? `${h}h ${m}m` : `${h}h`;
  } else {
    const days = Math.floor(hours / 24);
    const remainingHours = Math.round(hours % 24);
    return remainingHours > 0 ? `${days}d ${remainingHours}h` : `${days}d`;
  }
}
