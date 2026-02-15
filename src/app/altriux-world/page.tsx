'use client';

import { HexMap } from '@/components/hexmap/HexMap';
import Link from 'next/link';
import { Home } from 'lucide-react';
import { useServiceWorker } from '@/hooks/useServiceWorker';

export default function AltriuxWorldPage(): JSX.Element {
  // Enable offline functionality
  useServiceWorker();
  return (
    <main className="w-full h-screen relative">
      {/* Floating Home Button - Small and Unobtrusive */}
      <Link 
        href="/"
        className="absolute top-2 left-2 z-30 bg-white/70 hover:bg-white/90 p-2 rounded-full shadow-lg transition-all hover:scale-110"
        title="Back to Home"
      >
        <Home className="w-4 h-4 md:w-5 md:h-5 text-gray-800" />
      </Link>
      
      <HexMap />
    </main>
  );
}
