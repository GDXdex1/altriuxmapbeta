'use client';

import React, { useState } from 'react';
import type { Technology, TechnologyCategory } from '@/lib/science/types';
import { TECHNOLOGIES, TRADES, RELIGIONS, canResearchTech } from '@/lib/science/tech-tree';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';

interface TechTreeProps {
  wallet: string | null;
}

const CATEGORY_NAMES: Record<TechnologyCategory, string> = {
  trades: 'Trades',
  basic_sciences: 'Basic Sciences',
  literature: 'Literature',
  geography: 'Geography',
  history: 'History',
  mathematics: 'Mathematics',
  physics: 'Physics',
  chemistry: 'Chemistry',
  religion: 'Religion',
  philosophy: 'Philosophy'
};

const CATEGORY_COLORS: Record<TechnologyCategory, string> = {
  trades: 'bg-amber-500',
  basic_sciences: 'bg-blue-500',
  literature: 'bg-purple-500',
  geography: 'bg-green-500',
  history: 'bg-red-500',
  mathematics: 'bg-cyan-500',
  physics: 'bg-indigo-500',
  chemistry: 'bg-pink-500',
  religion: 'bg-yellow-500',
  philosophy: 'bg-gray-500'
};

export function TechTree({ wallet }: TechTreeProps): JSX.Element {
  const [researchedTechs, setResearchedTechs] = useState<string[]>([]);
  const [currentResearch, setCurrentResearch] = useState<string | null>(null);
  const [researchProgress, setResearchProgress] = useState<number>(0);
  const [knowledgePoints, setKnowledgePoints] = useState<number>(1000);
  const [selectedTech, setSelectedTech] = useState<Technology | null>(null);
  const [selectedCategory, setSelectedCategory] = useState<TechnologyCategory>('trades');

  const handleResearch = (tech: Technology): void => {
    if (!canResearchTech(tech, researchedTechs)) {
      alert('Prerequisites not met!');
      return;
    }

    if (knowledgePoints >= tech.researchCost) {
      setKnowledgePoints(prev => prev - tech.researchCost);
      setResearchedTechs(prev => [...prev, tech.id]);
      setCurrentResearch(null);
      setResearchProgress(0);
      alert(`${tech.name} researched!`);
    } else {
      alert(`Need ${tech.researchCost} knowledge points. You have ${knowledgePoints}.`);
    }
  };

  const getTechStatus = (tech: Technology): 'researched' | 'available' | 'locked' => {
    if (researchedTechs.includes(tech.id)) return 'researched';
    if (canResearchTech(tech, researchedTechs)) return 'available';
    return 'locked';
  };

  const filteredTechs = TECHNOLOGIES.filter(tech => tech.category === selectedCategory);

  return (
    <div className="w-full h-full bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900 text-white">
      <div className="container mx-auto px-4 py-6 max-w-7xl h-full flex flex-col">
        {/* Header */}
        <div className="mb-6">
          <h1 className="text-3xl md:text-4xl font-bold mb-2 bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
            Science & Technology
          </h1>
          <div className="flex flex-wrap gap-4 items-center">
            <div className="bg-white/10 px-4 py-2 rounded-lg backdrop-blur-sm">
              <p className="text-sm text-gray-300">Knowledge Points</p>
              <p className="text-2xl font-bold text-yellow-400">{knowledgePoints}</p>
            </div>
            <div className="bg-white/10 px-4 py-2 rounded-lg backdrop-blur-sm">
              <p className="text-sm text-gray-300">Technologies</p>
              <p className="text-2xl font-bold text-green-400">{researchedTechs.length}/{TECHNOLOGIES.length}</p>
            </div>
            {wallet && (
              <div className="bg-white/10 px-4 py-2 rounded-lg backdrop-blur-sm flex-1 min-w-[200px]">
                <p className="text-sm text-gray-300">Wallet</p>
                <p className="text-xs font-mono text-blue-300 truncate">{wallet}</p>
              </div>
            )}
          </div>
        </div>

        {/* Category Tabs */}
        <Tabs value={selectedCategory} onValueChange={(v) => setSelectedCategory(v as TechnologyCategory)} className="flex-1 flex flex-col overflow-hidden">
          <TabsList className="bg-white/10 mb-4 flex-wrap h-auto">
            {(Object.keys(CATEGORY_NAMES) as TechnologyCategory[]).map(category => (
              <TabsTrigger 
                key={category} 
                value={category}
                className="data-[state=active]:bg-white/20 text-xs sm:text-sm"
              >
                {CATEGORY_NAMES[category]}
              </TabsTrigger>
            ))}
          </TabsList>

          <TabsContent value={selectedCategory} className="flex-1 overflow-hidden">
            <ScrollArea className="h-full">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 pb-4">
                {filteredTechs.map(tech => {
                  const status = getTechStatus(tech);
                  return (
                    <Card 
                      key={tech.id}
                      className={`p-4 cursor-pointer transition-all ${
                        status === 'researched' 
                          ? 'bg-green-900/30 border-green-500' 
                          : status === 'available'
                          ? 'bg-blue-900/30 border-blue-500 hover:bg-blue-900/50'
                          : 'bg-gray-900/30 border-gray-600 opacity-60'
                      }`}
                      onClick={() => setSelectedTech(tech)}
                    >
                      <div className="flex items-start gap-3">
                        <div className="text-4xl">{tech.icon}</div>
                        <div className="flex-1">
                          <h3 className="font-bold text-lg mb-1">{tech.name}</h3>
                          <p className="text-sm text-gray-300 mb-2 line-clamp-2">{tech.description}</p>
                          
                          <div className="flex flex-wrap gap-2 mb-2">
                            <Badge className={`${CATEGORY_COLORS[tech.category]} text-white text-xs`}>
                              {CATEGORY_NAMES[tech.category]}
                            </Badge>
                            {tech.religion && (
                              <Badge className="bg-yellow-600 text-white text-xs">
                                Religion
                              </Badge>
                            )}
                          </div>

                          <div className="flex items-center justify-between">
                            <span className="text-sm font-semibold text-yellow-400">
                              {tech.researchCost} 🧠
                            </span>
                            {status === 'available' && (
                              <Button 
                                size="sm"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleResearch(tech);
                                }}
                                className="bg-blue-600 hover:bg-blue-700"
                              >
                                Research
                              </Button>
                            )}
                            {status === 'researched' && (
                              <Badge className="bg-green-600">✓ Done</Badge>
                            )}
                            {status === 'locked' && (
                              <Badge className="bg-gray-600">🔒 Locked</Badge>
                            )}
                          </div>

                          {tech.requiredTech.length > 0 && (
                            <div className="mt-2 text-xs text-gray-400">
                              <span>Requires: {tech.requiredTech.map(id => {
                                const reqTech = TECHNOLOGIES.find(t => t.id === id);
                                return reqTech?.name;
                              }).join(', ')}</span>
                            </div>
                          )}
                        </div>
                      </div>
                    </Card>
                  );
                })}
              </div>
            </ScrollArea>
          </TabsContent>
        </Tabs>

        {/* Selected Tech Detail Modal */}
        {selectedTech && (
          <div 
            className="fixed inset-0 bg-black/70 flex items-center justify-center p-4 z-50"
            onClick={() => setSelectedTech(null)}
          >
            <Card 
              className="bg-slate-800 border-blue-500 max-w-2xl w-full p-6"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="flex items-start gap-4 mb-4">
                <div className="text-6xl">{selectedTech.icon}</div>
                <div className="flex-1">
                  <h2 className="text-3xl font-bold mb-2">{selectedTech.name}</h2>
                  <Badge className={`${CATEGORY_COLORS[selectedTech.category]} text-white`}>
                    {CATEGORY_NAMES[selectedTech.category]}
                  </Badge>
                </div>
                <Button 
                  variant="ghost" 
                  onClick={() => setSelectedTech(null)}
                  className="text-white"
                >
                  ✕
                </Button>
              </div>

              <p className="text-gray-300 mb-4">{selectedTech.description}</p>

              <div className="space-y-3">
                <div>
                  <p className="font-semibold text-yellow-400">Research Cost: {selectedTech.researchCost} 🧠</p>
                </div>

                {selectedTech.requiredTech.length > 0 && (
                  <div>
                    <p className="font-semibold mb-1">Prerequisites:</p>
                    <div className="flex flex-wrap gap-2">
                      {selectedTech.requiredTech.map(id => {
                        const tech = TECHNOLOGIES.find(t => t.id === id);
                        const isResearched = researchedTechs.includes(id);
                        return (
                          <Badge 
                            key={id} 
                            className={isResearched ? 'bg-green-600' : 'bg-red-600'}
                          >
                            {isResearched ? '✓' : '✗'} {tech?.name}
                          </Badge>
                        );
                      })}
                    </div>
                  </div>
                )}

                {selectedTech.leadsTo.length > 0 && (
                  <div>
                    <p className="font-semibold mb-1">Unlocks Research:</p>
                    <div className="flex flex-wrap gap-2">
                      {selectedTech.leadsTo.map(id => {
                        const tech = TECHNOLOGIES.find(t => t.id === id);
                        return (
                          <Badge key={id} className="bg-blue-600">
                            {tech?.icon} {tech?.name}
                          </Badge>
                        );
                      })}
                    </div>
                  </div>
                )}

                {selectedTech.unlocks && selectedTech.unlocks.length > 0 && (
                  <div>
                    <p className="font-semibold mb-1">Unlocks:</p>
                    <ul className="list-disc list-inside text-green-400">
                      {selectedTech.unlocks.map((unlock, i) => (
                        <li key={i}>{unlock}</li>
                      ))}
                    </ul>
                  </div>
                )}

                {selectedTech.religion && (
                  <div>
                    <p className="font-semibold mb-1">Religion Details:</p>
                    {RELIGIONS.find(r => r.id === selectedTech.religion) && (
                      <div className="bg-yellow-900/20 p-3 rounded">
                        <p className="text-sm text-gray-300 mb-2">
                          {RELIGIONS.find(r => r.id === selectedTech.religion)?.description}
                        </p>
                        <p className="text-xs font-semibold text-yellow-300 mb-1">Bonuses:</p>
                        <ul className="text-xs text-green-400 space-y-1">
                          {RELIGIONS.find(r => r.id === selectedTech.religion)?.bonuses.map((b, i) => (
                            <li key={i}>• {b}</li>
                          ))}
                        </ul>
                      </div>
                    )}
                  </div>
                )}
              </div>

              <div className="mt-6 flex gap-3">
                {getTechStatus(selectedTech) === 'available' && (
                  <Button 
                    onClick={() => {
                      handleResearch(selectedTech);
                      setSelectedTech(null);
                    }}
                    className="bg-blue-600 hover:bg-blue-700 flex-1"
                  >
                    Research for {selectedTech.researchCost} 🧠
                  </Button>
                )}
                <Button 
                  variant="outline" 
                  onClick={() => setSelectedTech(null)}
                  className="flex-1"
                >
                  Close
                </Button>
              </div>
            </Card>
          </div>
        )}
      </div>
    </div>
  );
}
