// app/(dashboard)/user/devices/page.tsx
'use client';

import { useState, useEffect } from 'react';
import { DashboardLayoutWrapper } from '@/components/dashboard/DashboardLayoutWrapper';
import { Button } from '@/components/ui/Button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { DeviceCard } from '@/components/dashboard/DeviceCard';
import { PresetModal } from '@/components/dashboard/presets/PresetModal';
import { SubscriptionBanner } from '@/components/subscription/SubscriptionBanner';
import { useAuth } from '@/contexts/AuthContext';
import { Device } from '@/types/device';
import { api } from '@/lib/api';
import { useDeviceListWebSocket } from '@/hooks/useDashboardWebSocket';
import { Plus, Search, Filter, AlertTriangle, CheckCircle, XCircle, Zap, Crown, Star, ArrowUp } from 'lucide-react';

// Enhanced User type to include subscription info
interface UserWithSubscription {
  id: number;
  email: string;
  role: 'user' | 'pro' | 'admin';
  device_limit: number;
  available_device_slots: number;
  subscription?: {
    plan: {
      name: string;
      device_limit: number;
    };
    additional_device_slots: number;
    status: string;
  };
}

// Upgrade Modal Component
interface UpgradeModalProps {
  currentTier: string;
  onClose: () => void;
}

function UpgradeModal({ currentTier, onClose }: UpgradeModalProps) {
  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6 max-w-md w-full">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-xl font-bold text-cosmic-text">Upgrade Your Plan</h3>
          <button 
            onClick={onClose}
            className="text-cosmic-text-muted hover:text-cosmic-text"
          >
            ×
          </button>
        </div>

        <div className="space-y-4">
          <div className="border border-space-border rounded-lg p-4">
            <div className="flex items-center space-x-2 mb-2">
              <Star className="text-yellow-400" size={20} />
              <h4 className="font-semibold text-cosmic-text">Professional Plan</h4>
            </div>
            <p className="text-cosmic-text-muted text-sm mb-3">
              Up to 4 devices included + advanced features
            </p>
            <div className="flex items-center justify-between">
              <span className="text-2xl font-bold text-cosmic-text">$30/mo</span>
              <Button variant="cosmic" size="sm">
                Upgrade Now
              </Button>
            </div>
          </div>

          <div className="border border-space-border rounded-lg p-4">
            <div className="flex items-center space-x-2 mb-2">
              <Plus className="text-cosmic-blue" size={20} />
              <h4 className="font-semibold text-cosmic-text">Extra Device Slots</h4>
            </div>
            <p className="text-cosmic-text-muted text-sm mb-3">
              Add extra device slots to any plan
            </p>
            <div className="flex items-center justify-between">
              <span className="text-2xl font-bold text-cosmic-text">$5/mo</span>
              <Button variant="stellar" size="sm">
                Add Slot
              </Button>
            </div>
          </div>
        </div>

        <div className="mt-6 text-center">
          <p className="text-xs text-cosmic-text-muted">
            All plans include 24/7 support and cloud sync
          </p>
        </div>
      </div>
    </div>
  );
}

export default function MyDevicesPage() {
  const [devices, setDevices] = useState<Device[]>([]);
  const [userWithSub, setUserWithSub] = useState<UserWithSubscription | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState<'all' | 'active' | 'pending' | 'disabled'>('all');
  const [showUpgradeModal, setShowUpgradeModal] = useState(false);
  
  // ✅ NEW: Preset Modal State
  const [selectedDeviceForPresets, setSelectedDeviceForPresets] = useState<Device | null>(null);
  const [showPresetModal, setShowPresetModal] = useState(false);

  const { user } = useAuth();

  // ✅ Device update function for WebSocket
  const updateDevice = (deviceId: string, updates: Partial<Device>) => {
    setDevices(prevDevices => 
      prevDevices.map(device => 
        String(device.id) === deviceId 
          ? { ...device, ...updates }
          : device
      )
    );
  };

  // ✅ WebSocket connection for real-time status updates
  const { connectionStatus, isConnected } = useDeviceListWebSocket(devices, updateDevice);

  // ✅ NEW: Handle Configure Button Click
  const handleConfigure = (device: Device) => {
    console.log('🔧 Opening preset modal for device:', device.name);
    setSelectedDeviceForPresets(device);
    setShowPresetModal(true);
  };

  // ✅ NEW: Handle Preset Modal Close
  const handlePresetModalClose = () => {
    setShowPresetModal(false);
    setSelectedDeviceForPresets(null);
  };

  // ✅ NEW: Handle Preset Applied Successfully
  const handlePresetApplied = (preset: any) => {
    console.log('✅ Preset applied successfully:', preset.name);
    // Optionally show success notification here
    // The device status will be updated via WebSocket automatically
  };

  // Fetch user devices and subscription info using API client
  useEffect(() => {
    const fetchDevicesAndSubscription = async () => {
      if (!user) return;

      try {
        console.log('🔄 Fetching devices and dashboard data...');

        // Fetch devices using API client
        const devicesResult = await api.devices.list() as { status: string; data: Device[]; message?: string } | Device[];
        console.log('📱 Devices result:', devicesResult);
        
        if ('status' in devicesResult && devicesResult.status === 'success' && devicesResult.data) {
          setDevices(devicesResult.data);
        } else if (Array.isArray(devicesResult)) {
          // Handle case where devices are returned directly
          setDevices(devicesResult);
        }

        // Fetch dashboard data using API client
        const dashboardResult = await api.dashboard.overview() as { 
          status: string; 
          data: UserWithSubscription; 
          message?: string 
        } | UserWithSubscription;
        console.log('📊 Dashboard result:', dashboardResult);
        
        if ('status' in dashboardResult && dashboardResult.status === 'success' && dashboardResult.data) {
          console.log('✅ Setting userWithSub:', dashboardResult.data);
          setUserWithSub(dashboardResult.data);
        } else if ('id' in dashboardResult) {
          // Handle case where data is returned directly
          setUserWithSub(dashboardResult);
        } else {
          console.log('❌ Dashboard result structure unexpected:', dashboardResult);
        }

      } catch (err) {
        console.error('❌ Failed to fetch data:', err);
        setError(err instanceof Error ? err.message : 'Failed to fetch data');
      } finally {
        setLoading(false);
      }
    };

    fetchDevicesAndSubscription();
  }, [user]);

  // Filter devices for list view
  const filteredDevices = devices.filter(device => {
    const matchesSearch = device.name.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = filterStatus === 'all' || device.status === filterStatus;
    return matchesSearch && matchesStatus;
  });

  // Get tier info for display
  const getTierInfo = () => {
    if (!userWithSub) return null;
    
    const planName = userWithSub.subscription?.plan.name || 
      (userWithSub.role === 'pro' ? 'Pro' : userWithSub.role === 'admin' ? 'Admin' : 'Basic');
    
    const baseLimit = userWithSub.subscription?.plan.device_limit || userWithSub.device_limit;
    const additionalSlots = userWithSub.subscription?.additional_device_slots || 0;
    const totalLimit = baseLimit + additionalSlots;
    
    return {
      planName,
      baseLimit,
      additionalSlots,
      totalLimit,
      usedSlots: devices.length
    };
  };

  const getTierIcon = () => {
    if (!userWithSub) return <Zap className="text-cosmic-blue" size={20} />;
    
    switch (userWithSub.role) {
      case 'admin': return <Crown className="text-purple-400" size={20} />;
      case 'pro': return <Star className="text-yellow-400" size={20} />;
      default: return <Zap className="text-cosmic-blue" size={20} />;
    }
  };

  // Calculate stats
  const stats = {
    total: devices.length,
    active: devices.filter(d => d.status === 'active').length,
    warning: devices.filter(d => d.alert_status === 'warning').length,
    error: devices.filter(d => d.alert_status === 'error').length
  };

  const tierInfo = getTierInfo();

  if (loading) {
    return (
      <DashboardLayoutWrapper>
        <div className="flex items-center justify-center h-96">
          <LoadingSpinner />
        </div>
      </DashboardLayoutWrapper>
    );
  }

  return (
    <DashboardLayoutWrapper>
      <div className="space-y-6">
        {/* Header with Tier Info */}
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                {getTierIcon()}
                <div>
                  <h1 className="text-2xl font-bold text-cosmic-text">My Devices</h1>
                  {tierInfo && (
                    <p className="text-cosmic-text-muted">
                      {tierInfo.usedSlots}/{tierInfo.totalLimit} slots used • {tierInfo.planName} Plan
                      {tierInfo.additionalSlots > 0 && (
                        <span className="text-stellar-accent"> (+{tierInfo.additionalSlots} extra)</span>
                      )}
                    </p>
                  )}
                </div>
              </div>
              
              {/* WebSocket Status Indicator */}
              <div className="flex items-center space-x-2">
                <div className={`w-2 h-2 rounded-full ${
                  isConnected ? 'bg-green-400' : 'bg-gray-400'
                }`} />
                <span className="text-xs text-cosmic-text-muted">
                  {isConnected ? 'Live' : 'Offline'}
                </span>
              </div>
            </div>
            
            <div className="flex items-center space-x-3">
              {userWithSub?.role !== 'admin' && (
                <Button
                  variant="cosmic"
                  onClick={() => setShowUpgradeModal(true)}
                  size="sm"
                >
                  <ArrowUp size={16} className="mr-2" />
                  Upgrade
                </Button>
              )}
            </div>
          </div>
        </div>

        {/* ✅ NEW: Subscription Alerts */}
        <SubscriptionBanner />

        {/* Stats Cards */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-4">
            <div className="flex items-center space-x-2">
              <div className="w-8 h-8 bg-cosmic-blue/20 rounded-lg flex items-center justify-center">
                <CheckCircle size={16} className="text-cosmic-blue" />
              </div>
              <div>
                <p className="text-2xl font-bold text-cosmic-text">{stats.total}</p>
                <p className="text-xs text-cosmic-text-muted">Total Devices</p>
              </div>
            </div>
          </div>

          <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-4">
            <div className="flex items-center space-x-2">
              <div className="w-8 h-8 bg-green-500/20 rounded-lg flex items-center justify-center">
                <CheckCircle size={16} className="text-green-400" />
              </div>
              <div>
                <p className="text-2xl font-bold text-green-400">{stats.active}</p>
                <p className="text-xs text-cosmic-text-muted">Active</p>
              </div>
            </div>
          </div>

          <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-4">
            <div className="flex items-center space-x-2">
              <div className="w-8 h-8 bg-yellow-500/20 rounded-lg flex items-center justify-center">
                <AlertTriangle size={16} className="text-yellow-400" />
              </div>
              <div>
                <p className="text-2xl font-bold text-yellow-400">{stats.warning}</p>
                <p className="text-xs text-cosmic-text-muted">Warnings</p>
              </div>
            </div>
          </div>

          <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-4">
            <div className="flex items-center space-x-2">
              <div className="w-8 h-8 bg-red-500/20 rounded-lg flex items-center justify-center">
                <XCircle size={16} className="text-red-400" />
              </div>
              <div>
                <p className="text-2xl font-bold text-red-400">{stats.error}</p>
                <p className="text-xs text-cosmic-text-muted">Errors</p>
              </div>
            </div>
          </div>
        </div>

        {/* Search and Filter */}
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-4">
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="relative flex-1">
              <Search size={20} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-cosmic-text-muted" />
              <input
                type="text"
                placeholder="Search devices..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-space-secondary border border-space-border rounded-lg text-cosmic-text placeholder-cosmic-text-muted focus:outline-none focus:ring-2 focus:ring-stellar-accent"
              />
            </div>

            <div className="flex items-center space-x-2">
              <Filter size={20} className="text-cosmic-text-muted" />
              <select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value as any)}
                className="bg-space-secondary border border-space-border rounded-lg px-3 py-2 text-cosmic-text focus:outline-none focus:ring-2 focus:ring-stellar-accent"
              >
                <option value="all">All Status</option>
                <option value="active">Active</option>
                <option value="pending">Pending</option>
                <option value="disabled">Disabled</option>
              </select>
            </div>
          </div>
        </div>

        {/* Devices List */}
        {filteredDevices.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredDevices.map((device) => (
              <DeviceCard 
                key={device.id} 
                device={device}
                onConfigure={handleConfigure} // ✅ NEW: Pass configure handler
              />
            ))}
          </div>
        ) : (
          <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-12 text-center">
            <div className="w-16 h-16 bg-cosmic-text/10 rounded-full flex items-center justify-center mx-auto mb-4">
              <Plus size={32} className="text-cosmic-text-muted" />
            </div>
            <h3 className="text-cosmic-text font-semibold mb-2">
              {searchTerm || filterStatus !== 'all' ? 'No devices found' : 'No devices yet'}
            </h3>
            <p className="text-cosmic-text-muted mb-6">
              {searchTerm || filterStatus !== 'all' 
                ? 'Try adjusting your search or filter criteria'
                : 'Get started by adding your first IoT device'
              }
            </p>
            {!searchTerm && filterStatus === 'all' && (
              <Button variant="cosmic">
                <Plus size={20} className="mr-2" />
                Add Your First Device
              </Button>
            )}
          </div>
        )}

        {/* Error State */}
        {error && (
          <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-6 text-center">
            <h3 className="text-red-400 font-semibold mb-2">Error Loading Data</h3>
            <p className="text-cosmic-text-muted">{error}</p>
          </div>
        )}

        {/* ✅ NEW: Preset Modal */}
        {selectedDeviceForPresets && (
          <PresetModal
            isOpen={showPresetModal}
            onClose={handlePresetModalClose}
            device={selectedDeviceForPresets}
            onPresetApplied={handlePresetApplied}
          />
        )}

        {/* Upgrade Modal */}
        {showUpgradeModal && (
          <UpgradeModal 
            currentTier={userWithSub?.role || 'user'}
            onClose={() => setShowUpgradeModal(false)}
          />
        )}
      </div>
    </DashboardLayoutWrapper>
  );
}