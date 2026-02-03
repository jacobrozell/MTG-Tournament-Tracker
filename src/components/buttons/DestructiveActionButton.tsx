import { cn } from '../../utils';

interface DestructiveActionButtonProps {
  title: string;
  onClick: () => void;
  disabled?: boolean;
  ariaLabel?: string;
}

export function DestructiveActionButton({
  title,
  onClick,
  disabled = false,
  ariaLabel,
}: DestructiveActionButtonProps) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      aria-label={ariaLabel || title}
      className={cn(
        'w-full min-h-[44px] px-4 py-3 rounded-lg font-semibold text-white transition-colors',
        'bg-red-600 hover:bg-red-700 active:bg-red-800',
        disabled && 'opacity-50 cursor-not-allowed hover:bg-red-600'
      )}
    >
      {title}
    </button>
  );
}
