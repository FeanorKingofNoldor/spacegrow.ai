// types/chart.ts
import { DeviceSensor } from './device';

export type ChartMode = 'live' | 'history_24h' | 'history_7d' | 'history_3m';

export interface ChartDataPoint {
  timestamp: string;
  value: number;
}

export interface GaugeZone {
  min: number;
  max: number;
  color: string;
  label: string;
}

export interface SensorChartProps {
  sensor: DeviceSensor;
  mode: ChartMode;
  onModeChange: (mode: ChartMode) => void;
  className?: string;
}

