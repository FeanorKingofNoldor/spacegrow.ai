// lib/api.ts
// ✅ Fixed: Use the correct environment variable and default to Rails port 3000
const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000';

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

  async delete<T>(endpoint: string): Promise<T> {
    const url = `${this.baseURL}${endpoint}`;
    console.log('🌐 DELETE:', url);
    
    const response = await fetch(url, {
      method: 'DELETE',
      headers: this.getAuthHeaders(),
    });
    return this.handleResponse<T>(response);
  }
}

export const apiClient = new ApiClient();

// Convenience methods for common endpoints
export const api = {
  // ✅ FIXED: Direct API method access
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

  // ✅ FIXED: Preset Management API with proper endpoints
  presets: {
    // Get predefined presets by device type - FIXED URL format
    getByDeviceType: (deviceTypeId: string) => 
      apiClient.get(`/api/v1/frontend/presets/by_device_type?device_type_id=${deviceTypeId}`),
    
    // Get user's custom presets by device type - FIXED URL format  
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

  // Subscriptions
  subscriptions: {
    list: () => apiClient.get('/api/v1/frontend/subscriptions'),
    choosePlan: () => apiClient.get('/api/v1/frontend/subscriptions/choose_plan'),
    selectPlan: (plan_id: string, interval?: string) =>
      apiClient.post('/api/v1/frontend/subscriptions/select_plan', { plan_id, interval }),
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