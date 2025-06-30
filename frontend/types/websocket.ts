// types/websocket.ts
export interface ChartDataUpdate {
  type: 'chart_data_update';
  chart_id: string;
  data_points: [string, number][]; // [timestamp, value]
  title: string;
  mode: 'current' | 'history_24h' | 'history_7d' | 'history_3m';
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
  };
}

export interface DeviceStatusUpdate {
  type: 'device_status_update';
  data: {
    device_id: number;
    last_connection: string;
    status_class: string;
  };
}

export interface CommandStatusUpdate {
  type: 'command_status_update';
  command: string;
  args: Record<string, any>;
  status: 'pending' | 'success' | 'error';
  message: string;
  device_id: number;
}

export type WebSocketMessage = 
  | ChartDataUpdate 
  | SensorStatusUpdate 
  | DeviceStatusUpdate 
  | CommandStatusUpdate;