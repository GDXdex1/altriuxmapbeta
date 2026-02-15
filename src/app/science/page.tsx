'use client';

import { TechTree } from '@/components/science/TechTree';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';

export default function SciencePage(): JSX.Element {
  // TODO: Get actual wallet from Sui wallet connection
  const wallet = null; // Replace with actual wallet when Sui integration is done

  return (
    <main className="w-full h-screen relative">
      {/* Back Button */}
      <Link 
        href="/"
        className="absolute top-4 left-4 z-50 bg-white/90 hover:bg-white px-4 py-2 rounded-lg shadow-lg flex items-center gap-2 font-semibold transition-colors"
      >
        <ArrowLeft className="w-4 h-4" />
        <span className="hidden sm:inline">Home</span>
      </Link>
      
      <TechTree wallet={wallet} />
    </main>
  );
}
