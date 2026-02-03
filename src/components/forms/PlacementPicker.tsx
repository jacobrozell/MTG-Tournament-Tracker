import { cn } from '../../utils';

interface PlacementPickerProps {
  playerName: string;
  value: number | null;
  onChange: (placement: number) => void;
  disabled?: boolean;
}

const placements = [1, 2, 3, 4];
const placementLabels: Record<number, string> = {
  1: 'First place',
  2: 'Second place',
  3: 'Third place',
  4: 'Fourth place',
};

export function PlacementPicker({
  playerName,
  value,
  onChange,
  disabled = false,
}: PlacementPickerProps) {
  return (
    <div className="flex gap-1" role="radiogroup" aria-label={`Placement for ${playerName}`}>
      {placements.map((placement) => (
        <button
          key={placement}
          role="radio"
          aria-checked={value === placement}
          aria-label={placementLabels[placement]}
          onClick={() => !disabled && onChange(placement)}
          disabled={disabled}
          className={cn(
            'flex-1 min-h-[44px] py-2 px-3 rounded-lg font-semibold transition-colors',
            value === placement
              ? 'bg-blue-600 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
            disabled && 'opacity-50 cursor-not-allowed'
          )}
        >
          {placement}
        </button>
      ))}
    </div>
  );
}
