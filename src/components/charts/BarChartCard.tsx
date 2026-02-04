import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';

export interface BarChartDatum {
  id?: string;
  label: string;
  value?: number;
  [key: string]: string | number | undefined;
}

interface BarChartCardProps {
  title: string;
  data: BarChartDatum[];
  height?: number;
  /** Grouped bars: two bars per label (e.g. placement + achievement) */
  grouped?: boolean;
  primaryKey?: string;
  secondaryKey?: string;
  primaryLabel?: string;
  secondaryLabel?: string;
  /** Single bar data key when not grouped */
  valueKey?: string;
}

function hasNoData(data: BarChartDatum[], grouped: boolean, primaryKey?: string, secondaryKey?: string): boolean {
  if (!data.length) return true;
  if (grouped && primaryKey != null && secondaryKey != null) {
    const allZero = data.every(
      (d) => (Number(d[primaryKey]) ?? 0) === 0 && (Number(d[secondaryKey]) ?? 0) === 0
    );
    return allZero;
  }
  const key = primaryKey ?? 'value';
  return data.every((d) => (Number(d[key]) ?? 0) === 0);
}

export function BarChartCard({
  title,
  data,
  height = 200,
  grouped = false,
  primaryKey = 'placement',
  secondaryKey = 'achievement',
  primaryLabel = 'Placement',
  secondaryLabel = 'Achievement',
  valueKey = 'value',
}: BarChartCardProps) {
  const noData = hasNoData(data, grouped, grouped ? primaryKey : undefined, grouped ? secondaryKey : undefined);

  if (noData) {
    return (
      <div className="bg-white rounded-xl px-4 py-4 shadow-sm border border-gray-100">
        <h3 className="text-sm font-semibold text-gray-700 mb-2">{title}</h3>
        <div
          className="flex flex-col items-center justify-center text-gray-400"
          style={{ height }}
        >
          <span className="text-4xl opacity-50">📊</span>
          <p className="text-sm mt-2">No data yet</p>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-xl px-4 py-4 shadow-sm border border-gray-100">
      <h3 className="text-sm font-semibold text-gray-700 mb-2">{title}</h3>
      <div style={{ height }}>
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis dataKey="label" tick={{ fontSize: 12 }} />
            <YAxis tick={{ fontSize: 12 }} />
            <Tooltip />
            {grouped ? (
              <>
                <Legend />
                <Bar dataKey={primaryKey} name={primaryLabel} fill="#3b82f6" radius={[2, 2, 0, 0]} />
                <Bar dataKey={secondaryKey} name={secondaryLabel} fill="#8b5cf6" radius={[2, 2, 0, 0]} />
              </>
            ) : (
              <Bar dataKey={valueKey} fill="#3b82f6" radius={[2, 2, 0, 0]} />
            )}
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
