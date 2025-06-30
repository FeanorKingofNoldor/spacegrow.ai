// components/dashboard/FirmwareUpdatesSection.tsx
'use client';

import { Button } from '@/components/ui/Button';

export function FirmwareUpdatesSection() {
  return (
    <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
      <h2 className="text-xl font-semibold text-cosmic-text mb-4">Firmware Updates</h2>
      <div className="bg-stellar-accent/10 border border-stellar-accent/20 rounded-lg p-4">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="font-semibold text-stellar-accent">v2.1.0 Available</h3>
            <p className="text-cosmic-text-muted text-sm">
              New features: Enhanced pH calibration, improved WiFi stability
            </p>
          </div>
          <Button variant="stellar" size="sm">
            Update Now
          </Button>
        </div>
      </div>
    </div>
  );
}