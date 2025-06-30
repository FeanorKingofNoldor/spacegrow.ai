// app/(dashboard)/user/devices/[id]/page.tsx - FIXED with proper props
'use client';

import { useParams } from 'next/navigation';
import { DashboardLayoutWrapper } from '@/components/dashboard/DashboardLayoutWrapper';
import { DeviceDetailHeader } from '@/components/dashboard/DeviceDetailHeader';
import { DeviceChartsSection } from '@/components/dashboard/DeviceChartsSection';
import { DeviceControlsSection } from '@/components/dashboard/DeviceControlsSection';
import { DeviceHistorySection } from '@/components/dashboard/DeviceHistorySection';

export default function DeviceDetailPage() {
  const params = useParams();
  const deviceId = params.id as string;

  console.log('DeviceDetailPage - deviceId:', deviceId); // Debug log

  return (
    <DashboardLayoutWrapper>
      <div className="space-y-6">
        {/* Device Header - breadcrumb, name, status, controls */}
        <DeviceDetailHeader />

        {/* Main Charts Grid - 3x3 sensor monitoring */}
        <DeviceChartsSection />

        {/* Additional Device Information */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <DeviceControlsSection deviceId={deviceId} />
          <DeviceHistorySection deviceId={deviceId} />
        </div>
      </div>
    </DashboardLayoutWrapper>
  );
}