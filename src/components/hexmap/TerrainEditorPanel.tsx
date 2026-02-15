'use client';

import React, { useState } from 'react';
import type { HexTile, TerrainType, TerrainFeature } from '@/lib/hexmap/types';
import { X, Download, Upload, Trash2, Save, Edit3, Lock, Unlock, Database } from 'lucide-react';
import { exportModifications, importModifications, clearAllModifications, getModificationCount } from '@/lib/hexmap/terrain-storage';
import { isMapLocked, toggleMapLock, lockMap, saveMapSeed } from '@/lib/hexmap/map-lock';
import { downloadTileRegistry } from '@/lib/hexmap/tile-registry';

interface TerrainEditorPanelProps {
  selectedTiles: HexTile[];
  isEditing: boolean;
  onClose: () => void;
  onTerrainChange: (q: number, r: number, terrain: TerrainType, features: TerrainFeature[]) => void;
  onToggleEditMode: () => void;
  allTiles?: Map<string, HexTile>; // For complete export
}

const TERRAIN_OPTIONS: { value: TerrainType; label: string; color: string }[] = [
  { value: 'ocean', label: 'Ocean', color: '#1e40af' },
  { value: 'coast', label: 'Coast', color: '#3b82f6' },
  { value: 'ice', label: 'Ice', color: '#e0f2fe' },
  { value: 'tundra', label: 'Tundra', color: '#cbd5e1' },
  { value: 'mountain', label: 'Mountain', color: '#64748b' },
  { value: 'hills', label: 'Hills', color: '#78716c' },
  { value: 'plains', label: 'Plains', color: '#84cc16' },
  { value: 'meadow', label: 'Meadow', color: '#86efac' },
  { value: 'desert', label: 'Desert', color: '#fbbf24' },
];

const FEATURE_OPTIONS: { value: TerrainFeature; label: string; color: string }[] = [
  { value: 'none', label: 'None', color: '#94a3b8' },
  { value: 'forest', label: 'Forest', color: '#166534' },
  { value: 'jungle', label: 'Jungle', color: '#14532d' },
  { value: 'swamp', label: 'Pantanal (Swamp)', color: '#064e3b' },
  { value: 'river', label: 'River', color: '#0ea5e9' },
  { value: 'oasis', label: 'Oasis', color: '#0d9488' },
  { value: 'volcano', label: 'Volcano', color: '#991b1b' },
  { value: 'mountain', label: 'Isolated Peak', color: '#475569' },
];

export function TerrainEditorPanel({
  selectedTiles,
  isEditing,
  onClose,
  onTerrainChange,
  onToggleEditMode,
  allTiles
}: TerrainEditorPanelProps): JSX.Element {
  const [selectedTerrain, setSelectedTerrain] = useState<TerrainType>('plains');
  const [selectedFeatures, setSelectedFeatures] = useState<TerrainFeature[]>([]);
  const [showExportDialog, setShowExportDialog] = useState<boolean>(false);
  const [showImportDialog, setShowImportDialog] = useState<boolean>(false);
  const [importText, setImportText] = useState<string>('');
  const [mapLocked, setMapLocked] = useState<boolean>(isMapLocked());
  const modificationCount = getModificationCount();

  const handleApplyTerrain = (): void => {
    if (selectedTiles.length === 0) return;

    // Apply terrain to all selected tiles
    for (const tile of selectedTiles) {
      onTerrainChange(
        tile.coordinates.q,
        tile.coordinates.r,
        selectedTerrain,
        selectedFeatures
      );
    }
  };

  const handleExport = (): void => {
    const jsonData = exportModifications();
    const blob = new Blob([jsonData], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `altriux-terrain-${Date.now()}.json`;
    a.click();
    URL.revokeObjectURL(url);
    setShowExportDialog(false);
  };

  const handleImport = (): void => {
    const success = importModifications(importText);
    if (success) {
      alert('Terrain modifications imported successfully! Refresh the page to see changes.');
      setShowImportDialog(false);
      setImportText('');
    } else {
      alert('Failed to import: Invalid JSON format');
    }
  };

  const handleClearAll = (): void => {
    if (confirm('Are you sure you want to clear all terrain modifications? This cannot be undone.')) {
      clearAllModifications();
      alert('All modifications cleared. Refresh the page to see original terrain.');
    }
  };

  const handleToggleFeature = (feature: TerrainFeature): void => {
    if (feature === 'none') {
      setSelectedFeatures([]);
    } else {
      if (selectedFeatures.includes(feature)) {
        setSelectedFeatures(selectedFeatures.filter(f => f !== feature));
      } else {
        setSelectedFeatures([...selectedFeatures.filter(f => f !== 'none'), feature]);
      }
    }
  };

  const handleToggleMapLock = (): void => {
    const newState = toggleMapLock();
    setMapLocked(newState);
    if (newState) {
      // When locking, save current seed
      saveMapSeed(42); // Use actual seed from generator if available
      alert('Map locked! Auto-generation disabled. Manual edits only.');
    } else {
      alert('Map unlocked. Auto-generation enabled.');
    }
  };

  const handleExportCompleteMap = (): void => {
    if (!allTiles) {
      alert('Complete map data not available');
      return;
    }
    downloadTileRegistry(allTiles);
    alert('Complete map registry exported!');
  };

  return (
    <div className="fixed top-20 right-20 bg-gray-900 border-2 border-amber-500 rounded-lg shadow-2xl z-50 w-96 max-h-[calc(100vh-120px)] overflow-y-auto">
      {/* Header */}
      <div className="flex items-center justify-between p-4 border-b border-amber-500/30 bg-gradient-to-r from-amber-900/50 to-gray-900">
        <div className="flex items-center gap-2">
          <Edit3 className="w-5 h-5 text-amber-400" />
          <h2 className="text-lg font-bold text-amber-400">Terrain Editor</h2>
        </div>
        <button
          onClick={onClose}
          className="text-amber-400 hover:text-amber-300 transition-colors"
        >
          <X className="w-5 h-5" />
        </button>
      </div>

      {/* Edit Mode Toggle */}
      <div className="p-4 border-b border-amber-500/30">
        <button
          onClick={onToggleEditMode}
          className={`w-full py-3 px-4 rounded-lg font-semibold transition-all ${isEditing
            ? 'bg-green-600 hover:bg-green-700 text-white'
            : 'bg-amber-600 hover:bg-amber-700 text-white'
            }`}
        >
          {isEditing ? '✓ Edit Mode Active' : 'Activate Edit Mode'}
        </button>
        <p className="text-xs text-gray-400 mt-2 text-center">
          {isEditing ? 'Click & drag to select area. Hold Ctrl to add/remove tiles.' : 'Enable to start editing'}
        </p>
      </div>

      {/* Selected Tiles Info */}
      {selectedTiles.length > 0 && (
        <div className="p-4 border-b border-amber-500/30 bg-gray-800/50">
          <h3 className="text-sm font-bold text-amber-300 mb-2">
            Selected Hexes ({selectedTiles.length})
          </h3>
          {selectedTiles.length === 1 ? (
            <div className="grid grid-cols-2 gap-2 text-xs">
              <div>
                <span className="text-gray-400">Q:</span>
                <span className="text-white ml-1">{selectedTiles[0].coordinates.q}</span>
              </div>
              <div>
                <span className="text-gray-400">R:</span>
                <span className="text-white ml-1">{selectedTiles[0].coordinates.r}</span>
              </div>
              <div className="col-span-2">
                <span className="text-gray-400">Current:</span>
                <span className="text-white ml-1 capitalize">{selectedTiles[0].terrain}</span>
                {selectedTiles[0].features && selectedTiles[0].features.length > 0 && (
                  <span className="text-green-400 ml-1">
                    + {selectedTiles[0].features.join(', ')}
                  </span>
                )}
              </div>
            </div>
          ) : (
            <div className="text-xs text-gray-300">
              <p className="mb-1">Multiple hexes selected.</p>
              <p className="text-amber-300">Hold Ctrl and click to select/deselect tiles.</p>
            </div>
          )}
        </div>
      )}

      {/* Terrain Selection */}
      <div className="p-4 border-b border-amber-500/30">
        <div className="flex items-center gap-2 mb-3">
          <div className="w-2 h-4 bg-amber-500 rounded-full" />
          <h3 className="text-sm font-bold text-amber-300">Section 1: Base Biome</h3>
        </div>
        <p className="text-[10px] text-gray-400 mb-3 italic">Changes the fundamental terrain of the hex.</p>
        <div className="grid grid-cols-2 gap-2">
          {TERRAIN_OPTIONS.map((option) => (
            <button
              key={option.value}
              onClick={() => setSelectedTerrain(option.value)}
              className={`p-2 rounded-lg border-2 transition-all text-xs font-medium ${selectedTerrain === option.value
                ? 'border-amber-400 bg-amber-900/50 text-white'
                : 'border-gray-600 bg-gray-800 text-gray-300 hover:border-gray-500'
                }`}
              style={{
                boxShadow: selectedTerrain === option.value ? `0 0 10px ${option.color}50` : 'none'
              }}
            >
              <div
                className="w-full h-2 rounded mb-1"
                style={{ backgroundColor: option.color }}
              />
              {option.label}
            </button>
          ))}
        </div>
      </div>

      {/* Feature Selection */}
      <div className="p-4 border-b border-amber-500/30">
        <div className="flex items-center gap-2 mb-3">
          <div className="w-2 h-4 bg-green-500 rounded-full" />
          <h3 className="text-sm font-bold text-green-300">Section 2: Terrain Features</h3>
        </div>
        <p className="text-[10px] text-gray-400 mb-3 italic">Add vegetation, rivers, or landmarks WITHOUT changing biome.</p>
        <div className="grid grid-cols-2 gap-2">
          {FEATURE_OPTIONS.map((option) => (
            <button
              key={option.value}
              onClick={() => handleToggleFeature(option.value)}
              className={`p-2 rounded-lg border-2 transition-all text-xs font-medium ${(option.value === 'none' && selectedFeatures.length === 0) ||
                selectedFeatures.includes(option.value)
                ? 'border-green-400 bg-green-900/50 text-white'
                : 'border-gray-600 bg-gray-800 text-gray-300 hover:border-gray-500'
                }`}
            >
              <div
                className="w-full h-2 rounded mb-1"
                style={{ backgroundColor: option.color }}
              />
              {option.label}
            </button>
          ))}
        </div>
      </div>

      {/* Apply Button */}
      {selectedTiles.length > 0 && isEditing && (
        <div className="p-4 border-b border-amber-500/30">
          <button
            onClick={handleApplyTerrain}
            className="w-full py-3 px-4 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-semibold transition-all flex items-center justify-center gap-2"
          >
            <Save className="w-4 h-4" />
            Apply to {selectedTiles.length} Hex{selectedTiles.length > 1 ? 'es' : ''}
          </button>
        </div>
      )}

      {/* Modification Stats */}
      <div className="p-4 border-b border-amber-500/30 bg-gray-800/50">
        <p className="text-xs text-gray-400 text-center">
          <span className="text-amber-400 font-bold">{modificationCount}</span> tiles modified
        </p>
      </div>

      {/* Map Lock */}
      <div className="p-4 border-b border-amber-500/30 bg-gray-800/50">
        <button
          onClick={handleToggleMapLock}
          className={`w-full py-3 px-4 rounded-lg font-semibold transition-all flex items-center justify-center gap-2 ${mapLocked
            ? 'bg-red-600 hover:bg-red-700 text-white'
            : 'bg-gray-600 hover:bg-gray-700 text-white'
            }`}
        >
          {mapLocked ? <Lock className="w-4 h-4" /> : <Unlock className="w-4 h-4" />}
          {mapLocked ? 'Map Locked' : 'Map Unlocked'}
        </button>
        <p className="text-xs text-gray-400 mt-2 text-center">
          {mapLocked ? '🔒 Auto-generation disabled' : '🔓 Auto-generation enabled'}
        </p>
      </div>

      {/* Tools */}
      <div className="p-4 space-y-2">
        <button
          onClick={() => setShowExportDialog(true)}
          className="w-full py-2 px-4 bg-purple-600 hover:bg-purple-700 text-white rounded-lg text-sm font-medium transition-all flex items-center justify-center gap-2"
        >
          <Download className="w-4 h-4" />
          Export Changes
        </button>
        <button
          onClick={handleExportCompleteMap}
          className="w-full py-2 px-4 bg-cyan-600 hover:bg-cyan-700 text-white rounded-lg text-sm font-medium transition-all flex items-center justify-center gap-2"
        >
          <Database className="w-4 h-4" />
          Export Complete Map
        </button>
        <button
          onClick={() => setShowImportDialog(true)}
          className="w-full py-2 px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm font-medium transition-all flex items-center justify-center gap-2"
        >
          <Upload className="w-4 h-4" />
          Import Changes
        </button>
        <button
          onClick={handleClearAll}
          className="w-full py-2 px-4 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm font-medium transition-all flex items-center justify-center gap-2"
        >
          <Trash2 className="w-4 h-4" />
          Clear All Changes
        </button>
      </div>

      {/* Export Dialog */}
      {showExportDialog && (
        <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-[100]">
          <div className="bg-gray-900 border-2 border-amber-500 rounded-lg p-6 max-w-md">
            <h3 className="text-lg font-bold text-amber-400 mb-4">Export Terrain Changes</h3>
            <p className="text-sm text-gray-300 mb-4">
              Download your terrain modifications as a JSON file. You can import this file later to restore your changes.
            </p>
            <div className="flex gap-2">
              <button
                onClick={handleExport}
                className="flex-1 py-2 px-4 bg-purple-600 hover:bg-purple-700 text-white rounded-lg font-medium"
              >
                Download
              </button>
              <button
                onClick={() => setShowExportDialog(false)}
                className="flex-1 py-2 px-4 bg-gray-700 hover:bg-gray-600 text-white rounded-lg font-medium"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Import Dialog */}
      {showImportDialog && (
        <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-[100]">
          <div className="bg-gray-900 border-2 border-amber-500 rounded-lg p-6 max-w-md">
            <h3 className="text-lg font-bold text-amber-400 mb-4">Import Terrain Changes</h3>
            <p className="text-sm text-gray-300 mb-4">
              Paste the JSON content from an exported terrain file:
            </p>
            <textarea
              value={importText}
              onChange={(e) => setImportText(e.target.value)}
              className="w-full h-40 p-2 bg-gray-800 border border-gray-600 rounded text-white text-xs font-mono"
              placeholder='[{"q":0,"r":0,"terrain":"desert",...}]'
            />
            <div className="flex gap-2 mt-4">
              <button
                onClick={handleImport}
                className="flex-1 py-2 px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium"
              >
                Import
              </button>
              <button
                onClick={() => {
                  setShowImportDialog(false);
                  setImportText('');
                }}
                className="flex-1 py-2 px-4 bg-gray-700 hover:bg-gray-600 text-white rounded-lg font-medium"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
