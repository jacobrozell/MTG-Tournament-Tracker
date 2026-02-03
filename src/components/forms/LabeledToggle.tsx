import { cn } from '../../utils';

interface LabeledToggleProps {
  title: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
}

export function LabeledToggle({ title, checked, onChange }: LabeledToggleProps) {
  return (
    <label className="flex items-center justify-between min-h-[44px] py-2 cursor-pointer">
      <span className="text-gray-900 font-medium">{title}</span>
      <button
        role="switch"
        aria-checked={checked}
        onClick={() => onChange(!checked)}
        className={cn(
          'relative w-12 h-7 rounded-full transition-colors',
          checked ? 'bg-blue-600' : 'bg-gray-300'
        )}
      >
        <span
          className={cn(
            'absolute top-0.5 left-0.5 w-6 h-6 bg-white rounded-full shadow transition-transform',
            checked && 'translate-x-5'
          )}
        />
      </button>
    </label>
  );
}
