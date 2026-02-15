'use client'
import Link from 'next/link';
import { ArrowLeft, ShoppingCart } from 'lucide-react';

export default function MarketplacePage(): JSX.Element {
  return (
    <main className="w-full min-h-screen bg-gradient-to-br from-emerald-900 via-teal-900 to-slate-900">
      <div className="px-4 pt-8 pb-6">
        <Link 
          href="/"
          className="inline-flex items-center gap-2 text-white hover:text-emerald-300 transition-colors mb-6"
        >
          <ArrowLeft className="w-5 h-5" />
          Back to Home
        </Link>
        
        <div className="max-w-2xl mx-auto text-center py-20">
          <div className="bg-emerald-600/20 w-24 h-24 rounded-full flex items-center justify-center mx-auto mb-6">
            <ShoppingCart className="w-12 h-12 text-emerald-400" />
          </div>
          
          <h1 className="text-4xl md:text-5xl font-bold text-white mb-4">
            Marketplace
          </h1>
          
          <p className="text-emerald-200 text-lg mb-8">
            Coming Soon
          </p>
          
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-6 text-left">
            <h2 className="text-xl font-semibold text-white mb-4">
              Future Features:
            </h2>
            <ul className="space-y-2 text-emerald-100">
              <li className="flex items-start gap-2">
                <span className="text-emerald-400">•</span>
                Trade resources and materials
              </li>
              <li className="flex items-start gap-2">
                <span className="text-emerald-400">•</span>
                Buy and sell territory NFTs
              </li>
              <li className="flex items-start gap-2">
                <span className="text-emerald-400">•</span>
                Auction system for rare items
              </li>
              <li className="flex items-start gap-2">
                <span className="text-emerald-400">•</span>
                Peer-to-peer trading
              </li>
            </ul>
          </div>
        </div>
      </div>
    </main>
  );
}
