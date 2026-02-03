import { Trash2 } from 'lucide-react';

type PlayerRowMode = 'display' | 'removable' | 'toggleable';

interface PlayerRowProps {
  name: string;
  mode: PlayerRowMode;
  subtitle?: string;
  onRemove?: () => void;
  checked?: boolean;
  onToggle?: (checked: boolean) => void;
}

export function PlayerRow({
  name,
  mode,
  subtitle,
  onRemove,
  checked,
  onToggle,
}: PlayerRowProps) {
  if (mode === 'toggleable') {
    return (
      <label className="flex items-center gap-3 min-h-[44px] py-3 px-4 bg-white border-b border-gray-100 cursor-pointer hover:bg-gray-50">
        <input
          type="checkbox"
          checked={checked}
          onChange={(e) => onToggle?.(e.target.checked)}
          className="w-5 h-5 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
        />
        <span className="text-gray-900 font-medium">{name}</span>
      </label>
    );
  }

  if (mode === 'removable') {
    return (
      <div className="flex items-center justify-between min-h-[44px] py-3 px-4 bg-white border-b border-gray-100">
        <span className="text-gray-900 font-medium">{name}</span>
        <button
          onClick={onRemove}
          aria-label={`Remove ${name}`}
          className="w-10 h-10 flex items-center justify-center text-red-500 hover:bg-red-50 rounded-lg transition-colors"
        >
          <Trash2 className="w-5 h-5" />
        </button>
      </div>
    );
  }

  // Display mode
  return (
    <div className="flex items-center justify-between min-h-[44px] py-3 px-4 bg-white border-b border-gray-100">
      <div>
        <span className="text-gray-900 font-medium">{name}</span>
        {subtitle && (
          <p className="text-sm text-gray-500 mt-0.5">{subtitle}</p>
        )}
      </div>
    </div>
  );
}
