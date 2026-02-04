import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type {
  Player,
  Achievement,
  Tournament,
  GameResult,
  Screen,
  WeeklyPlayerPoints,
  PodSnapshot,
  AchievementCheck,
  WeekBoundaryState,
} from '../types';
import { AppConstants } from '../constants';
import { generateId } from '../utils';
import {
  rollActiveAchievements,
  calculatePlacementPoints,
  clampWeeks,
  clampRandomPerWeek,
} from '../engines/leagueEngine';

interface AppState {
  // League State
  activeTournamentId: string | null;
  currentScreen: Screen;

  // Collections
  players: Player[];
  achievements: Achievement[];
  tournaments: Tournament[];
  gameResults: GameResult[];

  // Actions
  setScreen: (screen: Screen) => void;
  setActiveTournament: (id: string | null) => void;

  // Player actions
  addPlayer: (name: string) => Player | null;
  removePlayer: (id: string) => void;

  // Achievement actions
  addAchievement: (name: string, points: number, alwaysOn: boolean) => Achievement | null;
  removeAchievement: (id: string) => void;
  setAchievementAlwaysOn: (id: string, alwaysOn: boolean) => void;

  // Tournament actions
  createTournament: (name: string, totalWeeks: number, randomPerWeek: number, playerIds: string[]) => void;
  selectTournament: (id: string) => void;
  archiveTournament: () => void;
  deleteTournament: (id: string) => void;

  // Attendance actions
  confirmAttendance: (presentIds: string[], achievementsOn: boolean) => void;
  addWeeklyPlayer: (name: string) => Player | null;

  // Pods actions
  updatePlacement: (playerId: string, placement: number | null) => void;
  updateAchievementCheck: (playerId: string, achievementId: string, checked: boolean) => void;
  setCurrentPods: (pods: string[][]) => void;
  nextRound: () => void;
  undoLastPod: () => void;
  
  // Selectors
  getActiveTournament: () => Tournament | null;
  getOngoingTournaments: () => Tournament[];
  getCompletedTournaments: () => Tournament[];
  getPlayerById: (id: string) => Player | undefined;
  getAchievementById: (id: string) => Achievement | undefined;
}

export const useAppStore = create<AppState>()(
  persist(
    (set, get) => ({
      // Initial State
      activeTournamentId: null,
      currentScreen: 'tournaments',
      players: [],
      achievements: [
        {
          id: generateId(),
          name: AppConstants.DefaultAchievement.name,
          points: AppConstants.DefaultAchievement.points,
          alwaysOn: AppConstants.DefaultAchievement.alwaysOn,
        },
      ],
      tournaments: [],
      gameResults: [],

      // Navigation
      setScreen: (screen) => set({ currentScreen: screen }),
      setActiveTournament: (id) => set({ activeTournamentId: id }),

      // Player Actions
      addPlayer: (name) => {
        const trimmedName = name.trim();
        if (!trimmedName) return null;

        const newPlayer: Player = {
          id: generateId(),
          name: trimmedName,
          placementPoints: AppConstants.Scoring.initialPlacementPoints,
          achievementPoints: AppConstants.Scoring.initialAchievementPoints,
          wins: AppConstants.Scoring.initialWins,
          gamesPlayed: AppConstants.Scoring.initialGamesPlayed,
          tournamentsPlayed: 0,
        };

        set((state) => ({ players: [...state.players, newPlayer] }));
        return newPlayer;
      },

      removePlayer: (id) => {
        set((state) => ({
          players: state.players.filter((p) => p.id !== id),
        }));
      },

      // Achievement Actions
      addAchievement: (name, points, alwaysOn) => {
        const trimmedName = name.trim();
        if (!trimmedName) return null;

        const newAchievement: Achievement = {
          id: generateId(),
          name: trimmedName,
          points: Math.min(Math.max(points, 0), 99),
          alwaysOn,
        };

        set((state) => ({
          achievements: [...state.achievements, newAchievement],
        }));
        return newAchievement;
      },

      removeAchievement: (id) => {
        set((state) => ({
          achievements: state.achievements.filter((a) => a.id !== id),
        }));
      },

      setAchievementAlwaysOn: (id, alwaysOn) => {
        set((state) => ({
          achievements: state.achievements.map((a) =>
            a.id === id ? { ...a, alwaysOn } : a
          ),
        }));
      },

      // Tournament Actions
      createTournament: (name, totalWeeks, randomPerWeek, playerIds) => {
        const { achievements, players } = get();
        
        const clampedWeeks = clampWeeks(totalWeeks);
        const clampedRandom = clampRandomPerWeek(randomPerWeek);
        
        const activeAchievements = rollActiveAchievements(achievements, clampedRandom);
        
        const newTournament: Tournament = {
          id: generateId(),
          name: name.trim() || 'New Tournament',
          totalWeeks: clampedWeeks,
          randomAchievementsPerWeek: clampedRandom,
          startDate: new Date().toISOString(),
          endDate: null,
          status: 'ongoing',
          currentWeek: AppConstants.League.defaultCurrentWeek,
          currentRound: AppConstants.League.defaultCurrentRound,
          achievementsOnThisWeek: AppConstants.League.defaultAchievementsOnThisWeek,
          selectedPlayerIds: playerIds,
          presentPlayerIds: [],
          weeklyPointsByPlayer: {},
          activeAchievementIds: activeAchievements.map((a) => a.id),
          roundPlacements: {},
          roundAchievementChecks: [],
          podHistorySnapshots: [],
          currentPods: [],
        };

        // Increment tournamentsPlayed for selected players
        const updatedPlayers = players.map((p) =>
          playerIds.includes(p.id)
            ? { ...p, tournamentsPlayed: p.tournamentsPlayed + 1 }
            : p
        );

        set({
          tournaments: [...get().tournaments, newTournament],
          players: updatedPlayers,
          activeTournamentId: newTournament.id,
          currentScreen: 'attendance',
        });
      },

      selectTournament: (id) => {
        const tournament = get().tournaments.find((t) => t.id === id);
        if (!tournament) return;

        if (tournament.status === 'completed') {
          set({ activeTournamentId: id, currentScreen: 'tournamentStandings' });
        } else {
          set({ activeTournamentId: id, currentScreen: 'attendance' });
        }
      },

      archiveTournament: () => {
        const { activeTournamentId, tournaments } = get();
        if (!activeTournamentId) return;

        set({
          tournaments: tournaments.map((t) =>
            t.id === activeTournamentId
              ? { ...t, status: 'completed', endDate: new Date().toISOString() }
              : t
          ),
          activeTournamentId: null,
          currentScreen: 'tournaments',
        });
      },

      deleteTournament: (id) => {
        const { activeTournamentId, tournaments, gameResults } = get();

        set({
          tournaments: tournaments.filter((t) => t.id !== id),
          gameResults: gameResults.filter((r) => r.tournamentId !== id),
          // Clear active tournament if it was the deleted one
          ...(activeTournamentId === id ? { activeTournamentId: null, currentScreen: 'tournaments' as Screen } : {}),
        });
      },

      // Attendance Actions
      confirmAttendance: (presentIds, achievementsOn) => {
        const { activeTournamentId, tournaments } = get();
        if (!activeTournamentId) return;

        const tournament = tournaments.find((t) => t.id === activeTournamentId);
        if (!tournament) return;

        // Check if we have existing data (placements, pods, or history)
        const hasExistingData =
          Object.keys(tournament.roundPlacements).length > 0 ||
          tournament.currentPods.length > 0 ||
          tournament.podHistorySnapshots.length > 0;

        // Build weeklyPointsByPlayer - preserve existing entries, add new ones
        const weeklyPointsByPlayer: Record<string, WeeklyPlayerPoints> = hasExistingData
          ? { ...tournament.weeklyPointsByPlayer }
          : {};
        
        presentIds.forEach((id) => {
          if (!weeklyPointsByPlayer[id]) {
            weeklyPointsByPlayer[id] = { placementPoints: 0, achievementPoints: 0 };
          }
        });

        set({
          tournaments: tournaments.map((t) =>
            t.id === activeTournamentId
              ? {
                  ...t,
                  presentPlayerIds: presentIds,
                  achievementsOnThisWeek: achievementsOn,
                  // Only reset round state if there's no existing data
                  currentRound: hasExistingData ? t.currentRound : 1,
                  weeklyPointsByPlayer,
                  podHistorySnapshots: hasExistingData ? t.podHistorySnapshots : [],
                  roundPlacements: hasExistingData ? t.roundPlacements : {},
                  roundAchievementChecks: hasExistingData ? t.roundAchievementChecks : [],
                  currentPods: hasExistingData ? t.currentPods : [],
                }
              : t
          ),
          currentScreen: 'pods',
        });
      },

      addWeeklyPlayer: (name) => {
        const { activeTournamentId, tournaments, players } = get();
        const trimmedName = name.trim();
        if (!trimmedName || !activeTournamentId) return null;

        const newPlayer: Player = {
          id: generateId(),
          name: trimmedName,
          placementPoints: 0,
          achievementPoints: 0,
          wins: 0,
          gamesPlayed: 0,
          tournamentsPlayed: 1,
        };

        const tournament = tournaments.find((t) => t.id === activeTournamentId);
        if (!tournament) return null;

        set({
          players: [...players, newPlayer],
          tournaments: tournaments.map((t) =>
            t.id === activeTournamentId
              ? {
                  ...t,
                  presentPlayerIds: [...t.presentPlayerIds, newPlayer.id],
                  weeklyPointsByPlayer: {
                    ...t.weeklyPointsByPlayer,
                    [newPlayer.id]: { placementPoints: 0, achievementPoints: 0 },
                  },
                }
              : t
          ),
        });

        return newPlayer;
      },

      // Pods Actions
      updatePlacement: (playerId, placement) => {
        const { activeTournamentId, tournaments } = get();
        if (!activeTournamentId) return;

        set({
          tournaments: tournaments.map((t) => {
            if (t.id !== activeTournamentId) return t;
            const next = { ...t.roundPlacements };
            if (placement === null) delete next[playerId];
            else next[playerId] = placement;
            return { ...t, roundPlacements: next };
          }),
        });
      },

      updateAchievementCheck: (playerId, achievementId, checked) => {
        const { activeTournamentId, tournaments } = get();
        if (!activeTournamentId) return;

        const key = `${playerId}:${achievementId}`;

        set({
          tournaments: tournaments.map((t) => {
            if (t.id !== activeTournamentId) return t;

            const checks = new Set(t.roundAchievementChecks);
            if (checked) {
              checks.add(key);
            } else {
              checks.delete(key);
            }
            return { ...t, roundAchievementChecks: Array.from(checks) };
          }),
        });
      },

      setCurrentPods: (pods) => {
        const { activeTournamentId, tournaments } = get();
        if (!activeTournamentId) return;

        set({
          tournaments: tournaments.map((t) =>
            t.id === activeTournamentId ? { ...t, currentPods: pods } : t
          ),
        });
      },

      nextRound: () => {
        // Use functional update to ensure we work with fresh state
        set((state) => {
          const { activeTournamentId, tournaments, players, achievements, gameResults } = state;
          if (!activeTournamentId) return state;

          const tournament = tournaments.find((t) => t.id === activeTournamentId);
          if (!tournament) return state;

          // Skip if no placements recorded
          const placementEntries = Object.entries(tournament.roundPlacements);
          if (placementEntries.length === 0) return state;

          const podId = generateId();
          const newGameResults: GameResult[] = [];
          const playerDeltas: Record<string, { placementPoints: number; achievementPoints: number; wins: number; gamesPlayed: number }> = {};
          const weeklyDeltas: Record<string, WeeklyPlayerPoints> = {};
          const achievementChecks: AchievementCheck[] = [];

          // Process each player's placement
          placementEntries.forEach(([playerId, placement]) => {
            const placementPoints = calculatePlacementPoints(placement);
            
            // Get achievement checks for this player
            const playerAchievementIds = tournament.roundAchievementChecks
              .filter((check) => check.startsWith(`${playerId}:`))
              .map((check) => check.split(':')[1]);

            const achievementPoints = tournament.achievementsOnThisWeek
              ? playerAchievementIds.reduce((sum, achId) => {
                  const ach = achievements.find((a) => a.id === achId);
                  return sum + (ach?.points ?? 0);
                }, 0)
              : 0;

            // Store achievement checks for undo
            playerAchievementIds.forEach((achId) => {
              const ach = achievements.find((a) => a.id === achId);
              if (ach) {
                achievementChecks.push({
                  playerId,
                  achievementId: achId,
                  points: ach.points,
                });
              }
            });

            // Create delta for undo
            playerDeltas[playerId] = {
              placementPoints,
              achievementPoints,
              wins: placement === 1 ? 1 : 0,
              gamesPlayed: 1,
            };

            weeklyDeltas[playerId] = {
              placementPoints,
              achievementPoints,
            };

            // Create game result
            newGameResults.push({
              id: generateId(),
              tournamentId: activeTournamentId,
              week: tournament.currentWeek,
              round: tournament.currentRound,
              playerId,
              placement,
              placementPoints,
              achievementPoints,
              achievementIds: playerAchievementIds,
              timestamp: new Date().toISOString(),
              podId,
            });
          });

          // Determine next state early to know if we need week boundary data
          const isLastRound = tournament.currentRound >= AppConstants.League.roundsPerWeek;
          const isFinalWeek = tournament.currentWeek >= tournament.totalWeeks;

          // Create snapshot for undo
          const snapshot: PodSnapshot = {
            podId,
            playerIds: placementEntries.map(([id]) => id),
            placements: { ...tournament.roundPlacements },
            achievementChecks,
            playerDeltas,
            weeklyDeltas,
          };

          // If advancing to next week (not final), store week boundary data for undo
          if (isLastRound && !isFinalWeek) {
            const weekBoundary: WeekBoundaryState = {
              previousWeek: tournament.currentWeek,
              previousPresentPlayerIds: [...tournament.presentPlayerIds],
              previousWeeklyPointsByPlayer: { ...tournament.weeklyPointsByPlayer },
              previousActiveAchievementIds: [...tournament.activeAchievementIds],
              previousAchievementsOnThisWeek: tournament.achievementsOnThisWeek,
              previousPodHistorySnapshots: [...tournament.podHistorySnapshots],
            };
            snapshot.weekBoundary = weekBoundary;
          }

          // Update player cumulative stats (using fresh players from state)
          const updatedPlayers = players.map((p) => {
            const delta = playerDeltas[p.id];
            if (!delta) return p;
            return {
              ...p,
              placementPoints: p.placementPoints + delta.placementPoints,
              achievementPoints: p.achievementPoints + delta.achievementPoints,
              wins: p.wins + delta.wins,
              gamesPlayed: p.gamesPlayed + delta.gamesPlayed,
            };
          });

          // Update weekly points
          const updatedWeeklyPoints = { ...tournament.weeklyPointsByPlayer };
          Object.entries(weeklyDeltas).forEach(([playerId, delta]) => {
            const current = updatedWeeklyPoints[playerId] || { placementPoints: 0, achievementPoints: 0 };
            updatedWeeklyPoints[playerId] = {
              placementPoints: current.placementPoints + delta.placementPoints,
              achievementPoints: current.achievementPoints + delta.achievementPoints,
            };
          });

          let updatedTournament: Tournament;
          let nextScreen: Screen | undefined;

          if (isLastRound && isFinalWeek) {
            // End tournament
            updatedTournament = {
              ...tournament,
              status: 'completed',
              endDate: new Date().toISOString(),
              weeklyPointsByPlayer: updatedWeeklyPoints,
              podHistorySnapshots: [...tournament.podHistorySnapshots, snapshot],
              roundPlacements: {},
              roundAchievementChecks: [],
              currentPods: [],
            };
            nextScreen = 'tournamentStandings';
          } else if (isLastRound) {
            // Advance to next week
            const newActiveAchievements = rollActiveAchievements(
              achievements,
              tournament.randomAchievementsPerWeek
            );

            updatedTournament = {
              ...tournament,
              currentWeek: tournament.currentWeek + 1,
              currentRound: 1,
              presentPlayerIds: [],
              weeklyPointsByPlayer: {},
              activeAchievementIds: newActiveAchievements.map((a) => a.id),
              // Keep the snapshot with weekBoundary data for undo capability
              podHistorySnapshots: [snapshot],
              roundPlacements: {},
              roundAchievementChecks: [],
              currentPods: [],
            };
            nextScreen = 'attendance';
          } else {
            // Next round in same week
            updatedTournament = {
              ...tournament,
              currentRound: tournament.currentRound + 1,
              weeklyPointsByPlayer: updatedWeeklyPoints,
              podHistorySnapshots: [...tournament.podHistorySnapshots, snapshot],
              roundPlacements: {},
              roundAchievementChecks: [],
              currentPods: [],
            };
          }

          return {
            ...state,
            tournaments: tournaments.map((t) => (t.id === activeTournamentId ? updatedTournament : t)),
            players: updatedPlayers,
            gameResults: [...gameResults, ...newGameResults],
            ...(nextScreen ? { currentScreen: nextScreen } : {}),
          };
        });
      },

      undoLastPod: () => {
        // Use functional update to ensure we work with fresh state
        set((state) => {
          const { activeTournamentId, tournaments, players, gameResults } = state;
          if (!activeTournamentId) return state;

          const tournament = tournaments.find((t) => t.id === activeTournamentId);
          if (!tournament || tournament.podHistorySnapshots.length === 0) return state;

          const snapshot = tournament.podHistorySnapshots[tournament.podHistorySnapshots.length - 1];

          // Reverse player cumulative stats
          const updatedPlayers = players.map((p) => {
            const delta = snapshot.playerDeltas[p.id];
            if (!delta) return p;
            return {
              ...p,
              placementPoints: p.placementPoints - delta.placementPoints,
              achievementPoints: p.achievementPoints - delta.achievementPoints,
              wins: p.wins - delta.wins,
              gamesPlayed: p.gamesPlayed - delta.gamesPlayed,
            };
          });

          // Delete corresponding game results
          const filteredResults = gameResults.filter((r) => r.podId !== snapshot.podId);

          let updatedTournament: Tournament;

          // Check if this snapshot has week boundary data (we're undoing a week advancement)
          if (snapshot.weekBoundary) {
            const wb = snapshot.weekBoundary;
            // Restore the previous week's full state
            updatedTournament = {
              ...tournament,
              currentWeek: wb.previousWeek,
              currentRound: AppConstants.League.roundsPerWeek, // Back to last round of previous week
              presentPlayerIds: wb.previousPresentPlayerIds,
              weeklyPointsByPlayer: wb.previousWeeklyPointsByPlayer,
              activeAchievementIds: wb.previousActiveAchievementIds,
              achievementsOnThisWeek: wb.previousAchievementsOnThisWeek,
              podHistorySnapshots: wb.previousPodHistorySnapshots,
              roundPlacements: {},
              roundAchievementChecks: [],
              currentPods: [],
            };
          } else {
            // Normal undo within the same week
            // Reverse weekly points
            const updatedWeeklyPoints = { ...tournament.weeklyPointsByPlayer };
            Object.entries(snapshot.weeklyDeltas).forEach(([playerId, delta]) => {
              const current = updatedWeeklyPoints[playerId];
              if (current) {
                updatedWeeklyPoints[playerId] = {
                  placementPoints: current.placementPoints - delta.placementPoints,
                  achievementPoints: current.achievementPoints - delta.achievementPoints,
                };
              }
            });

            updatedTournament = {
              ...tournament,
              currentRound: tournament.currentRound > 1 ? tournament.currentRound - 1 : tournament.currentRound,
              weeklyPointsByPlayer: updatedWeeklyPoints,
              podHistorySnapshots: tournament.podHistorySnapshots.slice(0, -1),
              roundPlacements: {},
              roundAchievementChecks: [],
              currentPods: [],
            };
          }

          return {
            ...state,
            tournaments: tournaments.map((t) => (t.id === activeTournamentId ? updatedTournament : t)),
            players: updatedPlayers,
            gameResults: filteredResults,
          };
        });
      },

      // Selectors
      getActiveTournament: () => {
        const { activeTournamentId, tournaments } = get();
        return tournaments.find((t) => t.id === activeTournamentId) ?? null;
      },

      getOngoingTournaments: () => {
        return get().tournaments.filter((t) => t.status === 'ongoing');
      },

      getCompletedTournaments: () => {
        return get().tournaments.filter((t) => t.status === 'completed');
      },

      getPlayerById: (id) => {
        return get().players.find((p) => p.id === id);
      },

      getAchievementById: (id) => {
        return get().achievements.find((a) => a.id === id);
      },
    }),
    {
      name: 'budget-league-tracker-storage',
    }
  )
);