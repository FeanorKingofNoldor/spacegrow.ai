// User types
export interface User {
  id: number
  email: string
  role: 'user' | 'pro' | 'admin'
  created_at: string
  devices_count: number
}

// Device types
export interface Device {
  id: number
  name: string
  status: 'active' | 'pending' | 'disabled'
  alert_status: 'error' | 'warning' | 'normal' | 'no_data'
  device_type: string
  last_connection: string | null
  created_at: string
  updated_at: string
}

// API Response types
export interface AuthResponse {
  status: {
    code: number
    message: string
  }
  data: User
  token: string
}

export interface ApiResponse<T> {
  status: 'success' | 'error'
  data: T
  message?: string
}