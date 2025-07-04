// contexts/SubscriptionContext.tsx - FIXED with smart plan selection
'use client';

import { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { 
  Subscription, 
  Plan, 
  SubscriptionContextType,
  SubscriptionResponse,
  OnboardingResponse,
  PlanChangePreview,
  PlanChangeRequest,
  PlanChangeResult,
  DeviceSelectionData,
  PlanChangePreviewResponse,
  DevicesForSelectionResponse,
  PlanChangeResponse
} from '@/types/subscription';
import { api, subscriptionAPI } from '@/lib/api';
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

  // ✅ Preview plan change
  const previewPlanChange = useCallback(async (planId: number, interval: 'month' | 'year'): Promise<PlanChangePreview> => {
    try {
      console.log('🔄 Previewing plan change:', { planId, interval });
      
      const response = await subscriptionAPI.previewPlanChange(planId, interval) as PlanChangePreviewResponse;
      
      console.log('✅ Plan change preview:', response.data);
      return response.data;
      
    } catch (err) {
      console.error('❌ Failed to preview plan change:', err);
      throw err;
    }
  }, []);

  // ✅ Execute plan change
  const changePlan = useCallback(async (request: PlanChangeRequest): Promise<PlanChangeResult> => {
    try {
      setLoading(true);
      setError(null);
      
      console.log('🔄 Executing plan change:', request);
      
      const response = await subscriptionAPI.changePlan(request) as PlanChangeResponse;
      
      // Update local state with new subscription
      setSubscription(response.data.updated_subscription);
      
      console.log('✅ Plan change completed:', response.data.change_result);
      return response.data.change_result;
      
    } catch (err) {
      console.error('❌ Failed to change plan:', err);
      setError(err instanceof Error ? err.message : 'Failed to change plan');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  // ✅ FIXED: Smart plan selection - routes to appropriate API based on subscription status
  const selectPlan = useCallback(async (planId: number, interval: 'month' | 'year') => {
    try {
      setLoading(true);
      setError(null);
      
      console.log('🔄 Selecting plan:', { planId, interval, hasSubscription: !!subscription });
      
      // ✅ NEW LOGIC: Check if user already has a subscription
      if (subscription && subscription.status !== 'canceled') {
        // User has existing subscription - use plan change flow
        console.log('🔄 User has existing subscription, using plan change flow...');
        
        // First preview the change
        const preview = await previewPlanChange(planId, interval);
        
        // Find the best strategy (prefer immediate, fallback to recommended)
        const immediateStrategy = preview.available_strategies.find(s => s.type === 'immediate');
        const recommendedStrategy = preview.available_strategies.find(s => s.recommended);
        const selectedStrategy = immediateStrategy || recommendedStrategy || preview.available_strategies[0];
        
        if (!selectedStrategy) {
          throw new Error('No available strategy for plan change');
        }
        
        // Execute the plan change
        const request: PlanChangeRequest = {
          plan_id: planId,
          interval: interval,
          strategy: selectedStrategy.type,
          selected_device_ids: undefined // For simple immediate changes
        };
        
        const result = await changePlan(request);
        console.log('✅ Plan change completed via selectPlan:', result);
        
      } else {
        // User has no subscription - use onboarding flow
        console.log('🔄 User has no subscription, using onboarding flow...');
        
        const response = await api.onboarding.selectPlan(planId, interval) as OnboardingResponse;
        
        setSubscription(response.data.subscription);
        setUser(response.data.user);
        
        console.log('✅ Plan selected via onboarding:', response.message);
      }
      
    } catch (err) {
      console.error('❌ Failed to select plan:', err);
      setError(err instanceof Error ? err.message : 'Failed to select plan');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [subscription, setUser, previewPlanChange, changePlan]);

  // ✅ Get devices for selection
  const getDevicesForSelection = useCallback(async (): Promise<DeviceSelectionData[]> => {
    try {
      console.log('🔄 Fetching devices for selection...');
      
      const response = await subscriptionAPI.getDevicesForSelection() as DevicesForSelectionResponse;
      
      console.log('✅ Devices for selection:', response.data.devices);
      return response.data.devices;
      
    } catch (err) {
      console.error('❌ Failed to fetch devices for selection:', err);
      throw err;
    }
  }, []);

  // ✅ Schedule plan change
  const schedulePlanChange = useCallback(async (planId: number, interval: 'month' | 'year') => {
    try {
      setLoading(true);
      setError(null);
      
      console.log('🔄 Scheduling plan change:', { planId, interval });
      
      const response = await subscriptionAPI.schedulePlanChange(planId, interval);
      
      console.log('✅ Plan change scheduled:', response);
      return response;
      
    } catch (err) {
      console.error('❌ Failed to schedule plan change:', err);
      setError(err instanceof Error ? err.message : 'Failed to schedule plan change');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  // Cancel subscription
  const cancelSubscription = useCallback(async () => {
    if (!subscription) {
      setError('No subscription to cancel');
      return;
    }

    try {
      setLoading(true);
      setError(null);
      
      console.log('🔄 Canceling subscription...');
      
      await api.subscriptions.cancel(subscription.id.toString());
      
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
  }, [fetchSubscription, subscription]);

  // Add device slot
  const addDeviceSlot = useCallback(async () => {
    if (!subscription) {
      setError('No subscription found');
      return;
    }

    try {
      setLoading(true);
      setError(null);
      
      console.log('🔄 Adding device slot...');
      
      await api.subscriptions.addDeviceSlot(subscription.id.toString());
      
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
  }, [fetchSubscription, subscription]);

  // Remove device slot
  const removeDeviceSlot = useCallback(async (deviceId: number) => {
    if (!subscription) {
      setError('No subscription found');
      return;
    }

    try {
      setLoading(true);
      setError(null);
      
      console.log('🔄 Removing device slot for device:', deviceId);
      
      await api.subscriptions.removeDeviceSlot(subscription.id.toString(), deviceId.toString());
      
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
  }, [fetchSubscription, subscription]);

  // Computed properties with safe null checks
  const canAddDevice = subscription && subscription.devices ? 
    subscription.devices.length < subscription.device_limit : false;

  const deviceUsage = subscription ? {
    used: subscription.devices?.length || 0,
    limit: subscription.device_limit || 0,
    percentage: subscription.device_limit ? 
      ((subscription.devices?.length || 0) / subscription.device_limit) * 100 : 0
  } : {
    used: 0,
    limit: 0,
    percentage: 0
  };

  const nextBillingDate = subscription?.current_period_end ? 
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
    selectPlan, // ✅ Now smart - handles both onboarding and plan changes
    
    // Plan change methods
    previewPlanChange,
    changePlan,
    getDevicesForSelection,
    schedulePlanChange,
    
    // Existing methods
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

  // ✅ FIXED: Treat canceled subscriptions as "no active subscription"
  const hasActiveSubscription = !!subscription && subscription.status !== 'canceled';
  const hasSubscription = !!subscription; // Keep for backward compatibility
  const subscriptionStatus = subscription?.status || null;
  
  // ✅ FIXED: Canceled users need onboarding (new plan selection)
  const needsOnboarding = user && (!subscription || subscription.status === 'canceled');
  
  // ✅ FIXED: Only past_due is blocked (canceled should go to onboarding)
  const isBlocked = subscription?.status === 'past_due';

  const canAccessFeature = useCallback((feature: string) => {
    // ✅ FIXED: Only allow feature access for active subscriptions
    if (!subscription || subscription.status === 'canceled') return false;
    
    // Basic feature access logic
    const planFeatures = {
      'Basic': ['basic_monitoring', 'email_alerts', 'api_access'],
      'Professional': [
        'basic_monitoring', 
        'email_alerts', 
        'api_access', 
        'advanced_monitoring', 
        'priority_support', 
        'custom_integrations', 
        'data_analytics'
      ]
    };

    return planFeatures[subscription.plan?.name as keyof typeof planFeatures]?.includes(feature) || false;
  }, [subscription]);

  return {
    hasSubscription,
    hasActiveSubscription, // ✅ NEW: Distinguish between any subscription and active subscription
    subscriptionStatus,
    needsOnboarding,
    isBlocked,
    canAccessFeature,
    loading
  };
}