// components/dashboard/DeviceCard.tsx
'use client';

import { Device } from '@/types/device';
import { StatusIndicator, StatusBadge } from '@/components/ui/StatusIndicator';
import { Button } from '@/components/ui/Button';
import { Wifi, WifiOff, Settings } from 'lucide-react';
import Link from 'next/link';
import { cn } from '@/lib/utils';

interface DeviceCardProps {
  device: Device;
  onConfigure?: (device: Device) => void; // ✅ NEW: Handler for opening preset modal
  className?: string;
}

export function DeviceCard({ device, onConfigure, className }: DeviceCardProps) {
  // Check if device is online (connected in last 10 minutes)
  const isOnline = device.last_connection && 
    new Date(device.last_connection).getTime() > Date.now() - (10 * 60 * 1000);

  // Get connection status classes
  const getConnectionClass = (online: boolean) => {
    return online 
      ? 'bg-green-500/10 border-green-500/50' 
      : 'bg-red-500/10 border-red-500/50';
  };

  // Get device status from alert_status field
  const deviceStatus = device.alert_status || 'no_data';

  // ✅ NEW: Get status-based card styling for enhanced visual feedback
  const getCardStyling = (status: string) => {
    switch (status) {
      case 'normal':
        return 'hover:border-green-500/50 hover:shadow-green-500/10';
      case 'warning':
        return 'hover:border-orange-500/50 hover:shadow-orange-500/10';
      case 'error':
        return 'hover:border-red-500/50 hover:shadow-red-500/10';
      default:
        return 'hover:border-stellar-accent/50';
    }
  };

  return (
    <div className={cn(
      'bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6 transition-all duration-200',
      getCardStyling(deviceStatus), // ✅ Enhanced status-based styling
      className
    )}>
      {/* Header with Device Name and Connection Status */}
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center space-x-3">
          {/* Device Avatar */}
          <div className="w-12 h-12 bg-gradient-cosmic rounded-xl flex items-center justify-center">
            <div className="text-white font-bold text-lg">
              {device.name.charAt(0).toUpperCase()}
            </div>
          </div>
          
          {/* Device Info */}
          <div>
            <h3 className="font-semibold text-cosmic-text">{device.name}</h3>
            <p className="text-sm text-cosmic-text-muted">{device.device_type}</p>
          </div>
        </div>
        
        {/* Connection Status Icon */}
        <div className={cn(
          'flex items-center space-x-1 px-2 py-1 rounded-full border',
          getConnectionClass(!!isOnline)
        )}>
          {isOnline ? (
            <Wifi size={14} className="text-green-400" />
          ) : (
            <WifiOff size={14} className="text-red-400" />
          )}
          <span className={cn(
            'text-xs font-medium',
            isOnline ? 'text-green-400' : 'text-red-400'
          )}>
            {isOnline ? 'Online' : 'Offline'}
          </span>
        </div>
      </div>

      {/* Device Status Section */}
      <div className="space-y-3 mb-4">
        {/* Operational Status */}
        <div className="flex items-center justify-between text-sm">
          <span className="text-cosmic-text-muted">Status:</span>
          <StatusBadge 
            status={device.status as any} 
            size="sm"
          />
        </div>
        
        {/* Alert Status - Main sensor status indicator */}
        <div className="flex items-center justify-between text-sm">
          <span className="text-cosmic-text-muted">Sensors:</span>
          <StatusIndicator 
            status={deviceStatus as any}
            size="sm"
            showText={true}
          />
        </div>
      </div>

      {/* Last Connection Info */}
      {device.last_connection && (
        <div className="text-xs text-cosmic-text-muted mb-4">
          Last seen: {new Date(device.last_connection).toLocaleString()}
        </div>
      )}

      {/* Action Buttons */}
      <div className="flex space-x-2">
        <Link href={`/user/devices/${device.id}`} className="flex-1">
          <Button variant="cosmic" size="sm" className="w-full">
            View Details
          </Button>
        </Link>
        
        {/* ✅ NEW: Configure Button with Preset Modal Handler */}
        <Button 
          variant="outline" 
          size="sm"
          onClick={() => onConfigure?.(device)}
          title="Configure Presets"
        >
          <Settings size={16} />
        </Button>
      </div>
    </div>
  );
}

// ✅ ENHANCED: More detailed device card variant
export function EnhancedDeviceCard({ device, onConfigure, className }: DeviceCardProps) {
  const isOnline = device.last_connection && 
    new Date(device.last_connection).getTime() > Date.now() - (10 * 60 * 1000);
  
  const deviceStatus = device.alert_status || 'no_data';

  // Get status-based card styling
  const getCardStyling = (status: string) => {
    switch (status) {
      case 'normal':
        return 'hover:border-green-500/50 hover:shadow-green-500/10';
      case 'warning':
        return 'hover:border-orange-500/50 hover:shadow-orange-500/10';
      case 'error':
        return 'hover:border-red-500/50 hover:shadow-red-500/10';
      default:
        return 'hover:border-stellar-accent/50';
    }
  };

  return (
    <div className={cn(
      'bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6 transition-all duration-200 hover:shadow-lg',
      getCardStyling(deviceStatus),
      className
    )}>
      {/* Status Bar at Top */}
      <div className="flex items-center justify-between mb-4">
        <StatusIndicator 
          status={deviceStatus as any}
          size="md"
          showText={true}
        />
        
        {/* Connection Indicator */}
        <div className="flex items-center space-x-1">
          {isOnline ? (
            <Wifi size={16} className="text-green-400" />
          ) : (
            <WifiOff size={16} className="text-red-400" />
          )}
        </div>
      </div>

      {/* Device Info */}
      <div className="flex items-center space-x-3 mb-4">
        <div className="w-12 h-12 bg-gradient-cosmic rounded-xl flex items-center justify-center">
          <div className="text-white font-bold text-lg">
            {device.name.charAt(0).toUpperCase()}
          </div>
        </div>
        <div>
          <h3 className="font-semibold text-cosmic-text">{device.name}</h3>
          <p className="text-sm text-cosmic-text-muted">{device.device_type}</p>
        </div>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-2 gap-3 mb-4 text-xs">
        <div>
          <span className="text-cosmic-text-muted">Status:</span>
          <div className="font-medium text-cosmic-text capitalize">
            {device.status}
          </div>
        </div>
        <div>
          <span className="text-cosmic-text-muted">Connection:</span>
          <div className={cn(
            'font-medium',
            isOnline ? 'text-green-400' : 'text-red-400'
          )}>
            {isOnline ? 'Online' : 'Offline'}
          </div>
        </div>
      </div>

      {/* Actions */}
      <div className="flex space-x-2">
        <Link href={`/user/devices/${device.id}`} className="flex-1">
          <Button variant="cosmic" size="sm" className="w-full">
            Manage
          </Button>
        </Link>
        
        {/* ✅ NEW: Configure Button */}
        <Button 
          variant="ghost" 
          size="sm"
          onClick={() => onConfigure?.(device)}
          title="Configure Presets"
        >
          <Settings size={16} />
        </Button>
      </div>
    </div>
  );
}