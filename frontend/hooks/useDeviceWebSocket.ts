// hooks/useDeviceWebSocket.ts - CLEANED VERSION
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
  
  const [state, setState] = useState<WebSocketState>({
    isConnected: false,
    isConnecting: false,
    connectionError: null,
    lastMessage: null,
    connectionAttempts: 0
  });

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
      return false;
    }

    if (state.isConnecting) {
      return false;
    }

    setState(prev => ({ 
      ...prev, 
      isConnecting: true, 
      connectionError: null,
      connectionAttempts: prev.connectionAttempts + 1
    }));

    try {
      const token = localStorage.getItem('auth_token');
      if (!token) {
        throw new Error('No authentication token available');
      }

      connectionRef.current = await actionCable.connect(user.id, token);
      
      setupMessageHandlers();
      
      setState(prev => ({ 
        ...prev, 
        isConnected: true, 
        isConnecting: false,
        connectionError: null
      }));

      return true;
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown connection error';
      
      setState(prev => ({ 
        ...prev, 
        isConnected: false, 
        isConnecting: false,
        connectionError: errorMessage
      }));

      // Retry logic with exponential backoff
      if (reconnectOnError && state.connectionAttempts < 5) {
        const delay = Math.min(Math.pow(2, state.connectionAttempts) * 1000, 30000);
        
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
    // Chart data updates
    actionCable.on('chart_data_update', (data: WebSocketMessage) => {
      setState(prev => ({ ...prev, lastMessage: data }));
      
      if (callbacksRef.current.onChartDataUpdate && data.type === 'chart_data_update') {
        callbacksRef.current.onChartDataUpdate(data as ChartDataUpdate);
      }
    });

    // Device status updates
    actionCable.on('device_status_update', (data: WebSocketMessage) => {
      setState(prev => ({ ...prev, lastMessage: data }));
      
      if (callbacksRef.current.onDeviceStatusUpdate && data.type === 'device_status_update') {
        callbacksRef.current.onDeviceStatusUpdate(data);
      }
    });

    // Sensor status updates
    actionCable.on('sensor_status_update', (data: WebSocketMessage) => {
      setState(prev => ({ ...prev, lastMessage: data }));
      
      if (callbacksRef.current.onSensorStatusUpdate && data.type === 'sensor_status_update') {
        callbacksRef.current.onSensorStatusUpdate(data);
      }
    });

    // Connection monitoring
    actionCable.on('welcome', () => {
      setState(prev => ({ ...prev, isConnected: true, connectionError: null }));
    });

    actionCable.on('disconnect', () => {
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
      throw new Error('WebSocket not connected');
    }

    if (!actionCable.isConnected()) {
      throw new Error('ActionCable not ready');
    }

    try {
      actionCable.sendCommand(command, args);
      
      return {
        success: true,
        command,
        args,
        timestamp: new Date().toISOString()
      };
      
    } catch (error) {
      throw error;
    }
  }, [state.isConnected]);

  /**
   * Reconnect manually
   */
  const reconnect = useCallback(async () => {
    disconnect();
    
    // Wait a bit before reconnecting
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    return connect();
  }, [disconnect, connect]);

  // Auto-connect when user is available
  useEffect(() => {
    if (user && autoConnect && !state.isConnected && !state.isConnecting) {
      connect();
    }
    
    return () => {
      if (!autoConnect) {
        disconnect();
      }
    };
  }, [user, autoConnect, connect, disconnect, state.isConnected, state.isConnecting]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      disconnect();
    };
  }, [disconnect]);

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
    
    // Connection info
    connectionState: actionCable.getConnectionState()
  };
}