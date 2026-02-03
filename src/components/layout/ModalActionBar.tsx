import { PrimaryActionButton, SecondaryButton } from '../buttons';

interface ModalActionBarProps {
  primaryTitle: string;
  primaryAction: () => void;
  secondaryTitle?: string;
  secondaryAction?: () => void;
  primaryDisabled?: boolean;
}

export function ModalActionBar({
  primaryTitle,
  primaryAction,
  secondaryTitle,
  secondaryAction,
  primaryDisabled = false,
}: ModalActionBarProps) {
  return (
    <div className="sticky bottom-0 bg-white border-t border-gray-200 p-4 flex gap-3">
      {secondaryTitle && secondaryAction && (
        <div className="flex-1">
          <SecondaryButton title={secondaryTitle} onClick={secondaryAction} />
        </div>
      )}
      <div className="flex-1">
        <PrimaryActionButton
          title={primaryTitle}
          onClick={primaryAction}
          disabled={primaryDisabled}
        />
      </div>
    </div>
  );
}
