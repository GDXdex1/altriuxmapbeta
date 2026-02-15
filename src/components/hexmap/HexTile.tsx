'use client';

import React from 'react';
import type { HexTile as HexTileType } from '@/lib/hexmap/types';

interface HexTileProps {
  tile: HexTileType;
  size: number;
  x: number;
  y: number;
  onClick: (tile: HexTileType, event?: React.MouseEvent) => void;
  selected: boolean;
  isOnPath?: boolean;
}

const TERRAIN_COLORS: Record<string, string> = {
  ocean: '#1e40af',
  coast: '#3b82f6',
  ice: '#e0f2fe',
  plains: '#a3e635',
  meadow: '#84cc16',   // Pradera - lighter green
  hills: '#65a30d',    // Colinas - olive green
  mountain_range: '#78716c', // Cordillera
  tundra: '#cbd5e1',
  desert: '#fcd34d'
};

const TERRAIN_STROKE: Record<string, string> = {
  ocean: '#1e3a8a',
  coast: '#2563eb',
  ice: '#bae6fd',
  plains: '#84cc16',
  meadow: '#65a30d',   // Pradera stroke
  hills: '#4d7c0f',    // Colinas stroke
  mountain_range: '#57534e', // Cordillera stroke
  tundra: '#94a3b8',
  desert: '#fbbf24'
};

export function HexTile({ tile, size, x, y, onClick, selected, isOnPath = false }: HexTileProps): JSX.Element {
  const handleClick = (e: React.MouseEvent): void => {
    e.stopPropagation();
    onClick(tile, e);
  };

  // Generate hexagon points
  const points = Array.from({ length: 6 }, (_, i) => {
    const angle = (Math.PI / 3) * i;
    const px = x + size * Math.cos(angle);
    const py = y + size * Math.sin(angle);
    return `${px},${py}`;
  }).join(' ');

  const color = TERRAIN_COLORS[tile.terrain] || '#666';
  const strokeColor = TERRAIN_STROKE[tile.terrain] || '#000';
  
  // Check for terrain features
  const hasForest = tile.features?.includes('forest');
  const hasJungle = tile.features?.includes('jungle');
  const hasBorealForest = tile.features?.includes('boreal_forest');
  const hasOasis = tile.features?.includes('oasis');
  const hasVolcanoFeature = tile.features?.includes('volcano');
  const hasRiver = tile.features?.includes('river');
  
  // Determine if tile has resources to display (MAX 2 RESOURCES)
  const allResources = [
    ...tile.animals,
    ...tile.minerals,
    ...tile.resources
  ];
  
  // CRITICAL: Limit to MAXIMUM 2 resources per tile
  const displayResources = allResources.slice(0, 2);

  // Function to create IMPROVED forest texture - covers entire hexagon with clip-path
  const renderForestTexture = (): JSX.Element => {
    const clipId = `forest-clip-${tile.coordinates.q}-${tile.coordinates.r}`;
    
    return (
      <>
        {/* Define clip path to constrain trees within hexagon */}
        <defs>
          <clipPath id={clipId}>
            <polygon points={points} />
          </clipPath>
        </defs>
        
        {/* Forest base - full coverage dark green overlay */}
        <polygon
          points={points}
          fill="#1f3d0e"
          opacity={0.85}
          pointerEvents="none"
        />
        
        {/* Dense tree coverage - CLIPPED to hexagon shape */}
        <g clipPath={`url(#${clipId})`}>
          {/* Original 9 trees - centered */}
          <text x={x - size * 0.45} y={y - size * 0.35} fontSize={size * 0.5} fill="#0d2607" opacity={0.9}>🌲</text>
          <text x={x} y={y - size * 0.45} fontSize={size * 0.55} fill="#0d2607" opacity={0.95}>🌲</text>
          <text x={x + size * 0.45} y={y - size * 0.3} fontSize={size * 0.48} fill="#0d2607" opacity={0.9}>🌲</text>
          
          <text x={x - size * 0.5} y={y} fontSize={size * 0.52} fill="#0d2607" opacity={0.92}>🌲</text>
          <text x={x - size * 0.05} y={y - size * 0.05} fontSize={size * 0.58} fill="#0d2607" opacity={0.95}>🌲</text>
          <text x={x + size * 0.5} y={y + size * 0.05} fontSize={size * 0.5} fill="#0d2607" opacity={0.9}>🌲</text>
          
          <text x={x - size * 0.42} y={y + size * 0.4} fontSize={size * 0.48} fill="#0d2607" opacity={0.88}>🌲</text>
          <text x={x} y={y + size * 0.35} fontSize={size * 0.53} fill="#0d2607" opacity={0.93}>🌲</text>
          <text x={x + size * 0.38} y={y + size * 0.38} fontSize={size * 0.5} fill="#0d2607" opacity={0.9}>🌲</text>
          
          {/* 8 NEW trees on LEFT SIDE for denser coverage */}
          <text x={x - size * 0.7} y={y - size * 0.4} fontSize={size * 0.46} fill="#0d2607" opacity={0.85}>🌲</text>
          <text x={x - size * 0.65} y={y - size * 0.15} fontSize={size * 0.49} fill="#0d2607" opacity={0.88}>🌲</text>
          <text x={x - size * 0.68} y={y + size * 0.1} fontSize={size * 0.47} fill="#0d2607" opacity={0.86}>🌲</text>
          <text x={x - size * 0.6} y={y + size * 0.35} fontSize={size * 0.5} fill="#0d2607" opacity={0.87}>🌲</text>
          
          <text x={x - size * 0.75} y={y - size * 0.25} fontSize={size * 0.44} fill="#0d2607" opacity={0.83}>🌲</text>
          <text x={x - size * 0.72} y={y + size * 0.25} fontSize={size * 0.45} fill="#0d2607" opacity={0.84}>🌲</text>
          <text x={x - size * 0.55} y={y - size * 0.25} fontSize={size * 0.48} fill="#0d2607" opacity={0.89}>🌲</text>
          <text x={x - size * 0.58} y={y + size * 0.18} fontSize={size * 0.46} fill="#0d2607" opacity={0.87}>🌲</text>
          
          {/* Additional foliage for fullness */}
          <circle cx={x - size * 0.2} cy={y + size * 0.15} r={size * 0.12} fill="#2d5016" opacity={0.5} />
          <circle cx={x + size * 0.35} cy={y - size * 0.15} r={size * 0.1} fill="#2d5016" opacity={0.5} />
          <circle cx={x + size * 0.25} cy={y + size * 0.2} r={size * 0.11} fill="#2d5016" opacity={0.5} />
          <circle cx={x - size * 0.1} cy={y - size * 0.2} r={size * 0.09} fill="#2d5016" opacity={0.5} />
        </g>
      </>
    );
  };

  // Function to create IMPROVED jungle texture - covers entire hexagon with clip-path
  const renderJungleTexture = (): JSX.Element => {
    const clipId = `jungle-clip-${tile.coordinates.q}-${tile.coordinates.r}`;
    
    return (
      <>
        {/* Define clip path to constrain palms within hexagon */}
        <defs>
          <clipPath id={clipId}>
            <polygon points={points} />
          </clipPath>
        </defs>
        
        {/* Jungle base - full coverage vibrant green overlay */}
        <polygon
          points={points}
          fill="#0f3d1f"
          opacity={0.88}
          pointerEvents="none"
        />
        
        {/* Dense tropical tree coverage - CLIPPED to hexagon shape */}
        <g clipPath={`url(#${clipId})`}>
          {/* Original 9 palms - centered */}
          <text x={x - size * 0.48} y={y - size * 0.38} fontSize={size * 0.55} fill="#072814" opacity={0.92}>🌴</text>
          <text x={x - size * 0.05} y={y - size * 0.48} fontSize={size * 0.6} fill="#072814" opacity={0.95}>🌴</text>
          <text x={x + size * 0.48} y={y - size * 0.32} fontSize={size * 0.52} fill="#072814" opacity={0.9}>🌴</text>
          
          <text x={x - size * 0.52} y={y + size * 0.05} fontSize={size * 0.57} fill="#072814" opacity={0.93}>🌴</text>
          <text x={x - size * 0.02} y={y} fontSize={size * 0.62} fill="#072814" opacity={0.96}>🌴</text>
          <text x={x + size * 0.5} y={y + size * 0.1} fontSize={size * 0.54} fill="#072814" opacity={0.91}>🌴</text>
          
          <text x={x - size * 0.45} y={y + size * 0.42} fontSize={size * 0.53} fill="#072814" opacity={0.9}>🌴</text>
          <text x={x + size * 0.05} y={y + size * 0.4} fontSize={size * 0.58} fill="#072814" opacity={0.94}>🌴</text>
          <text x={x + size * 0.42} y={y + size * 0.4} fontSize={size * 0.52} fill="#072814" opacity={0.89}>🌴</text>
          
          {/* 8 NEW palms on LEFT SIDE for denser tropical coverage */}
          <text x={x - size * 0.72} y={y - size * 0.42} fontSize={size * 0.51} fill="#072814" opacity={0.88}>🌴</text>
          <text x={x - size * 0.68} y={y - size * 0.18} fontSize={size * 0.54} fill="#072814" opacity={0.9}>🌴</text>
          <text x={x - size * 0.7} y={y + size * 0.08} fontSize={size * 0.52} fill="#072814" opacity={0.89}>🌴</text>
          <text x={x - size * 0.63} y={y + size * 0.35} fontSize={size * 0.55} fill="#072814" opacity={0.91}>🌴</text>
          
          <text x={x - size * 0.78} y={y - size * 0.28} fontSize={size * 0.49} fill="#072814" opacity={0.86}>🌴</text>
          <text x={x - size * 0.75} y={y + size * 0.22} fontSize={size * 0.5} fill="#072814" opacity={0.87}>🌴</text>
          <text x={x - size * 0.58} y={y - size * 0.28} fontSize={size * 0.53} fill="#072814" opacity={0.92}>🌴</text>
          <text x={x - size * 0.6} y={y + size * 0.15} fontSize={size * 0.51} fill="#072814" opacity={0.9}>🌴</text>
          
          {/* Tropical foliage patches for density */}
          <circle cx={x - size * 0.15} cy={y - size * 0.15} r={size * 0.14} fill="#1a5c35" opacity={0.6} />
          <circle cx={x + size * 0.4} cy={y + size * 0.1} r={size * 0.13} fill="#1a5c35" opacity={0.6} />
          <circle cx={x + size * 0.1} cy={y + size * 0.2} r={size * 0.15} fill="#1a5c35" opacity={0.6} />
          <circle cx={x + size * 0.3} cy={y - size * 0.25} r={size * 0.11} fill="#1a5c35" opacity={0.6} />
        </g>
      </>
    );
  };

  // Function to create boreal forest texture (cold climate trees)
  const renderBorealForestTexture = (): JSX.Element => {
    return (
      <>
        {/* Boreal forest base - bluish green overlay */}
        <polygon
          points={points}
          fill="#1e4d2b"
          opacity={0.55}
          pointerEvents="none"
        />
        
        {/* Coniferous trees */}
        <text x={x - size * 0.3} y={y - size * 0.2} fontSize={size * 0.38} fill="#0f291a" opacity={0.8}>🌲</text>
        <text x={x + size * 0.25} y={y - size * 0.25} fontSize={size * 0.35} fill="#0f291a" opacity={0.75}>🌲</text>
        <text x={x} y={y + size * 0.05} fontSize={size * 0.4} fill="#0f291a" opacity={0.8}>🌲</text>
        <text x={x - size * 0.2} y={y + size * 0.3} fontSize={size * 0.32} fill="#0f291a" opacity={0.7}>🌲</text>
        <text x={x + size * 0.3} y={y + size * 0.25} fontSize={size * 0.33} fill="#0f291a" opacity={0.75}>🌲</text>
        
        {/* Snow patches */}
        <circle cx={x - size * 0.35} cy={y + size * 0.1} r={size * 0.08} fill="#d1e3f0" opacity={0.6} />
        <circle cx={x + size * 0.2} cy={y + size * 0.35} r={size * 0.06} fill="#d1e3f0" opacity={0.6} />
        <circle cx={x + size * 0.35} cy={y - size * 0.05} r={size * 0.07} fill="#d1e3f0" opacity={0.5} />
      </>
    );
  };

  // Function to render IMPROVED volcano visual
  const renderVolcanoVisual = (): JSX.Element => {
    return (
      <>
        {/* Volcanic smoke/ash cloud */}
        <circle cx={x - size * 0.15} cy={y - size * 0.5} r={size * 0.18} fill="#6b7280" opacity={0.4} />
        <circle cx={x + size * 0.1} cy={y - size * 0.55} r={size * 0.15} fill="#6b7280" opacity={0.35} />
        <circle cx={x} cy={y - size * 0.6} r={size * 0.12} fill="#6b7280" opacity={0.3} />
        
        {/* Lava glow base */}
        <circle cx={x} cy={y - size * 0.1} r={size * 0.35} fill="#ff6347" opacity={0.3} />
        
        {/* Volcano mountain with lava */}
        <text
          x={x}
          y={y - size * 0.15}
          fontSize={size * 1.1}
          textAnchor="middle"
          dominantBaseline="middle"
          fill="#ff4500"
          stroke="#8b0000"
          strokeWidth={1.5}
          fontWeight="bold"
          style={{
            filter: 'drop-shadow(0 0 8px #ff6347)'
          }}
        >
          ▲
        </text>
        
        {/* Lava streams */}
        <line x1={x - size * 0.15} y1={y - size * 0.05} x2={x - size * 0.3} y2={y + size * 0.15} stroke="#ff4500" strokeWidth={2} opacity={0.7} />
        <line x1={x + size * 0.15} y1={y - size * 0.05} x2={x + size * 0.3} y2={y + size * 0.15} stroke="#ff4500" strokeWidth={2} opacity={0.7} />
        
        {/* Small fire emoji at peak */}
        <text
          x={x}
          y={y - size * 0.45}
          fontSize={size * 0.35}
          textAnchor="middle"
          dominantBaseline="middle"
        >
          🔥
        </text>
      </>
    );
  };

  // Function to render beautiful marine life for ocean and coast tiles
  const renderMarineLife = (): JSX.Element | null => {
    if (tile.terrain !== 'ocean' && tile.terrain !== 'coast') return null;
    
    const hasFish = tile.resources.includes('fish');
    const hasWhales = tile.resources.includes('whales');
    const hasCrabs = tile.resources.includes('crabs');
    
    if (!hasFish && !hasWhales && !hasCrabs) return null;
    
    return (
      <>
        {/* Fish - swimming in schools */}
        {hasFish && (
          <>
            {/* Fish school with beautiful wavy pattern */}
            <g opacity={0.8}>
              {/* Main fish */}
              <ellipse cx={x - size * 0.15} cy={y - size * 0.1} rx={size * 0.18} ry={size * 0.12} fill="#60a5fa" stroke="#2563eb" strokeWidth={1} />
              <polygon points={`${x - size * 0.33},${y - size * 0.1} ${x - size * 0.42},${y - size * 0.18} ${x - size * 0.42},${y - size * 0.02}`} fill="#60a5fa" stroke="#2563eb" strokeWidth={1} />
              <circle cx={x - size * 0.08} cy={y - size * 0.12} r={size * 0.03} fill="#1e3a8a" />
              
              {/* Small fish companions */}
              <ellipse cx={x + size * 0.1} cy={y + size * 0.15} rx={size * 0.12} ry={size * 0.08} fill="#93c5fd" stroke="#3b82f6" strokeWidth={0.8} />
              <polygon points={`${x + size * 0.22},${y + size * 0.15} ${x + size * 0.28},${y + size * 0.2} ${x + size * 0.28},${y + size * 0.1}`} fill="#93c5fd" stroke="#3b82f6" strokeWidth={0.8} />
              
              <ellipse cx={x + size * 0.15} cy={y - size * 0.2} rx={size * 0.11} ry={size * 0.07} fill="#93c5fd" stroke="#3b82f6" strokeWidth={0.8} />
              <polygon points={`${x + size * 0.26},${y - size * 0.2} ${x + size * 0.32},${y - size * 0.24} ${x + size * 0.32},${y - size * 0.16}`} fill="#93c5fd" stroke="#3b82f6" strokeWidth={0.8} />
            </g>
          </>
        )}
        
        {/* Whales - majestic creatures */}
        {hasWhales && (
          <>
            <g opacity={0.85}>
              {/* Whale body */}
              <ellipse cx={x} cy={y} rx={size * 0.35} ry={size * 0.2} fill="#1e40af" stroke="#1e3a8a" strokeWidth={2} />
              {/* Whale tail */}
              <path d={`M ${x + size * 0.35} ${y} Q ${x + size * 0.45} ${y - size * 0.15}, ${x + size * 0.5} ${y - size * 0.1} Q ${x + size * 0.48} ${y}, ${x + size * 0.5} ${y + size * 0.1} Q ${x + size * 0.45} ${y + size * 0.15}, ${x + size * 0.35} ${y}`} fill="#1e40af" stroke="#1e3a8a" strokeWidth={2} />
              {/* Whale eye */}
              <circle cx={x - size * 0.2} cy={y - size * 0.05} r={size * 0.04} fill="#1e3a8a" />
              {/* Water spout */}
              <path d={`M ${x - size * 0.25} ${y - size * 0.2} Q ${x - size * 0.23} ${y - size * 0.35}, ${x - size * 0.2} ${y - size * 0.4}`} stroke="#60a5fa" strokeWidth={2} strokeDasharray="3,2" opacity={0.7} />
              <circle cx={x - size * 0.2} cy={y - size * 0.42} r={size * 0.05} fill="#93c5fd" opacity={0.6} />
            </g>
          </>
        )}
        
        {/* Crabs - on the seafloor/shore */}
        {hasCrabs && (
          <>
            <g opacity={0.9}>
              {/* Crab body */}
              <ellipse cx={x + size * 0.2} cy={y + size * 0.25} rx={size * 0.15} ry={size * 0.12} fill="#f97316" stroke="#c2410c" strokeWidth={1.5} />
              {/* Crab eyes on stalks */}
              <line x1={x + size * 0.12} y1={y + size * 0.18} x2={x + size * 0.1} y2={y + size * 0.12} stroke="#c2410c" strokeWidth={1.5} />
              <circle cx={x + size * 0.1} cy={y + size * 0.12} r={size * 0.03} fill="#1e3a8a" />
              <line x1={x + size * 0.28} y1={y + size * 0.18} x2={x + size * 0.3} y2={y + size * 0.12} stroke="#c2410c" strokeWidth={1.5} />
              <circle cx={x + size * 0.3} cy={y + size * 0.12} r={size * 0.03} fill="#1e3a8a" />
              {/* Crab claws */}
              <ellipse cx={x + size * 0.05} cy={y + size * 0.28} rx={size * 0.08} ry={size * 0.06} fill="#fb923c" stroke="#c2410c" strokeWidth={1.2} />
              <ellipse cx={x + size * 0.35} cy={y + size * 0.28} rx={size * 0.08} ry={size * 0.06} fill="#fb923c" stroke="#c2410c" strokeWidth={1.2} />
              {/* Crab legs */}
              <line x1={x + size * 0.15} y1={y + size * 0.32} x2={x + size * 0.1} y2={y + size * 0.38} stroke="#f97316" strokeWidth={1.5} />
              <line x1={x + size * 0.18} y1={y + size * 0.33} x2={x + size * 0.15} y2={y + size * 0.4} stroke="#f97316" strokeWidth={1.5} />
              <line x1={x + size * 0.22} y1={y + size * 0.33} x2={x + size * 0.22} y2={y + size * 0.4} stroke="#f97316" strokeWidth={1.5} />
              <line x1={x + size * 0.25} y1={y + size * 0.32} x2={x + size * 0.3} y2={y + size * 0.38} stroke="#f97316" strokeWidth={1.5} />
            </g>
          </>
        )}
      </>
    );
  };

  // CRITICAL NEW FUNCTION: Render beautiful SVG icons for ALL resources/animals
  // Positioned on the RIGHT side of the hexagon (x + size * 0.35 to x + size * 0.5)
  // If there's a feature (forest/jungle/boreal_forest), resources go ABOVE it (z-index wise)
  const renderResourceIcons = (): JSX.Element | null => {
    if (displayResources.length === 0) return null;
    
    // Skip marine resources - they have custom visuals
    const nonMarineResources = displayResources.filter(r => 
      !['fish', 'whales', 'crabs'].includes(r)
    );
    
    if (nonMarineResources.length === 0) return null;
    
    // Position on the RIGHT side of hexagon
    const rightPositions = [
      { x: x + size * 0.42, y: y - size * 0.2 },  // Top right
      { x: x + size * 0.42, y: y + size * 0.2 }   // Bottom right
    ];
    
    return (
      <>
        {nonMarineResources.slice(0, 2).map((resource, index) => {
          const pos = rightPositions[index];
          if (!pos) return null;
          
          // Render icon based on resource type
          if (resource === 'gold') {
            return (
              <g key={`resource-${index}`}>
                {/* Gold coin */}
                <circle cx={pos.x} cy={pos.y} r={size * 0.15} fill="#FFD700" stroke="#DAA520" strokeWidth={1.5} />
                <circle cx={pos.x} cy={pos.y} r={size * 0.1} fill="none" stroke="#FFB700" strokeWidth={1} />
                <text x={pos.x} y={pos.y + size * 0.05} fontSize={size * 0.12} textAnchor="middle" fill="#8B7500" fontWeight="bold">$</text>
              </g>
            );
          } else if (resource === 'silver') {
            return (
              <g key={`resource-${index}`}>
                {/* Silver coin */}
                <circle cx={pos.x} cy={pos.y} r={size * 0.15} fill="#C0C0C0" stroke="#A8A8A8" strokeWidth={1.5} />
                <circle cx={pos.x} cy={pos.y} r={size * 0.1} fill="none" stroke="#D3D3D3" strokeWidth={1} />
                <text x={pos.x} y={pos.y + size * 0.05} fontSize={size * 0.12} textAnchor="middle" fill="#696969" fontWeight="bold">¤</text>
              </g>
            );
          } else if (resource === 'iron') {
            return (
              <g key={`resource-${index}`}>
                {/* Iron ingot */}
                <rect x={pos.x - size * 0.12} y={pos.y - size * 0.08} width={size * 0.24} height={size * 0.16} fill="#6B6B6B" stroke="#4A4A4A" strokeWidth={1.5} rx={2} />
                <line x1={pos.x - size * 0.08} y1={pos.y - size * 0.08} x2={pos.x - size * 0.08} y2={pos.y + size * 0.08} stroke="#8B8B8B" strokeWidth={1} />
                <line x1={pos.x + size * 0.08} y1={pos.y - size * 0.08} x2={pos.x + size * 0.08} y2={pos.y + size * 0.08} stroke="#8B8B8B" strokeWidth={1} />
              </g>
            );
          } else if (resource === 'tin') {
            return (
              <g key={`resource-${index}`}>
                {/* Tin ingot */}
                <rect x={pos.x - size * 0.12} y={pos.y - size * 0.08} width={size * 0.24} height={size * 0.16} fill="#B8B8B8" stroke="#A0A0A0" strokeWidth={1.5} rx={2} />
                <line x1={pos.x - size * 0.08} y1={pos.y - size * 0.08} x2={pos.x - size * 0.08} y2={pos.y + size * 0.08} stroke="#D0D0D0" strokeWidth={1} />
              </g>
            );
          } else if (resource === 'bronze') {
            return (
              <g key={`resource-${index}`}>
                {/* Bronze shield */}
                <ellipse cx={pos.x} cy={pos.y} rx={size * 0.14} ry={size * 0.16} fill="#CD7F32" stroke="#8B5A2B" strokeWidth={1.5} />
                <circle cx={pos.x} cy={pos.y} r={size * 0.06} fill="#A0522D" />
              </g>
            );
          } else if (resource === 'copper') {
            return (
              <g key={`resource-${index}`}>
                {/* Copper nugget */}
                <circle cx={pos.x} cy={pos.y} r={size * 0.13} fill="#B87333" stroke="#A0522D" strokeWidth={1.5} />
                <circle cx={pos.x - size * 0.05} cy={pos.y - size * 0.05} r={size * 0.03} fill="#D2691E" opacity={0.7} />
              </g>
            );
          } else if (resource === 'stone') {
            return (
              <g key={`resource-${index}`}>
                {/* Stone rocks */}
                <ellipse cx={pos.x} cy={pos.y} rx={size * 0.14} ry={size * 0.11} fill="#808080" stroke="#696969" strokeWidth={1.5} />
                <ellipse cx={pos.x - size * 0.06} cy={pos.y - size * 0.03} rx={size * 0.08} ry={size * 0.06} fill="#A9A9A9" stroke="#808080" strokeWidth={1} />
              </g>
            );
          } else if (resource === 'gems') {
            return (
              <g key={`resource-${index}`}>
                {/* Gem crystal */}
                <polygon points={`${pos.x},${pos.y - size * 0.14} ${pos.x + size * 0.1},${pos.y - size * 0.02} ${pos.x + size * 0.05},${pos.y + size * 0.12} ${pos.x - size * 0.05},${pos.y + size * 0.12} ${pos.x - size * 0.1},${pos.y - size * 0.02}`} fill="#9B59B6" stroke="#7D3C98" strokeWidth={1.5} />
                <polygon points={`${pos.x},${pos.y - size * 0.1} ${pos.x + size * 0.06},${pos.y} ${pos.x},${pos.y + size * 0.08} ${pos.x - size * 0.06},${pos.y}`} fill="#E8DAEF" opacity={0.5} />
              </g>
            );
          } else if (resource === 'horses') {
            return (
              <g key={`resource-${index}`}>
                {/* Horse silhouette */}
                <ellipse cx={pos.x} cy={pos.y} rx={size * 0.14} ry={size * 0.1} fill="#8B4513" stroke="#654321" strokeWidth={1.5} />
                <ellipse cx={pos.x - size * 0.08} cy={pos.y - size * 0.08} rx={size * 0.06} ry={size * 0.08} fill="#8B4513" stroke="#654321" strokeWidth={1} />
                <line x1={pos.x - size * 0.1} y1={pos.y - size * 0.14} x2={pos.x - size * 0.12} y2={pos.y - size * 0.18} stroke="#654321" strokeWidth={2} strokeLinecap="round" />
                <line x1={pos.x + size * 0.05} y1={pos.y + size * 0.08} x2={pos.x + size * 0.05} y2={pos.y + size * 0.15} stroke="#654321" strokeWidth={1.5} />
              </g>
            );
          } else if (resource === 'sheep') {
            return (
              <g key={`resource-${index}`}>
                {/* Sheep */}
                <ellipse cx={pos.x} cy={pos.y} rx={size * 0.12} ry={size * 0.1} fill="#F5F5F5" stroke="#D3D3D3" strokeWidth={1.5} />
                <circle cx={pos.x - size * 0.08} cy={pos.y - size * 0.06} r={size * 0.05} fill="#F5F5F5" stroke="#D3D3D3" strokeWidth={1} />
                <circle cx={pos.x - size * 0.1} cy={pos.y - size * 0.08} r={size * 0.02} fill="#000" />
              </g>
            );
          } else if (resource === 'buffalo' || resource === 'yaks') {
            return (
              <g key={`resource-${index}`}>
                {/* Buffalo/Yak */}
                <ellipse cx={pos.x} cy={pos.y} rx={size * 0.15} ry={size * 0.11} fill="#5C4033" stroke="#3E2723" strokeWidth={1.5} />
                <ellipse cx={pos.x - size * 0.09} cy={pos.y - size * 0.07} rx={size * 0.07} ry={size * 0.09} fill="#5C4033" stroke="#3E2723" strokeWidth={1} />
                <line x1={pos.x - size * 0.12} y1={pos.y - size * 0.12} x2={pos.x - size * 0.15} y2={pos.y - size * 0.16} stroke="#3E2723" strokeWidth={2} strokeLinecap="round" />
                <line x1={pos.x - size * 0.06} y1={pos.y - size * 0.12} x2={pos.x - size * 0.03} y2={pos.y - size * 0.16} stroke="#3E2723" strokeWidth={2} strokeLinecap="round" />
              </g>
            );
          } else if (resource === 'muffon') {
            return (
              <g key={`resource-${index}`}>
                {/* Mountain goat */}
                <ellipse cx={pos.x} cy={pos.y} rx={size * 0.12} ry={size * 0.09} fill="#D3D3D3" stroke="#A9A9A9" strokeWidth={1.5} />
                <circle cx={pos.x - size * 0.08} cy={pos.y - size * 0.06} r={size * 0.05} fill="#D3D3D3" stroke="#A9A9A9" strokeWidth={1} />
                <line x1={pos.x - size * 0.11} y1={pos.y - size * 0.1} x2={pos.x - size * 0.13} y2={pos.y - size * 0.14} stroke="#696969" strokeWidth={1.5} strokeLinecap="round" />
                <line x1={pos.x - size * 0.05} y1={pos.y - size * 0.1} x2={pos.x - size * 0.03} y2={pos.y - size * 0.14} stroke="#696969" strokeWidth={1.5} strokeLinecap="round" />
              </g>
            );
          } else if (resource === 'camels') {
            return (
              <g key={`resource-${index}`}>
                {/* Camel */}
                <ellipse cx={pos.x} cy={pos.y} rx={size * 0.14} ry={size * 0.09} fill="#C19A6B" stroke="#9C7A54" strokeWidth={1.5} />
                <ellipse cx={pos.x - size * 0.08} cy={pos.y - size * 0.08} rx={size * 0.06} ry={size * 0.1} fill="#C19A6B" stroke="#9C7A54" strokeWidth={1} />
                {/* Hump */}
                <ellipse cx={pos.x + size * 0.03} cy={pos.y - size * 0.08} rx={size * 0.08} ry={size * 0.1} fill="#D2B48C" stroke="#9C7A54" strokeWidth={1} />
              </g>
            );
          } else if (resource === 'wheat') {
            return (
              <g key={`resource-${index}`}>
                {/* Wheat stalks */}
                <line x1={pos.x - size * 0.05} y1={pos.y + size * 0.08} x2={pos.x - size * 0.05} y2={pos.y - size * 0.08} stroke="#DAA520" strokeWidth={1.5} />
                <line x1={pos.x} y1={pos.y + size * 0.08} x2={pos.x} y2={pos.y - size * 0.12} stroke="#DAA520" strokeWidth={1.5} />
                <line x1={pos.x + size * 0.05} y1={pos.y + size * 0.08} x2={pos.x + size * 0.05} y2={pos.y - size * 0.08} stroke="#DAA520" strokeWidth={1.5} />
                <ellipse cx={pos.x - size * 0.05} cy={pos.y - size * 0.1} rx={size * 0.03} ry={size * 0.06} fill="#F4A460" />
                <ellipse cx={pos.x} cy={pos.y - size * 0.14} rx={size * 0.03} ry={size * 0.06} fill="#F4A460" />
                <ellipse cx={pos.x + size * 0.05} cy={pos.y - size * 0.1} rx={size * 0.03} ry={size * 0.06} fill="#F4A460" />
              </g>
            );
          } else if (resource === 'wood') {
            return (
              <g key={`resource-${index}`}>
                {/* Wood logs */}
                <rect x={pos.x - size * 0.12} y={pos.y - size * 0.06} width={size * 0.24} height={size * 0.12} fill="#8B4513" stroke="#654321" strokeWidth={1.5} rx={2} />
                <ellipse cx={pos.x - size * 0.12} cy={pos.y} rx={size * 0.04} ry={size * 0.06} fill="#A0522D" stroke="#654321" strokeWidth={1} />
                <ellipse cx={pos.x + size * 0.12} cy={pos.y} rx={size * 0.04} ry={size * 0.06} fill="#A0522D" stroke="#654321" strokeWidth={1} />
              </g>
            );
          } else if (resource === 'spices') {
            return (
              <g key={`resource-${index}`}>
                {/* Spice jar */}
                <rect x={pos.x - size * 0.08} y={pos.y - size * 0.05} width={size * 0.16} height={size * 0.14} fill="#D2691E" stroke="#8B4513" strokeWidth={1.5} rx={2} />
                <rect x={pos.x - size * 0.1} y={pos.y - size * 0.08} width={size * 0.2} height={size * 0.04} fill="#A0522D" stroke="#654321" strokeWidth={1} rx={1} />
                <circle cx={pos.x - size * 0.03} cy={pos.y + size * 0.02} r={size * 0.02} fill="#FF6347" />
                <circle cx={pos.x + size * 0.03} cy={pos.y + size * 0.02} r={size * 0.02} fill="#FFD700" />
              </g>
            );
          } else if (resource === 'dates') {
            return (
              <g key={`resource-${index}`}>
                {/* Date fruits */}
                <ellipse cx={pos.x - size * 0.04} cy={pos.y} rx={size * 0.05} ry={size * 0.08} fill="#8B4513" stroke="#654321" strokeWidth={1} />
                <ellipse cx={pos.x + size * 0.04} cy={pos.y} rx={size * 0.05} ry={size * 0.08} fill="#8B4513" stroke="#654321" strokeWidth={1} />
                <line x1={pos.x} y1={pos.y - size * 0.08} x2={pos.x} y2={pos.y - size * 0.15} stroke="#228B22" strokeWidth={1.5} />
              </g>
            );
          } else if (resource === 'cotton') {
            return (
              <g key={`resource-${index}`}>
                {/* Cotton bolls */}
                <circle cx={pos.x} cy={pos.y} r={size * 0.1} fill="#F5F5F5" stroke="#D3D3D3" strokeWidth={1.5} />
                <circle cx={pos.x - size * 0.05} cy={pos.y - size * 0.05} r={size * 0.04} fill="#FFFFFF" />
                <circle cx={pos.x + size * 0.05} cy={pos.y - size * 0.05} r={size * 0.04} fill="#FFFFFF" />
                <circle cx={pos.x} cy={pos.y + size * 0.05} r={size * 0.04} fill="#FFFFFF" />
              </g>
            );
          }
          
          return null;
        })}
      </>
    );
  };

  // Function to render STUNNING mountain texture with majestic peaks
  const renderMountainTexture = (): JSX.Element => {
    const clipId = `mountain-clip-${tile.coordinates.q}-${tile.coordinates.r}`;
    
    return (
      <>
        {/* Define clip path */}
        <defs>
          <clipPath id={clipId}>
            <polygon points={points} />
          </clipPath>
          {/* Enhanced mountain gradient for realistic depth */}
          <linearGradient id={`mountain-grad-${tile.coordinates.q}-${tile.coordinates.r}`} x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style={{ stopColor: '#b8b8b8', stopOpacity: 1 }} />
            <stop offset="30%" style={{ stopColor: '#8a8a8a', stopOpacity: 1 }} />
            <stop offset="70%" style={{ stopColor: '#6b6b6b', stopOpacity: 1 }} />
            <stop offset="100%" style={{ stopColor: '#4a4a4a', stopOpacity: 1 }} />
          </linearGradient>
          {/* Radial gradient for peak highlights */}
          <radialGradient id={`mountain-peak-${tile.coordinates.q}-${tile.coordinates.r}`} cx="50%" cy="30%">
            <stop offset="0%" style={{ stopColor: '#e8e8e8', stopOpacity: 0.9 }} />
            <stop offset="100%" style={{ stopColor: '#a0a0a0', stopOpacity: 0.3 }} />
          </radialGradient>
        </defs>
        
        {/* Base mountain texture with gradient */}
        <polygon
          points={points}
          fill={`url(#mountain-grad-${tile.coordinates.q}-${tile.coordinates.r})`}
          opacity={1}
          pointerEvents="none"
        />
        
        {/* Peak highlight overlay */}
        <polygon
          points={points}
          fill={`url(#mountain-peak-${tile.coordinates.q}-${tile.coordinates.r})`}
          opacity={0.6}
          pointerEvents="none"
        />
        
        {/* Rocky texture overlay - clipped */}
        <g clipPath={`url(#${clipId})`}>
          {/* Majestic peak formations */}
          <polygon
            points={`${x - size * 0.35},${y + size * 0.45} ${x - size * 0.15},${y - size * 0.35} ${x},${y - size * 0.15} ${x - size * 0.05},${y + size * 0.45}`}
            fill="#7a7a7a"
            opacity={0.75}
          />
          <polygon
            points={`${x + size * 0.05},${y + size * 0.4} ${x + size * 0.2},${y - size * 0.4} ${x + size * 0.35},${y - size * 0.25} ${x + size * 0.4},${y + size * 0.4}`}
            fill="#656565"
            opacity={0.8}
          />
          
          {/* Additional smaller peaks for depth */}
          <polygon
            points={`${x - size * 0.45},${y + size * 0.2} ${x - size * 0.38},${y - size * 0.15} ${x - size * 0.3},${y + size * 0.2}`}
            fill="#888888"
            opacity={0.6}
          />
          <polygon
            points={`${x + size * 0.3},${y + size * 0.25} ${x + size * 0.38},${y - size * 0.1} ${x + size * 0.45},${y + size * 0.25}`}
            fill="#808080"
            opacity={0.6}
          />
          
          {/* Pristine snow caps on peaks */}
          <circle cx={x - size * 0.15} cy={y - size * 0.35} r={size * 0.18} fill="#ffffff" opacity={0.85} />
          <circle cx={x - size * 0.1} cy={y - size * 0.38} r={size * 0.12} fill="#f5f5f5" opacity={0.9} />
          <circle cx={x + size * 0.2} cy={y - size * 0.4} r={size * 0.16} fill="#fafafa" opacity={0.8} />
          <circle cx={x + size * 0.25} cy={y - size * 0.42} r={size * 0.1} fill="#ffffff" opacity={0.85} />
          
          {/* Deep shadow valleys for dramatic effect */}
          <ellipse cx={x - size * 0.25} cy={y + size * 0.15} rx={size * 0.18} ry={size * 0.12} fill="#2a2a2a" opacity={0.5} />
          <ellipse cx={x + size * 0.15} cy={y + size * 0.08} rx={size * 0.15} ry={size * 0.1} fill="#303030" opacity={0.45} />
          <ellipse cx={x} cy={y + size * 0.2} rx={size * 0.12} ry={size * 0.08} fill="#353535" opacity={0.4} />
          
          {/* Rocky texture details */}
          <circle cx={x - size * 0.4} cy={y - size * 0.05} r={size * 0.09} fill="#909090" opacity={0.6} />
          <circle cx={x - size * 0.38} cy={y + size * 0.1} r={size * 0.07} fill="#858585" opacity={0.55} />
          <circle cx={x + size * 0.38} cy={y + size * 0.18} r={size * 0.08} fill="#7a7a7a" opacity={0.6} />
          <circle cx={x + size * 0.42} cy={y + size * 0.05} r={size * 0.06} fill="#888888" opacity={0.5} />
          <circle cx={x - size * 0.08} cy={y + size * 0.3} r={size * 0.09} fill="#959595" opacity={0.55} />
          <circle cx={x + size * 0.1} cy={y + size * 0.28} r={size * 0.07} fill="#8a8a8a" opacity={0.5} />
        </g>
      </>
    );
  };

  // Function to render beautiful plains texture with grasslands
  const renderPlainsTexture = (): JSX.Element => {
    const clipId = `plains-clip-${tile.coordinates.q}-${tile.coordinates.r}`;
    
    return (
      <>
        <defs>
          <clipPath id={clipId}>
            <polygon points={points} />
          </clipPath>
          {/* Grass gradient */}
          <linearGradient id={`plains-grad-${tile.coordinates.q}-${tile.coordinates.r}`} x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style={{ stopColor: '#c8e68c', stopOpacity: 1 }} />
            <stop offset="50%" style={{ stopColor: '#a3e635', stopOpacity: 1 }} />
            <stop offset="100%" style={{ stopColor: '#84cc16', stopOpacity: 1 }} />
          </linearGradient>
        </defs>
        
        {/* Base grass texture */}
        <polygon
          points={points}
          fill={`url(#plains-grad-${tile.coordinates.q}-${tile.coordinates.r})`}
          opacity={1}
          pointerEvents="none"
        />
        
        <g clipPath={`url(#${clipId})`}>
          {/* Grass patches for texture */}
          <ellipse cx={x - size * 0.3} cy={y - size * 0.2} rx={size * 0.2} ry={size * 0.12} fill="#9cd92d" opacity={0.4} />
          <ellipse cx={x + size * 0.25} cy={y + size * 0.1} rx={size * 0.18} ry={size * 0.1} fill="#a8e630" opacity={0.35} />
          <ellipse cx={x - size * 0.15} cy={y + size * 0.25} rx={size * 0.22} ry={size * 0.13} fill="#b2ed42" opacity={0.3} />
          
          {/* Small wildflowers */}
          <circle cx={x - size * 0.3} cy={y - size * 0.1} r={size * 0.03} fill="#ffeb3b" opacity={0.8} />
          <circle cx={x + size * 0.2} cy={y + size * 0.2} r={size * 0.03} fill="#ffd54f" opacity={0.8} />
          <circle cx={x - size * 0.1} cy={y + size * 0.15} r={size * 0.03} fill="#ffee58" opacity={0.8} />
          <circle cx={x + size * 0.35} cy={y - size * 0.15} r={size * 0.03} fill="#fff59d" opacity={0.8} />
        </g>
      </>
    );
  };

  // Function to render beautiful meadow texture (pradera)
  const renderMeadowTexture = (): JSX.Element => {
    const clipId = `meadow-clip-${tile.coordinates.q}-${tile.coordinates.r}`;
    
    return (
      <>
        <defs>
          <clipPath id={clipId}>
            <polygon points={points} />
          </clipPath>
          {/* Meadow gradient - lighter and more vibrant than plains */}
          <linearGradient id={`meadow-grad-${tile.coordinates.q}-${tile.coordinates.r}`} x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style={{ stopColor: '#bef264', stopOpacity: 1 }} />
            <stop offset="50%" style={{ stopColor: '#a3e635', stopOpacity: 1 }} />
            <stop offset="100%" style={{ stopColor: '#84cc16', stopOpacity: 1 }} />
          </linearGradient>
        </defs>
        
        <polygon
          points={points}
          fill={`url(#meadow-grad-${tile.coordinates.q}-${tile.coordinates.r})`}
          opacity={1}
          pointerEvents="none"
        />
        
        <g clipPath={`url(#${clipId})`}>
          {/* Lush grass patches */}
          <ellipse cx={x - size * 0.25} cy={y - size * 0.15} rx={size * 0.25} ry={size * 0.15} fill="#9cd92d" opacity={0.5} />
          <ellipse cx={x + size * 0.2} cy={y + size * 0.15} rx={size * 0.22} ry={size * 0.13} fill="#b2ed42" opacity={0.45} />
          <ellipse cx={x} cy={y + size * 0.3} rx={size * 0.2} ry={size * 0.12} fill="#c8f774" opacity={0.4} />
          
          {/* Beautiful wildflowers - more abundant than plains */}
          <circle cx={x - size * 0.35} cy={y - size * 0.15} r={size * 0.04} fill="#ec4899" opacity={0.9} />
          <circle cx={x - size * 0.2} cy={y} r={size * 0.04} fill="#f43f5e" opacity={0.85} />
          <circle cx={x + size * 0.1} cy={y - size * 0.2} r={size * 0.04} fill="#8b5cf6" opacity={0.9} />
          <circle cx={x + size * 0.3} cy={y + size * 0.05} r={size * 0.04} fill="#3b82f6" opacity={0.85} />
          <circle cx={x - size * 0.1} cy={y + size * 0.2} r={size * 0.04} fill="#f59e0b" opacity={0.9} />
          <circle cx={x + size * 0.25} cy={y + size * 0.25} r={size * 0.04} fill="#eab308" opacity={0.85} />
        </g>
      </>
    );
  };

  // Function to render beautiful tundra texture with frozen ground
  const renderTundraTexture = (): JSX.Element => {
    const clipId = `tundra-clip-${tile.coordinates.q}-${tile.coordinates.r}`;
    
    return (
      <>
        <defs>
          <clipPath id={clipId}>
            <polygon points={points} />
          </clipPath>
          {/* Tundra gradient - cold bluish gray */}
          <linearGradient id={`tundra-grad-${tile.coordinates.q}-${tile.coordinates.r}`} x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style={{ stopColor: '#e2e8f0', stopOpacity: 1 }} />
            <stop offset="50%" style={{ stopColor: '#cbd5e1', stopOpacity: 1 }} />
            <stop offset="100%" style={{ stopColor: '#94a3b8', stopOpacity: 1 }} />
          </linearGradient>
        </defs>
        
        <polygon
          points={points}
          fill={`url(#tundra-grad-${tile.coordinates.q}-${tile.coordinates.r})`}
          opacity={1}
          pointerEvents="none"
        />
        
        <g clipPath={`url(#${clipId})`}>
          {/* Frozen ground patches */}
          <ellipse cx={x - size * 0.3} cy={y - size * 0.15} rx={size * 0.2} ry={size * 0.12} fill="#b0c4de" opacity={0.5} />
          <ellipse cx={x + size * 0.25} cy={y + size * 0.1} rx={size * 0.18} ry={size * 0.1} fill="#a8b8d0" opacity={0.45} />
          <ellipse cx={x - size * 0.1} cy={y + size * 0.25} rx={size * 0.22} ry={size * 0.13} fill="#c8d4e8" opacity={0.4} />
          
          {/* Ice crystals */}
          <circle cx={x - size * 0.35} cy={y - size * 0.2} r={size * 0.05} fill="#e0f2fe" opacity={0.8} />
          <circle cx={x - size * 0.32} cy={y - size * 0.18} r={size * 0.03} fill="#f0f9ff" opacity={0.9} />
          <circle cx={x + size * 0.3} cy={y + size * 0.15} r={size * 0.04} fill="#dbeafe" opacity={0.85} />
          <circle cx={x + size * 0.33} cy={y + size * 0.18} r={size * 0.03} fill="#eff6ff" opacity={0.9} />
          
          {/* Permafrost cracks */}
          <line x1={x - size * 0.4} y1={y - size * 0.3} x2={x - size * 0.2} y2={y - size * 0.15} stroke="#64748b" strokeWidth={1} opacity={0.3} />
          <line x1={x + size * 0.1} y1={y} x2={x + size * 0.35} y2={y + size * 0.2} stroke="#64748b" strokeWidth={1} opacity={0.3} />
          <line x1={x - size * 0.15} y1={y + size * 0.1} x2={x + size * 0.05} y2={y + size * 0.3} stroke="#64748b" strokeWidth={1} opacity={0.3} />
        </g>
      </>
    );
  };

  // Function to render beautiful ice texture with glacial features
  const renderIceTexture = (): JSX.Element => {
    const clipId = `ice-clip-${tile.coordinates.q}-${tile.coordinates.r}`;
    
    return (
      <>
        <defs>
          <clipPath id={clipId}>
            <polygon points={points} />
          </clipPath>
          {/* Ice gradient - pristine white to pale blue */}
          <linearGradient id={`ice-grad-${tile.coordinates.q}-${tile.coordinates.r}`} x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style={{ stopColor: '#ffffff', stopOpacity: 1 }} />
            <stop offset="50%" style={{ stopColor: '#f0f9ff', stopOpacity: 1 }} />
            <stop offset="100%" style={{ stopColor: '#e0f2fe', stopOpacity: 1 }} />
          </linearGradient>
          {/* Radial gradient for ice shine */}
          <radialGradient id={`ice-shine-${tile.coordinates.q}-${tile.coordinates.r}`} cx="40%" cy="40%">
            <stop offset="0%" style={{ stopColor: '#ffffff', stopOpacity: 0.8 }} />
            <stop offset="100%" style={{ stopColor: '#e0f2fe', stopOpacity: 0.2 }} />
          </radialGradient>
        </defs>
        
        <polygon
          points={points}
          fill={`url(#ice-grad-${tile.coordinates.q}-${tile.coordinates.r})`}
          opacity={1}
          pointerEvents="none"
        />
        
        {/* Ice shine overlay */}
        <polygon
          points={points}
          fill={`url(#ice-shine-${tile.coordinates.q}-${tile.coordinates.r})`}
          opacity={0.7}
          pointerEvents="none"
        />
        
        <g clipPath={`url(#${clipId})`}>
          {/* Glacial formations */}
          <ellipse cx={x - size * 0.25} cy={y - size * 0.15} rx={size * 0.25} ry={size * 0.15} fill="#bfdbfe" opacity={0.4} />
          <ellipse cx={x + size * 0.2} cy={y + size * 0.1} rx={size * 0.22} ry={size * 0.13} fill="#dbeafe" opacity={0.35} />
          <ellipse cx={x - size * 0.05} cy={y + size * 0.25} rx={size * 0.2} ry={size * 0.12} fill="#f0f9ff" opacity={0.3} />
          
          {/* Ice crystals and sparkles */}
          <circle cx={x - size * 0.35} cy={y - size * 0.25} r={size * 0.06} fill="#ffffff" opacity={0.9} />
          <circle cx={x - size * 0.33} cy={y - size * 0.23} r={size * 0.04} fill="#f0f9ff" opacity={0.95} />
          <circle cx={x + size * 0.3} cy={y - size * 0.15} r={size * 0.05} fill="#ffffff" opacity={0.85} />
          <circle cx={x + size * 0.32} cy={y - size * 0.13} r={size * 0.03} fill="#f0f9ff" opacity={0.9} />
          <circle cx={x - size * 0.1} cy={y + size * 0.3} r={size * 0.05} fill="#ffffff" opacity={0.9} />
          <circle cx={x + size * 0.35} cy={y + size * 0.2} r={size * 0.04} fill="#f0f9ff" opacity={0.85} />
          
          {/* Crevasses for realistic ice surface */}
          <line x1={x - size * 0.4} y1={y - size * 0.2} x2={x - size * 0.15} y2={y - size * 0.05} stroke="#93c5fd" strokeWidth={1.5} opacity={0.5} />
          <line x1={x + size * 0.05} y1={y} x2={x + size * 0.3} y2={y + size * 0.15} stroke="#93c5fd" strokeWidth={1.5} opacity={0.5} />
          <line x1={x - size * 0.2} y1={y + size * 0.1} x2={x + size * 0.1} y2={y + size * 0.35} stroke="#93c5fd" strokeWidth={1.5} opacity={0.5} />
          
          {/* Additional sparkles for magical ice effect */}
          <circle cx={x - size * 0.15} cy={y - size * 0.3} r={size * 0.02} fill="#ffffff" opacity={1} />
          <circle cx={x + size * 0.15} cy={y - size * 0.25} r={size * 0.02} fill="#ffffff" opacity={1} />
          <circle cx={x + size * 0.05} cy={y + size * 0.15} r={size * 0.02} fill="#ffffff" opacity={1} />
          <circle cx={x - size * 0.25} cy={y + size * 0.2} r={size * 0.02} fill="#ffffff" opacity={1} />
        </g>
      </>
    );
  };

  // Function to render beautiful desert texture with sand dunes
  const renderDesertTexture = (): JSX.Element => {
    const clipId = `desert-clip-${tile.coordinates.q}-${tile.coordinates.r}`;
    
    return (
      <>
        {/* Define clip path */}
        <defs>
          <clipPath id={clipId}>
            <polygon points={points} />
          </clipPath>
          {/* Desert gradient for depth */}
          <linearGradient id={`desert-grad-${tile.coordinates.q}-${tile.coordinates.r}`} x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style={{ stopColor: '#fef3c7', stopOpacity: 1 }} />
            <stop offset="50%" style={{ stopColor: '#fcd34d', stopOpacity: 1 }} />
            <stop offset="100%" style={{ stopColor: '#f59e0b', stopOpacity: 1 }} />
          </linearGradient>
        </defs>
        
        {/* Base desert texture with gradient */}
        <polygon
          points={points}
          fill={`url(#desert-grad-${tile.coordinates.q}-${tile.coordinates.r})`}
          opacity={0.95}
          pointerEvents="none"
        />
        
        {/* Sand dune patterns - clipped */}
        <g clipPath={`url(#${clipId})`}>
          {/* Large dunes with shadows */}
          <ellipse cx={x - size * 0.25} cy={y - size * 0.1} rx={size * 0.35} ry={size * 0.18} fill="#f59e0b" opacity={0.5} />
          <ellipse cx={x + size * 0.2} cy={y + size * 0.15} rx={size * 0.3} ry={size * 0.15} fill="#d97706" opacity={0.4} />
          
          {/* Dune shadows for depth */}
          <path
            d={`M ${x - size * 0.4} ${y - size * 0.05} Q ${x - size * 0.2} ${y - size * 0.15}, ${x} ${y - size * 0.05} L ${x} ${y + size * 0.05} L ${x - size * 0.4} ${y + size * 0.05} Z`}
            fill="#d97706"
            opacity={0.3}
          />
          <path
            d={`M ${x + size * 0.05} ${y + size * 0.1} Q ${x + size * 0.25} ${y}, ${x + size * 0.4} ${y + size * 0.1} L ${x + size * 0.4} ${y + size * 0.25} L ${x + size * 0.05} ${y + size * 0.25} Z`}
            fill="#d97706"
            opacity={0.35}
          />
          
          {/* Sand ripples for texture */}
          <line x1={x - size * 0.4} y1={y - size * 0.3} x2={x + size * 0.4} y2={y - size * 0.3} stroke="#f59e0b" strokeWidth={1} opacity={0.3} />
          <line x1={x - size * 0.35} y1={y - size * 0.15} x2={x + size * 0.35} y2={y - size * 0.15} stroke="#f59e0b" strokeWidth={1} opacity={0.25} />
          <line x1={x - size * 0.4} y1={y} x2={x + size * 0.4} y2={y} stroke="#f59e0b" strokeWidth={1} opacity={0.3} />
          <line x1={x - size * 0.35} y1={y + size * 0.15} x2={x + size * 0.35} y2={y + size * 0.15} stroke="#f59e0b" strokeWidth={1} opacity={0.25} />
          <line x1={x - size * 0.3} y1={y + size * 0.3} x2={x + size * 0.3} y2={y + size * 0.3} stroke="#f59e0b" strokeWidth={1} opacity={0.3} />
          
          {/* Small scattered rocks/pebbles */}
          <circle cx={x - size * 0.3} cy={y + size * 0.2} r={size * 0.04} fill="#92400e" opacity={0.6} />
          <circle cx={x + size * 0.15} cy={y - size * 0.25} r={size * 0.03} fill="#92400e" opacity={0.5} />
          <circle cx={x + size * 0.3} cy={y + size * 0.1} r={size * 0.035} fill="#92400e" opacity={0.55} />
        </g>
      </>
    );
  };

  return (
    <g onClick={handleClick} style={{ cursor: 'pointer' }}>
      {/* Hex tile with better styling */}
      <polygon
        points={points}
        fill={color}
        stroke={selected ? '#fbbf24' : isOnPath ? '#fbbf24' : strokeColor}
        strokeWidth={selected ? 3 : isOnPath ? 1.5 : 1.5}
        opacity={tile.terrain === 'ocean' ? 0.9 : (tile.terrain === 'coast' ? 0.95 : 1)}
        style={{
          filter: selected ? 'brightness(1.3)' : isOnPath ? 'brightness(1.15)' : undefined
        }}
      />
      
      {/* Render beautiful mountain_range texture */}
      {tile.terrain === 'mountain_range' && renderMountainTexture()}
      
      {/* Render beautiful desert texture */}
      {tile.terrain === 'desert' && renderDesertTexture()}
      
      {/* Render beautiful plains texture */}
      {tile.terrain === 'plains' && renderPlainsTexture()}
      
      {/* Render beautiful meadow texture */}
      {tile.terrain === 'meadow' && renderMeadowTexture()}
      
      {/* Render beautiful tundra texture */}
      {tile.terrain === 'tundra' && renderTundraTexture()}
      
      {/* Render beautiful ice texture */}
      {tile.terrain === 'ice' && renderIceTexture()}
      
      {/* Render terrain feature textures - IMPROVED FULL COVERAGE */}
      {hasForest && renderForestTexture()}
      {hasJungle && renderJungleTexture()}
      {hasBorealForest && renderBorealForestTexture()}
      
      {/* Subtle inner border for depth */}
      {tile.terrain !== 'ocean' && tile.terrain !== 'coast' && !(hasForest || hasJungle) && (
        <polygon
          points={points}
          fill="none"
          stroke="rgba(255, 255, 255, 0.3)"
          strokeWidth={0.8}
        />
      )}
      
      {/* Oasis indicator - palm tree and water pool - ONLY show in desert terrain */}
      {hasOasis && tile.terrain === 'desert' && (
        <>
          <circle cx={x} cy={y + size * 0.2} r={size * 0.25} fill="#4299e1" opacity={0.5} />
          <text
            x={x}
            y={y - size * 0.1}
            fontSize={size * 0.6}
            textAnchor="middle"
            dominantBaseline="middle"
            fill="#2d5016"
          >
            🌴
          </text>
        </>
      )}
      
      {/* IMPROVED Volcano feature visual */}
      {hasVolcanoFeature && renderVolcanoVisual()}
      
      {/* Volcano indicator (hasVolcano flag) - tribal mountain fire symbol */}
      {tile.hasVolcano && !hasVolcanoFeature && renderVolcanoVisual()}
      
      {/* Render beautiful marine life for ocean and coast tiles */}
      {renderMarineLife()}
      
      {/* CRITICAL: Render beautiful resource icons on RIGHT side (max 2) */}
      {/* This renders ABOVE features if they exist */}
      {renderResourceIcons()}
      
      {/* RIVER INDICATOR - EXTREMELY VISIBLE Flowing water visual */}
      {hasRiver && (
        <>
          {/* River water overlay - MAXIMUM VISIBILITY */}
          <polygon
            points={points}
            fill="#2563eb"
            opacity={0.85}
            pointerEvents="none"
          />
          
          {/* Bright center for water depth effect */}
          <circle
            cx={x}
            cy={y}
            r={size * 0.5}
            fill="#3b82f6"
            opacity={0.7}
            pointerEvents="none"
          />
          
          {/* Water flow lines for dynamic effect - VERY PROMINENT */}
          <line
            x1={x - size * 0.5}
            y1={y - size * 0.3}
            x2={x + size * 0.5}
            y2={y + size * 0.3}
            stroke="#ffffff"
            strokeWidth={4}
            opacity={0.9}
            strokeDasharray="10,5"
            pointerEvents="none"
          />
          <line
            x1={x - size * 0.45}
            y1={y - size * 0.05}
            x2={x + size * 0.45}
            y2={y + size * 0.05}
            stroke="#bfdbfe"
            strokeWidth={3.5}
            opacity={0.8}
            strokeDasharray="8,4"
            pointerEvents="none"
          />
          <line
            x1={x - size * 0.4}
            y1={y + size * 0.25}
            x2={x + size * 0.4}
            y2={y - size * 0.25}
            stroke="#dbeafe"
            strokeWidth={3}
            opacity={0.7}
            strokeDasharray="6,3"
            pointerEvents="none"
          />
          
          {/* River sparkles for water effect - MORE VISIBLE */}
          <circle cx={x - size * 0.3} cy={y - size * 0.2} r={size * 0.08} fill="#ffffff" opacity={0.95} pointerEvents="none" />
          <circle cx={x + size * 0.25} cy={y + size * 0.15} r={size * 0.07} fill="#ffffff" opacity={0.9} pointerEvents="none" />
          <circle cx={x} cy={y - size * 0.3} r={size * 0.06} fill="#ffffff" opacity={1} pointerEvents="none" />
          <circle cx={x - size * 0.1} cy={y + size * 0.25} r={size * 0.05} fill="#ffffff" opacity={0.85} pointerEvents="none" />
          <circle cx={x + size * 0.35} cy={y - size * 0.1} r={size * 0.06} fill="#ffffff" opacity={0.9} pointerEvents="none" />
          
          {/* Water wave emoji for extra visibility */}
          <text
            x={x}
            y={y + size * 0.1}
            fontSize={size * 0.6}
            textAnchor="middle"
            dominantBaseline="middle"
            opacity={0.6}
          >
            🌊
          </text>
        </>
      )}
      
      {/* Multiple resources indicator (if more than 2 exist) */}
      {allResources.length > 2 && (
        <text
          x={x + size * 0.5}
          y={y + size * 0.5}
          fontSize={size * 0.4}
          textAnchor="middle"
          dominantBaseline="middle"
          fill="white"
          stroke="black"
          strokeWidth={0.5}
          fontWeight="bold"
        >
          +{allResources.length - 2}
        </text>
      )}
    </g>
  );
}
