'use client';

import { useState, useEffect } from 'react';

interface ServerTime {
  serverTime: Date;
  loading: boolean;
  error: string | null;
}

/**
 * Hook to fetch server time from Cloudflare Time API (Venezuela timezone)
 * Security: Uses Cloudflare's public API for accurate server time
 */
export function useServerTime(): ServerTime {
  const [serverTime, setServerTime] = useState<Date>(new Date());
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchServerTime = async (): Promise<void> => {
      try {
        setLoading(true);
        
        // Fetch from Cloudflare Time API
        const response = await fetch('https://time.cloudflare.com/api/v1/time', {
          headers: {
            'Accept': 'application/json'
          }
        });

        if (!response.ok) {
          throw new Error('Failed to fetch server time');
        }

        const data = await response.json() as { unixtime: number };
        
        // Convert Unix timestamp to Date
        const timeInMs = data.unixtime * 1000;
        
        // Adjust to Venezuela timezone (UTC-4)
        const venezuelaOffset = -4 * 60 * 60 * 1000; // -4 hours in milliseconds
        const venezuelaTime = new Date(timeInMs + venezuelaOffset);
        
        setServerTime(venezuelaTime);
        setError(null);
      } catch (err) {
        console.error('Error fetching server time:', err);
        setError('Failed to sync with server');
        // Fallback to local time
        setServerTime(new Date());
      } finally {
        setLoading(false);
      }
    };

    fetchServerTime();
    
    // Update every 30 seconds for accuracy
    const interval = setInterval(fetchServerTime, 30000);
    
    return () => clearInterval(interval);
  }, []);

  return { serverTime, loading, error };
}
