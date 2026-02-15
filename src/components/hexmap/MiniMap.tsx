'use client';

import React, { useMemo } from 'react';
import type { HexTile } from '@/lib/hexmap/types';
import { getTerrainColor, axialToPixel } from '@/lib/hexmap/hex-utils';

interface MiniMapProps {
  tiles: Map<string, HexTile>;
  viewport: { x: number; y: number; scale: number };
  mapWidth: number;
  mapHeight: number;
  onNavigate: (x: number, y: number) => void;
}

export function MiniMap({ tiles, viewport, mapWidth, mapHeight, onNavigate }: MiniMapProps): JSX.Element {
  const miniMapWidth = 200;
  const miniMapHeight = 100;
  const HEX_SIZE = 20; // Must match HexMap component
  
  // Calculate map bounds in pixel coordinates
  const mapBounds = useMemo(() => {
    let minX = Infinity;
    let maxX = -Infinity;
    let minY = Infinity;
    let maxY = -Infinity;
    
    for (const [, tile] of tiles) {
      const { x, y } = axialToPixel(tile.coordinates.q, tile.coordinates.r, HEX_SIZE);
      minX = Math.min(minX, x);
      maxX = Math.max(maxX, x);
      minY = Math.min(minY, y);
      maxY = Math.max(maxY, y);
    }
    
    return {
      minX,
      maxX,
      minY,
      maxY,
      width: maxX - minX,
      height: maxY - minY,
      centerX: (minX + maxX) / 2,
      centerY: (minY + maxY) / 2
    };
  }, [tiles]);
  
  // Sample tiles for minimap (show every 8th tile for performance)
  const sampledTiles = useMemo(() => {
    return Array.from(tiles.values()).filter((_, i) => i % 8 === 0);
  }, [tiles]);

  const handleMiniMapClick = (e: React.MouseEvent<SVGSVGElement>): void => {
    const rect = e.currentTarget.getBoundingClientRect();
    const clickX = e.clientX - rect.left;
    const clickY = e.clientY - rect.top;
    
    // Convert minimap click to world coordinates
    const worldX = mapBounds.minX + (clickX / miniMapWidth) * mapBounds.width;
    const worldY = mapBounds.minY + (clickY / miniMapHeight) * mapBounds.height;
    
    // Get container size to center the click point
    if (typeof window !== 'undefined') {
      const containerWidth = window.innerWidth;
      const containerHeight = window.innerHeight;
      
      // Calculate viewport position to center the clicked point
      const newViewportX = -worldX * viewport.scale + containerWidth / 2;
      const newViewportY = -worldY * viewport.scale + containerHeight / 2;
      
      onNavigate(newViewportX, newViewportY);
    }
  };

  // Calculate viewport rectangle in minimap coordinates
  const getViewportRect = (): { x: number; y: number; width: number; height: number } => {
    if (typeof window === 'undefined') {
      return { x: 0, y: 0, width: 20, height: 20 };
    }
    
    const containerWidth = window.innerWidth;
    const containerHeight = window.innerHeight;
    
    // Calculate what world coordinates are visible
    const viewportWorldWidth = containerWidth / viewport.scale;
    const viewportWorldHeight = containerHeight / viewport.scale;
    const viewportWorldCenterX = -viewport.x / viewport.scale + viewportWorldWidth / 2;
    const viewportWorldCenterY = -viewport.y / viewport.scale + viewportWorldHeight / 2;
    
    // Convert to minimap coordinates
    const minimapCenterX = ((viewportWorldCenterX - mapBounds.minX) / mapBounds.width) * miniMapWidth;
    const minimapCenterY = ((viewportWorldCenterY - mapBounds.minY) / mapBounds.height) * miniMapHeight;
    const minimapWidth = (viewportWorldWidth / mapBounds.width) * miniMapWidth;
    const minimapHeight = (viewportWorldHeight / mapBounds.height) * miniMapHeight;
    
    return {
      x: minimapCenterX - minimapWidth / 2,
      y: minimapCenterY - minimapHeight / 2,
      width: minimapWidth,
      height: minimapHeight
    };
  };

  const viewportRect = getViewportRect();

  return (
    <div className="bg-gray-900/95 p-2 rounded-lg shadow-2xl border-2 border-yellow-500">
      <p className="text-xs font-bold text-yellow-400 mb-1 text-center tracking-wide">WORLD MAP</p>
      <div className="relative" style={{ width: miniMapWidth, height: miniMapHeight }}>
        <svg
          width={miniMapWidth}
          height={miniMapHeight}
          className="bg-blue-950 cursor-pointer rounded border border-yellow-600/50"
          onClick={handleMiniMapClick}
        >
          {/* Draw sampled tiles */}
          {sampledTiles.map((tile) => {
            const { x, y } = axialToPixel(tile.coordinates.q, tile.coordinates.r, HEX_SIZE);
            
            // Normalize coordinates to minimap
            const minimapX = ((x - mapBounds.minX) / mapBounds.width) * miniMapWidth;
            const minimapY = ((y - mapBounds.minY) / mapBounds.height) * miniMapHeight;
            
            return (
              <circle
                key={`${tile.coordinates.q},${tile.coordinates.r}`}
                cx={minimapX}
                cy={minimapY}
                r={1}
                fill={getTerrainColor(tile.terrain)}
                opacity={0.9}
              />
            );
          })}
          
          {/* Viewport indicator - bright yellow rectangle */}
          <rect
            x={viewportRect.x}
            y={viewportRect.y}
            width={viewportRect.width}
            height={viewportRect.height}
            fill="none"
            stroke="#fbbf24"
            strokeWidth={2}
            opacity={0.9}
          />
          
          {/* Viewport center crosshair */}
          <g opacity={0.8}>
            <line
              x1={viewportRect.x + viewportRect.width / 2 - 3}
              y1={viewportRect.y + viewportRect.height / 2}
              x2={viewportRect.x + viewportRect.width / 2 + 3}
              y2={viewportRect.y + viewportRect.height / 2}
              stroke="#fbbf24"
              strokeWidth={1.5}
            />
            <line
              x1={viewportRect.x + viewportRect.width / 2}
              y1={viewportRect.y + viewportRect.height / 2 - 3}
              x2={viewportRect.x + viewportRect.width / 2}
              y2={viewportRect.y + viewportRect.height / 2 + 3}
              stroke="#fbbf24"
              strokeWidth={1.5}
            />
          </g>
        </svg>
      </div>
      <div className="text-[9px] text-yellow-300/80 text-center mt-1 font-semibold">
        Click to navigate • Zoom: {(viewport.scale * 100).toFixed(0)}%
      </div>
    </div>
  );
}
