// components/charts/SensorChart.tsx - ENHANCED with real-time status indicators
'use client';

import { useState } from 'react';
import { DeviceSensor } from '@/types/device';
import { ChartMode } from '@/types/chart';
import { Wifi, WifiOff, Clock, Zap } from 'lucide-react';
import { GaugeChart } from './GaugeChart'; // Fallback generic gauge
import { TimeSeriesChart } from './TimeSeriesChart';
import { useChartData } from '@/hooks/useChartData'; // ✅ Now includes WebSocket support

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
  
  // ✅ ENHANCED: Now includes WebSocket real-time updates
  const { 
    data: historicalData, 
    loading, 
    error,
    lastUpdate,
    isLive,
    refetch
  } = useChartData({
    sensorId: sensor.id,
    mode,
    autoRefresh: mode !== 'live', // Only auto-refresh for historical data
    refreshInterval: 60000, // 1 minute
    enableWebSocket: true // ✅ Enable real-time updates
  });

  const modeOptions = [
    { value: 'live', label: 'Live' },
    { value: 'history_24h', label: '24 Hours' },
    { value: 'history_7d', label: '7 Days' },
    { value: 'history_3m', label: '3 Months' }
  ];

  // ✅ ENHANCED: Use real-time data from WebSocket when available
  const gaugeValue: number | null | undefined = (() => {
    if (mode === 'live' && historicalData.length > 0) {
      // Use the latest data point from WebSocket
      return historicalData[historicalData.length - 1].value;
    }
    // Fallback to liveValue prop or sensor.last_reading
    return liveValue !== undefined ? liveValue : sensor.last_reading;
  })();

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
      console.log('💨 Pressure sensor detected - using PressureGaugeChart');
      return PressureGaugeChart;
    }
    
    // EC/Conductivity sensors
    if (typeIdentifiers.some(id => 
      id.includes('ec') || 
      id.includes('electrical') || 
      id.includes('conductivity') || 
      id.includes('tds')
    )) {
      console.log('⚡ EC sensor detected - using ECGaugeChart');
      return ECGaugeChart;
    }
    
    // Humidity sensors
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

  // ✅ NEW: Format last update time
  const formatLastUpdate = (date: Date | null): string => {
    if (!date) return 'Never';
    
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffSeconds = Math.floor(diffMs / 1000);
    const diffMinutes = Math.floor(diffSeconds / 60);
    
    if (diffSeconds < 30) return 'Just now';
    if (diffSeconds < 60) return `${diffSeconds}s ago`;
    if (diffMinutes < 60) return `${diffMinutes}m ago`;
    
    return date.toLocaleTimeString();
  };

  // ✅ NEW: Real-time status indicator
  const renderStatusIndicator = () => {
    const showLiveIndicator = mode === 'live';
    const isConnected = isLive && mode === 'live';
    
    return (
      <div className="flex items-center space-x-2 text-xs">
        {showLiveIndicator && (
          <div className="flex items-center space-x-1">
            {isConnected ? (
              <>
                <Zap size={12} className="text-green-400 animate-pulse" />
                <span className="text-green-400 font-medium">LIVE</span>
              </>
            ) : (
              <>
                <Clock size={12} className="text-yellow-400" />
                <span className="text-yellow-400">POLLING</span>
              </>
            )}
          </div>
        )}
        
        {!showLiveIndicator && (
          <div className="flex items-center space-x-1">
            <Clock size={12} className="text-blue-400" />
            <span className="text-blue-400">HISTORICAL</span>
          </div>
        )}
        
        {lastUpdate && (
          <div className="text-cosmic-text-muted">
            {formatLastUpdate(lastUpdate)}
          </div>
        )}
      </div>
    );
  };

  return (
    <div className={`relative ${className}`}>
      {/* Header with Mode Toggle and Status */}
      <div className="absolute top-4 left-4 right-4 z-10 flex justify-between items-start">
        {/* ✅ NEW: Status Indicator */}
        <div className="bg-space-glass/80 backdrop-blur-sm rounded-lg px-2 py-1 border border-space-border/50">
          {renderStatusIndicator()}
        </div>
        
        {/* Mode Toggle */}
        <select
          value={mode}
          onChange={(e) => setMode(e.target.value as ChartMode)}
          className="text-xs min-w-[100px] bg-space-glass/90 backdrop-blur-sm border border-space-border rounded-lg px-2 py-1 text-cosmic-text focus:outline-none focus:ring-2 focus:ring-stellar-accent"
        >
          {modeOptions.map(option => (
            <option key={option.value} value={option.value} className="bg-space-primary text-cosmic-text">
              {option.label}
            </option>
          ))}
        </select>
      </div>

      {/* ✅ NEW: Error State */}
      {error && (
        <div className="absolute top-16 left-4 right-4 z-10">
          <div className="bg-red-500/10 border border-red-500/30 rounded-lg px-3 py-2">
            <div className="flex items-center space-x-2 text-xs text-red-400">
              <WifiOff size={12} />
              <span>Error: {error}</span>
              <button 
                onClick={() => refetch()}
                className="underline hover:no-underline"
              >
                Retry
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ✅ NEW: Loading Overlay for Visual Feedback */}
      {loading && (
        <div className="absolute inset-0 z-10 bg-space-primary/20 backdrop-blur-sm rounded-xl flex items-center justify-center">
          <div className="flex items-center space-x-2 text-cosmic-text">
            <div className="w-4 h-4 border-2 border-stellar-accent border-t-transparent rounded-full animate-spin" />
            <span className="text-sm">
              {mode === 'live' ? 'Updating...' : 'Loading...'}
            </span>
          </div>
        </div>
      )}

      {/* Chart Display */}
      <div className="relative">
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

      {/* ✅ NEW: Chart Footer with Additional Info */}
      <div className="absolute bottom-4 left-4 right-4 z-10">
        <div className="bg-space-glass/60 backdrop-blur-sm rounded-lg px-3 py-1 border border-space-border/30">
          <div className="flex justify-between items-center text-xs text-cosmic-text-muted">
            <span>{sensor.type}</span>
            {mode === 'live' && isLive && (
              <div className="flex items-center space-x-1">
                <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                <span>Real-time</span>
              </div>
            )}
            {mode !== 'live' && (
              <span>{historicalData?.length || 0} data points</span>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}