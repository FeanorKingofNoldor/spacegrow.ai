// types/subscription.ts - PHASE 6: Complete suspended terminology replacement (COMPLETE VERSION)

import { Device, SuspensionPriority, UpsellOption } from './device';

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

// ✅ UPDATED: Subscription interface with suspended terminology
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
  
  // ✅ UPDATED: Device suspension data
  devices?: Array<{
    id: number;
    name: string;
    device_type: string;
    status: 'pending' | 'active' | 'suspended' | 'disabled';
    alert_status?: string;
    last_connection?: string;
    suspended_at?: string | null;
    suspended?: boolean;
    operational?: boolean;
    in_grace_period?: boolean;
  }>;
  
  // ✅ UPDATED: Device counts with suspension breakdown
  device_counts?: {
    total: number;
    operational: number;
    suspended: number;
    pending?: number;
    disabled?: number;
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
  display_name: string;
  timezone?: string;
  devices_count: number;
  subscription?: Subscription;
}

// ✅ UPDATED: Device Management Types with suspended terminology
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
      suspended: number;
    };
  };
  device_limits: {
    total_limit: number;
    operational_count: number;
    suspended_count: number;
    available_slots: number;
  };
  devices: {
    operational: Device[];
    suspended: Device[];
  };
  operational_devices: Device[];
  suspended_devices: Array<Device & {
    in_grace_period: boolean;
    days_until_grace_period_end?: number;
  }>;
  upsell_options: UpsellOption[];
  over_device_limit: boolean;
}

export interface DeviceManagementResponse {
  status: 'success';
  data: DeviceManagementData;
}

// ✅ UPDATED: Device usage tracking with suspended terminology
export interface DeviceUsage {
  used: number;
  limit: number;
  percentage: number;
  available: number;
  over_limit: boolean;
  operational_count: number;
  suspended_count: number;
  pending_count: number;
  disabled_count: number;
}

export interface DeviceSelectionData {
  device_id: number;
  device_name: string;
  device_type: string;
  last_connection: string | null;
  alert_status: string;
  operational: boolean;
  suspended: boolean;
  in_grace_period: boolean;
  recommendation: 'recommended_to_suspend' | 'consider_suspending' | 'keep_active';
}

// ✅ UPDATED: Plan change types with suspended terminology
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
    suspended_devices_count?: number;
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
  type: 'immediate' | 'immediate_with_selection' | 'end_of_period' | 'pay_for_extra' | 'suspend_excess';
  name: string;
  description: string;
  recommended: boolean;
  extra_monthly_cost?: number;
  devices_to_suspend?: number;
}

export interface PlanChangeRequest {
  plan_id: number;
  interval: 'month' | 'year';
  strategy: 'immediate' | 'immediate_with_selection' | 'end_of_period' | 'pay_for_extra' | 'suspend_excess';
  selected_device_ids?: number[];
  devices_to_suspend?: number[];
}

export interface PlanChangeResult {
  status: 'completed' | 'scheduled' | 'failed';
  subscription?: Subscription;
  disabled_devices?: number;
  suspended_devices?: number;
  extra_device_slots?: number;
  extra_monthly_cost?: number;
  effective_date?: string;
  scheduled_change_id?: string;
  message: string;
  suspension_summary?: {
    suspended_count: number;
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

// ✅ UPDATED: Context types with suspended methods
export interface SubscriptionContextType {
  subscription: Subscription | null;
  plans: Plan[];
  loading: boolean;
  error: string | null;
  
  // ✅ UPDATED: Device management data
  deviceManagement: DeviceManagementData | null;
  
  // Actions
  fetchSubscription: () => Promise<void>;
  selectPlan: (planId: number, interval: 'month' | 'year') => Promise<void>;
  
  // ✅ UPDATED: Device management methods with suspended terminology
  fetchDeviceManagement: () => Promise<void>;
  suspendDevice: (deviceId: number, reason?: string) => Promise<void>;
  wakeDevice: (deviceId: number) => Promise<void>;
  suspendMultipleDevices: (deviceIds: number[], reason?: string) => Promise<void>;
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
  
  // ✅ UPDATED: Suspension computed properties
  operationalDevicesCount: number;
  suspendedDevicesCount: number;
  pendingDevicesCount: number;
  disabledDevicesCount: number;
  isOverDeviceLimit: boolean;
  hasSuspendedDevices: boolean;
  devicesInGracePeriod: number;
}

// ✅ UPDATED: API Response types with suspended terminology
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
      operational: number;
      suspended: number;
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
      recommended_to_suspend?: number;
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

// ✅ UPDATED: Bulk operations with suspended terminology
export interface BulkSuspensionResponse {
  status: 'success';
  data: {
    suspended_devices: Device[];
    failed_devices: Array<{
      device_id: number;
      error: string;
    }>;
    message: string;
  };
}

export interface BulkWakeResponse {
  status: 'success';
  data: {
    woken_devices: Device[];
    failed_devices: Array<{
      device_id: number;
      error: string;
    }>;
    message: string;
  };
}

// Hook return types
export interface UseSubscriptionGuardReturn {
  hasSubscription: boolean;
  subscriptionStatus: Subscription['status'] | null;
  needsOnboarding: boolean;
  isBlocked: boolean;
  canAccessFeature: (feature: string) => boolean;
  loading?: boolean;
  hasActiveSubscription?: boolean;
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

// ✅ UPDATED: Device Management Component Props with suspended terminology
export interface DeviceManagementProps {
  deviceManagement: DeviceManagementData;
  onSuspendDevice: (deviceId: number, reason?: string) => Promise<void>;
  onWakeDevice: (deviceId: number) => Promise<void>;
  onBulkSuspend: (deviceIds: number[], reason?: string) => Promise<void>;
  onBulkWake: (deviceIds: number[]) => Promise<void>;
  loading?: boolean;
}

export interface SuspensionControlsProps {
  device: Device;
  onSuspend: (reason?: string) => Promise<void>;
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