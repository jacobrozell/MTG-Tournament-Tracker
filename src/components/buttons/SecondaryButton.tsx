import { cn } from '../../utils';

interface SecondaryButtonProps {
  title: string;
  onClick: () => void;
  disabled?: boolean;
  ariaLabel?: string;
}

export function SecondaryButton({
  title,
  onClick,
  disabled = false,
  ariaLabel,
}: SecondaryButtonProps) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      aria-label={ariaLabel || title}
      className={cn(
        'w-full min-h-[44px] px-4 py-3 rounded-lg font-semibold transition-colors',
        'border-2 border-gray-300 text-gray-700 bg-white',
        'hover:bg-gray-50 active:bg-gray-100',
        disabled && 'opacity-50 cursor-not-allowed hover:bg-white'
      )}
    >
      {title}
    </button>
  );
}
