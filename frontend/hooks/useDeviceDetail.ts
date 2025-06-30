// hooks/useDeviceDetail.ts - FIXED
'use client';

import { useState, useEffect } from 'react';
import { Device, DeviceDetailResponse } from '@/types/device';
import { useAuth } from '@/contexts/AuthContext';

interface UseDeviceDetailReturn {
  device: Device | null;
  loading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
}

export function useDeviceDetail(deviceId: string): UseDeviceDetailReturn {
  const [device, setDevice] = useState<Device | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { user } = useAuth();

  const fetchDevice = async () => {
    if (!deviceId || !user) return;

    setLoading(true);
    setError(null);

    try {
      const response = await fetch(
        `/api/v1/frontend/devices/${deviceId}`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('auth_token')}`,
            'Content-Type': 'application/json'
          }
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const result: DeviceDetailResponse = await response.json();
      
      // FIX: Extract just the device from the nested data structure
      setDevice(result.data.device);
      console.log('📱 Device loaded:', result.data.device.name);

    } catch (err) {
      console.error('❌ Failed to fetch device:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch device');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDevice();
  }, [deviceId, user]);

  return {
    device,
    loading,
    error,
    refetch: fetchDevice
  };
}