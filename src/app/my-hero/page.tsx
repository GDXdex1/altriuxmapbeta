'use client';

import { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { Home, User, Award, History, Edit2, Save, Package, Shield, Crown, GraduationCap, Hammer, Ship, ChevronRight } from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Progress } from '@/components/ui/progress';
import { motion, AnimatePresence } from 'framer-motion';

// --- Types ---
interface InventoryItem {
  id: string;
  name: string;
  type: 'resource' | 'technology' | 'territory';
  quantity: number;
  icon: string;
  rarity: 'common' | 'rare' | 'epic' | 'legendary';
}

interface Title {
  id: string;
  name: string;
  description: string;
  nftId: string;
  icon: string;
  acquired: Date;
  category: 'noble' | 'academic' | 'trade';
}

interface HistoryEvent {
  id: string;
  date: Date;
  type: 'territory' | 'technology' | 'trade' | 'battle' | 'title';
  description: string;
  icon: string;
}

// --- Mock Data ---
const mockInventory: InventoryItem[] = [
    { id: '1', name: 'Gold', type: 'resource', quantity: 1250, icon: '⚜️', rarity: 'legendary' },
    { id: '2', name: 'Iron', type: 'resource', quantity: 3400, icon: '⚙️', rarity: 'common' },
    { id: '3', name: 'Wood', type: 'resource', quantity: 5600, icon: '🪵', rarity: 'common' },
    { id: '4', name: 'Wheat', type: 'resource', quantity: 2100, icon: '🌾', rarity: 'common' },
    { id: '5', name: 'Spices', type: 'resource', quantity: 890, icon: '🌶️', rarity: 'rare' },
    { id: '7', name: 'Blacksmith Tech', type: 'technology', quantity: 1, icon: '🔨', rarity: 'epic' },
];

const mockTitles: Title[] = [
    { id: 't1', name: 'Desert Wanderer', description: 'Claimed 10 desert territories', nftId: 'NFT-TITLE-0001', icon: '🏜️', acquired: new Date('2025-12-15'), category: 'noble' },
    { id: 't2', name: 'Master Blacksmith', description: 'Unlocked advanced metallurgy', nftId: 'NFT-TITLE-0042', icon: '🔨', acquired: new Date('2025-12-20'), category: 'trade' },
];

const mockHistory: HistoryEvent[] = [
    { id: 'h1', date: new Date('2026-01-10'), type: 'territory', description: 'Claimed 3 plains territories', icon: '🌾' },
    { id: 'h2', date: new Date('2026-01-08'), type: 'technology', description: 'Researched Carpentry', icon: '🪚' },
    { id: 'h3', date: new Date('2026-01-05'), type: 'title', description: 'Earned title: Resource Baron', icon: '🏆' },
];

const rarityColors: Record<string, string> = {
    common: 'bg-slate-500',
    rare: 'bg-blue-500',
    epic: 'bg-purple-500',
    legendary: 'bg-amber-500' // Changed to amber for better fit
};

export default function MyHeroPage(): JSX.Element {
  const [isEditingDescription, setIsEditingDescription] = useState<boolean>(false);
  const [userDescription, setUserDescription] = useState<string>(
    'Ambitious explorer of the Altriux World. Building my empire one hex at a time.'
  );
  const [tempDescription, setTempDescription] = useState<string>(userDescription);
  
  // Shield State
  const [shieldImage, setShieldImage] = useState<string | null>(null);
  const [isBuilderOpen, setIsBuilderOpen] = useState<boolean>(false);
  const iframeRef = useRef<HTMLIFrameElement>(null);

  // Load shield from local storage on mount
  useEffect(() => {
      const savedShield = localStorage.getItem('heraldic_shield');
      if (savedShield) {
          setShieldImage(savedShield);
      }
  }, []);

  // Listen for messages from the Shield Builder (iframe)
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      // Security check: typically you verify origin here, but for local/public serving we'll be permissive or check specifics
      // console.log("Received message:", event.data);

      if (event.data && event.data.type === 'shieldCreated' && event.data.image) {
        setShieldImage(event.data.image);
        localStorage.setItem('heraldic_shield', event.data.image);
        setIsBuilderOpen(false); // Close builder on success
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);


  const handleSaveDescription = () => {
    setUserDescription(tempDescription);
    setIsEditingDescription(false);
  };

  return (
    <main className="min-h-screen bg-gradient-to-br from-black via-zinc-900 to-orange-950 p-4 md:p-8 text-orange-50 font-sans">
      
      {/* Header */}
      <motion.div 
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="max-w-7xl mx-auto mb-8 flex items-center justify-between"
      >
          <Link href="/">
            <Button variant="ghost" className="text-orange-400 hover:text-orange-200 hover:bg-orange-900/20 gap-2">
              <Home className="w-5 h-5" />
              <span>Sanctuary</span>
            </Button>
          </Link>
          <h1 className="text-4xl md:text-5xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-orange-400 to-amber-200 tracking-tight">
            MY HERO
          </h1>
          <div className="w-32" /> 
      </motion.div>

      <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-12 gap-8">
        
        {/* Left Column: Hero Profile & Shield */}
        <motion.div 
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.2 }}
            className="lg:col-span-4 space-y-6"
        >
            {/* Hero Card */}
            <Card className="bg-black/40 backdrop-blur-xl border-orange-500/20 p-6 shadow-[0_0_30px_rgba(249,115,22,0.1)] overflow-hidden relative group">
                <div className="absolute inset-0 bg-gradient-to-b from-orange-500/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none" />
                
                <div className="flex flex-col items-center text-center">
                    <div className="relative mb-6">
                        <div className="w-32 h-32 rounded-full border-4 border-orange-500/30 p-1 bg-black">
                            <div className="w-full h-full rounded-full bg-gradient-to-br from-orange-600 to-red-700 flex items-center justify-center overflow-hidden">
                                <User className="w-16 h-16 text-orange-100" />
                            </div>
                        </div>
                        <Badge className="absolute -bottom-3 left-1/2 -translate-x-1/2 bg-orange-600 hover:bg-orange-500 text-white border-0 px-3 py-1 text-sm font-bold shadow-lg">
                            Level 12
                        </Badge>
                    </div>

                    <h2 className="text-2xl font-bold text-orange-50 mb-1">Anonymous Hero</h2>
                    <p className="text-orange-300/60 text-sm font-mono mb-6">Wallet: 0x742d...8f3c</p>

                    {/* Stats Grid */}
                    <div className="grid grid-cols-3 gap-3 w-full mb-6">
                        <div className="p-3 rounded-lg bg-orange-500/10 border border-orange-500/10 flex flex-col items-center">
                            <span className="text-2xl">🏰</span>
                            <span className="text-xs text-orange-300 mt-1">24 Lands</span>
                        </div>
                        <div className="p-3 rounded-lg bg-orange-500/10 border border-orange-500/10 flex flex-col items-center">
                            <span className="text-2xl">⚔️</span>
                            <span className="text-xs text-orange-300 mt-1">15 Power</span>
                        </div>
                        <div className="p-3 rounded-lg bg-orange-500/10 border border-orange-500/10 flex flex-col items-center">
                            <span className="text-2xl">📜</span>
                            <span className="text-xs text-orange-300 mt-1">2 Titles</span>
                        </div>
                    </div>

                    {/* Description */}
                    <div className="w-full bg-black/40 rounded-xl p-4 border border-orange-500/10 text-left">
                         <div className="flex items-center justify-between mb-2">
                            <h3 className="text-orange-400 text-xs font-bold uppercase tracking-wider">Bio</h3>
                            {!isEditingDescription ? (
                                <Button variant="ghost" size="icon" onClick={() => setIsEditingDescription(true)} className="h-6 w-6 text-orange-400/50 hover:text-orange-400">
                                    <Edit2 className="w-3 h-3" />
                                </Button>
                            ) : (
                                <div className="flex gap-1">
                                    <Button variant="ghost" size="icon" onClick={() => { setIsEditingDescription(false); setTempDescription(userDescription); }} className="h-6 w-6 text-red-400 hover:text-red-300">
                                        <span className="text-xs">✕</span>
                                    </Button>
                                    <Button variant="ghost" size="icon" onClick={handleSaveDescription} className="h-6 w-6 text-green-400 hover:text-green-300">
                                        <Save className="w-3 h-3" />
                                    </Button>
                                </div>
                            )}
                        </div>
                        {isEditingDescription ? (
                            <Textarea 
                                value={tempDescription} 
                                onChange={(e) => setTempDescription(e.target.value)}
                                className="bg-orange-950/30 border-orange-500/30 text-orange-100 text-sm focus:ring-orange-500" 
                            />
                        ) : (
                            <p className="text-orange-200/80 text-sm leading-relaxed italic">"{userDescription}"</p>
                        )}
                    </div>
                </div>
            </Card>

            {/* Heraldic Shield Section */}
            <Card className="bg-black/40 backdrop-blur-xl border-orange-500/20 p-6 shadow-[0_0_30px_rgba(249,115,22,0.1)]">
                <div className="flex items-center justify-between mb-4">
                    <h3 className="text-xl font-bold text-orange-100 flex items-center gap-2">
                        <Shield className="w-5 h-5 text-orange-500" />
                        Heraldry
                    </h3>
                    <Button 
                        onClick={() => setIsBuilderOpen(!isBuilderOpen)}
                        size="sm"
                        className="bg-orange-600 hover:bg-orange-500 text-white font-medium shadow-lg hover:shadow-orange-500/20 transition-all border border-orange-400/50"
                    >
                        {shieldImage ? 'Modify Shield' : 'Create Shield'}
                    </Button>
                </div>

                <AnimatePresence>
                    {isBuilderOpen && (
                         <motion.div 
                            initial={{ height: 0, opacity: 0 }}
                            animate={{ height: 'auto', opacity: 1 }}
                            exit={{ height: 0, opacity: 0 }}
                            className="mb-6 overflow-hidden border border-orange-500/30 rounded-xl bg-black"
                         >
                            <div className="p-2 bg-orange-950/20 border-b border-orange-500/20 flex justify-between items-center text-xs text-orange-400">
                                <span>Shield Forge v1.0</span>
                                <Button variant="ghost" size="sm" onClick={() => setIsBuilderOpen(false)} className="h-6 px-2 hover:bg-red-900/20 text-red-400">Close</Button>
                            </div>
                            {/* Assuming the builder is hosted at /heraldic_shield_builder/app/dist/index.html */}
                            <iframe 
                                ref={iframeRef}
                                src="/heraldic_shield_builder/app/dist/index.html" 
                                className="w-full h-[600px] border-none"
                                title="Shield Builder"
                            />
                        </motion.div>
                    )}
                </AnimatePresence>

                {shieldImage ? (
                     <div className="relative group rounded-xl overflow-hidden border border-orange-500/10 bg-gradient-to-br from-orange-900/10 to-black p-4 flex justify-center items-center">
                        <img src={shieldImage} alt="My Heraldic Shield" className="max-w-[180px] drop-shadow-2xl hover:scale-105 transition-transform duration-300" />
                        <div className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity">
                             <Badge className="bg-green-500/20 text-green-400 border-0 pointer-events-none">Active</Badge>
                        </div>
                     </div>
                ) : (
                    <div className="h-48 border-2 border-dashed border-orange-500/20 rounded-xl flex flex-col items-center justify-center text-orange-500/40 bg-orange-950/5">
                        <Shield className="w-12 h-12 mb-2 opacity-50" />
                        <span className="text-sm">No shield forged yet</span>
                    </div>
                )}
            </Card>
        </motion.div>

        {/* Right Column: Tabs (Inventory, etc.) */}
        <motion.div 
             initial={{ opacity: 0, x: 20 }}
             animate={{ opacity: 1, x: 0 }}
             transition={{ delay: 0.3 }}
             className="lg:col-span-8"
        >
            <Tabs defaultValue="inventory" className="w-full">
                <TabsList className="w-full bg-black/40 border border-orange-500/20 h-auto p-1 rounded-xl grid grid-cols-3 mb-6">
                    {/* Custom Styled Triggers */}
                    {['inventory', 'titles', 'history'].map((tab) => (
                         <TabsTrigger 
                            key={tab} 
                            value={tab}
                            className="data-[state=active]:bg-orange-600 data-[state=active]:text-white text-orange-400/70 py-3 rounded-lg transition-all duration-300 capitalize font-medium flex items-center justify-center gap-2"
                         >
                            {tab === 'inventory' && <Package className="w-4 h-4" />}
                            {tab === 'titles' && <Award className="w-4 h-4" />}
                            {tab === 'history' && <History className="w-4 h-4" />}
                            {tab}
                         </TabsTrigger>
                    ))}
                </TabsList>

                {/* --- Inventory Content --- */}
                <TabsContent value="inventory">
                    <Card className="bg-black/40 backdrop-blur-md border-orange-500/10 p-6 min-h-[500px]">
                        <div className="flex justify-between items-center mb-6">
                            <h3 className="text-xl font-bold text-orange-100">Assets & Resources</h3>
                            <Button variant="outline" size="sm" className="border-orange-500/30 text-orange-300 hover:bg-orange-950/30">
                                Filter
                            </Button>
                        </div>
                        
                        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                            {mockInventory.map((item) => (
                                <motion.div 
                                    key={item.id}
                                    whileHover={{ scale: 1.02 }}
                                    className="bg-zinc-900/50 border border-orange-500/10 rounded-xl p-4 hover:border-orange-500/40 hover:bg-zinc-900/80 transition-all cursor-pointer group"
                                >
                                    <div className="flex justify-between items-start mb-3">
                                        <div className="text-3xl bg-black rounded-lg p-2 group-hover:bg-orange-500/10 transition-colors">
                                            {item.icon}
                                        </div>
                                        <Badge className={`${rarityColors[item.rarity] || 'bg-slate-500'} text-xs font-bold border-0`}>
                                            {item.rarity}
                                        </Badge>
                                    </div>
                                    <h4 className="text-orange-50 font-bold">{item.name}</h4>
                                    <p className="text-orange-400/60 text-xs uppercase tracking-wide mb-3">{item.type}</p>
                                    <div className="flex justify-between items-end border-t border-white/5 pt-3">
                                        <span className="text-xs text-orange-300/50">Quantity</span>
                                        <span className="text-lg font-mono text-orange-200">{item.quantity.toLocaleString()}</span>
                                    </div>
                                </motion.div>
                            ))}
                        </div>
                    </Card>
                </TabsContent>

                {/* --- Titles Content --- */}
                <TabsContent value="titles">
                    <Card className="bg-black/40 backdrop-blur-md border-orange-500/10 p-6">
                        <h3 className="text-xl font-bold text-orange-100 mb-6">Earned Honors</h3>
                        <div className="space-y-4">
                            {mockTitles.map((title) => (
                                <div key={title.id} className="flex items-center gap-4 bg-zinc-900/50 p-4 rounded-xl border border-orange-500/10 hover:border-orange-500/30 transition-colors">
                                    <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-amber-600/20 to-orange-600/20 flex items-center justify-center text-2xl border border-orange-500/20">
                                        {title.icon}
                                    </div>
                                    <div className="flex-1">
                                        <h4 className="text-orange-50 font-bold">{title.name}</h4>
                                        <p className="text-orange-300/60 text-sm">{title.description}</p>
                                    </div>
                                    <Badge variant="outline" className="border-orange-500/30 text-orange-300">
                                        {title.category}
                                    </Badge>
                                </div>
                            ))}
                        </div>
                    </Card>
                </TabsContent>
                
                 {/* --- History Content --- */}
                 <TabsContent value="history">
                    <Card className="bg-black/40 backdrop-blur-md border-orange-500/10 p-6">
                         <h3 className="text-xl font-bold text-orange-100 mb-6">Chronicles</h3>
                         <div className="relative border-l-2 border-orange-500/20 ml-3 space-y-8 py-2">
                            {mockHistory.map((event) => (
                                <div key={event.id} className="relative pl-8">
                                    <div className="absolute -left-[9px] top-0 w-4 h-4 rounded-full bg-black border-2 border-orange-500/50" />
                                    <div className="bg-zinc-900/30 p-4 rounded-lg border border-white/5">
                                        <div className="flex items-center gap-2 mb-1">
                                            <span className="text-orange-500 text-xs font-mono">{event.date.toLocaleDateString()}</span>
                                            <Badge variant="secondary" className="bg-white/5 text-orange-200/70 text-[10px] hover:bg-white/10">{event.type}</Badge>
                                        </div>
                                        <p className="text-orange-100 text-sm">{event.description}</p>
                                    </div>
                                </div>
                            ))}
                         </div>
                    </Card>
                 </TabsContent>

            </Tabs>
        </motion.div>
      </div>
    </main>
  );
}
