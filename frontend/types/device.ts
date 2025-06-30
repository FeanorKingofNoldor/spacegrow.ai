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
  status: 'ok' | 'warning' | 'error' | 'no_data';
  last_reading: number | null;
  sensor_type: SensorType;
}

export interface Device {
  id: number;
  name: string;
  status: 'pending' | 'active' | 'disabled';
  alert_status: 'normal' | 'warning' | 'error';
  device_type: string;
  last_connection: string | null;
  created_at: string;
  updated_at: string;
  sensors: DeviceSensor[];
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
    latest_readings: Record<number, SensorReading>;
    device_status: any; // Add specific type if needed
    presets: any[]; // Add specific type if needed
    profiles: any[]; // Add specific type if needed
  };
}