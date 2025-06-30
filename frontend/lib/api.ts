// lib/api.ts
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

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
  }

  private getAuthHeaders(): HeadersInit {
    const token = typeof window !== 'undefined' ? localStorage.getItem('auth_token') : null;
    return {
      'Content-Type': 'application/json',
      ...(token && { Authorization: `Bearer ${token}` }),
    };
  }

  private async handleResponse<T>(response: Response): Promise<T> {
    if (!response.ok) {
      if (response.status === 401) {
        // Token expired, redirect to login
        if (typeof window !== 'undefined') {
          localStorage.removeItem('auth_token');
          window.location.href = '/login';
        }
      }
      
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.status?.message || errorData.error || `HTTP ${response.status}`);
    }

    return response.json();
  }

  async get<T>(endpoint: string): Promise<T> {
    const response = await fetch(`${this.baseURL}${endpoint}`, {
      method: 'GET',
      headers: this.getAuthHeaders(),
    });
    return this.handleResponse<T>(response);
  }

  async post<T>(endpoint: string, data?: any): Promise<T> {
    const response = await fetch(`${this.baseURL}${endpoint}`, {
      method: 'POST',
      headers: this.getAuthHeaders(),
      body: data ? JSON.stringify(data) : undefined,
    });
    return this.handleResponse<T>(response);
  }

  async put<T>(endpoint: string, data?: any): Promise<T> {
    const response = await fetch(`${this.baseURL}${endpoint}`, {
      method: 'PUT',
      headers: this.getAuthHeaders(),
      body: data ? JSON.stringify(data) : undefined,
    });
    return this.handleResponse<T>(response);
  }

  async patch<T>(endpoint: string, data?: any): Promise<T> {
    const response = await fetch(`${this.baseURL}${endpoint}`, {
      method: 'PATCH',
      headers: this.getAuthHeaders(),
      body: data ? JSON.stringify(data) : undefined,
    });
    return this.handleResponse<T>(response);
  }

  async delete<T>(endpoint: string): Promise<T> {
    const response = await fetch(`${this.baseURL}${endpoint}`, {
      method: 'DELETE',
      headers: this.getAuthHeaders(),
    });
    return this.handleResponse<T>(response);
  }
}

export const apiClient = new ApiClient();

// Convenience methods for common endpoints
export const api = {
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
};