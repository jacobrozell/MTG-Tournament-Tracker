import { useState, useMemo, useCallback, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, ChevronDown } from 'lucide-react';
import { useAppStore } from '../stores/useAppStore';
import { PageHeader, SectionHeader, EmptyStateView, HintText, Modal, ModalActionBar, TabButton } from '../components/layout';
import { PrimaryActionButton, SecondaryButton } from '../components/buttons';
import { PlacementPicker, AchievementCheckItem, LabeledToggle } from '../components/forms';
import { StandingsRow } from '../components/lists';
import { generatePodsForRound } from '../engines/leagueEngine';
import { sortByWeeklyPoints } from '../engines/statsEngine';
import type { Player } from '../types';

type Tab = 'attendance' | 'pods' | 'standings';

export function TournamentDetailPage() {
  const navigate = useNavigate();
  const {
    players,
    achievements,
    gameResults,
    getActiveTournament,
    setActiveTournament,
    setScreen,
    confirmAttendance,
    addWeeklyPlayer,
    updatePlacement,
    updateAchievementCheck,
    setCurrentPods,
    nextRound,
    undoLastPod,
  } = useAppStore();

  const tournament = getActiveTournament();
  
  // Tab state - start on attendance if no present players
  const [activeTab, setActiveTab] = useState<Tab>('attendance');
  const [showFinalStandingsModal, setShowFinalStandingsModal] = useState(false);
  const [selectedWeek, setSelectedWeek] = useState<number | 'overall'>('overall');
  
  // Attendance state
  const [presentIds, setPresentIds] = useState<Set<string>>(new Set());
  const [achievementsOn, setAchievementsOn] = useState(true);
  const [newPlayerName, setNewPlayerName] = useState('');
  const initializedForRef = useRef<string | null>(null);

  // Tournament week key for initialization
  const tournamentWeekKey = tournament ? `${tournament.id}-${tournament.currentWeek}` : null;

  // Players for this tournament
  const tournamentPlayers = useMemo(() => {
    if (!tournament) return [];
    const ids = new Set([
      ...(tournament.selectedPlayerIds || []),
      ...(tournament.presentPlayerIds || []),
    ]);
    return players.filter((p) => ids.has(p.id));
  }, [players, tournament]);

  // Initialize attendance state once per tournament week
  useEffect(() => {
    if (!tournamentWeekKey || !tournament || initializedForRef.current === tournamentWeekKey) return;
    if (tournamentPlayers.length === 0) return;
    initializedForRef.current = tournamentWeekKey;
    setPresentIds(new Set(tournament.presentPlayerIds.length > 0 
      ? tournament.presentPlayerIds 
      : tournamentPlayers.map((p) => p.id)));
    setAchievementsOn(tournament.achievementsOnThisWeek);
    
    // Auto-select pods tab if attendance already confirmed
    if (tournament.presentPlayerIds.length > 0) {
      setActiveTab('pods');
    }
  }, [tournamentPlayers, tournamentWeekKey, tournament]);

  // Show final standings modal when tournament completes
  useEffect(() => {
    if (tournament?.status === 'completed') {
      setShowFinalStandingsModal(true);
    }
  }, [tournament?.status]);

  // Pod data
  const pods = useMemo(() => {
    if (!tournament) return [];
    return (tournament.currentPods || []).map((podIds) =>
      podIds.map((id) => players.find((p) => p.id === id)).filter((p): p is Player => p !== undefined)
    );
  }, [tournament, players]);

  const activeAchievements = useMemo(() => {
    if (!tournament) return [];
    return achievements.filter((a) => tournament.activeAchievementIds.includes(a.id));
  }, [tournament, achievements]);

  const weeklyStandings = useMemo(() => {
    if (!tournament) return [];
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
  }, [tournament, players]);

  // Final tournament standings
  const finalStandings = useMemo(() => {
    if (!tournament) return [];
    const tournamentResults = gameResults.filter((r) => r.tournamentId === tournament.id);
    
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
  }, [tournament, gameResults, players]);

  // Standings for a specific week (past or current) from gameResults
  const standingsForWeek = useMemo(() => {
    if (!tournament || selectedWeek === 'overall') return [];
    const weekResults = gameResults.filter(
      (r) => r.tournamentId === tournament.id && r.week === selectedWeek
    );
    const byPlayer: Record<string, { placement: number; achievement: number }> = {};
    weekResults.forEach((r) => {
      if (!byPlayer[r.playerId]) byPlayer[r.playerId] = { placement: 0, achievement: 0 };
      byPlayer[r.playerId].placement += r.placementPoints;
      byPlayer[r.playerId].achievement += r.achievementPoints;
    });
    return Object.entries(byPlayer)
      .map(([playerId, stats]) => ({
        player: players.find((p) => p.id === playerId),
        ...stats,
        total: stats.placement + stats.achievement,
      }))
      .filter((s) => s.player)
      .sort((a, b) => b.total - a.total);
  }, [tournament, gameResults, players, selectedWeek]);

  const achievementChecksSet = useMemo(
    () => (tournament ? new Set(tournament.roundAchievementChecks) : new Set<string>()),
    [tournament]
  );

  const isAchievementChecked = useCallback(
    (playerId: string, achievementId: string) => {
      return achievementChecksSet.has(`${playerId}:${achievementId}`);
    },
    [achievementChecksSet]
  );

  const handleBack = () => {
    setScreen('tournaments');
    setActiveTournament(null);
    navigate('/');
  };

  // Attendance handlers
  const handleConfirmAttendance = () => {
    if (presentIds.size === 0) return;
    confirmAttendance(Array.from(presentIds), achievementsOn);
    setActiveTab('pods');
  };

  const handleAddPlayer = () => {
    if (!newPlayerName.trim()) return;
    const player = addWeeklyPlayer(newPlayerName);
    if (player) {
      setPresentIds((prev) => new Set([...prev, player.id]));
      setNewPlayerName('');
    }
  };

  const togglePlayer = (id: string, checked: boolean) => {
    setPresentIds((prev) => {
      const next = new Set(prev);
      if (checked) next.add(id);
      else next.delete(id);
      return next;
    });
  };

  // Pods handlers
  const handleGenerate = () => {
    if (!tournament) return;
    const newPods = generatePodsForRound(
      players,
      tournament.presentPlayerIds,
      tournament.currentRound,
      tournament.weeklyPointsByPlayer
    );
    setCurrentPods(newPods.map((pod) => pod.map((p) => p.id)));
  };

  const handleNextRound = () => {
    nextRound();
  };

  const handleUndo = () => {
    undoLastPod();
  };

  const handleCloseFinalStandings = () => {
    setShowFinalStandingsModal(false);
    setScreen('tournaments');
    setActiveTournament(null);
    navigate('/');
  };

  if (!tournament) {
    return (
      <div className="flex-1 flex flex-col min-h-0 bg-gray-50">
        <PageHeader title="Tournament" onBack={handleBack} />
        <div className="flex-1 flex items-center justify-center">
          <EmptyStateView message="Tournament not found" />
        </div>
      </div>
    );
  }

  const canGenerate = tournament.presentPlayerIds.length >= 1;
  const canUndo = tournament.podHistorySnapshots.length > 0;
  const hasAnyPlacement = Object.keys(tournament.roundPlacements).length > 0;
  const isCompleted = tournament.status === 'completed';

  return (
    <div className="flex-1 flex flex-col min-h-0 bg-gray-50">
      <PageHeader 
        title={tournament.name}
        onBack={handleBack}
      />

      {/* Tournament Info Bar */}
      <div className="bg-white border-b border-gray-200 px-4 py-2">
        <div className="flex items-center justify-between text-sm">
          <span className="text-gray-600">
            Week {tournament.currentWeek} of {tournament.totalWeeks}
          </span>
          <span className="text-gray-600">
            Round {tournament.currentRound} of 3
          </span>
          {isCompleted && (
            <span className="px-2 py-0.5 bg-green-100 text-green-700 rounded text-xs font-medium">
              Completed
            </span>
          )}
        </div>
      </div>

      {/* Tab Navigation */}
      {!isCompleted && (
        <div className="flex bg-white border-b border-gray-200">
          <TabButton 
            label="Attendance" 
            active={activeTab === 'attendance'} 
            onClick={() => setActiveTab('attendance')} 
          />
          <TabButton 
            label="Pods" 
            active={activeTab === 'pods'} 
            onClick={() => setActiveTab('pods')}
            disabled={tournament.presentPlayerIds.length === 0}
          />
          <TabButton 
            label="Standings" 
            active={activeTab === 'standings'} 
            onClick={() => setActiveTab('standings')} 
          />
        </div>
      )}

      <div className="flex-1 min-h-0 overflow-y-auto">
        {/* ATTENDANCE TAB */}
        {activeTab === 'attendance' && !isCompleted && (
          <>
            <SectionHeader title="This Week" />
            <div className="bg-white px-4">
              <LabeledToggle
                title="Count achievements this week"
                checked={achievementsOn}
                onChange={setAchievementsOn}
              />
            </div>

            <SectionHeader title={`Players (${presentIds.size} present)`} />
            <div className="bg-white">
              {tournamentPlayers.map((p) => (
                <label
                  key={p.id}
                  className="flex items-center gap-3 px-4 py-3 border-b border-gray-100 cursor-pointer hover:bg-gray-50"
                >
                  <input
                    type="checkbox"
                    checked={presentIds.has(p.id)}
                    onChange={(e) => togglePlayer(p.id, e.target.checked)}
                    className="w-5 h-5 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span className="text-gray-900 font-medium">{p.name}</span>
                </label>
              ))}

              <div className="flex gap-2 p-4 border-t border-gray-200">
                <input
                  type="text"
                  value={newPlayerName}
                  onChange={(e) => setNewPlayerName(e.target.value)}
                  placeholder="Add player this week"
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

            <div className="p-4">
              <PrimaryActionButton
                title="Confirm Attendance"
                onClick={handleConfirmAttendance}
                disabled={presentIds.size === 0}
              />
            </div>
          </>
        )}

        {/* PODS TAB */}
        {activeTab === 'pods' && !isCompleted && (
          <>
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
                <HintText message="No players present. Go to Attendance tab to mark players present." />
              )}
            </div>

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
          </>
        )}

        {/* STANDINGS TAB / COMPLETED VIEW */}
        {(activeTab === 'standings' || isCompleted) && (() => {
          const isOverall = selectedWeek === 'overall';
          const isCurrentWeek = selectedWeek === tournament.currentWeek;
          const sectionTitle = isOverall
            ? 'Tournament Standings'
            : `Week ${selectedWeek} Standings`;
          const weekStandings =
            isCurrentWeek ? weeklyStandings : standingsForWeek;
          const displayList = isOverall
            ? finalStandings
            : weekStandings;
          const isEmpty = isOverall
            ? finalStandings.length === 0
            : weekStandings.length === 0;
          return (
            <>
              <div className="flex items-center justify-between gap-2 px-4 py-3 bg-gray-50 border-b border-gray-200">
                <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider">
                  {sectionTitle}
                </h3>
                <label className="flex items-center gap-1 text-sm text-gray-600 shrink-0">
                  <span>View by week</span>
                  <select
                    value={selectedWeek}
                    onChange={(e) => {
                      const v = e.target.value;
                      setSelectedWeek(v === 'overall' ? 'overall' : Number(v));
                    }}
                    className="py-1.5 pl-2 pr-6 border border-gray-300 rounded-md text-gray-800 bg-white focus:ring-blue-500 focus:border-blue-500 text-sm"
                  >
                    <option value="overall">Tournament</option>
                    {Array.from({ length: tournament.totalWeeks }, (_, i) => i + 1).map((w) => (
                      <option key={w} value={w} disabled={!isCompleted && w > tournament.currentWeek}>
                        Week {w}
                      </option>
                    ))}
                  </select>
                  <ChevronDown className="w-4 h-4 text-gray-400 -ml-5 pointer-events-none" />
                </label>
              </div>
              {isEmpty ? (
                <div className="bg-white p-4">
                  <p className="text-gray-500 text-center">
                    {isOverall ? 'No games played yet' : 'No results yet'}
                  </p>
                </div>
              ) : isOverall ? (
                <div className="bg-white">
                  {displayList.map((s, i) => {
                    const pp = 'placementPoints' in s ? s.placementPoints : s.placement;
                    const ap = 'achievementPoints' in s ? s.achievementPoints : s.achievement;
                    const wins: number | undefined = 'wins' in s ? (s as { wins: number }).wins : undefined;
                    return (
                      <StandingsRow
                        key={s.player!.id}
                        rank={i + 1}
                        name={s.player!.name}
                        totalPoints={s.total}
                        placementPoints={pp}
                        achievementPoints={ap}
                        wins={wins}
                        mode="tournament"
                      />
                    );
                  })}
                </div>
              ) : (
                <div className="bg-white">
                  {displayList.map((s, i) => {
                    const pp = 'placementPoints' in s ? s.placementPoints : s.placement;
                    const ap = 'achievementPoints' in s ? s.achievementPoints : s.achievement;
                    return (
                      <StandingsRow
                        key={s.player?.id ?? i}
                        rank={i + 1}
                        name={s.player?.name ?? 'Unknown'}
                        totalPoints={s.total}
                        placementPoints={pp}
                        achievementPoints={ap}
                        mode="weekly"
                      />
                    );
                  })}
                </div>
              )}
            </>
          );
        })()}
      </div>

      {/* Final Standings Modal (shown when tournament completes) */}
      <Modal
        isOpen={showFinalStandingsModal}
        onClose={handleCloseFinalStandings}
        title={`${tournament.name} - Final Rankings`}
      >
        <div>
          {finalStandings.map((s, i) => (
            <StandingsRow
              key={s.player!.id}
              rank={i + 1}
              name={s.player!.name}
              totalPoints={s.total}
              placementPoints={s.placement}
              achievementPoints={s.achievement}
              wins={s.wins ?? 0}
              mode="tournament"
            />
          ))}
        </div>
        <ModalActionBar
          primaryTitle="Close"
          primaryAction={handleCloseFinalStandings}
        />
      </Modal>
    </div>
  );
}
