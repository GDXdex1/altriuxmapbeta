
'use client';

import { HexMapCanvas } from '@/components/hexmap/HexMapCanvas';

export default function Home() {
  return (
    <main className="min-h-screen bg-black overflow-hidden">
      <HexMapCanvas />
    </main>
  );
}
