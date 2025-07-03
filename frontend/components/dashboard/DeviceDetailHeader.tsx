// Updated components/dashboard/DeviceDetailHeader.tsx - FIXED with working buttons and real sensor data
'use client';

import { useState } from 'react';
import { useParams } from 'next/navigation';
import { Button } from '@/components/ui/Button';
import { ArrowLeft, Settings, Power, Wifi, WifiOff, Zap, AlertTriangle } from 'lucide-react';
import Link from 'next/link';
import { useDeviceDetail } from '@/hooks/useDeviceDetail';
import { useDeviceWebSocket } from '@/hooks/useDeviceWebSocket';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { PresetModal } from '@/components/dashboard/presets/PresetModal';
import { DeviceSensor } from '@/types/device';
import { cn } from '@/lib/utils';

export function DeviceDetailHeader() {
  const params = useParams();
  const deviceId = params.id as string;
  
  const { device, loading } = useDeviceDetail(deviceId);
  const { isConnected, sendCommand } = useDeviceWebSocket({
    deviceId: device?.id
  });

  // ✅ NEW: State for preset modal
  const [isPresetModalOpen, setIsPresetModalOpen] = useState(false);
  const [isRestarting, setIsRestarting] = useState(false);

  // ✅ NEW: Get sensors from device data (same logic as DeviceChartsSection)
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

  // ✅ NEW: Power cycle handler - restart device
  const handlePowerCycle = async () => {
    if (!device || !isConnected) return;

    setIsRestarting(true);
    try {
      console.log('🔄 Sending restart command to device:', device.name);
      
      // Send restart command via WebSocket
      sendCommand('restart_device', { 
        device_id: device.id,
        reason: 'Manual restart from UI'
      });
      
      // Show feedback for a few seconds
      setTimeout(() => {
        setIsRestarting(false);
      }, 3000);
      
    } catch (error) {
      console.error('❌ Failed to restart device:', error);
      setIsRestarting(false);
    }
  };

  // ✅ NEW: Configure handler - open preset modal
  const handleConfigure = () => {
    setIsPresetModalOpen(true);
  };

  // ✅ NEW: Get real sensor data and alert status
  const sensors = getSensorsFromDevice(device);
  const sensorCount = sensors.length;

  // ✅ NEW: Calculate real alert status from sensors
  const calculateAlertStatus = () => {
    if (!sensors.length) return { status: 'no_data', color: 'text-gray-400', label: 'No Data' };

    // Check for critical errors first
    const criticalSensors = sensors.filter(s => s.status === 'error' || s.status === 'error_high' || s.status === 'error_low');
    if (criticalSensors.length > 0) {
      return { 
        status: 'error', 
        color: 'text-red-400', 
        label: 'Critical',
        count: criticalSensors.length,
        details: `${criticalSensors.length} sensor${criticalSensors.length > 1 ? 's' : ''} in critical state`
      };
    }

    // Check for warnings
    const warningSensors = sensors.filter(s => s.status === 'warning' || s.status === 'warning_high' || s.status === 'warning_low');
    if (warningSensors.length > 0) {
      return { 
        status: 'warning', 
        color: 'text-yellow-400', 
        label: 'Warning',
        count: warningSensors.length,
        details: `${warningSensors.length} sensor${warningSensors.length > 1 ? 's' : ''} showing warnings`
      };
    }

    // All sensors OK
    return { 
      status: 'normal', 
      color: 'text-green-400', 
      label: 'Normal',
      details: 'All sensors operating normally'
    };
  };

  const alertInfo = calculateAlertStatus();

  if (loading) {
    return (
      <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
        <div className="flex items-center justify-center">
          <LoadingSpinner />
        </div>
      </div>
    );
  }

  if (!device) {
    return (
      <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
        <div className="text-center">
          <h1 className="text-xl font-bold text-red-400">Device Not Found</h1>
        </div>
      </div>
    );
  }

  // Calculate connection status
  const isDeviceOnline = device.last_connection && 
    new Date(device.last_connection).getTime() > Date.now() - (10 * 60 * 1000); // 10 minutes

  return (
    <>
      <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
        {/* Breadcrumb */}
        <div className="flex items-center space-x-2 text-cosmic-text-muted mb-4">
          <Link href="/user/dashboard/device_dashboard" className="hover:text-stellar-accent flex items-center">
            <ArrowLeft size={20} className="mr-1" />
            Device Dashboard
          </Link>
          <span>/</span>
          <span className="text-cosmic-text">{device.name}</span>
        </div>

        {/* Device Header Info */}
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between space-y-4 lg:space-y-0">
          <div className="flex items-center space-x-4">
            <div className="w-16 h-16 bg-gradient-cosmic rounded-xl flex items-center justify-center">
              <Settings size={32} className="text-white" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-cosmic-text">{device.name}</h1>
              <div className="flex flex-wrap items-center gap-4 text-sm text-cosmic-text-muted">
                <span>{device.device_type}</span>
                <span>•</span>
                <div className="flex items-center space-x-1">
                  {isDeviceOnline ? (
                    <Wifi size={16} className="text-green-400" />
                  ) : (
                    <WifiOff size={16} className="text-red-400" />
                  )}
                  <span className={isDeviceOnline ? 'text-green-400' : 'text-red-400'}>
                    {isDeviceOnline ? 'Online' : 'Offline'}
                  </span>
                </div>
                {device.last_connection && (
                  <>
                    <span>•</span>
                    <span>Last seen: {new Date(device.last_connection).toLocaleString()}</span>
                  </>
                )}
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex items-center space-x-3">
            {/* WebSocket Connection Indicator */}
            <div className="flex items-center space-x-2 text-xs">
              <div className={`w-2 h-2 rounded-full ${isConnected ? 'bg-green-400 animate-pulse' : 'bg-gray-400'}`} />
              <span className="text-cosmic-text-muted">
                {isConnected ? 'Live' : 'Disconnected'}
              </span>
            </div>
            
            {/* ✅ FIXED: Configure Button - Opens Preset Modal */}
            <Button 
              variant="outline" 
              size="sm"
              onClick={handleConfigure}
              title="Configure Presets"
            >
              <Settings size={16} className="mr-2" />
              Configure
            </Button>

            {/* ✅ FIXED: Power Cycle Button - Restart Device */}
            <Button 
              variant="stellar" 
              size="sm"
              onClick={handlePowerCycle}
              disabled={!isConnected || isRestarting}
              title={isConnected ? "Restart device" : "Device must be online to restart"}
            >
              {isRestarting ? (
                <>
                  <div className="w-4 h-4 border-2 border-black/30 border-t-black rounded-full animate-spin mr-2" />
                  Restarting...
                </>
              ) : (
                <>
                  <Power size={16} className="mr-2" />
                  Restart
                </>
              )}
            </Button>
          </div>
        </div>

        {/* ✅ FIXED: Device Status Summary - Real sensor data */}
        <div className="mt-4 flex flex-wrap gap-4">
          <div className="bg-space-secondary rounded-lg px-3 py-2">
            <span className="text-xs text-cosmic-text-muted">Status: </span>
            <span className={cn(
              "text-xs font-semibold",
              device.status === 'active' ? 'text-green-400' :
              device.status === 'pending' ? 'text-yellow-400' : 'text-red-400'
            )}>
              {device.status ? 
                device.status.charAt(0).toUpperCase() + device.status.slice(1) : 
                'Unknown'
              }
            </span>
          </div>
          
          {/* ✅ FIXED: Real Alert Level from Sensors */}
          <div className="bg-space-secondary rounded-lg px-3 py-2">
            <span className="text-xs text-cosmic-text-muted">Alert Level: </span>
            <span className={cn("text-xs font-semibold", alertInfo.color)}>
              {alertInfo.label}
            </span>
            {alertInfo.count && (
              <span className="text-xs text-cosmic-text-muted ml-1">
                ({alertInfo.count})
              </span>
            )}
          </div>

          {/* ✅ FIXED: Real Sensor Count */}
          <div className="bg-space-secondary rounded-lg px-3 py-2">
            <span className="text-xs text-cosmic-text-muted">Sensors: </span>
            <span className="text-xs font-semibold text-cosmic-text">
              {sensorCount}
            </span>
          </div>

          {/* ✅ NEW: Connection Status */}
          <div className="bg-space-secondary rounded-lg px-3 py-2">
            <span className="text-xs text-cosmic-text-muted">WebSocket: </span>
            <span className={cn(
              "text-xs font-semibold",
              isConnected ? 'text-green-400' : 'text-red-400'
            )}>
              {isConnected ? 'Connected' : 'Disconnected'}
            </span>
          </div>
        </div>

        {/* ✅ NEW: Alert Details (if there are issues) */}
        {alertInfo.status !== 'normal' && alertInfo.status !== 'no_data' && (
          <div className={cn(
            "mt-4 p-3 rounded-lg border flex items-start space-x-2",
            alertInfo.status === 'error' 
              ? 'bg-red-500/10 border-red-500/20' 
              : 'bg-yellow-500/10 border-yellow-500/20'
          )}>
            <AlertTriangle size={16} className={alertInfo.color} />
            <div>
              <p className={cn("text-sm font-medium", alertInfo.color)}>
                Sensor Alert
              </p>
              <p className="text-xs text-cosmic-text-muted">
                {alertInfo.details}
              </p>
            </div>
          </div>
        )}
      </div>

      {/* ✅ NEW: Preset Modal */}
      {device && (
        <PresetModal
          isOpen={isPresetModalOpen}
          onClose={() => setIsPresetModalOpen(false)}
          device={device}
          onPresetApplied={(preset) => {
            console.log('✅ Preset applied:', preset.name);
            // Could show a toast notification here
          }}
        />
      )}
    </>
  );
}