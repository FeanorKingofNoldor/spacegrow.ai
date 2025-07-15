// types/websocket.ts - CLEANED VERSION (removed ping/pong types)
export interface ChartDataUpdate {
  type: 'chart_data_update';
  chart_id: string;
  data_points: [string, number][];
  title: string;
  mode: string;
  device_id: number;
  timestamp: string;
}

export interface SensorStatusUpdate {
  type: 'sensor_status_update';
  data: {
    device_id: number;
    status: string;
    alert_status: string;
    sensors: Array<{
      sensor_id: number;
      status: string;
    }>;
    timestamp: string;
  };
}

export interface DeviceStatusUpdate {
  type: 'device_status_update';
  data: {
    device_id: number;
    last_connection: string;
    status_class: string;
    is_online: boolean;
    alert_status: string;
    status: string;
    timestamp: string;
  };
}

export interface CommandStatusUpdate {
  type: 'command_status_update';
  command: string;
  args: Record<string, any>;
  status: 'pending' | 'success' | 'error';
  message: string;
  device_id: number;
  command_id?: number;
  timestamp: string;
}

export interface WelcomeMessage {
  type: 'welcome';
  message?: string;
  user_id?: number;
  device_count?: number;
  timestamp?: string;
}

export interface ConfirmSubscriptionMessage {
  type: 'confirm_subscription';
  channel: string;
  user_id: number;
  timestamp: string;
}

export interface SubscriptionErrorMessage {
  type: 'subscription_error';
  message: string;
  timestamp?: string;
}

export interface CommandErrorMessage {
  type: 'command_error';
  command?: string;
  args?: Record<string, any>;
  status: 'error';
  message: string;
  device_id?: number;
  timestamp: string;
}

// Union type that includes all possible message types (NO PING/PONG)
export type WebSocketMessage = 
  | ChartDataUpdate 
  | SensorStatusUpdate 
  | DeviceStatusUpdate 
  | CommandStatusUpdate
  | WelcomeMessage
  | ConfirmSubscriptionMessage
  | SubscriptionErrorMessage
  | CommandErrorMessage;

// Type guards for better type safety
export const isChartDataUpdate = (message: WebSocketMessage): message is ChartDataUpdate => {
  return message.type === 'chart_data_update';
};

export const isSensorStatusUpdate = (message: WebSocketMessage): message is SensorStatusUpdate => {
  return message.type === 'sensor_status_update';
};

export const isDeviceStatusUpdate = (message: WebSocketMessage): message is DeviceStatusUpdate => {
  return message.type === 'device_status_update';
};

export const isCommandStatusUpdate = (message: WebSocketMessage): message is CommandStatusUpdate => {
  return message.type === 'command_status_update';
};

export const isWelcomeMessage = (message: WebSocketMessage): message is WelcomeMessage => {
  return message.type === 'welcome';
};