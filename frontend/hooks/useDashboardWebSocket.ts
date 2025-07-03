// hooks/useDashboardWebSocket.ts
'use client';

import { useEffect, useRef, useState, useCallback } from 'react';
import { Device } from '@/types/device';

interface DashboardWebSocketMessage {
  type: 'device_status_update' | 'dashboard_update' | 'sensor_status_update';
  data: any;
}

interface UseDashboardWebSocketProps {
  onDeviceStatusUpdate?: (deviceId: string, statusData: any) => void;
  onDashboardUpdate?: (dashboardData: any) => void;
  enabled?: boolean;
}

export function useDashboardWebSocket({ 
  onDeviceStatusUpdate, 
  onDashboardUpdate,
  enabled = true 
}: UseDashboardWebSocketProps = {}) {
  const wsRef = useRef<WebSocket | null>(null);
  const [connectionStatus, setConnectionStatus] = useState<'connecting' | 'connected' | 'disconnected'>('disconnected');
  const reconnectTimeoutRef = useRef<NodeJS.Timeout | undefined>(undefined);
  const reconnectAttempts = useRef(0);
  const maxReconnectAttempts = 3; // ✅ FIXED: Reduced max attempts to prevent spam
  const isConnecting = useRef(false); // ✅ FIXED: Prevent multiple connection attempts

  const connect = useCallback(() => {
    // ✅ FIXED: Prevent multiple connection attempts
    if (!enabled || isConnecting.current || wsRef.current?.readyState === WebSocket.CONNECTING) return;

    try {
      isConnecting.current = true;
      setConnectionStatus('connecting');
      
      // ✅ FIXED: Better WebSocket URL handling with fallback
      const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
      const host = window.location.host;
      const wsUrl = process.env.NEXT_PUBLIC_WS_URL || `${protocol}//${host}/cable`;
      
      console.log('🔌 Connecting to WebSocket:', wsUrl);
      const ws = new WebSocket(wsUrl);
      
      ws.onopen = () => {
        console.log('🔌 Dashboard WebSocket connected');
        setConnectionStatus('connected');
        reconnectAttempts.current = 0;
        isConnecting.current = false;
        
        // Subscribe to dashboard channel
        const subscribeMessage = {
          command: 'subscribe',
          identifier: JSON.stringify({
            channel: 'DashboardChannel'
          })
        };
        
        ws.send(JSON.stringify(subscribeMessage));
      };

      ws.onmessage = (event) => {
        try {
          const message = JSON.parse(event.data);
          
          // Handle ActionCable message structure
          if (message.type === 'confirm_subscription') {
            console.log('✅ Dashboard channel subscription confirmed');
            return;
          }
          
          if (message.message) {
            handleWebSocketMessage(message.message);
          }
        } catch (error) {
          console.error('❌ Error parsing WebSocket message:', error);
        }
      };

      ws.onclose = (event) => {
        console.log('🔌 Dashboard WebSocket disconnected:', event.code, event.reason);
        setConnectionStatus('disconnected');
        isConnecting.current = false;
        
        // ✅ FIXED: Only attempt reconnection if it wasn't a manual close and we haven't exceeded max attempts
        if (!event.wasClean && reconnectAttempts.current < maxReconnectAttempts && enabled) {
          const delay = Math.min(Math.pow(2, reconnectAttempts.current) * 1000, 10000); // Max 10 second delay
          console.log(`🔄 Reconnecting in ${delay}ms (attempt ${reconnectAttempts.current + 1}/${maxReconnectAttempts})`);
          
          reconnectTimeoutRef.current = setTimeout(() => {
            reconnectAttempts.current++;
            connect();
          }, delay);
        } else if (reconnectAttempts.current >= maxReconnectAttempts) {
          console.log('❌ Max reconnection attempts reached, giving up');
        }
      };

      ws.onerror = (error) => {
        console.error('❌ Dashboard WebSocket error:', error);
        setConnectionStatus('disconnected');
        isConnecting.current = false;
      };

      wsRef.current = ws;
    } catch (error) {
      console.error('❌ Failed to connect to WebSocket:', error);
      setConnectionStatus('disconnected');
      isConnecting.current = false;
    }
  }, [enabled]);

  const handleWebSocketMessage = useCallback((message: DashboardWebSocketMessage) => {
    console.log('📨 Dashboard WebSocket message:', message);
    
    switch (message.type) {
      case 'device_status_update':
        if (onDeviceStatusUpdate && message.data.device_id) {
          onDeviceStatusUpdate(message.data.device_id.toString(), message.data);
        }
        break;
        
      case 'dashboard_update':
        if (onDashboardUpdate) {
          onDashboardUpdate(message.data);
        }
        break;
        
      case 'sensor_status_update':
        // Handle sensor status updates which affect device alert_status
        if (onDeviceStatusUpdate && message.data.device_id) {
          onDeviceStatusUpdate(message.data.device_id.toString(), {
            alert_status: message.data.alert_status,
            sensors: message.data.sensors
          });
        }
        break;
        
      default:
        console.log('🤷 Unhandled WebSocket message type:', message.type);
    }
  }, [onDeviceStatusUpdate, onDashboardUpdate]);

  const disconnect = useCallback(() => {
    console.log('🔌 Manually disconnecting WebSocket');
    
    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current);
      reconnectTimeoutRef.current = undefined;
    }
    
    reconnectAttempts.current = maxReconnectAttempts; // Prevent auto-reconnect
    isConnecting.current = false;
    
    if (wsRef.current) {
      wsRef.current.close(1000, 'Manual disconnect'); // Normal closure
      wsRef.current = null;
    }
    
    setConnectionStatus('disconnected');
  }, [maxReconnectAttempts]);

  // ✅ FIXED: Connect only when enabled and in browser environment
  useEffect(() => {
    if (enabled && typeof window !== 'undefined') {
      // Small delay to prevent immediate connection on mount
      const connectTimeout = setTimeout(() => {
        connect();
      }, 100);
      
      return () => {
        clearTimeout(connectTimeout);
        disconnect();
      };
    }
    
    return () => {
      disconnect();
    };
  }, [enabled, connect, disconnect]);

  // ✅ FIXED: Cleanup on unmount
  useEffect(() => {
    return () => {
      disconnect();
    };
  }, [disconnect]);

  return {
    connectionStatus,
    connect,
    disconnect,
    isConnected: connectionStatus === 'connected'
  };
}

// ✅ FIXED: Moved from inline to proper hook export with better memoization
export function useDeviceListWebSocket(
  devices: Device[], 
  updateDevice: (deviceId: string, updates: Partial<Device>) => void
) {
  // ✅ FIXED: Memoize callbacks to prevent unnecessary re-renders
  const handleDeviceStatusUpdate = useCallback((deviceId: string, statusData: any) => {
    console.log(`📱 Device ${deviceId} status update:`, statusData);
    
    // Update device with new status data
    const updates: Partial<Device> = {};
    
    if (statusData.alert_status) {
      updates.alert_status = statusData.alert_status;
    }
    
    if (statusData.status) {
      updates.status = statusData.status;
    }
    
    if (statusData.last_connection) {
      updates.last_connection = statusData.last_connection;
    }
    
    updateDevice(deviceId, updates);
  }, [updateDevice]);

  const handleDashboardUpdate = useCallback((dashboardData: any) => {
    console.log('📊 Dashboard update:', dashboardData);
    
    // Handle bulk device updates if provided
    if (dashboardData.devices) {
      dashboardData.devices.forEach((deviceUpdate: any) => {
        if (deviceUpdate.id) {
          updateDevice(deviceUpdate.id.toString(), deviceUpdate);
        }
      });
    }
  }, [updateDevice]);

  return useDashboardWebSocket({
    onDeviceStatusUpdate: handleDeviceStatusUpdate,
    onDashboardUpdate: handleDashboardUpdate,
    enabled: devices.length > 0 && typeof window !== 'undefined' // ✅ FIXED: Only enable if we have devices and are in browser
  });
}