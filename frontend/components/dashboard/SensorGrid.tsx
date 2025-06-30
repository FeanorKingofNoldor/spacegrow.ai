// components/dashboard/SensorGrid.tsx - NEW responsive grid component
'use client';

import { DeviceSensor } from '@/types/device';
import { SensorChart } from '@/components/charts/SensorChart';

interface SensorGridProps {
  sensors: DeviceSensor[];
  liveValues: Record<number, number>;
}

export function SensorGrid({ sensors, liveValues }: SensorGridProps) {
  // Limit to first 9 sensors for the 3x3 grid
  const displaySensors = sensors.slice(0, 9);
  const hasMoreSensors = sensors.length > 9;

  return (
    <div className="space-y-4">
      {/* 3x3 Grid for Desktop, 2x2 for Tablet, 1x1 for Mobile */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {displaySensors.map((sensor) => (
          <div key={sensor.id} className="aspect-square">
            <SensorChart
              sensor={sensor}
              liveValue={liveValues[sensor.id] ?? sensor.last_reading ?? 0}
              className="h-full"
            />
          </div>
        ))}
        
        {/* Fill empty grid spots if less than 9 sensors */}
        {Array.from({ length: Math.max(0, 9 - displaySensors.length) }).map((_, index) => (
          <div 
            key={`empty-${index}`} 
            className="aspect-square bg-space-glass/50 backdrop-blur-md border border-space-border/50 rounded-xl flex items-center justify-center"
          >
            <div className="text-center">
              <div className="w-12 h-12 bg-cosmic-text/10 rounded-full flex items-center justify-center mx-auto mb-2">
                <span className="text-cosmic-text-muted text-xl">+</span>
              </div>
              <p className="text-xs text-cosmic-text-muted">No Sensor</p>
            </div>
          </div>
        ))}
      </div>

      {/* Show indicator if there are more sensors */}
      {hasMoreSensors && (
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-4 text-center">
          <p className="text-cosmic-text-muted">
            Showing 9 of {sensors.length} sensors. 
            <button className="text-stellar-accent hover:underline ml-1">
              View all sensors
            </button>
          </p>
        </div>
      )}
    </div>
  );
}