'use client';

import React, { useState, useEffect, useRef, useMemo, useCallback } from 'react';
import { Application, extend } from '@pixi/react';
import { Container, Sprite, Graphics, Text } from 'pixi.js';
import { SubLand } from '@/lib/sublands/types';
import { axialToPixel, pixelToAxial, getHexKey } from '@/lib/hexmap/hex-utils';
import { generateSubLandsForHex } from '@/lib/sublands/generator';
import { createTextureManager, TextureManagerType } from '@/lib/hexmap/texture-manager';
import { useGameTime } from '@/hooks/useGameTime';
import { useServerTime } from '@/hooks/useServerTime';
import { useTravel } from '@/contexts/TravelContext';
import { findSubLandPath } from '@/lib/hexmap/subland-pathfinding';

extend({ Container, Sprite, Graphics, Text });

interface SubLandCanvasProps {
    parentQ: number;
    parentR: number;
    parentTile: any; // HexTile
    onSubLandClick: (subland: SubLand) => void;
    playerPosition: { q: number; r: number } | null;
    travelPath: { q: number; r: number }[] | null;
}

const SUB_HEX_SIZE = 10; // Pixel size for sub-hexagons

export const SubLandCanvas = ({
    parentQ,
    parentR,
    parentTile,
    onSubLandClick,
    playerPosition,
    travelPath
}: SubLandCanvasProps) => {
    const [sublands, setSublands] = useState<SubLand[]>([]);
    const [viewport, setViewport] = useState({ x: 0, y: 0, scale: 1.0 });
    const [texturesReady, setTexturesReady] = useState(false);
    const [dimensions, setDimensions] = useState({ width: 1200, height: 800 });

    const textureManager = useRef<TextureManagerType | null>(null);

    useEffect(() => {
        if (typeof window !== 'undefined') {
            setDimensions({ width: window.innerWidth, height: window.innerHeight });
            setViewport({ x: window.innerWidth / 2, y: window.innerHeight / 2, scale: 1.0 });
        }
    }, []);

    useEffect(() => {
        if (parentTile) {
            // Placeholder for coastal logic (simplified for beta)
            const generated = generateSubLandsForHex(parentTile, parentQ, parentR, [], []);
            setSublands(generated);
        }
    }, [parentTile, parentQ, parentR]);

    useEffect(() => {
        const initTextures = async () => {
            const tm = createTextureManager();
            textureManager.current = tm;
            await tm.initialize();
            setTexturesReady(true);
        };
        initTextures();
    }, []);

    // Draw all 10,000 hexagons using a single Graphics object for maximum performance
    const renderHexGrid = useCallback((g: any) => {
        g.clear();
        if (sublands.length === 0) return;

        sublands.forEach(sl => {
            const { x, y } = axialToPixel(sl.q, sl.r, SUB_HEX_SIZE);

            // Biome Colors (Ported from original canvas logic)
            let color = 0x4A5568; // Default
            if (sl.resourceType === 'coastal_land') color = 0xD2B48C;
            else if (sl.resourceType === 'coastal_inland') color = 0x4A9EC2;
            else if (sl.resourceType.startsWith('mine_')) color = 0xFFB84D;
            else if (sl.resourceType.startsWith('farmland_')) color = 0x8FBC94;
            else if (sl.hasRiver) color = sl.isNavigableRiver ? 0x4A90E2 : 0x7EC8E3;
            else {
                switch (sl.biomeType) {
                    case 'jungle': color = 0x1A472A; break;
                    case 'forest': color = 0x2D5A27; break;
                    case 'mountain': color = 0x718096; break;
                    case 'desert': color = 0xED8936; break;
                    case 'tundra': color = 0xA0AEC0; break;
                    case 'plains': color = 0x68D391; break;
                }
            }

            g.poly([
                x + SUB_HEX_SIZE, y,
                x + SUB_HEX_SIZE * 0.5, y + SUB_HEX_SIZE * 0.866,
                x - SUB_HEX_SIZE * 0.5, y + SUB_HEX_SIZE * 0.866,
                x - SUB_HEX_SIZE, y,
                x - SUB_HEX_SIZE * 0.5, y - SUB_HEX_SIZE * 0.866,
                x + SUB_HEX_SIZE * 0.5, y - SUB_HEX_SIZE * 0.866,
            ]);
            g.fill(color);
            g.stroke({ width: 0.5, color: 0xffffff, alpha: 0.1 });
        });
    }, [sublands]);

    if (!parentTile || !texturesReady) return null;

    return (
        <Application
            width={dimensions.width}
            height={dimensions.height}
            backgroundColor={0x000000}
            antialias={true}
        >
            <container
                position={[viewport.x, viewport.y]}
                scale={viewport.scale}
                interactive={true}
                pointerdown={(e: any) => {
                    const localPos = e.getLocalPosition(e.currentTarget);
                    const axial = pixelToAxial(localPos.x, localPos.y, SUB_HEX_SIZE);
                    const sl = sublands.find(s => s.q === axial.q && s.r === axial.r);
                    if (sl) onSubLandClick(sl);
                }}
            >
                <graphics draw={renderHexGrid} />

                {/* Player Indicator */}
                {playerPosition && (
                    <graphics
                        draw={(g) => {
                            const { x, y } = axialToPixel(playerPosition.q, playerPosition.r, SUB_HEX_SIZE);
                            g.clear();
                            g.circle(x, y, 4);
                            g.fill(0xff0000);
                            g.stroke({ width: 1, color: 0xffffff });
                        }}
                    />
                )}

                {/* Travel Path */}
                {travelPath && travelPath.length > 0 && (
                    <graphics
                        draw={(g) => {
                            g.clear();
                            g.setStrokeStyle({ width: 2, color: 0xffff00, alpha: 0.8 });
                            travelPath.forEach((pt, i) => {
                                const { x, y } = axialToPixel(pt.q, pt.r, SUB_HEX_SIZE);
                                if (i === 0) g.moveTo(x, y);
                                else g.lineTo(x, y);
                            });
                            g.stroke();
                        }}
                    />
                )}
            </container>
        </Application>
    );
};
