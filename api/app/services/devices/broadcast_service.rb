# Devices::BroadcastService handles broadcasting real-time updates for devices and users.
# It sends WebSocket updates for sensor statuses, device connection statuses, and dashboard data.
module Devices
  class BroadcastService < ApplicationService
    # Initializes the service with a device instance.
    # @param device [Device] The device to broadcast updates for
    def initialize(device)
      @device = device
    end

    # Executes the broadcast process, sending updates to device and user channels.
    def call
      broadcast_to_device
      broadcast_to_user
    end

    private

    attr_reader :device

    # Broadcasts sensor status updates and device connection status to the device-specific channel.
    # Ensures clients receive live sensor data and device name background updates.
    def broadcast_to_device
      # Reload device to ensure latest data from DB
      device.reload

      # Map sensor data for the broadcast payload
      sensors = device.device_sensors.map do |sensor|
        { sensor_id: sensor.id, status: sensor.current_status } # Uses live status instead of cached
      end

      # Construct the sensor status update payload
      sensor_data = {
        device_id: device.id,
        status: device.status,
        alert_status: device.alert_status,
        sensors: sensors
      }

      Rails.logger.info "🚀 Broadcasting WebSocket Update with Live Data: #{sensor_data.inspect}"

      # Broadcast sensor status update to the device channel
      DeviceChannel.broadcast_to(device, { type: 'sensor_status_update', data: sensor_data })

      # Broadcast device connection status (e.g., last_connection for name background)
      DeviceChannel.broadcast_device_status(device)
    end

    # Broadcasts dashboard updates to the user-specific channel.
    # Provides an overview of all devices' statuses for the user’s dashboard.
    def broadcast_to_user
      # Reload user to ensure latest device associations
      device.user.reload

      # Map status data for all user devices
      devices_status = device.user.devices.map do |d|
        {
          device_id: d.id,
          status: d.status,
          alert_status: d.alert_status
        }
      end

      # Construct the dashboard update payload
      dashboard_data = {
        user_id: device.user.id,
        devices: devices_status
      }

      Rails.logger.info "🚀 Broadcasting Dashboard Update: #{dashboard_data.inspect}"

      # Broadcast dashboard update to the user channel
      DeviceChannel.broadcast_to(device.user, { type: 'dashboard_update', data: dashboard_data })
    end

    # Fetches detailed status data for the device using StatusService.
    # @return [Hash] The device status data
    def device_status_data
      Devices::StatusService.call(device)
    end

    # Aggregates status data for all user devices using AggregationService.
    # @return [Hash] The aggregated stats for the user’s devices
    def aggregate_status_data
      Devices::AggregationService.call(device.user.devices)
    end

    # Renders the dashboard stats partial with aggregated data.
    # @return [String] The rendered HTML for the stats partial
    def render_dashboard_stats
      ApplicationController.renderer.render(
        partial: 'dashboard/stats',
        locals: { stats: aggregate_status_data }
      )
    end
  end
end