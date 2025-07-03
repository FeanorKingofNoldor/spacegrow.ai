// components/subscription/SubscriptionDashboard.tsx
'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/Button';
import { Modal, ConfirmModal } from '@/components/ui/Modal';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { DashboardLayoutWrapper } from '@/components/dashboard/DashboardLayoutWrapper';
import { 
  CreditCard, 
  Calendar, 
  Users, 
  TrendingUp, 
  Plus, 
  Settings,
  Download,
  Star,
  AlertTriangle,
  Check
} from 'lucide-react';
import { cn } from '@/lib/utils';

export function SubscriptionDashboard() {
  const [showCancelModal, setShowCancelModal] = useState(false);
  const [showUpgradeModal, setShowUpgradeModal] = useState(false);
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  // Mock data - replace with real subscription context later
  const mockSubscription = {
    plan: { name: 'Professional', monthly_price: 29, yearly_price: 290 },
    status: 'active',
    interval: 'month',
    device_limit: 5,
    additional_device_slots: 0,
    current_period_end: '2024-02-15',
    devices: [
      { id: 1, name: 'Grow Tent Alpha', device_type: 'Environmental Monitor' },
      { id: 2, name: 'Hydro System', device_type: 'Liquid Monitor' }
    ]
  };

  const deviceUsage = {
    used: mockSubscription.devices.length,
    limit: mockSubscription.device_limit,
    percentage: (mockSubscription.devices.length / mockSubscription.device_limit) * 100
  };

  const nextBillingDate = new Date(mockSubscription.current_period_end);
  const daysUntilRenewal = Math.ceil((nextBillingDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24));

  return (
    <DashboardLayoutWrapper>
      <div className="max-w-6xl mx-auto space-y-8">
        {/* Header */}
        <div className="text-center">
          <h1 className="text-3xl font-bold text-cosmic-text mb-4">
            Subscription Management
          </h1>
          <p className="text-cosmic-text-muted">
            Manage your SpaceGrow.ai subscription and billing settings
          </p>
        </div>

        {/* Current Subscription Card */}
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-2xl p-8">
          <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between mb-8">
            {/* Plan Info */}
            <div>
              <div className="flex items-center space-x-3 mb-4">
                <div className="w-12 h-12 bg-gradient-cosmic rounded-xl flex items-center justify-center">
                  <Star className="w-6 h-6 text-white" />
                </div>
                <div>
                  <h2 className="text-2xl font-bold text-cosmic-text">
                    {mockSubscription.plan.name} Plan
                  </h2>
                  <div className="flex items-center space-x-4">
                    <span className="px-3 py-1 rounded-full text-xs font-medium bg-green-500/20 text-green-400">
                      ACTIVE
                    </span>
                    <span className="text-cosmic-text-muted text-sm">
                      Monthly billing
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* Pricing */}
            <div className="text-right">
              <div className="text-3xl font-bold text-cosmic-text">
                ${mockSubscription.plan.monthly_price}
              </div>
              <div className="text-cosmic-text-muted">
                per month
              </div>
            </div>
          </div>

          {/* Billing Info */}
          <div className="grid md:grid-cols-2 gap-6 mb-8">
            <div className="bg-space-secondary rounded-xl p-4">
              <div className="flex items-center space-x-3 mb-2">
                <Calendar className="w-5 h-5 text-cosmic-blue" />
                <span className="font-medium text-cosmic-text">Next Billing</span>
              </div>
              <div className="text-cosmic-text-muted">
                {nextBillingDate.toLocaleDateString()} ({daysUntilRenewal} days)
              </div>
            </div>

            <div className="bg-space-secondary rounded-xl p-4">
              <div className="flex items-center space-x-3 mb-2">
                <Users className="w-5 h-5 text-cosmic-blue" />
                <span className="font-medium text-cosmic-text">Device Usage</span>
              </div>
              <div className="flex items-center space-x-2">
                <div className="text-cosmic-text-muted">
                  {deviceUsage.used} / {deviceUsage.limit} devices
                </div>
                <div className="flex-1 bg-space-border rounded-full h-2">
                  <div 
                    className="bg-cosmic-blue h-2 rounded-full transition-all"
                    style={{ width: `${Math.min(deviceUsage.percentage, 100)}%` }}
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Actions */}
          <div className="flex flex-wrap gap-3">
            <Button variant="cosmic" onClick={() => setShowUpgradeModal(true)}>
              <TrendingUp className="w-4 h-4 mr-2" />
              Change Plan
            </Button>
            
            <Button variant="outline">
              <CreditCard className="w-4 h-4 mr-2" />
              Update Payment
            </Button>
            
            <Button variant="outline">
              <Download className="w-4 h-4 mr-2" />
              Download Invoice
            </Button>
            
            <Button variant="ghost" onClick={() => setShowCancelModal(true)}>
              Cancel Subscription
            </Button>
          </div>
        </div>

        {/* Connected Devices */}
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-2xl p-8">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-xl font-bold text-cosmic-text">Connected Devices</h3>
            <span className="text-cosmic-text-muted">
              {mockSubscription.devices.length} of {mockSubscription.device_limit} slots used
            </span>
          </div>

          <div className="grid gap-4">
            {mockSubscription.devices.map((device) => (
              <div key={device.id} className="flex items-center justify-between bg-space-secondary rounded-xl p-4">
                <div className="flex items-center space-x-3">
                  <div className="w-10 h-10 bg-gradient-cosmic rounded-lg flex items-center justify-center">
                    <Settings className="w-5 h-5 text-white" />
                  </div>
                  <div>
                    <h4 className="font-medium text-cosmic-text">{device.name}</h4>
                    <p className="text-cosmic-text-muted text-sm">{device.device_type}</p>
                  </div>
                </div>
                
                <div className="flex items-center space-x-3">
                  <span className="text-green-400 text-sm">Connected</span>
                </div>
              </div>
            ))}
          </div>

          {deviceUsage.percentage >= 80 && (
            <div className="mt-4 p-4 bg-orange-500/10 border border-orange-500/20 rounded-xl">
              <p className="text-orange-300 text-sm">
                You're approaching your device limit. Consider upgrading for more devices.
              </p>
            </div>
          )}
        </div>

        {/* Cancel Confirmation Modal */}
        <ConfirmModal
          isOpen={showCancelModal}
          onClose={() => setShowCancelModal(false)}
          onConfirm={() => {
            console.log('Cancel subscription');
            setShowCancelModal(false);
          }}
          title="Cancel Subscription"
          message="Are you sure you want to cancel your subscription? You'll lose access to all premium features at the end of your billing period."
          confirmText="Cancel Subscription"
          variant="danger"
          loading={actionLoading === 'cancel'}
        />
      </div>
    </DashboardLayoutWrapper>
  );
}