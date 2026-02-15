'use client';

import { use, useState, useEffect } from 'react';
import Link from 'next/link';
import { ArrowLeft, ZoomIn, ZoomOut, Home } from 'lucide-react';
import { SubLandCanvas } from '@/components/hexmap/SubLandCanvas';
import { SubLandPanel } from '@/components/hexmap/SubLandPanel';
import { generateEarthMap } from '@/lib/hexmap/generator';
import { getHexKey } from '@/lib/hexmap/hex-utils';
import { SubLand } from '@/lib/sublands/types';
import { Button } from '@/components/ui/button';

interface LandDetailPageProps {
    params: Promise<{
        q: string;
        r: string;
    }>;
}

export default function LandDetailPage({ params }: LandDetailPageProps) {
    const resolvedParams = use(params);
    const q = parseInt(resolvedParams.q, 10);
    const r = parseInt(resolvedParams.r, 10);

    const [parentTile, setParentTile] = useState<any>(null);
    const [selectedSubLand, setSelectedSubLand] = useState<SubLand | null>(null);
    const [playerPosition, setPlayerPosition] = useState<{ q: number; r: number }>({ q: 0, r: 0 });

    useEffect(() => {
        const loadParentTile = async () => {
            const map = await generateEarthMap(42, 1);
            const tile = map.get(getHexKey(q, r));
            setParentTile(tile);
        };
        loadParentTile();
    }, [q, r]);

    return (
        <div className="fixed inset-0 bg-black overflow-hidden select-none">
            {/* Header / Navigation */}
            <div className="absolute top-4 left-4 z-20 flex gap-2">
                <Link href="/">
                    <Button variant="secondary" size="sm" className="bg-black/60 backdrop-blur-md border-amber-500/30 text-amber-400">
                        <ArrowLeft className="w-4 h-4 mr-2" />
                        Back to World
                    </Button>
                </Link>
            </div>

            <div className="absolute top-4 right-4 z-20 text-right">
                <h1 className="text-xl font-bold text-white drop-shadow-lg">
                    Duchy at ({q}, {r})
                </h1>
                <p className="text-amber-400 text-sm">Detailed SubLand View (PixiJS Beta)</p>
            </div>

            {/* SubLand Canvas */}
            {parentTile && (
                <SubLandCanvas
                    parentQ={q}
                    parentR={r}
                    parentTile={parentTile}
                    onSubLandClick={setSelectedSubLand}
                    playerPosition={playerPosition}
                    travelPath={null}
                />
            )}

            {/* SubLand Info Panel */}
            {selectedSubLand && (
                <SubLandPanel
                    subland={selectedSubLand}
                    parentQ={q}
                    parentR={r}
                    onClose={() => setSelectedSubLand(null)}
                    playerPosition={playerPosition}
                    onNavigate={() => { }}
                    onStartTravel={(dest) => setPlayerPosition(dest)}
                />
            )}

            <div className="absolute bottom-8 left-1/2 -translate-x-1/2 z-20 flex gap-4 bg-black/40 backdrop-blur-lg px-6 py-3 rounded-full border border-white/10">
                <div className="flex items-center gap-2 text-white/80 text-sm">
                    <div className="w-3 h-3 rounded-full bg-red-500 animate-pulse" />
                    Live SubLand Tracker
                </div>
            </div>
        </div>
    );
}
