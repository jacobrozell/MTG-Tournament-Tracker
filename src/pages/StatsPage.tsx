import { useMemo, useCallback } from 'react';
import { useAppStore } from '../stores/useAppStore';
import { PageHeader, SectionHeader, EmptyStateView } from '../components/layout';
import { PlayerRow, StandingsRow } from '../components/lists';
import { sortPlayersByTotalPoints, sortByWeeklyPoints } from '../engines/statsEngine';
import { getPlayerTotalPoints } from '../types';

export function StatsPage() {
  const { players, getActiveTournament } = useAppStore();

  const tournament = getActiveTournament();

  // Memoize sorted players
  const sortedPlayers = useMemo(() => sortPlayersByTotalPoints(players), [players]);

  if (players.length === 0) {
    return (
      <div className="flex-1 flex flex-col bg-gray-50">
        <PageHeader title="Stats" />
        <div className="flex-1 flex items-center justify-center">
          <EmptyStateView
            message="No players yet"
            hint="Create a tournament to add players"
          />
        </div>
      </div>
    );
  }

  // Memoize weekly standings
  const weeklyStandings = useMemo(() => {
    if (!tournament) return [];

    const sortedIds = sortByWeeklyPoints(
      tournament.presentPlayerIds,
      tournament.weeklyPointsByPlayer
    );

    return sortedIds.map((id) => {
      const player = players.find((p) => p.id === id);
      const weekly = tournament.weeklyPointsByPlayer[id] || {
        placementPoints: 0,
        achievementPoints: 0,
      };
      return {
        player,
        ...weekly,
        total: weekly.placementPoints + weekly.achievementPoints,
      };
    });
  }, [tournament, players]);

  // Memoize player stats formatter
  const getPlayerStats = useCallback(
    (playerId: string) => {
      const player = players.find((p) => p.id === playerId);
      if (!player) return '';

      const total = getPlayerTotalPoints(player);
      return `${total} pts - ${player.wins} wins - ${player.gamesPlayed} games - ${player.tournamentsPlayed} tournaments`;
    },
    [players]
  );

  return (
    <div className="flex-1 flex flex-col bg-gray-50">
      <PageHeader title="Stats" />

      <div className="flex-1 min-h-0 overflow-y-auto">
        {/* Weekly Standings (if tournament active) */}
        {tournament && tournament.presentPlayerIds.length > 0 && (
          <>
            <SectionHeader
              title={`Week ${tournament.currentWeek} Standings`}
              subtitle={tournament.name}
            />
            {weeklyStandings.map((s, i) => (
              <StandingsRow
                key={s.player?.id || i}
                rank={i + 1}
                name={s.player?.name || 'Unknown'}
                totalPoints={s.total}
                placementPoints={s.placementPoints}
                achievementPoints={s.achievementPoints}
                mode="weekly"
              />
            ))}
          </>
        )}

        {/* All-Time Standings */}
        <SectionHeader title="All-Time Standings" />
        {sortedPlayers.map((player, i) => (
          <StandingsRow
            key={player.id}
            rank={i + 1}
            name={player.name}
            totalPoints={getPlayerTotalPoints(player)}
            placementPoints={player.placementPoints}
            achievementPoints={player.achievementPoints}
            wins={player.wins}
            mode="tournament"
          />
        ))}

        {/* Player Stats */}
        <SectionHeader title="Player Stats" />
        {sortedPlayers.map((player) => (
          <PlayerRow
            key={player.id}
            name={player.name}
            mode="display"
            subtitle={getPlayerStats(player.id)}
          />
        ))}
      </div>
    </div>
  );
}
