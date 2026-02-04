import { useMemo, useCallback, useState, useEffect } from 'react';
import { useAppStore } from '../stores/useAppStore';
import { PageHeader, SectionHeader, EmptyStateView, TabButton } from '../components/layout';
import { PlayerRow, StandingsRow } from '../components/lists';
import { BarChartCard, LineChartCard, PieChartCard } from '../components/charts';
import {
  sortPlayersByTotalPoints,
  sortByWeeklyPoints,
  getPerformanceTrend,
  getAchievementLeaderboard,
  getTopAchievementEarners,
  placementDistribution,
} from '../engines/statsEngine';
import { getPlayerTotalPoints } from '../types';

type StatsSegment = 'weekly' | 'standings' | 'charts' | 'players';

export function StatsPage() {
  const { players, gameResults, achievements, getActiveTournament } = useAppStore();
  const [chartPlayerId, setChartPlayerId] = useState<string | null>(null);
  const [activeSegment, setActiveSegment] = useState<StatsSegment>('standings');

  const tournament = getActiveTournament();
  const showWeekly = Boolean(tournament && tournament.presentPlayerIds.length > 0);

  // Segment fallback: when Weekly tab is hidden, leave "weekly" segment
  useEffect(() => {
    if (activeSegment === 'weekly' && !showWeekly) {
      setActiveSegment('standings');
    }
  }, [activeSegment, showWeekly]);

  // All hooks must be called before any early returns

  // Memoize sorted players
  const sortedPlayers = useMemo(() => sortPlayersByTotalPoints(players), [players]);
  const effectiveChartPlayerId = chartPlayerId ?? sortedPlayers[0]?.id ?? null;
  const hasGameResults = gameResults.length > 0;

  // Chart data
  const pointsComparisonData = useMemo(
    () =>
      sortedPlayers.map((p) => ({
        id: p.id,
        label: p.name,
        placement: p.placementPoints,
        achievement: p.achievementPoints,
      })),
    [sortedPlayers]
  );
  const performanceTrendData = useMemo(
    () => getPerformanceTrend(effectiveChartPlayerId, gameResults),
    [effectiveChartPlayerId, gameResults]
  );
  const placementPieData = useMemo(() => {
    if (!effectiveChartPlayerId) return [];
    const dist = placementDistribution(effectiveChartPlayerId, gameResults);
    return ([1, 2, 3, 4] as const).map((place) => ({
      name: place === 1 ? '1st' : place === 2 ? '2nd' : place === 3 ? '3rd' : '4th',
      value: dist[place] ?? 0,
    }));
  }, [effectiveChartPlayerId, gameResults]);
  const achievementLeaderboardData = useMemo(
    () => getAchievementLeaderboard(achievements, gameResults).slice(0, 5),
    [achievements, gameResults]
  );
  const winsComparisonData = useMemo(
    () =>
      [...sortedPlayers].sort((a, b) => b.wins - a.wins).map((p) => ({
        id: p.id,
        label: p.name,
        value: p.wins,
      })),
    [sortedPlayers]
  );
  const topAchievementEarnersData = useMemo(
    () =>
      getTopAchievementEarners(players, 5).map((p) => ({
        id: p.id,
        label: p.name,
        value: p.achievementPoints,
      })),
    [players]
  );

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

  // Early return after all hooks
  if (players.length === 0) {
    return (
      <div className="flex-1 flex flex-col min-h-0 bg-gray-50">
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

  return (
    <div className="flex-1 flex flex-col min-h-0 bg-gray-50">
      <PageHeader title="Stats" />

      <div className="flex bg-white border-b border-gray-200">
        {showWeekly && (
          <TabButton
            label="Weekly"
            active={activeSegment === 'weekly'}
            onClick={() => setActiveSegment('weekly')}
          />
        )}
        <TabButton
          label="Standings"
          active={activeSegment === 'standings'}
          onClick={() => setActiveSegment('standings')}
        />
        <TabButton
          label="Charts"
          active={activeSegment === 'charts'}
          onClick={() => setActiveSegment('charts')}
        />
        <TabButton
          label="Players"
          active={activeSegment === 'players'}
          onClick={() => setActiveSegment('players')}
        />
      </div>

      <div className="flex-1 min-h-0 overflow-y-auto">
        {activeSegment === 'weekly' && showWeekly && (
          <>
            <SectionHeader
              title={`Week ${tournament!.currentWeek} Standings`}
              subtitle={tournament!.name}
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

        {activeSegment === 'standings' && (
          <>
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
          </>
        )}

        {activeSegment === 'charts' && (
          <>
            {hasGameResults ? (
              <div className="px-4 pb-4 space-y-4">
                <BarChartCard
                  title="Points Comparison"
                  data={pointsComparisonData}
                  height={220}
                  grouped
                  primaryKey="placement"
                  secondaryKey="achievement"
                  primaryLabel="Placement"
                  secondaryLabel="Achievement"
                />
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Player for trend & placement</label>
                  <select
                    value={effectiveChartPlayerId ?? ''}
                    onChange={(e) => setChartPlayerId(e.target.value || null)}
                    className="w-full max-w-xs px-3 py-2 border border-gray-300 rounded-lg bg-white text-sm"
                  >
                    {sortedPlayers.map((p) => (
                      <option key={p.id} value={p.id}>
                        {p.name}
                      </option>
                    ))}
                  </select>
                </div>
                <LineChartCard
                  title="Performance Trends"
                  data={performanceTrendData.map((d) => ({ week: d.week, value: d.cumulativePoints }))}
                  xKey="week"
                  yKey="value"
                  height={180}
                />
                <PieChartCard title="Placement Distribution" data={placementPieData} height={160} donut />
                {achievementLeaderboardData.length > 0 && (
                  <BarChartCard
                    title="Most Earned Achievements"
                    data={achievementLeaderboardData.map((r) => ({
                      id: r.id,
                      label: r.achievementName,
                      value: r.timesEarned,
                    }))}
                    valueKey="value"
                    height={200}
                  />
                )}
                <BarChartCard
                  title="Wins by Player"
                  data={winsComparisonData}
                  valueKey="value"
                  height={180}
                />
                {topAchievementEarnersData.length > 0 && (
                  <BarChartCard
                    title="Top Achievement Earners"
                    data={topAchievementEarnersData}
                    valueKey="value"
                    height={180}
                  />
                )}
              </div>
            ) : (
              <div className="flex-1 flex items-center justify-center py-12">
                <EmptyStateView
                  message="No game results yet"
                  hint="Play games in a tournament to see charts"
                />
              </div>
            )}
          </>
        )}

        {activeSegment === 'players' && (
          <>
            <SectionHeader title="Player Stats" />
            {sortedPlayers.map((player) => (
              <PlayerRow
                key={player.id}
                name={player.name}
                mode="display"
                subtitle={getPlayerStats(player.id)}
              />
            ))}
          </>
        )}
      </div>
    </div>
  );
}
