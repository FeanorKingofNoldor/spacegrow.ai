// Updated components/dashboard/DeviceDetailHeader.tsx - ENHANCED with real device data
'use client';

import { useParams } from 'next/navigation';
import { Button } from '@/components/ui/Button';
import { ArrowLeft, Settings, Power, Wifi, WifiOff } from 'lucide-react';
import Link from 'next/link';
import { useDeviceDetail } from '@/hooks/useDeviceDetail';
import { useDeviceWebSocket } from '@/hooks/useDeviceWebSocket';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';

export function DeviceDetailHeader() {
  const params = useParams();
  const deviceId = params.id as string;
  
  const { device, loading } = useDeviceDetail(deviceId);
  const { isConnected, sendCommand } = useDeviceWebSocket({
    deviceId: device?.id
  });

  const handlePowerCycle = () => {
    if (device) {
      sendCommand('power_cycle', { device_id: device.id });
    }
  };

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
          
          <Button variant="outline" size="sm">
            <Settings size={16} className="mr-2" />
            Configure
          </Button>
          <Button 
            variant="stellar" 
            size="sm"
            onClick={handlePowerCycle}
            disabled={!isConnected}
          >
            <Power size={16} className="mr-2" />
            Power Cycle
          </Button>
        </div>
      </div>

      {/* Device Status Summary */}
      <div className="mt-4 flex flex-wrap gap-4">
        <div className="bg-space-secondary rounded-lg px-3 py-2">
          <span className="text-xs text-cosmic-text-muted">Status: </span>
          <span className={`text-xs font-semibold ${
            device.status === 'active' ? 'text-green-400' :
            device.status === 'pending' ? 'text-yellow-400' : 'text-red-400'
          }`}>
            {device.status.charAt(0).toUpperCase() + device.status.slice(1)}
          </span>
        </div>
        
        <div className="bg-space-secondary rounded-lg px-3 py-2">
          <span className="text-xs text-cosmic-text-muted">Alert Level: </span>
          <span className={`text-xs font-semibold ${
            device.alert_status === 'normal' ? 'text-green-400' :
            device.alert_status === 'warning' ? 'text-yellow-400' : 'text-red-400'
          }`}>
            {device.alert_status.charAt(0).toUpperCase() + device.alert_status.slice(1)}
          </span>
        </div>

        <div className="bg-space-secondary rounded-lg px-3 py-2">
          <span className="text-xs text-cosmic-text-muted">Sensors: </span>
          <span className="text-xs font-semibold text-cosmic-text">
            {device.sensors?.length || 0}
          </span>
        </div>
      </div>
    </div>
  );
}