# app/channels/device_channel.rb - PRODUCTION READY VERSION
class DeviceChannel < ApplicationCable::Channel
  # ✅ FIXED: Add error handling and connection verification
  before_action :verify_connection
  rescue_from StandardError, with: :handle_channel_error

  def subscribed
    return reject unless current_user
    
    Rails.logger.info "🔍 [DeviceChannel] Subscription attempt for user #{current_user.id}"
    Rails.logger.info "🔍 [DeviceChannel] Params: #{params.inspect}"
    
    begin
      # ✅ FIXED: Send immediate confirmation
      transmit({ 
        type: 'confirm_subscription',
        channel: 'DeviceChannel',
        user_id: current_user.id,
        timestamp: Time.current.iso8601
      })
      
      # Set up streams for the user
      setup_user_streams
      
      Rails.logger.info "✅ [DeviceChannel] User #{current_user.id} subscribed successfully"
      
      # ✅ FIXED: Send welcome message after subscription
      transmit({
        type: 'welcome',
        message: 'Successfully connected to DeviceChannel',
        user_id: current_user.id,
        device_count: current_user.devices.count
      })
      
    rescue StandardError => e
      Rails.logger.error "❌ [DeviceChannel] Subscription failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      transmit({
        type: 'subscription_error',
        message: 'Failed to subscribe to DeviceChannel'
      })
      
      reject
    end
  end

  def send_command(data)
    return unless current_user
    
    begin
      command = data['command']
      args = data['args'] || {}
      device_id = data['device_id'] || params[:device_id]
      
      Rails.logger.info "📤 [DeviceChannel] Command received from user #{current_user.id}: #{command}"
      Rails.logger.info "📤 [DeviceChannel] Args: #{args.inspect}"
      Rails.logger.info "📤 [DeviceChannel] Device ID: #{device_id}"
      
      # ✅ FIXED: Validate device ownership
      device = current_user.devices.find(device_id)
      unless device
        raise StandardError, "Device #{device_id} not found or not owned by user"
      end
      
      # ✅ FIXED: Handle special commands
      case command
      when 'ping'
        handle_ping_command(args)
        return
      when 'health_check'
        handle_health_check_command(device, args)
        return
      end
      
      # ✅ FIXED: Execute command through service
      result = CommandService.new(device).execute(command, args)
      
      if result.success?
        # Send success response
        response_payload = {
          type: "command_status_update",
          command: command,
          args: args,
          status: "pending",
          message: "Command queued successfully",
          device_id: device.id,
          command_id: result.command_id,
          timestamp: Time.current.iso8601
        }
        
        # ✅ FIXED: Broadcast to specific user and device streams
        broadcast_to_user(response_payload)
        broadcast_to_device(device, response_payload)
        
        Rails.logger.info "✅ [DeviceChannel] Command queued for device #{device.id}: #{command}"
        
      else
        # Send error response
        error_payload = {
          type: "command_error",
          command: command,
          args: args,
          status: "error",
          message: result.error || "Command failed",
          device_id: device.id,
          timestamp: Time.current.iso8601
        }
        
        transmit(error_payload)
        Rails.logger.error "❌ [DeviceChannel] Command failed for device #{device.id}: #{result.error}"
      end
      
    rescue ActiveRecord::RecordNotFound => e
      error_payload = {
        type: "command_error",
        message: "Device not found or access denied",
        timestamp: Time.current.iso8601
      }
      transmit(error_payload)
      Rails.logger.error "❌ [DeviceChannel] Device not found: #{e.message}"
      
    rescue StandardError => e
      error_payload = {
        type: "command_error",
        message: "Internal server error",
        timestamp: Time.current.iso8601
      }
      transmit(error_payload)
      Rails.logger.error "❌ [DeviceChannel] Command error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  def unsubscribed
    Rails.logger.info "👋 [DeviceChannel] User #{current_user&.id} unsubscribed"
    stop_all_streams
  end

  # ✅ FIXED: Class methods for broadcasting (called from other parts of the app)
  class << self
    def broadcast_chart_data(device_id, sensor_id, mode: :current)
      Rails.logger.info "📊 [DeviceChannel] Broadcasting chart data for device #{device_id}, sensor #{sensor_id}"
      
      begin
        data_points = ChartDataService.new(sensor_id, mode: mode).fetch_data_points
        
        payload = {
          type: 'chart_data_update',
          chart_id: "chart-#{sensor_id}",
          data_points: data_points,
          title: "Sensor #{sensor_id} Data",
          mode: mode.to_s,
          device_id: device_id,
          timestamp: Time.current.iso8601
        }
        
        # Broadcast to multiple streams for redundancy
        ActionCable.server.broadcast("device_sensor_#{sensor_id}", payload)
        ActionCable.server.broadcast("device_details_charts_#{device_id}", payload)
        
        Rails.logger.info "✅ [DeviceChannel] Chart data broadcasted: #{data_points.size} points"
        
      rescue StandardError => e
        Rails.logger.error "❌ [DeviceChannel] Chart broadcast failed: #{e.message}"
      end
    end

    def broadcast_device_status(device)
      Rails.logger.info "📱 [DeviceChannel] Broadcasting device status for #{device.id}"
      
      begin
        timeout = 10.minutes
        is_online = device.last_connection && device.last_connection > Time.current - timeout
        
        status_class = is_online ? 
          'bg-green-500/10 border-green-500/50' : 
          'bg-red-500/10 border-red-500/50'
        
        payload = {
          type: 'device_status_update',
          data: {
            device_id: device.id,
            last_connection: device.last_connection&.iso8601,
            status_class: status_class,
            is_online: is_online,
            alert_status: device.alert_status,
            status: device.status,
            timestamp: Time.current.iso8601
          }
        }
        
        # Broadcast to device-specific stream
        ActionCable.server.broadcast("device_status_#{device.id}", payload)
        ActionCable.server.broadcast("device_details_status_#{device.id}", payload)
        
        # Also broadcast to device owner
        if device.user
          broadcast_to device.user, payload
        end
        
        Rails.logger.info "✅ [DeviceChannel] Device status broadcasted"
        
      rescue StandardError => e
        Rails.logger.error "❌ [DeviceChannel] Device status broadcast failed: #{e.message}"
      end
    end

    def broadcast_sensor_status(device, sensor_data)
      Rails.logger.info "🔬 [DeviceChannel] Broadcasting sensor status for device #{device.id}"
      
      begin
        payload = {
          type: 'sensor_status_update',
          data: {
            device_id: device.id,
            sensors: sensor_data,
            alert_status: device.alert_status,
            timestamp: Time.current.iso8601
          }
        }
        
        # Broadcast to multiple streams
        ActionCable.server.broadcast("device_sensors_#{device.id}", payload)
        broadcast_to device, payload
        
        if device.user
          broadcast_to device.user, payload
        end
        
        Rails.logger.info "✅ [DeviceChannel] Sensor status broadcasted"
        
      rescue StandardError => e
        Rails.logger.error "❌ [DeviceChannel] Sensor status broadcast failed: #{e.message}"
      end
    end
  end

  private

  def verify_connection
    unless current_user
      Rails.logger.warn "🚨 [DeviceChannel] No current_user found"
      reject
    end
  end

  def handle_channel_error(error)
    Rails.logger.error "❌ [DeviceChannel] Channel error: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    
    transmit({
      type: 'error',
      message: 'Channel error occurred',
      timestamp: Time.current.iso8601
    })
  end

  def setup_user_streams
    # ✅ FIXED: Stream for the user specifically
    stream_for current_user
    
    # ✅ FIXED: Stream for each user's device
    current_user.devices.find_each do |device|
      Rails.logger.info "🔗 [DeviceChannel] Setting up streams for device #{device.id}"
      
      # Device-specific streams
      stream_for device
      stream_from "device_details_status_#{device.id}"
      stream_from "device_details_charts_#{device.id}"
      stream_from "device_status_#{device.id}"
      stream_from "device_sensors_#{device.id}"
      
      # Sensor-specific streams
      device.device_sensors.find_each do |sensor|
        stream_from "device_sensor_#{sensor.id}"
        Rails.logger.debug "🔗 [DeviceChannel] Streaming from device_sensor_#{sensor.id}"
      end
    end
    
    Rails.logger.info "✅ [DeviceChannel] Streams setup complete for #{current_user.devices.count} devices"
  end

  def handle_ping_command(args)
    pong_payload = {
      type: 'pong',
      ping_id: args['ping_id'],
      timestamp: Time.current.iso8601,
      server_time: Time.current.to_f
    }
    
    transmit(pong_payload)
    Rails.logger.info "🏓 [DeviceChannel] Pong sent for ping #{args['ping_id']}"
  end

  def handle_health_check_command(device, args)
    health_payload = {
      type: 'health_check_response',
      device_id: device.id,
      status: 'healthy',
      uptime: Time.current - device.created_at,
      last_connection: device.last_connection,
      timestamp: Time.current.iso8601
    }
    
    transmit(health_payload)
    Rails.logger.info "💓 [DeviceChannel] Health check response sent for device #{device.id}"
  end

  def broadcast_to_user(payload)
    DeviceChannel.broadcast_to(current_user, payload)
  end

  def broadcast_to_device(device, payload)
    DeviceChannel.broadcast_to(device, payload)
  end
end