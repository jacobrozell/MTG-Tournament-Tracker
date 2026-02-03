import { cn } from '../../utils';

interface PrimaryActionButtonProps {
  title: string;
  onClick: () => void;
  disabled?: boolean;
  ariaLabel?: string;
}

export function PrimaryActionButton({
  title,
  onClick,
  disabled = false,
  ariaLabel,
}: PrimaryActionButtonProps) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      aria-label={ariaLabel || title}
      className={cn(
        'w-full min-h-[44px] px-4 py-3 rounded-lg font-semibold text-white transition-colors',
        'bg-blue-600 hover:bg-blue-700 active:bg-blue-800',
        disabled && 'opacity-50 cursor-not-allowed hover:bg-blue-600'
      )}
    >
      {title}
    </button>
  );
}
