interface EmptyStateViewProps {
  message: string;
  hint?: string;
}

export function EmptyStateView({ message, hint }: EmptyStateViewProps) {
  return (
    <div className="flex flex-col items-center justify-center py-12 px-4 text-center">
      <p className="text-gray-600 text-lg">{message}</p>
      {hint && <p className="text-gray-400 text-sm mt-2">{hint}</p>}
    </div>
  );
}
