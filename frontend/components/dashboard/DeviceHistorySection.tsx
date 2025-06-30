// components/dashboard/DeviceHistorySection.tsx
'use client';

interface DeviceHistorySectionProps {
  deviceId: string;
}

export function DeviceHistorySection({ deviceId }: DeviceHistorySectionProps) {
  console.log('DeviceHistorySection loaded for device:', deviceId);
  
  const events = [
    {
      id: 1,
      type: 'info',
      title: 'Watering cycle completed',
      time: '5 minutes ago',
      details: 'Dispensed 2.5L over 15 minutes'
    },
    {
      id: 2,
      type: 'warning',
      title: 'Temperature spike detected',
      time: '2 hours ago',
      details: 'Reached 26.8°C, returned to normal'
    },
    {
      id: 3,
      type: 'info',
      title: 'LED schedule updated',
      time: '1 day ago',
      details: 'Changed to winter growing schedule'
    },
    {
      id: 4,
      type: 'success',
      title: 'Firmware updated',
      time: '3 days ago',
      details: 'Updated to version v2.1.0'
    }
  ];

  const getEventColor = (type: string) => {
    switch (type) {
      case 'warning': return 'border-l-yellow-400';
      case 'error': return 'border-l-red-400';
      case 'success': return 'border-l-green-400';
      default: return 'border-l-blue-400';
    }
  };

  return (
    <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
      <h3 className="text-lg font-semibold text-cosmic-text mb-6">Recent Activity</h3>
      
      <div className="space-y-4">
        {events.map((event) => (
          <div key={event.id} className={`border-l-4 ${getEventColor(event.type)} pl-4 py-2`}>
            <h4 className="font-medium text-cosmic-text">{event.title}</h4>
            <p className="text-sm text-cosmic-text-muted">{event.details}</p>
            <p className="text-xs text-cosmic-text-muted mt-1">{event.time}</p>
          </div>
        ))}
      </div>
    </div>
  );
}