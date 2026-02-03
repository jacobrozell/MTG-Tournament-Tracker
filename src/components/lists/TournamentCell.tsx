import { ChevronRight, Trash2 } from 'lucide-react';
import type { Tournament } from '../../types';
import { formatDateRange } from '../../utils';

interface TournamentCellProps {
  tournament: Tournament;
  playerCount: number;
  winnerName?: string;
  onClick: () => void;
  onDelete?: () => void;
}

export function TournamentCell({
  tournament,
  playerCount,
  winnerName,
  onClick,
  onDelete,
}: TournamentCellProps) {
  const isOngoing = tournament.status === 'ongoing';

  const getSubtitle = () => {
    if (isOngoing) {
      return `Week ${tournament.currentWeek} of ${tournament.totalWeeks} - ${playerCount} players`;
    }
    if (winnerName) {
      return `Winner: ${winnerName} - ${tournament.totalWeeks} weeks`;
    }
    return `${tournament.totalWeeks} weeks - ${formatDateRange(tournament.startDate, tournament.endDate)}`;
  };

  return (
    <div
      role="button"
      tabIndex={0}
      onClick={onClick}
      onKeyDown={(e) => e.key === 'Enter' && onClick()}
      className="w-full flex items-center justify-between min-h-[44px] py-3 px-4 bg-white border-b border-gray-100 hover:bg-gray-50 transition-colors text-left cursor-pointer"
    >
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="text-gray-900 font-semibold">{tournament.name}</span>
          {isOngoing && (
            <span className="px-2 py-0.5 text-xs font-medium bg-green-100 text-green-700 rounded-full">
              Active
            </span>
          )}
        </div>
        <p className="text-sm text-gray-500 mt-0.5">{getSubtitle()}</p>
      </div>
      <div className="flex items-center gap-1 shrink-0">
        {onDelete && (
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              onDelete();
            }}
            aria-label="Delete tournament"
            className="p-1.5 rounded text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors"
          >
            <Trash2 className="w-5 h-5" />
          </button>
        )}
        <ChevronRight className="w-5 h-5 text-gray-400" />
      </div>
    </div>
  );
}
