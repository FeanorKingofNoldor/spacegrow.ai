// components/subscription/DeviceManagementDashboard.tsx - NEW suspension management component
'use client';

import { useState } from 'react';
import { DeviceManagementData, UpsellOption } from '@/types/device';
import { Device, deviceUtils, suspensionPriority } from '@/types/device';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { CompactDeviceCard } from '@/components/dashboard/DeviceCard';
import { 
  Moon, 
  Sun, 
  Users, 
  Zap, 
  TrendingUp, 
  Clock, 
  AlertTriangle,
  CheckCircle,
  Info,
  Star,
  Plus,
  ArrowUp
} from 'lucide-react';
import { cn } from '@/lib/utils';

interface DeviceManagementDashboardProps {
  deviceManagement: DeviceManagementData;
  onsuspendedevice: (deviceId: number, reason?: string) => Promise<void>;
  onWakeDevice: (deviceId: number) => Promise<void>;
  onBulksuspend: (deviceIds: number[], reason?: string) => Promise<void>;
  onBulkWake: (deviceIds: number[]) => Promise<void>;
  onSelectUpsellOption: (option: UpsellOption) => void;
  loading?: boolean;
}

export function DeviceManagementDashboard({
  deviceManagement,
  onsuspendedevice,
  onWakeDevice,
  onBulksuspend,
  onBulkWake,
  onSelectUpsellOption,
  loading = false
}: DeviceManagementDashboardProps) {
  const [selectedDevices, setSelectedDevices] = useState<number[]>([]);
  const [showBulksuspendModal, setShowBulksuspendModal] = useState(false);
  const [bulksuspensionReason, setBulksuspensionReason] = useState('user_choice');
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  const {
    subscription,
    device_limits,
    devices,
    suspension_priorities,
    upsell_options,
    over_device_limit
  } = deviceManagement;

  // Toggle device selection
  const toggleDeviceSelection = (deviceId: number) => {
    setSelectedDevices(prev => 
      prev.includes(deviceId) 
        ? prev.filter(id => id !== deviceId)
        : [...prev, deviceId]
    );
  };

  // Select all operational devices
  const selectAllOperational = () => {
    const operationalIds = devices.operational.map(d => d.id);
    setSelectedDevices(operationalIds);
  };

  // Select all suspended devices
  const selectAllsuspended = () => {
    const suspendedIds = devices.suspended.map(d => d.id);
    setSelectedDevices(suspendedIds);
  };

  // Clear selection
  const clearSelection = () => {
    setSelectedDevices([]);
  };

  // Handle bulk suspension
  const handleBulksuspend = async () => {
    if (selectedDevices.length === 0) return;
    
    setActionLoading('bulk_suspend');
    try {
      await onBulksuspend(selectedDevices, bulksuspensionReason);
      setSelectedDevices([]);
      setShowBulksuspendModal(false);
    } catch (error) {
      console.error('Failed to suspend devices:', error);
    } finally {
      setActionLoading(null);
    }
  };

  // Handle bulk wake
  const handleBulkWake = async () => {
    if (selectedDevices.length === 0) return;
    
    setActionLoading('bulk_wake');
    try {
      await onBulkWake(selectedDevices);
      setSelectedDevices([]);
    } catch (error) {
      console.error('Failed to wake devices:', error);
    } finally {
      setActionLoading(null);
    }
  };

  // Get priority recommendation styling
  const getPriorityRecommendation = (priority: suspensionPriority) => {
    return deviceUtils.getPriorityRecommendation(priority);
  };

  return (
    <div className="space-y-6">
      {/* Header with Subscription Overview */}
      <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="text-2xl font-bold text-cosmic-text">Device Management</h2>
            <p className="text-cosmic-text-muted">
              {subscription.plan.name} Plan • {device_limits.operational_count} operational, {device_limits.suspended_count} suspended
            </p>
          </div>
          <div className="text-right">
            <div className="text-2xl font-bold text-cosmic-text">
              {device_limits.operational_count}/{device_limits.total_limit}
            </div>
            <div className="text-cosmic-text-muted text-sm">devices active</div>
          </div>
        </div>

        {/* Device Usage Bar */}
        <div className="mb-4">
          <div className="flex items-center justify-between text-sm mb-2">
            <span className="text-cosmic-text-muted">Device Usage</span>
            <span className="text-cosmic-text">
              {device_limits.available_slots} slots available
            </span>
          </div>
          <div className="w-full bg-space-border rounded-full h-3">
            <div 
              className={cn(
                'h-3 rounded-full transition-all',
                over_device_limit ? 'bg-red-400' : 'bg-cosmic-blue'
              )}
              style={{ 
                width: `${Math.min((device_limits.operational_count / device_limits.total_limit) * 100, 100)}%` 
              }}
            />
          </div>
        </div>

        {/* Over Limit Warning */}
        {over_device_limit && (
          <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-4 mb-4">
            <div className="flex items-start space-x-3">
              <AlertTriangle className="w-5 h-5 text-red-400 mt-0.5 flex-shrink-0" />
              <div>
                <h3 className="font-semibold text-red-400 mb-1">Over Device Limit</h3>
                <p className="text-red-300 text-sm">
                  You have {device_limits.operational_count} operational devices but your plan only includes {subscription.plan.device_limit}. 
                  Consider suspended some devices or upgrading your plan.
                </p>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Upsell Options */}
      {upsell_options.length > 0 && (
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
          <h3 className="text-lg font-semibold text-cosmic-text mb-4">
            Upgrade Options
          </h3>
          <div className="grid md:grid-cols-2 gap-4">
            {upsell_options.map((option, index) => (
              <div 
                key={index}
                className="border border-space-border rounded-lg p-4 hover:border-stellar-accent/50 transition-all cursor-pointer"
                onClick={() => onSelectUpsellOption(option)}
              >
                <div className="flex items-center justify-between mb-2">
                  <h4 className="font-medium text-cosmic-text">{option.title}</h4>
                  <div className="text-right">
                    <div className="font-bold text-cosmic-text">
                      {option.cost === 0 ? 'Free' : `$${option.cost}`}
                    </div>
                    {option.cost > 0 && (
                      <div className="text-xs text-cosmic-text-muted">/{option.billing}</div>
                    )}
                  </div>
                </div>
                <p className="text-cosmic-text-muted text-sm mb-3">
                  {option.description}
                </p>
                <Button 
                  variant={option.type === 'upgrade_plan' ? 'cosmic' : 'outline'} 
                  size="sm" 
                  className="w-full"
                >
                  {option.type === 'add_slots' && <Plus className="w-4 h-4 mr-2" />}
                  {option.type === 'upgrade_plan' && <TrendingUp className="w-4 h-4 mr-2" />}
                  {option.type === 'manage_devices' && <Users className="w-4 h-4 mr-2" />}
                  {option.action.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                </Button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Device Lists */}
      <div className="grid lg:grid-cols-2 gap-6">
        {/* Operational Devices */}
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center space-x-2">
              <Zap className="w-5 h-5 text-green-400" />
              <h3 className="text-lg font-semibold text-cosmic-text">
                Operational Devices ({devices.operational.length})
              </h3>
            </div>
            {devices.operational.length > 0 && (
              <Button 
                variant="outline" 
                size="sm"
                onClick={selectAllOperational}
              >
                Select All
              </Button>
            )}
          </div>

          {devices.operational.length > 0 ? (
            <div className="space-y-3">
              {devices.operational.map((device) => (
                <div key={device.id} className="relative">
                  <div 
                    className={cn(
                      'absolute left-3 top-3 w-4 h-4 rounded border-2 cursor-pointer z-10',
                      selectedDevices.includes(device.id)
                        ? 'bg-stellar-accent border-stellar-accent'
                        : 'border-cosmic-text-muted hover:border-stellar-accent'
                    )}
                    onClick={() => toggleDeviceSelection(device.id)}
                  >
                    {selectedDevices.includes(device.id) && (
                      <CheckCircle className="w-3 h-3 text-white" />
                    )}
                  </div>
                  <div className="pl-8">
                    <CompactDeviceCard
                      device={device}
                      onsuspend={onsuspendedevice}
                      className={cn(
                        selectedDevices.includes(device.id) && 'ring-2 ring-stellar-accent'
                      )}
                    />
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-8">
              <div className="w-16 h-16 bg-green-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
                <Zap className="w-8 h-8 text-green-400" />
              </div>
              <h4 className="font-medium text-cosmic-text mb-2">No Operational Devices</h4>
              <p className="text-cosmic-text-muted text-sm">
                All your devices are currently suspended
              </p>
            </div>
          )}
        </div>

        {/* suspended Devices */}
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center space-x-2">
              <Moon className="w-5 h-5 text-blue-400" />
              <h3 className="text-lg font-semibold text-cosmic-text">
                suspended Devices ({devices.suspended.length})
              </h3>
            </div>
            {devices.suspended.length > 0 && (
              <Button 
                variant="outline" 
                size="sm"
                onClick={selectAllsuspended}
              >
                Select All
              </Button>
            )}
          </div>

          {devices.suspended.length > 0 ? (
            <div className="space-y-3">
              {devices.suspended.map((device) => {
                const isInGracePeriod = deviceUtils.isInGracePeriod(device);
                const gracePeriodDays = deviceUtils.getDaysUntilGracePeriodEnd(device);
                
                return (
                  <div key={device.id} className="relative">
                    <div 
                      className={cn(
                        'absolute left-3 top-3 w-4 h-4 rounded border-2 cursor-pointer z-10',
                        selectedDevices.includes(device.id)
                          ? 'bg-stellar-accent border-stellar-accent'
                          : 'border-cosmic-text-muted hover:border-stellar-accent'
                      )}
                      onClick={() => toggleDeviceSelection(device.id)}
                    >
                      {selectedDevices.includes(device.id) && (
                        <CheckCircle className="w-3 h-3 text-white" />
                      )}
                    </div>
                    <div className="pl-8">
                      <CompactDeviceCard
                        device={device}
                        onWake={onWakeDevice}
                        className={cn(
                          selectedDevices.includes(device.id) && 'ring-2 ring-stellar-accent'
                        )}
                      />
                      {isInGracePeriod && (
                        <div className="mt-2 ml-4 text-xs text-orange-400">
                          <Clock className="w-3 h-3 inline mr-1" />
                          Grace period: {gracePeriodDays} days remaining
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="text-center py-8">
              <div className="w-16 h-16 bg-blue-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
                <Moon className="w-8 h-8 text-blue-400" />
              </div>
              <h4 className="font-medium text-cosmic-text mb-2">No suspended Devices</h4>
              <p className="text-cosmic-text-muted text-sm">
                All your devices are currently operational
              </p>
            </div>
          )}
        </div>
      </div>

      {/* suspension Priorities */}
      {suspension_priorities.length > 0 && (
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
          <div className="flex items-center space-x-2 mb-4">
            <Star className="w-5 h-5 text-stellar-accent" />
            <h3 className="text-lg font-semibold text-cosmic-text">suspension Priorities</h3>
            <div className="text-cosmic-text-muted text-sm">
              (Devices ranked by suspension recommendation)
            </div>
          </div>

          <div className="space-y-3">
            {suspension_priorities.map((priority) => {
              const recommendation = getPriorityRecommendation(priority);
              return (
                <div 
                  key={priority.device_id}
                  className="flex items-center justify-between bg-space-secondary rounded-lg p-4"
                >
                  <div className="flex items-center space-x-3">
                    <div className="w-8 h-8 bg-gradient-cosmic rounded-lg flex items-center justify-center">
                      <div className="text-white font-bold text-sm">
                        {priority.device_name.charAt(0).toUpperCase()}
                      </div>
                    </div>
                    <div>
                      <h4 className="font-medium text-cosmic-text">{priority.device_name}</h4>
                      <p className="text-cosmic-text-muted text-sm">
                        {priority.last_connection 
                          ? `Last seen: ${new Date(priority.last_connection).toLocaleDateString()}`
                          : 'Never connected'
                        }
                      </p>
                    </div>
                  </div>
                  
                  <div className="flex items-center space-x-4">
                    <div className="text-center">
                      <div className="text-lg font-bold text-cosmic-text">{priority.score}</div>
                      <div className="text-xs text-cosmic-text-muted">Priority</div>
                    </div>
                    <div className={cn('text-sm font-medium', recommendation.color)}>
                      {recommendation.icon} {recommendation.text}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Bulk Actions */}
      {selectedDevices.length > 0 && (
        <div className="fixed bottom-6 left-1/2 transform -translate-x-1/2 bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-4 shadow-lg">
          <div className="flex items-center space-x-4">
            <span className="text-cosmic-text font-medium">
              {selectedDevices.length} device{selectedDevices.length > 1 ? 's' : ''} selected
            </span>
            
            <Button 
              variant="outline" 
              size="sm"
              onClick={() => setShowBulksuspendModal(true)}
              disabled={actionLoading === 'bulk_suspend'}
            >
              <Moon className="w-4 h-4 mr-2" />
              suspend Selected
            </Button>
            
            <Button 
              variant="outline" 
              size="sm"
              onClick={handleBulkWake}
              disabled={actionLoading === 'bulk_wake'}
            >
              {actionLoading === 'bulk_wake' ? (
                <LoadingSpinner size="sm" />
              ) : (
                <Sun className="w-4 h-4 mr-2" />
              )}
              Wake Selected
            </Button>
            
            <Button 
              variant="ghost" 
              size="sm"
              onClick={clearSelection}
            >
              Clear
            </Button>
          </div>
        </div>
      )}

      {/* Bulk suspension Modal */}
      <Modal
        isOpen={showBulksuspendModal}
        onClose={() => setShowBulksuspendModal(false)}
        title="suspend Multiple Devices"
        size="md"
      >
        <div className="space-y-6">
          <div className="flex items-start space-x-3">
            <div className="w-12 h-12 bg-blue-500/20 rounded-xl flex items-center justify-center flex-shrink-0">
              <Moon className="w-6 h-6 text-blue-400" />
            </div>
            <div>
              <h3 className="text-lg font-semibold text-cosmic-text mb-2">
                suspend {selectedDevices.length} Device{selectedDevices.length > 1 ? 's' : ''}?
              </h3>
              <p className="text-cosmic-text-muted text-sm">
                The selected devices will stop processing data and go into sleep mode. 
                You can wake them up anytime within their grace periods.
              </p>
            </div>
          </div>

          {/* suspension Reason Selection */}
          <div>
            <label className="block text-sm font-medium text-cosmic-text mb-2">
              Reason for suspension:
            </label>
            <select
              value={bulksuspensionReason}
              onChange={(e) => setBulksuspensionReason(e.target.value)}
              className="w-full bg-space-secondary border border-space-border rounded-lg px-3 py-2 text-cosmic-text focus:outline-none focus:ring-2 focus:ring-stellar-accent"
            >
              <option value="user_choice">User choice</option>
              <option value="temporary_shutdown">Temporary shutdown</option>
              <option value="maintenance">Maintenance</option>
              <option value="cost_optimization">Cost optimization</option>
              <option value="over_limit">Over subscription limit</option>
            </select>
          </div>

          {/* Action Buttons */}
          <div className="flex space-x-3">
            <Button 
              variant="ghost"
              onClick={() => setShowBulksuspendModal(false)}
              disabled={actionLoading === 'bulk_suspend'}
              className="flex-1"
            >
              Cancel
            </Button>
            <Button 
              variant="cosmic"
              onClick={handleBulksuspend}
              disabled={actionLoading === 'bulk_suspend'}
              className="flex-1 bg-blue-500 hover:bg-blue-600"
            >
              {actionLoading === 'bulk_suspend' ? (
                <>
                  <LoadingSpinner size="sm" />
                  <span className="ml-2">suspended...</span>
                </>
              ) : (
                <>
                  <Moon size={16} className="mr-2" />
                  suspend {selectedDevices.length} Device{selectedDevices.length > 1 ? 's' : ''}
                </>
              )}
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}