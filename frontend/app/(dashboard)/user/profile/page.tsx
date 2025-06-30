// app/(dashboard)/user/profile/page.tsx - User profile page
'use client';

import { DashboardLayoutWrapper } from '@/components/dashboard/DashboardLayoutWrapper';
import { Button } from '@/components/ui/Button';
import { User } from 'lucide-react';

export default function ProfilePage() {
  return (
    <DashboardLayoutWrapper>
      <div className="space-y-6">
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-8 text-center">
          <User size={48} className="mx-auto text-cosmic-text-muted mb-4" />
          <h1 className="text-2xl font-bold text-cosmic-text mb-2">User Profile</h1>
          <p className="text-cosmic-text-muted">
            Manage your account information and preferences.
          </p>
          <div className="mt-6">
            <Button variant="outline" size="lg">Coming Soon</Button>
          </div>
        </div>
      </div>
    </DashboardLayoutWrapper>
  );
}