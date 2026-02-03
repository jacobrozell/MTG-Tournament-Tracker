import type { Achievement, Player, WeeklyPlayerPoints } from '../types';
import { AppConstants } from '../constants';
import { shuffleArray, clamp } from '../utils';

// Pod Generation
export function generatePodsForRound(
  players: Player[],
  presentPlayerIds: string[],
  currentRound: number,
  weeklyPointsByPlayer: Record<string, WeeklyPlayerPoints>
): Player[][] {
  // Filter to present players only
  const presentPlayers = players.filter(p => presentPlayerIds.includes(p.id));
  
  if (presentPlayers.length === 0) return [];
  
  let sortedPlayers: Player[];
  
  if (currentRound === 1) {
    // Round 1: shuffle randomly
    sortedPlayers = shuffleArray(presentPlayers);
  } else {
    // Rounds 2+: sort by weekly total points (descending)
    sortedPlayers = [...presentPlayers].sort((a, b) => {
      const aPoints = weeklyPointsByPlayer[a.id] 
        ? weeklyPointsByPlayer[a.id].placementPoints + weeklyPointsByPlayer[a.id].achievementPoints
        : 0;
      const bPoints = weeklyPointsByPlayer[b.id]
        ? weeklyPointsByPlayer[b.id].placementPoints + weeklyPointsByPlayer[b.id].achievementPoints
        : 0;
      return bPoints - aPoints;
    });
  }
  
  // Split into pods of 4 players
  const pods: Player[][] = [];
  const podSize = AppConstants.League.podSize;
  
  for (let i = 0; i < sortedPlayers.length; i += podSize) {
    pods.push(sortedPlayers.slice(i, i + podSize));
  }
  
  return pods;
}

// Achievement Rolling
export function rollActiveAchievements(
  achievements: Achievement[],
  randomPerWeek: number
): Achievement[] {
  const alwaysOn = achievements.filter(a => a.alwaysOn);
  const notAlwaysOn = achievements.filter(a => !a.alwaysOn);
  
  const shuffled = shuffleArray(notAlwaysOn);
  const randomSample = shuffled.slice(0, Math.min(randomPerWeek, notAlwaysOn.length));
  
  return [...alwaysOn, ...randomSample];
}

// Scoring
export function calculatePlacementPoints(placement: number): number {
  return AppConstants.Scoring.placementPoints[placement] ?? 0;
}

export function calculateAchievementPoints(
  achievementIds: string[],
  achievements: Achievement[]
): number {
  return achievementIds.reduce((total, id) => {
    const achievement = achievements.find(a => a.id === id);
    return total + (achievement?.points ?? 0);
  }, 0);
}

// Player Creation
export function createPlayer(name: string): Player | null {
  const trimmedName = name.trim();
  if (!trimmedName) return null;
  
  return {
    id: '', // Will be set by store
    name: trimmedName,
    placementPoints: AppConstants.Scoring.initialPlacementPoints,
    achievementPoints: AppConstants.Scoring.initialAchievementPoints,
    wins: AppConstants.Scoring.initialWins,
    gamesPlayed: AppConstants.Scoring.initialGamesPlayed,
    tournamentsPlayed: 0,
  };
}

// Achievement Creation
export function createAchievement(
  name: string,
  points: number,
  alwaysOn: boolean
): Achievement | null {
  const trimmedName = name.trim();
  if (!trimmedName) return null;
  
  return {
    id: '', // Will be set by store
    name: trimmedName,
    points: clamp(points, 0, 99),
    alwaysOn,
  };
}

// Validation
export function clampWeeks(weeks: number): number {
  return clamp(weeks, AppConstants.League.weeksRange.min, AppConstants.League.weeksRange.max);
}

export function clampRandomPerWeek(count: number): number {
  return clamp(count, AppConstants.League.randomAchievementsPerWeekRange.min, AppConstants.League.randomAchievementsPerWeekRange.max);
}
