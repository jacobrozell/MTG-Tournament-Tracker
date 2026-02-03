// Player
export interface Player {
  id: string;
  name: string;
  placementPoints: number;
  achievementPoints: number;
  wins: number;
  gamesPlayed: number;
  tournamentsPlayed: number;
}

// Achievement
export interface Achievement {
  id: string;
  name: string;
  points: number;
  alwaysOn: boolean;
}

// Tournament
export type TournamentStatus = 'ongoing' | 'completed';

export interface WeeklyPlayerPoints {
  placementPoints: number;
  achievementPoints: number;
}

export interface Tournament {
  id: string;
  name: string;
  totalWeeks: number;
  randomAchievementsPerWeek: number;
  startDate: string; // ISO string for persistence
  endDate: string | null;
  status: TournamentStatus;
  currentWeek: number;
  currentRound: number;
  achievementsOnThisWeek: boolean;
  selectedPlayerIds: string[]; // Players selected when tournament was created
  presentPlayerIds: string[];
  weeklyPointsByPlayer: Record<string, WeeklyPlayerPoints>;
  activeAchievementIds: string[];
  roundPlacements: Record<string, number>;
  roundAchievementChecks: string[]; // Array of "playerId:achievementId" strings
  podHistorySnapshots: PodSnapshot[];
}

// GameResult
export interface GameResult {
  id: string;
  tournamentId: string;
  week: number;
  round: number;
  playerId: string;
  placement: number;
  placementPoints: number;
  achievementPoints: number;
  achievementIds: string[];
  timestamp: string; // ISO string
  podId: string;
}

// Navigation
export type Screen =
  | 'tournaments'
  | 'newTournament'
  | 'addPlayers'
  | 'attendance'
  | 'pods'
  | 'tournamentStandings';

// Supporting Types
export interface AchievementCheck {
  playerId: string;
  achievementId: string;
  points: number;
}

export interface PlayerDelta {
  placementPoints: number;
  achievementPoints: number;
  wins: number;
  gamesPlayed: number;
}

export interface PodSnapshot {
  podId: string;
  playerIds: string[];
  placements: Record<string, number>;
  achievementChecks: AchievementCheck[];
  playerDeltas: Record<string, PlayerDelta>;
  weeklyDeltas: Record<string, WeeklyPlayerPoints>;
}

// Stats Types
export interface TournamentPlayerStats {
  gamesPlayed: number;
  wins: number;
  totalPoints: number;
  placementPoints: number;
  achievementPoints: number;
  placementDistribution: Record<number, number>;
  averagePlacement: number;
  winRate: number;
}

export interface HeadToHeadRecord {
  player1Wins: number;
  player2Wins: number;
  ties: number;
  totalGames: number;
}

// Computed helpers
export function getPlayerTotalPoints(player: Player): number {
  return player.placementPoints + player.achievementPoints;
}

export function getWeeklyTotalPoints(weekly: WeeklyPlayerPoints): number {
  return weekly.placementPoints + weekly.achievementPoints;
}

export function isTournamentFinalWeek(tournament: Tournament): boolean {
  return tournament.currentWeek >= tournament.totalWeeks;
}

export function getGameResultTotalPoints(result: GameResult): number {
  return result.placementPoints + result.achievementPoints;
}

export function isGameResultWin(result: GameResult): boolean {
  return result.placement === 1;
}
