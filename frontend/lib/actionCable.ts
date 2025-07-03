// lib/actionCable.ts - PRODUCTION READY VERSION
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
        console.log('🔌 Connection already in progress');
        return resolve(this.subscription);
      }

      if (this.subscription) {
        console.log('🔌 Already connected, disconnecting first');
        this.disconnect();
      }

      this.isConnecting = true;
      this.connectionConfig = { userId, token };

      try {
        // ✅ FIXED: Get JWT token from localStorage if not provided
        const authToken = token || this.getStoredToken();
        if (!authToken) {
          throw new Error('No authentication token available');
        }

        // ✅ FIXED: Build WebSocket URL with JWT token
        const wsUrl = this.buildWebSocketUrl(authToken);
        console.log('🔌 Connecting to ActionCable with token authentication');

        // ✅ FIXED: Create consumer with proper URL and token
        this.consumer = createConsumer(wsUrl);

        // ✅ FIXED: Set up connection monitoring
        this.setupConnectionMonitoring();

        this.subscription = this.consumer.subscriptions.create(
          { channel: 'DeviceChannel' },
          {
            connected: () => {
              console.log('✅ Connected to DeviceChannel');
              this.isConnecting = false;
              this.reconnectAttempts = 0;
              resolve(this.subscription);
            },
            
            disconnected: () => {
              console.log('🔌 Disconnected from DeviceChannel');
              this.isConnecting = false;
              this.handleDisconnection();
            },
            
            rejected: () => {
              console.error('❌ DeviceChannel subscription rejected');
              this.isConnecting = false;
              reject(new Error('Subscription rejected - check authentication'));
            },
            
            received: (data: WebSocketMessage) => {
              console.log('📨 Received WebSocket message:', data);
              this.handleMessage(data);
            },
            
            // ✅ FIXED: Proper command sending method
            send_command: function(command: string, args: Record<string, any>) {
              console.log('📤 Sending command:', command, args);
              this.perform('send_command', { command, args });
            }
          }
        );

        // ✅ FIXED: Add connection timeout
        setTimeout(() => {
          if (this.isConnecting) {
            this.isConnecting = false;
            reject(new Error('Connection timeout'));
          }
        }, 10000);

      } catch (error) {
        this.isConnecting = false;
        console.error('❌ Failed to connect to ActionCable:', error);
        reject(error);
      }
    });
  }

  /**
   * Build WebSocket URL with authentication
   */
  private buildWebSocketUrl(token: string): string {
    // ✅ FIXED: Proper environment-based URL construction
    const protocol = typeof window !== 'undefined' && window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = typeof window !== 'undefined' ? window.location.host : 'localhost:3000';
    
    // Use environment variable or construct from current location
    const baseUrl = process.env.NEXT_PUBLIC_WS_URL || `${protocol}//${host}`;
    const cableUrl = baseUrl.endsWith('/cable') ? baseUrl : `${baseUrl}/cable`;
    
    // ✅ FIXED: Add JWT token as query parameter
    const url = new URL(cableUrl);
    url.searchParams.set('token', token);
    
    console.log('🔗 WebSocket URL:', url.toString().replace(token, '[TOKEN]'));
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

    // Monitor connection state
    this.consumer.connection.monitor.start();
    
    // ✅ FIXED: Handle connection events
    const originalConnectionMonitor = this.consumer.connection.monitor;
    const originalReconnect = originalConnectionMonitor.reconnect;
    
    originalConnectionMonitor.reconnect = () => {
      console.log('🔄 ActionCable attempting reconnection...');
      return originalReconnect.call(originalConnectionMonitor);
    };
  }

  /**
   * Handle incoming messages
   */
  private handleMessage(data: WebSocketMessage): void {
    try {
      // Call registered callbacks based on message type
      const callback = this.callbacks.get(data.type);
      if (callback) {
        callback(data);
      }
      
      // Call general callback if registered
      const generalCallback = this.callbacks.get('*');
      if (generalCallback) {
        generalCallback(data);
      }
    } catch (error) {
      console.error('❌ Error handling message:', error);
    }
  }

  /**
   * Handle disconnection and reconnection logic
   */
  private handleDisconnection(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.error('❌ Max reconnection attempts reached');
      return;
    }

    // ✅ FIXED: Exponential backoff for reconnection
    const delay = Math.min(Math.pow(2, this.reconnectAttempts) * 1000, 30000);
    console.log(`🔄 Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts + 1}/${this.maxReconnectAttempts})`);
    
    this.reconnectTimeout = setTimeout(() => {
      this.reconnectAttempts++;
      if (this.connectionConfig.userId) {
        this.connect(this.connectionConfig.userId, this.connectionConfig.token)
          .catch(error => {
            console.error('❌ Reconnection failed:', error);
          });
      }
    }, delay);
  }

  /**
   * Disconnect from ActionCable
   */
  disconnect(): void {
    console.log('🔌 Disconnecting from ActionCable');
    
    // Clear reconnection timeout
    if (this.reconnectTimeout) {
      clearTimeout(this.reconnectTimeout);
      this.reconnectTimeout = null;
    }
    
    // Unsubscribe and disconnect
    if (this.subscription) {
      this.subscription.unsubscribe();
      this.subscription = null;
    }
    
    if (this.consumer) {
      this.consumer.disconnect();
      this.consumer = null;
    }
    
    // Reset state
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
      console.error('❌ Failed to send command:', error);
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

  /**
   * Health check - send ping and wait for pong
   */
  async healthCheck(): Promise<boolean> {
    if (!this.isConnected()) return false;

    return new Promise((resolve) => {
      const pingId = Date.now().toString();
      const timeout = setTimeout(() => resolve(false), 5000);
      
      // Listen for pong response
      const originalCallback = this.callbacks.get('pong');
      this.callbacks.set('pong', (message: any) => {
        if (originalCallback) originalCallback(message);
        if (message.ping_id === pingId) {
          clearTimeout(timeout);
          resolve(true);
        }
      });
      
      // Send ping
      try {
        this.sendCommand('ping', { ping_id: pingId });
      } catch (error) {
        clearTimeout(timeout);
        resolve(false);
      }
    });
  }
}

// ✅ FIXED: Export singleton instance
export const actionCable = new ActionCableManager();