// lib/actionCable.ts
import { createConsumer } from '@rails/actioncable';
import { WebSocketMessage } from '@/types/websocket';

class ActionCableManager {
  private consumer: any;
  private subscription: any;
  private callbacks: Map<string, (data: WebSocketMessage) => void> = new Map();

  constructor() {
    // Initialize ActionCable consumer
    this.consumer = createConsumer('/cable');
  }

  connect(userId: number) {
    if (this.subscription) {
      this.disconnect();
    }

    this.subscription = this.consumer.subscriptions.create(
      { channel: 'DeviceChannel' },
      {
        connected: () => {
          console.log('🔌 Connected to DeviceChannel');
        },
        
        disconnected: () => {
          console.log('🔌 Disconnected from DeviceChannel');
        },
        
        received: (data: WebSocketMessage) => {
          console.log('📨 Received WebSocket message:', data);
          
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
        },
        
        send_command: (command: string, args: Record<string, any>) => {
          console.log('📤 Sending command:', command, args);
          this.subscription.perform('send_command', { command, args });
        }
      }
    );

    return this.subscription;
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe();
      this.subscription = null;
    }
  }

  // Register callback for specific message type
  on(messageType: string, callback: (data: WebSocketMessage) => void) {
    this.callbacks.set(messageType, callback);
  }

  // Remove callback
  off(messageType: string) {
    this.callbacks.delete(messageType);
  }

  // Send command to device
  sendCommand(command: string, args: Record<string, any> = {}) {
    if (this.subscription && this.subscription.send_command) {
      this.subscription.send_command(command, args);
    } else {
      console.error('❌ WebSocket not connected or send_command not available');
    }
  }
}

export const actionCable = new ActionCableManager();