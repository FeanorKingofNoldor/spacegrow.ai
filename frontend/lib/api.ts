// lib/api.ts - MERGED with subscription endpoints
// ✅ Fixed: Use the correct environment variable and default to Rails port 3000
const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000';

// ✅ FIXED: Import missing types
import { Plan, Subscription } from '@/types/subscription';

export interface ApiResponse<T = any> {
  status: {
    code: number;
    message: string;
  };
  data?: T;
  error?: string;
}

class ApiClient {
  private baseURL: string;

  constructor(baseURL: string = API_BASE_URL) {
    this.baseURL = baseURL;
    console.log('🌐 API Client initialized with baseURL:', baseURL); // Debug log
  }

  private getAuthHeaders(): HeadersInit {
    // ✅ Check both localStorage and cookies for token
    let token: string | null = null;
    
    if (typeof window !== 'undefined') {
      // First try localStorage
      token = localStorage.getItem('auth_token');
      
      // If not in localStorage, try cookies
      if (!token) {
        token = document.cookie
          .split('; ')
          .find(row => row.startsWith('auth_token='))
          ?.split('=')[1] || null;
      }
    }

    return {
      'Content-Type': 'application/json',
      ...(token && { Authorization: `Bearer ${token}` }),
    };
  }

  private async handleResponse<T>(response: Response): Promise<T> {
    console.log(`🌐 API Response: ${response.status} ${response.statusText} for ${response.url}`);
    
    if (!response.ok) {
      if (response.status === 401) {
        // Token expired, redirect to login
        if (typeof window !== 'undefined') {
          localStorage.removeItem('auth_token');
          // Also remove from cookies
          document.cookie = 'auth_token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;';
          window.location.href = '/login';
        }
      }
      
      // ✅ FIXED: Better error handling for non-JSON responses
      let errorData;
      try {
        errorData = await response.json();
      } catch (jsonError) {
        // If response is not JSON, create a basic error object
        errorData = { 
          error: `HTTP ${response.status}: ${response.statusText}`,
          status: { message: response.statusText }
        };
      }
      
      console.error('🚨 API Error:', errorData);
      throw new Error(errorData.status?.message || errorData.error || errorData.message || `HTTP ${response.status}`);
    }

    // ✅ FIXED: Handle empty responses (204 No Content)
    if (response.status === 204) {
      return {} as T;
    }

    try {
      return await response.json();
    } catch (jsonError) {
      console.warn('⚠️ Response is not JSON, returning empty object');
      return {} as T;
    }
  }

  async get<T>(endpoint: string): Promise<T> {
    const url = `${this.baseURL}${endpoint}`;
    console.log('🌐 GET:', url);
    
    const response = await fetch(url, {
      method: 'GET',
      headers: this.getAuthHeaders(),
    });
    return this.handleResponse<T>(response);
  }

  async post<T>(endpoint: string, data?: any): Promise<T> {
    const url = `${this.baseURL}${endpoint}`;
    console.log('🌐 POST:', url, data);
    
    const response = await fetch(url, {
      method: 'POST',
      headers: this.getAuthHeaders(),
      body: data ? JSON.stringify(data) : undefined,
    });
    return this.handleResponse<T>(response);
  }

  async put<T>(endpoint: string, data?: any): Promise<T> {
    const url = `${this.baseURL}${endpoint}`;
    console.log('🌐 PUT:', url, data);
    
    const response = await fetch(url, {
      method: 'PUT',
      headers: this.getAuthHeaders(),
      body: data ? JSON.stringify(data) : undefined,
    });
    return this.handleResponse<T>(response);
  }

  async patch<T>(endpoint: string, data?: any): Promise<T> {
    const url = `${this.baseURL}${endpoint}`;
    console.log('🌐 PATCH:', url, data);
    
    const response = await fetch(url, {
      method: 'PATCH',
      headers: this.getAuthHeaders(),
      body: data ? JSON.stringify(data) : undefined,
    });
    return this.handleResponse<T>(response);
  }

  async delete<T>(endpoint: string, data?: any): Promise<T> {
    const url = `${this.baseURL}${endpoint}`;
    console.log('🌐 DELETE:', url, data);
    
    const response = await fetch(url, {
      method: 'DELETE',
      headers: this.getAuthHeaders(),
      body: data ? JSON.stringify(data) : undefined, // ✅ FIXED: Support DELETE with body
    });
    return this.handleResponse<T>(response);
  }
}

export const apiClient = new ApiClient();

// ✅ MERGED: Complete API object with subscription endpoints
export const api = {
  // ✅ Direct API method access
  get: apiClient.get.bind(apiClient),
  post: apiClient.post.bind(apiClient),
  put: apiClient.put.bind(apiClient),
  patch: apiClient.patch.bind(apiClient),
  delete: apiClient.delete.bind(apiClient),

  // Auth
  auth: {
    login: (email: string, password: string) =>
      apiClient.post('/api/v1/auth/login', { user: { email, password } }),
    signup: (email: string, password: string, password_confirmation: string) =>
      apiClient.post('/api/v1/auth/signup', { user: { email, password, password_confirmation } }),
    logout: () => apiClient.delete('/api/v1/auth/logout'),
    me: () => apiClient.get('/api/v1/auth/me'),
    refresh: () => apiClient.post('/api/v1/auth/refresh'),
    forgotPassword: (email: string) =>
      apiClient.post('/api/v1/auth/forgot_password', { email }),
    resetPassword: (reset_password_token: string, password: string, password_confirmation: string) =>
      apiClient.put('/api/v1/auth/reset_password', { reset_password_token, password, password_confirmation }),
  },

  // Dashboard
  dashboard: {
    overview: () => apiClient.get('/api/v1/frontend/dashboard'),
    devices: () => apiClient.get('/api/v1/frontend/dashboard/devices'),
    device: (id: string) => apiClient.get(`/api/v1/frontend/dashboard/device/${id}`),
  },

  // Devices
  devices: {
    list: () => apiClient.get('/api/v1/frontend/devices'),
    get: (id: string) => apiClient.get(`/api/v1/frontend/devices/${id}`),
    create: (data: any) => apiClient.post('/api/v1/frontend/devices', { device: data }),
    update: (id: string, data: any) => apiClient.put(`/api/v1/frontend/devices/${id}`, { device: data }),
    delete: (id: string) => apiClient.delete(`/api/v1/frontend/devices/${id}`),
    updateStatus: (id: string, status: string) =>
      apiClient.patch(`/api/v1/frontend/devices/${id}/update_status`, { device: { status } }),
    sendCommand: (id: string, command: string, args?: any) =>
      apiClient.post(`/api/v1/frontend/devices/${id}/commands`, { command, args }),
  },

  // Presets
  presets: {
    // Get predefined presets by device type
    getByDeviceType: (deviceTypeId: string) => 
      apiClient.get(`/api/v1/frontend/presets/by_device_type?device_type_id=${deviceTypeId}`),
    
    // Get user's custom presets by device type
    getUserPresets: (deviceTypeId: string) => 
      apiClient.get(`/api/v1/frontend/presets/user_by_device_type?device_type_id=${deviceTypeId}`),
    
    // Preset CRUD operations
    get: (id: number) => 
      apiClient.get(`/api/v1/frontend/presets/${id}`),
    
    create: (data: { name: string; device_id: number; settings: any }) => 
      apiClient.post('/api/v1/frontend/presets', { preset: data }),
    
    update: (id: number, data: { name?: string; settings?: any }) => 
      apiClient.put(`/api/v1/frontend/presets/${id}`, { preset: data }),
    
    delete: (id: number) => 
      apiClient.delete(`/api/v1/frontend/presets/${id}`),
    
    // Apply preset to device (sends WebSocket command)
    apply: (deviceId: number, presetId: number) => 
      apiClient.post(`/api/v1/frontend/devices/${deviceId}/commands`, { 
        command: 'apply_preset', 
        args: { preset_id: presetId } 
      }),
    
    // Validate preset settings
    validate: (settings: any, deviceTypeId: string) => 
      apiClient.post('/api/v1/frontend/presets/validate', { 
        settings, 
        device_type_id: deviceTypeId 
      }),
  },

  // ✅ NEW: Onboarding endpoints
  onboarding: {
    choosePlan: () => apiClient.get('/api/v1/frontend/onboarding/choose_plan'),
    selectPlan: (planId: number, interval: 'month' | 'year') =>
      apiClient.post('/api/v1/frontend/onboarding/select_plan', {
        plan_id: planId,
        interval
      }),
  },

  // ✅ ENHANCED: Subscription management (merged with existing + new endpoints)
  subscriptions: {
    list: () => apiClient.get('/api/v1/frontend/subscriptions'),
    choosePlan: () => apiClient.get('/api/v1/frontend/subscriptions/choose_plan'),
    selectPlan: (planId: number, interval: 'month' | 'year') =>
      apiClient.post('/api/v1/frontend/subscriptions/select_plan', { 
        plan_id: planId, 
        interval 
      }),
    cancel: () => apiClient.delete('/api/v1/frontend/subscriptions/cancel'),
    addDeviceSlot: () => apiClient.post('/api/v1/frontend/subscriptions/add_device_slot'),
    removeDeviceSlot: (deviceId: number) =>
      apiClient.delete('/api/v1/frontend/subscriptions/remove_device_slot', {
        device_id: deviceId
      }),
    
    // ✅ NEW: Additional subscription endpoints
    current: () => apiClient.get('/api/v1/frontend/subscriptions/current'),
    usage: () => apiClient.get('/api/v1/frontend/subscriptions/usage'),
    preview: (planId: number, interval: 'month' | 'year') =>
      apiClient.post('/api/v1/frontend/subscriptions/preview', {
        plan_id: planId,
        interval
      }),
  },

  // ✅ NEW: Billing endpoints
  billing: {
    history: () => apiClient.get('/api/v1/frontend/billing/history'),
    paymentMethods: () => apiClient.get('/api/v1/frontend/billing/payment_methods'),
    addPaymentMethod: (paymentMethodId: string) =>
      apiClient.post('/api/v1/frontend/billing/payment_methods', {
        payment_method_id: paymentMethodId
      }),
    setDefaultPaymentMethod: (paymentMethodId: string) =>
      apiClient.put('/api/v1/frontend/billing/payment_methods/default', {
        payment_method_id: paymentMethodId
      }),
    removePaymentMethod: (paymentMethodId: string) =>
      apiClient.delete(`/api/v1/frontend/billing/payment_methods/${paymentMethodId}`),
    downloadInvoice: (invoiceId: string) =>
      apiClient.get(`/api/v1/frontend/billing/invoices/${invoiceId}/download`),
    updateBillingAddress: (address: any) =>
      apiClient.put('/api/v1/frontend/billing/address', { address }),
  },

  // ✅ NEW: Stripe integration
  stripe: {
    createCheckoutSession: (planId: number, interval: 'month' | 'year') =>
      apiClient.post('/api/v1/frontend/stripe/create_checkout_session', {
        plan_id: planId,
        interval
      }),
    createSetupIntent: () => apiClient.post('/api/v1/frontend/stripe/create_setup_intent'),
    createPortalSession: () => apiClient.post('/api/v1/frontend/stripe/create_portal_session'),
    confirmPayment: (paymentIntentId: string) =>
      apiClient.post('/api/v1/frontend/stripe/confirm_payment', {
        payment_intent_id: paymentIntentId
      }),
  },

  // Shop
  shop: {
    products: () => apiClient.get('/api/v1/store/products'),
    featuredProducts: () => apiClient.get('/api/v1/store/products/featured'),
    product: (id: string) => apiClient.get(`/api/v1/store/products/${id}`),
    checkStock: (id: string) => apiClient.get(`/api/v1/store/products/${id}/check_stock`),
  },

  // Chart Data
  chartData: {
    latest: () => apiClient.get('/api/v1/chart_data/latest'),
  },
};

// ✅ FIXED: Add missing type definitions for API responses
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

// ✅ NEW: API Response types for dashboard and devices
export interface DevicesApiResponse {
  status: 'success';
  data: Array<{
    id: number;
    name: string;
    status: 'active' | 'pending' | 'disabled';
    alert_status: 'normal' | 'warning' | 'error' | 'no_data';
    device_type: string;
    last_connection: string | null;
    created_at: string;
    updated_at: string;
  }>;
}

export interface DashboardStatsApiResponse {
  status: 'success';
  data: {
    total_devices: number;
    active_devices: number;
    warning_devices: number;
    offline_devices: number;
    system_health: 'healthy' | 'warning' | 'critical';
    alerts_count: number;
    recent_activity: Array<{
      id: string;
      type: string;
      message: string;
      timestamp: string;
    }>;
  };
}

// Hook for subscription API calls
import { useState, useCallback } from 'react';

export function useSubscriptionAPI() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const execute = useCallback(async <T>(apiCall: () => Promise<T>): Promise<T | null> => {
    setLoading(true);
    setError(null);

    try {
      const result = await apiCall();
      return result;
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'An error occurred';
      setError(errorMessage);
      console.error('Subscription API error:', err);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  return { loading, error, execute };
}

// Utility functions for subscription management
export const subscriptionUtils = {
  // Calculate savings for yearly billing
  calculateYearlySavings: (monthlyPrice: number, yearlyPrice: number): number => {
    return (monthlyPrice * 12) - yearlyPrice;
  },

  // Calculate savings percentage
  calculateSavingsPercentage: (monthlyPrice: number, yearlyPrice: number): number => {
    const savings = subscriptionUtils.calculateYearlySavings(monthlyPrice, yearlyPrice);
    return Math.round((savings / (monthlyPrice * 12)) * 100);
  },

  // Format currency
  formatCurrency: (amount: number, currency: string = 'USD'): string => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency,
    }).format(amount);
  },

  // Calculate days until date
  daysUntil: (date: Date): number => {
    const now = new Date();
    const diffTime = date.getTime() - now.getTime();
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  },

  // Check if subscription is in grace period
  isInGracePeriod: (subscription: Subscription): boolean => {
    if (subscription.status !== 'past_due') return false;
    const gracePeriodDays = 7; // Adjust based on your business logic
    const pastDueDays = subscriptionUtils.daysUntil(new Date(subscription.current_period_end));
    return pastDueDays >= -gracePeriodDays;
  },

  // Get subscription health status
  getSubscriptionHealth: (subscription: Subscription | null): 'healthy' | 'warning' | 'critical' => {
    if (!subscription) return 'critical';
    
    switch (subscription.status) {
      case 'active':
        return 'healthy';
      case 'past_due':
        return subscriptionUtils.isInGracePeriod(subscription) ? 'warning' : 'critical';
      case 'canceled':
        return 'critical';
      case 'pending':
        return 'warning';
      default:
        return 'critical';
    }
  },

  // Format plan interval for display
  formatInterval: (interval: string): string => {
    return interval === 'month' ? 'Monthly' : 'Yearly';
  },

  // Get plan upgrade suggestions
  getUpgradeSuggestions: (currentPlan: Plan, allPlans: Plan[], deviceCount: number): Plan[] => {
    if (!currentPlan || !allPlans) return [];
    
    return allPlans.filter(plan => 
      plan.id !== currentPlan.id && 
      plan.device_limit > currentPlan.device_limit &&
      (deviceCount >= currentPlan.device_limit * 0.8) // Suggest upgrade when 80% capacity
    );
  },

  // Calculate total monthly cost including device slots
  calculateTotalMonthlyCost: (subscription: Subscription): number => {
    if (!subscription) return 0;
    
    const baseCost = subscription.interval === 'month' 
      ? subscription.plan.monthly_price 
      : subscription.plan.yearly_price / 12;
    
    const additionalDeviceCost = subscription.additional_device_slots * 5; // $5 per additional device
    
    return baseCost + additionalDeviceCost;
  },

  // Get feature availability
  hasFeature: (subscription: Subscription | null, feature: string): boolean => {
    if (!subscription) return false;
    
    const planFeatures: Record<string, string[]> = {
      'Basic': ['basic_monitoring', 'email_alerts', 'api_access', 'standard_support'],
      'Professional': [
        'basic_monitoring', 
        'email_alerts', 
        'api_access', 
        'standard_support',
        'advanced_monitoring',
        'priority_support',
        'custom_integrations',
        'data_analytics'
      ],
      'Enterprise': [
        'basic_monitoring', 
        'email_alerts', 
        'api_access', 
        'standard_support',
        'advanced_monitoring',
        'priority_support',
        'custom_integrations',
        'data_analytics',
        'white_label',
        'unlimited_devices'
      ]
    };
    
    return planFeatures[subscription.plan.name]?.includes(feature) || false;
  },

  // Validate device limits
  canAddDevices: (subscription: Subscription | null, requestedDevices: number = 1): boolean => {
    if (!subscription) return false;
    
    const currentDeviceCount = subscription.devices?.length || 0;
    const deviceLimit = subscription.device_limit || 0;
    
    return (currentDeviceCount + requestedDevices) <= deviceLimit;
  },

  // Get device limit warnings
  getDeviceLimitWarning: (subscription: Subscription | null): string | null => {
    if (!subscription) return null;
    
    const deviceCount = subscription.devices?.length || 0;
    const deviceLimit = subscription.device_limit || 0;
    const usagePercentage = (deviceCount / deviceLimit) * 100;
    
    if (usagePercentage >= 100) {
      return 'Device limit reached. Upgrade your plan or add device slots to connect more devices.';
    } else if (usagePercentage >= 80) {
      return `You're using ${deviceCount} of ${deviceLimit} device slots. Consider upgrading for more capacity.`;
    }
    
    return null;
  }
};

// Types for API responses
export interface SubscriptionAPIResponse<T = any> {
  status: 'success' | 'error';
  data?: T;
  message?: string;
  errors?: string[];
}

export interface PlansAPIResponse extends SubscriptionAPIResponse {
  data: {
    plans: Plan[];
  };
}

export interface SubscriptionDetailAPIResponse extends SubscriptionAPIResponse {
  data: {
    current_subscription: Subscription | null;
    plans: Plan[];
  };
}

export interface BillingHistoryAPIResponse extends SubscriptionAPIResponse {
  data: {
    invoices: BillingHistory[];
    total_count: number;
    current_page: number;
    per_page: number;
  };
}

export interface PaymentMethodsAPIResponse extends SubscriptionAPIResponse {
  data: {
    payment_methods: PaymentMethod[];
    default_payment_method_id: string | null;
  };
}

export interface StripeCheckoutSessionAPIResponse extends SubscriptionAPIResponse {
  data: {
    checkout_url: string;
    session_id: string;
  };
}

export interface StripePortalSessionAPIResponse extends SubscriptionAPIResponse {
  data: {
    portal_url: string;
  };
}