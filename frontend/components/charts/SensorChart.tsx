// components/charts/SensorChart.tsx - FIXED to properly handle empty states
'use client';

import { useState } from 'react';
import { DeviceSensor } from '@/types/device';
import { ChartMode } from '@/types/chart';
import { GaugeChart } from './GaugeChart';
import { TimeSeriesChart } from './TimeSeriesChart';
import { useChartData } from '@/hooks/useChartData';

interface SensorChartProps {
  sensor: DeviceSensor;
  liveValue?: number;
  className?: string;
}

export function SensorChart({ 
  sensor, 
  liveValue, // Remove the default fallback to 0 - let charts handle null/undefined
  className = '' 
}: SensorChartProps) {
  const [mode, setMode] = useState<ChartMode>('live');
  
  // Fetch historical data when not in live mode
  const { data: historicalData, loading } = useChartData({
    sensorId: sensor.id,
    mode,
    autoRefresh: mode !== 'live', // Auto-refresh historical data
    refreshInterval: 60000 // 1 minute
  });

  const modeOptions = [
    { value: 'live', label: 'Live' },
    { value: 'history_24h', label: '24 Hours' },
    { value: 'history_7d', label: '7 Days' },
    { value: 'history_3m', label: '3 Months' }
  ];

  // Determine the actual value to pass to GaugeChart
  // Priority: 1) liveValue prop, 2) sensor.last_reading, 3) null (for empty state)
  const gaugeValue = liveValue !== undefined ? liveValue : sensor.last_reading;

  return (
    <div className={`relative ${className}`}>
      {/* Mode Toggle - positioned in top-right corner */}
      <div className="absolute top-4 right-4 z-10">
        <select
          value={mode}
          onChange={(e) => setMode(e.target.value as ChartMode)}
          className="text-xs min-w-[100px] bg-space-glass border border-space-border rounded-lg px-2 py-1 text-cosmic-text focus:outline-none focus:ring-2 focus:ring-stellar-accent"
        >
          {modeOptions.map(option => (
            <option key={option.value} value={option.value} className="bg-space-primary text-cosmic-text">
              {option.label}
            </option>
          ))}
        </select>
      </div>

      {/* Chart Display */}
      {mode === 'live' ? (
        <GaugeChart 
          sensor={sensor} 
          value={gaugeValue} // Pass null/undefined if no data - let GaugeChart show empty state
          className="h-full"
        />
      ) : (
        <TimeSeriesChart 
          sensor={sensor} 
          data={historicalData || []} // Ensure we always pass an array
          loading={loading}
          className="h-full"
        />
      )}
    </div>
  );
}