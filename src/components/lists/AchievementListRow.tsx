import { Trash2 } from 'lucide-react';
import { cn } from '../../utils';

interface AchievementListRowProps {
  name: string;
  points: number;
  alwaysOn: boolean;
  onToggleAlwaysOn: (alwaysOn: boolean) => void;
  onRemove: () => void;
}

export function AchievementListRow({
  name,
  points,
  alwaysOn,
  onToggleAlwaysOn,
  onRemove,
}: AchievementListRowProps) {
  return (
    <div className="flex items-center justify-between min-h-[44px] py-3 px-4 bg-white border-b border-gray-100">
      <div className="flex items-center gap-3 flex-1">
        <div>
          <span className="text-gray-900 font-medium">{name}</span>
          <span className="ml-2 px-2 py-0.5 text-xs font-medium bg-blue-100 text-blue-700 rounded-full">
            {points} pts
          </span>
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
