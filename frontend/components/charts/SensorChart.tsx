// components/charts/SensorChart.tsx - CLEANED with proper routing
'use client';

import { useState } from 'react';
import { DeviceSensor } from '@/types/device';
import { ChartMode } from '@/types/chart';
import { GaugeChart } from './GaugeChart'; // Fallback generic gauge
import { TimeSeriesChart } from './TimeSeriesChart';
import { useChartData } from '@/hooks/useChartData';

// Import sensor-specific gauge components
import { TempGaugeChart } from './TempGaugeChart';
import { PHGaugeChart } from './PHGaugeChart';
import { PressureGaugeChart } from './PressureGaugeChart';
import { ECGaugeChart } from './ECGaugeChart';
import { WaterLevelGaugeChart } from './WaterLevelGaugeChart';
import { HumidityGaugeChart } from './HumidityGaugeChart';

interface SensorChartProps {
  sensor: DeviceSensor;
  liveValue?: number | null;
  className?: string;
}

export function SensorChart({ 
  sensor, 
  liveValue,
  className = '' 
}: SensorChartProps) {
  const [mode, setMode] = useState<ChartMode>('live');
  
  // Fetch historical data when not in live mode
  const { data: historicalData, loading } = useChartData({
    sensorId: sensor.id,
    mode,
    autoRefresh: mode !== 'live',
    refreshInterval: 60000 // 1 minute
  });

  const modeOptions = [
    { value: 'live', label: 'Live' },
    { value: 'history_24h', label: '24 Hours' },
    { value: 'history_7d', label: '7 Days' },
    { value: 'history_3m', label: '3 Months' }
  ];

  // Determine the actual value to pass to GaugeChart
  const gaugeValue: number | null | undefined = liveValue !== undefined ? liveValue : sensor.last_reading;

  // Smart sensor type detection and component selection
  const getSensorGaugeComponent = () => {
    const sensorType = sensor.type?.toLowerCase() || '';
    const sensorTypeName = sensor.sensor_type?.name?.toLowerCase() || '';
    
    // Check both sensor.type and sensor.sensor_type.name for flexibility
    const typeIdentifiers = [sensorType, sensorTypeName];
    
    // Temperature sensors
    if (typeIdentifiers.some(id => 
      id.includes('temperature') || 
      id.includes('temp')
    )) {
      console.log('🌡️ Temperature sensor detected - using TempGaugeChart');
      return TempGaugeChart;
    }
    
    // pH sensors
    if (typeIdentifiers.some(id => 
      id.includes('ph') || 
      id.includes('acid') || 
      id.includes('alkaline')
    )) {
      console.log('🧪 pH sensor detected - using PHGaugeChart');
      return PHGaugeChart;
    }
    
    // Pressure sensors
    if (typeIdentifiers.some(id => 
      id.includes('pressure') || 
      id.includes('psi') || 
      id.includes('bar')
    )) {
      console.log('💨 Pressure sensor detected - using PressureGaugeChart (fallback to GaugeChart for now)');
      return PressureGaugeChart;
      return GaugeChart; // Fallback until PressureGaugeChart is created
    }
    
    // EC/Conductivity sensors
    if (typeIdentifiers.some(id => 
      id.includes('ec') || 
      id.includes('electrical') || 
      id.includes('conductivity') || 
      id.includes('tds')
    )) {
      console.log('⚡ EC sensor detected - using ECGaugeChart (fallback to GaugeChart for now)');
      return ECGaugeChart;
      return GaugeChart; // Fallback until ECGaugeChart is created
    }
    
    if (typeIdentifiers.some(id => 
      id.includes('humidity') || 
      id.includes('moisture') ||
      id.includes('rh')
    )) {
      console.log('💧 Humidity sensor detected - using HumidityGaugeChart');
      return HumidityGaugeChart;
    }

	    // Water Level sensors
    if (typeIdentifiers.some(id => 
      id.includes('water') || 
      id.includes('level') || 
      id.includes('depth') || 
      id.includes('height')
    )) {
      console.log('🌊 Water Level sensor detected - using WaterLevelGaugeChart');
      return WaterLevelGaugeChart;
    }
    
    // Default fallback for unknown sensor types
    console.log(`❓ Unknown sensor type: ${sensorType}/${sensorTypeName} - using generic gauge`);
    return GaugeChart;
  };

  // Get the appropriate gauge component
  const GaugeComponent = getSensorGaugeComponent();

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
        <GaugeComponent 
          sensor={sensor} 
          value={gaugeValue}
          className="h-full"
        />
      ) : (
        <TimeSeriesChart 
          sensor={sensor} 
          data={historicalData || []}
          loading={loading}
          className="h-full"
        />
      )}
    </div>
  );
}