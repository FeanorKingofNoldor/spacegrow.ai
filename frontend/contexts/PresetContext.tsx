// contexts/PresetContext.tsx - FIXED to use CommandService properly
'use client';

import React, { createContext, useContext, useEffect, useState, useCallback, useRef } from 'react';
import { 
  Preset, 
  PresetContextType, 
  CreatePresetData, 
  UpdatePresetData, 
  ValidationResult,
  PresetWebSocketEvent,
  CachedPreset,
  PresetError
} from '@/types/preset';
import { Device } from '@/types/device';
import { api } from '@/lib/api';
import { useAuth } from '@/contexts/AuthContext';

const PresetContext = createContext<PresetContextType | undefined>(undefined);

interface PresetProviderProps {
  children: React.ReactNode;
}

export function PresetProvider({ children }: PresetProviderProps) {
  // State
  const [presets, setPresets] = useState<Record<string, Preset[]>>({});
  const [userProfiles, setUserProfiles] = useState<Record<string, Preset[]>>({});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Cache for preset data (in-memory)
  const presetCache = useRef<Map<string, CachedPreset>>(new Map());
  const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

  const { user } = useAuth();

  // ===== CACHE MANAGEMENT =====

  const getCacheKey = useCallback((type: 'predefined' | 'user', deviceTypeId: string): string => {
    return type === 'user' ? `user_${deviceTypeId}_${user?.id}` : `predefined_${deviceTypeId}`;
  }, [user?.id]);

  const isCacheValid = useCallback((cached: CachedPreset): boolean => {
    return Date.now() - cached.cachedAt < CACHE_TTL;
  }, [CACHE_TTL]);

  const setCacheItem = useCallback((key: string, preset: Preset): void => {
    presetCache.current.set(key, {
      preset,
      cachedAt: Date.now(),
      ttl: CACHE_TTL
    });
  }, [CACHE_TTL]);

  const invalidateCache = useCallback((deviceTypeId?: string) => {
    if (deviceTypeId && user?.id) {
      // Invalidate specific device type cache
      const predefinedKey = getCacheKey('predefined', deviceTypeId);
      const userKey = getCacheKey('user', deviceTypeId);
      presetCache.current.delete(predefinedKey);
      presetCache.current.delete(userKey);
    } else {
      // Clear all cache
      presetCache.current.clear();
    }
  }, [getCacheKey, user?.id]);

  // ===== API METHODS =====

  const fetchPresets = useCallback(async (deviceTypeId: string): Promise<void> => {
    if (!user || !deviceTypeId) return;

    const cacheKey = getCacheKey('predefined', deviceTypeId);
    
    // Check cache first
    const cached = presetCache.current.get(cacheKey);
    if (cached && isCacheValid(cached)) {
      setPresets(prev => ({ ...prev, [deviceTypeId]: [cached.preset] }));
      return;
    }

    setLoading(true);
    setError(null);

    try {
      console.log('🔄 Fetching predefined presets for device type:', deviceTypeId);
      
      // ✅ FIXED: Convert device type name to ID and use proper endpoint
      let deviceTypeParam = deviceTypeId;
      
      // Map device type names to IDs
      if (deviceTypeId === 'Environmental Monitor V1') {
        deviceTypeParam = '1';
      } else if (deviceTypeId === 'Liquid Monitor V1') {
        deviceTypeParam = '2';
      }
      
      const response = await api.get(`/api/v1/frontend/presets/by_device_type?device_type_id=${deviceTypeParam}`) as { 
        status?: string; 
        data?: Preset[] 
      };
      console.log('📦 Preset API response:', response);
      
      const fetchedPresets: Preset[] = Array.isArray(response?.data)
        ? response.data
        : (Array.isArray(response) ? response as Preset[] : []);
      
      // Cache the results
      fetchedPresets.forEach((preset: Preset) => {
        setCacheItem(`${cacheKey}_${preset.id}`, preset);
      });

      setPresets(prev => ({ ...prev, [deviceTypeId]: fetchedPresets }));
      console.log('✅ Predefined presets loaded:', fetchedPresets.length);
      
    } catch (err) {
      console.error('❌ Failed to fetch presets:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch presets');
      // Set empty array to prevent infinite loading
      setPresets(prev => ({ ...prev, [deviceTypeId]: [] }));
    } finally {
      setLoading(false);
    }
  }, [user, getCacheKey, isCacheValid, setCacheItem]);

  const fetchUserPresets = useCallback(async (deviceTypeId: string): Promise<void> => {
    if (!user || !deviceTypeId) return;

    const cacheKey = getCacheKey('user', deviceTypeId);
    
    setLoading(true);
    setError(null);

    try {
      console.log('🔄 Fetching user presets for device type:', deviceTypeId);
      
      // ✅ FIXED: Convert device type name to ID and use proper endpoint
      let deviceTypeParam = deviceTypeId;
      
      // Map device type names to IDs
      if (deviceTypeId === 'Environmental Monitor V1') {
        deviceTypeParam = '1';
      } else if (deviceTypeId === 'Liquid Monitor V1') {
        deviceTypeParam = '2';
      }
      
      const response = await api.get(`/api/v1/frontend/presets/user_by_device_type?device_type_id=${deviceTypeParam}`) as { 
        status?: string; 
        data?: Preset[] 
      };
      console.log('📦 User preset API response:', response);
      
      const fetchedProfiles = Array.isArray(response?.data) 
        ? response.data 
        : (Array.isArray(response) ? response as Preset[] : []);
      
      // Cache the results
      fetchedProfiles.forEach((preset: Preset) => {
        setCacheItem(`${cacheKey}_${preset.id}`, preset);
      });

      setUserProfiles(prev => ({ ...prev, [deviceTypeId]: fetchedProfiles }));
      console.log('✅ User presets loaded:', fetchedProfiles.length);
      
    } catch (err) {
      console.error('❌ Failed to fetch user presets:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch user presets');
      // Set empty array to prevent infinite loading
      setUserProfiles(prev => ({ ...prev, [deviceTypeId]: [] }));
    } finally {
      setLoading(false);
    }
  }, [user, getCacheKey, setCacheItem]);

  const createPreset = useCallback(async (data: CreatePresetData): Promise<Preset> => {
    if (!user) throw new Error('User not authenticated');

    setLoading(true);
    setError(null);

    try {
      console.log('🔄 Creating custom preset:', data.name);
      
      const response = await api.post('/api/v1/frontend/presets', { preset: data });
      const newPreset: Preset = (response as { data?: Preset })?.data ?? (response as Preset);
      
      // ✅ FIXED: Update local state immediately and invalidate cache
      const deviceTypeId = String(newPreset.device_type_id);
      
      // Add to user presets immediately (no refetch needed)
      setUserProfiles(prev => ({
        ...prev,
        [deviceTypeId]: [...(prev[deviceTypeId] || []), newPreset]
      }));
      
      // Clear cache to ensure fresh data on next fetch
      invalidateCache(deviceTypeId);
      console.log('✅ Preset created successfully:', newPreset.name);
      
      return newPreset;
      
    } catch (err) {
      console.error('❌ Failed to create preset:', err);
      const error = err instanceof Error ? err.message : 'Failed to create preset';
      setError(error);
      throw err;
    } finally {
      setLoading(false);
    }
  }, [user, invalidateCache]);

  const updatePreset = useCallback(async (id: number, data: UpdatePresetData): Promise<Preset> => {
    if (!user) throw new Error('User not authenticated');

    setLoading(true);
    setError(null);

    try {
      console.log('🔄 Updating preset:', id);
      
      const response = await api.put(`/api/v1/frontend/presets/${id}`, { preset: data });
      const updatedPreset: Preset = (response as { data?: Preset })?.data ?? (response as Preset);
      
      // Update local state
      const deviceTypeId = String(updatedPreset.device_type_id);
      setUserProfiles(prev => ({
        ...prev,
        [deviceTypeId]: (prev[deviceTypeId] || []).map(preset => 
          preset.id === id ? updatedPreset : preset
        )
      }));
      
      invalidateCache(deviceTypeId);
      console.log('✅ Preset updated successfully:', updatedPreset.name);
      
      return updatedPreset;
      
    } catch (err) {
      console.error('❌ Failed to update preset:', err);
      const error = err instanceof Error ? err.message : 'Failed to update preset';
      setError(error);
      throw err;
    } finally {
      setLoading(false);
    }
  }, [user, invalidateCache]);

  const deletePreset = useCallback(async (id: number): Promise<void> => {
    if (!user) throw new Error('User not authenticated');

    setLoading(true);
    setError(null);

    try {
      console.log('🔄 Deleting preset:', id);
      
      await api.delete(`/api/v1/frontend/presets/${id}`);
      
      // Remove from local state
      setUserProfiles(prev => {
        const updated = { ...prev };
        Object.keys(updated).forEach(deviceTypeId => {
          updated[deviceTypeId] = updated[deviceTypeId].filter(preset => preset.id !== id);
        });
        return updated;
      });
      
      invalidateCache(); // Clear all cache since we don't know device type
      console.log('✅ Preset deleted successfully');
      
    } catch (err) {
      console.error('❌ Failed to delete preset:', err);
      const error = err instanceof Error ? err.message : 'Failed to delete preset';
      setError(error);
      throw err;
    } finally {
      setLoading(false);
    }
  }, [user, invalidateCache]);

  // ✅ FIXED: Apply preset via CommandService (not direct preset endpoint)
  const applyPreset = useCallback(async (deviceId: number, presetId: number): Promise<void> => {
    if (!user) throw new Error('User not authenticated');

    setLoading(true);
    setError(null);

    try {
      console.log('🔄 Applying preset to device via CommandService:', { deviceId, presetId });
      
      // ✅ IMPORTANT: Use the commands endpoint, not presets endpoint!
      // This ensures proper integration with your CommandService architecture
      const response = await api.post(`/api/v1/frontend/devices/${deviceId}/commands`, { 
        command: 'apply_preset', 
        args: { preset_id: presetId } 
      });
      
      console.log('✅ Preset application command sent successfully via CommandService');
      console.log('📡 Command response:', response);
      
      // The actual application status will come via WebSocket from DeviceChannel
      // No need to update local state here - WebSocket will handle real-time feedback
      
    } catch (err) {
      console.error('❌ Failed to apply preset via CommandService:', err);
      const error = err instanceof Error ? err.message : 'Failed to apply preset';
      setError(error);
      throw err;
    } finally {
      setLoading(false);
    }
  }, [user]);

  const validateSettings = useCallback(async (
    settings: any, 
    deviceTypeId: string
  ): Promise<ValidationResult> => {
    try {
      console.log('🔄 Validating preset settings:', { settings, deviceTypeId });
      
      const response = await api.post('/api/v1/frontend/presets/validate', { 
        settings, 
        device_type_id: deviceTypeId 
      });
      const validationResult = (response as { data?: ValidationResult })?.data ?? response as ValidationResult;
      
      console.log('✅ Settings validation completed:', validationResult);
      return validationResult;
      
    } catch (err) {
      console.error('❌ Settings validation failed:', err);
      return {
        valid: false,
        errors: [{
          field: 'general',
          message: err instanceof Error ? err.message : 'Validation failed',
          code: 'VALIDATION_ERROR'
        }]
      };
    }
  }, []);

  // ===== CONTEXT VALUE =====

  const contextValue: PresetContextType = {
    // State
    presets,
    userProfiles,
    loading,
    error,
    
    // Actions
    fetchPresets,
    fetchUserPresets,
    createPreset,
    updatePreset,
    deletePreset,
    applyPreset, // ✅ Now properly uses CommandService
    validateSettings,
    
    // Cache management
    invalidateCache,
  };

  return (
    <PresetContext.Provider value={contextValue}>
      {children}
    </PresetContext.Provider>
  );
}

// ===== HOOK =====

export function usePresets(): PresetContextType {
  const context = useContext(PresetContext);
  if (context === undefined) {
    throw new Error('usePresets must be used within a PresetProvider');
  }
  return context;
}

// ===== CONVENIENCE HOOKS =====

export function useDevicePresets(device: Device) {
  const { presets, userProfiles, fetchPresets, fetchUserPresets, loading, error } = usePresets();
  const deviceTypeId = String(device.device_type);

  // ✅ FIXED: Memoize refetch function to prevent infinite loops
  const refetch = useCallback(() => {
    if (deviceTypeId) {
      fetchPresets(deviceTypeId);
      fetchUserPresets(deviceTypeId);
    }
  }, [deviceTypeId, fetchPresets, fetchUserPresets]);

  // ✅ FIXED: Auto-fetch presets for this device type only when deviceTypeId changes
  useEffect(() => {
    if (deviceTypeId && deviceTypeId !== 'undefined') {
      fetchPresets(deviceTypeId);
      fetchUserPresets(deviceTypeId);
    }
  }, [deviceTypeId, fetchPresets, fetchUserPresets]);

  return {
    predefinedPresets: presets[deviceTypeId] || [],
    userPresets: userProfiles[deviceTypeId] || [],
    loading,
    error,
    refetch
  };
}