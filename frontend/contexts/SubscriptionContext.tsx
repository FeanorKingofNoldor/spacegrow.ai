// contexts/SubscriptionContext.tsx
'use client';

import { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { 
  Subscription, 
  Plan, 
  SubscriptionContextType,
  SubscriptionResponse,
  OnboardingResponse 
} from '@/types/subscription';
import { api } from '@/lib/api';
import { useAuth } from '@/contexts/AuthContext';

const SubscriptionContext = createContext<SubscriptionContextType | undefined>(undefined);

export function SubscriptionProvider({ children }: { children: React.ReactNode }) {
  const [subscription, setSubscription] = useState<Subscription | null>(null);
  const [plans, setPlans] = useState<Plan[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  const { user, setUser } = useAuth();

  // Fetch subscription data
  const fetchSubscription = useCallback(async () => {
    if (!user) {
      setLoading(false);
      return;
    }

    try {
      setError(null);
      console.log('🔄 Fetching subscription data...');
      
      const response = await api.get('/api/v1/frontend/subscriptions') as SubscriptionResponse;
      
      setSubscription(response.data.current_subscription);
      setPlans(response.data.plans);
      
      console.log('✅ Subscription data loaded:', {
        subscription: response.data.current_subscription,
        plansCount: response.data.plans.length
      });
      
    } catch (err) {
      console.error('❌ Failed to fetch subscription:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch subscription data');
    } finally {
      setLoading(false);
    }
  }, [user]);

  // Initial load
  useEffect(() => {
    fetchSubscription();
  }, [fetchSubscription]);

  // Select plan (onboarding)
  const selectPlan = useCallback(async (planId: number, interval: 'month' | 'year') => {
    try {
      setLoading(true);
      setError(null);
      
      console.log('🔄 Selecting plan:', { planId, interval });
      
      const response = await api.post('/api/v1/frontend/onboarding/select_plan', {
        plan_id: planId,
        interval
      }) as OnboardingResponse;
      
      // Update local state
      setSubscription(response.data.subscription);
      setUser(response.data.user);
      
      console.log('✅ Plan selected successfully:', response.message);
      
    } catch (err) {
      console.error('❌ Failed to select plan:', err);
      setError(err instanceof Error ? err.message : 'Failed to select plan');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [setUser]);

  // Change plan (existing subscription)
  const changePlan = useCallback(async (planId: number, interval: 'month' | 'year') => {
    try {
      setLoading(true);
      setError(null);
      
      console.log('🔄 Changing plan:', { planId, interval });
      
      const response = await api.post('/api/v1/frontend/subscriptions/select_plan', {
        plan_id: planId,
        interval
      });
      
      // Refresh subscription data
      await fetchSubscription();
      
      console.log('✅ Plan changed successfully');
      
    } catch (err) {
      console.error('❌ Failed to change plan:', err);
      setError(err instanceof Error ? err.message : 'Failed to change plan');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [fetchSubscription]);

  // Cancel subscription
  const cancelSubscription = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      console.log('🔄 Canceling subscription...');
      
      await api.delete('/api/v1/frontend/subscriptions/cancel');
      
      // Refresh subscription data
      await fetchSubscription();
      
      console.log('✅ Subscription canceled successfully');
      
    } catch (err) {
      console.error('❌ Failed to cancel subscription:', err);
      setError(err instanceof Error ? err.message : 'Failed to cancel subscription');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [fetchSubscription]);

  // Add device slot
  const addDeviceSlot = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      console.log('🔄 Adding device slot...');
      
      const response = await api.post('/api/v1/frontend/subscriptions/add_device_slot');
      
      // Refresh subscription data
      await fetchSubscription();
      
      console.log('✅ Device slot added successfully');
      
    } catch (err) {
      console.error('❌ Failed to add device slot:', err);
      setError(err instanceof Error ? err.message : 'Failed to add device slot');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [fetchSubscription]);

  // Remove device slot
  const removeDeviceSlot = useCallback(async (deviceId: number) => {
    try {
      setLoading(true);
      setError(null);
      
      console.log('🔄 Removing device slot for device:', deviceId);
      
      await api.delete('/api/v1/frontend/subscriptions/remove_device_slot', {
        device_id: deviceId
      });
      
      // Refresh subscription data
      await fetchSubscription();
      
      console.log('✅ Device slot removed successfully');
      
    } catch (err) {
      console.error('❌ Failed to remove device slot:', err);
      setError(err instanceof Error ? err.message : 'Failed to remove device slot');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [fetchSubscription]);

  // Computed properties
  const canAddDevice = subscription ? 
    subscription.devices.length < subscription.device_limit : false;

  const deviceUsage = subscription ? {
    used: subscription.devices.length,
    limit: subscription.device_limit,
    percentage: (subscription.devices.length / subscription.device_limit) * 100
  } : {
    used: 0,
    limit: 0,
    percentage: 0
  };

  const nextBillingDate = subscription ? 
    new Date(subscription.current_period_end) : null;

  const isOnTrial = subscription ? 
    subscription.status === 'pending' : false;

  const daysUntilRenewal = nextBillingDate ? 
    Math.ceil((nextBillingDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24)) : 0;

  const contextValue: SubscriptionContextType = {
    subscription,
    plans,
    loading,
    error,
    
    // Actions
    fetchSubscription,
    selectPlan,
    changePlan,
    cancelSubscription,
    addDeviceSlot,
    removeDeviceSlot,
    
    // Computed properties
    canAddDevice,
    deviceUsage,
    nextBillingDate,
    isOnTrial,
    daysUntilRenewal,
  };

  return (
    <SubscriptionContext.Provider value={contextValue}>
      {children}
    </SubscriptionContext.Provider>
  );
}

export function useSubscription() {
  const context = useContext(SubscriptionContext);
  if (context === undefined) {
    throw new Error('useSubscription must be used within a SubscriptionProvider');
  }
  return context;
}

// Subscription guard hook
export function useSubscriptionGuard() {
  const { subscription, loading } = useSubscription();
  const { user } = useAuth();

  const hasSubscription = !!subscription;
  const subscriptionStatus = subscription?.status || null;
  const needsOnboarding = user && !subscription;
  const isBlocked = subscription?.status === 'canceled' || subscription?.status === 'past_due';

  const canAccessFeature = useCallback((feature: string) => {
    if (!subscription) return false;
    
    // Basic feature access logic
    const planFeatures = {
      'Basic': ['basic_monitoring', 'email_alerts', 'api_access'],
      'Professional': ['basic_monitoring', 'email_alerts', 'api_access', 'advanced_monitoring', 'priority_support', 'custom_integrations', 'data_analytics']
    };

    return planFeatures[subscription.plan.name as keyof typeof planFeatures]?.includes(feature) || false;
  }, [subscription]);

  return {
    hasSubscription,
    subscriptionStatus,
    needsOnboarding,
    isBlocked,
    canAccessFeature,
    loading
  };
}