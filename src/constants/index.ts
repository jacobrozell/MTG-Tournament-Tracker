export const AppConstants = {
  UI: {
    minTouchTargetHeight: 44,
  },

  League: {
    weeksRange: { min: 1, max: 99 },
    randomAchievementsPerWeekRange: { min: 0, max: 99 },
    defaultTotalWeeks: 6,
    defaultRandomAchievementsPerWeek: 2,
    roundsPerWeek: 3,
    podSize: 4,
    defaultCurrentWeek: 1,
    defaultCurrentRound: 1,
    defaultAchievementsOnThisWeek: true,
  },

  Scoring: {
    placementPoints: {
      1: 4,
      2: 3,
      3: 2,
      4: 1,
    } as Record<number, number>,
    initialPlacementPoints: 0,
    initialAchievementPoints: 0,
    initialWins: 0,
    initialGamesPlayed: 0,
  },

  DefaultAchievement: {
    name: 'First Blood',
    points: 1,
    alwaysOn: false,
  },
};
