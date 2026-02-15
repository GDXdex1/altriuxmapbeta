import React from 'react';
import { Texture, Assets } from 'pixi.js';
import { renderToStaticMarkup } from 'react-dom/server';
import { TerrainTemplate, FeatureTemplate, TerrainType, FeatureType } from './svg-templates';

export const createTextureManager = () => {
    const cache = new Map<string, Texture>();

    const getTerrainTexture = (type: TerrainType): Texture | undefined => {
        return cache.get(`terrain-${type}`);
    };

    const getFeatureTexture = (type: FeatureType): Texture | undefined => {
        return cache.get(`feature-${type}`);
    };

    const generateTexture = async (category: string, id: string, component: React.ReactElement) => {
        const key = `${category}-${id}`;
        if (cache.has(key)) return;

        try {
            const svgString = renderToStaticMarkup(component);
            const url = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svgString)}`;
            const texture = await Assets.load(url);
            console.log(`Textura generada ${key}: ${texture.width}x${texture.height}`);
            cache.set(key, texture);
        } catch (e) {
            console.error(`Error generando textura ${key}:`, e);
        }
    };

    const initialize = async () => {
        const terrains: TerrainType[] = ['ocean', 'coast', 'plains', 'meadow', 'hills', 'mountain_range', 'tundra', 'desert', 'ice'];
        const features: FeatureType[] = ['forest', 'jungle', 'boreal_forest', 'volcano', 'oasis', 'river'];

        console.log('Inicializando texturas PixiJS (Factory Pattern)...');

        for (const t of terrains) {
            await generateTexture('terrain', t, TerrainTemplate({ type: t }));
        }

        for (const f of features) {
            await generateTexture('feature', f, FeatureTemplate({ type: f }));
        }
    };

    return {
        initialize,
        getTerrainTexture,
        getFeatureTexture
    };
};

export type TextureManagerType = ReturnType<typeof createTextureManager>;

// Named export for compatibility
export const TextureManager = createTextureManager;
