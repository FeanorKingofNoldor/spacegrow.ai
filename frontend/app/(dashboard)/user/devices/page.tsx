// app/(dashboard)/user/devices/page.tsx - My Devices List Page with Tier-Aware Grid
'use client';

import { useState, useEffect } from 'react';
import { DashboardLayoutWrapper } from '@/components/dashboard/DashboardLayoutWrapper';
import { Button } from '@/components/ui/Button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { useAuth } from '@/contexts/AuthContext';
import { Device } from '@/types/device';
import { Plus, Search, Filter, Wifi, WifiOff, AlertTriangle, CheckCircle, XCircle, Lock, Zap, Crown, Star, ArrowUp, Settings } from 'lucide-react';
import Link from 'next/link';

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

interface DeviceSlot {
  id: string;
  type: 'device' | 'empty' | 'locked';
  device?: Device;
  position: number;
  canAdd: boolean;
  lockReason?: string;
}

export default function MyDevicesPage() {
  const [devices, setDevices] = useState<Device[]>([]);
  const [userWithSub, setUserWithSub] = useState<UserWithSubscription | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState<'all' | 'active' | 'pending' | 'disabled'>('all');
  const [showUpgradeModal, setShowUpgradeModal] = useState(false);
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const { user } = useAuth();

 // Fetch user devices and subscription info
useEffect(() => {
 const fetchDevicesAndSubscription = async () => {
   if (!user) return;

   try {
     // Fetch devices
     const devicesResponse = await fetch('/api/v1/frontend/devices', {
       headers: {
         'Authorization': `Bearer ${localStorage.getItem('auth_token')}`,
         'Content-Type': 'application/json'
       }
     });

     if (!devicesResponse.ok) {
       throw new Error(`HTTP error! status: ${devicesResponse.status}`);
     }

     const devicesResult = await devicesResponse.json();
     if (devicesResult.status === 'success') {
       setDevices(devicesResult.data);
     }

     // Fetch dashboard data (includes subscription info)
 //    console.log('🌐 Fetching dashboard data...');
     const dashboardResponse = await fetch('/api/v1/frontend/dashboard', {
       headers: {
         'Authorization': `Bearer ${localStorage.getItem('auth_token')}`,
         'Content-Type': 'application/json'
       }
     });

   //  console.log('🌐 Dashboard Response Status:', dashboardResponse.status);
   //  console.log('🌐 Dashboard Response OK:', dashboardResponse.ok);

     if (dashboardResponse.ok) {
       const dashboardResult = await dashboardResponse.json();
  //     console.log('📊 Dashboard Result:', dashboardResult);
       
			if (dashboardResult.status === 'success' && dashboardResult.data) {
//		console.log('✅ Setting userWithSub:', dashboardResult.data);
		setUserWithSub(dashboardResult.data);
		} else {
  //       console.log('❌ Dashboard result structure unexpected:', dashboardResult);
       }
     } else {
//       console.log('❌ Dashboard API call failed');
     }

   } catch (err) {
//     console.error('❌ Failed to fetch data:', err);
     setError(err instanceof Error ? err.message : 'Failed to fetch data');
   } finally {
     setLoading(false);
   }
 };

 fetchDevicesAndSubscription();
}, [user]);

  // Calculate device slots based on user tier and subscription
  const calculateDeviceSlots = (): DeviceSlot[] => {
    if (!userWithSub) return [];
    
    const slots: DeviceSlot[] = [];
    const totalSlots = 9; // 3x3 grid
    
    // Determine actual device limit based on role and subscription
    let actualDeviceLimit = userWithSub.device_limit;
    if (userWithSub.subscription) {
      actualDeviceLimit = userWithSub.subscription.plan.device_limit + userWithSub.subscription.additional_device_slots;
    }

    for (let i = 0; i < totalSlots; i++) {
      const position = i + 1;
      
      // Check if this slot has a device
      const device = devices[i];
      
      if (device) {
        // Slot has a device
        slots.push({
          id: `device-${device.id}`,
          type: 'device',
          device,
          position,
          canAdd: false
        });
      } else if (position <= actualDeviceLimit) {
        // Slot is available for adding a device
        slots.push({
          id: `empty-${position}`,
          type: 'empty',
          position,
          canAdd: true
        });
      } else {
        // Slot is locked based on tier
        let lockReason = '';
        if (userWithSub.role === 'user' && position > 2) {
          lockReason = 'Upgrade to Pro';
        } else if (userWithSub.role === 'pro' && position > 10) {
          lockReason = 'Add Extra Slot ($5/mo)';
        } else {
          lockReason = 'Add Extra Slot ($5/mo)';
        }
        
        slots.push({
          id: `locked-${position}`,
          type: 'locked',
          position,
          canAdd: false,
          lockReason
        });
      }
    }
    
    return slots;
  };

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

  // Add right before the return in MyDevicesPage
console.log('🐛 DEBUG:', {
  userWithSub,
  devices: devices.length,
  tierInfo,
  deviceSlots: calculateDeviceSlots()
});

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
            </div>
            
            <div className="flex items-center space-x-3">
              {/* View Toggle */}
              <div className="flex bg-space-secondary rounded-lg p-1">
                <button
                  onClick={() => setViewMode('grid')}
                  className={`px-3 py-1 text-sm rounded-md transition-colors ${
                    viewMode === 'grid' 
                      ? 'bg-stellar-accent text-white' 
                      : 'text-cosmic-text-muted hover:text-cosmic-text'
                  }`}
                >
                  Grid
                </button>
                <button
                  onClick={() => setViewMode('list')}
                  className={`px-3 py-1 text-sm rounded-md transition-colors ${
                    viewMode === 'list' 
                      ? 'bg-stellar-accent text-white' 
                      : 'text-cosmic-text-muted hover:text-cosmic-text'
                  }`}
                >
                  List
                </button>
              </div>

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

        {/* Grid View */}
        {viewMode === 'grid' && (
          <div className="grid grid-cols-3 gap-4">
            {calculateDeviceSlots().map((slot) => (
              <DeviceSlotCard 
                key={slot.id} 
                slot={slot} 
                onAddDevice={() => console.log('Add device clicked')}
                onUpgrade={() => setShowUpgradeModal(true)}
                onDeviceClick={(device) => console.log('Device clicked:', device)}
              />
            ))}
          </div>
        )}

        {/* List View */}
        {viewMode === 'list' && (
          <>
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
                  <DeviceCard key={device.id} device={device} />
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
          </>
        )}

        {/* Error State */}
        {error && (
          <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-6 text-center">
            <h3 className="text-red-400 font-semibold mb-2">Error Loading Data</h3>
            <p className="text-cosmic-text-muted">{error}</p>
          </div>
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

// Device Slot Card Component (for Grid View)
interface DeviceSlotCardProps {
  slot: DeviceSlot;
  onAddDevice: () => void;
  onUpgrade: () => void;
  onDeviceClick: (device: Device) => void;
}

function DeviceSlotCard({ slot, onAddDevice, onUpgrade, onDeviceClick }: DeviceSlotCardProps) {
  const isDeviceOnline = (device: Device) => {
    if (!device.last_connection) return false;
    return new Date(device.last_connection).getTime() > Date.now() - (10 * 60 * 1000);
  };

  const getStatusIcon = (device: Device) => {
    if (!isDeviceOnline(device)) {
      return <WifiOff size={16} className="text-red-400" />;
    }
    
    switch (device.alert_status) {
      case 'normal': return <CheckCircle size={16} className="text-green-400" />;
      case 'warning': return <AlertTriangle size={16} className="text-yellow-400" />;
      case 'error': return <XCircle size={16} className="text-red-400" />;
      default: return <Wifi size={16} className="text-cosmic-blue" />;
    }
  };

  if (slot.type === 'device' && slot.device) {
    return (
      <div 
        onClick={() => onDeviceClick(slot.device!)}
        className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-4 hover:border-stellar-accent/50 transition-all cursor-pointer hover:scale-105 aspect-square flex flex-col"
      >
        <div className="flex items-center justify-between mb-3">
          <div className="w-10 h-10 bg-gradient-cosmic rounded-lg flex items-center justify-center">
            <span className="text-white font-bold">
              {slot.device.name.charAt(0)}
            </span>
          </div>
          {getStatusIcon(slot.device)}
        </div>
        
        <div className="flex-1">
          <h3 className="font-semibold text-cosmic-text text-sm mb-1 line-clamp-2">
            {slot.device.name}
          </h3>
          <p className="text-xs text-cosmic-text-muted mb-2">
            {slot.device.device_type}
          </p>
        </div>
        
        <div className="text-xs text-cosmic-text-muted">
          {isDeviceOnline(slot.device) ? 'Online' : 'Offline'}
        </div>
      </div>
    );
  }

  if (slot.type === 'empty') {
    return (
      <div 
        onClick={onAddDevice}
        className="bg-space-glass backdrop-blur-md border-2 border-dashed border-space-border rounded-xl p-4 hover:border-stellar-accent/50 transition-all cursor-pointer hover:scale-105 aspect-square flex flex-col items-center justify-center text-center group"
      >
        <div className="w-12 h-12 bg-cosmic-text/10 rounded-full flex items-center justify-center mb-3 group-hover:bg-stellar-accent/20 transition-colors">
          <Plus size={24} className="text-cosmic-text-muted group-hover:text-stellar-accent" />
        </div>
        <p className="text-sm font-medium text-cosmic-text-muted group-hover:text-cosmic-text">
          Add Device
        </p>
        <p className="text-xs text-cosmic-text-muted mt-1">
          Slot {slot.position}
        </p>
      </div>
    );
  }

  return (
    <div className="bg-space-glass/50 backdrop-blur-md border border-space-border/50 rounded-xl p-4 aspect-square flex flex-col items-center justify-center text-center opacity-60">
      <div className="w-12 h-12 bg-cosmic-text/5 rounded-full flex items-center justify-center mb-3">
        <Lock size={24} className="text-cosmic-text-muted" />
      </div>
      <p className="text-xs font-medium text-cosmic-text-muted mb-1">
        Locked Slot
      </p>
      <button 
        onClick={onUpgrade}
        className="text-xs text-stellar-accent hover:text-stellar-accent/80 underline"
      >
        {slot.lockReason}
      </button>
    </div>
  );
}

// Device Card Component (for List View)
interface DeviceCardProps {
  device: Device;
}

function DeviceCard({ device }: DeviceCardProps) {
  const isOnline = device.last_connection && 
    new Date(device.last_connection).getTime() > Date.now() - (10 * 60 * 1000);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'text-green-400';
      case 'pending': return 'text-yellow-400';
      case 'disabled': return 'text-red-400';
      default: return 'text-cosmic-text-muted';
    }
  };

  const getAlertColor = (alertStatus: string) => {
    switch (alertStatus) {
      case 'normal': return 'text-green-400';
      case 'warning': return 'text-yellow-400';
      case 'error': return 'text-red-400';
      default: return 'text-cosmic-text-muted';
    }
  };

  return (
    <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6 hover:border-stellar-accent/50 transition-colors">
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center space-x-3">
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
        
        <div className="flex items-center space-x-1">
          {isOnline ? (
            <Wifi size={16} className="text-green-400" />
          ) : (
            <WifiOff size={16} className="text-red-400" />
          )}
        </div>
      </div>

      <div className="space-y-2 mb-4">
        <div className="flex items-center justify-between text-sm">
          <span className="text-cosmic-text-muted">Status:</span>
          <span className={`font-semibold ${getStatusColor(device.status)}`}>
            {device.status.charAt(0).toUpperCase() + device.status.slice(1)}
          </span>
        </div>
        
        <div className="flex items-center justify-between text-sm">
          <span className="text-cosmic-text-muted">Alert Level:</span>
          <span className={`font-semibold ${getAlertColor(device.alert_status)}`}>
            {device.alert_status.charAt(0).toUpperCase() + device.alert_status.slice(1)}
          </span>
        </div>
      </div>

      {device.last_connection && (
        <div className="text-xs text-cosmic-text-muted mb-4">
          Last seen: {new Date(device.last_connection).toLocaleString()}
        </div>
      )}

      <div className="flex space-x-2">
        <Link href={`/user/devices/${device.id}`} className="flex-1">
          <Button variant="cosmic" size="sm" className="w-full">
            View Details
          </Button>
        </Link>
        <Button variant="outline" size="sm">
          <Settings size={16} />
        </Button>
      </div>
    </div>
  );
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