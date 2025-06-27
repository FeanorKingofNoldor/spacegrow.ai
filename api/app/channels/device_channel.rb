# app/channels/device_channel.rb
class DeviceChannel < ApplicationCable::Channel
  def subscribed
    Rails.logger.info "🔍 [DeviceChannel] Subscription attempt with params: #{params.inspect}"
    return unless current_user

    Rails.logger.info "🔍 [DeviceChannel] Subscribing user #{current_user.id} at #{Time.now.iso8601}"
    stream_for current_user
    current_user.devices.each do |device|
      Rails.logger.info "🔍 [DeviceChannel] Setting up streams for device #{device.id}"
      stream_for device
      stream_from "device_details_status_#{device.id}"
      stream_from "device_details_charts_#{device.id}"
      device.device_sensors.each do |sensor|
        stream_from "device_sensor_#{sensor.id}"
        Rails.logger.info "🔍 [DeviceChannel] Streaming from device_sensor_#{sensor.id}"
      end
    end
  end

  def send_command(data)
    command = data['command']
    args = data['args'] || {}
    device = current_user.devices.find(params[:device_id])
    Rails.logger.info "Received command via ActionCable for device #{device.id}: #{command} with args #{args}"
    result = CommandService.new(device).execute(command, args)
    if result.success?
      payload = {
        type: "command_status_update",
        command: command,
        args: args,
        status: "pending",
        message: "Command queued",
        device_id: device.id
      }
      ActionCable.server.broadcast("device:Z2lkOi8veHNwYWNlZ3Jvdy9EZXZpY2Uv#{device.id}", payload)
    else
      Rails.logger.error "Failed to queue command for device #{device.id}: #{command} - #{result.error}"
    end
  end

  def self.broadcast_chart_data(device_id, sensor_id, mode: :current)
    Rails.logger.info "🔍 [DeviceChannel] Preparing chart data broadcast for device #{device_id}, sensor #{sensor_id}, mode: #{mode}"
    data_points = ChartDataService.new(sensor_id, mode: mode).fetch_data_points
    payload = {
      type: 'chart_data_update',
      chart_id: "chart-#{sensor_id}",
      data_points: data_points,
      title: "Sensor Data for Device #{device_id}",
      mode: mode
    }
    Rails.logger.info "🔍 [DeviceChannel] Broadcasting to device_sensor_#{sensor_id}: #{payload.inspect}"
    broadcast_to "device_sensor_#{sensor_id}", payload
    Rails.logger.info "✅ Broadcasted chart_data_update for chart-#{sensor_id}: #{data_points.inspect}"
  end

  def self.broadcast_device_status(device)
    timeout = 10.minutes
    status_class = if device.last_connection && device.last_connection > Time.now - timeout
                     'bg-green-500/10 border-green-500/50'
                   else
                     'bg-red-500/10 border-red-500/50'
                   end
    payload = {
      type: 'device_status_update',
      data: {
        device_id: device.id,
        last_connection: device.last_connection&.iso8601,
        status_class: status_class
      }
    }
    Rails.logger.info "🔍 [DeviceChannel] Broadcasting device_status_update: #{payload.inspect}"
    broadcast_to device, payload
  end

  def unsubscribed
    Rails.logger.info "🔍 [DeviceChannel] Unsubscribing user #{current_user&.id} at #{Time.now.iso8601}"
    stop_all_streams
  end
end