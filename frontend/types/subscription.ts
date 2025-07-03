// types/subscription.ts

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
  devices: Array<{
    id: number;
    name: string;
    device_type: string;
    status: string;
  }>;
}

export interface User {
  id: number;
  email: string;
  role: 'user' | 'pro' | 'admin';
  created_at: string; // ✅ FIXED: Added missing created_at field
  devices_count: number;
  subscription?: Subscription;
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
  };
}

export interface OnboardingResponse {
  status: 'success';
  message: string;
  data: {
    subscription: Subscription;
    user: User;
  };
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

// Context types
export interface SubscriptionContextType {
  subscription: Subscription | null;
  plans: Plan[];
  loading: boolean;
  error: string | null;
  
  // Actions
  fetchSubscription: () => Promise<void>;
  selectPlan: (planId: number, interval: 'month' | 'year') => Promise<void>;
  changePlan: (planId: number, interval: 'month' | 'year') => Promise<void>;
  cancelSubscription: () => Promise<void>;
  addDeviceSlot: () => Promise<void>;
  removeDeviceSlot: (deviceId: number) => Promise<void>;
  
  // Computed properties
  canAddDevice: boolean;
  deviceUsage: {
    used: number;
    limit: number;
    percentage: number;
  };
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
}

// Billing & Payment types
export interface BillingHistory {
  id: string;
  amount: number;
  currency: string;
  status: 'paid' | 'pending' | 'failed';
  description: string;
  created_at: string;
  invoice_url?: string;
}

export interface PaymentMethod {
  id: string;
  type: 'card';
  card: {
    brand: string;
    last4: string;
    exp_month: number;
    exp_year: number;
  };
  is_default: boolean;
}

// Feature flags based on plan
export const PLAN_FEATURES = {
  'Basic': {
    device_limit: 2,
    api_access: true,
    email_alerts: true,
    advanced_monitoring: false,
    priority_support: false,
    custom_integrations: false,
    data_analytics: false,
    white_label: false
  },
  'Professional': {
    device_limit: 4,
    api_access: true,
    email_alerts: true,
    advanced_monitoring: true,
    priority_support: true,
    custom_integrations: true,
    data_analytics: true,
    white_label: false
  },
  'Enterprise': {
    device_limit: Infinity,
    api_access: true,
    email_alerts: true,
    advanced_monitoring: true,
    priority_support: true,
    custom_integrations: true,
    data_analytics: true,
    white_label: true
  }
} as const;

export type PlanName = keyof typeof PLAN_FEATURES;
export type PlanFeature = keyof typeof PLAN_FEATURES[PlanName];