// types/device.ts - PHASE 6: Complete suspended terminology replacement (COMPLETE VERSION)
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

// ✅ UPDATED: Suspension priority (was suspensionPriority)
export interface SuspensionPriority {
  device_id: number;
  device_name: string;
  score: number;
  last_connection: string | null;
  created_at: string;
  alert_status: string;
  priority_reason?: string;
  recommendation?: 'recommended_to_suspend' | 'consider_suspending' | 'keep_active';
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

// ✅ UPDATED: Device management data with suspended terminology
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
      suspended: number;
    };
  };
  device_limits: {
    total_limit: number;
    operational_count: number;
    suspended_count: number;
    available_slots: number;
  };
  devices: {
    operational: Device[];
    suspended: Device[];
  };
  suspension_priorities: SuspensionPriority[];
  upsell_options: UpsellOption[];
  over_device_limit: boolean;
}

// ✅ UPDATED: Device interface with suspended status
export interface Device {
  id: number;
  name: string;
  status: 'pending' | 'active' | 'suspended' | 'disabled';
  alert_status: 'normal' | 'warning' | 'error' | 'no_data';
  device_type: string;
  last_connection: string | null;
  created_at: string;
  updated_at: string;
  sensors?: DeviceSensor[];
  
  // ✅ UPDATED: Suspension fields
  suspended_at: string | null;
  suspended_reason: string | null;
  grace_period_ends_at: string | null;
  
  // ✅ UPDATED: Computed suspension properties
  operational?: boolean;
  suspended?: boolean;
  in_grace_period?: boolean;

  
  // Optional properties from detailed API responses
  sensor_groups?: Record<string, DeviceSensor[]>;
  latest_readings?: Record<string, number | SensorReading>;
  device_status?: DeviceStatus;
  presets?: Preset[];
  profiles?: Preset[];
}

// Extended device interface for detailed views
export interface DeviceDetail extends Device {
  sensors: DeviceSensor[];
  latest_readings: Record<string, SensorReading>;
  device_status: DeviceStatus;
  presets: Preset[];
  profiles: Preset[];
}

// ✅ UPDATED: Suspension request/response types
export interface SuspendDeviceRequest {
  reason: string;
  grace_period_days?: number;
}

export interface SuspendDeviceResponse {
  status: 'success';
  message: string;
  data: {
    device: Device;
    suspended_at: string;
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

export interface BulkSuspensionRequest {
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

// ✅ UPDATED: WebSocket message types with suspended terminology
export interface DeviceStatusUpdate {
  device_id: string | number;
  alert_status?: 'normal' | 'warning' | 'error' | 'no_data';
  status?: 'pending' | 'active' | 'suspended' | 'disabled';
  last_connection?: string;
  status_class?: string;
  
  // ✅ UPDATED: Suspension status updates
  suspended_at?: string | null;
  suspended_reason?: string | null;
  grace_period_ends_at?: string | null;
  operational?: boolean;
  suspended?: boolean;
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
    suspended?: number;
  };
}

// ✅ COMPLETELY UPDATED: Device utilities with suspended terminology and status-based logic
export const deviceUtils = {
  isSuspended: (device: Device): boolean => {
    return device.status === 'suspended';
  },

  isOperational: (device: Device): boolean => {
    return device.status === 'active';
  },

  isPending: (device: Device): boolean => {
    return device.status === 'pending';
  },

  isDisabled: (device: Device): boolean => {
    return device.status === 'disabled';
  },

  isInGracePeriod: (device: Device): boolean => {
    if (!device.grace_period_ends_at) return false;
    return new Date(device.grace_period_ends_at) > new Date();
  },

  getSuspensionStatus: (device: Device): 'operational' | 'suspended' | 'grace_period' | 'pending' | 'disabled' => {
    if (device.status === 'pending') return 'pending';
    if (device.status === 'disabled') return 'disabled';
    if (device.status === 'suspended') {
      return deviceUtils.isInGracePeriod(device) ? 'grace_period' : 'suspended';
    }
    return 'operational';
  },

  getSuspensionDisplayText: (device: Device): string => {
    const status = deviceUtils.getSuspensionStatus(device);
    switch (status) {
      case 'operational': return 'Operational';
      case 'pending': return 'Pending Activation';
      case 'disabled': return 'Disabled';
      case 'grace_period': return 'Grace Period';
      case 'suspended': return 'Suspended';
      default: return 'Unknown';
    }
  },

  getSuspensionColor: (device: Device): string => {
    const status = deviceUtils.getSuspensionStatus(device);
    switch (status) {
      case 'operational': return 'text-green-400 bg-green-500/20';
      case 'pending': return 'text-yellow-400 bg-yellow-500/20';
      case 'disabled': return 'text-gray-400 bg-gray-500/20';
      case 'grace_period': return 'text-orange-400 bg-orange-500/20';
      case 'suspended': return 'text-blue-400 bg-blue-500/20';
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
    return deviceUtils.isSuspended(device);
  },

  canSuspendDevice: (device: Device): boolean => {
    return deviceUtils.isOperational(device);
  },

  canEnableDevice: (device: Device): boolean => {
    return device.status === 'disabled';
  },

  canDisableDevice: (device: Device): boolean => {
    return device.status === 'active' || device.status === 'suspended';
  },

  formatSuspensionReason: (reason: string | null): string => {
    if (!reason) return 'No reason provided';
    
    const reasonMap: Record<string, string> = {
      'subscription_limit': 'Over subscription limit',
      'user_choice': 'User suspended',
      'automatic': 'Automatically suspended',
      'grace_period_expired': 'Grace period expired',
      'payment_overdue': 'Payment overdue',
      'plan_downgrade': 'Plan downgrade'
    };

    return reasonMap[reason] || reason.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
  },

  getAlertColor: (alertStatus: string): string => {
    switch (alertStatus) {
      case 'normal': return 'text-green-400 bg-green-500/20';
      case 'warning': return 'text-yellow-400 bg-yellow-500/20';
      case 'error': return 'text-red-400 bg-red-500/20';
      case 'no_data': return 'text-gray-400 bg-gray-500/20';
      default: return 'text-gray-400 bg-gray-500/20';
    }
  },

  getStatusIcon: (device: Device): string => {
    const status = deviceUtils.getSuspensionStatus(device);
    switch (status) {
      case 'operational': return '🟢';
      case 'pending': return '🟡';
      case 'disabled': return '⚫';
      case 'grace_period': return '🟠';
      case 'suspended': return '🔵';
      default: return '❓';
    }
  },

  // ✅ NEW: Helper for subscription limit checks
  isOverSubscriptionLimit: (device: Device): boolean => {
    return device.suspended_reason === 'subscription_limit';
  },

  // ✅ UPDATED: Get priority recommendation with suspended terminology
  getPriorityRecommendation: (priority: SuspensionPriority): {
    color: string;
    text: string;
    icon: string;
  } => {
    if (priority.score >= 80) {
      return {
        color: 'text-red-400',
        text: 'Recommended to suspend',
        icon: '🔴'
      };
    } else if (priority.score >= 60) {
      return {
        color: 'text-orange-400',
        text: 'Consider suspending',
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

// ✅ UPDATED: Utility types for type safety
export type AlertStatus = 'normal' | 'warning' | 'error' | 'no_data';
export type DeviceConnectionStatus = 'pending' | 'active' | 'suspended' | 'disabled';
export type SensorStatus = 'ok' | 'warning' | 'error' | 'no_data' | 'warning_high' | 'warning_low' | 'error_high' | 'error_low';
export type SensorZone = 'normal' | 'warning_low' | 'warning_high' | 'error_low' | 'error_high' | 'error_out_of_range';
export type ConnectionStatus = 'online' | 'offline';
export type SuspensionStatus = 'operational' | 'suspended' | 'grace_period' | 'pending' | 'disabled';