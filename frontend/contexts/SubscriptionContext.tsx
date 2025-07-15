// contexts/SubscriptionContext.tsx - FIXED to use AuthContext subscription data
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
  PlanChangeResponse,
  DeviceManagementData,
  DeviceManagementResponse
} from '@/types/subscription';
import { Device } from '@/types/device';
import { api, subscriptionAPI } from '@/lib/api';
import { useAuth } from '@/contexts/AuthContext';

const SubscriptionContext = createContext<SubscriptionContextType | undefined>(undefined);

export function SubscriptionProvider({ children }: { children: React.ReactNode }) {
  const [subscription, setSubscription] = useState<Subscription | null>(null);
  const [plans, setPlans] = useState<Plan[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  // ✅ NEW: Device management state
  const [deviceManagement, setDeviceManagement] = useState<DeviceManagementData | null>(null);
  
  const { user, setUser, loading: authLoading } = useAuth();

  // ✅ FIXED: Initialize subscription from AuthContext immediately
  useEffect(() => {
    if (user?.subscription) {
      console.log('🔄 Using subscription from AuthContext:', user.subscription);
      setSubscription(user.subscription);
      setLoading(false); // ✅ Set loading to false immediately
    } else if (user && !user.subscription) {
      console.log('🔄 User loaded but no subscription in AuthContext');
      setSubscription(null);
      setLoading(false); // ✅ Set loading to false for users without subscription
    }
  }, [user]);

  // Fetch additional subscription data (plans, etc.) - but don't block loading
  const fetchSubscriptionDetails = useCallback(async () => {
    if (!user) return;

    try {
      setError(null);
      console.log('🔄 Fetching additional subscription details...');
      
      const response = await api.get('/api/v1/frontend/subscriptions') as SubscriptionResponse;
      
      // ✅ FIXED: Only update subscription if we don't have it from AuthContext
      if (!subscription && response.data.current_subscription) {
        setSubscription(response.data.current_subscription);
      }
      
      // Always update plans
      setPlans(response.data.plans);
      
      console.log('✅ Additional subscription details loaded:', {
        plansCount: response.data.plans.length
      });
      
    } catch (err) {
      console.error('❌ Failed to fetch subscription details:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch subscription details');
    }
  }, [user, subscription]);

  // ✅ NEW: Fetch device management data
  const fetchDeviceManagement = useCallback(async () => {
    if (!user || !subscription) {
      setDeviceManagement(null);
      return;
    }

    try {
      setError(null);
      console.log('🔄 Fetching device management data...');
      
      const response = await subscriptionAPI.getDeviceManagement() as DeviceManagementResponse;
      
      setDeviceManagement(response.data);
      
      console.log('✅ Device management data loaded:', {
        operationalDevices: response.data.device_limits.operational_count,
        suspendedDevices: response.data.device_limits.suspended_count,
        suspensionPriorities: response.data.suspension_priorities.length,
        upsellOptions: response.data.upsell_options.length
      });
      
    } catch (err) {
      console.error('❌ Failed to fetch device management:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch device management data');
    }
  }, [user, subscription]);

  // ✅ NEW: suspend single device
  const suspendedevice = useCallback(async (deviceId: number, reason: string = 'user_choice') => {
    try {
      setError(null);
      console.log('🔄 suspended device:', deviceId, 'Reason:', reason);
      
      await subscriptionAPI.suspendDevice(deviceId, reason);
      
      // Refresh device management data
      await fetchDeviceManagement();
      
      console.log('✅ Device suspended successfully');
      
    } catch (err) {
      console.error('❌ Failed to suspend device:', err);
      setError(err instanceof Error ? err.message : 'Failed to suspend device');
      throw err;
    }
  }, [fetchDeviceManagement]);

  // ✅ NEW: Wake single device
  const wakeDevice = useCallback(async (deviceId: number) => {
    try {
      setError(null);
      console.log('🔄 Waking device:', deviceId);
      
      await subscriptionAPI.wakeDevice(deviceId);
      
      // Refresh device management data
      await fetchDeviceManagement();
      
      console.log('✅ Device woken successfully');
      
    } catch (err) {
      console.error('❌ Failed to wake device:', err);
      setError(err instanceof Error ? err.message : 'Failed to wake device');
      throw err;
    }
  }, [fetchDeviceManagement]);

  // ✅ NEW: suspend multiple devices
  const suspendMultipleDevices = useCallback(async (deviceIds: number[], reason: string = 'user_choice') => {
    try {
      setError(null);
      console.log('🔄 suspended multiple devices:', deviceIds, 'Reason:', reason);
      
      await subscriptionAPI.suspendMultipleDevices(deviceIds, reason);
      
      // Refresh device management data
      await fetchDeviceManagement();
      
      console.log('✅ Multiple devices suspended successfully');
      
    } catch (err) {
      console.error('❌ Failed to suspend multiple devices:', err);
      setError(err instanceof Error ? err.message : 'Failed to suspend devices');
      throw err;
    }
  }, [fetchDeviceManagement]);

  // ✅ NEW: Wake multiple devices
  const wakeMultipleDevices = useCallback(async (deviceIds: number[]) => {
    try {
      setError(null);
      console.log('🔄 Waking multiple devices:', deviceIds);
      
      await subscriptionAPI.wakeMultipleDevices(deviceIds);
      
      // Refresh device management data
      await fetchDeviceManagement();
      
      console.log('✅ Multiple devices woken successfully');
      
    } catch (err) {
      console.error('❌ Failed to wake multiple devices:', err);
      setError(err instanceof Error ? err.message : 'Failed to wake devices');
      throw err;
    }
  }, [fetchDeviceManagement]);

  // Preview plan change
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

  // Execute plan change
  const changePlan = useCallback(async (request: PlanChangeRequest): Promise<PlanChangeResult> => {
    try {
      setLoading(true);
      setError(null);
      
      console.log('🔄 Executing plan change:', request);
      
      const response = await subscriptionAPI.changePlan(request) as PlanChangeResponse;
      
      // Update local state with new subscription
      setSubscription(response.data.updated_subscription);
      
      // Refresh device management data to get updated suspension states
      await fetchDeviceManagement();
      
      console.log('✅ Plan change completed:', response.data.change_result);
      return response.data.change_result;
      
    } catch (err) {
      console.error('❌ Failed to change plan:', err);
      setError(err instanceof Error ? err.message : 'Failed to change plan');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [fetchDeviceManagement]);

  // ✅ FIXED: Smart plan selection - routes to appropriate API based on subscription status
  const selectPlan = useCallback(async (planId: number, interval: 'month' | 'year') => {
    try {
      setLoading(true);
      setError(null);
      
      console.log('🔄 Selecting plan:', { planId, interval, hasSubscription: !!subscription });
      
      // ✅ Check if user already has a subscription
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

  // Get devices for selection
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

  // Schedule plan change
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
      await fetchSubscriptionDetails();
      
      console.log('✅ Subscription canceled successfully');
      
    } catch (err) {
      console.error('❌ Failed to cancel subscription:', err);
      setError(err instanceof Error ? err.message : 'Failed to cancel subscription');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [fetchSubscriptionDetails, subscription]);

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
      await fetchSubscriptionDetails();
      await fetchDeviceManagement();
      
      console.log('✅ Device slot added successfully');
      
    } catch (err) {
      console.error('❌ Failed to add device slot:', err);
      setError(err instanceof Error ? err.message : 'Failed to add device slot');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [fetchSubscriptionDetails, fetchDeviceManagement, subscription]);

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
      await fetchSubscriptionDetails();
      await fetchDeviceManagement();
      
      console.log('✅ Device slot removed successfully');
      
    } catch (err) {
      console.error('❌ Failed to remove device slot:', err);
      setError(err instanceof Error ? err.message : 'Failed to remove device slot');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [fetchSubscriptionDetails, fetchDeviceManagement, subscription]);

  // ✅ FIXED: Initial load - only fetch details, don't wait for them
  useEffect(() => {
    if (user && !authLoading) {
      fetchSubscriptionDetails(); // Don't await - let it run in background
    }
  }, [user, authLoading]); // ✅ Depend on authLoading

  // Load device management when subscription changes
  useEffect(() => {
    if (subscription && subscription.status === 'active') {
      fetchDeviceManagement();
    }
  }, [subscription, fetchDeviceManagement]);

  // Computed properties with safe null checks
  const canAddDevice = subscription && subscription.devices ? 
    subscription.devices.length < subscription.device_limit : false;

  const deviceUsage = subscription ? {
    used: subscription.devices?.length || 0,
    limit: subscription.device_limit || 0,
    percentage: subscription.device_limit ? 
      ((subscription.devices?.length || 0) / subscription.device_limit) * 100 : 0,
    operational: deviceManagement?.device_limits.operational_count || 0,
    suspended: deviceManagement?.device_limits.suspended_count || 0
  } : {
    used: 0,
    limit: 0,
    percentage: 0,
    operational: 0,
    suspended: 0
  };

  const nextBillingDate = subscription?.current_period_end ? 
    new Date(subscription.current_period_end) : null;

  const isOnTrial = subscription ? 
    subscription.status === 'pending' : false;

  const daysUntilRenewal = nextBillingDate ? 
    Math.ceil((nextBillingDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24)) : 0;

  // ✅ NEW: suspension computed properties
  const operationalDevicesCount = deviceManagement?.device_limits.operational_count || 0;
  const suspendedDevicesCount = deviceManagement?.device_limits.suspended_count || 0;
  const isOverDeviceLimit = deviceManagement?.over_device_limit || false;
  const hassuspendedDevices = suspendedDevicesCount > 0;
  const devicesInGracePeriod = deviceManagement?.suspended_devices?.filter(d => d.in_grace_period).length || 0;

  const contextValue: SubscriptionContextType = {
    subscription,
    plans,
    loading: loading,
    error,
    
    // ✅ NEW: Device management data
    deviceManagement,
    
    // Actions
    fetchSubscription: fetchSubscriptionDetails, // ✅ Renamed for clarity
    selectPlan, // Smart - handles both onboarding and plan changes
    
    // ✅ NEW: Device management methods
    fetchDeviceManagement,
    suspendedevice,
    wakeDevice,
    suspendMultipleDevices,
    wakeMultipleDevices,
    
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
    
    // ✅ NEW: suspension computed properties
    operationalDevicesCount,
    suspendedDevicesCount,
    isOverDeviceLimit,
    hassuspendedDevices,
    devicesInGracePeriod,
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

// ✅ ENHANCED: Subscription guard hook with suspension awareness
export function useSubscriptionGuard() {
  const { subscription, loading } = useSubscription();
  const { user, loading: authLoading } = useAuth();

  // ✅ FIXED: Use subscription from AuthContext as fallback
  const effectiveSubscription = subscription || user?.subscription;
  const effectiveLoading = authLoading;

  console.log('🔒 SubscriptionGuard check:', {
    user: !!user,
    authLoading,
    subscription: !!effectiveSubscription,
    subscriptionStatus: effectiveSubscription?.status,
    effectiveLoading
  });

  // ✅ Treat canceled subscriptions as "no active subscription"
  const hasActiveSubscription = !!effectiveSubscription && effectiveSubscription.status !== 'canceled';
  const hasSubscription = !!effectiveSubscription; // Keep for backward compatibility
  const subscriptionStatus = effectiveSubscription?.status || null;
  
  // ✅ FIXED: Only check onboarding need when not loading
  const needsOnboarding = !effectiveLoading && user && (!effectiveSubscription || effectiveSubscription.status === 'canceled');
  
  // ✅ Only past_due is blocked (canceled should go to onboarding)
  const isBlocked = effectiveSubscription?.status === 'past_due';

  const canAccessFeature = useCallback((feature: string) => {
    // ✅ Only allow feature access for active subscriptions
    if (!effectiveSubscription || effectiveSubscription.status === 'canceled') return false;
    
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

    return planFeatures[effectiveSubscription.plan?.name as keyof typeof planFeatures]?.includes(feature) || false;
  }, [effectiveSubscription]);

  return {
    hasSubscription,
    hasActiveSubscription, // ✅ Distinguish between any subscription and active subscription
    subscriptionStatus,
    needsOnboarding,
    isBlocked,
    canAccessFeature,
    loading: effectiveLoading // ✅ Return combined loading state
  };
}