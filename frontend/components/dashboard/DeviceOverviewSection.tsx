// components/dashboard/DeviceOverviewSection.tsx
'use client';

import { CheckCircle, AlertTriangle, XCircle, Clock } from 'lucide-react';

export function DeviceOverviewSection() {
  const deviceStats = {
    total: 12,
    active: 10,
    warning: 1,
    offline: 1
  };

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      {/* Total Devices */}
      <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
        <div className="flex items-center space-x-3 mb-4">
          <div className="w-10 h-10 bg-cosmic-blue/20 rounded-lg flex items-center justify-center">
            <Clock size={20} className="text-cosmic-blue" />
          </div>
          <div>
            <h3 className="font-semibold text-cosmic-text">Total Devices</h3>
            <p className="text-xs text-cosmic-text-muted">All registered</p>
          </div>
        </div>
        <div className="text-2xl font-bold text-cosmic-blue">{deviceStats.total}</div>
        <p className="text-sm text-cosmic-text-muted">Across all locations</p>
      </div>

      {/* Active Devices */}
      <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
        <div className="flex items-center space-x-3 mb-4">
          <div className="w-10 h-10 bg-green-500/20 rounded-lg flex items-center justify-center">
            <CheckCircle size={20} className="text-green-400" />
          </div>
          <div>
            <h3 className="font-semibold text-cosmic-text">Active</h3>
            <p className="text-xs text-cosmic-text-muted">Operating normally</p>
          </div>
        </div>
        <div className="text-2xl font-bold text-green-400">{deviceStats.active}</div>
        <p className="text-sm text-cosmic-text-muted">All systems green</p>
      </div>

      {/* Warning Devices */}
      <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
        <div className="flex items-center space-x-3 mb-4">
          <div className="w-10 h-10 bg-yellow-500/20 rounded-lg flex items-center justify-center">
            <AlertTriangle size={20} className="text-yellow-400" />
          </div>
          <div>
            <h3 className="font-semibold text-cosmic-text">Warnings</h3>
            <p className="text-xs text-cosmic-text-muted">Need attention</p>
          </div>
        </div>
        <div className="text-2xl font-bold text-yellow-400">{deviceStats.warning}</div>
        <p className="text-sm text-cosmic-text-muted">Check sensor</p>
      </div>

      {/* Offline Devices */}
      <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
        <div className="flex items-center space-x-3 mb-4">
          <div className="w-10 h-10 bg-red-500/20 rounded-lg flex items-center justify-center">
            <XCircle size={20} className="text-red-400" />
          </div>
          <div>
            <h3 className="font-semibold text-cosmic-text">Offline</h3>
            <p className="text-xs text-cosmic-text-muted">Connection lost</p>
          </div>
        </div>
        <div className="text-2xl font-bold text-red-400">{deviceStats.offline}</div>
        <p className="text-sm text-cosmic-text-muted">Needs reconnection</p>
      </div>
    </div>
  );
}