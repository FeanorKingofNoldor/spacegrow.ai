// app/(dashboard)/user/analytics/page.tsx - Analytics page
'use client';

import { DashboardLayoutWrapper } from '@/components/dashboard/DashboardLayoutWrapper';
import { Button } from '@/components/ui/Button';
import { BarChart3 } from 'lucide-react';

export default function AnalyticsPage() {
  return (
    <DashboardLayoutWrapper>
      <div className="space-y-6">
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-8 text-center">
          <BarChart3 size={48} className="mx-auto text-cosmic-text-muted mb-4" />
          <h1 className="text-2xl font-bold text-cosmic-text mb-2">Analytics & Reports</h1>
          <p className="text-cosmic-text-muted">
            Deep dive into your growing data with detailed analytics and custom reports.
          </p>
          <div className="mt-6">
            <Button variant="outline" size="lg">Coming Soon</Button>
          </div>
        </div>
      </div>
    </DashboardLayoutWrapper>
  );
}