'use client';

import React, { useState } from 'react';
import { ZoomIn, ZoomOut, Maximize2, MapPin, Edit3, ChevronDown, Download } from 'lucide-react';

interface MapHUDProps {
  resources: {
    atx: number;
    gdx: number;
    slx: number;
    bzx: number;
  };
  gameDate: string;
  season: string;
  onZoomIn: () => void;
  onZoomOut: () => void;
  onReset: () => void;
  onGoToPlayer: () => void;
  onOpenEditor?: () => void;
  onOpenResourceEditor?: () => void;
  onExportMap?: () => void;
  zoom: number;
}

export function MapHUD({
  resources,
  gameDate,
  season,
  onZoomIn,
  onZoomOut,
  onReset,
  onGoToPlayer,
  onOpenEditor,
  onOpenResourceEditor,
  onExportMap,
  zoom
}: MapHUDProps): JSX.Element {
  const [showResources, setShowResources] = useState<boolean>(false);

  return (
    <>
      {/* Top Bar - Clean header with Resources button */}
      <div className="absolute top-0 left-0 right-0 h-14 bg-gradient-to-b from-gray-900/95 to-gray-900/90 border-b border-gray-700 z-20 flex items-center justify-between px-4">
        {/* Left: Resources Dropdown Button */}
        <div className="relative">
          <button
            onClick={() => setShowResources(!showResources)}
            className="bg-gray-700/80 hover:bg-gray-600 px-4 py-2 rounded text-white text-sm font-semibold transition-all flex items-center gap-2"
          >
            📊 Resources
            <ChevronDown className={`w-4 h-4 transition-transform ${showResources ? 'rotate-180' : ''}`} />
          </button>

          {/* Resources Dropdown Panel */}
          {showResources && (
            <div className="absolute top-full mt-2 left-0 bg-gray-800/95 border border-gray-600 rounded-lg shadow-xl p-4 min-w-[320px] z-30">
              {/* Food Resources */}
              <div className="mb-3">
                <p className="text-white/70 text-[10px] font-semibold mb-2 uppercase tracking-wide">Food & Materials</p>
                <div className="flex items-center gap-3 flex-wrap">
                  <span className="text-amber-400 text-xs">🌾 1,234</span>
                  <span className="text-blue-400 text-xs">💎 567</span>
                  <span className="text-green-400 text-xs">🪵 890</span>
                </div>
              </div>

              {/* Currencies */}
              <div className="border-t border-gray-700 pt-3">
                <p className="text-white/70 text-[10px] font-semibold mb-2 uppercase tracking-wide">Currencies</p>
                <div className="flex flex-col gap-2">
                  <div className="flex items-center gap-2 bg-yellow-600/20 px-3 py-1.5 rounded">
                    <span className="text-yellow-400 font-bold text-sm">⚜️</span>
                    <span className="text-white text-xs font-bold">{resources.atx.toLocaleString()}</span>
                    <span className="text-white/60 text-[10px]">ATX</span>
                  </div>
                  <div className="flex items-center gap-2 bg-blue-600/20 px-3 py-1.5 rounded">
                    <span className="text-blue-400 font-bold text-sm">💠</span>
                    <span className="text-white text-xs font-bold">{resources.gdx.toLocaleString()}</span>
                    <span className="text-white/60 text-[10px]">GDX</span>
                  </div>
                  <div className="flex items-center gap-2 bg-purple-600/20 px-3 py-1.5 rounded">
                    <span className="text-purple-400 font-bold text-sm">⭐</span>
                    <span className="text-white text-xs font-bold">{resources.slx.toLocaleString()}</span>
                    <span className="text-white/60 text-[10px]">SLX</span>
                  </div>
                  <div className="flex items-center gap-2 bg-green-600/20 px-3 py-1.5 rounded">
                    <span className="text-green-400 font-bold text-sm">💚</span>
                    <span className="text-white text-xs font-bold">{resources.bzx.toLocaleString()}</span>
                    <span className="text-white/60 text-[10px]">BZX</span>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Center: Game Title or empty space */}
        <div className="text-white/80 text-sm font-bold tracking-wider">
          ALTRIUX TRIBAL
        </div>

        {/* Right: Inventory */}
        <button className="bg-gray-700/80 hover:bg-gray-600 px-3 py-1.5 rounded text-white text-xs font-semibold transition-all">
          🎒 Inventory
        </button>
      </div>

      {/* Left Sidebar - Zoom & Resource Editor Controls */}
      <div className="absolute left-0 top-14 bottom-10 w-14 bg-gradient-to-r from-gray-900/95 to-gray-900/90 border-r border-gray-700 z-20 flex flex-col items-center justify-center gap-3">
        <button
          onClick={onZoomIn}
          className="w-10 h-10 bg-gray-700/80 hover:bg-gray-600 rounded flex items-center justify-center transition-all"
          title="Zoom In"
        >
          <ZoomIn className="w-5 h-5 text-white" />
        </button>
        <div className="text-white text-[10px] font-mono">
          {Math.round(zoom * 100)}%
        </div>
        <button
          onClick={onZoomOut}
          className="w-10 h-10 bg-gray-700/80 hover:bg-gray-600 rounded flex items-center justify-center transition-all"
          title="Zoom Out"
        >
          <ZoomOut className="w-5 h-5 text-white" />
        </button>
        <button
          onClick={onReset}
          className="w-10 h-10 bg-gray-700/80 hover:bg-gray-600 rounded flex items-center justify-center transition-all mt-2"
          title="Reset View"
        >
          <Maximize2 className="w-5 h-5 text-white" />
        </button>

        {onOpenResourceEditor && (
          <button
            onClick={onOpenResourceEditor}
            className="w-10 h-10 bg-green-600/80 hover:bg-green-500 rounded flex items-center justify-center transition-all mt-6 shadow-lg shadow-green-900/20 border border-green-400/30"
            title="Add Resources Manually"
          >
            <div className="text-lg">💎</div>
          </button>
        )}
      </div>

      {/* Right Sidebar - Date, Info and Terrain Editor */}
      <div className="absolute right-0 top-14 bottom-10 w-14 bg-gradient-to-l from-gray-900/95 to-gray-900/90 border-l border-gray-700 z-20 flex flex-col items-center justify-center gap-3 px-1">
        <div className="text-center">
          <p className="text-white text-[9px] font-bold leading-tight">{gameDate}</p>
          <p className="text-white/70 text-[8px] leading-tight mt-1">{season}</p>
        </div>
        <button
          onClick={onGoToPlayer}
          className="w-10 h-10 bg-amber-600/80 hover:bg-amber-500 rounded flex items-center justify-center transition-all mt-3"
          title="My Location"
        >
          <MapPin className="w-5 h-5 text-white" />
        </button>

        {onOpenEditor && (
          <button
            onClick={onOpenEditor}
            className="w-10 h-10 bg-purple-600/80 hover:bg-purple-500 rounded flex items-center justify-center transition-all mt-2 border border-purple-400/30"
            title="Terrain Feature Editor"
          >
            <Edit3 className="w-5 h-5 text-white" />
          </button>
        )}

        {onExportMap && (
          <button
            onClick={onExportMap}
            className="w-10 h-10 bg-blue-600/80 hover:bg-blue-500 rounded flex items-center justify-center transition-all mt-6 border border-blue-400/30"
            title="Export Map to Image"
          >
            <Download className="w-5 h-5 text-white" />
          </button>
        )}
      </div>

      {/* Bottom Bar - Announcements */}
      <div className="absolute bottom-0 left-0 right-0 h-10 bg-gradient-to-t from-gray-900/95 to-gray-900/90 border-t border-gray-700 z-20 flex items-center justify-center px-4">
        <p className="text-white/50 text-xs italic">ALTRIUX WORLD EDITOR v1.2 | Season: {season.split('|')[0].trim()}</p>
      </div>
    </>
  );
}
