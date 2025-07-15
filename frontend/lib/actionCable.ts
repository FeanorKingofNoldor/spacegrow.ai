// lib/actionCable.ts - CLEANED VERSION
import { createConsumer } from '@rails/actioncable';
import { WebSocketMessage } from '@/types/websocket';

interface ConnectionConfig {
  token?: string;
  userId?: number;
  reconnectAttempts?: number;
  maxReconnectAttempts?: number;
}

class ActionCableManager {
  private consumer: any = null;
  private subscription: any = null;
  private callbacks: Map<string, (data: WebSocketMessage) => void> = new Map();
  private connectionConfig: ConnectionConfig = {};
  private isConnecting = false;
  private reconnectTimeout: NodeJS.Timeout | null = null;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;

  constructor() {
    // Don't initialize consumer in constructor - wait for connect()
  }

  /**
   * Connect to ActionCable with JWT authentication
   */
  connect(userId: number, token?: string): Promise<any> {
    return new Promise((resolve, reject) => {
      if (this.isConnecting) {
        return resolve(this.subscription);
      }

      if (this.subscription) {
        this.disconnect();
      }

      this.isConnecting = true;
      this.connectionConfig = { userId, token };

      try {
        const authToken = token || this.getStoredToken();
        if (!authToken) {
          throw new Error('No authentication token available');
        }

        const wsUrl = this.buildWebSocketUrl(authToken);

        this.consumer = createConsumer(wsUrl);
        this.setupConnectionMonitoring();

        this.subscription = this.consumer.subscriptions.create(
          { channel: 'DeviceChannel' },
          {
            connected: () => {
              this.isConnecting = false;
              this.reconnectAttempts = 0;
              resolve(this.subscription);
            },
            
            disconnected: () => {
              this.isConnecting = false;
              this.handleDisconnection();
            },
            
            rejected: () => {
              this.isConnecting = false;
              reject(new Error('Subscription rejected - check authentication'));
            },
            
            received: (data: WebSocketMessage) => {
              this.handleMessage(data);
            },
            
            send_command: function(command: string, args: Record<string, any>) {
              this.perform('send_command', { command, args });
            }
          }
        );

        // Add connection timeout
        setTimeout(() => {
          if (this.isConnecting) {
            this.isConnecting = false;
            reject(new Error('Connection timeout'));
          }
        }, 10000);

      } catch (error) {
        this.isConnecting = false;
        reject(error);
      }
    });
  }

  /**
   * Build WebSocket URL using environment variable as single source of truth
   */
  private buildWebSocketUrl(token: string): string {
    let baseWsUrl = process.env.NEXT_PUBLIC_WS_URL;
    
    if (!baseWsUrl) {
      const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000';
      const wsProtocol = apiBaseUrl.startsWith('https') ? 'wss:' : 'ws:';
      const urlParts = apiBaseUrl.replace(/^https?:/, '').replace('//', '');
      baseWsUrl = `${wsProtocol}//${urlParts}/cable`;
    }
    
    const url = new URL(baseWsUrl);
    url.searchParams.set('token', token);
    
    return url.toString();
  }

  /**
   * Get stored JWT token
   */
  private getStoredToken(): string | null {
    if (typeof window === 'undefined') return null;
    return localStorage.getItem('auth_token');
  }

  /**
   * Set up connection monitoring
   */
  private setupConnectionMonitoring(): void {
    if (!this.consumer) return;

    this.consumer.connection.monitor.start();
    
    const originalConnectionMonitor = this.consumer.connection.monitor;
    const originalReconnect = originalConnectionMonitor.reconnect;
    
    originalConnectionMonitor.reconnect = () => {
      return originalReconnect.call(originalConnectionMonitor);
    };
  }

  /**
   * Handle incoming messages
   */
  private handleMessage(data: WebSocketMessage): void {
    try {
      const callback = this.callbacks.get(data.type);
      if (callback) {
        callback(data);
      }
      
      const generalCallback = this.callbacks.get('*');
      if (generalCallback) {
        generalCallback(data);
      }
    } catch (error) {
      console.error('Error handling message:', error);
    }
  }

  /**
   * Handle disconnection and reconnection logic
   */
  private handleDisconnection(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      return;
    }

    const delay = Math.min(Math.pow(2, this.reconnectAttempts) * 1000, 30000);
    
    this.reconnectTimeout = setTimeout(() => {
      this.reconnectAttempts++;
      if (this.connectionConfig.userId) {
        this.connect(this.connectionConfig.userId, this.connectionConfig.token)
          .catch(() => {
            // Reconnection failed, will retry if attempts < max
          });
      }
    }, delay);
  }

  /**
   * Disconnect from ActionCable
   */
  disconnect(): void {
    if (this.reconnectTimeout) {
      clearTimeout(this.reconnectTimeout);
      this.reconnectTimeout = null;
    }
    
    if (this.subscription) {
      this.subscription.unsubscribe();
      this.subscription = null;
    }
    
    if (this.consumer) {
      this.consumer.disconnect();
      this.consumer = null;
    }
    
    this.isConnecting = false;
    this.reconnectAttempts = 0;
    this.callbacks.clear();
  }

  /**
   * Register callback for specific message type
   */
  on(messageType: string, callback: (data: WebSocketMessage) => void): void {
    this.callbacks.set(messageType, callback);
  }

  /**
   * Remove callback
   */
  off(messageType: string): void {
    this.callbacks.delete(messageType);
  }

  /**
   * Send command to device
   */
  sendCommand(command: string, args: Record<string, any> = {}): void {
    if (!this.subscription || !this.subscription.send_command) {
      throw new Error('WebSocket not connected or send_command not available');
    }
    
    try {
      this.subscription.send_command(command, args);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Check if connected
   */
  isConnected(): boolean {
    return !!this.subscription && !!this.consumer?.connection?.isOpen();
  }

  /**
   * Get connection state
   */
  getConnectionState(): string {
    if (!this.consumer) return 'disconnected';
    return this.consumer.connection.getState();
  }
}

export const actionCable = new ActionCableManager();