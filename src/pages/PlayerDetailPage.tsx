import { useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAppStore } from '../stores/useAppStore';
import { PageHeader, SectionHeader, EmptyStateView } from '../components/layout';
import { LineChartCard, PieChartCard } from '../components/charts';
import {
  getPlayerTournamentHistory,
  getPerformanceTrend,
  placementDistribution,
  pointsPerGame,
  winRate,
  averagePlacement,
} from '../engines/statsEngine';

export function PlayerDetailPage() {
  const navigate = useNavigate();
  const {
    getSelectedPlayer,
    getPlayerGameResults,
    getPlayerAchievementHistory,
    tournaments,
    gameResults,
    clearSelectedPlayer,
    removePlayer,
    setScreen,
  } = useAppStore();

  const player = getSelectedPlayer();
  const playerResults = player ? getPlayerGameResults(player.id) : [];

  const tournamentHistory = useMemo(() => {
    if (!player) return [];
    return getPlayerTournamentHistory(player.id, tournaments, gameResults);
  }, [player, tournaments, gameResults]);

  const achievementHistory = useMemo(() => {
    if (!player) return [];
    return getPlayerAchievementHistory(player.id);
  }, [player, getPlayerAchievementHistory]);

  const stats = useMemo(() => {
    if (!player) return null;
    const totalPoints = player.placementPoints + player.achievementPoints;
    const dist = placementDistribution(player.id, playerResults);
    const rate = winRate(player);
    const avgPlacement = averagePlacement(player.id, playerResults);

    return {
      totalPoints,
      placementPoints: player.placementPoints,
      achievementPoints: player.achievementPoints,
      wins: player.wins,
      gamesPlayed: player.gamesPlayed,
      tournamentsPlayed: player.tournamentsPlayed,
      winRate: rate,
      averagePlacement: avgPlacement,
      placementDistribution: dist,
    };
  }, [player, playerResults]);

  const hasGameResults = playerResults.length > 0;
  const performanceTrendData = useMemo(
    () => (player ? getPerformanceTrend(player.id, gameResults) : []),
    [player, gameResults]
  );
  const placementPieData = useMemo(() => {
    if (!player) return [];
    const dist = placementDistribution(player.id, playerResults);
    return ([1, 2, 3, 4] as const).map((place) => ({
      name: place === 1 ? '1st' : place === 2 ? '2nd' : place === 3 ? '3rd' : '4th',
      value: dist[place] ?? 0,
    }));
  }, [player, playerResults]);

  const handleBack = () => {
    setScreen('players');
    clearSelectedPlayer();
    navigate('/players');
  };

  if (!player || !stats) {
    return (
      <div className="flex-1 flex flex-col min-h-0 bg-gray-50">
        <PageHeader title="Player" onBack={handleBack} />
        <div className="flex-1 flex items-center justify-center">
          <EmptyStateView message="Player not found" />
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 flex flex-col min-h-0 bg-gray-50">
      <PageHeader title={player.name} onBack={handleBack} />

      <div className="flex-1 min-h-0 overflow-y-auto">
        {/* Stats Overview */}
        <SectionHeader title="Statistics" />
        <div className="bg-white p-4">
          <div className="grid grid-cols-2 gap-4">
            <StatItem label="Total Points" value={stats.totalPoints} />
            <StatItem label="Wins" value={stats.wins} />
            <StatItem label="Games Played" value={stats.gamesPlayed} />
            <StatItem label="Tournaments" value={stats.tournamentsPlayed} />
            <StatItem 
              label="Win Rate" 
              value={`${(stats.winRate * 100).toFixed(1)}%`} 
            />
            <StatItem 
              label="Avg Placement" 
              value={stats.gamesPlayed > 0 ? stats.averagePlacement.toFixed(2) : '-'} 
            />
          </div>

          {/* Points Breakdown */}
          <div className="mt-4 pt-4 border-t border-gray-100">
            <p className="text-sm text-gray-500 mb-2">Points Breakdown</p>
            <div className="flex gap-4">
              <div className="flex-1 bg-blue-50 rounded-lg p-3 text-center">
                <p className="text-2xl font-bold text-blue-600">{stats.placementPoints}</p>
                <p className="text-xs text-blue-600">Placement</p>
              </div>
              <div className="flex-1 bg-purple-50 rounded-lg p-3 text-center">
                <p className="text-2xl font-bold text-purple-600">{stats.achievementPoints}</p>
                <p className="text-xs text-purple-600">Achievement</p>
              </div>
            </div>
            <div className="mt-3 flex items-center justify-between text-sm">
              <span className="text-gray-500">Points per game</span>
              <span className="font-semibold text-gray-900">{pointsPerGame(player).toFixed(1)}</span>
            </div>
          </div>

          {/* Placement Distribution */}
          {stats.gamesPlayed > 0 && (
            <div className="mt-4 pt-4 border-t border-gray-100">
              <p className="text-sm text-gray-500 mb-2">Placement Distribution</p>
              <div className="grid grid-cols-4 gap-2">
                {[1, 2, 3, 4].map((place) => (
                  <div key={place} className="text-center">
                    <p className="text-lg font-semibold text-gray-900">
                      {stats.placementDistribution[place] || 0}
                    </p>
                    <p className="text-xs text-gray-500">
                      {place === 1 ? '1st' : place === 2 ? '2nd' : place === 3 ? '3rd' : '4th'}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Charts (only when player has game results) */}
        {hasGameResults && (
          <>
            <SectionHeader title="Charts" />
            <div className="px-4 pb-4 space-y-4">
              <PieChartCard title="Placement Distribution" data={placementPieData} height={160} donut />
              <LineChartCard
                title="Performance Over Time"
                data={performanceTrendData.map((d) => ({ week: d.week, value: d.cumulativePoints }))}
                xKey="week"
                yKey="value"
                height={180}
              />
            </div>
          </>
        )}

        {/* Tournament History */}
        <SectionHeader title="Tournament History" />
        {tournamentHistory.length === 0 ? (
          <div className="bg-white p-4">
            <p className="text-gray-500 text-center">No tournament history</p>
          </div>
        ) : (
          <div className="bg-white">
            {tournamentHistory.map((summary) => (
              <div
                key={summary.tournament.id}
                className="px-4 py-3 border-b border-gray-100 last:border-b-0"
              >
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium text-gray-900">{summary.tournament.name}</p>
                    <p className="text-sm text-gray-500">
                      {summary.gamesPlayed} games · {summary.wins} wins
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-gray-900">{summary.totalPoints} pts</p>
                    <p className="text-xs text-gray-500">
                      {summary.placementPoints} + {summary.achievementPoints}
                    </p>
                  </div>
                </div>
                <div className="mt-1 flex items-center gap-2 text-xs text-gray-400">
                  <span>
                    {new Date(summary.tournament.startDate).toLocaleDateString()}
                  </span>
                  {summary.tournament.status === 'completed' && (
                    <>
                      <span>→</span>
                      <span>
                        {summary.tournament.endDate 
                          ? new Date(summary.tournament.endDate).toLocaleDateString()
                          : 'Completed'}
                      </span>
                    </>
                  )}
                  {summary.tournament.status === 'ongoing' && (
                    <span className="px-1.5 py-0.5 bg-green-100 text-green-700 rounded">
                      Ongoing
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Achievement History */}
        <SectionHeader title="Achievements Earned" />
        {achievementHistory.length === 0 ? (
          <div className="bg-white p-4">
            <p className="text-gray-500 text-center">No achievements earned</p>
          </div>
        ) : (
          <div className="bg-white">
            {achievementHistory.map((summary) => (
              <div
                key={summary.achievement.id}
                className="flex items-center justify-between px-4 py-3 border-b border-gray-100 last:border-b-0"
              >
                <div>
                  <p className="font-medium text-gray-900">{summary.achievement.name}</p>
                  <p className="text-sm text-gray-500">
                    {summary.achievement.points} pts each · Earned {summary.count}x
                  </p>
                </div>
                <p className="font-semibold text-purple-600">{summary.totalPoints} pts</p>
              </div>
            ))}
          </div>
        )}

        {/* Delete Player */}
        <SectionHeader title="Danger Zone" />
        <div className="bg-white px-4 py-4">
          <button
            type="button"
            onClick={() => {
              if (window.confirm(`Delete ${player.name}? This cannot be undone.`)) {
                removePlayer(player.id);
                handleBack();
              }
            }}
            className="w-full py-2.5 text-red-600 font-medium hover:bg-red-50 rounded-lg transition-colors"
          >
            Delete Player
          </button>
        </div>

        {/* Bottom padding */}
        <div className="h-4" />
      </div>
    </div>
  );
}

function StatItem({ label, value }: { label: string; value: string | number }) {
  return (
    <div>
      <p className="text-sm text-gray-500">{label}</p>
      <p className="text-xl font-semibold text-gray-900">{value}</p>
    </div>
  );
}
