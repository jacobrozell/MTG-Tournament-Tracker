import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Area,
  AreaChart,
} from 'recharts';

export interface LineChartDatum {
  week: number;
  value: number;
  [key: string]: string | number | undefined;
}

interface LineChartCardProps {
  title: string;
  data: LineChartDatum[];
  height?: number;
  xKey?: string;
  yKey?: string;
  showArea?: boolean;
}

function hasNoData(data: LineChartDatum[], yKey: string): boolean {
  if (!data.length) return true;
  return data.every((d) => (Number(d[yKey]) ?? 0) === 0);
}

export function LineChartCard({
  title,
  data,
  height = 180,
  xKey = 'week',
  yKey = 'value',
  showArea = true,
}: LineChartCardProps) {
  const noData = hasNoData(data, yKey);

  if (noData) {
    return (
      <div className="bg-white rounded-xl px-4 py-4 shadow-sm border border-gray-100">
        <h3 className="text-sm font-semibold text-gray-700 mb-2">{title}</h3>
        <div
          className="flex flex-col items-center justify-center text-gray-400"
          style={{ height }}
        >
          <span className="text-4xl opacity-50">📈</span>
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
          {showArea ? (
            <AreaChart data={data} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey={xKey} tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip />
              <Area type="monotone" dataKey={yKey} stroke="#3b82f6" fill="#3b82f6" fillOpacity={0.2} strokeWidth={2} />
            </AreaChart>
          ) : (
            <LineChart data={data} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey={xKey} tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip />
              <Line type="monotone" dataKey={yKey} stroke="#3b82f6" strokeWidth={2} dot={{ r: 3 }} />
            </LineChart>
          )}
        </ResponsiveContainer>
      </div>
    </div>
  );
}
