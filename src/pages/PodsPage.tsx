import { useState, useMemo } from 'react';
import { useAppStore } from '../stores/useAppStore';
import { PageHeader, SectionHeader, EmptyStateView, HintText, Modal, ModalActionBar } from '../components/layout';
import { PrimaryActionButton, SecondaryButton } from '../components/buttons';
import { PlacementPicker, AchievementCheckItem } from '../components/forms';
import { StandingsRow } from '../components/lists';
import { generatePodsForRound } from '../engines/leagueEngine';
import { sortByWeeklyPoints } from '../engines/statsEngine';
import type { Player } from '../types';

export function PodsPage() {
  const {
    players,
    achievements,
    getActiveTournament,
    updatePlacement,
    updateAchievementCheck,
    nextRound,
    undoLastPod,
    setScreen,
  } = useAppStore();

  const tournament = getActiveTournament();
  const [pods, setPods] = useState<Player[][]>([]);
  const [showStandingsModal, setShowStandingsModal] = useState(false);

  const activeAchievements = useMemo(() => {
    if (!tournament) return [];
    return achievements.filter((a) => tournament.activeAchievementIds.includes(a.id));
  }, [tournament, achievements]);

  if (!tournament) {
    return (
      <div className="flex-1 flex items-center justify-center p-4">
        <EmptyStateView message="No tournament in progress" />
      </div>
    );
  }

  const handleGenerate = () => {
    const newPods = generatePodsForRound(
      players,
      tournament.presentPlayerIds,
      tournament.currentRound,
      tournament.weeklyPointsByPlayer
    );
    setPods(newPods);

    // Initialize placements (empty)
    // Placements are stored in tournament.roundPlacements
  };

  const handleNextRound = () => {
    nextRound();
    setPods([]); // Clear pods for next round
  };

  const handleUndo = () => {
    undoLastPod();
    setPods([]);
  };

  const canGenerate = tournament.presentPlayerIds.length >= 1;
  const canUndo = tournament.podHistorySnapshots.length > 0;
  const hasAnyPlacement = Object.keys(tournament.roundPlacements).length > 0;

  const getWeeklyStandings = () => {
    const sortedIds = sortByWeeklyPoints(
      tournament.presentPlayerIds,
      tournament.weeklyPointsByPlayer
    );

    return sortedIds.map((id) => {
      const player = players.find((p) => p.id === id);
      const weekly = tournament.weeklyPointsByPlayer[id] || { placementPoints: 0, achievementPoints: 0 };
      return {
        player,
        ...weekly,
        total: weekly.placementPoints + weekly.achievementPoints,
      };
    });
  };

  const isAchievementChecked = (playerId: string, achievementId: string) => {
    return tournament.roundAchievementChecks.includes(`${playerId}:${achievementId}`);
  };

  const handleBack = () => {
    setScreen('attendance');
  };

  return (
    <div className="flex-1 flex flex-col bg-gray-50">
      <PageHeader title={`Pods - Round ${tournament.currentRound}`} onBack={handleBack} />

      <div className="flex-1 min-h-0 overflow-y-auto">
        {/* Actions */}
        <div className="p-4 space-y-2 bg-white border-b border-gray-200">
          <PrimaryActionButton
            title="Generate Pods"
            onClick={handleGenerate}
            disabled={!canGenerate}
          />
          <div className="flex gap-2">
            <div className="flex-1">
              <SecondaryButton
                title="Next Round"
                onClick={handleNextRound}
                disabled={!hasAnyPlacement}
              />
            </div>
            <div className="flex-1">
              <SecondaryButton
                title="Undo Last"
                onClick={handleUndo}
                disabled={!canUndo}
              />
            </div>
          </div>
          {!canGenerate && (
            <HintText message="No players present. Go to Attendance to mark players present." />
          )}
        </div>

        {/* Weekly Standings */}
        {tournament.presentPlayerIds.length > 0 && (
          <>
            <SectionHeader
              title={`Week ${tournament.currentWeek} Standings`}
              subtitle={tournament.name}
            />
            {getWeeklyStandings().slice(0, 5).map((s, i) => (
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
            {getWeeklyStandings().length > 5 && (
              <button
                onClick={() => setShowStandingsModal(true)}
                className="w-full py-2 text-blue-600 text-sm font-medium hover:bg-gray-50"
              >
                View all {getWeeklyStandings().length} players
              </button>
            )}
          </>
        )}

        {/* Pods */}
        {pods.length === 0 ? (
          <div className="p-8">
            <EmptyStateView
              message="No pods generated"
              hint="Click 'Generate Pods' to create pods for this round"
            />
          </div>
        ) : (
          pods.map((pod, podIndex) => (
            <div key={podIndex}>
              <SectionHeader title={`Pod ${podIndex + 1}`} />
              <div className="bg-white">
                {pod.map((player) => (
                  <div
                    key={player.id}
                    className="px-4 py-3 border-b border-gray-100"
                  >
                    <div className="font-medium text-gray-900 mb-2">
                      {player.name}
                    </div>
                    <PlacementPicker
                      playerName={player.name}
                      value={tournament.roundPlacements[player.id] || null}
                      onChange={(placement) => updatePlacement(player.id, placement)}
                    />
                    {tournament.achievementsOnThisWeek && activeAchievements.length > 0 && (
                      <div className="mt-2 pl-1">
                        {activeAchievements.map((ach) => (
                          <AchievementCheckItem
                            key={ach.id}
                            name={ach.name}
                            points={ach.points}
                            checked={isAchievementChecked(player.id, ach.id)}
                            onChange={(checked) =>
                              updateAchievementCheck(player.id, ach.id, checked)
                            }
                          />
                        ))}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          ))
        )}
      </div>

      {/* Full Standings Modal */}
      <Modal
        isOpen={showStandingsModal}
        onClose={() => setShowStandingsModal(false)}
        title={`Week ${tournament.currentWeek} Standings`}
      >
        <div>
          {getWeeklyStandings().map((s, i) => (
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
        </div>
        <ModalActionBar
          primaryTitle="Close"
          primaryAction={() => setShowStandingsModal(false)}
        />
      </Modal>
    </div>
  );
}
