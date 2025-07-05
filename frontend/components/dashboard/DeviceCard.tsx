// components/dashboard/DeviceCard.tsx - ENHANCED with hibernation support
'use client';

import { Device, deviceUtils } from '@/types/device';
import { StatusIndicator, StatusBadge } from '@/components/ui/StatusIndicator';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { useState } from 'react';
import { 
  Wifi, 
  WifiOff, 
  Settings, 
  Moon, 
  Sun, 
  Clock, 
  AlertTriangle,
  Info,
  Zap
} from 'lucide-react';
import Link from 'next/link';
import { cn } from '@/lib/utils';

interface DeviceCardProps {
  device: Device;
  onConfigure?: (device: Device) => void;
  onHibernate?: (deviceId: number, reason?: string) => Promise<void>;
  onWake?: (deviceId: number) => Promise<void>;
  className?: string;
  showHibernationControls?: boolean;
  loading?: boolean;
}

export function DeviceCard({ 
  device, 
  onConfigure, 
  onHibernate,
  onWake,
  className,
  showHibernationControls = true,
  loading = false
}: DeviceCardProps) {
  const [showHibernateModal, setShowHibernateModal] = useState(false);
  const [hibernationReason, setHibernationReason] = useState('user_choice');
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  // Check if device is online (connected in last 10 minutes)
  const isOnline = device.last_connection && 
    new Date(device.last_connection).getTime() > Date.now() - (10 * 60 * 1000);

  // Get hibernation status
  const hibernationStatus = deviceUtils.getHibernationStatus(device);
  const isHibernating = deviceUtils.isHibernating(device);
  const isOperational = deviceUtils.isOperational(device);
  const isInGracePeriod = deviceUtils.isInGracePeriod(device);
  const gracePeriodDays = deviceUtils.getDaysUntilGracePeriodEnd(device);

  // Get connection status classes
  const getConnectionClass = (online: boolean) => {
    return online 
      ? 'bg-green-500/10 border-green-500/50' 
      : 'bg-red-500/10 border-red-500/50';
  };

  // Get device status from alert_status field
  const deviceStatus = device.alert_status || 'no_data';

  // ✅ ENHANCED: Get status-based card styling with hibernation awareness
  const getCardStyling = (status: string, hibernationStatus: string) => {
    if (hibernationStatus === 'hibernating') {
      return 'hover:border-blue-500/50 hover:shadow-blue-500/10 border-blue-500/20';
    }
    if (hibernationStatus === 'grace_period') {
      return 'hover:border-orange-500/50 hover:shadow-orange-500/10 border-orange-500/20';
    }
    
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

  const handleHibernate = async () => {
    if (!onHibernate) return;
    
    setActionLoading('hibernate');
    try {
      await onHibernate(device.id, hibernationReason);
      setShowHibernateModal(false);
    } catch (error) {
      console.error('Failed to hibernate device:', error);
    } finally {
      setActionLoading(null);
    }
  };

  const handleWake = async () => {
    if (!onWake) return;
    
    setActionLoading('wake');
    try {
      await onWake(device.id);
    } catch (error) {
      console.error('Failed to wake device:', error);
    } finally {
      setActionLoading(null);
    }
  };

  return (
    <>
      <div className={cn(
        'bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6 transition-all duration-200',
        getCardStyling(deviceStatus, hibernationStatus),
        loading && 'opacity-50 pointer-events-none',
        className
      )}>
        {/* Header with Device Name and Status */}
        <div className="flex items-start justify-between mb-4">
          <div className="flex items-center space-x-3">
            {/* Device Avatar */}
            <div className={cn(
              'w-12 h-12 rounded-xl flex items-center justify-center',
              isHibernating ? 'bg-blue-500/20' : 'bg-gradient-cosmic'
            )}>
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
          
          {/* ✅ ENHANCED: Hibernation Status or Connection Status */}
          {isHibernating ? (
            <div className={cn(
              'flex items-center space-x-1 px-2 py-1 rounded-full border',
              deviceUtils.getHibernationColor(device)
            )}>
              {isInGracePeriod ? (
                <Clock size={14} className="text-orange-400" />
              ) : (
                <Moon size={14} className="text-blue-400" />
              )}
              <span className={cn(
                'text-xs font-medium',
                isInGracePeriod ? 'text-orange-400' : 'text-blue-400'
              )}>
                {isInGracePeriod ? `Grace: ${gracePeriodDays}d` : 'Hibernating'}
              </span>
            </div>
          ) : (
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
          )}
        </div>

        {/* ✅ NEW: Hibernation Info Banner */}
        {isHibernating && (
          <div className={cn(
            'mb-4 p-3 rounded-lg border',
            isInGracePeriod 
              ? 'bg-orange-500/10 border-orange-500/20' 
              : 'bg-blue-500/10 border-blue-500/20'
          )}>
            <div className="flex items-start space-x-2">
              {isInGracePeriod ? (
                <Clock size={16} className="text-orange-400 mt-0.5 flex-shrink-0" />
              ) : (
                <Moon size={16} className="text-blue-400 mt-0.5 flex-shrink-0" />
              )}
              <div className="text-sm">
                <p className={cn(
                  'font-medium',
                  isInGracePeriod ? 'text-orange-400' : 'text-blue-400'
                )}>
                  {isInGracePeriod ? 'Grace Period Active' : 'Device Hibernating'}
                </p>
                <p className="text-cosmic-text-muted text-xs mt-1">
                  {isInGracePeriod 
                    ? `${gracePeriodDays} days remaining to reactivate`
                    : `Reason: ${deviceUtils.formatHibernationReason(device.hibernated_reason)}`
                  }
                </p>
              </div>
            </div>
          </div>
        )}

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
          
          {/* Alert Status - Only show for operational devices */}
          {!isHibernating && (
            <div className="flex items-center justify-between text-sm">
              <span className="text-cosmic-text-muted">Sensors:</span>
              <StatusIndicator 
                status={deviceStatus as any}
                size="sm"
                showText={true}
              />
            </div>
          )}

          {/* ✅ NEW: Hibernation Status Display */}
          <div className="flex items-center justify-between text-sm">
            <span className="text-cosmic-text-muted">Mode:</span>
            <span className={cn(
              'text-xs font-medium px-2 py-1 rounded-full',
              isHibernating 
                ? (isInGracePeriod ? 'bg-orange-500/20 text-orange-400' : 'bg-blue-500/20 text-blue-400')
                : 'bg-green-500/20 text-green-400'
            )}>
              {deviceUtils.getHibernationDisplayText(device)}
            </span>
          </div>
        </div>

        {/* Last Connection Info - Only for operational devices */}
        {!isHibernating && device.last_connection && (
          <div className="text-xs text-cosmic-text-muted mb-4">
            Last seen: {new Date(device.last_connection).toLocaleString()}
          </div>
        )}

        {/* ✅ ENHANCED: Action Buttons with Hibernation Controls */}
        <div className="flex space-x-2">
          <Link href={`/user/devices/${device.id}`} className="flex-1">
            <Button variant="cosmic" size="sm" className="w-full">
              View Details
            </Button>
          </Link>
          
          {/* Configure Button */}
          <Button 
            variant="outline" 
            size="sm"
            onClick={() => onConfigure?.(device)}
            title="Configure Presets"
            disabled={loading}
          >
            <Settings size={16} />
          </Button>

          {/* ✅ NEW: Hibernation Controls */}
          {showHibernationControls && (
            <>
              {isOperational && onHibernate && (
                <Button 
                  variant="ghost" 
                  size="sm"
                  onClick={() => setShowHibernateModal(true)}
                  title="Hibernate Device"
                  disabled={loading || actionLoading === 'hibernate'}
                  className="text-blue-400 hover:text-blue-300"
                >
                  {actionLoading === 'hibernate' ? (
                    <LoadingSpinner size="sm" />
                  ) : (
                    <Moon size={16} />
                  )}
                </Button>
              )}

              {isHibernating && onWake && (
                <Button 
                  variant="ghost" 
                  size="sm"
                  onClick={handleWake}
                  title="Wake Device"
                  disabled={loading || actionLoading === 'wake'}
                  className="text-green-400 hover:text-green-300"
                >
                  {actionLoading === 'wake' ? (
                    <LoadingSpinner size="sm" />
                  ) : (
                    <Sun size={16} />
                  )}
                </Button>
              )}
            </>
          )}
        </div>

        {/* Loading Overlay */}
        {loading && (
          <div className="absolute inset-0 bg-space-glass/50 backdrop-blur-sm rounded-xl flex items-center justify-center">
            <LoadingSpinner size="sm" />
          </div>
        )}
      </div>

      {/* ✅ NEW: Hibernation Confirmation Modal */}
      <Modal
        isOpen={showHibernateModal}
        onClose={() => setShowHibernateModal(false)}
        title="Hibernate Device"
        size="sm"
      >
        <div className="space-y-6">
          <div className="flex items-start space-x-3">
            <div className="w-12 h-12 bg-blue-500/20 rounded-xl flex items-center justify-center flex-shrink-0">
              <Moon className="w-6 h-6 text-blue-400" />
            </div>
            <div>
              <h3 className="text-lg font-semibold text-cosmic-text mb-2">
                Hibernate "{device.name}"?
              </h3>
              <p className="text-cosmic-text-muted text-sm">
                This device will stop processing data and go into sleep mode. 
                You can wake it up anytime within the grace period.
              </p>
            </div>
          </div>

          {/* Hibernation Reason Selection */}
          <div>
            <label className="block text-sm font-medium text-cosmic-text mb-2">
              Reason for hibernation:
            </label>
            <select
              value={hibernationReason}
              onChange={(e) => setHibernationReason(e.target.value)}
              className="w-full bg-space-secondary border border-space-border rounded-lg px-3 py-2 text-cosmic-text focus:outline-none focus:ring-2 focus:ring-stellar-accent"
            >
              <option value="user_choice">User choice</option>
              <option value="temporary_shutdown">Temporary shutdown</option>
              <option value="maintenance">Maintenance</option>
              <option value="testing">Testing purposes</option>
              <option value="cost_optimization">Cost optimization</option>
            </select>
          </div>

          {/* Grace Period Info */}
          <div className="bg-blue-500/10 border border-blue-500/20 rounded-lg p-3">
            <div className="flex items-start space-x-2">
              <Info size={16} className="text-blue-400 mt-0.5 flex-shrink-0" />
              <div className="text-sm">
                <p className="text-blue-400 font-medium">Grace Period: 7 days</p>
                <p className="text-cosmic-text-muted mt-1">
                  You can wake this device anytime within 7 days. After that, 
                  it will remain hibernated until manually activated.
                </p>
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex space-x-3">
            <Button 
              variant="ghost"
              onClick={() => setShowHibernateModal(false)}
              disabled={actionLoading === 'hibernate'}
              className="flex-1"
            >
              Cancel
            </Button>
            <Button 
              variant="cosmic"
              onClick={handleHibernate}
              disabled={actionLoading === 'hibernate'}
              className="flex-1 bg-blue-500 hover:bg-blue-600"
            >
              {actionLoading === 'hibernate' ? (
                <>
                  <LoadingSpinner size="sm" />
                  <span className="ml-2">Hibernating...</span>
                </>
              ) : (
                <>
                  <Moon size={16} className="mr-2" />
                  Hibernate Device
                </>
              )}
            </Button>
          </div>
        </div>
      </Modal>
    </>
  );
}

// ✅ ENHANCED: Compact device card variant for lists
export function CompactDeviceCard({ device, onHibernate, onWake, className }: DeviceCardProps) {
  const isHibernating = deviceUtils.isHibernating(device);
  const isInGracePeriod = deviceUtils.isInGracePeriod(device);
  const gracePeriodDays = deviceUtils.getDaysUntilGracePeriodEnd(device);

  return (
    <div className={cn(
      'bg-space-secondary rounded-lg p-4 flex items-center justify-between transition-all hover:bg-space-glass',
      className
    )}>
      <div className="flex items-center space-x-3">
        <div className={cn(
          'w-10 h-10 rounded-lg flex items-center justify-center',
          isHibernating ? 'bg-blue-500/20' : 'bg-gradient-cosmic'
        )}>
          <div className="text-white font-bold text-sm">
            {device.name.charAt(0).toUpperCase()}
          </div>
        </div>
        <div>
          <h4 className="font-medium text-cosmic-text">{device.name}</h4>
          <p className="text-cosmic-text-muted text-sm">{device.device_type}</p>
        </div>
      </div>
      
      <div className="flex items-center space-x-3">
        {/* Status Badge */}
        <span className={cn(
          'px-2 py-1 text-xs font-medium rounded-full',
          isHibernating 
            ? (isInGracePeriod ? 'bg-orange-500/20 text-orange-400' : 'bg-blue-500/20 text-blue-400')
            : (device.status === 'active' ? 'bg-green-500/20 text-green-400' : 'bg-gray-500/20 text-gray-400')
        )}>
          {isHibernating 
            ? (isInGracePeriod ? `Grace: ${gracePeriodDays}d` : 'Hibernating')
            : device.status
          }
        </span>

        {/* Quick Action Button */}
        {isHibernating && onWake ? (
          <Button variant="ghost" size="sm" onClick={() => onWake(device.id)}>
            <Sun size={14} className="text-green-400" />
          </Button>
        ) : (
          onHibernate && (
            <Button variant="ghost" size="sm" onClick={() => onHibernate(device.id, 'user_choice')}>
              <Moon size={14} className="text-blue-400" />
            </Button>
          )
        )}
      </div>
    </div>
  );
}