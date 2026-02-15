'use client';

import React, { useState, useEffect } from 'react';
import type { HexTile, ResourceType, AnimalType, MineralType } from '@/lib/hexmap/types';
import { Package, X, Save } from 'lucide-react';
import { saveResourcesOnly, getModification } from '@/lib/hexmap/terrain-storage';

interface ResourceEditorPanelProps {
    selectedTile: HexTile | null;
    onClose: () => void;
    onResourcesChange: (q: number, r: number, resources: ResourceType[], animals: AnimalType[], minerals: MineralType[]) => void;
}

const NATURAL_RESOURCES: { value: ResourceType; label: string }[] = [
    { value: 'wood', label: '🪵 Wood' },
    { value: 'fish', label: '🐟 Fish' },
    { value: 'whales', label: '🐋 Whales' },
    { value: 'crabs', label: '🦀 Crabs' },
    { value: 'wheat', label: '🌾 Wheat' },
    { value: 'cotton', label: '☁️ Cotton' },
    { value: 'spices', label: '🌶️ Spices' },
    { value: 'legumes', label: '🫘 Legumes' },
    { value: 'flax', label: '🧵 Flax' },
    { value: 'corn', label: '🌽 Corn' },
    { value: 'dates', label: '🌴 Dates' },
    { value: 'oil_well', label: '🛢️ Oil Well' },
];

const MINERAL_OPTIONS: { value: MineralType; label: string }[] = [
    { value: 'gold', label: '🟡 Gold' },
    { value: 'silver', label: '⚪ Silver' },
    { value: 'iron', label: '⛓️ Iron' },
    { value: 'tin', label: '🥫 Tin' },
    { value: 'bronze', label: '🥉 Bronze' },
    { value: 'copper', label: '🟠 Copper' },
    { value: 'stone', label: '🪨 Stone' },
    { value: 'gems', label: '💎 Gems' },
    { value: 'galena', label: '🌑 Galena (Pb+Ag)' },
    { value: 'zinc', label: '💿 Zinc' },
    { value: 'nickel', label: '💠 Nickel' },
    { value: 'cobalt', label: '🧿 Cobalt' },
    { value: 'laterite', label: '🧱 Laterite (Ni+Co)' }, // Requires: Foreman, Yield: 10 JAX/day (45% Ni, 7% Co)
    { value: 'cassiterite', label: '🎱 Cassiterite (Sn)' },
    { value: 'limestone', label: '⚪ Limestone' },
    { value: 'marble', label: '🏛️ Marble' },
];

const ANIMAL_OPTIONS: { value: AnimalType; label: string }[] = [
    { value: 'horses', label: '🐎 Horses' },
    { value: 'sheep', label: '🐑 Sheep' },
    { value: 'buffalo', label: '🐃 Buffalo' },
    { value: 'muffon', label: '🐐 Muffon' },
    { value: 'yaks', label: '🐂 Yaks' },
    { value: 'camels', label: '🐪 Camels' },
    { value: 'wild_cattle', label: '🐄 Wild Cattle' },
    { value: 'wild_horse', label: '🐎 Wild Horse' },
    { value: 'wild_camel', label: '🐪 Wild Camel' },
    { value: 'wild_yak', label: '🐂 Wild Yak' },
    { value: 'boar', label: '🐗 Boar' },
    { value: 'wolf', label: '🐺 Wolf' },
    { value: 'jackal', label: '🐕 Jackal' },
    { value: 'wild_cat', label: '🐈 Wild Cat' },
    { value: 'wild_dog', label: '🐕 Wild Dog' },
    { value: 'wild_donkey', label: '🫏 Wild Donkey' },
];

export function ResourceEditorPanel({
    selectedTile,
    onClose,
    onResourcesChange
}: ResourceEditorPanelProps): JSX.Element | null {
    const [selectedResources, setSelectedResources] = useState<ResourceType[]>([]);
    const [selectedMinerals, setSelectedMinerals] = useState<MineralType[]>([]);
    const [selectedAnimals, setSelectedAnimals] = useState<AnimalType[]>([]);

    // Load existing resources when tile changes
    useEffect(() => {
        if (!selectedTile) return;

        // Check for modifications first
        const modification = getModification(selectedTile.coordinates.q, selectedTile.coordinates.r);

        if (modification) {
            setSelectedResources(modification.resources || []);
            setSelectedMinerals(modification.minerals || []);
            setSelectedAnimals(modification.animals || []);
        } else {
            // Use tile's current data
            setSelectedResources(selectedTile.resources || []);
            setSelectedMinerals(selectedTile.minerals || []);
            setSelectedAnimals(selectedTile.animals || []);
        }
    }, [selectedTile]);

    if (!selectedTile) return null;

    const handleToggleResource = (resource: ResourceType): void => {
        setSelectedResources(prev =>
            prev.includes(resource)
                ? prev.filter(r => r !== resource)
                : [...prev, resource]
        );
    };

    const handleToggleMineral = (mineral: MineralType): void => {
        setSelectedMinerals(prev =>
            prev.includes(mineral)
                ? prev.filter(m => m !== mineral)
                : [...prev, mineral]
        );
    };

    const handleToggleAnimal = (animal: AnimalType): void => {
        setSelectedAnimals(prev =>
            prev.includes(animal)
                ? prev.filter(a => a !== animal)
                : [...prev, animal]
        );
    };

    const handleApplyResources = (): void => {
        const { q, r } = selectedTile.coordinates;

        // Save to storage (without modifying terrain/features)
        saveResourcesOnly(q, r, selectedResources, selectedAnimals, selectedMinerals);

        // Notify parent component
        onResourcesChange(q, r, selectedResources, selectedAnimals, selectedMinerals);
    };

    return (
        <div className="fixed top-20 right-[420px] bg-gray-900 border-2 border-green-500 rounded-lg shadow-2xl z-50 w-80 max-h-[calc(100vh-120px)] overflow-y-auto">
            {/* Header */}
            <div className="flex items-center justify-between p-4 border-b border-green-500/30 bg-gradient-to-r from-green-900/50 to-gray-900">
                <div className="flex items-center gap-2">
                    <Package className="w-5 h-5 text-green-400" />
                    <h2 className="text-lg font-bold text-green-400">Resources</h2>
                </div>
                <button
                    onClick={onClose}
                    className="text-green-400 hover:text-green-300 transition-colors"
                >
                    <X className="w-5 h-5" />
                </button>
            </div>

            {/* Tile Info */}
            <div className="p-4 border-b border-green-500/30 bg-gray-800/50">
                <div className="grid grid-cols-2 gap-2 text-xs">
                    <div>
                        <span className="text-gray-400">Q:</span>
                        <span className="text-white ml-1">{selectedTile.coordinates.q}</span>
                    </div>
                    <div>
                        <span className="text-gray-400">R:</span>
                        <span className="text-white ml-1">{selectedTile.coordinates.r}</span>
                    </div>
                    <div className="col-span-2">
                        <span className="text-gray-400">Biome:</span>
                        <span className="text-white ml-1 capitalize">{selectedTile.terrain}</span>
                        {selectedTile.features && selectedTile.features.length > 0 && (
                            <span className="text-green-400 ml-1">
                                + {selectedTile.features.join(', ')}
                            </span>
                        )}
                    </div>
                </div>
                <p className="text-xs text-amber-300 mt-2">
                    💡 Add resources without changing biome
                </p>
            </div>

            {/* Natural Resources */}
            <div className="p-4 border-b border-green-500/30">
                <h3 className="text-sm font-bold text-green-300 mb-3">Natural Resources</h3>
                <div className="grid grid-cols-2 gap-2">
                    {NATURAL_RESOURCES.map((option) => (
                        <button
                            key={option.value}
                            onClick={() => handleToggleResource(option.value)}
                            className={`p-2 rounded-lg border-2 transition-all text-xs font-medium ${selectedResources.includes(option.value)
                                ? 'border-green-400 bg-green-900/50 text-white'
                                : 'border-gray-600 bg-gray-800 text-gray-300 hover:border-gray-500'
                                }`}
                        >
                            {option.label}
                        </button>
                    ))}
                </div>
            </div>

            {/* Minerals */}
            <div className="p-4 border-b border-green-500/30">
                <h3 className="text-sm font-bold text-green-300 mb-3">Minerals</h3>
                <div className="grid grid-cols-2 gap-2">
                    {MINERAL_OPTIONS.map((option) => (
                        <button
                            key={option.value}
                            onClick={() => handleToggleMineral(option.value)}
                            className={`p-2 rounded-lg border-2 transition-all text-xs font-medium ${selectedMinerals.includes(option.value)
                                ? 'border-yellow-400 bg-yellow-900/50 text-white'
                                : 'border-gray-600 bg-gray-800 text-gray-300 hover:border-gray-500'
                                }`}
                        >
                            {option.label}
                        </button>
                    ))}
                </div>
            </div>

            {/* Animals */}
            <div className="p-4 border-b border-green-500/30">
                <h3 className="text-sm font-bold text-green-300 mb-3">Animals</h3>
                <div className="grid grid-cols-2 gap-2">
                    {ANIMAL_OPTIONS.map((option) => (
                        <button
                            key={option.value}
                            onClick={() => handleToggleAnimal(option.value)}
                            className={`p-2 rounded-lg border-2 transition-all text-xs font-medium ${selectedAnimals.includes(option.value)
                                ? 'border-blue-400 bg-blue-900/50 text-white'
                                : 'border-gray-600 bg-gray-800 text-gray-300 hover:border-gray-500'
                                }`}
                        >
                            {option.label}
                        </button>
                    ))}
                </div>
            </div>

            {/* Apply Button */}
            <div className="p-4">
                <button
                    onClick={handleApplyResources}
                    className="w-full py-3 px-4 bg-green-600 hover:bg-green-700 text-white rounded-lg font-semibold transition-all flex items-center justify-center gap-2"
                >
                    <Save className="w-4 h-4" />
                    Apply Resources
                </button>
                <p className="text-xs text-gray-400 mt-2 text-center">
                    Biome unchanged. Resources only.
                </p>
            </div>
        </div>
    );
}
