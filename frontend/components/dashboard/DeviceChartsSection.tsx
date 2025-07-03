// components/dashboard/DeviceChartsSection.tsx - FIXED for real-time WebSocket data
'use client';

import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';
import { SensorChart } from '@/components/charts/SensorChart';
import { useDeviceDetail } from '@/hooks/useDeviceDetail';
import { useDeviceWebSocket } from '@/hooks/useDeviceWebSocket';
import { ChartDataUpdate, SensorStatusUpdate, DeviceStatusUpdate } from '@/types/websocket';
import { DeviceSensor } from '@/types/device';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';

export function DeviceChartsSection() {
 const params = useParams();
 const deviceId = params.id as string;
 
 // Load device data
 const { device, loading: deviceLoading, error } = useDeviceDetail(deviceId);
 
 // State for live sensor values (updated via WebSocket)
 const [liveValues, setLiveValues] = useState<Record<number, number>>({});
 const [sensorStatuses, setSensorStatuses] = useState<Record<number, string>>({});
 
 // WebSocket connection for real-time updates
 const { isConnected } = useDeviceWebSocket({
   deviceId: device?.id, // ✅ Fixed: Use device.id when available
   onChartDataUpdate: (data: ChartDataUpdate) => {
     console.log('📊 Live chart data received:', data);
     
     // ✅ Fixed: Handle different chart_id formats
     let sensorId: number;
     if (data.chart_id.startsWith('chart-')) {
       sensorId = parseInt(data.chart_id.replace('chart-', ''));
     } else {
       // Handle direct sensor ID format
       sensorId = parseInt(data.chart_id);
     }
     
     // Update live value for this sensor
     if (data.data_points && data.data_points.length > 0) {
       const latestValue = data.data_points[data.data_points.length - 1][1];
       console.log(`🔄 Updating sensor ${sensorId} with value:`, latestValue);
       
       setLiveValues(prev => ({
         ...prev,
         [sensorId]: latestValue
       }));
     }
   },
   onSensorStatusUpdate: (data: SensorStatusUpdate) => {
     console.log('🔬 Sensor status update received:', data);
     
     // Update sensor statuses
     if (data.data.sensors) {
       const statusUpdates: Record<number, string> = {};
       data.data.sensors.forEach(sensor => {
         statusUpdates[sensor.sensor_id] = sensor.status;
       });
       
       setSensorStatuses(prev => ({
         ...prev,
         ...statusUpdates
       }));
     }
   },
   onDeviceStatusUpdate: (data: DeviceStatusUpdate) => {
     console.log('📱 Device status update received:', data);
     // Handle device-level status updates if needed
   }
 });

 // Extract sensors from the correct API structure
 const getSensorsFromDevice = (deviceData: any) => {
   if (!deviceData?.sensor_groups) return [];
   
   // Flatten all sensor groups into a single array
   const allSensors: DeviceSensor[] = [];
   Object.values(deviceData.sensor_groups).forEach((sensorGroup: any) => {
     if (Array.isArray(sensorGroup)) {
       allSensors.push(...sensorGroup);
     }
   });
   
   return allSensors;
 };

 // Get sensors from the device data
 const sensors = getSensorsFromDevice(device);

 // ✅ Fixed: Initialize live values from device data
 useEffect(() => {
   if (device?.latest_readings) {
     // Convert string IDs to numbers and use latest_readings
     const initialValues: Record<number, number> = {};
     Object.entries(device.latest_readings).forEach(([sensorId, value]) => {
       initialValues[parseInt(sensorId)] = value as number;
     });
     setLiveValues(initialValues);
     console.log('🔄 Initialized live values:', initialValues);
   }
 }, [device]); // ← Fixed: Only depend on device

 // ✅ Fixed: Separate useEffect for sensor statuses
 useEffect(() => {
   if (device?.sensor_groups) {
     const allSensors = getSensorsFromDevice(device);
     if (allSensors.length > 0) {
       const initialStatuses: Record<number, string> = {};
       allSensors.forEach(sensor => {
         initialStatuses[sensor.id] = sensor.status;
       });
       setSensorStatuses(initialStatuses);
       console.log('🔄 Initialized sensor statuses:', initialStatuses);
     }
   }
 }, [device?.sensor_groups]); // ← Fixed: Use device.sensor_groups instead of sensors array

 // Debug logs to verify data extraction
 console.log('🐛 DEBUG - DeviceChartsSection:', {
   deviceId,
   device: device?.name,
   sensorsCount: sensors.length,
   liveValues,
   sensorStatuses,
   isConnected
 });

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
 
 return (
   <div className="space-y-6">
     {/* Connection Status */}
     <div className="flex items-center justify-between">
       <h2 className="text-xl font-semibold text-cosmic-text">Sensor Monitoring</h2>
       <div className="flex items-center space-x-4">
         {/* Sensor Count */}
         <div className="text-sm text-cosmic-text-muted">
           {sensors.length} sensor{sensors.length !== 1 ? 's' : ''} detected
         </div>
         {/* Connection Status */}
         <div className="flex items-center space-x-2 text-sm">
           <div className={`w-2 h-2 rounded-full ${isConnected ? 'bg-green-400 animate-pulse' : 'bg-red-400'}`} />
           <span className="text-cosmic-text-muted">
             {isConnected ? 'Live Data Connected' : 'Connection Lost'}
           </span>
         </div>
       </div>
     </div>

     {/* ✅ Fixed: Direct sensor grid rendering */}
     {sensors.length > 0 ? (
       <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
         {sensors.map((sensor) => {
           // Get live value for this sensor, fallback to last_reading
           const liveValue = liveValues[sensor.id] ?? sensor.last_reading;
           
           console.log(`🔄 Rendering sensor ${sensor.id} (${sensor.type}) with value:`, liveValue);
           
           return (
             <SensorChart
               key={sensor.id}
               sensor={sensor}
               liveValue={liveValue} // ✅ Real-time value from WebSocket
               className="h-full"
             />
           );
         })}
       </div>
     ) : (
       <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-8 text-center">
         <h3 className="text-cosmic-text font-semibold mb-2">No Sensors Detected</h3>
         <p className="text-cosmic-text-muted">
           This device doesn't have any sensors configured yet.
         </p>
       </div>
     )}

     {/* ✅ Debug Panel (remove in production) */}
     {process.env.NODE_ENV === 'development' && (
       <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-4 mt-6">
         <h3 className="text-sm font-semibold text-cosmic-text mb-2">Debug Info</h3>
         <div className="text-xs text-cosmic-text-muted space-y-1">
           <div>Device ID: {deviceId}</div>
           <div>WebSocket Connected: {isConnected ? '✅' : '❌'}</div>
           <div>Sensors Found: {sensors.length}</div>
           <div>Live Values: {JSON.stringify(liveValues)}</div>
           <div>Latest Readings: {JSON.stringify(device?.latest_readings)}</div>
         </div>
       </div>
     )}
   </div>
 );
}