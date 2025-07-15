# app/services/websocket_broadcasting/broadcast_service.rb
module WebsocketBroadcasting
  class BroadcastService < ApplicationService
    # Initializes the service with a device instance.
    # @param device [Device] The device to broadcast updates for
    def initialize(device)
      @device = device
    end

    # ✅ UPDATED: Use throttled broadcasting instead of immediate
    def call
      broadcast_device_status_throttled
      broadcast_dashboard_update_throttled
    end

    private

    attr_reader :device

    # ✅ NEW: Throttled device status broadcasting
    def broadcast_device_status_throttled
      Rails.logger.info "🚀 [BroadcastService] Queuing throttled device status update for device #{device.id}"
      
      # Reload device to ensure latest data from DB
      device.reload

      # Use existing StatusService for comprehensive status data
      device_status = DeviceManagement::StatusService.new(device).call
      
      # Collect sensor data efficiently
      sensor_statuses = device.device_sensors.includes(:sensor_type).map do |sensor|
        {
          sensor_id: sensor.id,
          sensor_type: sensor.sensor_type.name,
          status: sensor.current_status,
          last_updated: sensor.updated_at
        }
      end

      # Create comprehensive status data for batching
      status_data = {
        device_id: device.id,
        device_name: device.name,
        device_status: device.status,
        device_alert_status: device.alert_status,
        last_connection: device.last_connection,
        sensor_statuses: sensor_statuses,
        detailed_status: device_status,
        broadcast_source: 'manual_broadcast_service'
      }

      # Use ThrottledBroadcaster for batched updates
      WebsocketBroadcasting::ThrottledBroadcaster.broadcast_device_status(device.id, status_data)
    end

    # ✅ NEW: Throttled dashboard broadcasting  
    def broadcast_dashboard_update_throttled
      Rails.logger.info "🚀 [BroadcastService] Queuing throttled dashboard update for user #{device.user.id}"
      
      # Use ThrottledBroadcaster for batched dashboard updates
      WebsocketBroadcasting::ThrottledBroadcaster.broadcast_dashboard_update(device.user.id)
    end


    # ✅ EMERGENCY BYPASS: For critical immediate broadcasts (use sparingly)
    def emergency_immediate_broadcast!
      Rails.logger.warn "🚨 [BroadcastService] EMERGENCY immediate broadcast for device #{device.id}"
      
      # Only use for critical system alerts that can't wait for batching
      device.reload
      
      emergency_data = {
        type: 'emergency_alert',
        device_id: device.id,
        device_status: device.status,
        alert_status: device.alert_status,
        timestamp: Time.current.iso8601,
        reason: 'emergency_bypass'
      }
      
      # Direct immediate broadcast (bypasses throttling)
      DeviceChannel.broadcast_to(device, emergency_data)
      DeviceChannel.broadcast_to(device.user, emergency_data)
    end
  end
end