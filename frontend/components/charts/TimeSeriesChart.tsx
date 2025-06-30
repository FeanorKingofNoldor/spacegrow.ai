// components/charts/TimeSeriesChart.tsx - FIXED with enhanced empty state
'use client';

import { useRef } from 'react';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  TimeScale,
  ChartOptions
} from 'chart.js';
import { Line } from 'react-chartjs-2';
import 'chartjs-adapter-date-fns';
import zoomPlugin from 'chartjs-plugin-zoom';
import { ChartDataPoint } from '@/types/chart';
import { DeviceSensor } from '@/types/device';
import { Activity, AlertTriangle, Clock, Wifi, WifiOff, TrendingUp } from 'lucide-react';

// Register Chart.js components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  TimeScale,
  zoomPlugin
);

interface TimeSeriesChartProps {
  sensor: DeviceSensor;
  data: ChartDataPoint[];
  loading?: boolean;
  className?: string;
}

export function TimeSeriesChart({ 
  sensor, 
  data, 
  loading = false,
  className = '' 
}: TimeSeriesChartProps) {
  const chartRef = useRef<any>(null);
  const { sensor_type } = sensor;

  // Convert data to Chart.js format
  const chartData = {
    datasets: [
      {
        label: sensor.type,
        data: data.map(point => ({
          x: point.timestamp,
          y: point.value
        })),
        borderColor: '#7c3aed', // violet-600
        backgroundColor: 'rgba(124, 58, 237, 0.1)',
        borderWidth: 2,
        fill: true,
        tension: 0.4,
        pointRadius: 3,
        pointHoverRadius: 6,
        pointBackgroundColor: '#7c3aed',
        pointBorderColor: '#ffffff',
        pointBorderWidth: 2,
      }
    ]
  };

  const options: ChartOptions<'line'> = {
    responsive: true,
    maintainAspectRatio: false,
    scales: {
      x: {
        type: 'time',
        time: {
          displayFormats: {
            minute: 'HH:mm',
            hour: 'HH:mm',
            day: 'MMM dd',
            week: 'MMM dd',
            month: 'MMM yyyy'
          }
        },
        grid: {
          color: 'rgba(255, 255, 255, 0.1)'
        },
        ticks: {
          color: '#9ca3af'
        }
      },
      y: {
        min: sensor_type.min_value,
        max: sensor_type.max_value,
        grid: {
          color: 'rgba(255, 255, 255, 0.1)'
        },
        ticks: {
          color: '#9ca3af',
          callback: function(value) {
            return `${value}${sensor_type.unit}`;
          }
        }
      }
    },
    plugins: {
      legend: {
        display: false
      },
      tooltip: {
        mode: 'index',
        intersect: false,
        backgroundColor: 'rgba(0, 0, 0, 0.8)',
        titleColor: '#ffffff',
        bodyColor: '#ffffff',
        borderColor: '#7c3aed',
        borderWidth: 1,
        callbacks: {
          label: function(context) {
            return `${context.parsed.y.toFixed(2)}${sensor_type.unit}`;
          }
        }
      },
      zoom: {
        limits: {
          x: { min: 'original', max: 'original' },
          y: { min: sensor_type.min_value, max: sensor_type.max_value }
        },
        pan: {
          enabled: true,
          mode: 'x'
        },
        zoom: {
          wheel: {
            enabled: true,
          },
          pinch: {
            enabled: true
          },
          mode: 'x',
        }
      }
    },
    interaction: {
      mode: 'nearest',
      axis: 'x',
      intersect: false
    }
  };

  // Reset zoom function
  const resetZoom = () => {
    if (chartRef.current) {
      chartRef.current.resetZoom();
    }
  };

  return (
    <div className={`bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-4 ${className}`}>
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h3 className="text-sm font-semibold text-cosmic-text">{sensor.type}</h3>
          <div className="flex items-center space-x-2">
            <p className="text-xs text-cosmic-text-muted">Historical Data</p>
            {!loading && data.length > 0 && (
              <div className="flex items-center space-x-1">
                <Wifi size={12} className="text-green-400" />
                <span className="text-xs text-green-400">Live</span>
              </div>
            )}
          </div>
        </div>
        {!loading && data.length > 0 && (
          <button
            onClick={resetZoom}
            className="text-xs text-stellar-accent hover:text-stellar-accent/80 transition-colors"
          >
            Reset Zoom
          </button>
        )}
      </div>

      {/* Chart Container */}
      <div className="relative h-64 w-full">
        {loading ? (
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-stellar-accent"></div>
          </div>
        ) : data.length > 0 ? (
          <Line ref={chartRef} data={chartData} options={options} />
        ) : (
          // Enhanced Empty State
          <div className="absolute inset-0 flex flex-col items-center justify-center text-center border-2 border-dashed border-space-border rounded-lg">
            <Activity size={32} className="text-cosmic-text-muted mb-3 opacity-50" />
            <h4 className="text-sm font-medium text-cosmic-text mb-1">No Historical Data</h4>
            <p className="text-xs text-cosmic-text-muted mb-4 max-w-48">
              Historical readings will appear here once your device starts transmitting data over time
            </p>
            
            <div className="flex items-center space-x-1 text-xs text-cosmic-text-muted mb-4">
              <Clock size={12} />
              <span>Waiting for readings...</span>
            </div>

            {/* Mini preview of what the chart will look like */}
            <div className="w-32 h-16 bg-space-secondary rounded border border-space-border mb-3 relative overflow-hidden">
              <div className="absolute inset-0 flex items-end justify-center">
                <div className="flex items-end space-x-1 h-full w-full p-2">
                  <div className="w-1 bg-stellar-accent/30 h-1/4 rounded-t"></div>
                  <div className="w-1 bg-stellar-accent/30 h-2/4 rounded-t"></div>
                  <div className="w-1 bg-stellar-accent/30 h-3/4 rounded-t"></div>
                  <div className="w-1 bg-stellar-accent/30 h-1/2 rounded-t"></div>
                  <div className="w-1 bg-stellar-accent/30 h-4/5 rounded-t"></div>
                  <div className="w-1 bg-stellar-accent/30 h-3/5 rounded-t"></div>
                  <div className="w-1 bg-stellar-accent/30 h-1/3 rounded-t"></div>
                </div>
              </div>
              <div className="absolute bottom-1 left-1/2 transform -translate-x-1/2">
                <TrendingUp size={12} className="text-stellar-accent/50" />
              </div>
            </div>

            <div className="text-xs text-cosmic-text-muted">
              Expected range: {sensor_type.min_value} - {sensor_type.max_value} {sensor_type.unit}
            </div>
          </div>
        )}
      </div>

      {/* Chart Info Footer */}
      {!loading && (
        <div className="flex justify-between items-center mt-2 text-xs text-cosmic-text-muted">
          {data.length > 0 ? (
            <>
              <span>{data.length} data points</span>
              <span>Scroll to zoom • Drag to pan</span>
            </>
          ) : (
            <>
              <div className="flex items-center space-x-4">
                <div className="flex items-center space-x-1">
                  <WifiOff size={12} className="text-red-400" />
                  <span className="text-red-400">No Recent Data</span>
                </div>
              </div>
              <div className="flex items-center space-x-2">
                <AlertTriangle size={12} className="text-yellow-400" />
                <span>Check device connection</span>
              </div>
            </>
          )}
        </div>
      )}

      {/* Troubleshooting Section - Only show when no data */}
      {!loading && data.length === 0 && (
        <div className="mt-3 p-3 bg-space-secondary rounded-lg">
          <div className="flex items-start space-x-2">
            <AlertTriangle size={14} className="text-yellow-400 mt-0.5 flex-shrink-0" />
            <div className="text-xs text-cosmic-text-muted">
              <p className="font-medium text-cosmic-text mb-1">Troubleshooting Tips:</p>
              <ul className="space-y-1 list-disc list-inside ml-2">
                <li>Verify device is powered on and connected</li>
                <li>Check sensor wiring and connections</li>
                <li>Review device logs for error messages</li>
                <li>Ensure data transmission interval is configured</li>
              </ul>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}