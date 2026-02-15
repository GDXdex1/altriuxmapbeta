'use client';

import React, { useState, useEffect, useRef, useMemo, useCallback } from 'react';
import { Application, extend } from '@pixi/react';
import { Container, Sprite, Graphics } from 'pixi.js';
import { HexTile as HexTileType, HexCoordinates } from '@/lib/hexmap/types';
import { axialToPixel, pixelToAxial, getHexKey, wrapCoordinates } from '@/lib/hexmap/hex-utils';
import { generateEarthMap, addCoastalTiles } from '@/lib/hexmap/generator';
import { createTextureManager, TextureManagerType } from '@/lib/hexmap/texture-manager';
import { useGameTime } from '@/hooks/useGameTime';
import { useServerTime } from '@/hooks/useServerTime';
import { useTravel } from '@/contexts/TravelContext';
import { findPath, calculatePathTravelTime, getPathTerrainSummary, isDestinationReachable } from '@/lib/hexmap/pathfinding';
import { loadAllModifications, saveTerrainModification, saveResourcesOnly } from '@/lib/hexmap/terrain-storage';

// Componentes UI originales
import { MapHUD } from './MapHUD';
import { MapControls } from './MapControls';
import { MiniMap } from './MiniMap';
import { DuchyPanel } from './DuchyPanel';
import { TravelPanel } from './TravelPanel';
import { DuchyTravelIndicator } from './DuchyTravelIndicator';
import { TerrainEditorPanel } from './TerrainEditorPanel';

// Registrar componentes PixiJS
extend({ Container, Sprite, Graphics });

// Declaración de tipos para JSX intrínseco
declare global {
    namespace JSX {
        interface IntrinsicElements {
            container: any;
            sprite: any;
            graphics: any;
            application: any;
        }
    }
}

const HEX_SIZE = 20;
const MAP_WIDTH = 400;
const MAP_HEIGHT = 200;

export const HexMapCanvas = () => {
    const [tiles, setTiles] = useState<Map<string, HexTileType>>(new Map());
    const [viewport, setViewport] = useState({ x: 0, y: 0, scale: 1.0 });
    const [loading, setLoading] = useState(true);
    const [texturesReady, setTexturesReady] = useState(false);
    const [dimensions, setDimensions] = useState({ width: 1200, height: 800 });

    // Estado portado de HexMap.tsx
    const [selectedTile, setSelectedTile] = useState<HexTileType | null>(null);
    const [selectedTiles, setSelectedTiles] = useState<HexTileType[]>([]);
    const [playerLocation, setPlayerLocation] = useState<{ q: number; r: number }>({ q: -70, r: -17 });
    const [travelOrigin, setTravelOrigin] = useState<HexTileType | null>(null);
    const [travelDestination, setTravelDestination] = useState<HexTileType | null>(null);
    const [travelPath, setTravelPath] = useState<HexCoordinates[] | null>(null);
    const [showTravelPanel, setShowTravelPanel] = useState(false);
    const [isEditMode, setIsEditMode] = useState(false);
    const [showEditorPanel, setShowEditorPanel] = useState(false);

    const textureManager = useRef<TextureManagerType | null>(null);
    const gameTime = useGameTime();
    const { serverTime } = useServerTime();
    const { activeTravel, startDuchyTravel, updateTravel } = useTravel();
    const duchyTravel = activeTravel?.level === 'duchy' ? activeTravel : null;

    // Lógica de wrapping del viewport (Portado de HexMap.tsx)
    const wrapViewportX = useCallback((x: number, scale: number) => {
        const mapPixelWidth = MAP_WIDTH * HEX_SIZE * 1.5 * scale;
        let wrappedX = x;
        const halfWidth = mapPixelWidth / 2;
        if (wrappedX > halfWidth) wrappedX -= mapPixelWidth;
        else if (wrappedX < -halfWidth) wrappedX += mapPixelWidth;
        return wrappedX;
    }, []);

    useEffect(() => {
        if (typeof window !== 'undefined') {
            setDimensions({ width: window.innerWidth, height: window.innerHeight });
            const handleResize = () => setDimensions({ width: window.innerWidth, height: window.innerHeight });
            window.addEventListener('resize', handleResize);
            return () => window.removeEventListener('resize', handleResize);
        }
    }, []);

    // Carga de mapa con persistencia (Portado de HexMap.tsx)
    useEffect(() => {
        const loadMap = async () => {
            setLoading(true);
            try {
                const generatedMap = await generateEarthMap(42, gameTime.monthNumber);
                const modifications = loadAllModifications();
                for (const mod of modifications) {
                    const tile = generatedMap.get(getHexKey(mod.q, mod.r));
                    if (tile) {
                        tile.terrain = mod.terrain;
                        if (mod.features) tile.features = mod.features;
                    }
                }
                addCoastalTiles(generatedMap, {
                    width: 420, height: 220, hexSizeKm: 100,
                    continents: [
                        { centerQ: -70, centerR: -17, width: 70, height: 70, type: 'drantium' },
                        { centerQ: 70, centerR: 0, width: 70, height: 70, type: 'brontium' }
                    ],
                    islands: []
                });
                setTiles(generatedMap);
                setLoading(false);
            } catch (e) {
                console.error('Error loading map:', e);
            }
        };
        loadMap();
    }, [gameTime.monthNumber]);

    // Inicialización de texturas (PixiJS v8 Pattern)
    useEffect(() => {
        const initTextures = async () => {
            try {
                const tm = createTextureManager();
                textureManager.current = tm;
                await tm.initialize();
                setTexturesReady(true);
            } catch (e) {
                console.error('FATAL: Error initializing TextureManager:', e);
            }
        };
        initTextures();
    }, []);

    // Centrar en el jugador al cargar
    useEffect(() => {
        if (!loading && tiles.size > 0 && viewport.x === 0 && viewport.y === 0) {
            const { x, y } = axialToPixel(playerLocation.q, playerLocation.r, HEX_SIZE);
            setViewport({
                x: dimensions.width / 2 - x,
                y: dimensions.height / 2 - y,
                scale: 1.0
            });
        }
    }, [loading, tiles.size, playerLocation, dimensions]);

    // Handlers portados de HexMap.tsx
    const handleTileClick = (tile: HexTileType) => {
        setSelectedTile(tile);
        if (isEditMode) {
            setSelectedTiles([tile]);
            return;
        }

        if (showTravelPanel && travelOrigin) {
            if (!isDestinationReachable(tile.coordinates, tiles)) {
                setTravelDestination(tile);
                setTravelPath(null);
                return;
            }
            const path = findPath(travelOrigin.coordinates, tile.coordinates, tiles);
            setTravelDestination(tile);
            setTravelPath(path);
        }
    };

    const handleGoToPlayer = () => {
        const { x, y } = axialToPixel(playerLocation.q, playerLocation.r, HEX_SIZE);
        setViewport(prev => ({
            ...prev,
            x: dimensions.width / 2 - x * prev.scale,
            y: dimensions.height / 2 - y * prev.scale
        }));
    };

    const handleStartDuchyTravel = (destination: { q: number; r: number }) => {
        const path = findPath(playerLocation, destination, tiles);
        if (!path || path.length === 0) return;

        const travelTime = calculatePathTravelTime(path, tiles, 0.5);
        const startTime = new Date();
        const estimatedArrival = new Date(startTime.getTime() + travelTime * 24 * 60 * 60 * 1000);

        startDuchyTravel({
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
            terrainType: tiles.get(getHexKey(playerLocation.q, playerLocation.r))?.terrain || 'plains'
        });
        setSelectedTile(null);
    };

    // Renderizado optimizado de sprites (PixiJS Virtualization)
    const visibleSprites = useMemo(() => {
        if (loading || !texturesReady || !textureManager.current) return [];
        const sprites: JSX.Element[] = [];
        const tm = textureManager.current;

        // Culling bounds
        const padding = 10;
        const topLeft = pixelToAxial(-viewport.x / viewport.scale, -viewport.y / viewport.scale, HEX_SIZE);
        const bottomRight = pixelToAxial((-viewport.x + dimensions.width) / viewport.scale, (-viewport.y + dimensions.height) / viewport.scale, HEX_SIZE);

        for (let r = topLeft.r - padding; r <= bottomRight.r + padding; r++) {
            for (let q = topLeft.q - padding; q <= bottomRight.q + padding; q++) {
                const wrappedQ = wrapCoordinates(q, MAP_WIDTH);
                const tile = tiles.get(getHexKey(wrappedQ, r));
                if (!tile) continue;

                const { x, y } = axialToPixel(tile.coordinates.q, tile.coordinates.r, HEX_SIZE);

                // Terreno base
                const terrainTex = tm.getTerrainTexture(tile.terrain);
                if (terrainTex) {
                    sprites.push(
                        <sprite
                            key={`t-${tile.coordinates.q}-${tile.coordinates.r}`}
                            texture={terrainTex}
                            x={x} y={y}
                            anchor={0.5}
                            interactive={true}
                            pointertap={() => handleTileClick(tile)}
                        />
                    );
                }

                // Features
                if (tile.features) {
                    tile.features.forEach((f, i) => {
                        const fTex = tm.getFeatureTexture(f);
                        if (fTex) {
                            sprites.push(
                                <sprite
                                    key={`f-${tile.coordinates.q}-${tile.coordinates.r}-${i}`}
                                    texture={fTex}
                                    x={x} y={y}
                                    anchor={0.5}
                                    alpha={0.9}
                                />
                            );
                        }
                    });
                }
            }
        }
        return sprites;
    }, [tiles, viewport, loading, texturesReady, dimensions, isEditMode, travelOrigin]);

    if (loading || !texturesReady) {
        return (
            <div className="flex items-center justify-center h-screen bg-black text-white">
                <h2 className="text-2xl font-bold animate-pulse text-blue-400">ALTRIUX WORLD: INICIANDO MOTOR PIXIJS...</h2>
            </div>
        );
    }

    return (
        <div className="fixed inset-0 bg-black overflow-hidden touch-none select-none">
            {/* Lógica de Teclado */}
            <KeyboardHandler setViewport={setViewport} viewport={viewport} />

            {/* UI Overlays (Portado de HexMap.tsx) */}
            <MapHUD
                resources={{ atx: 10000, gdx: 5000, slx: 2500, bzx: 1250 }}
                gameDate={`Año ${gameTime.yearNumber}, Mes ${gameTime.monthNumber}, Día ${gameTime.dayNumber}`}
                season={`Norte: ${gameTime.seasonInNorth} | Sur: ${gameTime.seasonInSouth}`}
                onZoomIn={() => setViewport(v => ({ ...v, scale: Math.min(5, v.scale * 1.2) }))}
                onZoomOut={() => setViewport(v => ({ ...v, scale: Math.max(0.1, v.scale / 1.2) }))}
                onReset={() => setViewport({ x: dimensions.width / 2, y: dimensions.height / 2, scale: 1.0 })}
                onGoToPlayer={handleGoToPlayer}
                onOpenEditor={() => { setShowEditorPanel(true); setIsEditMode(true); }}
                onOpenResourceEditor={() => { }}
                onExportMap={() => { }}
                zoom={viewport.scale}
            />

            {selectedTile && !showTravelPanel && !showEditorPanel && !duchyTravel && (
                <DuchyPanel
                    tile={selectedTile}
                    tiles={tiles}
                    onClose={() => setSelectedTile(null)}
                    currentPlayerLocation={playerLocation}
                    serverTime={serverTime}
                    currentMonth={gameTime.monthNumber}
                    onStartTravel={(tile) => { setTravelOrigin(tile); setShowTravelPanel(true); }}
                    onStartDuchyTravel={handleStartDuchyTravel}
                    isCurrentlyTraveling={duchyTravel !== null}
                />
            )}

            {showTravelPanel && travelOrigin && (
                <TravelPanel
                    startTile={travelOrigin}
                    endTile={travelDestination}
                    path={travelPath}
                    travelTime={travelPath ? calculatePathTravelTime(travelPath, tiles, 1.0) : 0}
                    terrainSummary={travelPath ? getPathTerrainSummary(travelPath, tiles) : {}}
                    onClose={() => { setShowTravelPanel(false); setTravelPath(null); }}
                    onClearDestination={() => { setTravelDestination(null); setTravelPath(null); }}
                />
            )}

            {showEditorPanel && (
                <TerrainEditorPanel
                    selectedTiles={selectedTiles}
                    isEditing={isEditMode}
                    onClose={() => { setShowEditorPanel(false); setIsEditMode(false); }}
                    onTerrainChange={(q, r, t, f) => {
                        const key = getHexKey(q, r);
                        const tile = tiles.get(key);
                        if (tile) {
                            tile.terrain = t;
                            tile.features = f;
                            saveTerrainModification(q, r, t, f);
                            setTiles(new Map(tiles));
                        }
                    }}
                    onToggleEditMode={() => setIsEditMode(!isEditMode)}
                />
            )}

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

            <div className="absolute bottom-12 right-16 z-10">
                <MiniMap
                    tiles={tiles}
                    viewport={viewport}
                    mapWidth={MAP_WIDTH}
                    mapHeight={MAP_HEIGHT}
                    onNavigate={(x, y) => setViewport(prev => ({ ...prev, x, y }))}
                />
            </div>

            <Application
                width={dimensions.width}
                height={dimensions.height}
                backgroundColor={0x000000}
                antialias={true}
                resolution={typeof window !== 'undefined' ? window.devicePixelRatio : 1}
            >
                <container
                    position={[viewport.x, viewport.y]}
                    scale={viewport.scale}
                >
                    {visibleSprites}

                    {/* Renderizado de camino de viaje (PIXI.Graphics) */}
                    {travelPath && travelPath.length > 1 && (
                        <graphics
                            draw={(g) => {
                                g.clear();
                                g.setStrokeStyle({ width: 3, color: 0xfbbf24, alpha: 0.8 });
                                travelPath.forEach((coord, i) => {
                                    const { x, y } = axialToPixel(coord.q, coord.r, HEX_SIZE);
                                    if (i === 0) g.moveTo(x, y);
                                    else g.lineTo(x, y);
                                });
                                g.stroke();
                            }}
                        />
                    )}

                    {/* Indicador de jugador (PIXI.Graphics) */}
                    <graphics
                        draw={(g) => {
                            const { x, y } = axialToPixel(playerLocation.q, playerLocation.r, HEX_SIZE);
                            g.clear();
                            g.circle(x, y, 6);
                            g.fill(0x3b82f6);
                            g.setStrokeStyle({ width: 2, color: 0xffffff });
                            g.stroke();
                        }}
                    />

                    {/* Resaltado de Tile Seleccionado */}
                    {selectedTile && (
                        <graphics
                            draw={(g) => {
                                const { x, y } = axialToPixel(selectedTile.coordinates.q, selectedTile.coordinates.r, HEX_SIZE);
                                g.clear();
                                g.setStrokeStyle({ width: 3, color: 0xffffff, alpha: 0.9 });
                                for (let i = 0; i < 6; i++) {
                                    const angle = (Math.PI / 3) * i;
                                    const px = x + HEX_SIZE * Math.cos(angle);
                                    const py = y + HEX_SIZE * Math.sin(angle);
                                    if (i === 0) g.moveTo(px, py);
                                    else g.lineTo(px, py);
                                }
                                g.closePath();
                                g.stroke();
                            }}
                        />
                    )}
                </container>
            </Application>
        </div>
    );
};

// Helper interno para manejo de teclado
const KeyboardHandler = ({ setViewport, viewport }: { setViewport: any, viewport: any }) => {
    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            const step = 50 / viewport.scale;
            setViewport((prev: any) => {
                let { x, y } = prev;
                switch (e.key) {
                    case 'ArrowUp': case 'w': y += step; break;
                    case 'ArrowDown': case 's': y -= step; break;
                    case 'ArrowLeft': case 'a': x += step; break;
                    case 'ArrowRight': case 'd': x -= step; break;
                }
                return { ...prev, x, y };
            });
        };
        window.addEventListener('keydown', handleKeyDown);
        return () => window.removeEventListener('keydown', handleKeyDown);
    }, [viewport.scale, setViewport]);
    return null;
};
