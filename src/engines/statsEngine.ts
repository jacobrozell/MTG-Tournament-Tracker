import type {
  Player,
  GameResult,
  TournamentPlayerStats,
  HeadToHeadRecord,
  Tournament,
  Achievement,
  TournamentSummary,
  AchievementSummary,
  AchievementStats,
} from '../types';
import { getGameResultTotalPoints } from '../types';

// Chart DTOs
export interface PerformanceTrendPoint {
  id: string;
  week: number;
  cumulativePoints: number;
}

export interface AchievementLeaderboardRow {
  id: string;
  achievementName: string;
  timesEarned: number;
  points: number;
}

export interface TopAchievementEarnerRow {
  id: string;
  name: string;
  achievementPoints: number;
}

// All-Time Stats
export function winRate(player: Player): number {
  if (player.gamesPlayed === 0) return 0;
  return player.wins / player.gamesPlayed;
}

export function averagePlacement(playerId: string, results: GameResult[]): number {
  const playerResults = results.filter(r => r.playerId === playerId);
  if (playerResults.length === 0) return 0;
  
  const sum = playerResults.reduce((acc, r) => acc + r.placement, 0);
  return sum / playerResults.length;
}

export function placementDistribution(
  playerId: string,
  results: GameResult[]
): Record<number, number> {
  const distribution: Record<number, number> = { 1: 0, 2: 0, 3: 0, 4: 0 };
  
  results
    .filter(r => r.playerId === playerId)
    .forEach(r => {
      if (r.placement >= 1 && r.placement <= 4) {
        distribution[r.placement]++;
      }
    });
  
  return distribution;
}

export function pointsPerGame(player: Player): number {
  if (player.gamesPlayed === 0) return 0;
  const totalPoints = player.placementPoints + player.achievementPoints;
  return totalPoints / player.gamesPlayed;
}

// Per-Tournament Stats
export function tournamentStats(
  playerId: string,
  tournamentId: string,
  results: GameResult[]
): TournamentPlayerStats {
  const tournamentResults = results.filter(
    r => r.playerId === playerId && r.tournamentId === tournamentId
  );
  
  const gamesPlayed = tournamentResults.length;
  const wins = tournamentResults.filter(r => r.placement === 1).length;
  const placementPoints = tournamentResults.reduce((sum, r) => sum + r.placementPoints, 0);
  const achievementPoints = tournamentResults.reduce((sum, r) => sum + r.achievementPoints, 0);
  const totalPoints = placementPoints + achievementPoints;
  
  const dist = placementDistribution(playerId, tournamentResults);
  const avgPlacement = gamesPlayed > 0
    ? tournamentResults.reduce((sum, r) => sum + r.placement, 0) / gamesPlayed
    : 0;
  
  return {
    gamesPlayed,
    wins,
    totalPoints,
    placementPoints,
    achievementPoints,
    placementDistribution: dist,
    averagePlacement: avgPlacement,
    winRate: gamesPlayed > 0 ? wins / gamesPlayed : 0,
  };
}

// Head-to-Head
export function headToHeadRecord(
  player1Id: string,
  player2Id: string,
  results: GameResult[]
): HeadToHeadRecord {
  // Group results by podId
  const resultsByPod = new Map<string, GameResult[]>();
  
  results.forEach(r => {
    const existing = resultsByPod.get(r.podId) || [];
    existing.push(r);
    resultsByPod.set(r.podId, existing);
  });
  
  let player1Wins = 0;
  let player2Wins = 0;
  let ties = 0;
  
  resultsByPod.forEach(podResults => {
    const p1Result = podResults.find(r => r.playerId === player1Id);
    const p2Result = podResults.find(r => r.playerId === player2Id);
    
    // Only count if both players were in the same pod
    if (p1Result && p2Result) {
      if (p1Result.placement < p2Result.placement) {
        player1Wins++;
      } else if (p2Result.placement < p1Result.placement) {
        player2Wins++;
      } else {
        ties++;
      }
    }
  });
  
  return {
    player1Wins,
    player2Wins,
    ties,
    totalGames: player1Wins + player2Wins + ties,
  };
}

// Leaderboard sorting
export function sortPlayersByTotalPoints(players: Player[]): Player[] {
  return [...players].sort((a, b) => {
    const aTotal = a.placementPoints + a.achievementPoints;
    const bTotal = b.placementPoints + b.achievementPoints;
    return bTotal - aTotal;
  });
}

export function sortByWeeklyPoints(
  playerIds: string[],
  weeklyPointsByPlayer: Record<string, { placementPoints: number; achievementPoints: number }>
): string[] {
  return [...playerIds].sort((a, b) => {
    const aPoints = weeklyPointsByPlayer[a]
      ? weeklyPointsByPlayer[a].placementPoints + weeklyPointsByPlayer[a].achievementPoints
      : 0;
    const bPoints = weeklyPointsByPlayer[b]
      ? weeklyPointsByPlayer[b].placementPoints + weeklyPointsByPlayer[b].achievementPoints
      : 0;
    return bPoints - aPoints;
  });
}

// Player History
export function getPlayerTournamentHistory(
  playerId: string,
  tournaments: Tournament[],
  gameResults: GameResult[]
): TournamentSummary[] {
  // Get all tournament IDs where this player has results
  const tournamentIds = new Set(
    gameResults
      .filter((r) => r.playerId === playerId)
      .map((r) => r.tournamentId)
  );

  const summaries: TournamentSummary[] = [];

  tournamentIds.forEach((tournamentId) => {
    const tournament = tournaments.find((t) => t.id === tournamentId);
    if (!tournament) return;

    const playerResults = gameResults.filter(
      (r) => r.playerId === playerId && r.tournamentId === tournamentId
    );

    const gamesPlayed = playerResults.length;
    const wins = playerResults.filter((r) => r.placement === 1).length;
    const placementPoints = playerResults.reduce((sum, r) => sum + r.placementPoints, 0);
    const achievementPoints = playerResults.reduce((sum, r) => sum + r.achievementPoints, 0);

    summaries.push({
      tournament,
      gamesPlayed,
      wins,
      totalPoints: placementPoints + achievementPoints,
      placementPoints,
      achievementPoints,
    });
  });

  // Sort by start date descending (most recent first)
  return summaries.sort((a, b) => 
    new Date(b.tournament.startDate).getTime() - new Date(a.tournament.startDate).getTime()
  );
}

export function getPlayerAchievementBreakdown(
  playerId: string,
  gameResults: GameResult[],
  achievements: Achievement[]
): AchievementSummary[] {
  const playerResults = gameResults.filter((r) => r.playerId === playerId);

  // Count achievements earned
  const achievementCounts: Record<string, number> = {};
  playerResults.forEach((result) => {
    result.achievementIds.forEach((achId) => {
      achievementCounts[achId] = (achievementCounts[achId] || 0) + 1;
    });
  });

  // Build summary
  const summaries: AchievementSummary[] = [];
  Object.entries(achievementCounts).forEach(([achId, count]) => {
    const achievement = achievements.find((a) => a.id === achId);
    if (achievement) {
      summaries.push({
        achievement,
        count,
        totalPoints: achievement.points * count,
      });
    }
  });

  // Sort by total points descending
  return summaries.sort((a, b) => b.totalPoints - a.totalPoints);
}

const TOP_PLAYERS_CAP = 5;

export function getAchievementStats(
  achievementId: string,
  gameResults: GameResult[],
  players: Player[]
): AchievementStats {
  const playerCounts: Record<string, number> = {};
  let totalTimesEarned = 0;

  gameResults.forEach((result) => {
    result.achievementIds.forEach((achId) => {
      if (achId !== achievementId) return;
      totalTimesEarned++;
      playerCounts[result.playerId] = (playerCounts[result.playerId] || 0) + 1;
    });
  });

  const topPlayers = Object.entries(playerCounts)
    .map(([playerId, count]) => {
      const player = players.find((p) => p.id === playerId);
      return { playerId, playerName: player?.name ?? 'Unknown', count };
    })
    .sort((a, b) => b.count - a.count)
    .slice(0, TOP_PLAYERS_CAP);

  return { totalTimesEarned, topPlayers };
}

export function getAllAchievementStats(
  achievements: Achievement[],
  gameResults: GameResult[],
  players: Player[]
): Record<string, AchievementStats> {
  const map: Record<string, AchievementStats> = {};
  achievements.forEach((a) => {
    map[a.id] = getAchievementStats(a.id, gameResults, players);
  });
  return map;
}

// Performance trend: cumulative points by week for a player
export function getPerformanceTrend(
  playerId: string | null,
  gameResults: GameResult[]
): PerformanceTrendPoint[] {
  if (!playerId) return [];
  const playerResults = gameResults
    .filter((r) => r.playerId === playerId)
    .sort((a, b) => (a.week !== b.week ? a.week - b.week : a.round - b.round));
  let cumulative = 0;
  const byWeek = new Map<number, number>();
  for (const r of playerResults) {
    cumulative += getGameResultTotalPoints(r);
    byWeek.set(r.week, cumulative);
  }
  return Array.from(byWeek.entries())
    .sort((a, b) => a[0] - b[0])
    .map(([week, cumulativePoints]) => ({
      id: `${playerId}-${week}`,
      week,
      cumulativePoints,
    }));
}

// Achievement leaderboard: most earned achievements (times earned across all results)
export function getAchievementLeaderboard(
  achievements: Achievement[],
  gameResults: GameResult[]
): AchievementLeaderboardRow[] {
  const countByAchId: Record<string, number> = {};
  for (const r of gameResults) {
    for (const achId of r.achievementIds) {
      countByAchId[achId] = (countByAchId[achId] ?? 0) + 1;
    }
  }
  return achievements
    .map((a) => ({
      id: a.id,
      achievementName: a.name,
      timesEarned: countByAchId[a.id] ?? 0,
      points: a.points,
    }))
    .filter((row) => row.timesEarned > 0)
    .sort((a, b) => b.timesEarned - a.timesEarned);
}

// Top achievement earners: players with achievementPoints > 0, sorted desc, capped
export function getTopAchievementEarners(
  players: Player[],
  limit: number = 5
): TopAchievementEarnerRow[] {
  return players
    .filter((p) => p.achievementPoints > 0)
    .sort((a, b) => b.achievementPoints - a.achievementPoints)
    .slice(0, limit)
    .map((p) => ({
      id: p.id,
      name: p.name,
      achievementPoints: p.achievementPoints,
    }));
}
