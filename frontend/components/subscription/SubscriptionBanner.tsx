// components/subscription/SubscriptionBanner.tsx
'use client';

import Link from 'next/link';
import { Button } from '@/components/ui/Button';
import { 
  AlertTriangle, 
  CreditCard, 
  Clock, 
  Users, 
  TrendingUp,
  X
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { useState } from 'react';

interface SubscriptionBannerProps {
  subscription?: any; // Replace with proper type when context is ready
  deviceUsage?: {
    used: number;
    limit: number;
    percentage: number;
  };
  daysUntilRenewal?: number;
  className?: string;
}

export function SubscriptionBanner({ 
  subscription, 
  deviceUsage, 
  daysUntilRenewal,
  className 
}: SubscriptionBannerProps) {
  const [dismissed, setDismissed] = useState<string[]>([]);

  // Mock data for development - remove when context is connected
  const mockSubscription = subscription || {
    status: 'active',
    plan: { name: 'Professional' }
  };
  
  const mockDeviceUsage = deviceUsage || {
    used: 4,
    limit: 5,
    percentage: 80
  };

  const mockDaysUntilRenewal = daysUntilRenewal || 7;

  // Don't show banner if no subscription issues
  if (!mockSubscription) return null;

  const alerts = [];

  // Payment issues
  if (mockSubscription.status === 'past_due') {
    alerts.push({
      id: 'payment_due',
      type: 'error',
      icon: CreditCard,
      title: 'Payment Required',
      message: 'Your subscription payment is overdue. Update your payment method to continue using all features.',
      action: { text: 'Update Payment', href: '/user/billing' }
    });
  }

  // Subscription canceled
  if (mockSubscription.status === 'canceled') {
    alerts.push({
      id: 'subscription_canceled',
      type: 'error',
      icon: AlertTriangle,
      title: 'Subscription Canceled',
      message: 'Your subscription has been canceled. Choose a new plan to continue monitoring your devices.',
      action: { text: 'Choose Plan', href: '/user/subscription' }
    });
  }

  // Renewal reminder
  if (mockSubscription.status === 'active' && mockDaysUntilRenewal <= 7 && mockDaysUntilRenewal > 0) {
    alerts.push({
      id: 'renewal_reminder',
      type: 'info',
      icon: Clock,
      title: 'Renewal Reminder',
      message: `Your subscription will renew in ${mockDaysUntilRenewal} day${mockDaysUntilRenewal !== 1 ? 's' : ''}.`,
      action: { text: 'Manage Billing', href: '/user/billing' }
    });
  }

  // Device limit warning
  if (mockDeviceUsage.percentage >= 80) {
    alerts.push({
      id: 'device_limit_warning',
      type: 'warning',
      icon: Users,
      title: 'Device Limit Warning',
      message: `You're using ${mockDeviceUsage.used} of ${mockDeviceUsage.limit} device slots. Consider upgrading for more devices.`,
      action: { text: 'Upgrade Plan', href: '/user/subscription' }
    });
  }

  // Filter out dismissed alerts
  const visibleAlerts = alerts.filter(alert => !dismissed.includes(alert.id));

  if (visibleAlerts.length === 0) return null;

  const dismissAlert = (alertId: string) => {
    setDismissed(prev => [...prev, alertId]);
  };

  return (
    <div className={cn('space-y-4', className)}>
      {visibleAlerts.map((alert) => {
        const Icon = alert.icon;
        
        return (
          <div
            key={alert.id}
            className={cn(
              'rounded-xl p-4 border relative',
              alert.type === 'error' 
                ? 'bg-red-500/10 border-red-500/20' 
                : alert.type === 'warning'
                ? 'bg-orange-500/10 border-orange-500/20'
                : 'bg-blue-500/10 border-blue-500/20'
            )}
          >
            {/* Dismiss Button */}
            <button
              onClick={() => dismissAlert(alert.id)}
              className="absolute top-4 right-4 text-cosmic-text-muted hover:text-cosmic-text transition-colors"
            >
              <X size={16} />
            </button>

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
                )}
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}

// Quick status indicator for headers/nav
export function SubscriptionStatusBadge({ subscription }: { subscription?: any }) {
  // Mock data
  const mockSubscription = subscription || { status: 'active', plan: { name: 'Pro' } };
  
  if (!mockSubscription) return null;

  const statusConfig = {
    active: { color: 'green', text: 'Active' },
    past_due: { color: 'orange', text: 'Past Due' },
    canceled: { color: 'red', text: 'Canceled' },
    pending: { color: 'blue', text: 'Pending' }
  };

  const config = statusConfig[mockSubscription.status as keyof typeof statusConfig];
  if (!config) return null;

  return (
    <div className={cn(
      'px-3 py-1 rounded-full text-xs font-medium',
      config.color === 'green' && 'bg-green-500/20 text-green-400',
      config.color === 'orange' && 'bg-orange-500/20 text-orange-400',
      config.color === 'red' && 'bg-red-500/20 text-red-400',
      config.color === 'blue' && 'bg-blue-500/20 text-blue-400'
    )}>
      {config.text}
    </div>
  );
}

// Device usage indicator for dashboard
export function DeviceUsageIndicator({ deviceUsage }: { deviceUsage?: any }) {
  // Mock data
  const mockUsage = deviceUsage || { used: 3, limit: 5, percentage: 60 };
  
  return (
    <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-lg p-4">
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center space-x-2">
          <Users size={16} className="text-cosmic-blue" />
          <span className="text-sm font-medium text-cosmic-text">Device Usage</span>
        </div>
        <span className="text-xs text-cosmic-text-muted">
          {mockUsage.used}/{mockUsage.limit}
        </span>
      </div>
      
      <div className="w-full bg-space-border rounded-full h-2">
        <div 
          className={cn(
            'h-2 rounded-full transition-all',
            mockUsage.percentage >= 90 ? 'bg-red-400' :
            mockUsage.percentage >= 80 ? 'bg-orange-400' : 'bg-cosmic-blue'
          )}
          style={{ width: `${Math.min(mockUsage.percentage, 100)}%` }}
        />
      </div>
      
      {mockUsage.percentage >= 80 && (
        <p className="text-xs text-orange-400 mt-2">
          Approaching device limit
        </p>
      )}
    </div>
  );
}