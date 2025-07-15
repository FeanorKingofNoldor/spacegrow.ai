# app/services/devices/aggregation_service.rb
module DeviceManagement
  class AggregationService < ApplicationService
    attr_reader :devices

    def initialize(devices)
      @devices = devices
    end

    def call
      Rails.logger.info "Starting cache fetch"
      start_cache = Time.now
      result = Rails.cache.fetch(cache_key, expires_in: 30.seconds) do
        Rails.logger.info "Cache miss, calculating stats"
        start_stats = Time.now
        stats = {
          operational_stats: calculate_operational_stats,
          alert_stats: calculate_alert_stats,
          connection_stats: calculate_connection_stats,
          sensor_stats: calculate_sensor_stats
        }
        Rails.logger.info "Finished stats calc: #{Time.now - start_stats}s"
        stats
      end
      Rails.logger.info "Finished cache fetch: #{Time.now - start_cache}s"
      result
    end

    private

    def cache_key
      device_max = devices.maximum(:updated_at)&.to_i
      sensor_max = devices.joins(:device_sensors).maximum('device_sensors.updated_at')&.to_i
      ["device-aggregation", device_max, sensor_max].join("/")
    end

    def calculate_operational_stats
      counts = devices.group(:status).count
      {
        total: counts.values.sum,
        active: counts["active"] || 0,
        pending: counts["pending"] || 0,
        disabled: counts["disabled"] || 0
      }
    end

    def calculate_alert_stats
      counts = devices.where(status: "active").group(:alert_status).count
      {
        error: counts["error"] || 0,
        warning: counts["warning"] || 0,
        healthy: counts["normal"] || 0
      }
    end

    def calculate_connection_stats
      # Preload devices and count in-memory to respect limit
      loaded_devices = devices.to_a # Convert relation to array with limit applied
      {
        connected_24h: loaded_devices.count { |d| d.last_connection && d.last_connection > 24.hours.ago },
        connected_1h: loaded_devices.count { |d| d.last_connection && d.last_connection > 1.hour.ago },
        never_connected: loaded_devices.count { |d| d.last_connection.nil? }
      }
    end

    def calculate_sensor_stats
      sensor_data = devices.joins(:device_sensors)
                           .group("device_sensors.current_status")
                           .count("device_sensors.id")
      {
        total_sensors: sensor_data.values.sum,
        error_sensors: sensor_data["error"] || 0,
        warning_sensors: sensor_data["warning"] || 0,
        ok_sensors: sensor_data["ok"] || 0
      }
    end
  end
end