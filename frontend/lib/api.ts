// lib/api.ts - ENHANCED with hibernation endpoints (COMPLETE MERGED VERSION)
// ✅ Fixed: Use the correct environment variable and default to Rails port 3000
const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000';

// ✅ ENHANCED: Import both subscription and device types for hibernation functionality
import { 
  Plan, 
  Subscription, 
  PlanChangePreview,
  PlanChangeRequest,
  PlanChangeResult,
  DeviceSelectionData,
  DeviceManagementData,
  DeviceManagementResponse
} from '@/types/subscription';

import {
  Device,
  HibernateDeviceRequest,
  HibernateDeviceResponse,
  WakeDeviceResponse,
  BulkHibernationRequest,
  BulkWakeRequest
} from '@/types/device';

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
        // ✅ ENHANCED: Check if this is an onboarding route to avoid redirect loops
        const isOnboardingRoute = response.url.includes('/onboarding/');
        
        if (!isOnboardingRoute && typeof window !== 'undefined') {
          // Token expired, redirect to login
          localStorage.removeItem('auth_token');
          // Also remove from cookies
          document.cookie = 'auth_token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;';
          window.location.href = '/login';
          return Promise.reject(new Error('Authentication required'));
        }
      }
      
      // ✅ ENHANCED: Better error handling for non-JSON responses
      let errorData;
      try {
        errorData = await response.json();
      } catch (jsonError) {
        errorData = { 
          error: `HTTP ${response.status}: ${response.statusText}`,
          status: { message: response.statusText }
        };
      }
      
      console.error('🚨 API Error:', errorData);
      throw new Error(errorData.status?.message || errorData.error || errorData.message || `HTTP ${response.status}`);
    }

    // ✅ ENHANCED: Handle 204 No Content responses
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
      body: data ? JSON.stringify(data) : undefined,
    });
    return this.handleResponse<T>(response);
  }
}

export const apiClient = new ApiClient();

// ✅ ENHANCED: Complete API object with hibernation endpoints
export const api = {
  // ✅ Direct API method access for flexibility
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

  // ✅ ENHANCED: Devices with hibernation support
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
    
    // ✅ NEW: Hibernation endpoints
    hibernate: (id: string, request: HibernateDeviceRequest) =>
      apiClient.post(`/api/v1/frontend/devices/${id}/hibernate`, request) as Promise<HibernateDeviceResponse>,
    
    wake: (id: string) =>
      apiClient.post(`/api/v1/frontend/devices/${id}/wake`) as Promise<WakeDeviceResponse>,
  },

  // ✅ Preset Management API
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

  // ✅ Onboarding (for new subscriptions)
  onboarding: {
    choosePlan: () => apiClient.get('/api/v1/frontend/onboarding/choose_plan'),
    selectPlan: (planId: number, interval: 'month' | 'year') =>
      apiClient.post('/api/v1/frontend/onboarding/select_plan', {
        plan_id: planId,
        interval
      }),
  },

  // ✅ ENHANCED: Subscription management with hibernation capabilities
  subscriptions: {
    // Get subscription data
    list: () => apiClient.get('/api/v1/frontend/subscriptions'),
    choosePlan: () => apiClient.get('/api/v1/frontend/subscriptions/choose_plan'),
    selectPlan: (plan_id: string, interval?: string) =>
      apiClient.post('/api/v1/frontend/subscriptions/select_plan', { plan_id, interval }),
    
    // ✅ NEW: Device management endpoint (your working endpoint!)
    deviceManagement: () =>
      apiClient.get('/api/v1/frontend/subscriptions/device_management') as Promise<DeviceManagementResponse>,
    
    // ✅ NEW: Bulk hibernation operations
    hibernateDevices: (request: BulkHibernationRequest) =>
      apiClient.post('/api/v1/frontend/subscriptions/hibernate_devices', request),
    
    wakeDevices: (request: BulkWakeRequest) =>
      apiClient.post('/api/v1/frontend/subscriptions/wake_devices', request),
    
    // Plan change workflow
    previewChange: (planId: number, interval: 'month' | 'year') =>
      apiClient.post('/api/v1/frontend/subscriptions/preview_change', {
        plan_id: planId,
        interval
      }),
    
    changePlan: (request: PlanChangeRequest) =>
      apiClient.post('/api/v1/frontend/subscriptions/change_plan', {
        plan_id: request.plan_id,
        interval: request.interval,
        strategy: request.strategy,
        selected_device_ids: request.selected_device_ids || [],
        devices_to_hibernate: request.devices_to_hibernate || []
      }),
    
    scheduleChange: (planId: number, interval: 'month' | 'year') =>
      apiClient.post('/api/v1/frontend/subscriptions/schedule_change', {
        plan_id: planId,
        interval
      }),
    
    getDevicesForSelection: () =>
      apiClient.get('/api/v1/frontend/subscriptions/devices_for_selection'),
    
    // Existing subscription management
    cancel: (id: string) => apiClient.delete(`/api/v1/frontend/subscriptions/${id}/cancel`),
    addDeviceSlot: (id: string) => apiClient.post(`/api/v1/frontend/subscriptions/${id}/add_device_slot`),
    removeDeviceSlot: (id: string, device_id: string) =>
      apiClient.delete(`/api/v1/frontend/subscriptions/${id}/remove_device_slot?device_id=${device_id}`),
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

// ✅ ENHANCED: Subscription API helper methods for hibernation
export const subscriptionAPI = {
  // Plan selection (for new subscriptions)
  selectPlan: (planId: number, interval: 'month' | 'year') =>
    api.onboarding.selectPlan(planId, interval),
  
  // ✅ NEW: Device management
  getDeviceManagement: () => api.subscriptions.deviceManagement(),
  
  // ✅ NEW: Individual device hibernation
  hibernateDevice: (deviceId: number, reason: string = 'user_choice') =>
    api.devices.hibernate(deviceId.toString(), { reason }),
  
  wakeDevice: (deviceId: number) =>
    api.devices.wake(deviceId.toString()),
  
  // ✅ NEW: Bulk hibernation operations  
  hibernateMultipleDevices: (deviceIds: number[], reason: string = 'user_choice') =>
    api.subscriptions.hibernateDevices({ device_ids: deviceIds, reason }),
  
  wakeMultipleDevices: (deviceIds: number[]) =>
    api.subscriptions.wakeDevices({ device_ids: deviceIds }),
  
  // Plan change workflow
  previewPlanChange: (planId: number, interval: 'month' | 'year') =>
    api.subscriptions.previewChange(planId, interval),
  
  changePlan: (request: PlanChangeRequest) =>
    api.subscriptions.changePlan(request),
  
  getDevicesForSelection: () =>
    api.subscriptions.getDevicesForSelection(),
  
  schedulePlanChange: (planId: number, interval: 'month' | 'year') =>
    api.subscriptions.scheduleChange(planId, interval),
  
  // Subscription management
  getSubscriptions: () => api.subscriptions.list(),
  cancelSubscription: (id: string) => api.subscriptions.cancel(id),
  addDeviceSlot: (id: string) => api.subscriptions.addDeviceSlot(id),
  removeDeviceSlot: (id: string, deviceId: string) => 
    api.subscriptions.removeDeviceSlot(id, deviceId),
};

// ✅ ENHANCED: Utility functions with hibernation support
export const subscriptionUtils = {
  calculateYearlySavings: (monthlyPrice: number, yearlyPrice: number): number => {
    return (monthlyPrice * 12) - yearlyPrice;
  },

  calculateSavingsPercentage: (monthlyPrice: number, yearlyPrice: number): number => {
    const savings = subscriptionUtils.calculateYearlySavings(monthlyPrice, yearlyPrice);
    return Math.round((savings / (monthlyPrice * 12)) * 100);
  },

  formatCurrency: (amount: number, currency: string = 'USD'): string => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency,
    }).format(amount);
  },

  daysUntil: (date: Date): number => {
    const now = new Date();
    const diffTime = date.getTime() - now.getTime();
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  },

  formatDeviceCount: (count: number): string => {
    return `${count} device${count !== 1 ? 's' : ''}`;
  },

  canAddDevices: (subscription: Subscription | null, requestedDevices: number = 1): boolean => {
    if (!subscription) return false;
    
    const currentDeviceCount = subscription.devices?.length || 0;
    const deviceLimit = subscription.device_limit || 0;
    
    return (currentDeviceCount + requestedDevices) <= deviceLimit;
  },

  // ✅ NEW: Hibernation utility functions
  getOperationalDevicesCount: (subscription: Subscription | null): number => {
    if (!subscription?.devices) return 0;
    return subscription.devices.filter(d => d.operational !== false && !d.hibernated_at).length;
  },

  getHibernatingDevicesCount: (subscription: Subscription | null): number => {
    if (!subscription?.devices) return 0;
    return subscription.devices.filter(d => d.hibernating === true || d.hibernated_at).length;
  },

  isOverDeviceLimit: (subscription: Subscription | null): boolean => {
    if (!subscription) return false;
    const operationalCount = subscriptionUtils.getOperationalDevicesCount(subscription);
    return operationalCount > subscription.device_limit;
  },

  formatHibernationReason: (reason: string | null): string => {
    if (!reason) return 'No reason provided';
    
    const reasonMap: Record<string, string> = {
      'subscription_limit': 'Over subscription limit',
      'user_choice': 'User hibernated',
      'automatic': 'Automatically hibernated',
      'grace_period_expired': 'Grace period expired',
      'payment_overdue': 'Payment overdue'
    };

    return reasonMap[reason] || reason;
  },

  calculateGracePeriodDays: (gracePeriodEndDate: string | null): number => {
    if (!gracePeriodEndDate) return 0;
    const now = new Date();
    const endDate = new Date(gracePeriodEndDate);
    const diffTime = endDate.getTime() - now.getTime();
    return Math.max(0, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));
  },

  getHibernationPriorityColor: (score: number): string => {
    if (score >= 80) return 'text-red-400';
    if (score >= 60) return 'text-orange-400';
    return 'text-green-400';
  },

  formatUpsellCost: (option: any): string => {
    if (option.cost === 0) return 'Free';
    return `$${option.cost}/${option.billing}`;
  }
};