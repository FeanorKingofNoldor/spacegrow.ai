// types/device.ts - FIXED to match API response
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

export interface Device {
  id: number;
  name: string;
  status: 'pending' | 'active' | 'disabled';
  alert_status: 'normal' | 'warning' | 'error' | 'no_data';
  device_type: string;
  last_connection: string | null;
  created_at: string;
  updated_at: string;
  sensors: DeviceSensor[];
  
  // Add the missing properties from API response:
  sensor_groups?: Record<string, DeviceSensor[]>;
  latest_readings?: Record<string, number>;
  device_status?: {
    overall_status: string;
    alert_level: string;
    last_seen: string;
    connection_status: string;
  };
  presets?: any[];
  profiles?: any[];
}

export interface SensorReading {
  value: number;
  timestamp: string;
  is_valid: boolean;
  zone: 'error_low' | 'warning_low' | 'normal' | 'warning_high' | 'error_high' | 'error_out_of_range';
}

export interface DeviceDetailResponse {
  status: 'success';
  data: {
    device: Device;
    sensor_groups: Record<string, DeviceSensor[]>;
    latest_readings: Record<string, number>;
    device_status: {
      overall_status: string;
      alert_level: string;
      last_seen: string;
      connection_status: string;
    };
    presets: any[];
    profiles: any[];
  };
}