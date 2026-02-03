import type { Player, GameResult, TournamentPlayerStats, HeadToHeadRecord } from '../types';

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
