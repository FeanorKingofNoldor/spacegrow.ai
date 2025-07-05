// types/subscription.ts - COMPLETE with hibernation and device management types

import { Device, HibernationPriority, UpsellOption } from './device';

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

// ✅ ENHANCED: Subscription interface with hibernation support
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
  
  // ✅ NEW: Device hibernation data
  devices?: Array<{
    id: number;
    name: string;
    device_type: string;
    status: string;
    alert_status?: string;
    last_connection?: string;
    hibernated_at?: string | null;
    hibernating?: boolean;
    operational?: boolean;
    in_grace_period?: boolean;
  }>;
  
  // ✅ NEW: Device counts with hibernation breakdown
  device_counts?: {
    total: number;
    operational: number;
    hibernating: number;
  };
  
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

// ✅ NEW: Device Management Types
export interface DeviceManagementData {
  subscription: {
    id: number;
    plan: {
      id: number;
      name: string;
      device_limit: number;
      monthly_price: number;
      yearly_price: number;
      features: string[];
    };
    status: string;
    interval: string;
    device_limit: number;
    additional_device_slots: number;
    current_period_start: string;
    current_period_end: string;
    device_counts: {
      total: number;
      operational: number;
      hibernating: number;
    };
  };
  device_limits: {
    total_limit: number;
    operational_count: number;
    hibernating_count: number;
    available_slots: number;
  };
  devices: {
    operational: Device[];
    hibernating: Device[];
  };
  operational_devices: Device[];
  hibernating_devices: Array<Device & {
    hibernation_priority_score?: number;
    in_grace_period: boolean;
    days_until_grace_period_end?: number;
  }>;
  hibernation_priorities: HibernationPriority[];
  upsell_options: UpsellOption[];
  over_device_limit: boolean;
}

export interface DeviceManagementResponse {
  status: 'success';
  data: DeviceManagementData;
}

// ✅ NEW: Plan Change Types (existing but enhanced)
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
    hibernating_devices_count?: number; // ✅ NEW
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
  type: 'immediate' | 'immediate_with_selection' | 'end_of_period' | 'pay_for_extra' | 'hibernate_excess'; // ✅ NEW
  name: string;
  description: string;
  recommended: boolean;
  extra_monthly_cost?: number;
  devices_to_hibernate?: number; // ✅ NEW
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
  recommendation: 'recommended_to_disable' | 'consider_disabling' | 'keep_active' | 'has_errors' | 'recommended_to_hibernate'; // ✅ NEW
  offline_duration?: string;
  sensor_count?: number;
  has_errors?: boolean;
  priority_score?: number;
  hibernated_at?: string | null; // ✅ NEW
  hibernating?: boolean; // ✅ NEW
  can_hibernate?: boolean; // ✅ NEW
}

export interface PlanChangeRequest {
  plan_id: number;
  interval: 'month' | 'year';
  strategy: 'immediate' | 'immediate_with_selection' | 'end_of_period' | 'pay_for_extra' | 'hibernate_excess'; // ✅ NEW
  selected_device_ids?: number[];
  devices_to_hibernate?: number[]; // ✅ NEW
}

export interface PlanChangeResult {
  status: 'completed' | 'scheduled' | 'failed';
  subscription?: Subscription;
  disabled_devices?: number;
  hibernated_devices?: number; // ✅ NEW
  extra_device_slots?: number;
  extra_monthly_cost?: number;
  effective_date?: string;
  scheduled_change_id?: string;
  message: string;
  hibernation_summary?: { // ✅ NEW
    hibernated_count: number;
    grace_period_days: number;
    can_wake_immediately: boolean;
  };
}

export interface ScheduledPlanChange {
  id: string;
  target_plan: Plan;
  target_interval: 'month' | 'year';
  scheduled_for: string;
  status: 'pending' | 'completed' | 'canceled' | 'failed';
  created_at: string;
}

// ✅ ENHANCED: Context types with hibernation methods
export interface SubscriptionContextType {
  subscription: Subscription | null;
  plans: Plan[];
  loading: boolean;
  error: string | null;
  
  // ✅ NEW: Device management data
  deviceManagement: DeviceManagementData | null;
  
  // Actions
  fetchSubscription: () => Promise<void>;
  selectPlan: (planId: number, interval: 'month' | 'year') => Promise<void>;
  
  // ✅ NEW: Device management methods
  fetchDeviceManagement: () => Promise<void>;
  hibernateDevice: (deviceId: number, reason?: string) => Promise<void>;
  wakeDevice: (deviceId: number) => Promise<void>;
  hibernateMultipleDevices: (deviceIds: number[], reason?: string) => Promise<void>;
  wakeMultipleDevices: (deviceIds: number[]) => Promise<void>;
  
  // Plan change methods
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
  
  // ✅ NEW: Hibernation computed properties
  operationalDevicesCount: number;
  hibernatingDevicesCount: number;
  isOverDeviceLimit: boolean;
  hasHibernatingDevices: boolean;
  devicesInGracePeriod: number;
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
      operational?: number; // ✅ NEW
      hibernating?: number; // ✅ NEW
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
      recommended_to_hibernate?: number; // ✅ NEW
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
  operational?: number; // ✅ NEW
  hibernating?: number; // ✅ NEW
}

// Hook return types
export interface UseSubscriptionGuardReturn {
  hasSubscription: boolean;
  subscriptionStatus: Subscription['status'] | null;
  needsOnboarding: boolean;
  isBlocked: boolean;
  canAccessFeature: (feature: string) => boolean;
  loading?: boolean;
  hasActiveSubscription?: boolean; // ✅ NEW
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

// ✅ NEW: Device Management Component Props
export interface DeviceManagementProps {
  deviceManagement: DeviceManagementData;
  onHibernateDevice: (deviceId: number, reason?: string) => Promise<void>;
  onWakeDevice: (deviceId: number) => Promise<void>;
  onBulkHibernate: (deviceIds: number[], reason?: string) => Promise<void>;
  onBulkWake: (deviceIds: number[]) => Promise<void>;
  loading?: boolean;
}

export interface HibernationControlsProps {
  device: Device;
  onHibernate: (reason?: string) => Promise<void>;
  onWake: () => Promise<void>;
  loading?: boolean;
  showReasonDialog?: boolean;
}

export interface UpsellBannerProps {
  upsellOptions: UpsellOption[];
  subscription: Subscription;
  onSelectOption: (option: UpsellOption) => void;
  onDismiss?: () => void;
}

// Utility types
export type SubscriptionStatus = 'active' | 'pending' | 'canceled' | 'past_due' | 'trialing';
export type PlanChangeType = 'new_subscription' | 'current' | 'upgrade' | 'downgrade_safe' | 'downgrade_warning';
export type ChangeStrategyType = 'immediate' | 'immediate_with_selection' | 'end_of_period' | 'pay_for_extra' | 'hibernate_excess';

// Error types
export interface SubscriptionError extends Error {
  code?: string;
  details?: any;
}