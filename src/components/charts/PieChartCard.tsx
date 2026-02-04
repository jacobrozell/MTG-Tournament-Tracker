import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend } from 'recharts';

export interface PieChartDatum {
  name: string;
  value: number;
}

const PLACEMENT_COLORS = ['#3b82f6', '#6b7280', '#f59e0b', '#ef4444'];

interface PieChartCardProps {
  title: string;
  data: PieChartDatum[];
  height?: number;
  donut?: boolean;
}

function hasNoData(data: PieChartDatum[]): boolean {
  if (!data.length) return true;
  return data.every((d) => d.value === 0);
}

export function PieChartCard({
  title,
  data,
  height = 200,
  donut = true,
}: PieChartCardProps) {
  const noData = hasNoData(data);

  if (noData) {
    return (
      <div className="bg-white rounded-xl px-4 py-4 shadow-sm border border-gray-100">
        <h3 className="text-sm font-semibold text-gray-700 mb-2">{title}</h3>
        <div
          className="flex flex-col items-center justify-center text-gray-400"
          style={{ height }}
        >
          <span className="text-4xl opacity-50">🥧</span>
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
          <PieChart>
            <Pie
              data={data}
              dataKey="value"
              nameKey="name"
              cx="50%"
              cy="50%"
              innerRadius={donut ? '60%' : 0}
              outerRadius="80%"
              paddingAngle={1}
              label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
            >
              {data.map((_, index) => (
                <Cell key={index} fill={PLACEMENT_COLORS[index % PLACEMENT_COLORS.length]} />
              ))}
            </Pie>
            <Tooltip />
            <Legend />
          </PieChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
