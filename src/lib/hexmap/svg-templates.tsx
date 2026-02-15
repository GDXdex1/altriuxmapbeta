
import React from 'react';

const HEX_SIZE = 20;

export type TerrainType = 'ocean' | 'coast' | 'plains' | 'meadow' | 'hills' | 'mountain_range' | 'tundra' | 'desert' | 'ice';
export type FeatureType = 'forest' | 'jungle' | 'boreal_forest' | 'volcano' | 'oasis' | 'river' | 'mountain' | 'swamp';

const TERRAIN_COLORS: Record<string, string> = {
    ocean: '#1e40af', coast: '#3b82f6', ice: '#e0f2fe',
    plains: '#a3e635', meadow: '#84cc16', hills: '#65a30d',
    mountain_range: '#78716c', tundra: '#cbd5e1', desert: '#fcd34d'
};

const TERRAIN_STROKE: Record<string, string> = {
    ocean: '#1e3a8a', coast: '#2563eb', ice: '#bae6fd',
    plains: '#84cc16', meadow: '#65a30d', hills: '#4d7c0f',
    mountain_range: '#57534e', tundra: '#94a3b8', desert: '#fbbf24'
};

const POINTS = Array.from({ length: 6 }, (_, i) => {
    const angle = (Math.PI / 3) * i;
    return `${HEX_SIZE * Math.cos(angle)},${HEX_SIZE * Math.sin(angle)}`;
}).join(' ');

// Slightly larger fill to prevent gaps
const POINTS_FILL = Array.from({ length: 6 }, (_, i) => {
    const angle = (Math.PI / 3) * i;
    return `${(HEX_SIZE + 0.5) * Math.cos(angle)},${(HEX_SIZE + 0.5) * Math.sin(angle)}`;
}).join(' ');

export const TerrainTemplate = ({ type }: { type: TerrainType }) => {
    const color = TERRAIN_COLORS[type] || '#666';
    const stroke = TERRAIN_STROKE[type] || '#000';
    const size = HEX_SIZE * 2.5; const p = size / 2;
    const q = 0; const r = 0; // Constants for IDs

    return (
        <svg width={size} height={size} viewBox={`-${p} -${p} ${size} ${size}`} xmlns="http://www.w3.org/2000/svg">
            <defs>
                {type === 'mountain_range' && (
                    <linearGradient id={`mount-grad-${type}`} x1="0%" y1="0%" x2="100%" y2="100%">
                        <stop offset="0%" style={{ stopColor: '#b8b8b8', stopOpacity: 1 }} />
                        <stop offset="30%" style={{ stopColor: '#8a8a8a', stopOpacity: 1 }} />
                        <stop offset="70%" style={{ stopColor: '#6b6b6b', stopOpacity: 1 }} />
                        <stop offset="100%" style={{ stopColor: '#4a4a4a', stopOpacity: 1 }} />
                    </linearGradient>
                )}
                {type === 'ice' && (
                    <linearGradient id={`ice-grad-${type}`} x1="0%" y1="0%" x2="100%" y2="100%">
                        <stop offset="0%" style={{ stopColor: '#ffffff', stopOpacity: 1 }} />
                        <stop offset="50%" style={{ stopColor: '#f0f9ff', stopOpacity: 1 }} />
                        <stop offset="100%" style={{ stopColor: '#e0f2fe', stopOpacity: 1 }} />
                    </linearGradient>
                )}
            </defs>
            <polygon
                points={POINTS_FILL}
                fill={type === 'mountain_range' ? `url(#mount-grad-${type})` : type === 'ice' ? `url(#ice-grad-${type})` : color}
                stroke={stroke}
                strokeWidth={1}
            />
        </svg>
    );
};

export const FeatureTemplate = ({ type }: { type: FeatureType }) => {
    const size = HEX_SIZE * 2.5; const p = size / 2;
    const x = 0; const y = 0; // Centers

    if (type === 'forest') {
        return (
            <svg width={size} height={size} viewBox={`-${p} -${p} ${size} ${size}`} xmlns="http://www.w3.org/2000/svg">
                <text x={x - HEX_SIZE * 0.45} y={y - HEX_SIZE * 0.35} fontSize={HEX_SIZE * 0.5} fill="#0d2607">🌲</text>
                <text x={x} y={y - HEX_SIZE * 0.45} fontSize={HEX_SIZE * 0.55} fill="#0d2607">🌲</text>
                <text x={x + HEX_SIZE * 0.45} y={y - HEX_SIZE * 0.3} fontSize={HEX_SIZE * 0.48} fill="#0d2607">🌲</text>
                <text x={x - HEX_SIZE * 0.5} y={y} fontSize={HEX_SIZE * 0.52} fill="#0d2607">🌲</text>
                <text x={x - HEX_SIZE * 0.05} y={y - HEX_SIZE * 0.05} fontSize={HEX_SIZE * 0.58} fill="#0d2607">🌲</text>
                <text x={x + HEX_SIZE * 0.5} y={y + HEX_SIZE * 0.05} fontSize={HEX_SIZE * 0.5} fill="#0d2607">🌲</text>
            </svg>
        );
    }

    if (type === 'jungle') {
        return (
            <svg width={size} height={size} viewBox={`-${p} -${p} ${size} ${size}`} xmlns="http://www.w3.org/2000/svg">
                <text x={x - HEX_SIZE * 0.48} y={y - HEX_SIZE * 0.38} fontSize={HEX_SIZE * 0.55} fill="#072814">🌴</text>
                <text x={x - HEX_SIZE * 0.05} y={y - HEX_SIZE * 0.48} fontSize={HEX_SIZE * 0.6} fill="#072814">🌴</text>
                <text x={x + HEX_SIZE * 0.48} y={y - HEX_SIZE * 0.32} fontSize={HEX_SIZE * 0.52} fill="#072814">🌴</text>
                <text x={x - HEX_SIZE * 0.52} y={y + HEX_SIZE * 0.05} fontSize={HEX_SIZE * 0.57} fill="#072814">🌴</text>
                <text x={x - HEX_SIZE * 0.02} y={y} fontSize={HEX_SIZE * 0.62} fill="#072814">🌴</text>
            </svg>
        );
    }

    if (type === 'mountain' || type === 'mountain_range') {
        return (
            <svg width={size} height={size} viewBox={`-${p} -${p} ${size} ${size}`} xmlns="http://www.w3.org/2000/svg">
                <text x="0" y="0" fontSize={HEX_SIZE * 1.5} textAnchor="middle" dominantBaseline="middle">⛰️</text>
            </svg>
        );
    }

    if (type === 'volcano') {
        return (
            <svg width={size} height={size} viewBox={`-${p} -${p} ${size} ${size}`} xmlns="http://www.w3.org/2000/svg">
                <circle cx={0} cy={-HEX_SIZE * 0.1} r={HEX_SIZE * 0.35} fill="#ff6347" opacity={0.3} />
                <text x="0" y="0" fontSize={HEX_SIZE * 1.5} textAnchor="middle" dominantBaseline="middle">🌋</text>
            </svg>
        );
    }

    if (type === 'oasis') {
        return (
            <svg width={size} height={size} viewBox={`-${p} -${p} ${size} ${size}`} xmlns="http://www.w3.org/2000/svg">
                <text x="0" y="0" fontSize={HEX_SIZE * 1.5} textAnchor="middle" dominantBaseline="middle">🏝️</text>
            </svg>
        );
    }

    if (type === 'river') {
        return (
            <svg width={size} height={size} viewBox={`-${p} -${p} ${size} ${size}`} xmlns="http://www.w3.org/2000/svg">
                <path d={`M ${-HEX_SIZE / 2} 0 Q 0 ${HEX_SIZE / 4} ${HEX_SIZE / 2} 0`} stroke="#3b82f6" strokeWidth={3} fill="none" />
            </svg>
        );
    }

    if (type === 'swamp') {
        return (
            <svg width={size} height={size} viewBox={`-${p} -${p} ${size} ${size}`} xmlns="http://www.w3.org/2000/svg">
                <text x="0" y="0" fontSize={HEX_SIZE * 1.2} textAnchor="middle" dominantBaseline="middle">🐊</text>
            </svg>
        );
    }

    return null;
};
