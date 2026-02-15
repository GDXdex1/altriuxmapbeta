'use client';

import { use } from 'react';
import { useState, useRef, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { ArrowLeft, ZoomIn, ZoomOut } from 'lucide-react';
import { Button } from '@/components/ui/button';
import type { HexTile as HexTileType } from '@/lib/hexmap/types';
import { generateEarthMap } from '@/lib/hexmap/generator';
import { getHexKey, axialToPixel, pixelToAxial } from '@/lib/hexmap/hex-utils';
import type { SubLand } from '@/lib/sublands/types';
import { generateSubLandsForHex } from '@/lib/sublands/generator';

interface ViewPort {
  x: number;
  y: number;
  scale: number;
}

interface XLandDetailPageProps {
  params: Promise<{
    parentQ: string;
    parentR: string;
    subQ: string;
    subR: string;
  }>;
}

interface XLandHex {
  q: number;
  r: number;
  color: string;
}

export default function XLandDetailPage({ params }: XLandDetailPageProps): JSX.Element {
  const resolvedParams = use(params);
  const parentQ = parseInt(resolvedParams.parentQ, 10);
  const parentR = parseInt(resolvedParams.parentR, 10);
  const subQ = parseInt(resolvedParams.subQ, 10);
  const subR = parseInt(resolvedParams.subR, 10);

  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  // XLand hexagonal grid settings: ~10,000 hexagons with radius 58
  const HEX_RADIUS = 58;
  const HEX_SIZE = 10;

  const [viewport, setViewport] = useState<ViewPort>({
    x: 0,
    y: 0,
    scale: 1.0
  });

  const [canvasSize, setCanvasSize] = useState<number>(800);
  const [parentTile, setParentTile] = useState<HexTileType | null>(null);
  const [parentSubland, setParentSubland] = useState<SubLand | null>(null);
  const [xlandHexes, setXlandHexes] = useState<XLandHex[]>([]);
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const [dragStart, setDragStart] = useState<{ x: number; y: number }>({ x: 0, y: 0 });

  useEffect(() => {
    const initializeMap = async () => {
      const mapTiles = await generateEarthMap(42, 1);
      const key = getHexKey(parentQ, parentR);
      const tile = mapTiles.get(key);

      if (tile) {
        setParentTile(tile);

        // Get the parent subland data
        const sublands = generateSubLandsForHex(tile, parentQ, parentR);
        const subland = sublands.find(sl => sl.q === subQ && sl.r === subR);

        if (subland) {
          setParentSubland(subland);

          // Generate xLand hexagons (dividing 1km into smaller hexagons)
          const hexes = generateXLandHexes(subland);
          setXlandHexes(hexes);
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

  const renderXLand = useCallback((): void => {
    const canvas = canvasRef.current;
    if (!canvas || xlandHexes.length === 0) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.save();
    ctx.translate(viewport.x, viewport.y);
    ctx.scale(viewport.scale, viewport.scale);

    // Create hexagonal clipping path
    ctx.save();
    ctx.beginPath();
    const mapHexSize = HEX_RADIUS * HEX_SIZE * 2.0;
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

    // Fill background
    ctx.fillStyle = '#000000';
    ctx.fill();

    // Draw xLand hexagons
    for (const hex of xlandHexes) {
      const pixel = axialToPixel(hex.q, hex.r, HEX_SIZE);

      ctx.fillStyle = hex.color;
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

      ctx.strokeStyle = 'rgba(255, 255, 255, 0.2)';
      ctx.lineWidth = 0.3 / viewport.scale;
      ctx.stroke();
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
  }, [xlandHexes, viewport]);

  useEffect(() => {
    renderXLand();
  }, [renderXLand]);

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
    setViewport({ x: centerOffsetX, y: centerOffsetY, scale: 1.0 });
  };

  return (
    <main className="fixed inset-0 bg-gradient-to-br from-slate-900 to-slate-800 overflow-hidden">
      {/* Top Bar */}
      <div className="absolute top-0 left-0 right-0 z-20 bg-black/40 backdrop-blur-sm p-2 flex items-center justify-between">
        <Link href={`/land-detail/${parentQ}/${parentR}`}>
          <Button variant="ghost" size="sm" className="text-white hover:bg-white/20 h-8 px-2">
            <ArrowLeft className="w-4 h-4" />
          </Button>
        </Link>

        <div className="flex-1 px-2">
          <p className="text-white/90 text-xs font-mono">
            xLand Detail (1km²) | Position: ({subQ}, {subR})
          </p>
          <p className="text-white/60 text-[10px]">
            Parent Duchy: ({parentQ}, {parentR}) | Biome: {parentSubland?.biomeType || 'Loading...'}
          </p>
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

      {/* Info Panel */}
      <div className="absolute top-14 left-2 z-30 bg-black/80 backdrop-blur-sm rounded border border-purple-500/50 p-2 text-xs">
        <div className="space-y-1 text-white/80">
          <div className="text-purple-300 font-bold mb-1">🔬 xLand (1km²)</div>
          <div className="flex justify-between gap-4">
            <span className="text-white/60">Total Hexagons:</span>
            <span className="text-green-300">{xlandHexes.length.toLocaleString()}</span>
          </div>
          <div className="flex justify-between gap-4">
            <span className="text-white/60">Biome:</span>
            <span className="text-blue-300 capitalize">{parentSubland?.biomeType || 'N/A'}</span>
          </div>
        </div>
      </div>

      {/* Compass */}
      <div className="absolute bottom-4 right-4 z-30 bg-black/80 backdrop-blur-sm rounded-full border-2 border-purple-500/50 w-20 h-20 flex items-center justify-center">
        <div className="relative w-full h-full">
          <div className="absolute top-1 left-1/2 -translate-x-1/2 text-red-500 font-bold text-sm">N</div>
          <div className="absolute bottom-1 left-1/2 -translate-x-1/2 text-blue-400 font-bold text-sm">S</div>
          <div className="absolute right-1 top-1/2 -translate-y-1/2 text-white/70 font-semibold text-xs">E</div>
          <div className="absolute left-1 top-1/2 -translate-y-1/2 text-white/70 font-semibold text-xs">W</div>
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-2 h-2 bg-purple-500 rounded-full"></div>
          <div className="absolute top-5 left-1/2 -translate-x-1/2 w-0 h-0 border-l-4 border-r-4 border-b-6 border-l-transparent border-r-transparent border-b-red-500"></div>
        </div>
      </div>

      {/* Main Canvas */}
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
          onWheel={handleWheel}
        />
      </div>
    </main>
  );
}

function generateXLandHexes(subland: SubLand): XLandHex[] {
  const hexes: XLandHex[] = [];
  const radius = 58; // Same radius as sublands for ~10,000 hexagons

  // Get base color from biome
  const baseColor = getBiomeColor(subland.biomeType);

  for (let q = -radius; q <= radius; q++) {
    const r1 = Math.max(-radius, -q - radius);
    const r2 = Math.min(radius, -q + radius);

    for (let r = r1; r <= r2; r++) {
      hexes.push({
        q,
        r,
        color: addColorVariation(baseColor, 10)
      });
    }
  }

  return hexes;
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
