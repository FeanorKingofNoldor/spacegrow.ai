// components/dashboard/WelcomeSection.tsx
'use client';

import { useAuth } from '@/contexts/AuthContext';

export function WelcomeSection() {
  const { user } = useAuth();

  return (
    <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-cosmic-text mb-2">
            Welcome back, {user?.email?.split('@')[0] || 'Grower'}! 🌱
          </h1>
          <p className="text-cosmic-text-muted">
            Here's what's happening with your growing systems today.
          </p>
        </div>
        <div className="text-right">
          <div className="text-3xl font-bold text-stellar-accent">
            {user?.devices_count || 0}
          </div>
          <div className="text-sm text-cosmic-text-muted">Active Devices</div>
        </div>
      </div>
    </div>
  );
}