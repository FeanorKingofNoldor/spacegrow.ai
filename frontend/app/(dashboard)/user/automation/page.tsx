// app/(dashboard)/user/automation/page.tsx - Automation page
'use client';

import { DashboardLayoutWrapper } from '@/components/dashboard/DashboardLayoutWrapper';
import { Button } from '@/components/ui/Button';
import { Zap } from 'lucide-react';

export default function AutomationPage() {
  return (
    <DashboardLayoutWrapper>
      <div className="space-y-6">
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-8 text-center">
          <Zap size={48} className="mx-auto text-cosmic-text-muted mb-4" />
          <h1 className="text-2xl font-bold text-cosmic-text mb-2">Automation Rules</h1>
          <p className="text-cosmic-text-muted">
            Create smart automation rules and schedules for your growing systems.
          </p>
          <div className="mt-6">
            <Button variant="outline" size="lg">Coming Soon</Button>
          </div>
        </div>
      </div>
    </DashboardLayoutWrapper>
  );
}