// app/(dashboard)/user/dashboard/device_dashboard/page.tsx - Device macro overview
'use client';

import { DashboardLayoutWrapper } from '@/components/dashboard/DashboardLayoutWrapper';
import { DeviceOverviewSection } from '@/components/dashboard/DeviceOverviewSection';
import { DeviceGridSection } from '@/components/dashboard/DeviceGridSection';
import { DeviceAlertsSection } from '@/components/dashboard/DeviceAlertsSection';

export default function DeviceDashboardPage() {
  return (
    <DashboardLayoutWrapper>
      <div className="space-y-6">
        {/* Page Header */}
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
          <h1 className="text-2xl font-bold text-cosmic-text mb-2">Device Dashboard</h1>
          <p className="text-cosmic-text-muted">
            Macro overview of all your growing devices and their current status.
          </p>
        </div>

        {/* Device Overview Stats */}
        <DeviceOverviewSection />

        {/* Device Grid */}
        <DeviceGridSection />

        {/* Alerts & Notifications */}
        <DeviceAlertsSection />
      </div>
    </DashboardLayoutWrapper>
  );
}