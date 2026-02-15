// Notes for AI:
// Place any provider components here to enable them globally for the entire app.
'use client';

import { TravelProvider } from '@/contexts/TravelContext';

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <TravelProvider>
      {children}
    </TravelProvider>
  );
}
