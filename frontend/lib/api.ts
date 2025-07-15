// lib/api.ts - PHASE 6: Complete suspended terminology replacement (FULL VERSION)
// ✅ Fixed: Use the correct environment variable and default to Rails port 3000
const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000';

// ✅ ENHANCED: Import both subscription and device types for suspension functionality
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
  SuspendDeviceRequest,
  SuspendDeviceResponse,
  WakeDeviceResponse,
  BulkSuspensionRequest,
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

export interface UserSession {
  jti: string;
  device_type: string;
  ip_address: string;
  last_active: string;
  created_at: string;
  is_current: boolean;
}

export interface SessionsResponse {
  status: {
    code: number;
    message: string;
  };
  data: {
    sessions: UserSession[];
    total_count: number;
    session_limit: number;
  };
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

// ✅ ENHANCED: Complete API object with suspension endpoints
export const api = {
  // ✅ Direct API method access for flexibility
  get: apiClient.get.bind(apiClient),
  post: apiClient.post.bind(apiClient),
  put: apiClient.put.bind(apiClient),
  patch: apiClient.patch.bind(apiClient),
  delete: apiClient.delete.bind(apiClient),

  // ✅ UPDATED: Auth with display_name support
  auth: {
    login: (email: string, password: string) =>
      apiClient.post('/api/v1/auth/login', { user: { email, password } }),
    
    // ✅ UPDATED: Include display_name in signup
    signup: (email: string, password: string, password_confirmation: string, display_name?: string) =>
      apiClient.post('/api/v1/auth/signup', { 
        user: { email, password, password_confirmation, display_name } 
      }),
    
    logout: () => apiClient.delete('/api/v1/auth/logout'),
    me: () => apiClient.get('/api/v1/auth/me'),
    refresh: () => apiClient.post('/api/v1/auth/refresh'),
    
    // ✅ NEW: Profile update method
    updateProfile: (updates: { display_name?: string; timezone?: string }) =>
      apiClient.patch('/api/v1/auth/update_profile', { user: updates }),
    
    forgotPassword: (email: string) =>
      apiClient.post('/api/v1/auth/forgot_password', { email }),
    resetPassword: (reset_password_token: string, password: string, password_confirmation: string) =>
      apiClient.put('/api/v1/auth/reset_password', { reset_password_token, password, password_confirmation }),

    changePassword: (currentPassword: string, newPassword: string, confirmPassword: string) =>
      apiClient.patch('/api/v1/auth/change_password', { 
        user: {
          current_password: currentPassword,
          password: newPassword,
          password_confirmation: confirmPassword
        }
      }),

    getSessions: (): Promise<SessionsResponse> =>
      apiClient.get('/api/v1/auth/sessions'),
    
    logoutSession: (jti: string) =>
      apiClient.delete(`/api/v1/auth/sessions/${jti}`),
    
    logoutAllSessions: () =>
      apiClient.delete('/api/v1/auth/sessions/logout_all'),
  },

  // ✅ NEW: Onboarding endpoints
  onboarding: {
    getPlans: () => apiClient.get('/api/v1/onboarding/plans'),
    selectPlan: (planId: number, interval: 'month' | 'year') =>
      apiClient.post('/api/v1/onboarding/select_plan', { plan_id: planId, interval }),
    completeOnboarding: () => apiClient.post('/api/v1/onboarding/complete', {}),
    skipOnboarding: () => apiClient.post('/api/v1/onboarding/skip', {}),
  },

  // Dashboard
  dashboard: {
    overview: () => apiClient.get('/api/v1/frontend/dashboard'),
    devices: () => apiClient.get('/api/v1/frontend/dashboard/devices'),
    device: (id: string) => apiClient.get(`/api/v1/frontend/dashboard/device/${id}`),
  },

  // ✅ UPDATED: Devices with suspension support
  devices: {
    list: () => apiClient.get('/api/v1/frontend/devices'),
    get: (id: string) => apiClient.get(`/api/v1/frontend/devices/${id}`),
    create: (data: any) => apiClient.post('/api/v1/frontend/devices', { device: data }),
    update: (id: string, data: any) => apiClient.put(`/api/v1/frontend/devices/${id}`, { device: data }),
    delete: (id: string) => apiClient.delete(`/api/v1/frontend/devices/${id}`),
    updateStatus: (id: string, status: string) =>
      apiClient.patch(`/api/v1/frontend/devices/${id}/update_status`, { device: { status } }),
    
    // ✅ UPDATED: Suspension methods (renamed from suspend)
    suspend: (id: string, request: SuspendDeviceRequest): Promise<SuspendDeviceResponse> =>
      apiClient.post(`/api/v1/frontend/devices/${id}/suspend`, request),
    
    wake: (id: string): Promise<WakeDeviceResponse> =>
      apiClient.post(`/api/v1/frontend/devices/${id}/wake`, {}),
    
    sendCommand: (id: string, command: string, args?: Record<string, any>) =>
      apiClient.post(`/api/v1/frontend/devices/${id}/command`, { command, args }),
    
    getReadings: (id: string, timeframe?: string) =>
      apiClient.get(`/api/v1/frontend/devices/${id}/readings${timeframe ? `?timeframe=${timeframe}` : ''}`),
    
    getAlerts: (id: string) =>
      apiClient.get(`/api/v1/frontend/devices/${id}/alerts`),
    
    updatePreset: (id: string, presetData: any) =>
      apiClient.put(`/api/v1/frontend/devices/${id}/preset`, { preset: presetData }),
    
    getPresets: (id: string) =>
      apiClient.get(`/api/v1/frontend/devices/${id}/presets`),
  },

  // ✅ UPDATED: Subscriptions with suspension terminology
  subscriptions: {
    list: () => apiClient.get('/api/v1/frontend/subscriptions'),
    current: () => apiClient.get('/api/v1/frontend/subscriptions/current'),
    cancel: () => apiClient.post('/api/v1/frontend/subscriptions/cancel', {}),
    addDeviceSlot: () => apiClient.post('/api/v1/frontend/subscriptions/add_device_slot', {}),
    removeDeviceSlot: (deviceId: number) =>
      apiClient.delete(`/api/v1/frontend/subscriptions/remove_device_slot/${deviceId}`),
    
    // ✅ UPDATED: Device management with suspension terminology
    deviceManagement: (): Promise<DeviceManagementResponse> => 
      apiClient.get('/api/v1/frontend/subscriptions/device_management'),
    
    suspendDevices: (request: BulkSuspensionRequest) =>
      apiClient.post('/api/v1/frontend/subscriptions/suspend_devices', request),
    
    wakeDevices: (request: BulkWakeRequest) =>
      apiClient.post('/api/v1/frontend/subscriptions/wake_devices', request),
    
    activateDevice: (deviceId: number) =>
      apiClient.post('/api/v1/frontend/subscriptions/activate_device', { device_id: deviceId }),
    
    // Plan management
    getPlans: () => apiClient.get('/api/v1/frontend/subscriptions/plans'),
    previewPlanChange: (planId: number, interval: 'month' | 'year') =>
      apiClient.post('/api/v1/frontend/subscriptions/preview_plan_change', { plan_id: planId, interval }),
    changePlan: (request: PlanChangeRequest) =>
      apiClient.post('/api/v1/frontend/subscriptions/change_plan', request),
    getDevicesForSelection: () =>
      apiClient.get('/api/v1/frontend/subscriptions/devices_for_selection'),
    schedulePlanChange: (planId: number, interval: 'month' | 'year') =>
      apiClient.post('/api/v1/frontend/subscriptions/schedule_plan_change', { plan_id: planId, interval }),
  },

  // Billing
  billing: {
    getInvoices: () => apiClient.get('/api/v1/frontend/billing/invoices'),
    getInvoice: (id: string) => apiClient.get(`/api/v1/frontend/billing/invoices/${id}`),
    downloadInvoice: (id: string) => apiClient.get(`/api/v1/frontend/billing/invoices/${id}/download`),
    getPaymentMethods: () => apiClient.get('/api/v1/frontend/billing/payment_methods'),
    addPaymentMethod: (data: any) => apiClient.post('/api/v1/frontend/billing/payment_methods', data),
    removePaymentMethod: (id: string) => apiClient.delete(`/api/v1/frontend/billing/payment_methods/${id}`),
    setDefaultPaymentMethod: (id: string) => apiClient.patch(`/api/v1/frontend/billing/payment_methods/${id}/set_default`, {}),
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

  // Admin endpoints
  admin: {
    getUsers: () => apiClient.get('/api/v1/admin/users'),
    getUser: (id: string) => apiClient.get(`/api/v1/admin/users/${id}`),
    updateUser: (id: string, data: any) => apiClient.put(`/api/v1/admin/users/${id}`, data),
    deleteUser: (id: string) => apiClient.delete(`/api/v1/admin/users/${id}`),
    
    // ✅ UPDATED: Admin device management with suspension terminology
    getAllDevices: () => apiClient.get('/api/v1/admin/devices'),
    suspendUserDevices: (userId: string, deviceIds: number[], reason: string) =>
      apiClient.post(`/api/v1/admin/users/${userId}/suspend_devices`, { 
        device_ids: deviceIds, 
        reason 
      }),
    
    wakeUserDevices: (userId: string, deviceIds: number[]) =>
      apiClient.post(`/api/v1/admin/users/${userId}/wake_devices`, { 
        device_ids: deviceIds 
      }),
    
    getSubscriptions: () => apiClient.get('/api/v1/admin/subscriptions'),
    updateSubscription: (id: string, data: any) => apiClient.put(`/api/v1/admin/subscriptions/${id}`, data),
  },

  // Health check
  health: {
    check: () => apiClient.get('/api/v1/health'),
    database: () => apiClient.get('/api/v1/health/database'),
    redis: () => apiClient.get('/api/v1/health/redis'),
  },
};

// ✅ UPDATED: Subscription API helper methods for suspension
export const subscriptionAPI = {
  // Plan selection (for new subscriptions)
  selectPlan: (planId: number, interval: 'month' | 'year') =>
    api.onboarding.selectPlan(planId, interval),
  
  // ✅ UPDATED: Device management
  getDeviceManagement: () => api.subscriptions.deviceManagement(),
  
  // ✅ UPDATED: Individual device suspension
  suspendDevice: (deviceId: number, reason: string = 'user_choice') =>
    api.devices.suspend(deviceId.toString(), { reason }),
  
  wakeDevice: (deviceId: number) =>
    api.devices.wake(deviceId.toString()),
  
  // ✅ UPDATED: Bulk suspension operations  
  suspendMultipleDevices: (deviceIds: number[], reason: string = 'user_choice') =>
    api.subscriptions.suspendDevices({ device_ids: deviceIds, reason }),
  
  wakeMultipleDevices: (deviceIds: number[]) =>
    api.subscriptions.wakeDevices({ device_ids: deviceIds }),
  
  // Plan change workflow
  previewPlanChange: (planId: number, interval: 'month' | 'year') =>
    api.subscriptions.previewPlanChange(planId, interval),
  
  changePlan: (request: PlanChangeRequest) =>
    api.subscriptions.changePlan(request),
  
  getDevicesForSelection: () =>
    api.subscriptions.getDevicesForSelection(),
};

export default api;