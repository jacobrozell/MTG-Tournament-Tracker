import { Trash2 } from 'lucide-react';
import { cn } from '../../utils';

interface AchievementListRowTopPlayer {
  playerName: string;
  count: number;
}

interface AchievementListRowProps {
  name: string;
  points: number;
  alwaysOn: boolean;
  onToggleAlwaysOn: (alwaysOn: boolean) => void;
  onRemove: () => void;
  timesEarned?: number;
  topPlayers?: AchievementListRowTopPlayer[];
}

export function AchievementListRow({
  name,
  points,
  alwaysOn,
  onToggleAlwaysOn,
  onRemove,
  timesEarned,
  topPlayers,
}: AchievementListRowProps) {
  const hasStats = timesEarned !== undefined || (topPlayers && topPlayers.length > 0);

  return (
    <div className="flex items-center justify-between min-h-[44px] py-3 px-4 bg-white border-b border-gray-100">
      <div className="flex items-center gap-3 flex-1 min-w-0">
        <div className="min-w-0">
          <span className="text-gray-900 font-medium">{name}</span>
          <span className="ml-2 px-2 py-0.5 text-xs font-medium bg-blue-100 text-blue-700 rounded-full">
            {points} pts
          </span>
          {hasStats && (
            <p className="text-sm text-gray-500 mt-1">
              {timesEarned !== undefined && (
                <>Earned {timesEarned} time{timesEarned !== 1 ? 's' : ''}</>
              )}
              {timesEarned !== undefined && topPlayers && topPlayers.length > 0 && ' · '}
              {topPlayers && topPlayers.length > 0 && (
                <>Top: {topPlayers.map((p) => `${p.playerName} (${p.count})`).join(', ')}</>
              )}
            </p>
          )}
        </div>
      </div>
      <div className="flex items-center gap-2">
        <button
          onClick={() => onToggleAlwaysOn(!alwaysOn)}
          className={cn(
            'px-3 py-1.5 text-xs font-medium rounded-full transition-colors',
            alwaysOn
              ? 'bg-green-100 text-green-700'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          )}
        >
          {alwaysOn ? 'Always on' : 'Random'}
        </button>
        <button
          onClick={onRemove}
          aria-label={`Remove ${name}`}
          className="w-10 h-10 flex items-center justify-center text-red-500 hover:bg-red-50 rounded-lg transition-colors"
        >
          <Trash2 className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
}
