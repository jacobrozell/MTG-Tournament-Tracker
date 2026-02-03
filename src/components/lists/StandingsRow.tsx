interface StandingsRowProps {
  rank: number;
  name: string;
  totalPoints: number;
  placementPoints: number;
  achievementPoints: number;
  wins?: number;
  mode: 'weekly' | 'tournament';
}

export function StandingsRow({
  rank,
  name,
  totalPoints,
  placementPoints,
  achievementPoints,
  wins,
  mode,
}: StandingsRowProps) {
  return (
    <div className="flex items-center justify-between min-h-[44px] py-3 px-4 bg-white border-b border-gray-100">
      <div className="flex items-center gap-3">
        <span className="w-8 text-gray-500 font-medium">#{rank}</span>
        <span className="text-gray-900 font-medium">{name}</span>
      </div>
      <div className="text-right">
        <span className="text-gray-900 font-semibold">{totalPoints} pts</span>
        <p className="text-xs text-gray-500 mt-0.5">
          P: {placementPoints} A: {achievementPoints}
          {mode === 'tournament' && wins !== undefined && ` W: ${wins}`}
        </p>
      </div>
    </div>
  );
}
