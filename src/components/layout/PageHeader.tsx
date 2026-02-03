import { Plus, ChevronLeft } from 'lucide-react';

interface PageHeaderProps {
  title: string;
  onAdd?: () => void;
  onBack?: () => void;
}

export function PageHeader({ title, onAdd, onBack }: PageHeaderProps) {
  return (
    <div className="flex items-center justify-between p-4 border-b border-gray-200 bg-white">
      <div className="flex items-center gap-2">
        {onBack && (
          <button
            onClick={onBack}
            aria-label="Go back"
            className="w-10 h-10 flex items-center justify-center text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ChevronLeft className="w-6 h-6" />
          </button>
        )}
        <h1 className="text-2xl font-bold text-gray-900">{title}</h1>
      </div>
      {onAdd && (
        <button
          onClick={onAdd}
          aria-label="Add new"
          className="w-10 h-10 flex items-center justify-center text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
        >
          <Plus className="w-6 h-6" />
        </button>
      )}
    </div>
  );
}
