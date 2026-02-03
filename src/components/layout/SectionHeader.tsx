interface SectionHeaderProps {
  title: string;
  subtitle?: string;
}

export function SectionHeader({ title, subtitle }: SectionHeaderProps) {
  return (
    <div className="px-4 py-3 bg-gray-50">
      <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider">
        {title}
      </h3>
      {subtitle && (
        <p className="text-xs text-gray-400 mt-0.5">{subtitle}</p>
      )}
    </div>
  );
}
