// components/subscription/SubscriptionBanner.tsx - ENHANCED
'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Button } from '@/components/ui/Button';
import { useSubscription } from '@/contexts/SubscriptionContext';
import { PlanChangeModal } from './PlanChangeModal';
import { 
  AlertTriangle, 
  CreditCard, 
  Clock, 
  Users, 
  TrendingUp,
  X,
  Zap,
  Star
} from 'lucide-react';
import { cn } from '@/lib/utils';

interface SubscriptionBannerProps {
  className?: string;
  showOnlyWarnings?: boolean;
}

export function SubscriptionBanner({ 
  className,
  showOnlyWarnings = false 
}: SubscriptionBannerProps) {
  const { subscription, deviceUsage, daysUntilRenewal } = useSubscription();
  const [dismissed, setDismissed] = useState<string[]>([]);
  const [showPlanChangeModal, setShowPlanChangeModal] = useState(false);

  if (!subscription) return null;

  const alerts = [];

  // Payment issues (highest priority)
  if (subscription.status === 'past_due') {
    alerts.push({
      id: 'payment_due',
      type: 'error' as const,
      icon: CreditCard,
      title: 'Payment Required',
      message: 'Your subscription payment is overdue. Update your payment method to continue using all features.',
      action: { text: 'Update Payment', href: '/user/billing' }
    });
  }

  // Subscription canceled
  if (subscription.status === 'canceled') {
    alerts.push({
      id: 'subscription_canceled',
      type: 'error' as const,
      icon: AlertTriangle,
      title: 'Subscription Ended',
      message: 'Your subscription has ended. Choose a new plan to continue monitoring your devices.',
      action: { text: 'Choose Plan', action: () => setShowPlanChangeModal(true) }
    });
  }

  // Device limit warnings
  if (deviceUsage.percentage >= 100) {
    alerts.push({
      id: 'device_limit_reached',
      type: 'warning' as const,
      icon: Users,
      title: 'Device Limit Reached',
      message: `You're using all ${deviceUsage.limit} device slots. Upgrade your plan or add device slots to connect more devices.`,
      action: { text: 'Upgrade Plan', action: () => setShowPlanChangeModal(true) }
    });
  } else if (deviceUsage.percentage >= 80) {
    alerts.push({
      id: 'device_limit_warning',
      type: 'warning' as const,
      icon: Users,
      title: 'Approaching Device Limit',
      message: `You're using ${deviceUsage.used} of ${deviceUsage.limit} device slots. Consider upgrading for more capacity.`,
      action: { text: 'Upgrade Plan', action: () => setShowPlanChangeModal(true) }
    });
  }

  // Renewal reminder (only if not showing only warnings)
  if (!showOnlyWarnings && subscription.status === 'active' && daysUntilRenewal <= 7 && daysUntilRenewal > 0) {
    alerts.push({
      id: 'renewal_reminder',
      type: 'info' as const,
      icon: Clock,
      title: 'Renewal Reminder',
      message: `Your subscription will renew in ${daysUntilRenewal} day${daysUntilRenewal !== 1 ? 's' : ''}.`,
      action: { text: 'Manage Billing', href: '/user/billing' }
    });
  }

  // Upgrade suggestions (only if not showing only warnings)
  if (!showOnlyWarnings && subscription.plan.name === 'Basic' && deviceUsage.used >= 1) {
    alerts.push({
      id: 'upgrade_suggestion',
      type: 'info' as const,
      icon: Star,
      title: 'Unlock More Features',
      message: 'Upgrade to Professional for advanced monitoring, priority support, and more devices.',
      action: { text: 'See Plans', action: () => setShowPlanChangeModal(true) }
    });
  }

  // Filter out dismissed alerts
  const visibleAlerts = alerts.filter(alert => !dismissed.includes(alert.id));

  if (visibleAlerts.length === 0) return null;

  const dismissAlert = (alertId: string) => {
    setDismissed(prev => [...prev, alertId]);
  };

  return (
    <>
      <div className={cn('space-y-3', className)}>
        {visibleAlerts.map((alert) => {
          const Icon = alert.icon;
          
          return (
            <div
              key={alert.id}
              className={cn(
                'rounded-xl p-4 border relative',
                alert.type === 'error' 
                  ? 'bg-red-500/10 border-red-500/20 backdrop-blur-md' 
                  : alert.type === 'warning'
                  ? 'bg-orange-500/10 border-orange-500/20 backdrop-blur-md'
                  : 'bg-blue-500/10 border-blue-500/20 backdrop-blur-md'
              )}
            >
              {/* Dismiss Button */}
              {alert.type !== 'error' && (
                <button
                  onClick={() => dismissAlert(alert.id)}
                  className="absolute top-3 right-3 text-cosmic-text-muted hover:text-cosmic-text transition-colors"
                >
                  <X size={16} />
                </button>
              )}

              <div className="flex items-start space-x-3 pr-8">
                <Icon className={cn(
                  'w-5 h-5 mt-0.5 flex-shrink-0',
                  alert.type === 'error' ? 'text-red-400' : 
                  alert.type === 'warning' ? 'text-orange-400' : 'text-blue-400'
                )} />
                
                <div className="flex-1">
                  <h4 className={cn(
                    'font-medium mb-1',
                    alert.type === 'error' ? 'text-red-400' : 
                    alert.type === 'warning' ? 'text-orange-400' : 'text-blue-400'
                  )}>
                    {alert.title}
                  </h4>
                  <p className={cn(
                    'text-sm mb-3',
                    alert.type === 'error' ? 'text-red-300' : 
                    alert.type === 'warning' ? 'text-orange-300' : 'text-blue-300'
                  )}>
                    {alert.message}
                  </p>
                  
                  {alert.action && (
                    <>
                      {alert.action.href ? (
                        <Link href={alert.action.href}>
                          <Button 
                            variant="outline" 
                            size="sm"
                            className={cn(
                              'border-current',
                              alert.type === 'error' 
                                ? 'text-red-400 hover:bg-red-500/20' 
                                : alert.type === 'warning'
                                ? 'text-orange-400 hover:bg-orange-500/20'
                                : 'text-blue-400 hover:bg-blue-500/20'
                            )}
                          >
                            {alert.action.text}
                          </Button>
                        </Link>
                      ) : (
                        <Button 
                          variant="outline" 
                          size="sm"
                          onClick={alert.action.action}
                          className={cn(
                            'border-current',
                            alert.type === 'error' 
                              ? 'text-red-400 hover:bg-red-500/20' 
                              : alert.type === 'warning'
                              ? 'text-orange-400 hover:bg-orange-500/20'
                              : 'text-blue-400 hover:bg-blue-500/20'
                          )}
                        >
                          {alert.action.text}
                        </Button>
                      )}
                    </>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Plan Change Modal */}
      <PlanChangeModal
        isOpen={showPlanChangeModal}
        onClose={() => setShowPlanChangeModal(false)}
        onComplete={() => {
          // Refresh to show updated state
          window.location.reload();
        }}
      />
    </>
  );
}

// Quick status indicator for headers/nav
export function SubscriptionStatusBadge({ className }: { className?: string }) {
  const { subscription } = useSubscription();
  
  if (!subscription) return null;

  const statusConfig = {
    active: { color: 'green', text: 'Active' },
    past_due: { color: 'orange', text: 'Past Due' },
    canceled: { color: 'red', text: 'Canceled' },
    pending: { color: 'blue', text: 'Pending' }
  };

  const config = statusConfig[subscription.status as keyof typeof statusConfig];
  if (!config) return null;

  return (
    <div className={cn(
      'px-3 py-1 rounded-full text-xs font-medium',
      config.color === 'green' && 'bg-green-500/20 text-green-400',
      config.color === 'orange' && 'bg-orange-500/20 text-orange-400',
      config.color === 'red' && 'bg-red-500/20 text-red-400',
      config.color === 'blue' && 'bg-blue-500/20 text-blue-400',
      className
    )}>
      {config.text}
    </div>
  );
}

// Device usage indicator for dashboard
export function DeviceUsageIndicator({ className }: { className?: string }) {
  const { deviceUsage } = useSubscription();
  
  return (
    <div className={cn('bg-space-glass backdrop-blur-md border border-space-border rounded-lg p-4', className)}>
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center space-x-2">
          <Users size={16} className="text-cosmic-blue" />
          <span className="text-sm font-medium text-cosmic-text">Device Usage</span>
        </div>
        <span className="text-xs text-cosmic-text-muted">
          {deviceUsage.used}/{deviceUsage.limit}
        </span>
      </div>
      
      <div className="w-full bg-space-border rounded-full h-2">
        <div 
          className={cn(
            'h-2 rounded-full transition-all',
            deviceUsage.percentage >= 90 ? 'bg-red-400' :
            deviceUsage.percentage >= 80 ? 'bg-orange-400' : 'bg-cosmic-blue'
          )}
          style={{ width: `${Math.min(deviceUsage.percentage, 100)}%` }}
        />
      </div>
      
      {deviceUsage.percentage >= 80 && (
        <p className="text-xs text-orange-400 mt-2">
          {deviceUsage.percentage >= 100 ? 'Device limit reached' : 'Approaching device limit'}
        </p>
      )}
    </div>
  );
}

// Compact upgrade prompt for specific features
export function UpgradePrompt({ 
  feature, 
  className 
}: { 
  feature: string;
  className?: string;
}) {
  const { subscription } = useSubscription();
  const [showPlanChangeModal, setShowPlanChangeModal] = useState(false);
  
  // Only show for Basic plan users
  if (!subscription || subscription.plan.name !== 'Basic') return null;

  return (
    <>
      <div className={cn(
        'bg-gradient-cosmic rounded-xl p-6 text-center',
        className
      )}>
        <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-4">
          <Zap className="w-6 h-6 text-white" />
        </div>
        <h3 className="text-lg font-semibold text-white mb-2">
          Unlock {feature}
        </h3>
        <p className="text-white/80 mb-4">
          Upgrade to Professional for access to {feature.toLowerCase()} and more advanced features.
        </p>
        <Button 
          variant="outline" 
          onClick={() => setShowPlanChangeModal(true)}
          className="border-white text-white hover:bg-white/10"
        >
          <TrendingUp className="w-4 h-4 mr-2" />
          Upgrade Now
        </Button>
      </div>

      <PlanChangeModal
        isOpen={showPlanChangeModal}
        onClose={() => setShowPlanChangeModal(false)}
        onComplete={() => window.location.reload()}
      />
    </>
  );
}