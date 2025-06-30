// components/dashboard/DeviceAlertsSection.tsx
'use client';

import { AlertTriangle, Info, CheckCircle } from 'lucide-react';

export function DeviceAlertsSection() {
  const alerts = [
    {
      id: 1,
      type: 'warning',
      title: 'High Temperature Alert',
      message: 'LED Panel Controller temperature above threshold (26.1°C)',
      device: 'LED Panel Controller',
      time: '5 minutes ago'
    },
    {
      id: 2,
      type: 'error',
      title: 'Device Offline',
      message: 'Climate Monitor has lost connection',
      device: 'Climate Monitor',
      time: '12 minutes ago'
    },
    {
      id: 3,
      type: 'info',
      title: 'Watering Cycle Complete',
      message: 'Hydroponic system completed scheduled watering',
      device: 'Hydroponic System',
      time: '1 hour ago'
    }
  ];

  const getAlertIcon = (type: string) => {
    switch (type) {
      case 'warning': return AlertTriangle;
      case 'error': return AlertTriangle;
      case 'info': return Info;
      case 'success': return CheckCircle;
      default: return Info;
    }
  };

  const getAlertColor = (type: string) => {
    switch (type) {
      case 'warning': return 'text-yellow-400';
      case 'error': return 'text-red-400';
      case 'info': return 'text-blue-400';
      case 'success': return 'text-green-400';
      default: return 'text-cosmic-text-muted';
    }
  };

  return (
    <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
      <h2 className="text-xl font-semibold text-cosmic-text mb-6">Recent Alerts</h2>
      
      <div className="space-y-4">
        {alerts.map((alert) => {
          const Icon = getAlertIcon(alert.type);
          return (
            <div key={alert.id} className="flex items-start space-x-3 p-3 bg-space-secondary rounded-lg">
              <Icon size={20} className={getAlertColor(alert.type)} />
              <div className="flex-1">
                <h4 className="font-medium text-cosmic-text">{alert.title}</h4>
                <p className="text-sm text-cosmic-text-muted mb-1">{alert.message}</p>
                <div className="flex items-center justify-between text-xs text-cosmic-text-muted">
                  <span>{alert.device}</span>
                  <span>{alert.time}</span>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}