// components/charts/TimeSeriesChart.tsx
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
          <p className="text-xs text-cosmic-text-muted">Historical Data</p>
        </div>
        <button
          onClick={resetZoom}
          className="text-xs text-stellar-accent hover:text-stellar-accent/80 transition-colors"
        >
          Reset Zoom
        </button>
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
          <div className="absolute inset-0 flex items-center justify-center text-cosmic-text-muted">
            No data available
          </div>
        )}
      </div>

      {/* Chart Info */}
      <div className="flex justify-between items-center mt-2 text-xs text-cosmic-text-muted">
        <span>{data.length} data points</span>
        <span>Scroll to zoom • Drag to pan</span>
      </div>
    </div>
  );
}
