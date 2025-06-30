// components/dashboard/DeviceControlsSection.tsx
'use client';

import { Button } from '@/components/ui/Button';
import { Power, Lightbulb, Droplets, Fan } from 'lucide-react';

interface DeviceControlsSectionProps {
  deviceId: string;
}

export function DeviceControlsSection({ deviceId }: DeviceControlsSectionProps) {
  console.log('DeviceControlsSection loaded for device:', deviceId);
  
  return (
    <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
      <h3 className="text-lg font-semibold text-cosmic-text mb-6">Device Controls</h3>
      
      <div className="space-y-4">
        {/* LED Controls */}
        <div className="flex items-center justify-between p-4 bg-space-secondary rounded-lg">
          <div className="flex items-center space-x-3">
            <Lightbulb size={20} className="text-yellow-400" />
            <div>
              <h4 className="font-medium text-cosmic-text">LED System</h4>
              <p className="text-sm text-cosmic-text-muted">Currently: On (75% intensity)</p>
            </div>
          </div>
          <Button variant="outline" size="sm">Control</Button>
        </div>

        {/* Water System */}
        <div className="flex items-center justify-between p-4 bg-space-secondary rounded-lg">
          <div className="flex items-center space-x-3">
            <Droplets size={20} className="text-blue-400" />
            <div>
              <h4 className="font-medium text-cosmic-text">Water System</h4>
              <p className="text-sm text-cosmic-text-muted">Next cycle: 2 hours</p>
            </div>
          </div>
          <Button variant="outline" size="sm">Manual Run</Button>
        </div>

        {/* Ventilation */}
        <div className="flex items-center justify-between p-4 bg-space-secondary rounded-lg">
          <div className="flex items-center space-x-3">
            <Fan size={20} className="text-green-400" />
            <div>
              <h4 className="font-medium text-cosmic-text">Ventilation</h4>
              <p className="text-sm text-cosmic-text-muted">Speed: 60% (Auto mode)</p>
            </div>
          </div>
          <Button variant="outline" size="sm">Adjust</Button>
        </div>

        {/* Power Management */}
        <div className="flex items-center justify-between p-4 bg-space-secondary rounded-lg">
          <div className="flex items-center space-x-3">
            <Power size={20} className="text-red-400" />
            <div>
              <h4 className="font-medium text-cosmic-text">Power Management</h4>
              <p className="text-sm text-cosmic-text-muted">Current draw: 247W</p>
            </div>
          </div>
          <Button variant="outline" size="sm">Settings</Button>
        </div>
      </div>
    </div>
  );
}