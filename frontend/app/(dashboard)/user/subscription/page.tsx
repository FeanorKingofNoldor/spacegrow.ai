// app/user/subscription/page.tsx - ENHANCED subscription management page
'use client';

import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/Button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { Modal } from '@/components/ui/Modal';
import { DashboardLayoutWrapper } from '@/components/dashboard/DashboardLayoutWrapper';
import { PlanChangeModal } from '@/components/subscription/PlanChangeModal';
import { useSubscription } from '@/contexts/SubscriptionContext';
import { Plan } from '@/types/subscription';
import { 
  CreditCard, 
  Calendar, 
  Users, 
  TrendingUp, 
  Star,
  Settings,
  Download,
  AlertTriangle,
  CheckCircle,
  Clock,
  Zap,
  Plus,
  Shield,
  ArrowRight
} from 'lucide-react';
import { cn } from '@/lib/utils';

export default function SubscriptionPage() {
  const { 
    subscription, 
    plans, 
    loading, 
    error, 
    deviceUsage, 
    nextBillingDate, 
    daysUntilRenewal,
    cancelSubscription,
    addDeviceSlot 
  } = useSubscription();

  const [showPlanChangeModal, setShowPlanChangeModal] = useState(false);
  const [showCancelModal, setShowCancelModal] = useState(false);
  const [selectedPlanForChange, setSelectedPlanForChange] = useState<Plan | undefined>(undefined);
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  if (loading) {
    return (
      <DashboardLayoutWrapper>
        <div className="flex items-center justify-center min-h-[400px]">
          <LoadingSpinner size="lg" text="Loading subscription..." />
        </div>
      </DashboardLayoutWrapper>
    );
  }

  if (error) {
    return (
      <DashboardLayoutWrapper>
        <div className="text-center py-12">
          <AlertTriangle size={48} className="mx-auto text-red-400 mb-4" />
          <h2 className="text-xl font-semibold text-red-400 mb-2">Error Loading Subscription</h2>
          <p className="text-cosmic-text-muted">{error}</p>
        </div>
      </DashboardLayoutWrapper>
    );
  }

  if (!subscription) {
    return (
      <DashboardLayoutWrapper>
        <div className="text-center py-12">
          <Shield size={48} className="mx-auto text-cosmic-text-muted mb-4" />
          <h2 className="text-xl font-semibold text-cosmic-text mb-2">No Subscription Found</h2>
          <p className="text-cosmic-text-muted mb-6">
            You don't have an active subscription. Choose a plan to get started.
          </p>
          <Button variant="cosmic" onClick={() => window.location.href = '/onboarding/choose-plan'}>
            Choose Plan
          </Button>
        </div>
      </DashboardLayoutWrapper>
    );
  }

  const handlePlanChange = (plan?: Plan) => {
    setSelectedPlanForChange(plan || undefined);
    setShowPlanChangeModal(true);
  };

  const handleCancelSubscription = async () => {
    setActionLoading('cancel');
    try {
      await cancelSubscription();
      setShowCancelModal(false);
    } catch (err) {
      console.error('Failed to cancel subscription:', err);
    } finally {
      setActionLoading(null);
    }
  };

  const handleAddDeviceSlot = async () => {
    setActionLoading('add_slot');
    try {
      await addDeviceSlot();
    } catch (err) {
      console.error('Failed to add device slot:', err);
    } finally {
      setActionLoading(null);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'text-green-400 bg-green-500/20';
      case 'past_due': return 'text-orange-400 bg-orange-500/20';
      case 'canceled': return 'text-red-400 bg-red-500/20';
      case 'pending': return 'text-blue-400 bg-blue-500/20';
      default: return 'text-cosmic-text-muted bg-space-secondary';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active': return CheckCircle;
      case 'past_due': return AlertTriangle;
      case 'canceled': return AlertTriangle;
      case 'pending': return Clock;
      default: return Settings;
    }
  };

  const StatusIcon = getStatusIcon(subscription.status);

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

        {/* Current Subscription Overview */}
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-2xl p-8">
          {/* Plan Header */}
          <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between mb-8">
            <div className="flex items-center space-x-4 mb-6 lg:mb-0">
              <div className="w-16 h-16 bg-gradient-cosmic rounded-xl flex items-center justify-center">
                <Star className="w-8 h-8 text-white" />
              </div>
              <div>
                <h2 className="text-2xl font-bold text-cosmic-text mb-2">
                  {subscription.plan.name} Plan
                </h2>
                <div className="flex items-center space-x-4">
                  <span className={cn(
                    'px-3 py-1 rounded-full text-xs font-medium',
                    getStatusColor(subscription.status)
                  )}>
                    <StatusIcon size={12} className="mr-1 inline" />
                    {subscription.status.toUpperCase()}
                  </span>
                  <span className="text-cosmic-text-muted text-sm">
                    {subscription.interval === 'month' ? 'Monthly' : 'Yearly'} billing
                  </span>
                </div>
              </div>
            </div>

            {/* Pricing Display */}
            <div className="text-right">
              <div className="text-3xl font-bold text-cosmic-text">
                ${subscription.interval === 'month' 
                  ? subscription.plan.monthly_price 
                  : subscription.plan.yearly_price
                }
              </div>
              <div className="text-cosmic-text-muted">
                per {subscription.interval}
              </div>
              {subscription.additional_device_slots > 0 && (
                <div className="text-sm text-orange-400 mt-1">
                  +${subscription.additional_device_slots * 5}/month for extra devices
                </div>
              )}
            </div>
          </div>

          {/* Quick Stats Grid */}
          <div className="grid md:grid-cols-3 gap-6 mb-8">
            {/* Next Billing */}
            <div className="bg-space-secondary rounded-xl p-4">
              <div className="flex items-center space-x-3 mb-2">
                <Calendar className="w-5 h-5 text-cosmic-blue" />
                <span className="font-medium text-cosmic-text">Next Billing</span>
              </div>
              <div className="text-cosmic-text-muted">
                {nextBillingDate?.toLocaleDateString()} 
                <span className="text-cosmic-text ml-1">
                  ({daysUntilRenewal} days)
                </span>
              </div>
            </div>

            {/* Device Usage */}
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
                    className={cn(
                      'h-2 rounded-full transition-all',
                      deviceUsage.percentage >= 90 ? 'bg-red-400' :
                      deviceUsage.percentage >= 80 ? 'bg-orange-400' : 'bg-cosmic-blue'
                    )}
                    style={{ width: `${Math.min(deviceUsage.percentage, 100)}%` }}
                  />
                </div>
              </div>
            </div>

            {/* Plan Features */}
            <div className="bg-space-secondary rounded-xl p-4">
              <div className="flex items-center space-x-3 mb-2">
                <Star className="w-5 h-5 text-cosmic-blue" />
                <span className="font-medium text-cosmic-text">Plan Features</span>
              </div>
              <div className="text-cosmic-text-muted">
                {subscription.plan.features?.length || 0} features included
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex flex-wrap gap-3">
            <Button 
              variant="cosmic" 
              onClick={() => handlePlanChange()}
              className="flex items-center"
            >
              <TrendingUp className="w-4 h-4 mr-2" />
              Change Plan
            </Button>
            
            <Button variant="outline" onClick={() => window.location.href = '/user/billing'}>
              <CreditCard className="w-4 h-4 mr-2" />
              Manage Billing
            </Button>
            
            <Button variant="outline">
              <Download className="w-4 h-4 mr-2" />
              Download Invoice
            </Button>
            
            {deviceUsage.percentage >= 80 && (
              <Button 
                variant="stellar" 
                onClick={handleAddDeviceSlot}
                disabled={actionLoading === 'add_slot'}
              >
                {actionLoading === 'add_slot' ? (
                  <LoadingSpinner size="sm" />
                ) : (
                  <Plus className="w-4 h-4 mr-2" />
                )}
                Add Device Slot (+$5/mo)
              </Button>
            )}
            
            <Button 
              variant="ghost" 
              onClick={() => setShowCancelModal(true)}
              className="text-red-400 hover:text-red-300"
            >
              Cancel Subscription
            </Button>
          </div>
        </div>

        {/* Device Usage Warning */}
        {deviceUsage.percentage >= 80 && (
          <div className="bg-orange-500/10 border border-orange-500/20 rounded-xl p-6">
            <div className="flex items-start space-x-3">
              <AlertTriangle className="w-6 h-6 text-orange-400 mt-1 flex-shrink-0" />
              <div>
                <h3 className="font-semibold text-orange-400 mb-2">Device Limit Warning</h3>
                <p className="text-orange-300 mb-4">
                  You're using {deviceUsage.used} of {deviceUsage.limit} device slots. 
                  {deviceUsage.percentage >= 100 
                    ? " You've reached your limit and can't add more devices." 
                    : " Consider upgrading for more capacity."
                  }
                </p>
                <div className="flex space-x-3">
                  <Button variant="outline" size="sm" onClick={() => handlePlanChange()}>
                    <TrendingUp className="w-4 h-4 mr-2" />
                    Upgrade Plan
                  </Button>
                  <Button variant="ghost" size="sm" onClick={handleAddDeviceSlot}>
                    <Plus className="w-4 h-4 mr-2" />
                    Add Device Slot
                  </Button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Available Plans for Upgrade */}
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-2xl p-8">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-xl font-bold text-cosmic-text">Available Plans</h3>
            <span className="text-cosmic-text-muted text-sm">
              Compare and upgrade your plan
            </span>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {plans.map((plan) => {
              const isCurrent = plan.id === subscription.plan.id;
              const isUpgrade = plan.device_limit > subscription.plan.device_limit;
              const isDowngrade = plan.device_limit < subscription.plan.device_limit;

              return (
                <div
                  key={plan.id}
                  className={cn(
                    'rounded-xl p-6 border transition-all duration-200',
                    isCurrent 
                      ? 'border-stellar-accent bg-stellar-accent/10' 
                      : 'border-space-border bg-space-secondary hover:border-stellar-accent/50'
                  )}
                >
                  {/* Plan Header */}
                  <div className="text-center mb-4">
                    <div className="w-12 h-12 bg-gradient-cosmic rounded-lg flex items-center justify-center mx-auto mb-3">
                      {isUpgrade ? (
                        <TrendingUp size={24} className="text-white" />
                      ) : isDowngrade ? (
                        <TrendingUp size={24} className="text-white rotate-180" />
                      ) : (
                        <Star size={24} className="text-white" />
                      )}
                    </div>
                    <h4 className="font-semibold text-cosmic-text flex items-center justify-center space-x-2">
                      <span>{plan.name}</span>
                      {isCurrent && (
                        <span className="px-2 py-1 bg-green-500/20 text-green-400 text-xs rounded-full">
                          Current
                        </span>
                      )}
                    </h4>
                    <p className="text-cosmic-text-muted text-sm mt-1">
                      {plan.device_limit} devices included
                    </p>
                  </div>

                  {/* Pricing */}
                  <div className="text-center mb-4">
                    <div className="text-2xl font-bold text-cosmic-text">
                      ${plan.monthly_price}
                    </div>
                    <div className="text-cosmic-text-muted text-sm">per month</div>
                  </div>

                  {/* Key Features */}
                  <div className="space-y-2 mb-6">
                    {plan.features?.slice(0, 3).map((feature, index) => (
                      <div key={index} className="flex items-center text-cosmic-text text-sm">
                        <CheckCircle className="w-4 h-4 text-green-400 mr-2 flex-shrink-0" />
                        <span>{feature}</span>
                      </div>
                    ))}
                    {plan.features?.length > 3 && (
                      <div className="text-cosmic-text-muted text-xs">
                        +{plan.features.length - 3} more features
                      </div>
                    )}
                  </div>

                  {/* Action Button */}
                  {isCurrent ? (
                    <Button variant="outline" className="w-full" disabled>
                      <CheckCircle className="w-4 h-4 mr-2" />
                      Current Plan
                    </Button>
                  ) : (
                    <Button 
                      variant={isUpgrade ? "cosmic" : "outline"} 
                      className="w-full"
                      onClick={() => handlePlanChange(plan)}
                    >
                      {isUpgrade ? (
                        <>
                          <TrendingUp className="w-4 h-4 mr-2" />
                          Upgrade
                        </>
                      ) : (
                        <>
                          <ArrowRight className="w-4 h-4 mr-2" />
                          Change to {plan.name}
                        </>
                      )}
                    </Button>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Connected Devices */}
        {subscription.devices && subscription.devices.length > 0 && (
          <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-2xl p-8">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-xl font-bold text-cosmic-text">Connected Devices</h3>
              <span className="text-cosmic-text-muted">
                {subscription.devices.length} of {subscription.device_limit} slots used
              </span>
            </div>

            <div className="grid gap-4">
              {subscription.devices.map((device) => (
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
                    <span className={cn(
                      'px-2 py-1 text-xs font-medium rounded-full',
                      device.status === 'active' ? 'bg-green-500/20 text-green-400' : 'bg-gray-500/20 text-gray-400'
                    )}>
                      {device.status}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Plan Change Modal */}
        <PlanChangeModal
          isOpen={showPlanChangeModal}
          onClose={() => {
            setShowPlanChangeModal(false);
            setSelectedPlanForChange(undefined);
          }}
          onComplete={() => {
            // Refresh the page or trigger a data refresh
            window.location.reload();
          }}
          preselectedPlan={selectedPlanForChange}
        />

        {/* Cancel Confirmation Modal */}
        <Modal
          isOpen={showCancelModal}
          onClose={() => setShowCancelModal(false)}
          title="Cancel Subscription"
          size="sm"
        >
          <div className="text-center space-y-6">
            <div className="w-16 h-16 bg-red-500/20 rounded-full flex items-center justify-center mx-auto">
              <AlertTriangle className="w-8 h-8 text-red-400" />
            </div>
            
            <div>
              <h3 className="text-lg font-semibold text-red-400 mb-2">
                Cancel Your Subscription?
              </h3>
              <p className="text-cosmic-text-muted">
                Are you sure you want to cancel your subscription? You'll lose access to all premium features at the end of your billing period.
              </p>
            </div>
            
            <div className="flex space-x-3">
              <Button 
                variant="ghost"
                onClick={() => setShowCancelModal(false)}
                disabled={actionLoading === 'cancel'}
                className="flex-1"
              >
                Keep Subscription
              </Button>
              <Button 
                variant="cosmic"
                onClick={handleCancelSubscription}
                disabled={actionLoading === 'cancel'}
                className="flex-1 bg-red-500 hover:bg-red-600"
              >
                {actionLoading === 'cancel' ? (
                  <>
                    <LoadingSpinner size="sm" />
                    <span className="ml-2">Canceling...</span>
                  </>
                ) : (
                  'Yes, Cancel'
                )}
              </Button>
            </div>
          </div>
        </Modal>
      </div>
    </DashboardLayoutWrapper>
  );
}