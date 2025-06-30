// app/(dashboard)/admin/dashboard/page.tsx - Admin dashboard
'use client';

import { DashboardLayoutWrapper } from '@/components/dashboard/DashboardLayoutWrapper';
import { Button } from '@/components/ui/Button';
import { Shield, Users, Database, Settings } from 'lucide-react';

export default function AdminDashboardPage() {
  return (
    <DashboardLayoutWrapper>
      <div className="space-y-6">
        {/* Admin Header */}
        <div className="bg-gradient-to-r from-stellar-accent/10 to-nebula-primary/10 border border-stellar-accent/20 rounded-xl p-6">
          <div className="flex items-center space-x-4">
            <div className="w-12 h-12 bg-stellar-accent/20 rounded-lg flex items-center justify-center">
              <Shield size={24} className="text-stellar-accent" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-cosmic-text">Admin Dashboard</h1>
              <p className="text-cosmic-text-muted">System administration and user management</p>
            </div>
          </div>
        </div>

        {/* Admin Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
            <div className="flex items-center space-x-3 mb-4">
              <Users size={24} className="text-cosmic-blue" />
              <h3 className="font-semibold text-cosmic-text">Total Users</h3>
            </div>
            <div className="text-3xl font-bold text-cosmic-blue">1,247</div>
            <p className="text-sm text-cosmic-text-muted">+12% this month</p>
          </div>

          <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
            <div className="flex items-center space-x-3 mb-4">
              <Database size={24} className="text-nebula-primary" />
              <h3 className="font-semibold text-cosmic-text">Active Devices</h3>
            </div>
            <div className="text-3xl font-bold text-nebula-primary">3,891</div>
            <p className="text-sm text-cosmic-text-muted">+8% this month</p>
          </div>

          <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
            <div className="flex items-center space-x-3 mb-4">
              <Settings size={24} className="text-stellar-accent" />
              <h3 className="font-semibold text-cosmic-text">System Health</h3>
            </div>
            <div className="text-3xl font-bold text-green-400">99.8%</div>
            <p className="text-sm text-cosmic-text-muted">All systems normal</p>
          </div>
        </div>

        {/* Admin Actions */}
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
          <h2 className="text-xl font-semibold text-cosmic-text mb-4">Quick Admin Actions</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <Button variant="outline" className="h-20">
              <div className="text-center">
                <Users size={20} className="mx-auto mb-2" />
                <div className="text-sm">User Management</div>
              </div>
            </Button>
            <Button variant="outline" className="h-20">
              <div className="text-center">
                <Database size={20} className="mx-auto mb-2" />
                <div className="text-sm">Device Overview</div>
              </div>
            </Button>
            <Button variant="outline" className="h-20">
              <div className="text-center">
                <Settings size={20} className="mx-auto mb-2" />
                <div className="text-sm">System Settings</div>
              </div>
            </Button>
            <Button variant="outline" className="h-20">
              <div className="text-center">
                <Shield size={20} className="mx-auto mb-2" />
                <div className="text-sm">Security Logs</div>
              </div>
            </Button>
          </div>
        </div>
      </div>
    </DashboardLayoutWrapper>
  );
}