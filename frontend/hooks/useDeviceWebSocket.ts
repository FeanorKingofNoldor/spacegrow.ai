// hooks/useDeviceWebSocket.ts
'use client';

import { useEffect, useRef, useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { actionCable } from '@/lib/actionCable';
import { WebSocketMessage, ChartDataUpdate } from '@/types/websocket';

interface UseDeviceWebSocketProps {
  deviceId?: number;
  onChartDataUpdate?: (data: ChartDataUpdate) => void;
  onDeviceStatusUpdate?: (data: any) => void;
  onSensorStatusUpdate?: (data: any) => void;
}

export function useDeviceWebSocket({
  deviceId,
  onChartDataUpdate,
  onDeviceStatusUpdate,
  onSensorStatusUpdate
}: UseDeviceWebSocketProps) {
  const { user } = useAuth();
  const [isConnected, setIsConnected] = useState(false);
  const [lastMessage, setLastMessage] = useState<WebSocketMessage | null>(null);
  const connectionRef = useRef<any>(null);

  useEffect(() => {
    if (!user) return;

    console.log('🔌 Setting up WebSocket connection for user:', user.id);
    
    // Connect to ActionCable
    connectionRef.current = actionCable.connect(user.id);
    setIsConnected(true);

    // Register message handlers
    actionCable.on('chart_data_update', (data: WebSocketMessage) => {
      console.log('📊 Chart data update received:', data);
      setLastMessage(data);
      if (onChartDataUpdate && data.type === 'chart_data_update') {
        onChartDataUpdate(data);
      }
    });

    actionCable.on('device_status_update', (data: WebSocketMessage) => {
      console.log('📱 Device status update received:', data);
      setLastMessage(data);
      if (onDeviceStatusUpdate && data.type === 'device_status_update') {
        onDeviceStatusUpdate(data);
      }
    });

    actionCable.on('sensor_status_update', (data: WebSocketMessage) => {
      console.log('🔬 Sensor status update received:', data);
      setLastMessage(data);
      if (onSensorStatusUpdate && data.type === 'sensor_status_update') {
        onSensorStatusUpdate(data);
      }
    });

    // Cleanup on unmount
    return () => {
      console.log('🔌 Cleaning up WebSocket connection');
      actionCable.off('chart_data_update');
      actionCable.off('device_status_update');
      actionCable.off('sensor_status_update');
      actionCable.disconnect();
      setIsConnected(false);
    };
  }, [user, onChartDataUpdate, onDeviceStatusUpdate, onSensorStatusUpdate]);

  const sendCommand = (command: string, args: Record<string, any> = {}) => {
    if (isConnected) {
      actionCable.sendCommand(command, args);
    } else {
      console.error('❌ Cannot send command: WebSocket not connected');
    }
  };

  return {
    isConnected,
    lastMessage,
    sendCommand
  };
}
