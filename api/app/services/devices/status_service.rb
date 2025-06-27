# app/services/devices/status_service.rb
module Devices
  class StatusService < ApplicationService
    attr_reader :device

    def initialize(device)
      @device = device
    end

    def call
      Rails.cache.fetch(cache_key, expires_in: 45.seconds) do
        # Use preloaded sensors
        @sensors = device.device_sensors # Preloaded in controller
        {
          operational_status: calculate_operational_status,
          alert_status: update_alert_status!,
          sensor_stats: calculate_sensor_stats,
          last_connection_status: calculate_connection_status
        }
      end
    end

    def detailed_sensor_status
      Rails.cache.fetch(detailed_cache_key, expires_in: 45.seconds) do
        device.device_sensors.map do |sensor|
          {
            id: sensor.id,
            name: sensor.sensor_type.name,
            status: sensor.current_status,
            last_updated: sensor.updated_at
          }
        end
      end
    end

    private

    def cache_key
      ['device-status', device.id, device.updated_at.to_i, device.device_sensors.maximum(:updated_at)&.to_i,
       device.last_connection&.to_i].join('/')
    end

    def detailed_cache_key
      ['detailed-sensor-status', device.id, device.device_sensors.maximum(:updated_at)&.to_i].join('/')
    end

    def calculate_operational_status
      device.status
    end

    def update_alert_status!
      new_status = calculate_alert_status
      device.update!(alert_status: new_status) if device.alert_status != new_status
      new_status
    end

    def calculate_alert_status
      # Use preloaded sensors, avoid pluck
      statuses = @sensors.map(&:current_status).reject { |s| s.nil? || s == 'no_data' }
      return 'error' if statuses.include?('error')
      return 'warning' if statuses.include?('warning')
      return 'ok' if statuses.all? { |s| s == 'ok' } && statuses.any?
      'no_data'
    end

    def calculate_sensor_stats
      # Use preloaded sensors, in-memory counts
      {
        total: @sensors.length,
        error_count: @sensors.count { |s| s.current_status == 'error' },
        warning_count: @sensors.count { |s| s.current_status == 'warning' },
        ok_count: @sensors.count { |s| s.current_status == 'ok' }
      }
    end

    def calculate_connection_status
      return 'never_connected' if device.last_connection.nil?
      hours_since_connection = ((Time.current - device.last_connection) / 1.hour).round
      return 'inactive' if hours_since_connection > 24
      return 'stale' if hours_since_connection > 1
      'active'
    end
  end
end