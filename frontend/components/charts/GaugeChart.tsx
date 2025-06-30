// components/charts/GaugeChart.tsx - FIXED with empty state handling
'use client';

import { useEffect, useRef } from 'react';
import {
  Chart as ChartJS,
  ArcElement,
  Tooltip,
  Legend,
  ChartOptions
} from 'chart.js';
import { Doughnut } from 'react-chartjs-2';
import { DeviceSensor } from '@/types/device';
import { Activity, AlertTriangle, Clock, Wifi, WifiOff } from 'lucide-react';

// Register Chart.js components
ChartJS.register(ArcElement, Tooltip, Legend);

interface GaugeChartProps {
  sensor: DeviceSensor;
  value: number;
  className?: string;
}

export function GaugeChart({ sensor, value, className = '' }: GaugeChartProps) {
  const { sensor_type } = sensor;
  
  // Check if we have valid data
  const hasValidData = value !== null && value !== undefined && !isNaN(value);
  
  // If no valid data, show empty state
  if (!hasValidData) {
    return (
      <div className={`bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-4 ${className}`}>
        {/* Sensor Name */}
        <div className="text-center mb-2">
          <h3 className="text-sm font-semibold text-cosmic-text">{sensor.type}</h3>
          <p className="text-xs text-cosmic-text-muted">{sensor_type.unit}</p>
        </div>

        {/* Empty State */}
        <div className="h-32 w-full flex flex-col items-center justify-center text-center border-2 border-dashed border-space-border rounded-lg">
          <Activity size={32} className="text-cosmic-text-muted mb-2 opacity-50" />
          <h4 className="text-sm font-medium text-cosmic-text mb-1">Waiting for Data</h4>
          <p className="text-xs text-cosmic-text-muted mb-3 max-w-32">
            Sensor readings will appear here once data is received
          </p>
          
          <div className="flex items-center space-x-1 text-xs text-cosmic-text-muted">
            <WifiOff size={12} />
            <span>No Recent Data</span>
          </div>
        </div>

        {/* Troubleshooting Info */}
        <div className="mt-3 p-2 bg-space-secondary rounded-lg">
          <div className="flex items-start space-x-2">
            <AlertTriangle size={12} className="text-yellow-400 mt-0.5 flex-shrink-0" />
            <div className="text-xs text-cosmic-text-muted">
              <p className="font-medium text-cosmic-text mb-1">Troubleshooting:</p>
              <ul className="space-y-0.5 list-disc list-inside ml-1">
                <li>Check device connection</li>
                <li>Verify sensor wiring</li>
                <li>Review device logs</li>
              </ul>
            </div>
          </div>
        </div>

        {/* Min/Max Labels - still show the expected range */}
        <div className="flex justify-between mt-2 text-xs text-cosmic-text-muted">
          <span>{sensor_type.min_value}</span>
          <span>{sensor_type.max_value}</span>
        </div>
      </div>
    );
  }
  
  // Create 5-zone configuration based on sensor thresholds
  const zones = [
    {
      min: sensor_type.error_low_min,
      max: sensor_type.error_low_max,
      color: '#ef4444', // red-500
      label: 'Error Low'
    },
    {
      min: sensor_type.warning_low_min,
      max: sensor_type.warning_low_max,
      color: '#f59e0b', // amber-500
      label: 'Warning Low'
    },
    {
      min: sensor_type.normal_min,
      max: sensor_type.normal_max,
      color: '#10b981', // emerald-500
      label: 'Normal'
    },
    {
      min: sensor_type.warning_high_min,
      max: sensor_type.warning_high_max,
      color: '#f59e0b', // amber-500
      label: 'Warning High'
    },
    {
      min: sensor_type.error_high_min,
      max: sensor_type.error_high_max,
      color: '#ef4444', // red-500
      label: 'Error High'
    }
  ];

  // Calculate zone sizes for the gauge
  const totalRange = sensor_type.max_value - sensor_type.min_value;
  const zoneData = zones.map(zone => {
    const zoneSize = zone.max - zone.min;
    return (zoneSize / totalRange) * 180; // Half circle = 180 degrees
  });

  // Add empty half for the bottom of the gauge
  const emptyHalf = 180;

  // Determine current zone color
  const getCurrentZoneColor = (val: number) => {
    for (const zone of zones) {
      if (val >= zone.min && val <= zone.max) {
        return zone.color;
      }
    }
    return '#6b7280'; // gray-500 for out of range
  };

  const data = {
    datasets: [
      {
        // Zone colors for the gauge background
        data: [...zoneData, emptyHalf],
        backgroundColor: [...zones.map(z => z.color), 'transparent'],
        borderWidth: 0,
        cutout: '75%',
        circumference: 180,
        rotation: 270,
      },
      {
        // Current value indicator
        data: [5, 175], // Small arc for the needle effect
        backgroundColor: [getCurrentZoneColor(value), 'transparent'],
        borderWidth: 0,
        cutout: '60%',
        circumference: 180,
        rotation: 270 + (((value - sensor_type.min_value) / totalRange) * 180),
      }
    ]
  };

  const options: ChartOptions<'doughnut'> = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: false
      },
      tooltip: {
        enabled: false
      }
    },
    animation: {
      animateRotate: true,
      duration: 1000
    }
  };

  return (
    <div className={`bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-4 ${className}`}>
      {/* Sensor Name */}
      <div className="text-center mb-2">
        <h3 className="text-sm font-semibold text-cosmic-text">{sensor.type}</h3>
        <div className="flex items-center justify-center space-x-2">
          <p className="text-xs text-cosmic-text-muted">{sensor_type.unit}</p>
          <Wifi size={12} className="text-green-400" />
        </div>
      </div>

      {/* Gauge Chart */}
      <div className="relative h-32 w-full">
        <Doughnut data={data} options={options} />
        
        {/* Center Value Display */}
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <div className="text-2xl font-bold text-cosmic-text">
            {value?.toFixed(1) || '--'}
          </div>
          <div className="text-xs text-cosmic-text-muted">
            {sensor_type.unit}
          </div>
        </div>
      </div>

      {/* Status Indicator */}
      <div className="flex items-center justify-center mt-2">
        <div 
          className="w-2 h-2 rounded-full mr-2"
          style={{ backgroundColor: getCurrentZoneColor(value) }}
        />
        <span className="text-xs text-cosmic-text-muted capitalize">
          {sensor.status}
        </span>
      </div>

      {/* Min/Max Labels */}
      <div className="flex justify-between mt-2 text-xs text-cosmic-text-muted">
        <span>{sensor_type.min_value}</span>
        <span>{sensor_type.max_value}</span>
      </div>
    </div>
  );
}