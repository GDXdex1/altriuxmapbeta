'use client';

import React from 'react';
import type { HexTile } from '@/lib/hexmap/types';
import type { HexCoordinates } from '@/lib/hexmap/types';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { Navigation, MapPin, Clock, Route, X, AlertTriangle } from 'lucide-react';

interface TravelPanelProps {
  startTile: HexTile;
  endTile: HexTile | null;
  path: HexCoordinates[] | null;
  travelTime: number;
  terrainSummary: Record<string, number>;
  onClose: () => void;
  onClearDestination: () => void;
}

const TERRAIN_DISPLAY: Record<string, { name: string; color: string; icon: string }> = {
  plains: { name: 'Plains', color: 'bg-green-500', icon: '🌾' },
  meadow: { name: 'Meadow', color: 'bg-green-400', icon: '🌸' },
  hills: { name: 'Hills', color: 'bg-yellow-600', icon: '⛰️' },
  mountain: { name: 'Mountain', color: 'bg-gray-600', icon: '🏔️' },
  desert: { name: 'Desert', color: 'bg-yellow-400', icon: '🏜️' },
  tundra: { name: 'Tundra', color: 'bg-blue-200', icon: '❄️' },
  forest: { name: 'Forest', color: 'bg-green-700', icon: '🌲' },
  jungle: { name: 'Jungle', color: 'bg-green-900', icon: '🌴' },
  ocean: { name: 'Ocean', color: 'bg-blue-600', icon: '🌊' },
  coast: { name: 'Coast', color: 'bg-blue-400', icon: '🏖️' },
  ice: { name: 'Ice', color: 'bg-cyan-100', icon: '🧊' }
};

export function TravelPanel({
  startTile,
  endTile,
  path,
  travelTime,
  terrainSummary,
  onClose,
  onClearDestination
}: TravelPanelProps): JSX.Element {
  const startCoords = startTile.coordinates;
  const endCoords = endTile?.coordinates;

  // Calculate distance
  const distance = path ? path.length - 1 : 0;

  return (
    <Card className="fixed top-20 left-4 w-96 max-h-[calc(100vh-120px)] overflow-y-auto z-20 bg-black/90 text-white border-2 border-amber-500/50 shadow-xl">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2 text-xl">
            <Route className="w-5 h-5 text-amber-400" />
            Travel Route
          </CardTitle>
          <Button
            variant="ghost"
            size="icon"
            onClick={onClose}
            className="text-white hover:bg-amber-500/20"
          >
            <X className="w-4 h-4" />
          </Button>
        </div>
      </CardHeader>

      <CardContent className="space-y-4">
        {/* Origin */}
        <div className="space-y-2">
          <div className="flex items-center gap-2 text-sm font-semibold text-amber-400">
            <MapPin className="w-4 h-4" />
            Origin
          </div>
          <div className="ml-6 text-sm">
            <div>Coordinates: Q: {startCoords.q}, R: {startCoords.r}</div>
            <div>Terrain: {TERRAIN_DISPLAY[startTile.terrain]?.icon} {TERRAIN_DISPLAY[startTile.terrain]?.name}</div>
          </div>
        </div>

        <Separator className="bg-amber-500/30" />

        {/* Destination */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 text-sm font-semibold text-amber-400">
              <Navigation className="w-4 h-4" />
              Destination
            </div>
            {endTile && (
              <Button
                variant="ghost"
                size="sm"
                onClick={onClearDestination}
                className="text-xs text-red-400 hover:text-red-300 hover:bg-red-500/20"
              >
                Clear
              </Button>
            )}
          </div>
          
          {endTile && endCoords ? (
            <div className="ml-6 text-sm">
              <div>Coordinates: Q: {endCoords.q}, R: {endCoords.r}</div>
              <div>Terrain: {TERRAIN_DISPLAY[endTile.terrain]?.icon} {TERRAIN_DISPLAY[endTile.terrain]?.name}</div>
            </div>
          ) : (
            <div className="ml-6 text-sm text-gray-400 italic">
              Click on a hex to set destination
            </div>
          )}
        </div>

        {/* Route Information */}
        {path && path.length > 0 ? (
          <>
            <Separator className="bg-amber-500/30" />
            
            <div className="space-y-3">
              <div className="flex items-center gap-2 text-sm font-semibold text-amber-400">
                <Clock className="w-4 h-4" />
                Route Details
              </div>
              
              <div className="ml-6 space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-300">Distance:</span>
                  <span className="font-semibold">{distance} hexes</span>
                </div>
                
                <div className="flex justify-between text-sm">
                  <span className="text-gray-300">Travel Time:</span>
                  <span className="font-semibold">{travelTime.toFixed(1)} game days</span>
                </div>
                
                <div className="flex justify-between text-sm">
                  <span className="text-gray-300">Real Time:</span>
                  <span className="font-semibold">{(travelTime / 4).toFixed(2)} days</span>
                </div>
              </div>
            </div>

            <Separator className="bg-amber-500/30" />

            {/* Terrain Summary */}
            <div className="space-y-3">
              <div className="text-sm font-semibold text-amber-400">
                Terrain Along Route
              </div>
              
              <div className="space-y-2">
                {Object.entries(terrainSummary).map(([terrain, count]) => {
                  const displayInfo = TERRAIN_DISPLAY[terrain];
                  if (!displayInfo) return null;
                  
                  const percentage = ((count / distance) * 100).toFixed(0);
                  
                  return (
                    <div key={terrain} className="flex items-center justify-between text-sm">
                      <div className="flex items-center gap-2">
                        <span>{displayInfo.icon}</span>
                        <span className="text-gray-300">{displayInfo.name}</span>
                      </div>
                      <Badge variant="outline" className="bg-amber-900/30 text-amber-200 border-amber-500/50">
                        {count} ({percentage}%)
                      </Badge>
                    </div>
                  );
                })}
              </div>
            </div>
          </>
        ) : endTile && !path ? (
          <>
            <Separator className="bg-amber-500/30" />
            <div className="flex items-center gap-2 p-3 bg-red-900/30 border border-red-500/50 rounded-md">
              <AlertTriangle className="w-5 h-5 text-red-400 flex-shrink-0" />
              <div className="text-sm text-red-200">
                <div className="font-semibold">No path available!</div>
                <div className="text-xs mt-1">
                  The destination is unreachable by foot. You may need a ship to cross water.
                </div>
              </div>
            </div>
          </>
        ) : null}

        {/* Tips */}
        <Separator className="bg-amber-500/30" />
        <div className="text-xs text-gray-400 space-y-1">
          <div>💡 <span className="font-semibold">Tip:</span> Mountains and forests slow travel</div>
          <div>💡 <span className="font-semibold">Tip:</span> Water cannot be crossed on foot</div>
          <div>💡 <span className="font-semibold">Tip:</span> Click any hex to set as destination</div>
        </div>
      </CardContent>
    </Card>
  );
}
