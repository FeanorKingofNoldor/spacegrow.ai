// types/device.ts
export interface SensorType {
  id: number;
  name: string;
  unit: string;
  min_value: number;
  max_value: number;
  error_low_min: number;
  error_low_max: number;
  warning_low_min: number;
  warning_low_max: number;
  normal_min: number;
  normal_max: number;
  warning_high_min: number;
  warning_high_max: number;
  error_high_min: number;
  error_high_max: number;
}

export interface DeviceSensor {
  id: number;
  type: string;
  status: 'ok' | 'warning' | 'error' | 'no_data' | 'warning_high' | 'warning_low' | 'error_high' | 'error_low';
  last_reading: number | null;
  sensor_type: SensorType;
}

export interface SensorReading {
  id?: string;
  value: number;
  timestamp: string;
  zone: 'normal' | 'warning_low' | 'warning_high' | 'error_low' | 'error_high' | 'error_out_of_range';
  is_valid: boolean;
}

export interface DeviceStatus {
  overall_status: string;
  alert_level: string;
  last_seen: string | null;
  connection_status: 'online' | 'offline';
}

export interface Preset {
  id: string;
  name: string;
  settings: Record<string, any>;
  is_user_defined: boolean;
  user_id?: string;
  device_id?: string;
}

export interface Device {
  id: number;
  name: string;
  status: 'active' | 'pending' | 'disabled';
  alert_status: 'normal' | 'warning' | 'error' | 'no_data';
  device_type: string;
  last_connection: string | null;
  created_at: string;
  updated_at: string;
  sensors?: DeviceSensor[];
  
  // Optional properties from detailed API responses
  sensor_groups?: Record<string, DeviceSensor[]>;
  latest_readings?: Record<string, number | SensorReading>;
  device_status?: DeviceStatus;
  presets?: Preset[];
  profiles?: Preset[];
}

// Extended device interface for detailed views (backwards compatibility)
export interface DeviceDetail extends Device {
  sensors: DeviceSensor[];
  latest_readings: Record<string, SensorReading>;
  device_status: DeviceStatus;
  presets: Preset[];
  profiles: Preset[];
}

// API Response types
export interface DeviceDetailResponse {
  status: 'success';
  data: {
    device: Device;
    sensor_groups: Record<string, DeviceSensor[]>;
    latest_readings: Record<string, number>;
    device_status: DeviceStatus;
    presets: Preset[];
    profiles: Preset[];
  };
}

// WebSocket message types for device updates
export interface DeviceStatusUpdate {
  device_id: string | number;
  alert_status?: 'normal' | 'warning' | 'error' | 'no_data';
  status?: 'active' | 'pending' | 'disabled';
  last_connection?: string;
  status_class?: string; // Pre-calculated CSS classes from backend
}

export interface SensorStatusUpdate {
  device_id: string | number;
  status: string;
  alert_status: 'normal' | 'warning' | 'error' | 'no_data';
  sensors: Array<{
    sensor_id: string | number;
    status: 'ok' | 'warning' | 'error' | 'no_data' | 'warning_high' | 'warning_low' | 'error_high' | 'error_low';
  }>;
}

export interface DashboardUpdate {
  devices?: DeviceStatusUpdate[];
  stats?: {
    total: number;
    active: number;
    warning: number;
    error: number;
  };
}

// Utility types for type safety
export type AlertStatus = 'normal' | 'warning' | 'error' | 'no_data';
export type DeviceConnectionStatus = 'active' | 'pending' | 'disabled';
export type SensorStatus = 'ok' | 'warning' | 'error' | 'no_data' | 'warning_high' | 'warning_low' | 'error_high' | 'error_low';
export type SensorZone = 'normal' | 'warning_low' | 'warning_high' | 'error_low' | 'error_high' | 'error_out_of_range';
export type ConnectionStatus = 'online' | 'offline';