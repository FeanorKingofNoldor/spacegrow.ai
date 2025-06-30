// components/dashboard/SystemOverviewSection.tsx
'use client';

import { Zap, Thermometer, Droplets, Lightbulb } from 'lucide-react';

export function SystemOverviewSection() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      {/* Total Power Consumption */}
      <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
        <div className="flex items-center space-x-3 mb-4">
          <div className="w-10 h-10 bg-yellow-500/20 rounded-lg flex items-center justify-center">
            <Zap size={20} className="text-yellow-400" />
          </div>
          <div>
            <h3 className="font-semibold text-cosmic-text">Power Usage</h3>
            <p className="text-xs text-cosmic-text-muted">Total consumption</p>
          </div>
        </div>
        <div className="text-2xl font-bold text-yellow-400">1,247W</div>
        <p className="text-sm text-cosmic-text-muted">+12% from yesterday</p>
      </div>

      {/* Average Temperature */}
      <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
        <div className="flex items-center space-x-3 mb-4">
          <div className="w-10 h-10 bg-red-500/20 rounded-lg flex items-center justify-center">
            <Thermometer size={20} className="text-red-400" />
          </div>
          <div>
            <h3 className="font-semibold text-cosmic-text">Avg Temperature</h3>
            <p className="text-xs text-cosmic-text-muted">All devices</p>
          </div>
        </div>
        <div className="text-2xl font-bold text-red-400">24.5°C</div>
        <p className="text-sm text-cosmic-text-muted">Optimal range</p>
      </div>

      {/* Humidity Levels */}
      <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
        <div className="flex items-center space-x-3 mb-4">
          <div className="w-10 h-10 bg-blue-500/20 rounded-lg flex items-center justify-center">
            <Droplets size={20} className="text-blue-400" />
          </div>
          <div>
            <h3 className="font-semibold text-cosmic-text">Avg Humidity</h3>
            <p className="text-xs text-cosmic-text-muted">All devices</p>
          </div>
        </div>
        <div className="text-2xl font-bold text-blue-400">68%</div>
        <p className="text-sm text-cosmic-text-muted">Within range</p>
      </div>

      {/* Light Hours */}
      <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
        <div className="flex items-center space-x-3 mb-4">
          <div className="w-10 h-10 bg-purple-500/20 rounded-lg flex items-center justify-center">
            <Lightbulb size={20} className="text-purple-400" />
          </div>
          <div>
            <h3 className="font-semibold text-cosmic-text">Light Hours</h3>
            <p className="text-xs text-cosmic-text-muted">Today total</p>
          </div>
        </div>
        <div className="text-2xl font-bold text-purple-400">14.2h</div>
        <p className="text-sm text-cosmic-text-muted">Schedule on track</p>
      </div>
    </div>
  );
}