// types/preset.ts
import { Device } from './device';

// ===== CORE PRESET TYPES =====

export interface Preset {
  id: number;
  name: string;
  device_type_id: number;
  device_id?: number;
  user_id?: number;
  is_user_defined: boolean;
  settings: PresetSettings;
  created_at: string;
  updated_at: string;
}

// ===== PRESET SETTINGS BY DEVICE TYPE =====

export interface EnvironmentalMonitorSettings {
  lights: {
    on_at: string;    // "08:00hrs"
    off_at: string;   // "20:00hrs"
  };
  spray: {
    on_for: number;   // seconds spray is on
    off_for: number;  // seconds spray is off
  };
}

export interface LiquidMonitorSettings {
  pump1: { duration: number };  // seconds to run pump
  pump2: { duration: number };
  pump3: { duration: number };
  pump4: { duration: number };
  pump5: { duration: number };
}

// Union type for all preset settings
export type PresetSettings = EnvironmentalMonitorSettings | LiquidMonitorSettings;

// ===== DEVICE TYPE CONFIGURATION =====

export interface ActuatorConfig {
  commands: string[];
  payload_key?: string;
}

export interface DeviceTypeConfig {
  id: number;
  name: string;
  supported_actuators: Record<string, ActuatorConfig>;
  settings_schema?: any; // JSON Schema for validation
}

// ===== API RESPONSE TYPES =====

export interface PresetResponse {
  status: 'success' | 'error';
  data: Preset;
  message?: string;
}

export interface PresetsResponse {
  status: 'success' | 'error';
  data: Preset[];
  message?: string;
}

export interface PresetDetailResponse {
  status: 'success';
  data: {
    id: number;
    name: string;
    settings: PresetSettings;
    user_timezone?: string;
    device_type: DeviceTypeConfig;
  };
}

export interface UserPresetsResponse {
  status: 'success' | 'error';
  data: Preset[];
  message?: string;
}

// ===== PRESET CRUD TYPES =====

export interface CreatePresetData {
  name: string;
  device_id: number;
  settings: Partial<PresetSettings>;
}

export interface UpdatePresetData {
  name?: string;
  settings?: Partial<PresetSettings>;
}

// ===== PRESET APPLICATION TYPES =====

export interface PresetApplicationRequest {
  device_id: number;
  preset_id: number;
}

export interface PresetApplicationResponse {
  status: 'success' | 'error';
  data: {
    command_id: number;
    status: 'pending' | 'success' | 'failed';
    device_id: number;
    preset_id: number;
    applied_settings: PresetSettings;
  };
  message?: string;
}

// ===== VALIDATION TYPES =====

export interface ValidationError {
  field: string;
  message: string;
  code: string;
}

export interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
  warnings?: string[];
}

export interface ValidationResponse {
  status: 'success' | 'error';
  data: ValidationResult;
}

// ===== WEBSOCKET PRESET EVENTS =====

export interface PresetAppliedEvent {
  type: 'preset_applied';
  data: {
    device_id: number;
    preset_id: number;
    status: 'pending' | 'success' | 'failed';
    timestamp: string;
    applied_settings?: PresetSettings;
  };
}

export interface PresetApplicationProgressEvent {
  type: 'preset_application_progress';
  data: {
    device_id: number;
    preset_id: number;
    step: string;
    progress: number; // 0-100
    message?: string;
  };
}

export interface DeviceSettingsChangedEvent {
  type: 'device_settings_changed';
  data: {
    device_id: number;
    new_settings: PresetSettings;
    applied_preset_id?: number;
    timestamp: string;
  };
}

export type PresetWebSocketEvent = 
  | PresetAppliedEvent 
  | PresetApplicationProgressEvent 
  | DeviceSettingsChangedEvent;

// ===== PRESET CONTEXT TYPES =====

export interface PresetContextType {
  // State
  presets: Record<string, Preset[]>; // Keyed by device_type_id
  userProfiles: Record<string, Preset[]>; // User's custom presets
  loading: boolean;
  error: string | null;
  
  // Actions
  fetchPresets: (deviceTypeId: string) => Promise<void>;
  fetchUserPresets: (deviceTypeId: string) => Promise<void>;
  createPreset: (data: CreatePresetData) => Promise<Preset>;
  updatePreset: (id: number, data: UpdatePresetData) => Promise<Preset>;
  deletePreset: (id: number) => Promise<void>;
  applyPreset: (deviceId: number, presetId: number) => Promise<void>;
  validateSettings: (settings: Partial<PresetSettings>, deviceTypeId: string) => Promise<ValidationResult>;
  
  // Cache management
  invalidateCache: (deviceTypeId?: string) => void;
}

// ===== COMPONENT PROP TYPES =====

export interface PresetModalProps {
  isOpen: boolean;
  onClose: () => void;
  device: Device;
  onPresetApplied?: (preset: Preset) => void;
}

export interface PresetCardProps {
  preset: Preset;
  onApply: (preset: Preset) => void;
  onEdit?: (preset: Preset) => void;
  onDelete?: (preset: Preset) => void;
  loading?: boolean;
  disabled?: boolean;
}

export interface PresetFormProps {
  deviceType: DeviceTypeConfig;
  initialSettings?: Partial<PresetSettings>;
  onSubmit: (data: CreatePresetData | UpdatePresetData) => void;
  onCancel: () => void;
  loading?: boolean;
  mode: 'create' | 'edit';
}

export interface PresetTabsProps {
  presets: Preset[];
  userPresets: Preset[];
  onPresetSelect: (preset: Preset) => void;
  selectedPreset?: Preset;
  loading?: boolean;
}

// ===== PRESET UTILITY TYPES =====

export interface PresetStats {
  total: number;
  predefined: number;
  userDefined: number;
  applied: number;
}

export interface PresetFilter {
  deviceTypeId?: string;
  isUserDefined?: boolean;
  searchTerm?: string;
}

export interface PresetSort {
  field: 'name' | 'created_at' | 'updated_at';
  direction: 'asc' | 'desc';
}

// ===== ERROR TYPES =====

export interface PresetError extends Error {
  code: 'PRESET_NOT_FOUND' | 'INVALID_SETTINGS' | 'DEVICE_OFFLINE' | 'PERMISSION_DENIED' | 'VALIDATION_FAILED';
  deviceId?: number;
  presetId?: number;
  validationErrors?: ValidationError[];
}

// ===== CACHE TYPES =====

export interface CachedPreset {
  preset: Preset;
  cachedAt: number;
  ttl: number;
}

export interface PresetCacheConfig {
  ttl: number; // Time to live in milliseconds
  maxSize: number; // Maximum number of cached items
}

// ===== PREDEFINED PRESET CONSTANTS =====

export const PREDEFINED_PRESET_NAMES = {
  ENVIRONMENTAL_MONITOR: ['Cannabis', 'Chili'],
  LIQUID_MONITOR: Array.from({ length: 10 }, (_, i) => `Preset ${i + 1}`)
} as const;

export const DEVICE_TYPES = {
  ENVIRONMENTAL_MONITOR_V1: 'Environmental Monitor V1',
  LIQUID_MONITOR_V1: 'Liquid Monitor V1'
} as const;

// ===== TIME FORMAT HELPERS =====

export interface TimeValue {
  hours: number;
  minutes: number;
}

export const parseTimeString = (timeStr: string): TimeValue => {
  // Parse "08:00hrs" format
  const match = timeStr.match(/(\d{2}):(\d{2})hrs/);
  if (!match) throw new Error(`Invalid time format: ${timeStr}`);
  
  return {
    hours: parseInt(match[1], 10),
    minutes: parseInt(match[2], 10)
  };
};

export const formatTimeString = (time: TimeValue): string => {
  const hours = time.hours.toString().padStart(2, '0');
  const minutes = time.minutes.toString().padStart(2, '0');
  return `${hours}:${minutes}hrs`;
};