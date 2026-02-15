'use client';

import type { ReactElement } from 'react';
import { Card } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { Navigation, Clock, MapPin } from 'lucide-react';

interface DuchyTravelIndicatorProps {
  origin: { q: number; r: number };
  destination: { q: number; r: number };
  currentPosition: { q: number; r: number };
  path: Array<{ q: number; r: number }>;
  totalTravelTime: number; // in game days
  elapsedTime: number; // in game days
  currentHexIndex: number; // index in path array
  estimatedArrival: Date;
  terrainType: string;
}

export function DuchyTravelIndicator({
  origin,
  destination,
  currentPosition,
  path,
  totalTravelTime,
  elapsedTime,
  currentHexIndex,
  estimatedArrival,
  terrainType
}: DuchyTravelIndicatorProps): ReactElement {
  const progressPercentage = (elapsedTime / totalTravelTime) * 100;
  const remainingHexes = path.length - currentHexIndex - 1;
  const remainingTime = totalTravelTime - elapsedTime;
  
  // Format time remaining in game days
  const formatTimeRemaining = (days: number): string => {
    if (days < 1) {
      return `${Math.round(days * 24)}h`;
    } else {
      const wholeDays = Math.floor(days);
      const remainingHours = Math.round((days % 1) * 24);
      return remainingHours > 0 ? `${wholeDays}d ${remainingHours}h` : `${wholeDays}d`;
    }
  };
  
  return (
    <Card className="absolute top-20 left-4 w-80 z-30 bg-black/95 backdrop-blur-sm border-amber-500/50 shadow-xl">
      <div className="p-3">
        <div className="flex items-center gap-2 mb-3">
          <Navigation className="w-4 h-4 text-amber-400 animate-pulse" />
          <h3 className="text-amber-400 font-bold text-sm">Traveling Between Duchies...</h3>
        </div>
        
        <div className="space-y-3">
          {/* Progress Bar */}
          <div className="space-y-1">
            <div className="flex justify-between text-xs">
              <span className="text-white/70">Progress</span>
              <span className="text-amber-300 font-semibold">{Math.round(progressPercentage)}%</span>
            </div>
            <Progress 
              value={progressPercentage} 
              className="h-2 bg-slate-700"
            />
          </div>
          
          {/* Current Position */}
          <div className="bg-amber-500/10 p-2 rounded border border-amber-500/30">
            <div className="flex items-center gap-2 mb-1">
              <MapPin className="w-3 h-3 text-amber-400" />
              <span className="text-amber-300 text-xs font-semibold">Current Position</span>
            </div>
            <div className="text-white text-xs ml-5">
              <div>Duchy: ({currentPosition.q}, {currentPosition.r})</div>
              <div className="text-white/60 capitalize">Terrain: {terrainType}</div>
            </div>
          </div>
          
          {/* Route Info */}
          <div className="grid grid-cols-2 gap-2 text-xs">
            <div className="bg-slate-800/50 p-2 rounded">
              <div className="text-white/60 text-[10px]">Origin</div>
              <div className="text-white font-mono">({origin.q}, {origin.r})</div>
            </div>
            <div className="bg-slate-800/50 p-2 rounded">
              <div className="text-white/60 text-[10px]">Destination</div>
              <div className="text-white font-mono">({destination.q}, {destination.r})</div>
            </div>
          </div>
          
          {/* Time Info */}
          <div className="flex items-center justify-between text-xs bg-slate-800/50 p-2 rounded">
            <div className="flex items-center gap-1">
              <Clock className="w-3 h-3 text-amber-400" />
              <span className="text-white/70">Remaining:</span>
            </div>
            <span className="text-amber-300 font-semibold">{formatTimeRemaining(remainingTime)}</span>
          </div>
          
          {/* Duchies Remaining */}
          <div className="flex justify-between text-xs">
            <span className="text-white/70">Duchies remaining:</span>
            <span className="text-white font-semibold">{remainingHexes} / {path.length - 1}</span>
          </div>
          
          {/* Estimated Arrival */}
          <div className="bg-green-500/10 p-2 rounded border border-green-500/30 text-xs">
            <div className="text-green-300 font-semibold">Estimated Arrival</div>
            <div className="text-green-200 text-[10px] mt-1">
              {estimatedArrival.toLocaleString('en-US', {
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
              })}
            </div>
          </div>
        </div>
      </div>
    </Card>
  );
}
