// types/subscription.ts - ENHANCED with plan change types

export interface Plan {
  id: number;
  name: string;
  description: string;
  device_limit: number;
  monthly_price: number;
  yearly_price: number;
  features: string[];
  stripe_monthly_price_id: string;
  stripe_yearly_price_id: string;
  created_at?: string;
  updated_at?: string;
  active?: boolean;
}

export interface Subscription {
  id: number;
  plan: Plan;
  status: 'active' | 'past_due' | 'canceled' | 'pending';
  interval: 'month' | 'year';
  device_limit: number;
  additional_device_slots: number;
  current_period_start: string;
  current_period_end: string;
  cancel_at_period_end: boolean;
  stripe_subscription_id?: string;
  devices?: Array<{
    id: number;
    name: string;
    device_type: string;
    status: string;
    alert_status?: string;
    last_connection?: string;
  }>;
  user_id?: number;
  plan_id?: number;
  stripe_customer_id?: string;
  
  // Computed properties that might come from API
  days_until_renewal?: number;
  is_trial?: boolean;
}

export interface User {
  id: number;
  email: string;
  role: 'user' | 'pro' | 'admin';
  created_at: string;
  devices_count: number;
  subscription?: Subscription;
}

// ✅ NEW: Plan Change Types

export interface PlanChangePreview {
  change_type: 'new_subscription' | 'current' | 'upgrade' | 'downgrade_safe' | 'downgrade_warning';
  current_plan: {
    id: number;
    name: string;
    device_limit: number;
    monthly_price: number;
    yearly_price: number;
    current_interval: string;
    devices_used: number;
    additional_device_slots: number;
  } | null;
  target_plan: {
    id: number;
    name: string;
    device_limit: number;
    monthly_price: number;
    yearly_price: number;
    target_interval: string;
  };
  device_impact: {
    current_device_count: number;
    target_device_limit: number;
    device_difference: number;
    requires_device_selection: boolean;
    excess_device_count: number;
    affected_devices: DeviceSelectionData[];
  };
  billing_impact: {
    current_monthly_cost: number;
    target_monthly_cost: number;
    cost_difference: number;
    no_refund_policy: boolean;
    extra_device_cost_per_month: number;
    potential_extra_cost: number;
  };
  warnings: string[];
  available_strategies: ChangeStrategy[];
}

export interface ChangeStrategy {
  type: 'immediate' | 'immediate_with_selection' | 'end_of_period' | 'pay_for_extra';
  name: string;
  description: string;
  recommended: boolean;
  extra_monthly_cost?: number;
}

export interface DeviceSelectionData {
  id: number;
  name: string;
  device_type: string;
  status: string;
  last_connection: string | null;
  alert_status: string;
  is_offline: boolean;
  priority_reason: string;
  recommendation: 'recommended_to_disable' | 'consider_disabling' | 'keep_active' | 'has_errors';
  offline_duration?: string;
  sensor_count?: number;
  has_errors?: boolean;
  priority_score?: number;
}

export interface PlanChangeRequest {
  plan_id: number;
  interval: 'month' | 'year';
  strategy: 'immediate' | 'immediate_with_selection' | 'end_of_period' | 'pay_for_extra';
  selected_device_ids?: number[];
}

export interface PlanChangeResult {
  status: 'completed' | 'scheduled' | 'failed';
  subscription?: Subscription;
  disabled_devices?: number;
  extra_device_slots?: number;
  extra_monthly_cost?: number;
  effective_date?: string;
  scheduled_change_id?: string;
  message: string;
}

export interface ScheduledPlanChange {
  id: string;
  target_plan: Plan;
  target_interval: 'month' | 'year';
  scheduled_for: string;
  status: 'pending' | 'completed' | 'canceled' | 'failed';
  created_at: string;
}

// API Response types
export interface PlansResponse {
  status: 'success';
  data: {
    plans: Plan[];
  };
}

export interface SubscriptionResponse {
  status: 'success';
  data: {
    current_subscription: Subscription | null;
    plans: Plan[];
    device_summary?: {
      total: number;
      active: number;
      pending: number;
      disabled: number;
      offline: number;
      with_errors: number;
      with_warnings: number;
      device_limit: number;
      available_slots: number;
    };
  };
}

export interface PlanChangePreviewResponse {
  status: 'success';
  data: PlanChangePreview;
}

export interface DevicesForSelectionResponse {
  status: 'success';
  data: {
    devices: DeviceSelectionData[];
    total_count: number;
    recommendations: {
      recommended_to_disable: number;
      consider_disabling: number;
      keep_active: number;
    };
  };
}

export interface PlanChangeResponse {
  status: 'success';
  data: {
    change_result: PlanChangeResult;
    updated_subscription: Subscription;
    device_summary: any;
  };
  message: string;
}

export interface OnboardingResponse {
  status: 'success';
  message: string;
  data: {
    subscription: Subscription;
    user: User;
    checkout_url?: string;
  };
}

// Device usage tracking
export interface DeviceUsage {
  used: number;
  limit: number;
  percentage: number;
}

// Context types
export interface SubscriptionContextType {
  subscription: Subscription | null;
  plans: Plan[];
  loading: boolean;
  error: string | null;
  
  // Actions
  fetchSubscription: () => Promise<void>;
  selectPlan: (planId: number, interval: 'month' | 'year') => Promise<void>;
  
  // ✅ NEW: Plan change methods
  previewPlanChange: (planId: number, interval: 'month' | 'year') => Promise<PlanChangePreview>;
  changePlan: (request: PlanChangeRequest) => Promise<PlanChangeResult>;
  getDevicesForSelection: () => Promise<DeviceSelectionData[]>;
  schedulePlanChange: (planId: number, interval: 'month' | 'year') => Promise<any>;
  
  // Existing methods
  cancelSubscription: () => Promise<void>;
  addDeviceSlot: () => Promise<void>;
  removeDeviceSlot: (deviceId: number) => Promise<void>;
  
  // Computed properties
  canAddDevice: boolean;
  deviceUsage: DeviceUsage;
  nextBillingDate: Date | null;
  isOnTrial: boolean;
  daysUntilRenewal: number;
}

// Hook return types
export interface UseSubscriptionGuardReturn {
  hasSubscription: boolean;
  subscriptionStatus: Subscription['status'] | null;
  needsOnboarding: boolean;
  isBlocked: boolean;
  canAccessFeature: (feature: string) => boolean;
  loading?: boolean;
}

// Component Props
export interface PlanCardProps {
  plan: Plan;
  interval: 'month' | 'year';
  selected: boolean;
  onSelect: () => void;
  currentPlan?: Plan;
  isUpgrade?: boolean;
  loading?: boolean;
}

export interface SubscriptionGuardProps {
  children: React.ReactNode;
  requiresSubscription?: boolean;
  allowedWithoutSubscription?: string[];
}

// Utility types
export type SubscriptionStatus = 'active' | 'pending' | 'canceled' | 'past_due' | 'trialing';
export type PlanChangeType = 'new_subscription' | 'current' | 'upgrade' | 'downgrade_safe' | 'downgrade_warning';
export type ChangeStrategyType = 'immediate' | 'immediate_with_selection' | 'end_of_period' | 'pay_for_extra';

// Error types
export interface SubscriptionError extends Error {
  code?: string;
  details?: any;
}