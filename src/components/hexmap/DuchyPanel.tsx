'use client';

import { useState } from 'react';
import Link from 'next/link';
import { X, Navigation, Eye, Crown, Building } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import type { HexTile as HexTileType } from '@/lib/hexmap/types';
import type { DuchyInfo, TransportItem, TravelCalculation } from '@/types/game';
import { generateDuchyInfo } from '@/lib/duchy-generator';
import { calculateTravel, TRANSPORT_OPTIONS } from '@/lib/travel-calculator';
import { getOceanNeighborSides } from '@/lib/hexmap/generator';

interface DuchyPanelProps {
  tile: HexTileType;
  tiles: Map<string, HexTileType>;
  onClose: () => void;
  currentPlayerLocation: { q: number; r: number };
  serverTime: Date;
  currentMonth: number;
  onStartTravel?: (tile: HexTileType) => void;
  onStartDuchyTravel?: (destination: { q: number; r: number }) => void;
  isCurrentlyTraveling?: boolean;
}

// Medieval/Tribal icons consistent with HexTile
const RESOURCE_ICONS: Record<string, string> = {
  // Food Resources (Animals)
  horses: '◈', sheep: '⌇', buffalo: '⟐', muffon: '⟁', yaks: '⟡', camels: '⟢',
  // Minerals
  gold: '◉', silver: '◎', iron: '⬢', tin: '▽', bronze: '△',
  copper: '◇', stone: '◆', gems: '✦',
  // Natural Resources
  wood: '⚶', fish: '≋', whales: '≈', crabs: '⋈',
  wheat: '⚘', cotton: '✿', spices: '✤', legumes: '⚇', flax: '⚘', corn: '⚘', dates: '◐'
};

export function DuchyPanel({ tile, tiles, onClose, currentPlayerLocation, serverTime, currentMonth, onStartTravel, onStartDuchyTravel, isCurrentlyTraveling }: DuchyPanelProps): JSX.Element {
  const [view, setView] = useState<'info' | 'travel' | 'overview'>('info');
  const [selectedTransport, setSelectedTransport] = useState<string>(TRANSPORT_OPTIONS[0].id);

  const duchyInfo: DuchyInfo = generateDuchyInfo(tile.coordinates.q, tile.coordinates.r);
  
  // Calculate travel if in travel view
  const transport = TRANSPORT_OPTIONS.find((t) => t.id === selectedTransport) || TRANSPORT_OPTIONS[0];
  const travelCalc: TravelCalculation | null = view === 'travel' 
    ? calculateTravel(
        currentPlayerLocation.q,
        currentPlayerLocation.r,
        tile.coordinates.q,
        tile.coordinates.r,
        transport,
        serverTime
      )
    : null;

  const isCurrentLocation = 
    currentPlayerLocation.q === tile.coordinates.q && 
    currentPlayerLocation.r === tile.coordinates.r;
  
  // Calculate travel info for this duchy
  const { findPath, calculatePathTravelTime } = require('@/lib/hexmap/pathfinding');
  const travelPath = !isCurrentLocation && onStartDuchyTravel 
    ? findPath(currentPlayerLocation, tile.coordinates, tiles)
    : null;
  // Duchy Lands are 50km per hexagon, and travel is 100x slower than SubLands
  // In SubLands: 50 hexagons (1km each) per day = 50km/day
  // In Duchy Lands: 0.5 hexagons (50km each) per day = 25km/day effective (100x slower than SubLands per hexagon)
  const travelTime = travelPath ? calculatePathTravelTime(travelPath, tiles, 0.5) : 0; // 0.5 duchies per day (100x slower)
  const travelDistanceKm = travelPath ? (travelPath.length - 1) * 50 : 0; // Each duchy is 50km

  // Format travel time
  const formatTravelTime = (days: number): string => {
    if (days < 1) {
      return `${Math.round(days * 24)}h`;
    } else {
      const wholeDays = Math.floor(days);
      const remainingHours = Math.round((days % 1) * 24);
      return remainingHours > 0 ? `${wholeDays}d ${remainingHours}h` : `${wholeDays}d`;
    }
  };

  return (
    <Card className="absolute top-16 left-2 md:left-4 z-20 bg-gradient-to-br from-blue-900/95 to-purple-900/95 backdrop-blur-sm border-2 border-blue-400 max-w-md w-full max-h-[80vh] overflow-y-auto">
      {/* Header */}
      <div className="sticky top-0 bg-gradient-to-r from-blue-800 to-purple-800 p-4 border-b border-blue-400/30">
        <button
          onClick={onClose}
          className="absolute top-2 right-2 text-white/70 hover:text-white text-2xl leading-none px-2 hover:bg-white/10 rounded transition-colors"
        >
          <X className="w-5 h-5" />
        </button>
        
        <div className="pr-8">
          <h3 className="text-xl font-bold text-white mb-1">{duchyInfo.name}</h3>
          <div className="flex items-center gap-2">
            {tile.terrain !== 'ocean' && tile.terrain !== 'coast' && (
              <Badge className="bg-cyan-500/20 text-cyan-300 border-cyan-500/30 text-xs">
                NFT Land Duchy
              </Badge>
            )}
            {isCurrentLocation && (
              <Badge className="bg-green-500/20 text-green-300 border-green-500/30 text-xs">
                📍 Your Location
              </Badge>
            )}
          </div>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="flex border-b border-white/10">
        <button
          onClick={() => setView('info')}
          className={`flex-1 px-4 py-3 text-sm font-semibold transition-colors ${
            view === 'info'
              ? 'bg-blue-600/50 text-white border-b-2 border-blue-400'
              : 'text-white/70 hover:text-white hover:bg-white/5'
          }`}
        >
          <Eye className="w-4 h-4 inline mr-2" />
          Info
        </button>
        <button
          onClick={() => setView('travel')}
          disabled={isCurrentLocation}
          className={`flex-1 px-4 py-3 text-sm font-semibold transition-colors ${
            view === 'travel'
              ? 'bg-blue-600/50 text-white border-b-2 border-blue-400'
              : isCurrentLocation
              ? 'text-white/30 cursor-not-allowed'
              : 'text-white/70 hover:text-white hover:bg-white/5'
          }`}
        >
          <Navigation className="w-4 h-4 inline mr-2" />
          Travel
        </button>
        <button
          onClick={() => setView('overview')}
          className={`flex-1 px-4 py-3 text-sm font-semibold transition-colors ${
            view === 'overview'
              ? 'bg-blue-600/50 text-white border-b-2 border-blue-400'
              : 'text-white/70 hover:text-white hover:bg-white/5'
          }`}
        >
          <Building className="w-4 h-4 inline mr-2" />
          Overview
        </button>
      </div>

      {/* Content */}
      <div className="p-4 space-y-3">
        {view === 'info' && (
          <>
            <div className="space-y-2 text-xs md:text-sm text-white/90">
              <div className="flex items-center justify-between py-1 border-b border-white/20">
                <span className="text-white/70">Terrain</span>
                <span className="font-semibold text-cyan-300 capitalize">
                  {tile.terrain === 'ocean' ? '🌊' : 
                   tile.terrain === 'coast' ? '🏖️' :
                   tile.terrain === 'ice' ? '🧊' :
                   tile.terrain === 'plains' ? '🌾' : 
                   tile.terrain === 'jungle' ? '🌴' : 
                   tile.terrain === 'forest' ? '🌲' : 
                   tile.terrain === 'mountain' ? '⛰️' : 
                   tile.terrain === 'tundra' ? '❄️' : '🏜️'} {tile.terrain}
                </span>
              </div>
              
              <div className="flex items-center justify-between py-1 border-b border-white/20">
                <span className="text-white/70">Coordinates (Q, R)</span>
                <span className="font-semibold text-cyan-300">({tile.coordinates.q}, {tile.coordinates.r})</span>
              </div>
              
              <div className="flex items-center justify-between py-1 border-b border-white/20">
                <span className="text-white/70">Grid Position (X, Y)</span>
                <span className="font-semibold text-cyan-300">({tile.coordinates.x}, {tile.coordinates.y})</span>
              </div>
              
              <div className="flex items-center justify-between py-1 border-b border-white/20">
                <span className="text-white/70">Latitude</span>
                <span className="font-semibold text-cyan-300">{tile.latitude.toFixed(1)}°</span>
              </div>
              
              <div className="flex items-center justify-between py-1 border-b border-white/20">
                <span className="text-white/70">Season</span>
                <span className="font-semibold text-cyan-300 capitalize">{tile.season}</span>
              </div>
              
              {tile.hasVolcano && (
                <div className="py-2 px-3 bg-red-500/30 rounded border border-red-500/50">
                  <p className="font-semibold text-red-200 text-xs md:text-sm">🌋 Active Volcano</p>
                </div>
              )}
              
              {tile.hasRiver && (
                <div className="py-2 px-3 bg-blue-500/30 rounded border border-blue-500/50">
                  <p className="font-semibold text-blue-200 text-xs md:text-sm">🌊 Has River</p>
                  <p className="text-blue-100/80 text-xs mt-1">
                    {tile.elevation < 2 && tile.terrain === 'coast' 
                      ? '🚢 Navigable River - Large river reaching the sea. Can build shipyards and river ports for trade and transport.'
                      : '💧 Non-Navigable River - Smaller river or stream. Can build water mills and sawmills for resource processing.'}
                  </p>
                </div>
              )}
              
              {tile.continent && (
                <div className="flex items-center justify-between py-1">
                  <span className="text-white/70">Continent</span>
                  <span className="font-semibold text-green-300 capitalize">
                    {tile.continent === 'drantium' ? '🌴 Drantium (West)' : '🌲 Brontium (East)'}
                  </span>
                </div>
              )}
              
              {/* Polar Regions */}
              {(tile.terrain === 'tundra' || tile.terrain === 'ice') && Math.abs(tile.latitude) > 70 && (
                <div className="flex items-center justify-between py-1">
                  <span className="text-white/70">Polar Region</span>
                  <span className="font-semibold text-cyan-300">
                    {tile.latitude > 0 ? '❄️ Noix (North Pole)' : '❄️ Soix (South Pole)'}
                  </span>
                </div>
              )}
              
              {/* Coastal or Continental Tile */}
              {tile.terrain !== 'ocean' && tile.terrain !== 'ice' && (
                <div className="flex items-center justify-between py-1 border-b border-white/20">
                  <span className="text-white/70">Location Type</span>
                  <span className="font-semibold text-blue-300">
                    {(() => {
                      // Casillas coast son automáticamente costeras
                      if (tile.terrain === 'coast') {
                        return '🌊 Coastal Tile';
                      }
                      // Para otras casillas de tierra, verificar vecinos ocean/coast
                      const oceanSides = getOceanNeighborSides(tile, tiles);
                      const hasOceanNeighbor = oceanSides.length > 0;
                      return hasOceanNeighbor ? '🌊 Coastal Tile' : '🏔️ Continental Tile';
                    })()}
                  </span>
                </div>
              )}
              
              {/* Terrain Features */}
              {tile.features && tile.features.length > 0 && (
                <div className="mt-2 p-2 bg-amber-500/20 rounded border border-amber-500/50">
                  <p className="font-semibold text-amber-300 text-xs md:text-sm mb-1">✨ Terrain Features</p>
                  <div className="flex flex-wrap gap-1">
                    {tile.features.map((feature, idx) => (
                      <span key={idx} className="text-xs bg-amber-600/40 px-2 py-0.5 rounded text-amber-100 capitalize">
                        {feature === 'forest' ? '🌲 Forest' :
                         feature === 'jungle' ? '🌴 Jungle' :
                         feature === 'boreal_forest' ? '🌲 Boreal Forest' :
                         feature === 'oasis' ? '🏝️ Oasis' :
                         feature === 'volcano' ? '🌋 Volcano' : feature}
                      </span>
                    ))}
                  </div>
                </div>
              )}
              
              {/* Food Resources - Animals */}
              {tile.animals.length > 0 && (
                <div className="mt-2 p-2 bg-green-500/20 rounded border border-green-500/50">
                  <p className="font-semibold text-green-300 text-xs md:text-sm mb-1">🍖 Food Resources</p>
                  <div className="flex flex-wrap gap-1">
                    {tile.animals.map((animal, idx) => (
                      <span key={idx} className="text-xs bg-green-600/40 px-2 py-0.5 rounded text-green-100 capitalize">
                        {RESOURCE_ICONS[animal]} {animal}
                      </span>
                    ))}
                  </div>
                </div>
              )}
              
              {tile.minerals.length > 0 && (
                <div className="mt-2 p-2 bg-yellow-500/20 rounded border border-yellow-500/50">
                  <p className="font-semibold text-yellow-300 text-xs md:text-sm mb-1">⛏️ Minerals</p>
                  <div className="flex flex-wrap gap-1">
                    {tile.minerals.map((mineral, idx) => (
                      <span key={idx} className="text-xs bg-yellow-600/40 px-2 py-0.5 rounded text-yellow-100 capitalize">
                        {RESOURCE_ICONS[mineral]} {mineral}
                      </span>
                    ))}
                  </div>
                </div>
              )}
              
              {tile.resources.length > 0 && (
                <div className="mt-2 p-2 bg-purple-500/20 rounded border border-purple-500/50">
                  <p className="font-semibold text-purple-300 text-xs md:text-sm mb-1">📦 Resources</p>
                  <div className="flex flex-wrap gap-1">
                    {tile.resources.map((resource, idx) => (
                      <span key={idx} className="text-xs bg-purple-600/40 px-2 py-0.5 rounded text-purple-100 capitalize">
                        {RESOURCE_ICONS[resource]} {resource}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Travel to Duchy Button */}
            {!isCurrentLocation && onStartDuchyTravel && travelPath && (
              <div className="space-y-2 mt-3">
                <div className="bg-amber-500/10 p-3 rounded border border-amber-500/30">
                  <h4 className="text-amber-300 font-semibold text-xs mb-2">Travel Information</h4>
                  <div className="space-y-1 text-[10px] text-white/80">
                    <div className="flex justify-between">
                      <span>Distance:</span>
                      <span className="text-amber-200 font-semibold">{travelDistanceKm} km ({travelPath.length - 1} duchies)</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Travel Time:</span>
                      <span className="text-amber-200 font-semibold">{formatTravelTime(travelTime)}</span>
                    </div>
                    <p className="text-[9px] text-white/60 mt-2">* Terrain affects travel speed</p>
                  </div>
                </div>
                <Button 
                  onClick={() => onStartDuchyTravel(tile.coordinates)}
                  disabled={isCurrentlyTraveling}
                  className="w-full bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-700 hover:to-orange-700 text-white font-semibold disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <Navigation className="w-4 h-4 mr-2" />
                  {isCurrentlyTraveling ? 'Already Traveling...' : 'Travel Here'}
                </Button>
              </div>
            )}
            
            {!isCurrentLocation && !travelPath && onStartDuchyTravel && (
              <div className="bg-red-500/20 p-3 rounded border border-red-500/50 text-xs text-red-200">
                ❌ This duchy is unreachable on foot. You may need a ship to cross water.
              </div>
            )}
          </>
        )}

        {view === 'travel' && travelCalc && (
          <div className="space-y-4">
            <div>
              <label className="text-white text-sm font-semibold mb-2 block">
                Select Transport Method
              </label>
              <Select value={selectedTransport} onValueChange={setSelectedTransport}>
                <SelectTrigger className="bg-black/30 border-white/20 text-white">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {TRANSPORT_OPTIONS.map((t) => (
                    <SelectItem key={t.id} value={t.id}>
                      {t.icon} {t.name} - {t.speed} tiles/day
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="p-4 bg-blue-500/20 rounded-lg border border-blue-500/30 space-y-2">
              <h4 className="text-white font-bold mb-3">Travel Calculation</h4>
              <div className="flex justify-between text-sm">
                <span className="text-blue-200">Distance:</span>
                <span className="text-white font-semibold">{travelCalc.distance} tiles</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-blue-200">Travel Time:</span>
                <span className="text-white font-semibold">{travelCalc.travelTime.toFixed(1)} game days</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-blue-200">Arrival:</span>
                <span className="text-white font-semibold">{travelCalc.arrivalDate.toLocaleString()}</span>
              </div>
            </div>

            <Button className="w-full bg-green-600 hover:bg-green-700">
              <Navigation className="w-4 h-4 mr-2" />
              Start Journey to {duchyInfo.name}
            </Button>

            <p className="text-xs text-purple-300 text-center">
              💡 Travel happens in real-time based on server time (x4 speed)
            </p>
          </div>
        )}

        {view === 'overview' && (
          <div className="space-y-4">
            <div className="p-4 bg-purple-500/20 rounded-lg border border-purple-500/30">
              <h4 className="text-white font-bold mb-2 flex items-center gap-2">
                <Crown className="w-5 h-5 text-yellow-400" />
                Ownership
              </h4>
              {duchyInfo.owner ? (
                <div>
                  <p className="text-purple-200 text-sm">Owner: {duchyInfo.owner}</p>
                  {duchyInfo.nftId && (
                    <p className="text-purple-300 text-xs mt-1">NFT ID: {duchyInfo.nftId}</p>
                  )}
                </div>
              ) : (
                <p className="text-purple-200 text-sm">🏴 Unclaimed Territory</p>
              )}
            </div>

            <div className="p-4 bg-orange-500/20 rounded-lg border border-orange-500/30">
              <h4 className="text-white font-bold mb-2 flex items-center gap-2">
                <Building className="w-5 h-5 text-orange-400" />
                Buildings ({duchyInfo.buildings.length})
              </h4>
              {duchyInfo.buildings.length > 0 ? (
                <div className="space-y-2">
                  {duchyInfo.buildings.map((building) => (
                    <div key={building.id} className="bg-black/20 rounded p-2">
                      <div className="flex items-center gap-2">
                        <span className="text-2xl">{building.icon}</span>
                        <div>
                          <p className="text-white font-semibold text-sm">{building.name}</p>
                          <p className="text-orange-200 text-xs">{building.type}</p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-orange-200 text-sm">No buildings constructed</p>
              )}
            </div>

            <Button className="w-full bg-purple-600 hover:bg-purple-700">
              View Full Duchy Details
            </Button>
            
            {isCurrentLocation && (
              <Link href={`/land-detail/${tile.coordinates.q}/${tile.coordinates.r}`} className="block">
                <Button className="w-full bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 mt-3">
                  <Building className="w-4 h-4 mr-2" />
                  Enter Land (SubLands View)
                </Button>
              </Link>
            )}
          </div>
        )}
      </div>
    </Card>
  );
}
