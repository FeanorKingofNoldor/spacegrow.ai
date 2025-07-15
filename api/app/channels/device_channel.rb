# app/channels/device_channel.rb
class DeviceChannel < ApplicationCable::Channel
  def subscribed
    Rails.logger.info "🔗 [DeviceChannel] User #{current_user&.id} subscribing to device channel"
    
    if current_user
      setup_consolidated_user_streams
      Rails.logger.info "🔗 [DeviceChannel] User #{current_user.id} subscribed to #{stream_count} consolidated streams"
    else
      Rails.logger.warn "🔗 [DeviceChannel] No authenticated user found, rejecting subscription"
      reject
    end
  end

  def unsubscribed
    Rails.logger.info "🔗 [DeviceChannel] User #{current_user&.id} unsubscribed from device channel"
  end

  # ✅ NEW: Consolidated stream setup (5 streams instead of 33+)
  def setup_consolidated_user_streams
    user_id = current_user.id
    
    # Stream 1: Main user stream (for batched updates from ThrottledBroadcaster)
    stream_for current_user
    Rails.logger.debug "📡 [DeviceChannel] Subscribed to main user stream"
    
    # Stream 2: All user devices (consolidated device updates)
    stream_from "user_devices_#{user_id}"
    Rails.logger.debug "📡 [DeviceChannel] Subscribed to user devices stream"
    
    # Stream 3: All user sensors (consolidated sensor updates)  
    stream_from "user_sensors_#{user_id}"
    Rails.logger.debug "📡 [DeviceChannel] Subscribed to user sensors stream"
    
    # Stream 4: Dashboard updates (aggregated stats)
    stream_from "user_dashboard_#{user_id}" 
    Rails.logger.debug "📡 [DeviceChannel] Subscribed to user dashboard stream"
    
    # Stream 5: System alerts and notifications
    stream_from "user_alerts_#{user_id}"
    Rails.logger.debug "📡 [DeviceChannel] Subscribed to user alerts stream"
  end

  # ✅ UPDATED: Consolidated broadcasting methods work with new streams
  class << self
    
    # Main method - routes all broadcasts through ThrottledBroadcaster
    def broadcast_to_user_consolidated(user, data)
      Rails.logger.info "📡 [DeviceChannel] Broadcasting consolidated data to user #{user.id}"
      
      # Use main user stream (Stream 1) for batched updates
      broadcast_to(user, data)
    end

    # Legacy compatibility methods - now route through consolidated streams
    def broadcast_chart_data(device_id, sensor_id, mode: :current)
      Rails.logger.debug "📊 [DeviceChannel] Legacy chart broadcast redirected to ThrottledBroadcaster"
      
      # Instead of immediate broadcast, queue in ThrottledBroadcaster
      device_sensor = DeviceSensor.find(sensor_id)
      data_point = ChartDataService.new(sensor_id, mode: mode).fetch_data_points.last
      
      if data_point
        WebsocketBroadcasting::ThrottledBroadcaster.broadcast_sensor_data(sensor_id, {
          chart_id: "chart-#{sensor_id}",
          data_point: data_point,
          mode: mode,
          timestamp: Time.current.iso8601
        })
      end
    end

    def broadcast_sensor_status(device, sensor_data)
      Rails.logger.debug "🔬 [DeviceChannel] Legacy sensor status broadcast redirected to ThrottledBroadcaster"
      
      # Route through ThrottledBroadcaster instead of immediate broadcast
      WebsocketBroadcasting::ThrottledBroadcaster.broadcast_device_status(device.id, {
        device_id: device.id,
        sensor_statuses: sensor_data,
        broadcast_source: 'legacy_sensor_status'
      })
    end

    def broadcast_device_status(device)
      Rails.logger.debug "📱 [DeviceChannel] Legacy device status broadcast redirected to ThrottledBroadcaster"
      
      # Route through ThrottledBroadcaster instead of immediate broadcast  
      WebsocketBroadcasting::ThrottledBroadcaster.broadcast_device_status(device.id, {
        device_id: device.id,
        device_status: device.status,
        device_alert_status: device.alert_status,
        last_connection: device.last_connection,
        broadcast_source: 'legacy_device_status'
      })
    end

    # ✅ NEW: Direct consolidated broadcasting methods
    def broadcast_to_user_devices(user_id, device_data)
      ActionCable.server.broadcast("user_devices_#{user_id}", {
        type: 'device_update',
        data: device_data,
        timestamp: Time.current.iso8601
      })
    end

    def broadcast_to_user_sensors(user_id, sensor_data)
      ActionCable.server.broadcast("user_sensors_#{user_id}", {
        type: 'sensor_update', 
        data: sensor_data,
        timestamp: Time.current.iso8601
      })
    end

    def broadcast_to_user_dashboard(user_id, dashboard_data)
      ActionCable.server.broadcast("user_dashboard_#{user_id}", {
        type: 'dashboard_update',
        data: dashboard_data, 
        timestamp: Time.current.iso8601
      })
    end

    def broadcast_to_user_alerts(user_id, alert_data)
      ActionCable.server.broadcast("user_alerts_#{user_id}", {
        type: 'alert',
        data: alert_data,
        timestamp: Time.current.iso8601,
        priority: alert_data[:priority] || 'normal'
      })
    end
  end

  private

  def stream_count
    5 # Always 5 consolidated streams
  end
end