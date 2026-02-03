import { Minus, Plus } from 'lucide-react';
import { cn } from '../../utils';

interface LabeledStepperProps {
  title: string;
  value: number;
  onChange: (value: number) => void;
  min: number;
  max: number;
}

export function LabeledStepper({
  title,
  value,
  onChange,
  min,
  max,
}: LabeledStepperProps) {
  const canDecrement = value > min;
  const canIncrement = value < max;

  return (
    <div className="flex items-center justify-between min-h-[44px] py-2">
      <span className="text-gray-900 font-medium">
        {title}: {value}
      </span>
      <div className="flex items-center gap-2">
        <button
          onClick={() => canDecrement && onChange(value - 1)}
          disabled={!canDecrement}
          aria-label={`Decrease ${title}`}
          className={cn(
            'w-10 h-10 flex items-center justify-center rounded-lg transition-colors',
            'bg-gray-100 hover:bg-gray-200 active:bg-gray-300',
            !canDecrement && 'opacity-50 cursor-not-allowed hover:bg-gray-100'
          )}
        >
          <Minus className="w-5 h-5" />
        </button>
        <button
          onClick={() => canIncrement && onChange(value + 1)}
          disabled={!canIncrement}
          aria-label={`Increase ${title}`}
          className={cn(
            'w-10 h-10 flex items-center justify-center rounded-lg transition-colors',
            'bg-gray-100 hover:bg-gray-200 active:bg-gray-300',
            !canIncrement && 'opacity-50 cursor-not-allowed hover:bg-gray-100'
          )}
        >
          <Plus className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
}
