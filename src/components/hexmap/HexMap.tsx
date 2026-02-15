'use client';

import React, { useState, useRef, useEffect, useCallback } from 'react';
import type { HexTile as HexTileType } from '@/lib/hexmap/types';
import { axialToPixel, pixelToAxial, getHexKey, wrapCoordinates } from '@/lib/hexmap/hex-utils';
import { generateEarthMap, addCoastalTiles } from '@/lib/hexmap/generator';
import { HexTile } from './HexTile';
import { MapControls } from './MapControls';
import { MiniMap } from './MiniMap';
import { DuchyPanel } from './DuchyPanel';
import { MapHUD } from './MapHUD';
import { useGameTime, formatGameDate, formatDayNumber } from '@/hooks/useGameTime';
import { useServerTime } from '@/hooks/useServerTime';
import { MapPin } from 'lucide-react';
import { findPath, calculatePathTravelTime, getPathTerrainSummary, isDestinationReachable } from '@/lib/hexmap/pathfinding';
import { TravelPanel } from './TravelPanel';
import { axialToPixel as toPixel } from '@/lib/hexmap/hex-utils';
import { saveTerrainModification, saveResourcesOnly, loadAllModifications } from '@/lib/hexmap/terrain-storage';
import type { TerrainFeature, ResourceType, AnimalType, MineralType } from '@/lib/hexmap/types';
import { useTravel } from '@/contexts/TravelContext';
import { ResourceEditorPanel } from './ResourceEditorPanel';
import type { DuchyTravel } from '@/contexts/TravelContext';
import { DuchyTravelIndicator } from './DuchyTravelIndicator';

interface ViewPort {
  x: number;
  y: number;
  scale: number;
}

interface TouchState {
  distance: number;
  center: { x: number; y: number };
}

const RESOURCE_ICONS: Record<string, string> = {
  horses: '🐎', sheep: '🐑', buffalo: '🦬', muffon: '🐐', yaks: '🦬',
  gold: '⚜️', silver: '⚪', iron: '⚙️', tin: '🔩', bronze: '🥉',
  copper: '🟤', stone: '🪨', gems: '💎', wood: '🪵', fish: '🐟',
  whales: '🐋', crabs: '🦀',
  wheat: '🌾', cotton: '☁️', spices: '🌶️'
};

export function HexMap(): JSX.Element {
  const [tiles, setTiles] = useState<Map<string, HexTileType>>(new Map());
  const [riverEdges, setRiverEdges] = useState<Array<{ edgeId: string; hex1: { q: number; r: number }; hex2: { q: number; r: number }; direction: number; riverId: string }>>([]);
  const [selectedTile, setSelectedTile] = useState<HexTileType | null>(null);
  const [selectedTiles, setSelectedTiles] = useState<HexTileType[]>([]);
  // Travel route state
  const [travelOrigin, setTravelOrigin] = useState<HexTileType | null>(null);
  const [travelDestination, setTravelDestination] = useState<HexTileType | null>(null);
  const [travelPath, setTravelPath] = useState<HexCoordinates[] | null>(null);
  const [showTravelPanel, setShowTravelPanel] = useState<boolean>(false);
  // Terrain editor state
  const [isEditMode, setIsEditMode] = useState<boolean>(false);
  const [showEditorPanel, setShowEditorPanel] = useState<boolean>(false);
  const [showResourcePanel, setShowResourcePanel] = useState<boolean>(false);
  // Drag selection state for editor
  const [isDraggingSelection, setIsDraggingSelection] = useState<boolean>(false);
  const [selectionStartPixel, setSelectionStartPixel] = useState<{ x: number; y: number } | null>(null);
  const [selectionEndPixel, setSelectionEndPixel] = useState<{ x: number; y: number } | null>(null);
  // Start with scale 1.0 (100% zoom)
  const [viewport, setViewport] = useState<ViewPort>({ x: 0, y: 0, scale: 1.0 });
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const [dragStart, setDragStart] = useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const [touchState, setTouchState] = useState<TouchState | null>(null);

  // Player location state for tracking position on Duchy map
  // Initialize at a safe land position in Drantium continent
  const [playerLocation, setPlayerLocation] = useState<{ q: number; r: number }>({ q: -70, r: -17 });

  // Travel system using global context
  const { activeTravel, startDuchyTravel, updateTravel } = useTravel();
  const duchyTravel = activeTravel?.level === 'duchy' ? activeTravel : null;

  const svgRef = useRef<SVGSVGElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const HEX_SIZE = 20;
  const MAP_WIDTH = 400;
  const MAP_HEIGHT = 200;

  // Wrap viewport coordinates for east-west continuity
  const wrapViewport = (x: number, y: number, scale: number): { x: number; y: number } => {
    // Calculate the pixel width of the entire map
    const mapPixelWidth = MAP_WIDTH * HEX_SIZE * 1.5 * scale;

    // Wrap x coordinate (east-west)
    let wrappedX = x;
    const halfWidth = mapPixelWidth / 2;

    // If we've panned beyond the east edge, wrap to west
    if (wrappedX > halfWidth) {
      wrappedX = wrappedX - mapPixelWidth;
    }
    // If we've panned beyond the west edge, wrap to east
    else if (wrappedX < -halfWidth) {
      wrappedX = wrappedX + mapPixelWidth;
    }

    // Don't wrap y coordinate (north-south is limited)
    return { x: wrappedX, y };
  };

  const gameTime = useGameTime();
  const { serverTime } = useServerTime();

  // Generate map on mount with current month - with error handling
  useEffect(() => {
    const generateMap = async (): Promise<void> => {
      try {
        const generatedMap = await generateEarthMap(42, gameTime.monthNumber);

        // Apply stored terrain modifications
        const modifications = loadAllModifications();
        for (const mod of modifications) {
          const key = getHexKey(mod.q, mod.r);
          const tile = generatedMap.get(key);
          if (tile) {
            tile.terrain = mod.terrain;
            if (mod.features) {
              tile.features = mod.features;
            }
          }
        }

        // Regenerate coastal tiles after applying user modifications
        // This ensures coasts are correctly updated based on terrain changes
        // WITHOUT modifying deserts, tundras, or converting land to water
        addCoastalTiles(generatedMap, {
          width: 420,
          height: 220,
          hexSizeKm: 100,
          continents: [
            { centerQ: -70, centerR: -17, width: 70, height: 70, type: 'drantium' },
            { centerQ: 70, centerR: 0, width: 70, height: 70, type: 'brontium' }
          ],
          islands: []
        });

        // Extract river edges from metadata
        const edges = (generatedMap as any).__riverEdges || [];
        setRiverEdges(edges);

        setTiles(generatedMap);
      } catch (error) {
        console.error('Error generating map:', error);
        // Retry with default month if current month fails
        try {
          const generatedMap = await generateEarthMap(42, 1);
          setTiles(generatedMap);
        } catch (retryError) {
          console.error('Failed to generate map on retry:', retryError);
        }
      }
    };

    generateMap();
  }, [gameTime.monthNumber]);

  // Center the map viewport on initial load - centered on player's duchy
  useEffect(() => {
    if (containerRef.current && tiles.size > 0) {
      const container = containerRef.current;
      const containerWidth = container.clientWidth;
      const containerHeight = container.clientHeight;

      // Center on player's starting duchy (0, 0)
      const centerPixel = axialToPixel(playerLocation.q, playerLocation.r, HEX_SIZE);

      // Center the viewport on the player's duchy with 100% zoom
      setViewport({
        x: containerWidth / 2 - centerPixel.x * 1.0,
        y: containerHeight / 2 - centerPixel.y * 1.0,
        scale: 1.0
      });
    }
  }, [tiles.size, playerLocation.q, playerLocation.r]);

  // Get visible tiles based on viewport (optimized rendering with wrap-around)
  const getVisibleTiles = useCallback((): HexTileType[] => {
    if (!containerRef.current) return [];

    const container = containerRef.current;
    const width = container.clientWidth;
    const height = container.clientHeight;

    const visibleTiles: HexTileType[] = [];

    const topLeft = pixelToAxial(
      -viewport.x / viewport.scale,
      -viewport.y / viewport.scale,
      HEX_SIZE
    );
    const bottomRight = pixelToAxial(
      (-viewport.x + width) / viewport.scale,
      (-viewport.y + height) / viewport.scale,
      HEX_SIZE
    );

    const padding = 40; // Increased padding to show more tiles toward poles

    for (let r = topLeft.r - padding; r <= bottomRight.r + padding; r++) {
      for (let q = topLeft.q - padding; q <= bottomRight.q + padding; q++) {
        // Wrap q coordinate for east-west continuity
        const wrappedQ = wrapCoordinates(q, MAP_WIDTH);
        const key = getHexKey(wrappedQ, r);
        const tile = tiles.get(key);
        if (tile) {
          visibleTiles.push(tile);
        }
      }
    }

    return visibleTiles;
  }, [tiles, viewport]);

  const visibleTiles = getVisibleTiles();

  // Mouse/Touch drag handlers
  const handleMouseDown = (e: React.MouseEvent<SVGSVGElement>): void => {
    if (e.button === 0) {
      // In edit mode, start selection drag instead of map drag
      if (isEditMode) {
        const svgRect = svgRef.current?.getBoundingClientRect();
        if (svgRect) {
          const pixelX = (e.clientX - svgRect.left - viewport.x) / viewport.scale;
          const pixelY = (e.clientY - svgRect.top - viewport.y) / viewport.scale;
          setIsDraggingSelection(true);
          setSelectionStartPixel({ x: pixelX, y: pixelY });
          setSelectionEndPixel({ x: pixelX, y: pixelY });

          // Clear selection if not holding Ctrl
          if (!e.ctrlKey && !e.metaKey) {
            setSelectedTiles([]);
          }
        }
      } else {
        // Normal map dragging
        setIsDragging(true);
        setDragStart({ x: e.clientX - viewport.x, y: e.clientY - viewport.y });
      }
    }
  };

  const handleMouseMove = (e: React.MouseEvent<SVGSVGElement>): void => {
    if (isDraggingSelection && selectionStartPixel) {
      // Update drag selection rectangle
      const svgRect = svgRef.current?.getBoundingClientRect();
      if (svgRect) {
        const pixelX = (e.clientX - svgRect.left - viewport.x) / viewport.scale;
        const pixelY = (e.clientY - svgRect.top - viewport.y) / viewport.scale;
        setSelectionEndPixel({ x: pixelX, y: pixelY });
      }
    } else if (isDragging) {
      const newX = e.clientX - dragStart.x;
      const newY = e.clientY - dragStart.y;

      // Apply east-west wrapping to viewport
      const wrappedViewport = wrapViewport(newX, newY, viewport.scale);

      setViewport({
        ...viewport,
        x: wrappedViewport.x,
        y: wrappedViewport.y
      });
    }
  };

  const handleMouseUp = (e: React.MouseEvent<SVGSVGElement>): void => {
    if (isDraggingSelection && selectionStartPixel && selectionEndPixel) {
      // Calculate which tiles are in the selection rectangle
      const minX = Math.min(selectionStartPixel.x, selectionEndPixel.x);
      const maxX = Math.max(selectionStartPixel.x, selectionEndPixel.x);
      const minY = Math.min(selectionStartPixel.y, selectionEndPixel.y);
      const maxY = Math.max(selectionStartPixel.y, selectionEndPixel.y);

      const tilesInSelection: HexTileType[] = [];

      // Check all visible tiles
      for (const tile of visibleTiles) {
        const { x, y } = axialToPixel(tile.coordinates.q, tile.coordinates.r, HEX_SIZE);

        // Check if tile center is within selection rectangle
        if (x >= minX && x <= maxX && y >= minY && y <= maxY) {
          tilesInSelection.push(tile);
        }
      }

      // If Ctrl is held, add to existing selection, otherwise replace
      if (e.ctrlKey || e.metaKey) {
        // Add new tiles that aren't already selected
        const newTiles = tilesInSelection.filter(tile =>
          !selectedTiles.some(st =>
            st.coordinates.q === tile.coordinates.q && st.coordinates.r === tile.coordinates.r
          )
        );
        setSelectedTiles([...selectedTiles, ...newTiles]);
      } else {
        setSelectedTiles(tilesInSelection);
      }

      // Clear drag selection state
      setIsDraggingSelection(false);
      setSelectionStartPixel(null);
      setSelectionEndPixel(null);
    } else {
      setIsDragging(false);
    }
  };

  const handleWheel = (e: React.WheelEvent<SVGSVGElement>): void => {
    e.preventDefault();
    const scaleFactor = e.deltaY > 0 ? 0.9 : 1.1;
    const newScale = Math.max(0.1, Math.min(5, viewport.scale * scaleFactor));

    setViewport({
      ...viewport,
      scale: newScale
    });
  };

  const handleTouchStart = (e: React.TouchEvent<SVGSVGElement>): void => {
    if (e.touches.length === 1) {
      const touch = e.touches[0];
      if (touch) {
        setIsDragging(true);
        setDragStart({ x: touch.clientX - viewport.x, y: touch.clientY - viewport.y });
      }
    } else if (e.touches.length === 2) {
      const touch1 = e.touches[0];
      const touch2 = e.touches[1];
      if (touch1 && touch2) {
        const distance = Math.hypot(
          touch2.clientX - touch1.clientX,
          touch2.clientY - touch1.clientY
        );
        const center = {
          x: (touch1.clientX + touch2.clientX) / 2,
          y: (touch1.clientY + touch2.clientY) / 2
        };
        setTouchState({ distance, center });
        setIsDragging(false);
      }
    }
  };

  const handleTouchMove = (e: React.TouchEvent<SVGSVGElement>): void => {
    if (e.touches.length === 1 && isDragging) {
      const touch = e.touches[0];
      if (touch) {
        const newX = touch.clientX - dragStart.x;
        const newY = touch.clientY - dragStart.y;

        // Apply east-west wrapping to viewport
        const wrappedViewport = wrapViewport(newX, newY, viewport.scale);

        setViewport({
          ...viewport,
          x: wrappedViewport.x,
          y: wrappedViewport.y
        });
      }
    } else if (e.touches.length === 2 && touchState) {
      const touch1 = e.touches[0];
      const touch2 = e.touches[1];
      if (touch1 && touch2) {
        const distance = Math.hypot(
          touch2.clientX - touch1.clientX,
          touch2.clientY - touch1.clientY
        );
        const scaleFactor = distance / touchState.distance;
        const newScale = Math.max(0.1, Math.min(5, viewport.scale * scaleFactor));

        setViewport({
          ...viewport,
          scale: newScale
        });

        setTouchState({ distance, center: touchState.center });
      }
    }
  };

  const handleTouchEnd = (): void => {
    setIsDragging(false);
    setTouchState(null);
  };

  const handleTileClick = (tile: HexTileType, event?: React.MouseEvent): void => {
    setSelectedTile(tile);

    // If edit mode is active, handle multi-selection with Ctrl
    if (isEditMode) {
      if (event?.ctrlKey || event?.metaKey) {
        // Multi-selection mode: toggle tile selection
        const isAlreadySelected = selectedTiles.some(
          t => t.coordinates.q === tile.coordinates.q && t.coordinates.r === tile.coordinates.r
        );

        if (isAlreadySelected) {
          // Remove from selection
          setSelectedTiles(selectedTiles.filter(
            t => !(t.coordinates.q === tile.coordinates.q && t.coordinates.r === tile.coordinates.r)
          ));
        } else {
          // Add to selection
          setSelectedTiles([...selectedTiles, tile]);
        }
      } else {
        // Single selection mode: replace selection with this tile
        setSelectedTiles([tile]);
      }
      return;
    }

    // If travel panel is open, clicking sets destination
    if (showTravelPanel && travelOrigin) {
      // First check if destination itself is water/ice
      if (!isDestinationReachable(tile.coordinates, tiles)) {
        // Destination is water/ice - show as unreachable
        setTravelDestination(tile);
        setTravelPath(null);
        return;
      }

      // Destination is land, now try to find a path
      const path = findPath(travelOrigin.coordinates, tile.coordinates, tiles);

      // Set destination and path (path will be null if no route exists)
      setTravelDestination(tile);
      setTravelPath(path);

      // Path will be null if destination is unreachable (separated by water)
      // The TravelPanel will show the error message automatically
    }
  };

  const handleTerrainChange = (q: number, r: number, terrain: TerrainType, features: TerrainFeature[]): void => {
    // Update the tile in the map
    const key = getHexKey(q, r);
    const tile = tiles.get(key);

    if (tile) {
      tile.terrain = terrain;
      tile.features = features;

      // Save to localStorage
      saveTerrainModification(q, r, terrain, features);

      // Force re-render by creating new Map
      setTiles(new Map(tiles));

      alert(`Terrain updated to ${terrain}${features.length > 0 ? ' + ' + features.join(', ') : ''}`);
    }
  };

  const handleResourcesChange = (q: number, r: number, resources: ResourceType[], animals: AnimalType[], minerals: MineralType[]): void => {
    const key = getHexKey(q, r);
    const tile = tiles.get(key);

    if (tile) {
      tile.resources = resources;
      tile.animals = animals;
      tile.minerals = minerals;

      // Update tiles Map to trigger re-render
      setTiles(new Map(tiles));

      alert(`Resources updated for tile [${q}, ${r}]`);
    }
  };

  const handleExportMap = async (): Promise<void> => {
    if (!svgRef.current) return;

    try {
      // Simple SVG to PNG export
      const svg = svgRef.current;
      const svgData = new XMLSerializer().serializeToString(svg);
      const svgBlob = new Blob([svgData], { type: 'image/svg+xml;charset=utf-8' });
      const url = URL.createObjectURL(svgBlob);

      const img = new Image();
      img.onload = () => {
        const canvas = document.createElement('canvas');
        canvas.width = svg.clientWidth * 2; // High DPI
        canvas.height = svg.clientHeight * 2;
        const ctx = canvas.getContext('2d');
        if (ctx) {
          ctx.fillStyle = 'black'; // Background
          ctx.fillRect(0, 0, canvas.width, canvas.height);
          ctx.drawImage(img, 0, 0, canvas.width, canvas.height);

          const pngUrl = canvas.toDataURL('image/png');
          const downloadLink = document.createElement('a');
          downloadLink.href = pngUrl;
          downloadLink.download = `altriux-map-${Date.now()}.png`;
          document.body.appendChild(downloadLink);
          downloadLink.click();
          document.body.removeChild(downloadLink);
        }
        URL.revokeObjectURL(url);
      };
      img.src = url;

      alert('Generating high-resolution map image... please wait.');
    } catch (error) {
      console.error('Export failed:', error);
      alert('Map export failed. See console for details.');
    }
  };

  const handleToggleEditMode = (): void => {
    setIsEditMode(!isEditMode);
    if (!isEditMode) {
      // Entering edit mode
      setShowEditorPanel(true);
      setShowTravelPanel(false);
      // Initialize with current selected tile if any
      if (selectedTile) {
        setSelectedTiles([selectedTile]);
      }
    } else {
      // Exiting edit mode - clear multi-selection
      setSelectedTiles([]);
    }
  };

  const handleZoomIn = (): void => {
    setViewport({ ...viewport, scale: Math.min(5, viewport.scale * 1.2) });
  };

  const handleZoomOut = (): void => {
    setViewport({ ...viewport, scale: Math.max(0.1, viewport.scale / 1.2) });
  };

  const handleReset = (): void => {
    if (containerRef.current) {
      const container = containerRef.current;
      const containerWidth = container.clientWidth;
      const containerHeight = container.clientHeight;

      const centerPixel = axialToPixel(0, 0, HEX_SIZE);

      setViewport({
        x: containerWidth / 2 - centerPixel.x * 1.0,
        y: containerHeight / 2 - centerPixel.y * 1.0,
        scale: 1.0
      });
    } else {
      setViewport({ x: 0, y: 0, scale: 1.0 });
    }
    setSelectedTile(null);
  };

  const handleMove = (dx: number, dy: number): void => {
    const newX = viewport.x + dx;
    const newY = viewport.y + dy;

    // Apply east-west wrapping to viewport
    const wrappedViewport = wrapViewport(newX, newY, viewport.scale);

    setViewport({
      ...viewport,
      x: wrappedViewport.x,
      y: wrappedViewport.y
    });
  };

  const handleMiniMapNavigate = (x: number, y: number): void => {
    setViewport({
      ...viewport,
      x,
      y
    });
  };

  const handleGoToPlayer = (): void => {
    // Calculate pixel position of player location
    const { x, y } = axialToPixel(playerLocation.q, playerLocation.r, HEX_SIZE);

    // Center viewport on player location
    const containerWidth = containerRef.current?.clientWidth || 800;
    const containerHeight = containerRef.current?.clientHeight || 600;

    setViewport({
      ...viewport,
      x: containerWidth / 2 - x * viewport.scale,
      y: containerHeight / 2 - y * viewport.scale
    });

    // Auto-select the player's current tile to open the panel
    const playerTileKey = getHexKey(playerLocation.q, playerLocation.r);
    const playerTile = tiles.get(playerTileKey);
    if (playerTile) {
      setSelectedTile(playerTile);
    }
  };

  const handleStartTravel = (originTile: HexTileType): void => {
    setTravelOrigin(originTile);
    setTravelDestination(null);
    setTravelPath(null);
    setShowTravelPanel(true);
  };

  const handleClearDestination = (): void => {
    setTravelDestination(null);
    setTravelPath(null);
  };

  const handleCloseTravel = (): void => {
    setShowTravelPanel(false);
    setTravelOrigin(null);
    setTravelDestination(null);
    setTravelPath(null);
  };

  // Calculate travel time if path exists
  const travelTime = travelPath && travelPath.length > 0
    ? calculatePathTravelTime(travelPath, tiles, 1.0) // 1.0 = on foot speed
    : 0;

  const terrainSummary = travelPath && travelPath.length > 0
    ? getPathTerrainSummary(travelPath, tiles)
    : {};

  // Handle Duchy-level travel updates every second
  useEffect(() => {
    if (!duchyTravel) return;

    const updateInterval = setInterval(() => {
      updateTravel(prev => {
        if (!prev || prev.level !== 'duchy') return null;

        // Update elapsed time (1 second in real time = X progress in game days)
        // With 0.5 duchies per day speed, we update proportionally
        const newElapsedTime = prev.elapsedTime + (1 / 86400); // 1 second in days

        // Check if travel is complete
        if (newElapsedTime >= prev.totalTravelTime) {
          // Arrive at destination
          setPlayerLocation({ q: prev.destination.q, r: prev.destination.r });
          return null; // End travel
        }

        // Calculate which duchy we should be at based on elapsed time
        const progressRatio = newElapsedTime / prev.totalTravelTime;
        const targetDuchyIndex = Math.floor(progressRatio * (prev.path.length - 1));

        // Update current position if we've moved to a new duchy
        if (targetDuchyIndex !== prev.currentHexIndex && targetDuchyIndex < prev.path.length) {
          const newDuchy = prev.path[targetDuchyIndex];
          if (newDuchy) {
            setPlayerLocation({ q: newDuchy.q, r: newDuchy.r });

            // Update terrain type based on current duchy
            const currentTile = tiles.get(getHexKey(newDuchy.q, newDuchy.r));
            const currentTerrain = currentTile?.terrain || prev.terrainType;

            return {
              ...prev,
              currentPosition: newDuchy,
              currentHexIndex: targetDuchyIndex,
              elapsedTime: newElapsedTime,
              terrainType: currentTerrain
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
  }, [duchyTravel, tiles, updateTravel]);

  // Handler for starting travel from DuchyPanel
  const handleStartDuchyTravel = (destination: { q: number; r: number }): void => {
    if (duchyTravel) {
      alert('You are already traveling! Wait until you arrive at your destination.');
      return;
    }

    // Calculate path using A* pathfinding
    const path = findPath(playerLocation, destination, tiles);

    if (!path || path.length === 0) {
      alert('No path found to destination! The destination may be across water.');
      return;
    }

    // Check if path crosses water or ice
    const crossesWater = path.some((hex, index) => {
      if (index === 0) return false; // Skip starting position
      const tile = tiles.get(getHexKey(hex.q, hex.r));
      if (!tile) return false;

      // Block if terrain is impassable
      if (tile.terrain === 'ocean' || tile.terrain === 'coast' || tile.terrain === 'ice') {
        return true;
      }

      return false;
    });

    if (crossesWater) {
      alert('No hay ruta disponible. El destino es inaccesible a pie. Puede que necesites un barco para cruzar el agua.');
      return;
    }

    // Calculate travel time with terrain costs
    // Duchy Lands are 100x slower than SubLands: 0.5 duchies per day (vs 50 hexagons per day in SubLands)
    const travelTime = calculatePathTravelTime(path, tiles, 0.5); // 0.5 duchies per day (100x slower)

    // Create active travel object
    const startTime = new Date();
    const estimatedArrival = new Date(startTime.getTime() + travelTime * 24 * 60 * 60 * 1000);

    const originTile = tiles.get(getHexKey(playerLocation.q, playerLocation.r));

    const newTravel: Omit<DuchyTravel, 'level'> = {
      id: `duchy-travel-${Date.now()}`,
      origin: playerLocation,
      destination,
      path,
      currentPosition: playerLocation,
      currentHexIndex: 0,
      totalTravelTime: travelTime,
      elapsedTime: 0,
      startTime,
      estimatedArrival,
      terrainType: originTile?.terrain || 'plains'
    };

    startDuchyTravel(newTravel);
    setSelectedTile(null); // Close panel
  };

  return (
    <div ref={containerRef} className="fixed inset-0 bg-black overflow-hidden touch-none select-none">
      {/* Map HUD Frame - Top, Left, Right, Bottom bars */}
      <MapHUD
        resources={{
          atx: 10000,
          gdx: 5000,
          slx: 2500,
          bzx: 1250
        }}
        gameDate={`Year ${gameTime.yearNumber}, Month ${gameTime.monthNumber}, Day ${gameTime.dayNumber}`}
        season={`North: ${gameTime.seasonInNorth} | South: ${gameTime.seasonInSouth}`}
        onZoomIn={handleZoomIn}
        onZoomOut={handleZoomOut}
        onReset={handleReset}
        onGoToPlayer={handleGoToPlayer}
        onOpenEditor={() => {
          setShowEditorPanel(true);
          setShowResourcePanel(false);
          setShowTravelPanel(false);
        }}
        onOpenResourceEditor={() => {
          setShowResourcePanel(true);
          setShowEditorPanel(false);
          setShowTravelPanel(false);
        }}
        onExportMap={handleExportMap}
        zoom={viewport.scale}
      />

      {/* Mini Map - Bottom Right (inside frame) */}
      <div className="absolute bottom-12 right-16 z-10">
        <MiniMap
          tiles={tiles}
          viewport={viewport}
          mapWidth={MAP_WIDTH}
          mapHeight={MAP_HEIGHT}
          onNavigate={handleMiniMapNavigate}
        />
      </div>

      {/* Travel Panel */}
      {showTravelPanel && travelOrigin && (
        <TravelPanel
          startTile={travelOrigin}
          endTile={travelDestination}
          path={travelPath}
          travelTime={travelTime}
          terrainSummary={terrainSummary}
          onClose={handleCloseTravel}
          onClearDestination={handleClearDestination}
        />
      )}

      {/* Terrain Editor Panel */}
      {showEditorPanel && (
        <TerrainEditorPanel
          selectedTiles={selectedTiles}
          isEditing={isEditMode}
          onClose={() => {
            setShowEditorPanel(false);
            setIsEditMode(false);
            setSelectedTiles([]);
          }}
          onTerrainChange={handleTerrainChange}
          onToggleEditMode={handleToggleEditMode}
        />
      )}

      {/* Resource Editor Panel */}
      {showResourcePanel && selectedTile && (
        <ResourceEditorPanel
          selectedTile={selectedTile}
          onClose={() => setShowResourcePanel(false)}
          onResourcesChange={handleResourcesChange}
        />
      )}

      {/* Duchy Travel Indicator */}
      {duchyTravel && (
        <DuchyTravelIndicator
          origin={duchyTravel.origin}
          destination={duchyTravel.destination}
          currentPosition={duchyTravel.currentPosition}
          path={duchyTravel.path}
          totalTravelTime={duchyTravel.totalTravelTime}
          elapsedTime={duchyTravel.elapsedTime}
          currentHexIndex={duchyTravel.currentHexIndex}
          estimatedArrival={duchyTravel.estimatedArrival}
          terrainType={duchyTravel.terrainType}
        />
      )}

      {/* Duchy Panel with Travel & Overview */}
      {selectedTile && !showTravelPanel && !showEditorPanel && !duchyTravel && (
        <DuchyPanel
          tile={selectedTile}
          tiles={tiles}
          onClose={() => setSelectedTile(null)}
          currentPlayerLocation={playerLocation}
          serverTime={serverTime}
          currentMonth={gameTime.monthNumber}
          onStartTravel={handleStartTravel}
          onStartDuchyTravel={handleStartDuchyTravel}
          isCurrentlyTraveling={duchyTravel !== null}
        />
      )}

      {/* SVG Map - Inside Frame (80-90% of screen) */}
      <svg
        ref={svgRef}
        className="absolute top-14 left-14 right-14 bottom-10"
        style={{
          width: 'calc(100% - 112px)',
          height: 'calc(100% - 96px)',
          cursor: isDragging ? 'grabbing' : 'grab'
        }}
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={(e) => {
          setIsDragging(false);
          setIsDraggingSelection(false);
          setSelectionStartPixel(null);
          setSelectionEndPixel(null);
        }}
        onWheel={handleWheel}
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}
      >
        <g transform={`translate(${viewport.x}, ${viewport.y}) scale(${viewport.scale})`}>
          {visibleTiles.map((tile) => {
            const { x, y } = axialToPixel(tile.coordinates.q, tile.coordinates.r, HEX_SIZE);

            // Check if this tile is on the travel path
            const isOnPath = travelPath && travelPath.some(
              coord => coord.q === tile.coordinates.q && coord.r === tile.coordinates.r
            );

            // Check if this is the player's current location
            const isPlayerLocation = playerLocation.q === tile.coordinates.q && playerLocation.r === tile.coordinates.r;

            return (
              <HexTile
                key={getHexKey(tile.coordinates.q, tile.coordinates.r)}
                tile={tile}
                size={HEX_SIZE}
                x={x}
                y={y}
                onClick={handleTileClick}
                selected={
                  isPlayerLocation ||
                  (selectedTile?.coordinates.q === tile.coordinates.q &&
                    selectedTile?.coordinates.r === tile.coordinates.r) ||
                  (isEditMode && selectedTiles.some(
                    t => t.coordinates.q === tile.coordinates.q && t.coordinates.r === tile.coordinates.r
                  ))
                }
                isOnPath={isOnPath || false}
              />
            );
          })}

          {/* Draw path line */}
          {travelPath && travelPath.length > 1 && (
            <polyline
              points={travelPath.map(coord => {
                const { x, y } = axialToPixel(coord.q, coord.r, HEX_SIZE);
                return `${x},${y}`;
              }).join(' ')}
              fill="none"
              stroke="#fbbf24"
              strokeWidth={2}
              strokeDasharray="5,5"
              strokeLinecap="round"
              strokeLinejoin="round"
              opacity={0.8}
            />
          )}

          {/* Draw drag selection rectangle */}
          {isDraggingSelection && selectionStartPixel && selectionEndPixel && (
            <rect
              x={Math.min(selectionStartPixel.x, selectionEndPixel.x)}
              y={Math.min(selectionStartPixel.y, selectionEndPixel.y)}
              width={Math.abs(selectionEndPixel.x - selectionStartPixel.x)}
              height={Math.abs(selectionEndPixel.y - selectionStartPixel.y)}
              fill="rgba(59, 130, 246, 0.2)"
              stroke="#3b82f6"
              strokeWidth={2}
              strokeDasharray="5,5"
            />
          )}
        </g>
      </svg>
    </div>
  );
}
