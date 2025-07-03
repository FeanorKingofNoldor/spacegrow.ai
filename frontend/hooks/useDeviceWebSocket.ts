// hooks/useDeviceWebSocket.ts - PRODUCTION READY VERSION
'use client';

import { useEffect, useRef, useState, useCallback } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { actionCable } from '@/lib/actionCable';
import { WebSocketMessage, ChartDataUpdate } from '@/types/websocket';

interface UseDeviceWebSocketProps {
  deviceId?: number;
  onChartDataUpdate?: (data: ChartDataUpdate) => void;
  onDeviceStatusUpdate?: (data: any) => void;
  onSensorStatusUpdate?: (data: any) => void;
  autoConnect?: boolean;
  reconnectOnError?: boolean;
}

interface WebSocketState {
  isConnected: boolean;
  isConnecting: boolean;
  connectionError: string | null;
  lastMessage: WebSocketMessage | null;
  connectionAttempts: number;
}

export function useDeviceWebSocket({
  deviceId,
  onChartDataUpdate,
  onDeviceStatusUpdate,
  onSensorStatusUpdate,
  autoConnect = true,
  reconnectOnError = true
}: UseDeviceWebSocketProps) {
  const { user } = useAuth();
  
  // ✅ FIXED: Comprehensive WebSocket state management
  const [state, setState] = useState<WebSocketState>({
    isConnected: false,
    isConnecting: false,
    connectionError: null,
    lastMessage: null,
    connectionAttempts: 0
  });

  // ✅ FIXED: Use refs to prevent stale closures
  const connectionRef = useRef<any>(null);
  const callbacksRef = useRef({
    onChartDataUpdate,
    onDeviceStatusUpdate,
    onSensorStatusUpdate
  });

  // Update refs when callbacks change
  useEffect(() => {
    callbacksRef.current = {
      onChartDataUpdate,
      onDeviceStatusUpdate,
      onSensorStatusUpdate
    };
  }, [onChartDataUpdate, onDeviceStatusUpdate, onSensorStatusUpdate]);

  /**
   * Connect to WebSocket with proper error handling
   */
  const connect = useCallback(async () => {
    if (!user || !autoConnect) {
      console.log('🔌 Skipping WebSocket connection - no user or autoConnect disabled');
      return false;
    }

    if (state.isConnecting) {
      console.log('🔌 Connection already in progress');
      return false;
    }

    setState(prev => ({ 
      ...prev, 
      isConnecting: true, 
      connectionError: null,
      connectionAttempts: prev.connectionAttempts + 1
    }));

    try {
      console.log('🔌 Setting up WebSocket connection for user:', user.id);
      
      // ✅ FIXED: Get JWT token for authentication
      const token = localStorage.getItem('auth_token');
      if (!token) {
        throw new Error('No authentication token available');
      }

      // Connect to ActionCable with authentication
      connectionRef.current = await actionCable.connect(user.id, token);
      
      // Set up message handlers
      setupMessageHandlers();
      
      setState(prev => ({ 
        ...prev, 
        isConnected: true, 
        isConnecting: false,
        connectionError: null
      }));

      console.log('✅ WebSocket connection established');
      return true;
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown connection error';
      console.error('❌ WebSocket connection failed:', errorMessage);
      
      setState(prev => ({ 
        ...prev, 
        isConnected: false, 
        isConnecting: false,
        connectionError: errorMessage
      }));

      // ✅ FIXED: Retry logic with exponential backoff
      if (reconnectOnError && state.connectionAttempts < 5) {
        const delay = Math.min(Math.pow(2, state.connectionAttempts) * 1000, 30000);
        console.log(`🔄 Retrying connection in ${delay}ms`);
        
        setTimeout(() => {
          connect();
        }, delay);
      }

      return false;
    }
  }, [user, autoConnect, reconnectOnError, state.isConnecting, state.connectionAttempts]);

  /**
   * Set up message handlers
   */
  const setupMessageHandlers = useCallback(() => {
    console.log('📡 Setting up WebSocket message handlers');

    // ✅ FIXED: Chart data updates
    actionCable.on('chart_data_update', (data: WebSocketMessage) => {
      console.log('📊 Chart data update received:', data);
      setState(prev => ({ ...prev, lastMessage: data }));
      
      if (callbacksRef.current.onChartDataUpdate && data.type === 'chart_data_update') {
        callbacksRef.current.onChartDataUpdate(data as ChartDataUpdate);
      }
    });

    // ✅ FIXED: Device status updates
    actionCable.on('device_status_update', (data: WebSocketMessage) => {
      console.log('📱 Device status update received:', data);
      setState(prev => ({ ...prev, lastMessage: data }));
      
      if (callbacksRef.current.onDeviceStatusUpdate && data.type === 'device_status_update') {
        callbacksRef.current.onDeviceStatusUpdate(data);
      }
    });

    // ✅ FIXED: Sensor status updates
    actionCable.on('sensor_status_update', (data: WebSocketMessage) => {
      console.log('🔬 Sensor status update received:', data);
      setState(prev => ({ ...prev, lastMessage: data }));
      
      if (callbacksRef.current.onSensorStatusUpdate && data.type === 'sensor_status_update') {
        callbacksRef.current.onSensorStatusUpdate(data);
      }
    });

    // ✅ FIXED: Connection monitoring
    actionCable.on('welcome', () => {
      console.log('👋 ActionCable welcome received');
      setState(prev => ({ ...prev, isConnected: true, connectionError: null }));
    });

    actionCable.on('disconnect', () => {
      console.log('👋 ActionCable disconnected');
      setState(prev => ({ 
        ...prev, 
        isConnected: false, 
        connectionError: 'Connection lost' 
      }));
    });

  }, []);

  /**
   * Disconnect from WebSocket
   */
  const disconnect = useCallback(() => {
    console.log('🔌 Disconnecting WebSocket');
    
    // Clean up message handlers
    actionCable.off('chart_data_update');
    actionCable.off('device_status_update');
    actionCable.off('sensor_status_update');
    actionCable.off('welcome');
    actionCable.off('disconnect');
    
    // Disconnect ActionCable
    actionCable.disconnect();
    
    // Reset state
    setState({
      isConnected: false,
      isConnecting: false,
      connectionError: null,
      lastMessage: null,
      connectionAttempts: 0
    });
    
    connectionRef.current = null;
  }, []);

  /**
   * Send command with error handling
   */
  const sendCommand = useCallback(async (command: string, args: Record<string, any> = {}) => {
    if (!state.isConnected) {
      console.error('❌ Cannot send command: WebSocket not connected');
      throw new Error('WebSocket not connected');
    }

    if (!actionCable.isConnected()) {
      console.error('❌ Cannot send command: ActionCable not ready');
      throw new Error('ActionCable not ready');
    }

    try {
      console.log('📤 Sending command:', command, args);
      actionCable.sendCommand(command, args);
      
      return {
        success: true,
        command,
        args,
        timestamp: new Date().toISOString()
      };
      
    } catch (error) {
      console.error('❌ Failed to send command:', error);
      throw error;
    }
  }, [state.isConnected]);

  /**
   * Health check
   */
  const healthCheck = useCallback(async (): Promise<boolean> => {
    if (!state.isConnected) return false;
    
    try {
      return await actionCable.healthCheck();
    } catch (error) {
      console.error('❌ Health check failed:', error);
      return false;
    }
  }, [state.isConnected]);

  /**
   * Reconnect manually
   */
  const reconnect = useCallback(async () => {
    console.log('🔄 Manual reconnection requested');
    disconnect();
    
    // Wait a bit before reconnecting
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    return connect();
  }, [disconnect, connect]);

  // ✅ FIXED: Auto-connect when user is available
  useEffect(() => {
    if (user && autoConnect && !state.isConnected && !state.isConnecting) {
      console.log('🔌 Auto-connecting WebSocket for user:', user.id);
      connect();
    }
    
    return () => {
      if (!autoConnect) {
        disconnect();
      }
    };
  }, [user, autoConnect, connect, disconnect, state.isConnected, state.isConnecting]);

  // ✅ FIXED: Cleanup on unmount
  useEffect(() => {
    return () => {
      console.log('🔌 Component unmounting, cleaning up WebSocket');
      disconnect();
    };
  }, [disconnect]);

  // ✅ FIXED: Monitor connection health
  useEffect(() => {
    if (!state.isConnected) return;

    const healthCheckInterval = setInterval(async () => {
      const isHealthy = await healthCheck();
      if (!isHealthy && reconnectOnError) {
        console.log('💔 Health check failed, attempting reconnection');
        reconnect();
      }
    }, 30000); // Check every 30 seconds

    return () => clearInterval(healthCheckInterval);
  }, [state.isConnected, healthCheck, reconnect, reconnectOnError]);

  return {
    // Connection state
    isConnected: state.isConnected,
    isConnecting: state.isConnecting,
    connectionError: state.connectionError,
    connectionAttempts: state.connectionAttempts,
    
    // Last received message
    lastMessage: state.lastMessage,
    
    // Connection management
    connect,
    disconnect,
    reconnect,
    
    // Commands
    sendCommand,
    
    // Health monitoring
    healthCheck,
    
    // Connection info
    connectionState: actionCable.getConnectionState()
  };
}