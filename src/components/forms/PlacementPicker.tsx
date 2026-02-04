import { cn } from '../../utils';

interface PlacementPickerProps {
  playerName: string;
  value: number | null;
  onChange: (placement: number | null) => void;
  disabled?: boolean;
}

const options: { value: '' | number; label: string }[] = [
  { value: '', label: '—' },
  { value: 1, label: '1st' },
  { value: 2, label: '2nd' },
  { value: 3, label: '3rd' },
  { value: 4, label: '4th' },
];

export function PlacementPicker({
  playerName,
  value,
  onChange,
  disabled = false,
}: PlacementPickerProps) {
  const selectValue = value ?? '';

  return (
    <select
      aria-label={`Placement for ${playerName}`}
      value={selectValue}
      onChange={(e) => {
        const v = e.target.value;
        onChange(v === '' ? null : Number(v));
      }}
      disabled={disabled}
      className={cn(
        'w-full min-h-[44px] py-2 px-3 rounded-lg font-medium border border-gray-300 bg-white text-gray-900 transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500',
        disabled && 'opacity-50 cursor-not-allowed'
      )}
    >
      {options.map((opt) => (
        <option key={opt.value === '' ? 'none' : opt.value} value={opt.value}>
          {opt.label}
        </option>
      ))}
    </select>
  );
}
