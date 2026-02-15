import { useState, useEffect } from 'react';
import type { GameTime } from '@/lib/hexmap/types';
import { getNorthernSeasonByMonth, getSouthernSeasonByMonth } from '@/lib/hexmap/season-system';

// Genesis: November 15, 2025 at 00:00:00 UTC
const GENESIS_DATE = new Date('2025-11-15T00:00:00Z');

// Current server time: January 10, 2026 at 00:05:00 UTC (12:05 AM)
const SERVER_TIME_NOW = new Date('2026-01-10T00:05:00Z');

// Speed multiplier: 4x faster than real time
const SPEED_MULTIPLIER = 4;

// Game calendar: 14 months per year, 28 days per month
// 1 real week = 1 game month (28 days)
// 1 game year = 14 months × 28 days = 392 game days = 14 real weeks
const DAYS_PER_MONTH = 28;
const MONTHS_PER_YEAR = 14;
const DAYS_PER_YEAR = DAYS_PER_MONTH * MONTHS_PER_YEAR; // 392 days

// Calculate how much real time has passed since genesis
const REAL_TIME_SINCE_GENESIS = SERVER_TIME_NOW.getTime() - GENESIS_DATE.getTime();

// Calculate game time elapsed (4x faster)
const GAME_TIME_SINCE_GENESIS = REAL_TIME_SINCE_GENESIS * SPEED_MULTIPLIER;

// Calculate current game date at server time
const GAME_DATE_AT_SERVER_TIME = new Date(GENESIS_DATE.getTime() + GAME_TIME_SINCE_GENESIS);

/**
 * Hook for continuous game time with 14-month calendar system
 * Genesis: November 15, 2025 as Day 1, Month 1, Year 1
 * Calendar: 14 months per year, 28 days per month
 * 1 real week = 1 game month (28 days)
 */
export function useGameTime(): GameTime {
  const [currentDate, setCurrentDate] = useState<Date>(GAME_DATE_AT_SERVER_TIME);
  const [dayNumber, setDayNumber] = useState<number>(1);
  const [monthNumber, setMonthNumber] = useState<number>(1);
  const [yearNumber, setYearNumber] = useState<number>(1);
  const componentMountTime = Date.now();

  useEffect(() => {
    const interval = setInterval(() => {
      // Calculate elapsed real time since component mounted
      const realElapsedSinceMount = Date.now() - componentMountTime;
      
      // Multiply by speed to get game time elapsed since mount
      const gameElapsedSinceMount = realElapsedSinceMount * SPEED_MULTIPLIER;
      
      // Calculate current game date (server time + elapsed since mount)
      const totalGameTime = GAME_TIME_SINCE_GENESIS + gameElapsedSinceMount;
      const newGameDate = new Date(GENESIS_DATE.getTime() + totalGameTime);
      setCurrentDate(newGameDate);
      
      // Calculate day number (days since genesis)
      const totalDaysSinceGenesis = Math.floor(totalGameTime / (1000 * 60 * 60 * 24));
      setDayNumber(totalDaysSinceGenesis + 1);
      
      // Calculate year number (years since genesis)
      const yearsElapsed = Math.floor(totalDaysSinceGenesis / DAYS_PER_YEAR);
      setYearNumber(yearsElapsed + 1);
      
      // Calculate month number (1-14) within current year
      const daysInCurrentYear = totalDaysSinceGenesis % DAYS_PER_YEAR;
      const monthsElapsed = Math.floor(daysInCurrentYear / DAYS_PER_MONTH);
      setMonthNumber(monthsElapsed + 1);
    }, 100); // Update every 100ms for smooth counter

    return () => clearInterval(interval);
  }, [componentMountTime]);

  return {
    startDate: GENESIS_DATE,
    currentDate,
    dayNumber,
    monthNumber,
    yearNumber,
    speed: SPEED_MULTIPLIER,
    seasonInNorth: getNorthernSeasonByMonth(monthNumber),
    seasonInSouth: getSouthernSeasonByMonth(monthNumber)
  };
}

/**
 * Format game date for display with 14-month calendar
 */
export function formatGameDate(gameTime: GameTime): string {
  return `Year ${gameTime.yearNumber}, Month ${gameTime.monthNumber}, Day ${gameTime.dayNumber}`;
}

/**
 * Format day number with ordinal suffix
 */
export function formatDayNumber(day: number): string {
  return `Day ${day.toLocaleString('en-US')}`;
}

/**
 * Format month and year
 */
export function formatMonthYear(monthNumber: number, yearNumber: number): string {
  return `Month ${monthNumber} of Year ${yearNumber}`;
}
