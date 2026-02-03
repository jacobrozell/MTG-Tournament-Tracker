import { cn } from '../../utils';

interface AchievementCheckItemProps {
  name: string;
  points: number;
  checked: boolean;
  onChange: (checked: boolean) => void;
  disabled?: boolean;
}

export function AchievementCheckItem({
  name,
  points,
  checked,
  onChange,
  disabled = false,
}: AchievementCheckItemProps) {
  return (
    <label
      className={cn(
        'flex items-center gap-3 min-h-[44px] py-2 cursor-pointer',
        disabled && 'opacity-50 cursor-not-allowed'
      )}
    >
      <input
        type="checkbox"
        checked={checked}
        onChange={(e) => !disabled && onChange(e.target.checked)}
        disabled={disabled}
        className="w-5 h-5 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
      />
      <span className="text-gray-900">
        {name} <span className="text-green-600 font-medium">+{points}</span>
      </span>
    </label>
  );
}
