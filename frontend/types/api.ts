// types/api.ts
// ✅ SIMPLE: Only the types you actually need right now

import { Plan, Subscription } from './subscription';

// User types
export interface User {
  id: number;
  email: string;
  display_name: string;
  timezone?: string;
  role: 'user' | 'pro' | 'admin';
  created_at: string;
  devices_count: number;
  subscription?: Subscription;
}

// Device types
export interface Device {
  id: number;
  name: string;
  status: 'active' | 'pending' | 'disabled';
  alert_status: 'error' | 'warning' | 'normal' | 'no_data';
  device_type: string;
  last_connection: string | null;
  created_at: string;
  updated_at: string;
}

// ✅ FIXED: Basic API Response types
export interface AuthResponse {
  status: {
    code: number;
    message: string;
  };
  data: User;
  token: string;
}

export interface ApiResponse<T> {
  status: 'success' | 'error';
  data: T;
  message?: string;
  errors?: string[];
}

// ✅ FIXED: Onboarding response with proper typing
export interface OnboardingResponse {
  status: 'success' | 'error';
  message: string;
  data: {
    subscription: Subscription;
    user: User;
  };
}

// Plan selection request
export interface PlanSelectionRequest {
  plan_id: number;
  interval: 'month' | 'year';
}

// Plans list response
export interface PlansResponse {
  status: 'success';
  data: {
    plans: Plan[];
  };
}