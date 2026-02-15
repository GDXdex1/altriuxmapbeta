'use client';

import { use } from 'react';
import { useState, useRef, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { ArrowLeft, ZoomIn, ZoomOut, Leaf, Mountain, Droplet, MapPin, X, Building2, Coins } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card } from '@/components/ui/card';
import type { HexTile as HexTileType } from '@/lib/hexmap/types';
import { generateEarthMap } from '@/lib/hexmap/generator';
import { getHexKey, axialToPixel, pixelToAxial } from '@/lib/hexmap/hex-utils';
import type { SubLand } from '@/lib/sublands/types';
import { generateSubLandsForHex } from '@/lib/sublands/generator';
import { BUILDING_CONFIGS, formatArea, getAvailableBuildings } from '@/lib/sublands/building-config';

interface ViewPort {
  x: number;
  y: number;
  scale: number;
}

interface XLandOverviewPageProps {
  params: Promise<{
    parentQ: string;
    parentR: string;
    subQ: string;
    subR: string;
  }>;
}

interface Parcel {
  q: number;
  r: number;
  color: string;
  status: 'virgin' | 'claimed' | 'developed';
  owner?: string;
  buildings: ParcelBuilding[];
  isRestricted?: boolean; // Central 7 parcels restricted to xLand owner
  resourceType: string; // Type of terrain (coastal_inland, standard, etc.)
  isAdjacentToWater?: boolean; // Adjacent to coastal_inland parcels
}

interface ParcelBuilding {
  id: string;
  type: string;
  builtAt: Date;
}

export default function XLandOverviewPage({ params }: XLandOverviewPageProps): JSX.Element {
  const resolvedParams = use(params);
  const parentQ = parseInt(resolvedParams.parentQ, 10);
  const parentR = parseInt(resolvedParams.parentR, 10);
  const subQ = parseInt(resolvedParams.subQ, 10);
  const subR = parseInt(resolvedParams.subR, 10);

  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  // Parcels: 10x10 grid, radius 5 gives ~90-100 hexagons
  const PARCEL_RADIUS = 5;
  const PARCEL_SIZE = 40; // Pixel size for each parcel hexagon

  const [viewport, setViewport] = useState<ViewPort>({
    x: 0,
    y: 0,
    scale: 0.5
  });

  // Touch state for pinch zoom
  const [touchState, setTouchState] = useState<{
    initialDistance: number;
    initialScale: number;
  } | null>(null);

  const [canvasSize, setCanvasSize] = useState<number>(800);
  const [parentTile, setParentTile] = useState<HexTileType | null>(null);
  const [parentSubland, setParentSubland] = useState<SubLand | null>(null);
  const [parcels, setParcels] = useState<Parcel[]>([]);
  const [selectedParcel, setSelectedParcel] = useState<Parcel | null>(null);
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const [dragStart, setDragStart] = useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const [isClaiming, setIsClaiming] = useState<boolean>(false);
  const [isBuilding, setIsBuilding] = useState<boolean>(false);
  const [showBuildMenu, setShowBuildMenu] = useState<boolean>(false);

  useEffect(() => {
    const initializeMap = async () => {
      const mapTiles = await generateEarthMap(42, 1);
      const key = getHexKey(parentQ, parentR);
      const tile = mapTiles.get(key);

      if (tile) {
        setParentTile(tile);

        const sublands = generateSubLandsForHex(tile, parentQ, parentR);
        const subland = sublands.find(sl => sl.q === subQ && sl.r === subR);

        if (subland) {
          setParentSubland(subland);

          // Generate parcels (10x10 grid)
          const generatedParcels = generateParcels(subland);
          setParcels(generatedParcels);
        }
      }
    };

    initializeMap();
  }, [parentQ, parentR, subQ, subR]);

  useEffect(() => {
    const updateCanvasSize = (): void => {
      if (containerRef.current) {
        const container = containerRef.current;
        const size = Math.min(container.clientWidth, container.clientHeight);
        setCanvasSize(size);

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

  const handleClaimParcel = async (): Promise<void> => {
    if (!selectedParcel || selectedParcel.status !== 'virgin') return;

    setIsClaiming(true);
    await new Promise(resolve => setTimeout(resolve, 1500));

    setParcels(prev => prev.map(p =>
      p.q === selectedParcel.q && p.r === selectedParcel.r
        ? { ...p, status: 'claimed', owner: '0x1234...5678' }
        : p
    ));

    setSelectedParcel(prev => prev ? { ...prev, status: 'claimed', owner: '0x1234...5678' } : null);
    setIsClaiming(false);
  };

  const handleBuildBuilding = async (buildingType: string): Promise<void> => {
    if (!selectedParcel || selectedParcel.owner !== '0x1234...5678') return;

    setIsBuilding(true);
    await new Promise(resolve => setTimeout(resolve, 1500));

    const newBuilding: ParcelBuilding = {
      id: `${Date.now()}-${Math.random()}`,
      type: buildingType,
      builtAt: new Date()
    };

    setParcels(prev => prev.map(p =>
      p.q === selectedParcel.q && p.r === selectedParcel.r
        ? { ...p, status: 'developed', buildings: [...p.buildings, newBuilding] }
        : p
    ));

    setSelectedParcel(prev => prev ? {
      ...prev,
      status: 'developed',
      buildings: [...prev.buildings, newBuilding]
    } : null);

    setIsBuilding(false);
    setShowBuildMenu(false);
  };

  const renderParcels = useCallback((): void => {
    const canvas = canvasRef.current;
    if (!canvas || parcels.length === 0) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Fill background with black
    ctx.fillStyle = '#000000';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    ctx.save();
    ctx.translate(viewport.x, viewport.y);
    ctx.scale(viewport.scale, viewport.scale);

    // Create hexagonal clipping path
    ctx.save();
    ctx.beginPath();
    const mapHexSize = PARCEL_RADIUS * PARCEL_SIZE * 2.6;
    const rotationOffset = Math.PI / 3;
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

    // Draw parcels
    for (const parcel of parcels) {
      const pixel = axialToPixel(parcel.q, parcel.r, PARCEL_SIZE);

      let color = parcel.color;

      // Color based on status
      if (parcel.status === 'claimed') {
        color = '#22C55E'; // Green for claimed
      } else if (parcel.status === 'developed') {
        color = '#9333EA'; // Purple for developed with buildings
      }

      // Draw parcel hexagon
      ctx.fillStyle = color;
      ctx.beginPath();
      for (let i = 0; i < 6; i++) {
        const angle = (Math.PI / 3) * i;
        const hx = pixel.x + PARCEL_SIZE * Math.cos(angle);
        const hy = pixel.y + PARCEL_SIZE * Math.sin(angle);
        if (i === 0) {
          ctx.moveTo(hx, hy);
        } else {
          ctx.lineTo(hx, hy);
        }
      }
      ctx.closePath();
      ctx.fill();

      // Border
      ctx.strokeStyle = 'rgba(255, 255, 255, 0.3)';
      ctx.lineWidth = 1 / viewport.scale;
      ctx.stroke();

      // Draw buildings as icons
      if (parcel.buildings.length > 0) {
        ctx.fillStyle = '#FFD700';
        ctx.font = `${20 / viewport.scale}px Arial`;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText('🏗️', pixel.x, pixel.y);
      }

      // Draw lock icon for restricted parcels
      if (parcel.isRestricted && parcel.status === 'virgin') {
        ctx.fillStyle = '#FF6B6B';
        ctx.font = `${16 / viewport.scale}px Arial`;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText('🔒', pixel.x, pixel.y);
      }

      // Selected highlight
      if (selectedParcel && selectedParcel.q === parcel.q && selectedParcel.r === parcel.r) {
        ctx.strokeStyle = '#FF0000';
        ctx.lineWidth = 3 / viewport.scale;
        ctx.beginPath();
        for (let i = 0; i < 6; i++) {
          const angle = (Math.PI / 3) * i;
          const hx = pixel.x + PARCEL_SIZE * Math.cos(angle);
          const hy = pixel.y + PARCEL_SIZE * Math.sin(angle);
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

    ctx.restore();

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
  }, [parcels, viewport, selectedParcel, PARCEL_RADIUS, PARCEL_SIZE]);

  useEffect(() => {
    renderParcels();
  }, [renderParcels]);

  const handleCanvasClick = (e: React.MouseEvent<HTMLCanvasElement>): void => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const rect = canvas.getBoundingClientRect();
    const clickX = (e.clientX - rect.left - viewport.x) / viewport.scale;
    const clickY = (e.clientY - rect.top - viewport.y) / viewport.scale;

    const axial = pixelToAxial(clickX, clickY, PARCEL_SIZE);

    const parcel = parcels.find(p => p.q === axial.q && p.r === axial.r);

    if (parcel) {
      setSelectedParcel(parcel);
      setShowBuildMenu(false);
    }
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

  const handleZoomIn = (): void => {
    setViewport({ ...viewport, scale: Math.min(3.0, viewport.scale * 1.2) });
  };

  const handleZoomOut = (): void => {
    setViewport({ ...viewport, scale: Math.max(0.5, viewport.scale / 1.2) });
  };

  const handleReset = (): void => {
    const centerOffsetX = canvasSize / 2;
    const centerOffsetY = canvasSize / 2;
    setViewport({ x: centerOffsetX, y: centerOffsetY, scale: 0.5 });
  };

  // Calculate distance between two touch points
  const getTouchDistance = (touch1: React.Touch, touch2: React.Touch): number => {
    const dx = touch1.clientX - touch2.clientX;
    const dy = touch1.clientY - touch2.clientY;
    return Math.sqrt(dx * dx + dy * dy);
  };

  // Touch handlers for pinch zoom
  const handleTouchStart = (e: React.TouchEvent<HTMLCanvasElement>): void => {
    if (e.touches.length === 2) {
      // Pinch zoom start
      const distance = getTouchDistance(e.touches[0]!, e.touches[1]!);
      setTouchState({
        initialDistance: distance,
        initialScale: viewport.scale
      });
      setIsDragging(false);
    } else if (e.touches.length === 1) {
      // Single touch for panning
      const touch = e.touches[0]!;
      setIsDragging(true);
      setDragStart({ x: touch.clientX - viewport.x, y: touch.clientY - viewport.y });
      setTouchState(null);
    }
  };

  const handleTouchMove = (e: React.TouchEvent<HTMLCanvasElement>): void => {
    if (e.touches.length === 2 && touchState) {
      // Pinch zoom
      e.preventDefault();
      const currentDistance = getTouchDistance(e.touches[0]!, e.touches[1]!);
      const scaleFactor = currentDistance / touchState.initialDistance;
      const newScale = Math.max(0.3, Math.min(3.0, touchState.initialScale * scaleFactor));

      setViewport(prev => ({
        ...prev,
        scale: newScale
      }));
    } else if (e.touches.length === 1 && isDragging) {
      // Pan
      const touch = e.touches[0]!;
      setViewport(prev => ({
        ...prev,
        x: touch.clientX - dragStart.x,
        y: touch.clientY - dragStart.y
      }));
    }
  };

  const handleTouchEnd = (): void => {
    setIsDragging(false);
    setTouchState(null);
  };

  const getBiomeIcon = (biomeType: string): JSX.Element => {
    switch (biomeType) {
      case 'mountain':
        return <Mountain className="w-4 h-4 text-gray-400" />;
      case 'forest':
      case 'jungle':
      case 'boreal_forest':
        return <Leaf className="w-4 h-4 text-green-500" />;
      case 'coast':
      case 'ocean':
        return <Droplet className="w-4 h-4 text-blue-400" />;
      default:
        return <MapPin className="w-4 h-4 text-amber-400" />;
    }
  };

  // Get available buildings based on parcel properties
  const getAvailableBuildingsForParcel = (parcel: Parcel): string[] => {
    if (!parcel || parcel.owner !== '0x1234...5678') return [];

    // Calculate available area
    const usedArea = parcel.buildings.reduce((sum, b) => {
      const config = BUILDING_CONFIGS[b.type as keyof typeof BUILDING_CONFIGS];
      return sum + (config?.areaM2 || 0);
    }, 0);
    const availableArea = 10000 - usedArea; // 1 hectare = 10,000 m²

    // Create a mock subland object for the function
    const mockSubland = {
      status: parcel.status,
      buildings: parcel.buildings.map(b => ({ type: b.type })),
      resourceType: parcel.resourceType
    };

    // Get available buildings using the validation function
    const available = getAvailableBuildings(
      false, // hasRiver
      false, // isNavigableRiver
      false, // hasSpecialNFTs
      availableArea,
      'none', // nftType
      mockSubland,
      undefined, // hexagonData
      parcel.isAdjacentToWater // isAdjacentToCoastalInland
    );

    return available.map(config => config.type);
  };

  const availableBuildings = selectedParcel ? getAvailableBuildingsForParcel(selectedParcel) : [];

  return (
    <main className="fixed inset-0 bg-gradient-to-br from-slate-900 via-purple-900 to-slate-800 overflow-hidden">
      {/* Top Bar with Info */}
      <div className="absolute top-0 left-0 right-0 z-20 bg-black/60 backdrop-blur-sm p-2">
        <div className="flex items-center justify-between">
          <Link href={`/land-detail/${parentQ}/${parentR}`}>
            <Button variant="ghost" size="sm" className="text-white hover:bg-white/20 h-8 px-2">
              <ArrowLeft className="w-4 h-4 mr-1" />
              Volver al xLand
            </Button>
          </Link>

          <div className="flex-1 px-4">
            <div className="flex items-center justify-center gap-4 text-xs">
              {parentSubland && (
                <>
                  <div className="flex items-center gap-2 bg-purple-900/40 px-3 py-1 rounded">
                    {getBiomeIcon(parentSubland.biomeType)}
                    <span className="text-white/90">Parcelas de xLand ({subQ}, {subR})</span>
                    <Badge className="bg-green-500/20 text-green-300 capitalize text-[10px]">
                      {parentSubland.biomeType}
                    </Badge>
                  </div>

                  <div className="flex items-center gap-2 bg-amber-900/40 px-3 py-1 rounded">
                    <span className="text-white/70">Parcelas:</span>
                    <span className="text-amber-300 font-bold">~{parcels.length}</span>
                  </div>

                  <div className="flex items-center gap-2 bg-amber-900/40 px-3 py-1 rounded">
                    <span className="text-white/70">Tamaño Parcela:</span>
                    <span className="text-amber-300 font-bold">100m × 100m</span>
                  </div>
                </>
              )}
            </div>
          </div>

          {/* Zoom Controls */}
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
      </div>

      {/* Parcel Panel */}
      {selectedParcel && (
        <Card className="absolute top-14 left-2 right-2 md:left-auto md:right-4 md:w-96 z-30 bg-black/95 backdrop-blur-sm border-amber-500/50 max-h-[75vh] overflow-y-auto">
          <div className="p-3">
            <button
              onClick={() => {
                setSelectedParcel(null);
                setShowBuildMenu(false);
              }}
              className="absolute top-2 right-2 text-white/70 hover:text-white"
            >
              <X className="w-4 h-4" />
            </button>

            <h3 className="text-amber-400 font-bold text-sm mb-2">Parcela (100m × 100m)</h3>

            <div className="space-y-2 text-xs mb-3">
              <div className="flex justify-between">
                <span className="text-white/70">Posición:</span>
                <span className="text-white">({selectedParcel.q}, {selectedParcel.r})</span>
              </div>

              <div className="flex justify-between">
                <span className="text-white/70">Estado:</span>
                <Badge className={`text-[10px] ${selectedParcel.status === 'virgin' ? 'bg-green-500/20 text-green-300' :
                    selectedParcel.status === 'claimed' ? 'bg-blue-500/20 text-blue-300' :
                      'bg-purple-500/20 text-purple-300'
                  }`}>
                  {selectedParcel.status}
                </Badge>
              </div>

              <div className="flex justify-between">
                <span className="text-white/70">Área:</span>
                <span className="text-white">1 hectárea (10,000 m²)</span>
              </div>

              {selectedParcel.isAdjacentToWater && (
                <div className="flex items-center gap-1 bg-blue-900/30 p-1 rounded">
                  <Droplet className="w-3 h-3 text-blue-400" />
                  <span className="text-blue-300 text-[10px]">Adyacente al agua</span>
                </div>
              )}
            </div>

            {selectedParcel.status === 'virgin' ? (
              <div className="space-y-2">
                {selectedParcel.isRestricted ? (
                  <div className="bg-red-500/10 p-2 rounded text-[10px] text-red-200">
                    🔒 <strong>Parcela Restringida</strong><br />
                    Esta es una de las 7 parcelas centrales del xLand. Solo el dueño del xLand puede reclamarla.
                  </div>
                ) : (
                  <>
                    <div className="bg-yellow-500/10 p-2 rounded text-[10px] text-yellow-200">
                      Esta parcela está disponible para reclamar.
                    </div>

                    <Button
                      onClick={handleClaimParcel}
                      disabled={isClaiming}
                      className="w-full bg-gradient-to-r from-green-600 to-emerald-600 text-xs h-8"
                    >
                      {isClaiming ? 'Reclamando...' : (
                        <>
                          <Coins className="w-3 h-3 mr-1" />
                          Reclamar Parcela (Burn 5 SLX)
                        </>
                      )}
                    </Button>
                  </>
                )}
              </div>
            ) : (
              <div className="space-y-2">
                <div className="text-[10px]">
                  <span className="text-white/70">Dueño:</span>
                  <span className="text-white ml-1">{selectedParcel.owner}</span>
                </div>

                {selectedParcel.buildings.length > 0 && (
                  <div className="bg-purple-600/20 p-2 rounded">
                    <p className="text-white/80 text-[11px] mb-1">Edificios ({selectedParcel.buildings.length}):</p>
                    <div className="space-y-1">
                      {selectedParcel.buildings.map(building => {
                        const config = BUILDING_CONFIGS[building.type as keyof typeof BUILDING_CONFIGS];
                        return (
                          <div key={building.id} className="text-[10px] text-white/70 flex items-center gap-1">
                            <Building2 className="w-3 h-3" />
                            <span>{config?.name || building.type}</span>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                )}

                {selectedParcel.owner === '0x1234...5678' && (
                  <>
                    {!showBuildMenu ? (
                      <Button
                        onClick={() => setShowBuildMenu(true)}
                        className="w-full bg-blue-600/20 hover:bg-blue-600/30 border border-blue-500/30 h-8 text-xs"
                      >
                        <Building2 className="w-3 h-3 mr-1" />
                        Construir Edificio
                      </Button>
                    ) : (
                      <div className="space-y-1 max-h-64 overflow-y-auto border-t border-white/10 pt-2">
                        <p className="text-white/80 text-[11px] mb-1">Edificios Disponibles:</p>
                        {availableBuildings.map((type) => {
                          const config = BUILDING_CONFIGS[type as keyof typeof BUILDING_CONFIGS];
                          if (!config) return null;

                          return (
                            <button
                              key={type}
                              onClick={() => handleBuildBuilding(type)}
                              disabled={isBuilding}
                              className="w-full bg-blue-600/20 hover:bg-blue-600/30 border border-blue-500/30 p-2 rounded text-left text-[10px]"
                            >
                              <div className="flex justify-between items-center">
                                <span className="text-white font-semibold">{config.name}</span>
                                <span className="text-amber-400 font-bold">{config.slxCost} SLX</span>
                              </div>
                              <div className="text-white/60 mt-1">{formatArea(config.areaM2)}</div>
                            </button>
                          );
                        })}
                      </div>
                    )}
                  </>
                )}
              </div>
            )}
          </div>
        </Card>
      )}

      {/* Compass */}
      <div className="absolute bottom-4 right-4 z-30 bg-black/80 backdrop-blur-sm rounded-full border-2 border-amber-500/50 w-20 h-20 flex items-center justify-center">
        <div className="relative w-full h-full">
          <div className="absolute top-1 left-1/2 -translate-x-1/2 text-red-500 font-bold text-sm">N</div>
          <div className="absolute bottom-1 left-1/2 -translate-x-1/2 text-blue-400 font-bold text-sm">S</div>
          <div className="absolute right-1 top-1/2 -translate-y-1/2 text-white/70 font-semibold text-xs">E</div>
          <div className="absolute left-1 top-1/2 -translate-y-1/2 text-white/70 font-semibold text-xs">W</div>
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-2 h-2 bg-amber-500 rounded-full"></div>
          <div className="absolute top-5 left-1/2 -translate-x-1/2 w-0 h-0 border-l-4 border-r-4 border-b-6 border-l-transparent border-r-transparent border-b-red-500"></div>
        </div>
      </div>

      {/* Main Canvas */}
      <div
        ref={containerRef}
        className="absolute inset-0 top-14 flex items-center justify-center"
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

function generateParcels(subland: SubLand): Parcel[] {
  const parcels: Parcel[] = [];
  const radius = 5; // ~10x10 grid (approximately 91 hexagons)

  const baseColor = getBiomeColor(subland.biomeType);

  // Define the 7 central parcels (center + 6 neighbors)
  const centralParcels = [
    { q: 0, r: 0 },     // Center
    { q: 1, r: 0 },     // East
    { q: 1, r: -1 },    // Northeast
    { q: 0, r: -1 },    // Northwest
    { q: -1, r: 0 },    // West
    { q: -1, r: 1 },    // Southwest
    { q: 0, r: 1 }      // Southeast
  ];

  // Generate water parcels at edges (coastal_inland) - simulating ocean adjacency
  const waterParcels: Array<{ q: number; r: number }> = [];

  // For coastal biomes, add some water parcels at the edges
  if (subland.biomeType === 'coast') {
    for (let q = -radius; q <= radius; q++) {
      const r1 = Math.max(-radius, -q - radius);
      const r2 = Math.min(radius, -q + radius);

      for (let r = r1; r <= r2; r++) {
        // Check if this is an edge parcel
        const isEdge = Math.abs(q) === radius || Math.abs(r) === radius || Math.abs(-q - r) === radius;

        // 60% chance for edge parcels to be water in coastal biomes
        if (isEdge && Math.random() < 0.6) {
          waterParcels.push({ q, r });
        }
      }
    }
  }

  // Generate all parcels
  for (let q = -radius; q <= radius; q++) {
    const r1 = Math.max(-radius, -q - radius);
    const r2 = Math.min(radius, -q + radius);

    for (let r = r1; r <= r2; r++) {
      // Check if this parcel is one of the central 7
      const isRestricted = centralParcels.some(cp => cp.q === q && cp.r === r);

      // Check if this is a water parcel
      const isWater = waterParcels.some(wp => wp.q === q && wp.r === r);
      const resourceType = isWater ? 'coastal_inland' : 'standard';

      parcels.push({
        q,
        r,
        color: isWater ? '#4A90E2' : addColorVariation(baseColor, 15), // Blue for water
        status: 'virgin',
        buildings: [],
        isRestricted,
        resourceType
      });
    }
  }

  // Calculate adjacency to water for each parcel
  for (const parcel of parcels) {
    if (parcel.resourceType !== 'coastal_inland') {
      const neighbors = [
        { q: parcel.q + 1, r: parcel.r },
        { q: parcel.q + 1, r: parcel.r - 1 },
        { q: parcel.q, r: parcel.r - 1 },
        { q: parcel.q - 1, r: parcel.r },
        { q: parcel.q - 1, r: parcel.r + 1 },
        { q: parcel.q, r: parcel.r + 1 }
      ];

      // Check if any neighbor is water
      parcel.isAdjacentToWater = neighbors.some(n =>
        waterParcels.some(wp => wp.q === n.q && wp.r === n.r)
      );
    } else {
      parcel.isAdjacentToWater = false; // Water parcels themselves are not adjacent to water
    }
  }

  return parcels;
}

function getBiomeColor(biomeType: string): string {
  switch (biomeType) {
    case 'mountain':
      return '#8B8B8B';
    case 'forest':
      return '#2D5016';
    case 'jungle':
      return '#1A3A1A';
    case 'boreal_forest':
      return '#1E4D2B';
    case 'tundra':
      return '#C0D8E0';
    case 'meadow':
      return '#84cc16';
    case 'hills':
      return '#65a30d';
    case 'desert':
      return '#E5C29F';
    case 'coast':
      return '#B8A68D';
    case 'plains':
    default:
      return '#7FB069';
  }
}

function addColorVariation(color: string, variation: number): string {
  const hex = color.replace('#', '');
  const r = parseInt(hex.substring(0, 2), 16);
  const g = parseInt(hex.substring(2, 4), 16);
  const b = parseInt(hex.substring(4, 6), 16);

  const vr = Math.floor(Math.random() * variation * 2) - variation;
  const vg = Math.floor(Math.random() * variation * 2) - variation;
  const vb = Math.floor(Math.random() * variation * 2) - variation;

  const nr = Math.max(0, Math.min(255, r + vr));
  const ng = Math.max(0, Math.min(255, g + vg));
  const nb = Math.max(0, Math.min(255, b + vb));

  return `#${nr.toString(16).padStart(2, '0')}${ng.toString(16).padStart(2, '0')}${nb.toString(16).padStart(2, '0')}`;
}
