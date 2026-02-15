import { useState } from 'react';
import { CoatOfArmsEditor } from '@/components/CoatOfArmsEditor';
import type { CoatOfArms } from '@/types/heraldry';
import { DEFAULT_COAT_OF_ARMS } from '@/types/heraldry';
import { Toaster } from '@/components/ui/sonner';
import { Shield, Info, History, Sword, Flame, Trophy, Coins } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { ScrollArea } from '@/components/ui/scroll-area';
import './App.css';

function App() {
  const [savedCoats, setSavedCoats] = useState<CoatOfArms[]>([]);
  const [showGallery, setShowGallery] = useState(false);

  const handleSaveCoat = (coatOfArms: CoatOfArms) => {
    setSavedCoats((prev) => [...prev, coatOfArms]);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-black via-gray-900 to-black">
      {/* Animated background */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-orange-500/10 rounded-full blur-3xl animate-pulse" />
        <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-orange-600/10 rounded-full blur-3xl animate-pulse delay-1000" />
      </div>

      {/* Header */}
      <header className="relative bg-black/80 backdrop-blur-md border-b border-orange-500/30 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="relative">
              <div className="w-12 h-12 bg-gradient-to-br from-orange-500 to-orange-700 rounded-lg flex items-center justify-center shadow-lg shadow-orange-500/30 overflow-hidden">
                <img src="/logo.png" alt="Altriux Tribal" className="w-10 h-10 object-contain" />
              </div>
              <div className="absolute -top-1 -right-1 w-4 h-4 bg-orange-400 rounded-full animate-pulse" />
            </div>
            <div>
              <h1 className="text-2xl font-black text-white tracking-wider">
                <span className="text-orange-500">ALTRIUX</span> TRIBAL
              </h1>
              <p className="text-xs text-orange-400/70 uppercase tracking-widest">Heraldic Shield Creator</p>
            </div>
          </div>
          
          <div className="flex items-center gap-3">
            <Dialog>
              <DialogTrigger asChild>
                <Button 
                  variant="ghost" 
                  size="icon" 
                  className="text-orange-400 hover:text-orange-300 hover:bg-orange-500/10"
                >
                  <Info className="w-5 h-5" />
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-2xl bg-gray-900 border-orange-500/30">
                <DialogHeader>
                  <DialogTitle className="text-orange-400 flex items-center gap-2">
                    <Trophy className="w-5 h-5" />
                    About Altriux Tribal
                  </DialogTitle>
                </DialogHeader>
                <ScrollArea className="h-[450px] pr-4">
                  <div className="space-y-4 text-sm text-gray-300">
                    <p>
                      <span className="text-orange-400 font-semibold">Altriux Tribal</span> is a next-generation 
                      heraldic shield creator that combines medieval tradition with modern blockchain technology. 
                      Design your unique coat of arms and register it on the blockchain for 10 AGC.
                    </p>

                    <div className="bg-orange-500/10 border border-orange-500/30 rounded-lg p-4">
                      <h4 className="text-orange-300 font-bold flex items-center gap-2 mb-2">
                        <Shield className="w-4 h-4" />
                        Your Shield in the Game
                      </h4>
                      <p className="text-gray-300">
                        Your registered shield will be <strong className="text-orange-400">visible throughout the entire game</strong>. 
                        Your warriors and followers will carry it as their banner, displaying your heraldic emblem 
                        in battles, tournaments, and conquests across the realm.
                      </p>
                      <p className="text-gray-300 mt-2">
                        You can change your shield design at any time by paying <strong className="text-orange-400">20 Altriux Gold Coins (AGC)</strong>.
                      </p>
                    </div>
                    
                    <h3 className="font-bold text-lg text-orange-400 flex items-center gap-2">
                      <Shield className="w-4 h-4" />
                      Shield Components
                    </h3>
                    <ul className="space-y-2 list-disc pl-4">
                      <li><strong className="text-orange-300">Shield/Field:</strong> The central space bearing the main arms (colors, pieces, and figures).</li>
                      <li><strong className="text-orange-300">Helm/Helmet:</strong> Positioned above the shield, indicating the knight's dignity or rank.</li>
                      <li><strong className="text-orange-300">Crest:</strong> Figure or symbol placed on the helm, often the most distinctive element.</li>
                      <li><strong className="text-orange-300">Mantling/Lambrequin:</strong> Ornament falling from the helm, representing the cloth covering the armor.</li>
                      <li><strong className="text-orange-300">Supporters:</strong> Figures (animals or persons) holding the shield on both sides.</li>
                      <li><strong className="text-orange-300">Motto:</strong> Inspirational phrase usually placed on a ribbon under the shield.</li>
                      <li><strong className="text-orange-300">Bordure:</strong> Piece surrounding the field, often used to differentiate lineages.</li>
                    </ul>

                    <h3 className="font-bold text-lg text-orange-400 flex items-center gap-2">
                      <Sword className="w-4 h-4" />
                      Shield Shapes (Fantasy Names)
                    </h3>
                    <p>
                      Choose from 12 different shield shapes with unique fantasy names: 
                      Drantium (Classic), Brontium, Draux, Druxiux, Dreix, Sultrium, 
                      Vortix, Krantor, Imlax, Shiex, Xaldrin, and Zynthor.
                    </p>

                    <h3 className="font-bold text-lg text-orange-400 flex items-center gap-2">
                      <Flame className="w-4 h-4" />
                      Charge Categories
                    </h3>
                    <p>
                      Our collection includes 150+ symbols across categories: Animals, Celestial, Nature, 
                      Buildings, Objects, Religious, Geometric, Islamic, Buddhist, Hindu, Naval, Agriculture, and Warfare.
                    </p>

                    <div className="bg-gradient-to-r from-orange-500/20 to-orange-600/20 border border-orange-500/30 rounded-lg p-4 mt-4">
                      <div className="flex items-center justify-center gap-2 mb-2">
                        <Coins className="w-5 h-5 text-orange-400" />
                        <span className="text-orange-300 font-bold">Registration Cost</span>
                      </div>
                      <p className="text-center text-white font-semibold">
                        Register your shield for 10 AGC<br/>
                        <span className="text-sm text-orange-400/70">Change anytime for 20 AGC</span>
                      </p>
                    </div>
                  </div>
                </ScrollArea>
              </DialogContent>
            </Dialog>

            <Button 
              variant="ghost" 
              size="icon" 
              className="text-orange-400 hover:text-orange-300 hover:bg-orange-500/10"
              onClick={() => setShowGallery(!showGallery)}
            >
              <History className="w-5 h-5" />
            </Button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="relative max-w-7xl mx-auto px-4 py-6">
        {showGallery && savedCoats.length > 0 && (
          <div className="mb-6 bg-gray-900/80 backdrop-blur rounded-xl p-4 border border-orange-500/30">
            <h2 className="text-lg font-semibold text-orange-400 mb-4 flex items-center gap-2">
              <Trophy className="w-5 h-5" />
              Registered Shields ({savedCoats.length})
            </h2>
            <div className="flex gap-4 overflow-x-auto pb-2">
              {savedCoats.map((_, index) => (
                <div 
                  key={index} 
                  className="flex-shrink-0 w-24 h-32 bg-gradient-to-br from-gray-800 to-gray-900 rounded-lg flex items-center justify-center cursor-pointer hover:ring-2 ring-orange-500 transition-all border border-orange-500/20"
                >
                  <span className="text-xs text-orange-400/70">Shield #{index + 1}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        <CoatOfArmsEditor 
          initialCoatOfArms={DEFAULT_COAT_OF_ARMS}
          onSave={handleSaveCoat}
        />
      </main>

      {/* Footer */}
      <footer className="relative bg-black/80 border-t border-orange-500/30 mt-8">
        <div className="max-w-7xl mx-auto px-4 py-6 text-center">
          <div className="flex items-center justify-center gap-2 mb-2">
            <img src="/logo.png" alt="Altriux" className="w-6 h-6 object-contain" />
            <span className="text-xl font-black text-white">
              <span className="text-orange-500">ALTRIUX</span> TRIBAL
            </span>
          </div>
          <p className="text-orange-400/60 text-sm">Create & Register Your Heraldic Shield on the Blockchain</p>
          <p className="text-gray-500 text-xs mt-2">150+ Symbols • 12 Shield Shapes • 10 AGC Registration</p>
        </div>
      </footer>

      <Toaster 
        position="bottom-right"
        toastOptions={{
          style: {
            background: '#1a1a1a',
            border: '1px solid rgba(249, 115, 22, 0.3)',
            color: '#fff',
          },
        }}
      />
    </div>
  );
}

export default App;
