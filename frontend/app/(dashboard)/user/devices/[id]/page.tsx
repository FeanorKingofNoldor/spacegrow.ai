// Updated app/(dashboard)/user/devices/[id]/page.tsx - COMPLETE device detail page
'use client';

import { DashboardLayoutWrapper } from '@/components/dashboard/DashboardLayoutWrapper';
import { DeviceDetailHeader } from '@/components/dashboard/DeviceDetailHeader';
import { DeviceChartsSection } from '@/components/dashboard/DeviceChartsSection';
import { DeviceControlsSection } from '@/components/dashboard/DeviceControlsSection';
import { DeviceHistorySection } from '@/components/dashboard/DeviceHistorySection';

export default function DeviceDetailPage() {
  return (
    <DashboardLayoutWrapper>
      <div className="space-y-6">
        {/* Device Header - breadcrumb, name, status, controls */}
        <DeviceDetailHeader />

        {/* Main Charts Grid - 3x3 sensor monitoring */}
        <DeviceChartsSection />

        {/* Additional Device Information */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <DeviceControlsSection />
          <DeviceHistorySection />
        </div>
      </div>
    </DashboardLayoutWrapper>
  );
}
