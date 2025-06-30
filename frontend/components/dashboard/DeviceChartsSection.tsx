// components/dashboard/DeviceChartsSection.tsx - UPDATED with real sensor grid
'use client';

import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';
import { SensorChart } from '@/components/charts/SensorChart';
import { SensorGrid } from './SensorGrid';
import { useDeviceDetail } from '@/hooks/useDeviceDetail';
import { useDeviceWebSocket } from '@/hooks/useDeviceWebSocket';
import { ChartDataUpdate } from '@/types/websocket';
import { DeviceSensor } from '@/types/device';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';

export function DeviceChartsSection() {
  const params = useParams();
  const deviceId = params.id as string;
  
  // Load device data
  const { device, loading: deviceLoading, error } = useDeviceDetail(deviceId);
  
  // State for live sensor values (updated via WebSocket)
  const [liveValues, setLiveValues] = useState<Record<number, number>>({});
  
  // WebSocket connection for real-time updates
  const { isConnected } = useDeviceWebSocket({
    deviceId: device?.id,
    onChartDataUpdate: (data: ChartDataUpdate) => {
      console.log('📊 Live chart data received:', data);
      
      // Extract sensor ID from chart_id (format: "chart-123")
      const sensorId = parseInt(data.chart_id.replace('chart-', ''));
      
      // Update live value for this sensor
      if (data.data_points && data.data_points.length > 0) {
        const latestValue = data.data_points[data.data_points.length - 1][1];
        setLiveValues(prev => ({
          ...prev,
          [sensorId]: latestValue
        }));
      }
    }
  });

  // Initialize live values from device data
  useEffect(() => {
    if (device?.sensors) {
      const initialValues: Record<number, number> = {};
      device.sensors.forEach(sensor => {
        if (sensor.last_reading !== null) {
          initialValues[sensor.id] = sensor.last_reading;
        }
      });
      setLiveValues(initialValues);
    }
  }, [device]);

  if (deviceLoading) {
    return (
      <div className="flex items-center justify-center h-96">
        <LoadingSpinner />
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-6 text-center">
        <h3 className="text-red-400 font-semibold mb-2">Error Loading Device</h3>
        <p className="text-cosmic-text-muted">{error}</p>
      </div>
    );
  }

  if (!device) {
    return (
      <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6 text-center">
        <h3 className="text-cosmic-text font-semibold mb-2">Device Not Found</h3>
        <p className="text-cosmic-text-muted">The requested device could not be found.</p>
      </div>
    );
  }

  const sensors = device.sensors || [];
  
  return (
    <div className="space-y-6">
      {/* Connection Status */}
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-semibold text-cosmic-text">Sensor Monitoring</h2>
        <div className="flex items-center space-x-2 text-sm">
          <div className={`w-2 h-2 rounded-full ${isConnected ? 'bg-green-400 animate-pulse' : 'bg-red-400'}`} />
          <span className="text-cosmic-text-muted">
            {isConnected ? 'Live Data Connected' : 'Connection Lost'}
          </span>
        </div>
      </div>

      {/* Responsive Sensor Grid */}
      <SensorGrid sensors={sensors} liveValues={liveValues} />
    </div>
  );
}
