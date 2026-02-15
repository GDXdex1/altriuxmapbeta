'use client';

import React from 'react';
import { ChevronUp, ChevronDown, ChevronLeft, ChevronRight, ZoomIn, ZoomOut, Home, MapPin } from 'lucide-react';

interface MapControlsProps {
  onMove: (dx: number, dy: number) => void;
  onZoomIn: () => void;
  onZoomOut: () => void;
  onReset: () => void;
  onGoToPlayer: () => void;
  zoom: number;
}

export function MapControls({ onMove, onZoomIn, onZoomOut, onReset, onGoToPlayer, zoom }: MapControlsProps): JSX.Element {
  const moveSpeed = 100; // pixels per button press

  return (
    <>
      {/* Mobile Directional Controls - Bottom Left */}
      <div className="md:hidden absolute bottom-20 left-4 z-20">
        <div className="relative w-32 h-32">
          {/* Center Home Button */}
          <button
            onClick={onReset}
            className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-white/95 active:bg-gray-200 p-3 rounded-full shadow-xl touch-manipulation"
            aria-label="Reset view"
          >
            <Home className="w-5 h-5 text-gray-700" />
          </button>

          {/* Up */}
          <button
            onClick={() => onMove(0, moveSpeed)}
            className="absolute top-0 left-1/2 -translate-x-1/2 bg-white/90 active:bg-gray-200 p-2 rounded-lg shadow-lg touch-manipulation"
            aria-label="Move up"
          >
            <ChevronUp className="w-6 h-6" />
          </button>

          {/* Down */}
          <button
            onClick={() => onMove(0, -moveSpeed)}
            className="absolute bottom-0 left-1/2 -translate-x-1/2 bg-white/90 active:bg-gray-200 p-2 rounded-lg shadow-lg touch-manipulation"
            aria-label="Move down"
          >
            <ChevronDown className="w-6 h-6" />
          </button>

          {/* Left */}
          <button
            onClick={() => onMove(moveSpeed, 0)}
            className="absolute left-0 top-1/2 -translate-y-1/2 bg-white/90 active:bg-gray-200 p-2 rounded-lg shadow-lg touch-manipulation"
            aria-label="Move left"
          >
            <ChevronLeft className="w-6 h-6" />
          </button>

          {/* Right */}
          <button
            onClick={() => onMove(-moveSpeed, 0)}
            className="absolute right-0 top-1/2 -translate-y-1/2 bg-white/90 active:bg-gray-200 p-2 rounded-lg shadow-lg touch-manipulation"
            aria-label="Move right"
          >
            <ChevronRight className="w-6 h-6" />
          </button>
        </div>
      </div>

      {/* Go To Player Button - Bottom Center */}
      <div className="absolute bottom-2 left-1/2 -translate-x-1/2 z-20">
        <button
          onClick={onGoToPlayer}
          className="bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 active:from-amber-700 active:to-orange-800 text-white px-4 py-2 rounded-full shadow-xl font-semibold text-sm flex items-center gap-2 touch-manipulation transition-all"
          aria-label="Go to my location"
        >
          <MapPin className="w-5 h-5" />
          <span>My Location</span>
        </button>
      </div>

      {/* Zoom Controls - Bottom Right */}
      <div className="absolute bottom-20 right-4 z-20 flex flex-col gap-2">
        <button
          onClick={onZoomIn}
          className="bg-white/95 hover:bg-white active:bg-gray-200 p-3 rounded-lg shadow-xl font-bold text-xl touch-manipulation transition-colors"
          aria-label="Zoom in"
        >
          <ZoomIn className="w-6 h-6 md:hidden" />
          <span className="hidden md:inline px-2">+</span>
        </button>
        
        <div className="bg-white/95 px-3 py-2 rounded-lg shadow-xl text-center font-semibold text-sm">
          {Math.round(zoom * 100)}%
        </div>
        
        <button
          onClick={onZoomOut}
          className="bg-white/95 hover:bg-white active:bg-gray-200 p-3 rounded-lg shadow-xl font-bold text-xl touch-manipulation transition-colors"
          aria-label="Zoom out"
        >
          <ZoomOut className="w-6 h-6 md:hidden" />
          <span className="hidden md:inline px-2">−</span>
        </button>
      </div>

      {/* Desktop Controls - Right Side */}
      <div className="hidden md:flex absolute top-1/2 right-4 -translate-y-1/2 z-20 flex-col gap-2">
        <button
          onClick={onZoomIn}
          className="bg-white/90 hover:bg-white active:bg-gray-200 px-4 py-2 rounded-lg font-semibold shadow-lg text-xl"
        >
          +
        </button>
        <button
          onClick={onZoomOut}
          className="bg-white/90 hover:bg-white active:bg-gray-200 px-4 py-2 rounded-lg font-semibold shadow-lg text-xl"
        >
          −
        </button>
        <button
          onClick={onReset}
          className="bg-white/90 hover:bg-white active:bg-gray-200 px-3 py-2 rounded-lg text-sm font-semibold shadow-lg"
        >
          Reset
        </button>
      </div>
    </>
  );
}
