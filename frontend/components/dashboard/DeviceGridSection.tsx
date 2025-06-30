// components/dashboard/DeviceGridSection.tsx
'use client';

import { Button } from '@/components/ui/Button';
import { Settings, MoreVertical, Wifi, WifiOff } from 'lucide-react';
import Link from 'next/link';

export function DeviceGridSection() {
  const devices = [
    { 
      id: 'grow-tent-1', 
      name: 'Grow Tent Alpha', 
      status: 'active', 
      temperature: '24.2°C', 
      humidity: '65%',
      location: 'Greenhouse A'
    },
    { 
      id: 'hydro-system-1', 
      name: 'Hydroponic System', 
      status: 'active', 
      temperature: '23.8°C', 
      humidity: '70%',
      location: 'Lab Section B'
    },
    { 
      id: 'led-panel-1', 
      name: 'LED Panel Controller', 
      status: 'warning', 
      temperature: '26.1°C', 
      humidity: '62%',
      location: 'Greenhouse A'
    },
    { 
      id: 'climate-sensor-1', 
      name: 'Climate Monitor', 
      status: 'offline', 
      temperature: '--', 
      humidity: '--',
      location: 'Storage Room'
    },
  ];

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'text-green-400';
      case 'warning': return 'text-yellow-400';
      case 'offline': return 'text-red-400';
      default: return 'text-cosmic-text-muted';
    }
  };

  const getStatusIcon = (status: string) => {
    return status === 'offline' ? WifiOff : Wifi;
  };

  return (
    <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-xl font-semibold text-cosmic-text">Device Overview</h2>
        <Button variant="outline" size="sm">View All</Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {devices.map((device) => {
          const StatusIcon = getStatusIcon(device.status);
          return (
            <div key={device.id} className="bg-space-secondary rounded-lg p-4 hover:bg-space-glass transition-colors">
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center space-x-3">
                  <div className="w-10 h-10 bg-nebula-primary/20 rounded-lg flex items-center justify-center">
                    <Settings size={20} className="text-nebula-primary" />
                  </div>
                  <div>
                    <h3 className="font-medium text-cosmic-text">{device.name}</h3>
                    <p className="text-xs text-cosmic-text-muted">{device.location}</p>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <StatusIcon size={16} className={getStatusColor(device.status)} />
                  <button className="text-cosmic-text-muted hover:text-cosmic-text">
                    <MoreVertical size={16} />
                  </button>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4 mb-3">
                <div>
                  <p className="text-xs text-cosmic-text-muted">Temperature</p>
                  <p className="font-medium text-cosmic-text">{device.temperature}</p>
                </div>
                <div>
                  <p className="text-xs text-cosmic-text-muted">Humidity</p>
                  <p className="font-medium text-cosmic-text">{device.humidity}</p>
                </div>
              </div>

              <Link href={`/user/devices/${device.id}`}>
                <Button variant="outline" size="sm" className="w-full">
                  View Details
                </Button>
              </Link>
            </div>
          );
        })}
      </div>
    </div>
  );
}