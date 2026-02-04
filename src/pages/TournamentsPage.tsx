import { useState, useMemo, useCallback } from 'react';
import { useAppStore } from '../stores/useAppStore';
import { PageHeader, SectionHeader, EmptyStateView, Modal, ModalActionBar } from '../components/layout';
import { TournamentCell, StandingsRow } from '../components/lists';
import { PrimaryActionButton, DestructiveActionButton } from '../components/buttons';
import { LabeledStepper } from '../components/forms';
import { AppConstants } from '../constants';
import { Plus } from 'lucide-react';

export function TournamentsPage() {
  const {
    tournaments,
    players,
    getOngoingTournaments,
    getCompletedTournaments,
    selectTournament,
    createTournament,
    deleteTournament,
    addPlayer,
    gameResults,
  } = useAppStore();

  const [showNewModal, setShowNewModal] = useState(false);
  const [showStandingsModal, setShowStandingsModal] = useState(false);
  const [selectedTournamentId, setSelectedTournamentId] = useState<string | null>(null);

  // New tournament form state
  const [name, setName] = useState('');
  const [weeks, setWeeks] = useState(AppConstants.League.defaultTotalWeeks);
  const [randomPerWeek, setRandomPerWeek] = useState(AppConstants.League.defaultRandomAchievementsPerWeek);
  const [selectedPlayerIds, setSelectedPlayerIds] = useState<Set<string>>(new Set());
  const [newPlayerName, setNewPlayerName] = useState('');

  const ongoing = getOngoingTournaments();
  const completed = getCompletedTournaments();

  const handleOpenNew = () => {
    setName('');
    setWeeks(AppConstants.League.defaultTotalWeeks);
    setRandomPerWeek(AppConstants.League.defaultRandomAchievementsPerWeek);
    setSelectedPlayerIds(new Set(players.map((p) => p.id)));
    setNewPlayerName('');
    setShowNewModal(true);
  };

  const handleCreate = () => {
    if (!name.trim() || selectedPlayerIds.size === 0) return;
    createTournament(name, weeks, randomPerWeek, Array.from(selectedPlayerIds));
    setShowNewModal(false);
  };

  const handleAddPlayer = () => {
    if (!newPlayerName.trim()) return;
    const player = addPlayer(newPlayerName);
    if (player) {
      setSelectedPlayerIds((prev) => new Set([...prev, player.id]));
      setNewPlayerName('');
    }
  };

  const handleTournamentClick = (id: string) => {
    const tournament = tournaments.find((t) => t.id === id);
    if (!tournament) return;

    if (tournament.status === 'completed') {
      setSelectedTournamentId(id);
      setShowStandingsModal(true);
    } else {
      selectTournament(id);
    }
  };

  const handleDeleteTournament = (id: string) => {
    if (!window.confirm('Delete this tournament? This cannot be undone.')) return;
    deleteTournament(id);
    if (selectedTournamentId === id) {
      setSelectedTournamentId(null);
      setShowStandingsModal(false);
    }
  };

  // Memoize winner name lookup
  const getWinnerName = useCallback(
    (tournamentId: string) => {
      const tournamentResults = gameResults.filter((r) => r.tournamentId === tournamentId);
      if (tournamentResults.length === 0) return undefined;

      const pointsByPlayer: Record<string, number> = {};
      tournamentResults.forEach((r) => {
        pointsByPlayer[r.playerId] = (pointsByPlayer[r.playerId] || 0) + r.placementPoints + r.achievementPoints;
      });

      let winnerId = '';
      let maxPoints = -1;
      Object.entries(pointsByPlayer).forEach(([playerId, points]) => {
        if (points > maxPoints) {
          maxPoints = points;
          winnerId = playerId;
        }
      });

      return players.find((p) => p.id === winnerId)?.name;
    },
    [gameResults, players]
  );

  // Memoize selected tournament lookup
  const selectedTournament = useMemo(
    () => (selectedTournamentId ? tournaments.find((t) => t.id === selectedTournamentId) : null),
    [selectedTournamentId, tournaments]
  );

  // Memoize tournament standings calculation
  const tournamentStandings = useMemo(() => {
    if (!selectedTournamentId) return [];
    const tournamentResults = gameResults.filter((r) => r.tournamentId === selectedTournamentId);
    
    const statsByPlayer: Record<string, { placement: number; achievement: number; wins: number }> = {};
    tournamentResults.forEach((r) => {
      if (!statsByPlayer[r.playerId]) {
        statsByPlayer[r.playerId] = { placement: 0, achievement: 0, wins: 0 };
      }
      statsByPlayer[r.playerId].placement += r.placementPoints;
      statsByPlayer[r.playerId].achievement += r.achievementPoints;
      if (r.placement === 1) statsByPlayer[r.playerId].wins++;
    });

    return Object.entries(statsByPlayer)
      .map(([playerId, stats]) => ({
        player: players.find((p) => p.id === playerId),
        ...stats,
        total: stats.placement + stats.achievement,
      }))
      .filter((s) => s.player)
      .sort((a, b) => b.total - a.total);
  }, [selectedTournamentId, gameResults, players]);

  return (
    <div className="flex-1 flex flex-col bg-gray-50">
      <PageHeader title="Tournaments" onAdd={handleOpenNew} />

      {tournaments.length === 0 ? (
        <div className="flex-1 flex flex-col items-center justify-center p-4">
          <EmptyStateView
            message="No tournaments yet"
            hint="Create a tournament to get started"
          />
          <div className="mt-4 w-full max-w-xs">
            <PrimaryActionButton title="Create Tournament" onClick={handleOpenNew} />
          </div>
        </div>
      ) : (
        <div className="flex-1 min-h-0 overflow-y-auto">
          {ongoing.length > 0 && (
            <>
              <SectionHeader title="Ongoing" />
              {ongoing.map((t) => (
                <TournamentCell
                  key={t.id}
                  tournament={t}
                  playerCount={t.presentPlayerIds.length || players.length}
                  onClick={() => handleTournamentClick(t.id)}
                  onDelete={() => handleDeleteTournament(t.id)}
                />
              ))}
            </>
          )}
          {completed.length > 0 && (
            <>
              <SectionHeader title="Completed" />
              {completed.map((t) => (
                <TournamentCell
                  key={t.id}
                  tournament={t}
                  playerCount={0}
                  winnerName={getWinnerName(t.id)}
                  onClick={() => handleTournamentClick(t.id)}
                  onDelete={() => handleDeleteTournament(t.id)}
                />
              ))}
            </>
          )}
        </div>
      )}

      {/* New Tournament Modal */}
      <Modal
        isOpen={showNewModal}
        onClose={() => setShowNewModal(false)}
        title="New Tournament"
      >
        <div className="p-4 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Tournament Name
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Enter tournament name"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>

          <LabeledStepper
            title="Weeks"
            value={weeks}
            onChange={setWeeks}
            min={AppConstants.League.weeksRange.min}
            max={AppConstants.League.weeksRange.max}
          />

          <LabeledStepper
            title="Random achievements/week"
            value={randomPerWeek}
            onChange={setRandomPerWeek}
            min={AppConstants.League.randomAchievementsPerWeekRange.min}
            max={AppConstants.League.randomAchievementsPerWeekRange.max}
          />

          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium text-gray-700">
                Players ({selectedPlayerIds.size} selected)
              </span>
            </div>
            <div className="border border-gray-200 rounded-lg overflow-hidden max-h-48 overflow-y-auto">
              {players.map((p) => (
                <label
                  key={p.id}
                  className="flex items-center gap-3 px-3 py-2 hover:bg-gray-50 cursor-pointer border-b border-gray-100 last:border-b-0"
                >
                  <input
                    type="checkbox"
                    checked={selectedPlayerIds.has(p.id)}
                    onChange={(e) => {
                      const next = new Set(selectedPlayerIds);
                      if (e.target.checked) {
                        next.add(p.id);
                      } else {
                        next.delete(p.id);
                      }
                      setSelectedPlayerIds(next);
                    }}
                    className="w-4 h-4 rounded border-gray-300 text-blue-600"
                  />
                  <span className="text-gray-900">{p.name}</span>
                </label>
              ))}
            </div>
            <div className="flex gap-2 mt-2">
              <input
                type="text"
                value={newPlayerName}
                onChange={(e) => setNewPlayerName(e.target.value)}
                placeholder="Add new player"
                className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                onKeyDown={(e) => e.key === 'Enter' && handleAddPlayer()}
              />
              <button
                onClick={handleAddPlayer}
                className="px-3 py-2 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors"
              >
                <Plus className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
        <ModalActionBar
          primaryTitle="Create Tournament"
          primaryAction={handleCreate}
          primaryDisabled={!name.trim() || selectedPlayerIds.size === 0}
          secondaryTitle="Cancel"
          secondaryAction={() => setShowNewModal(false)}
        />
      </Modal>

      {/* Tournament Standings Modal */}
      <Modal
        isOpen={showStandingsModal}
        onClose={() => setShowStandingsModal(false)}
        title={selectedTournament ? `${selectedTournament.name} - Final Rankings` : 'Final Rankings'}
      >
        <div>
          {tournamentStandings.map((s, i) => (
            <StandingsRow
              key={s.player!.id}
              rank={i + 1}
              name={s.player!.name}
              totalPoints={s.total}
              placementPoints={s.placement}
              achievementPoints={s.achievement}
              wins={s.wins}
              mode="tournament"
            />
          ))}
        </div>
        {selectedTournamentId && (
          <div className="px-4 pb-2">
            <DestructiveActionButton
              title="Delete tournament"
              onClick={() => handleDeleteTournament(selectedTournamentId)}
            />
          </div>
        )}
        <ModalActionBar
          primaryTitle="Close"
          primaryAction={() => setShowStandingsModal(false)}
        />
      </Modal>
    </div>
  );
}
