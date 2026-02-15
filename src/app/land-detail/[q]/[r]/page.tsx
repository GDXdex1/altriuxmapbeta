'use client';

import { use } from 'react';
import { useState, useRef, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { ArrowLeft, ZoomIn, ZoomOut, X, Building2, Coins, Plus, Settings, Trash2, Users, Crown, Home, Navigation } from 'lucide-react';
import { SubLandPanel } from '@/components/hexmap/SubLandPanel';
import { TravelIndicator } from '@/components/hexmap/TravelIndicator';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import type { HexTile as HexTileType } from '@/lib/hexmap/types';
import { generateEarthMap } from '@/lib/hexmap/generator';
import { getHexKey, axialToPixel, pixelToAxial } from '@/lib/hexmap/hex-utils';
import type { SubLand, PlacedBuilding, HexagonSettlementData, NFTType, ReligionType } from '@/lib/sublands/types';
import type { ActiveTravel } from '@/types/game';
import { generateSubLandsForHex, isAdjacentToCoastalInland } from '@/lib/sublands/generator';
import { BUILDING_CONFIGS, getAvailableBuildings, formatArea, isCentralTile, getTownTiles, countUrbanCores, hasTownInHexagon } from '@/lib/sublands/building-config';
import { calculateSubLandTravel, calculateSubLandDistance } from '@/lib/travel-calculator';
import { findSubLandPath } from '@/lib/hexmap/subland-pathfinding';

interface ViewPort {
  x: number;
  y: number;
  scale: number;
}

interface LandDetailPageProps {
  params: Promise<{
    q: string;
    r: string;
  }>;
}

interface TouchInfo {
  id: number;
  x: number;
  y: number;
}

export default function LandDetailPage({ params }: LandDetailPageProps): JSX.Element {
  const resolvedParams = use(params);
  const parentQ = parseInt(resolvedParams.q, 10);
  const parentR = parseInt(resolvedParams.r, 10);

  const canvasRef = useRef<HTMLCanvasElement>(null);
  const minimapRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  // Hexagonal grid settings: ~10,000 hexagons with radius 58
  const HEX_RADIUS = 58; // Hexagonal grid radius (~10,000 hexagons)
  const HEX_SIZE = 10; // Pixel size of each hexagon at scale 1.0

  // Initial viewport: scale 1.0, centered on (0, 0)
  const [viewport, setViewport] = useState<ViewPort>({
    x: 0,
    y: 0,
    scale: 1.0
  });

  const [canvasSize, setCanvasSize] = useState<number>(800);
  const [selectedSubLand, setSelectedSubLand] = useState<SubLand | null>(null);
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const [dragStart, setDragStart] = useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const [touchStartTime, setTouchStartTime] = useState<number>(0);
  const [touchStartPos, setTouchStartPos] = useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const [isClaiming, setIsClaiming] = useState<boolean>(false);
  const [isBuilding, setIsBuilding] = useState<boolean>(false);
  const [showKmMenu, setShowKmMenu] = useState<boolean>(false);
  const [showBuildingManagement, setShowBuildingManagement] = useState<boolean>(false);
  const [selectedBuilding, setSelectedBuilding] = useState<PlacedBuilding | null>(null);
  const [hasSpecialNFTs] = useState<boolean>(false);
  const [selectedSubLandForPanel, setSelectedSubLandForPanel] = useState<SubLand | null>(null);
  // Player starts at duchy capital center (0, 0) - this should always be land
  // The 7 central hexagons are reserved for duchy capital
  const [playerPosition, setPlayerPosition] = useState<{ q: number; r: number } | null>(null);
  const [activeTravel, setActiveTravel] = useState<ActiveTravel | null>(null);

  // Travel system: Update position every second during active travel
  useEffect(() => {
    if (!activeTravel) return;

    const updateInterval = setInterval(() => {
      setActiveTravel(prev => {
        if (!prev) return null;

        // Update elapsed time (1 second = 0.000278 hours)
        const newElapsedTime = prev.elapsedTime + (1 / 3600);

        // Check if travel is complete
        if (newElapsedTime >= prev.totalTravelTime) {
          // Arrive at destination
          setPlayerPosition(prev.destination);
          return null; // End travel
        }

        // Calculate which hex we should be at based on elapsed time
        const progressRatio = newElapsedTime / prev.totalTravelTime;
        const targetHexIndex = Math.floor(progressRatio * (prev.path.length - 1));

        // Update current position if we've moved to a new hex
        if (targetHexIndex !== prev.currentHexIndex && targetHexIndex < prev.path.length) {
          const newHex = prev.path[targetHexIndex];
          if (newHex) {
            setPlayerPosition({ q: newHex.q, r: newHex.r });

            // Update biome type based on current hex
            const currentSubland = sublands.find(sl => sl.q === newHex.q && sl.r === newHex.r);
            const currentBiome = currentSubland?.biomeType || prev.biomeType;

            return {
              ...prev,
              currentPosition: newHex,
              currentHexIndex: targetHexIndex,
              elapsedTime: newElapsedTime,
              biomeType: currentBiome
            };
          }
        }

        // Just update elapsed time
        return {
          ...prev,
          elapsedTime: newElapsedTime
        };
      });
    }, 1000); // Update every second

    return () => clearInterval(updateInterval);
  }, [activeTravel]);

  // NFT System: Simulate user's NFT type (in production, fetch from blockchain)
  const [userNFTType, setUserNFTType] = useState<NFTType>('duchy_land'); // 'county_land', 'duchy_land', or 'none'
  const [selectedReligion, setSelectedReligion] = useState<ReligionType>('christian');

  const [parentTile, setParentTile] = useState<HexTileType | null>(null);
  const [sublands, setSublands] = useState<SubLand[]>([]);
  const [hexagonData, setHexagonData] = useState<HexagonSettlementData>({
    parentQ,
    parentR,
    urbanCoreCount: 0,
    maxUrbanCores: 100,
    hasTown: false,
    totalPopulation: 0
  });

  // Touch handling
  const [touches, setTouches] = useState<TouchInfo[]>([]);
  const [lastDistance, setLastDistance] = useState<number>(0);

  useEffect(() => {
    const initializeMap = async () => {
      const mapTiles = await generateEarthMap(42, 1);
      const key = getHexKey(parentQ, parentR);
      const tile = mapTiles.get(key);

      if (tile) {
        setParentTile(tile);

        // If this is a coastal tile, determine which sides touch land
        let coastalLandSides: number[] | undefined;
        if (tile.terrain === 'coast') {
          // Import getCoastalLandSides from generator
          const { getCoastalLandSides } = require('@/lib/hexmap/generator');
          coastalLandSides = getCoastalLandSides(tile, mapTiles);
        }

        // For any land tile, determine which sides touch ocean (for coastal inland areas)
        let oceanNeighborSides: number[] | undefined;
        if (tile.terrain !== 'ocean' && tile.terrain !== 'ice') {
          const { getOceanNeighborSides } = require('@/lib/hexmap/generator');
          oceanNeighborSides = getOceanNeighborSides(tile, mapTiles);
        }

        const generated = generateSubLandsForHex(tile, parentQ, parentR, coastalLandSides, oceanNeighborSides);

        // Assign NFT types to sublands (simulate ownership)
        const withNFTs = generated.map(sl => ({
          ...sl,
          nftType: sl.owner ? 'county_land' : 'none'
        } as SubLand));

        setSublands(withNFTs);

        // Set initial player position to a valid land hexagon (not ocean or coastal_inland)
        // Prefer duchy capital center (0, 0) if it's valid land
        if (!playerPosition) {
          let initialPosition: { q: number; r: number } | null = null;

          // First, try to use duchy capital center (0, 0)
          const centerHex = withNFTs.find(sl => sl.q === 0 && sl.r === 0);
          if (centerHex && centerHex.biomeType !== 'ocean' && centerHex.resourceType !== 'coastal_inland') {
            initialPosition = { q: 0, r: 0 };
          } else {
            // If center is not valid, find any valid land hexagon
            const validLandHex = withNFTs.find(sl =>
              sl.biomeType !== 'ocean' &&
              sl.biomeType !== 'ice' &&
              sl.resourceType !== 'coastal_inland'
            );

            if (validLandHex) {
              initialPosition = { q: validLandHex.q, r: validLandHex.r };
            } else {
              // Fallback: use (0, 0) even if not ideal
              initialPosition = { q: 0, r: 0 };
            }
          }

          setPlayerPosition(initialPosition);
        }

        // Update hexagon data
        const urbanCores = countUrbanCores(withNFTs);
        const hasTown = hasTownInHexagon(withNFTs);
        setHexagonData({
          parentQ,
          parentR,
          urbanCoreCount: urbanCores,
          maxUrbanCores: 100,
          hasTown,
          totalPopulation: urbanCores * 300
        });
      }
    };

    initializeMap();
  }, [parentQ, parentR, playerPosition]);

  // Calculate square canvas size based on container and center on player's duchy
  useEffect(() => {
    const updateCanvasSize = (): void => {
      if (containerRef.current) {
        const container = containerRef.current;
        const size = Math.min(container.clientWidth, container.clientHeight);
        setCanvasSize(size);

        // Center the hexagonal grid at player position (duchy capital at origin)
        const centerOffsetX = size / 2;
        const centerOffsetY = size / 2;
        setViewport(prev => ({
          ...prev,
          x: centerOffsetX,
          y: centerOffsetY
        }));
      }
    };

    updateCanvasSize();
    window.addEventListener('resize', updateCanvasSize);
    return () => window.removeEventListener('resize', updateCanvasSize);
  }, []);

  const handleClaimLand = async (): Promise<void> => {
    if (!selectedSubLand || selectedSubLand.status !== 'virgin') return;

    // Cannot claim coastal_inland areas
    if (selectedSubLand.resourceType === 'coastal_inland') {
      alert('Cannot claim coastal inland areas. These are water-adjacent zones.');
      return;
    }

    setIsClaiming(true);
    await new Promise(resolve => setTimeout(resolve, 2000));

    const claimedAt = new Date();
    const expiresAt = new Date(claimedAt);
    expiresAt.setMonth(expiresAt.getMonth() + 6);

    setSublands(prev => prev.map(sl =>
      sl.id === selectedSubLand.id
        ? {
          ...sl,
          status: 'claimed',
          owner: '0x1234...5678',
          ownerName: 'You',
          nftId: `SL-${parentQ}-${parentR}-${sl.q}-${sl.r}`,
          nftType: 'county_land', // Assign County Land NFT on claim
          claimedAt,
          claimExpiresAt: expiresAt,
          hasNaturalFeatures: false // Clear trees/rocks on claim
        }
        : sl
    ));

    setSelectedSubLand(prev => prev ? {
      ...prev,
      status: 'claimed',
      owner: '0x1234...5678',
      ownerName: 'You',
      nftId: `SL-${parentQ}-${parentR}-${prev.q}-${prev.r}`,
      nftType: 'county_land',
      claimedAt,
      claimExpiresAt: expiresAt,
      hasNaturalFeatures: false
    } : null);

    setIsClaiming(false);
  };

  const handleBuildBuilding = async (buildingType: string): Promise<void> => {
    if (!selectedSubLand || selectedSubLand.owner !== '0x1234...5678') return;

    // Cannot build in coastal_inland areas
    if (selectedSubLand.resourceType === 'coastal_inland') {
      alert('Cannot build in coastal inland areas. Build on adjacent land instead.');
      return;
    }

    const config = BUILDING_CONFIGS[buildingType as keyof typeof BUILDING_CONFIGS];
    if (!config) return;

    // Check NFT type requirements
    if (config.requiresNFTType && config.requiresNFTType !== selectedSubLand.nftType) {
      alert(`Requires ${config.requiresNFTType === 'county_land' ? 'County Land' : 'Duchy Land'} NFT!`);
      return;
    }

    // Check if building a town
    if (config.type === 'town') {
      // Must be duchy land owner (hexagon owner)
      if (userNFTType !== 'duchy_land') {
        alert('Only the Duchy Land NFT owner (hexagon owner) can build a Town!');
        return;
      }

      // Must have at least 20 villages
      if (hexagonData.urbanCoreCount < 20) {
        alert(`Need 20 villages to build a town. Current: ${hexagonData.urbanCoreCount}/20`);
        return;
      }

      // Must be on central tiles
      if (!isCentralTile(selectedSubLand.q, selectedSubLand.r)) {
        alert('Town must be built on the central tiles!');
        return;
      }

      // Check if town already exists
      if (hexagonData.hasTown) {
        alert('Only one town per hexagon allowed!');
        return;
      }

      // Check if all tiles are available
      const townTiles = getTownTiles(selectedSubLand.q, selectedSubLand.r);
      const allAvailable = townTiles.every(tile => {
        const sl = sublands.find(s => s.q === tile.q && s.r === tile.r);
        return sl && sl.status === 'virgin' && sl.buildings.length === 0;
      });

      if (!allAvailable) {
        alert('All central tiles must be empty to build a town!');
        return;
      }
    }

    // Check if building urban core
    if (config.type === 'urban_core') {
      // Check limit
      if (hexagonData.urbanCoreCount >= hexagonData.maxUrbanCores) {
        alert(`Maximum urban cores reached (${hexagonData.maxUrbanCores})!`);
        return;
      }

      // Must be on empty land
      if (selectedSubLand.status !== 'virgin' || selectedSubLand.buildings.length > 0) {
        alert('Urban Core must be built on virgin land with no previous constructions!');
        return;
      }
    }

    // Check if there's enough space
    const availableArea = selectedSubLand.maxAreaM2 - selectedSubLand.usedAreaM2;
    if (config.areaM2 > availableArea) {
      alert(`Not enough space! Available: ${formatArea(availableArea)}, Required: ${formatArea(config.areaM2)}`);
      return;
    }

    setIsBuilding(true);
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Create new building instance
    const newBuilding: PlacedBuilding = {
      id: `${Date.now()}-${Math.random()}`,
      type: config.type,
      builtAt: new Date(),
      nftId: `BLD-${parentQ}-${parentR}-${selectedSubLand.q}-${selectedSubLand.r}-${config.type}-${Date.now()}`,
      position: {
        offsetX: Math.random() * 0.7 + 0.15, // Random position within tile (15-85%)
        offsetY: Math.random() * 0.7 + 0.15
      },
      workers: 0,
      productionRate: 0,
      inventory: {},
      religion: config.type === 'urban_core' ? selectedReligion : undefined,
      urbanCoreData: config.type === 'urban_core' ? {
        market: true,
        tavern: true,
        barracks: true,
        religiousBuilding: selectedReligion,
        houses: 100,
        soldiers: 30,
        population: 300
      } : undefined
    };

    // If building a town, mark all tiles
    if (config.type === 'town') {
      const townTiles = getTownTiles(selectedSubLand.q, selectedSubLand.r);
      const centerPos = { centerQ: townTiles[0].q, centerR: townTiles[0].r };

      setSublands(prev => prev.map(sl => {
        const isTownTile = townTiles.some(t => t.q === sl.q && t.r === sl.r);
        if (isTownTile) {
          // For the selected tile, add the building
          if (sl.id === selectedSubLand.id) {
            return {
              ...sl,
              status: 'developed',
              buildings: [...sl.buildings, newBuilding],
              usedAreaM2: sl.maxAreaM2, // Town uses entire tile
              claimExpiresAt: undefined,
              isPartOfTown: true,
              townCenterPosition: centerPos
            };
          }
          // For other tiles, just mark as part of town
          return {
            ...sl,
            status: 'developed',
            isPartOfTown: true,
            townCenterPosition: centerPos,
            claimExpiresAt: undefined
          };
        }
        return sl;
      }));

      setHexagonData(prev => ({
        ...prev,
        hasTown: true,
        townPosition: centerPos
      }));
    } else {
      // Regular building
      setSublands(prev => prev.map(sl =>
        sl.id === selectedSubLand.id
          ? {
            ...sl,
            status: 'developed',
            buildings: [...sl.buildings, newBuilding],
            usedAreaM2: sl.usedAreaM2 + config.areaM2,
            claimExpiresAt: undefined
          }
          : sl
      ));

      // Update hexagon data if urban core
      if (config.type === 'urban_core') {
        setHexagonData(prev => ({
          ...prev,
          urbanCoreCount: prev.urbanCoreCount + 1,
          totalPopulation: prev.totalPopulation + 300
        }));
      }
    }

    setSelectedSubLand(prev => prev ? {
      ...prev,
      status: 'developed',
      buildings: [...prev.buildings, newBuilding],
      usedAreaM2: prev.usedAreaM2 + config.areaM2,
      claimExpiresAt: undefined
    } : null);

    setIsBuilding(false);
  };

  const handleDeleteBuilding = (buildingId: string): void => {
    if (!selectedSubLand) return;

    const building = selectedSubLand.buildings.find(b => b.id === buildingId);
    if (!building) return;

    const config = BUILDING_CONFIGS[building.type];

    // Prevent deleting town (would need special logic to remove from all tiles)
    if (building.type === 'town') {
      alert('Towns cannot be deleted through this menu. Contact administrator.');
      return;
    }

    setSublands(prev => prev.map(sl =>
      sl.id === selectedSubLand.id
        ? {
          ...sl,
          buildings: sl.buildings.filter(b => b.id !== buildingId),
          usedAreaM2: sl.usedAreaM2 - config.areaM2,
          status: sl.buildings.length === 1 ? 'claimed' : 'developed'
        }
        : sl
    ));

    setSelectedSubLand(prev => prev ? {
      ...prev,
      buildings: prev.buildings.filter(b => b.id !== buildingId),
      usedAreaM2: prev.usedAreaM2 - config.areaM2,
      status: prev.buildings.length === 1 ? 'claimed' : 'developed'
    } : null);

    // Update hexagon data if urban core
    if (building.type === 'urban_core') {
      setHexagonData(prev => ({
        ...prev,
        urbanCoreCount: Math.max(0, prev.urbanCoreCount - 1),
        totalPopulation: Math.max(0, prev.totalPopulation - 300)
      }));
    }

    setSelectedBuilding(null);
  };

  const renderSubLands = useCallback((): void => {
    const canvas = canvasRef.current;
    if (!canvas || sublands.length === 0) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Fill background with black first
    ctx.fillStyle = '#000000';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    ctx.save();
    ctx.translate(viewport.x, viewport.y);
    ctx.scale(viewport.scale, viewport.scale);

    // Create hexagonal clipping path for the entire map
    ctx.save();
    ctx.beginPath();
    const mapHexSize = HEX_RADIUS * HEX_SIZE * 2.6; // Much larger frame to contain all sublands properly
    const rotationOffset = Math.PI / 3; // 60 degrees clockwise rotation
    for (let i = 0; i < 6; i++) {
      const angle = (Math.PI / 3) * i + rotationOffset;
      const hx = mapHexSize * Math.cos(angle);
      const hy = mapHexSize * Math.sin(angle);
      if (i === 0) {
        ctx.moveTo(hx, hy);
      } else {
        ctx.lineTo(hx, hy);
      }
    }
    ctx.closePath();
    ctx.clip();

    // Draw hexagonal tiles
    for (const subland of sublands) {
      const pixel = axialToPixel(subland.q, subland.r, HEX_SIZE);

      // Base color based on biome and resource
      let color = getBiomeColor(subland);

      if (subland.resourceType === 'coastal_land') {
        color = '#D2B48C'; // Coastal land (sand/earth color)
      } else if (subland.resourceType === 'coastal_inland') {
        color = '#4A9EC2'; // Coastal inland (blue coastal color)
      } else if (subland.resourceType.startsWith('mine_')) {
        color = '#FFB84D'; // Mines
      } else if (subland.resourceType.startsWith('farmland_')) {
        color = '#8FBC94'; // Farmlands
      }

      if (subland.hasRiver) {
        color = subland.isNavigableRiver ? '#4A90E2' : '#7EC8E3'; // Rivers
      }

      // Mark claimed hexagons in green
      if (subland.status === 'claimed') {
        color = '#22C55E'; // Green for claimed lands
      } else if (subland.status === 'developed') {
        color = adjustColorBrightness(color, -50);
      }

      // Special color for town tiles
      if (subland.isPartOfTown) {
        color = '#8B4513'; // Dark brown for town
      }

      // Check if this is part of the duchy capital (central hexagon + 6 neighbors)
      const isDuchyCapital = isDuchyCapitalHex(subland.q, subland.r);

      // Apply duchy capital overlay
      if (isDuchyCapital) {
        color = '#8B4513'; // Dark brown for duchy capital reserve
      }

      // Draw hexagon
      ctx.fillStyle = color;
      ctx.beginPath();
      for (let i = 0; i < 6; i++) {
        const angle = (Math.PI / 3) * i;
        const hx = pixel.x + HEX_SIZE * Math.cos(angle);
        const hy = pixel.y + HEX_SIZE * Math.sin(angle);
        if (i === 0) {
          ctx.moveTo(hx, hy);
        } else {
          ctx.lineTo(hx, hy);
        }
      }
      ctx.closePath();
      ctx.fill();

      // Draw hexagon border
      if (isDuchyCapital) {
        ctx.strokeStyle = '#FFD700'; // Gold border for duchy capital
        ctx.lineWidth = 1.5 / viewport.scale;
      } else {
        ctx.strokeStyle = 'rgba(255, 255, 255, 0.3)';
        ctx.lineWidth = 0.5 / viewport.scale;
      }
      ctx.stroke();

      // Highlight player position with red border
      if (playerPosition && playerPosition.q === subland.q && playerPosition.r === subland.r) {
        ctx.strokeStyle = '#FF0000';
        ctx.lineWidth = 3 / viewport.scale;
        ctx.beginPath();
        for (let i = 0; i < 6; i++) {
          const angle = (Math.PI / 3) * i;
          const hx = pixel.x + HEX_SIZE * Math.cos(angle);
          const hy = pixel.y + HEX_SIZE * Math.sin(angle);
          if (i === 0) {
            ctx.moveTo(hx, hy);
          } else {
            ctx.lineTo(hx, hy);
          }
        }
        ctx.closePath();
        ctx.stroke();
      }

      // Draw natural features (trees for forest/jungle on virgin lands)
      if (subland.hasNaturalFeatures && subland.status === 'virgin') {
        drawNaturalFeaturesHex(ctx, pixel.x, pixel.y, HEX_SIZE, subland.biomeType, viewport.scale);
      }

      // Draw buildings as proportional shapes
      if (subland.buildings.length > 0) {
        for (const building of subland.buildings) {
          const config = BUILDING_CONFIGS[building.type];
          drawBuildingHex(ctx, pixel.x, pixel.y, HEX_SIZE, building, config, viewport.scale);
        }
      }

      // Selected highlight
      if (selectedSubLand?.id === subland.id) {
        ctx.strokeStyle = '#FF0000';
        ctx.lineWidth = 2 / viewport.scale;
        ctx.beginPath();
        for (let i = 0; i < 6; i++) {
          const angle = (Math.PI / 3) * i;
          const hx = pixel.x + HEX_SIZE * Math.cos(angle);
          const hy = pixel.y + HEX_SIZE * Math.sin(angle);
          if (i === 0) {
            ctx.moveTo(hx, hy);
          } else {
            ctx.lineTo(hx, hy);
          }
        }
        ctx.closePath();
        ctx.stroke();
      }
    }

    ctx.restore(); // Restore clipping

    // Draw outer hexagonal border
    ctx.strokeStyle = '#D97706';
    ctx.lineWidth = 4 / viewport.scale;
    ctx.beginPath();
    for (let i = 0; i < 6; i++) {
      const angle = (Math.PI / 3) * i + rotationOffset;
      const hx = mapHexSize * Math.cos(angle);
      const hy = mapHexSize * Math.sin(angle);
      if (i === 0) {
        ctx.moveTo(hx, hy);
      } else {
        ctx.lineTo(hx, hy);
      }
    }
    ctx.closePath();
    ctx.stroke();

    ctx.restore();
  }, [sublands, viewport, selectedSubLand, playerPosition]);

  const renderMinimap = useCallback((): void => {
    const canvas = minimapRef.current;
    if (!canvas || sublands.length === 0) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const minimapSize = 120;

    ctx.clearRect(0, 0, minimapSize, minimapSize);

    // Center minimap
    ctx.save();
    ctx.translate(minimapSize / 2, minimapSize / 2);

    // Create hexagonal clipping path
    ctx.beginPath();
    const hexSize = minimapSize / 2.2;
    const rotationOffset = Math.PI / 3; // 60 degrees clockwise rotation
    for (let i = 0; i < 6; i++) {
      const angle = (Math.PI / 3) * i + rotationOffset;
      const hx = hexSize * Math.cos(angle);
      const hy = hexSize * Math.sin(angle);
      if (i === 0) {
        ctx.moveTo(hx, hy);
      } else {
        ctx.lineTo(hx, hy);
      }
    }
    ctx.closePath();
    ctx.clip();

    // Draw all sublands as small dots
    const scale = (minimapSize * 0.4) / (HEX_RADIUS * HEX_SIZE);

    for (const subland of sublands) {
      const pixel = axialToPixel(subland.q, subland.r, HEX_SIZE);
      const x = pixel.x * scale;
      const y = pixel.y * scale;

      let color = '#4A5568'; // Default gray

      if (subland.resourceType === 'coastal_land') {
        color = '#D2B48C'; // Coastal land
      } else if (subland.resourceType === 'coastal_inland') {
        color = '#4A9EC2'; // Coastal inland
      } else if (subland.resourceType.startsWith('mine_')) {
        color = '#FFB84D';
      } else if (subland.resourceType.startsWith('farmland_')) {
        color = '#8FBC94';
      } else if (subland.hasRiver) {
        color = '#4A90E2';
      }

      ctx.fillStyle = color;
      ctx.fillRect(x - 0.5, y - 0.5, 1, 1);
    }

    ctx.restore();

    // Draw hexagonal border
    ctx.save();
    ctx.translate(minimapSize / 2, minimapSize / 2);
    ctx.strokeStyle = '#D97706';
    ctx.lineWidth = 2;
    ctx.beginPath();
    const rotationOffsetMini = Math.PI / 3; // 60 degrees clockwise rotation
    for (let i = 0; i < 6; i++) {
      const angle = (Math.PI / 3) * i + rotationOffsetMini;
      const hx = hexSize * Math.cos(angle);
      const hy = hexSize * Math.sin(angle);
      if (i === 0) {
        ctx.moveTo(hx, hy);
      } else {
        ctx.lineTo(hx, hy);
      }
    }
    ctx.closePath();
    ctx.stroke();
    ctx.restore();
  }, [sublands]);

  const handleCanvasClick = (e: React.MouseEvent<HTMLCanvasElement>): void => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const rect = canvas.getBoundingClientRect();
    const clickX = (e.clientX - rect.left - viewport.x) / viewport.scale;
    const clickY = (e.clientY - rect.top - viewport.y) / viewport.scale;

    const axial = pixelToAxial(clickX, clickY, HEX_SIZE);

    const subland = sublands.find(sl => sl.q === axial.q && sl.r === axial.r);

    if (subland) {
      // Always use SubLandPanel which has travel logic
      setSelectedSubLandForPanel(subland);
      setSelectedSubLand(null);
      setShowKmMenu(false);
      setShowBuildingManagement(false);
      setSelectedBuilding(null);
    }
  };

  const handleNavigateToSubland = (q: number, r: number): void => {
    setPlayerPosition({ q, r });
    setSelectedSubLandForPanel(null);
  };

  // Handle start travel with intelligent pathfinding and water detection
  const handleStartTravel = (destination: { q: number; r: number }): void => {
    if (!playerPosition || activeTravel) return;

    // Calculate path using A* pathfinding
    const path = findSubLandPath(playerPosition, destination);

    if (!path || path.length === 0) {
      alert('No path found to destination!');
      return;
    }

    // Check if path crosses water (ocean or coastal_inland)
    const crossesWater = path.some((hex, index) => {
      if (index === 0) return false; // Skip starting position
      const subland = sublands.find(sl => sl.q === hex.q && sl.r === hex.r);
      if (!subland) return false;

      // Block if terrain is ocean or deep water
      if (subland.biomeType === 'ocean' || subland.biomeType === 'ice') return true;

      // Also block coastal_inland hexes (shallow water)
      if (subland.resourceType === 'coastal_inland') return true;

      return false;
    });

    if (crossesWater) {
      alert('No hay ruta disponible. El destino es inaccesible a pie. Puede que necesites un barco para cruzar el agua.');
      return;
    }

    // Build biome and feature maps for travel calculation
    const biomeMap = new Map<string, string>();
    const featureMap = new Map<string, string[]>();

    for (const hex of path) {
      const subland = sublands.find(sl => sl.q === hex.q && sl.r === hex.r);
      if (subland) {
        const hexKey = `${hex.q},${hex.r}`;
        biomeMap.set(hexKey, subland.biomeType);

        // Get parent tile features for this hex
        const features: string[] = [];
        if (parentTile?.features) {
          features.push(...parentTile.features);
        }
        featureMap.set(hexKey, features);
      }
    }

    // Calculate travel time with terrain costs
    const travelCalc = calculateSubLandTravel(path, biomeMap, featureMap);

    // Create active travel object
    const startTime = new Date();
    const estimatedArrival = new Date(startTime.getTime() + travelCalc.totalTravelTimeHours * 60 * 60 * 1000);

    const originSubland = sublands.find(sl => sl.q === playerPosition.q && sl.r === playerPosition.r);

    const newTravel: ActiveTravel = {
      id: `travel-${Date.now()}`,
      origin: playerPosition,
      destination,
      path,
      currentPosition: playerPosition,
      currentHexIndex: 0,
      totalTravelTime: travelCalc.totalTravelTimeHours,
      elapsedTime: 0,
      startTime,
      estimatedArrival,
      biomeType: originSubland?.biomeType || 'plains'
    };

    setActiveTravel(newTravel);
    setSelectedSubLandForPanel(null);
  };

  const handleMinimapClick = (e: React.MouseEvent<HTMLCanvasElement>): void => {
    const canvas = minimapRef.current;
    if (!canvas) return;

    const rect = canvas.getBoundingClientRect();
    const clickX = e.clientX - rect.left - 60; // Center offset
    const clickY = e.clientY - rect.top - 60;

    const scale = (120 * 0.4) / (HEX_RADIUS * HEX_SIZE);

    // Convert minimap click to hex coordinates
    const hexX = clickX / scale;
    const hexY = clickY / scale;

    // Center viewport on clicked position
    const newX = -(hexX * viewport.scale) + canvasSize / 2;
    const newY = -(hexY * viewport.scale) + canvasSize / 2;

    setViewport({
      ...viewport,
      x: newX,
      y: newY
    });
  };

  const handleMouseDown = (e: React.MouseEvent<HTMLCanvasElement>): void => {
    setIsDragging(true);
    setDragStart({ x: e.clientX - viewport.x, y: e.clientY - viewport.y });
  };

  const handleMouseMove = (e: React.MouseEvent<HTMLCanvasElement>): void => {
    if (isDragging) {
      setViewport({
        ...viewport,
        x: e.clientX - dragStart.x,
        y: e.clientY - dragStart.y
      });
    }
  };

  const handleMouseUp = (): void => {
    setIsDragging(false);
  };

  const handleWheel = (e: React.WheelEvent<HTMLCanvasElement>): void => {
    e.preventDefault();
    const scaleFactor = e.deltaY > 0 ? 0.9 : 1.1;
    const newScale = Math.max(0.5, Math.min(3.0, viewport.scale * scaleFactor));

    setViewport({
      ...viewport,
      scale: newScale
    });
  };

  // Touch handlers for mobile pinch zoom and pan
  const handleTouchStart = (e: React.TouchEvent<HTMLCanvasElement>): void => {
    e.preventDefault();

    const touchList: TouchInfo[] = [];
    for (let i = 0; i < e.touches.length; i++) {
      const touch = e.touches[i];
      if (touch) {
        touchList.push({
          id: touch.identifier,
          x: touch.clientX,
          y: touch.clientY
        });
      }
    }
    setTouches(touchList);

    if (touchList.length === 1) {
      // Single touch: record start time and position for tap detection
      setTouchStartTime(Date.now());
      setTouchStartPos({ x: touchList[0].x, y: touchList[0].y });
      setIsDragging(true);
      setDragStart({ x: touchList[0].x - viewport.x, y: touchList[0].y - viewport.y });
    } else if (touchList.length === 2) {
      // Two touches: prepare for pinch zoom
      const dx = touchList[1].x - touchList[0].x;
      const dy = touchList[1].y - touchList[0].y;
      const distance = Math.sqrt(dx * dx + dy * dy);
      setLastDistance(distance);
      setIsDragging(false);
    }
  };

  const handleTouchMove = (e: React.TouchEvent<HTMLCanvasElement>): void => {
    e.preventDefault();

    const touchList: TouchInfo[] = [];
    for (let i = 0; i < e.touches.length; i++) {
      const touch = e.touches[i];
      if (touch) {
        touchList.push({
          id: touch.identifier,
          x: touch.clientX,
          y: touch.clientY
        });
      }
    }

    if (touchList.length === 1 && isDragging) {
      // Single touch: pan
      setViewport({
        ...viewport,
        x: touchList[0].x - dragStart.x,
        y: touchList[0].y - dragStart.y
      });
    } else if (touchList.length === 2) {
      // Two touches: pinch zoom
      const dx = touchList[1].x - touchList[0].x;
      const dy = touchList[1].y - touchList[0].y;
      const distance = Math.sqrt(dx * dx + dy * dy);

      if (lastDistance > 0) {
        const scaleFactor = distance / lastDistance;
        const newScale = Math.max(0.5, Math.min(3.0, viewport.scale * scaleFactor));

        setViewport(prev => ({
          ...prev,
          scale: newScale
        }));
      }

      setLastDistance(distance);
    }

    setTouches(touchList);
  };

  const handleTouchEnd = (e: React.TouchEvent<HTMLCanvasElement>): void => {
    e.preventDefault();

    const touchList: TouchInfo[] = [];
    for (let i = 0; i < e.touches.length; i++) {
      const touch = e.touches[i];
      if (touch) {
        touchList.push({
          id: touch.identifier,
          x: touch.clientX,
          y: touch.clientY
        });
      }
    }

    // Detect tap vs drag
    if (touchList.length === 0 && touches.length === 1) {
      const touchDuration = Date.now() - touchStartTime;
      const touch = e.changedTouches[0];

      if (touch) {
        const dx = touch.clientX - touchStartPos.x;
        const dy = touch.clientY - touchStartPos.y;
        const distance = Math.sqrt(dx * dx + dy * dy);

        // If touch was quick (<300ms) and didn't move much (<10px), treat it as a tap
        if (touchDuration < 300 && distance < 10) {
          const canvas = canvasRef.current;
          if (canvas) {
            const rect = canvas.getBoundingClientRect();
            const clickX = (touch.clientX - rect.left - viewport.x) / viewport.scale;
            const clickY = (touch.clientY - rect.top - viewport.y) / viewport.scale;

            const axial = pixelToAxial(clickX, clickY, HEX_SIZE);

            const subland = sublands.find(sl => sl.q === axial.q && sl.r === axial.r);

            if (subland) {
              // Use SubLandPanel which has travel logic
              setSelectedSubLandForPanel(subland);
              setSelectedSubLand(null);
              setShowKmMenu(false);
              setShowBuildingManagement(false);
              setSelectedBuilding(null);
            }
          }
        }
      }
    }

    setTouches(touchList);

    if (touchList.length === 0) {
      setIsDragging(false);
      setLastDistance(0);
    } else if (touchList.length === 1) {
      setTouchStartTime(Date.now());
      setTouchStartPos({ x: touchList[0].x, y: touchList[0].y });
      setIsDragging(true);
      setDragStart({ x: touchList[0].x - viewport.x, y: touchList[0].y - viewport.y });
      setLastDistance(0);
    }
  };

  const handleZoomIn = (): void => {
    setViewport({ ...viewport, scale: Math.min(3.0, viewport.scale * 1.2) });
  };

  const handleZoomOut = (): void => {
    setViewport({ ...viewport, scale: Math.max(0.5, viewport.scale / 1.2) });
  };

  const handleReset = (): void => {
    const centerOffsetX = canvasSize / 2;
    const centerOffsetY = canvasSize / 2;
    setViewport({ x: centerOffsetX, y: centerOffsetY, scale: 1.0 });
  };

  useEffect(() => {
    renderSubLands();
    renderMinimap();
  }, [renderSubLands, renderMinimap]);

  const getResourceName = (resourceType: string): string => {
    if (resourceType === 'standard') return 'Moderate Agricultural Land';
    if (resourceType === 'coastal_land') return 'Coastal Land (for ports & shipyards)';
    if (resourceType === 'coastal_inland') return 'Coastal Inland (near ocean)';
    if (resourceType.startsWith('mine_')) {
      return `${resourceType.split('_')[1].charAt(0).toUpperCase()}${resourceType.split('_')[1].slice(1)} Mine`;
    }
    if (resourceType.startsWith('farmland_')) {
      return `${resourceType.split('_')[1].charAt(0).toUpperCase()}${resourceType.split('_')[1].slice(1)} Farmland`;
    }
    return resourceType;
  };

  const availableAreaM2 = selectedSubLand ? selectedSubLand.maxAreaM2 - selectedSubLand.usedAreaM2 : 0;
  const isCoastalAdjacent = selectedSubLand ? isAdjacentToCoastalInland(selectedSubLand, sublands) : false;
  const availableBuildings = selectedSubLand
    ? getAvailableBuildings(
      selectedSubLand.hasRiver,
      selectedSubLand.isNavigableRiver,
      hasSpecialNFTs,
      availableAreaM2,
      selectedSubLand.nftType || 'none',
      selectedSubLand,
      hexagonData,
      isCoastalAdjacent
    )
    : [];

  return (
    <main className="fixed inset-0 bg-gradient-to-br from-slate-900 to-slate-800 overflow-hidden">
      {/* Minimal Top Bar */}
      <div className="absolute top-0 left-0 right-0 z-20 bg-black/40 backdrop-blur-sm p-2 flex items-center justify-between">
        <Link href="/altriux-world">
          <Button variant="ghost" size="sm" className="text-white hover:bg-white/20 h-8 px-2">
            <ArrowLeft className="w-4 h-4" />
          </Button>
        </Link>

        <div className="flex-1 px-2">
          <p className="text-white/90 text-xs font-mono">
            Duchy ({parentQ}, {parentR}) | {parentTile?.continent === 'drantium' ? '🌴 Drantium' : '🌲 Brontium'}
          </p>
          {parentTile?.owner && (
            <p className="text-white/60 text-[10px]">
              Owner: {parentTile.owner.slice(0, 8)}... | NFT: #{parentQ * 1000 + parentR}
            </p>
          )}
        </div>

        <div className="flex items-center gap-1">
          <Button onClick={handleZoomOut} variant="ghost" size="sm" className="text-white hover:bg-white/20 h-7 w-7 p-0">
            <ZoomOut className="w-3 h-3" />
          </Button>
          <span className="text-white/80 text-[10px] font-mono w-10 text-center">{Math.round(viewport.scale * 100)}%</span>
          <Button onClick={handleZoomIn} variant="ghost" size="sm" className="text-white hover:bg-white/20 h-7 w-7 p-0">
            <ZoomIn className="w-4 h-4" />
          </Button>
          <Button onClick={handleReset} variant="ghost" size="sm" className="text-white/70 hover:bg-white/20 h-7 px-2 text-[10px]">
            Reset
          </Button>
        </div>
      </div>

      {/* Settlement Info Panel - Top Left */}
      <div className="absolute top-14 left-2 z-30 bg-black/80 backdrop-blur-sm rounded border border-amber-500/50 p-2 text-xs">
        <div className="flex items-center gap-2 mb-1">
          <Crown className="w-4 h-4 text-amber-400" />
          <span className="text-amber-300 font-bold">Hexagon Status</span>
        </div>
        <div className="space-y-1 text-white/80">
          <div className="flex justify-between gap-4">
            <span className="text-white/60">Villages:</span>
            <span className="text-green-300 font-semibold">{hexagonData.urbanCoreCount} / {hexagonData.maxUrbanCores}</span>
          </div>
          <div className="flex justify-between gap-4">
            <span className="text-white/60">Population:</span>
            <span className="text-blue-300">{hexagonData.totalPopulation.toLocaleString()}</span>
          </div>
          <div className="flex justify-between gap-4">
            <span className="text-white/60">Town:</span>
            <span className={hexagonData.hasTown ? 'text-amber-400' : 'text-red-400'}>
              {hexagonData.hasTown ? '✓ Built' : '✗ None'}
            </span>
          </div>
          {!hexagonData.hasTown && hexagonData.urbanCoreCount >= 20 && (
            <div className="bg-green-500/20 p-1 rounded text-[9px] text-green-300 mt-1">
              ✓ Town eligible!
            </div>
          )}
        </div>
      </div>

      {/* Minimap - Top Right (Hexagonal shape) */}
      <div className="hidden md:block absolute top-14 right-4 z-30">
        <canvas
          ref={minimapRef}
          width={120}
          height={120}
          className="bg-black/60 cursor-pointer"
          onClick={handleMinimapClick}
        />
      </div>

      {/* Compass - Bottom Right */}
      <div className="absolute bottom-4 right-4 z-30 bg-black/80 backdrop-blur-sm rounded-full border-2 border-amber-500/50 w-20 h-20 flex items-center justify-center">
        <div className="relative w-full h-full">
          {/* North indicator */}
          <div className="absolute top-1 left-1/2 -translate-x-1/2 text-red-500 font-bold text-sm">
            N
          </div>
          {/* South indicator */}
          <div className="absolute bottom-1 left-1/2 -translate-x-1/2 text-blue-400 font-bold text-sm">
            S
          </div>
          {/* East indicator */}
          <div className="absolute right-1 top-1/2 -translate-y-1/2 text-white/70 font-semibold text-xs">
            E
          </div>
          {/* West indicator */}
          <div className="absolute left-1 top-1/2 -translate-y-1/2 text-white/70 font-semibold text-xs">
            W
          </div>
          {/* Center dot */}
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-2 h-2 bg-amber-500 rounded-full"></div>
          {/* North arrow */}
          <div className="absolute top-5 left-1/2 -translate-x-1/2 w-0 h-0 border-l-4 border-r-4 border-b-6 border-l-transparent border-r-transparent border-b-red-500"></div>
        </div>
      </div>

      {/* Travel Indicator */}
      {activeTravel && (
        <TravelIndicator
          origin={activeTravel.origin}
          destination={activeTravel.destination}
          currentPosition={activeTravel.currentPosition}
          path={activeTravel.path}
          totalTravelTime={activeTravel.totalTravelTime}
          elapsedTime={activeTravel.elapsedTime}
          currentHexIndex={activeTravel.currentHexIndex}
          estimatedArrival={activeTravel.estimatedArrival}
          biomeType={activeTravel.biomeType}
        />
      )}

      {/* SubLand Panel */}
      {selectedSubLandForPanel && (
        <SubLandPanel
          subland={selectedSubLandForPanel}
          parentQ={parentQ}
          parentR={parentR}
          onClose={() => setSelectedSubLandForPanel(null)}
          playerPosition={playerPosition}
          onNavigate={handleNavigateToSubland}
          onStartTravel={handleStartTravel}
          isCurrentlyTraveling={activeTravel !== null}
          sublands={sublands}
        />
      )}

      {/* Management Menu */}
      {showKmMenu && selectedSubLand && (
        <Card className="absolute top-14 left-2 right-2 md:left-auto md:right-4 md:w-96 lg:w-[450px] z-30 bg-black/95 backdrop-blur-sm border-amber-500/50 max-h-[75vh] overflow-y-auto">
          <div className="p-3">
            <button
              onClick={() => {
                setShowKmMenu(false);
                setShowBuildingManagement(false);
                setSelectedBuilding(null);
              }}
              className="absolute top-2 right-2 text-white/70 hover:text-white"
            >
              <X className="w-4 h-4" />
            </button>

            <h3 className="text-amber-400 font-bold text-sm mb-2">xLand (1km × 1km)</h3>

            <div className="space-y-2 text-xs mb-3">
              <div className="flex justify-between">
                <span className="text-white/70">Position:</span>
                <span className="text-white">({selectedSubLand.q}, {selectedSubLand.r})</span>
              </div>

              <div className="flex justify-between">
                <span className="text-white/70">Biome:</span>
                <span className="text-amber-300 capitalize">{selectedSubLand.biomeType}</span>
              </div>

              <div className="flex justify-between">
                <span className="text-white/70">Resource:</span>
                <span className="text-amber-300">{getResourceName(selectedSubLand.resourceType)}</span>
              </div>

              {/* Terrain Features Section - Display features from parent tile */}
              <div className="bg-slate-700/30 p-2 rounded">
                <p className="text-white/80 text-[10px] font-semibold mb-1">Terrain Features:</p>
                <div className="space-y-1">
                  {parentTile?.features?.includes('jungle') && (
                    <div className="flex items-center gap-1 text-[10px]">
                      <span className="text-green-400">🌴</span>
                      <span className="text-green-200">Jungle (Selva)</span>
                    </div>
                  )}
                  {parentTile?.features?.includes('forest') && (
                    <div className="flex items-center gap-1 text-[10px]">
                      <span className="text-green-600">🌲</span>
                      <span className="text-green-200">Forest (Bosque)</span>
                    </div>
                  )}
                  {parentTile?.features?.includes('boreal_forest') && (
                    <div className="flex items-center gap-1 text-[10px]">
                      <span className="text-teal-400">🌲</span>
                      <span className="text-teal-200">Boreal Forest (Bosque Boreal)</span>
                    </div>
                  )}
                  {parentTile?.features?.includes('volcano') && (
                    <div className="flex items-center gap-1 text-[10px]">
                      <span className="text-red-500">🌋</span>
                      <span className="text-red-300">Volcano (Volcán)</span>
                    </div>
                  )}
                  {parentTile?.features?.includes('oasis') && (
                    <div className="flex items-center gap-1 text-[10px]">
                      <span className="text-blue-400">🏝️</span>
                      <span className="text-blue-200">Oasis</span>
                    </div>
                  )}
                  {(!parentTile?.features || parentTile.features.length === 0) && (
                    <span className="text-white/50 text-[10px] italic">None</span>
                  )}
                </div>
              </div>

              <div className="flex justify-between">
                <span className="text-white/70">Status:</span>
                <Badge className={`text-[10px] ${selectedSubLand.status === 'virgin' ? 'bg-green-500/20 text-green-300' :
                    selectedSubLand.status === 'claimed' ? 'bg-blue-500/20 text-blue-300' :
                      'bg-purple-500/20 text-purple-300'
                  }`}>
                  {selectedSubLand.status}
                </Badge>
              </div>

              {selectedSubLand.nftType && selectedSubLand.nftType !== 'none' && (
                <div className="bg-amber-500/20 p-2 rounded text-[10px] text-amber-200">
                  <div className="flex items-center gap-1">
                    <Crown className="w-3 h-3" />
                    <span className="font-semibold">
                      {selectedSubLand.nftType === 'county_land' ? 'County Land NFT' : 'Duchy Land NFT'}
                    </span>
                  </div>
                </div>
              )}

              {selectedSubLand.isPartOfTown && (
                <div className="bg-purple-500/20 p-2 rounded text-[10px] text-purple-200">
                  🏰 Part of Town territory
                </div>
              )}

              {selectedSubLand.status !== 'virgin' && (
                <div className="bg-slate-700/50 p-2 rounded">
                  <div className="flex justify-between text-[10px] mb-1">
                    <span className="text-white/70">Area Used:</span>
                    <span className="text-white">{formatArea(selectedSubLand.usedAreaM2)} / {formatArea(selectedSubLand.maxAreaM2)}</span>
                  </div>
                  <div className="w-full bg-slate-600 h-1 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-green-500 to-amber-500"
                      style={{ width: `${(selectedSubLand.usedAreaM2 / selectedSubLand.maxAreaM2) * 100}%` }}
                    />
                  </div>
                </div>
              )}
            </div>

            {/* Info only - no construction options in sublands */}
            <div className="space-y-2">
              <div className="bg-purple-500/10 p-3 rounded text-center">
                <p className="text-purple-200 text-sm font-semibold mb-1">📍 xLand Hexagon</p>
                <p className="text-purple-300/80 text-[10px]">
                  To claim land or build structures, enter the xLand Overview map.
                </p>
              </div>

              {/* xLand Overview button - always visible */}
              {playerPosition && playerPosition.q === selectedSubLand.q && playerPosition.r === selectedSubLand.r && (
                <Button
                  onClick={() => {
                    window.location.href = `/xland-overview/${parentQ}/${parentR}/${selectedSubLand.q}/${selectedSubLand.r}`;
                  }}
                  className="w-full bg-gradient-to-r from-purple-600 to-indigo-600 text-xs h-8"
                >
                  🔍 Enter xLand Overview
                </Button>
              )}
            </div>
          </div>
        </Card>
      )}

      {/* Main Canvas - Square with hexagonal map */}
      <div
        ref={containerRef}
        className="absolute inset-0 top-12 flex items-center justify-center"
      >
        <canvas
          ref={canvasRef}
          width={canvasSize}
          height={canvasSize}
          className="cursor-crosshair touch-none"
          style={{ width: `${canvasSize}px`, height: `${canvasSize}px` }}
          onMouseDown={handleMouseDown}
          onMouseMove={handleMouseMove}
          onMouseUp={handleMouseUp}
          onMouseLeave={handleMouseUp}
          onClick={handleCanvasClick}
          onWheel={handleWheel}
          onTouchStart={handleTouchStart}
          onTouchMove={handleTouchMove}
          onTouchEnd={handleTouchEnd}
        />
      </div>
    </main>
  );
}

// Helper functions

function isDuchyCapitalHex(q: number, r: number): boolean {
  // Central hexagon and its 6 neighbors are reserved for duchy capital
  // Central: (0, 0)
  // Neighbors: (1,0), (1,-1), (0,-1), (-1,0), (-1,1), (0,1)
  if (q === 0 && r === 0) return true;
  if (q === 1 && r === 0) return true;
  if (q === 1 && r === -1) return true;
  if (q === 0 && r === -1) return true;
  if (q === -1 && r === 0) return true;
  if (q === -1 && r === 1) return true;
  if (q === 0 && r === 1) return true;
  return false;
}

function getBiomeColor(subland: SubLand): string {
  // Special case: if parent terrain is ocean, show as water
  if (subland.biomeType === 'coast' && subland.resourceType === 'standard') {
    // This is likely an ocean tile, show as water
    return '#3b82f6'; // Blue water
  }

  switch (subland.biomeType) {
    case 'mountain':
      return '#8B8B8B'; // Gray
    case 'forest':
      return '#2D5016'; // Dark green
    case 'jungle':
      return '#1A3A1A'; // Very dark green
    case 'boreal_forest':
      return '#1E4D2B'; // Dark teal green for boreal
    case 'tundra':
      return '#C0D8E0'; // Light blue-gray
    case 'meadow':
      return '#84cc16'; // Pradera - light green
    case 'hills':
      return '#65a30d'; // Colinas - olive green
    case 'desert':
      return '#E5C29F'; // Sandy
    case 'coast':
      return '#B8A68D'; // Light brown
    case 'plains':
    default:
      return '#7FB069'; // Green
  }
}

function adjustColorBrightness(color: string, amount: number): string {
  const hex = color.replace('#', '');
  const r = Math.max(0, Math.min(255, parseInt(hex.substring(0, 2), 16) + amount));
  const g = Math.max(0, Math.min(255, parseInt(hex.substring(2, 4), 16) + amount));
  const b = Math.max(0, Math.min(255, parseInt(hex.substring(4, 6), 16) + amount));
  return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`;
}

// Hexagonal helper functions

function drawNaturalFeaturesHex(
  ctx: CanvasRenderingContext2D,
  centerX: number,
  centerY: number,
  hexSize: number,
  biomeType: string,
  scale: number
): void {
  ctx.save();

  if (biomeType === 'forest' || biomeType === 'jungle' || biomeType === 'boreal_forest') {
    // Draw 2-4 small trees within hexagon
    const treeCount = Math.floor(Math.random() * 3) + 2;
    let treeColor = '#1A4D2E'; // Default forest green

    if (biomeType === 'jungle') {
      treeColor = '#0D2818'; // Very dark green for jungle
    } else if (biomeType === 'boreal_forest') {
      treeColor = '#0F3D26'; // Dark teal green for boreal
    }

    for (let i = 0; i < treeCount; i++) {
      const angle = (Math.random() * Math.PI * 2);
      const radius = Math.random() * hexSize * 0.5;
      const treeX = centerX + Math.cos(angle) * radius;
      const treeY = centerY + Math.sin(angle) * radius;
      const treeSize = (Math.random() * 2 + 2) / scale;

      // Tree trunk
      ctx.fillStyle = '#4A2C2A';
      ctx.fillRect(treeX - treeSize / 4, treeY, treeSize / 2, treeSize);

      // Tree crown
      ctx.fillStyle = treeColor;
      ctx.beginPath();
      ctx.arc(treeX, treeY, treeSize, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  ctx.restore();
}

function drawBuildingHex(
  ctx: CanvasRenderingContext2D,
  centerX: number,
  centerY: number,
  hexSize: number,
  building: PlacedBuilding,
  config: { name: string; type: string; areaM2: number; category: string },
  scale: number
): void {
  ctx.save();

  // Calculate building size proportional to area
  const areaRatio = Math.sqrt(config.areaM2 / 1000000); // Ratio to 1km²
  const buildingSize = hexSize * areaRatio * 1.2;

  // Position within hexagon (offset from center)
  const offsetAngle = (building.position.offsetX * 2 - 1) * Math.PI;
  const offsetRadius = (building.position.offsetY * 0.5) * hexSize;
  const buildingX = centerX + Math.cos(offsetAngle) * offsetRadius;
  const buildingY = centerY + Math.sin(offsetAngle) * offsetRadius;

  // Special rendering for urban_core (village)
  if (config.type === 'urban_core') {
    // Draw as a cluster of small houses
    ctx.fillStyle = '#D2691E';
    ctx.fillRect(buildingX - buildingSize / 2, buildingY - buildingSize / 2, buildingSize, buildingSize);

    // Add small house icons
    ctx.fillStyle = '#8B4513';
    const houseSize = buildingSize / 4;
    for (let i = 0; i < 4; i++) {
      const hx = buildingX - buildingSize / 4 + (i % 2) * buildingSize / 2;
      const hy = buildingY - buildingSize / 4 + Math.floor(i / 2) * buildingSize / 2;
      ctx.fillRect(hx - houseSize / 2, hy - houseSize / 2, houseSize, houseSize);
    }

    // Border
    ctx.strokeStyle = '#FFD700';
    ctx.lineWidth = 1.5 / scale;
    ctx.strokeRect(buildingX - buildingSize / 2, buildingY - buildingSize / 2, buildingSize, buildingSize);
    return;
  }

  // Special rendering for town
  if (config.type === 'town') {
    // Draw as large castle/fortress
    ctx.fillStyle = '#8B4513';
    ctx.fillRect(buildingX - buildingSize / 2, buildingY - buildingSize / 2, buildingSize, buildingSize);

    // Add towers in corners
    ctx.fillStyle = '#654321';
    const towerSize = buildingSize / 5;
    const corners = [
      [buildingX - buildingSize / 2, buildingY - buildingSize / 2],
      [buildingX + buildingSize / 2 - towerSize, buildingY - buildingSize / 2],
      [buildingX - buildingSize / 2, buildingY + buildingSize / 2 - towerSize],
      [buildingX + buildingSize / 2 - towerSize, buildingY + buildingSize / 2 - towerSize]
    ];
    for (const corner of corners) {
      ctx.fillRect(corner[0], corner[1], towerSize, towerSize);
    }

    // Golden border
    ctx.strokeStyle = '#FFD700';
    ctx.lineWidth = 2 / scale;
    ctx.strokeRect(buildingX - buildingSize / 2, buildingY - buildingSize / 2, buildingSize, buildingSize);
    return;
  }

  if (config.type === 'farm') {
    // Draw plowed field pattern
    ctx.fillStyle = '#8B7355';
    ctx.fillRect(buildingX - buildingSize / 2, buildingY - buildingSize / 2, buildingSize, buildingSize);

    // Draw rows
    ctx.strokeStyle = '#6B5344';
    ctx.lineWidth = 0.5 / scale;
    const rowCount = 5;
    for (let i = 0; i <= rowCount; i++) {
      const rowY = buildingY - buildingSize / 2 + (i * buildingSize / rowCount);
      ctx.beginPath();
      ctx.moveTo(buildingX - buildingSize / 2, rowY);
      ctx.lineTo(buildingX + buildingSize / 2, rowY);
      ctx.stroke();
    }
  } else {
    // Draw building as roof/structure
    const roofColors: Record<string, string> = {
      residential: '#A0522D',
      production: '#8B4513',
      commerce: '#CD853F',
      infrastructure: '#696969',
      special: '#DAA520',
      settlement: '#D2691E'
    };

    const roofColor = roofColors[config.category as keyof typeof roofColors] || '#8B4513';

    // Building base
    ctx.fillStyle = '#5C4033';
    ctx.fillRect(buildingX - buildingSize / 2, buildingY - buildingSize / 2, buildingSize, buildingSize);

    // Roof (slightly smaller, offset up-left for 3D effect)
    const roofOffset = buildingSize * 0.1;
    ctx.fillStyle = roofColor;
    ctx.fillRect(
      buildingX - buildingSize / 2 - roofOffset,
      buildingY - buildingSize / 2 - roofOffset,
      buildingSize,
      buildingSize
    );

    // Roof highlight
    ctx.fillStyle = 'rgba(255, 255, 255, 0.2)';
    ctx.fillRect(
      buildingX - buildingSize / 2 - roofOffset,
      buildingY - buildingSize / 2 - roofOffset,
      buildingSize,
      buildingSize * 0.3
    );
  }

  ctx.restore();
}
