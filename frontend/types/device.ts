// types/device.ts - ENHANCED with hibernation support
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

// ✅ NEW: Hibernation-related interfaces
export interface HibernationPriority {
  device_id: number;
  device_name: string;
  score: number;
  last_connection: string | null;
  created_at: string;
  alert_status: string;
  priority_reason?: string;
  recommendation?: 'recommended_to_hibernate' | 'consider_hibernating' | 'keep_active';
}

export interface UpsellOption {
  type: 'add_slots' | 'upgrade_plan' | 'manage_devices';
  title: string;
  description: string;
  cost: number;
  billing: string;
  action: string;
  devices_count?: number;
  savings?: number;
}

export interface DeviceManagementData {
  subscription: {
    id: number;
    plan: {
      id: number;
      name: string;
      device_limit: number;
    };
    status: string;
    device_limit: number;
    additional_device_slots: number;
    device_counts: {
      total: number;
      operational: number;
      hibernating: number;
    };
  };
  device_limits: {
    total_limit: number;
    operational_count: number;
    hibernating_count: number;
    available_slots: number;
  };
  devices: {
    operational: Device[];
    hibernating: Device[];
  };
  hibernation_priorities: HibernationPriority[];
  upsell_options: UpsellOption[];
  over_device_limit: boolean;
}

// ✅ ENHANCED: Device interface with hibernation fields
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
  
  // ✅ NEW: Hibernation fields
  hibernated_at: string | null;
  hibernated_reason: string | null;
  grace_period_ends_at: string | null;
  
  // ✅ NEW: Computed hibernation properties
  operational?: boolean;
  hibernating?: boolean;
  in_grace_period?: boolean;
  hibernation_priority_score?: number;
  
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

// ✅ NEW: Device hibernation action interfaces
export interface HibernateDeviceRequest {
  reason: string;
  grace_period_days?: number;
}

export interface HibernateDeviceResponse {
  status: 'success';
  message: string;
  data: {
    device: Device;
    hibernated_at: string;
    grace_period_ends_at: string;
  };
}

export interface WakeDeviceResponse {
  status: 'success';
  message: string;
  data: {
    device: Device;
  };
}

export interface BulkHibernationRequest {
  device_ids: number[];
  reason: string;
}

export interface BulkWakeRequest {
  device_ids: number[];
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

export interface DeviceManagementResponse {
  status: 'success';
  data: DeviceManagementData;
}

// WebSocket message types for device updates
export interface DeviceStatusUpdate {
  device_id: string | number;
  alert_status?: 'normal' | 'warning' | 'error' | 'no_data';
  status?: 'active' | 'pending' | 'disabled';
  last_connection?: string;
  status_class?: string;
  
  // ✅ NEW: Hibernation status updates
  hibernated_at?: string | null;
  hibernated_reason?: string | null;
  grace_period_ends_at?: string | null;
  operational?: boolean;
  hibernating?: boolean;
  in_grace_period?: boolean;
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
    operational?: number;
    hibernating?: number;
  };
}

// ✅ NEW: Hibernation utility functions
export const deviceUtils = {
  isHibernating: (device: Device): boolean => {
    return !!device.hibernated_at;
  },

  isOperational: (device: Device): boolean => {
    return device.status === 'active' && !device.hibernated_at;
  },

  isInGracePeriod: (device: Device): boolean => {
    if (!device.hibernated_at || !device.grace_period_ends_at) return false;
    return new Date(device.grace_period_ends_at) > new Date();
  },

  getHibernationStatus: (device: Device): 'operational' | 'hibernating' | 'grace_period' => {
    if (!device.hibernated_at) return 'operational';
    if (deviceUtils.isInGracePeriod(device)) return 'grace_period';
    return 'hibernating';
  },

  getHibernationDisplayText: (device: Device): string => {
    const status = deviceUtils.getHibernationStatus(device);
    switch (status) {
      case 'operational': return 'Operational';
      case 'grace_period': return 'Grace Period';
      case 'hibernating': return 'Hibernating';
      default: return 'Unknown';
    }
  },

  getHibernationColor: (device: Device): string => {
    const status = deviceUtils.getHibernationStatus(device);
    switch (status) {
      case 'operational': return 'text-green-400 bg-green-500/20';
      case 'grace_period': return 'text-orange-400 bg-orange-500/20';
      case 'hibernating': return 'text-blue-400 bg-blue-500/20';
      default: return 'text-gray-400 bg-gray-500/20';
    }
  },

  getDaysUntilGracePeriodEnd: (device: Device): number => {
    if (!device.grace_period_ends_at) return 0;
    const now = new Date();
    const endDate = new Date(device.grace_period_ends_at);
    const diffTime = endDate.getTime() - now.getTime();
    return Math.max(0, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));
  },

  canWakeDevice: (device: Device): boolean => {
    return deviceUtils.isHibernating(device);
  },

  canHibernateDevice: (device: Device): boolean => {
    return deviceUtils.isOperational(device);
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

  getPriorityRecommendation: (priority: HibernationPriority): {
    color: string;
    text: string;
    icon: string;
  } => {
    if (priority.score >= 80) {
      return {
        color: 'text-red-400',
        text: 'Recommended to hibernate',
        icon: '🔴'
      };
    } else if (priority.score >= 60) {
      return {
        color: 'text-orange-400',
        text: 'Consider hibernating',
        icon: '🟠'
      };
    } else {
      return {
        color: 'text-green-400',
        text: 'Keep active',
        icon: '🟢'
      };
    }
  }
};

// Utility types for type safety
export type AlertStatus = 'normal' | 'warning' | 'error' | 'no_data';
export type DeviceConnectionStatus = 'active' | 'pending' | 'disabled';
export type SensorStatus = 'ok' | 'warning' | 'error' | 'no_data' | 'warning_high' | 'warning_low' | 'error_high' | 'error_low';
export type SensorZone = 'normal' | 'warning_low' | 'warning_high' | 'error_low' | 'error_high' | 'error_out_of_range';
export type ConnectionStatus = 'online' | 'offline';
export type HibernationStatus = 'operational' | 'hibernating' | 'grace_period';