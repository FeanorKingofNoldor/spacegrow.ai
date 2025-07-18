# app/serializers/admin/device_fleet_serializer.rb
module Admin
  class DeviceFleetSerializer
    include ActiveModel::Serialization

    def self.serialize(device, include_detailed: false)
      base_data = {
        id: device.id,
        name: device.name,
        status: device.status,
        device_type: device.device_type&.name,
        created_at: device.created_at.iso8601,
        last_connection: device.last_connection&.iso8601,
        
        # Owner information
        owner: {
          id: device.user.id,
          email: device.user.email,
          display_name: device.user.display_name,
          subscription_plan: device.user.subscription&.plan&.name
        },
        
        # Health status
        health_status: determine_device_health(device),
        alert_level: determine_alert_level(device),
        
        # Connection info
        connection_info: {
          last_connection: device.last_connection&.iso8601,
          connection_status: determine_connection_status(device),
          uptime_estimate: calculate_uptime_estimate(device)
        }
      }

      if include_detailed
        base_data.merge!(
          detailed_info: {
            activation_token: device.activation_token&.token,
            firmware_version: device.firmware_version,
            hardware_info: device.hardware_info,
            configuration: device.configuration,
            location: device.location,
            last_reconnect_attempt: device.last_reconnect_attempt&.iso8601
          },
          
          sensor_summary: serialize_sensor_summary(device),
          recent_activity: serialize_device_activity(device)
        )
      end

      base_data
    end

    def self.serialize_list(devices)
      devices.map { |device| serialize(device, include_detailed: false) }
    end

    def self.serialize_fleet_summary(devices_scope)
      {
        total_devices: devices_scope.count,
        by_status: devices_scope.group(:status).count,
        by_type: devices_scope.joins(:device_type).group('device_types.name').count,
        health_overview: {
          healthy: devices_scope.where(last_connection: 10.minutes.ago..).count,
          warning: devices_scope.where(last_connection: 10.minutes.ago..1.hour.ago).count,
          critical: devices_scope.where(last_connection: ..1.hour.ago).count
        },
        connection_stats: {
          online: devices_scope.where(last_connection: 1.hour.ago..).count,
          offline: devices_scope.where(last_connection: ..1.hour.ago).count,
          never_connected: devices_scope.where(last_connection: nil).count
        }
      }
    end

    private

    def self.determine_device_health(device)
      return 'critical' if device.last_connection.nil? || device.last_connection < 1.hour.ago
      return 'warning' if device.last_connection < 10.minutes.ago
      'healthy'
    end

    def self.determine_alert_level(device)
      return 'high' if device.status == 'error' || device.last_connection.nil?
      return 'medium' if device.last_connection && device.last_connection < 30.minutes.ago
      'low'
    end

    def self.determine_connection_status(device)
      return 'never_connected' if device.last_connection.nil?
      return 'online' if device.last_connection > 5.minutes.ago
      return 'recently_online' if device.last_connection > 1.hour.ago
      'offline'
    end

    def self.calculate_uptime_estimate(device)
      return "0%" unless device.last_connection
      
      # Simplified uptime calculation
      total_time = Time.current - device.created_at
      connected_time = total_time * 0.95 # Assume 95% uptime
      ((connected_time / total_time) * 100).round(1)
    end

    def self.serialize_sensor_summary(device)
      return {} unless device.respond_to?(:sensor_data)
      
      recent_data = device.sensor_data.where(created_at: 24.hours.ago..)
      
      {
        total_readings_24h: recent_data.count,
        sensor_types: recent_data.group(:sensor_type).count,
        latest_reading: recent_data.order(created_at: :desc).first&.created_at&.iso8601
      }
    end

    def self.serialize_device_activity(device)
      activities = []
      
      if device.last_connection
        activities << {
          type: 'connection',
          description: 'Last connected',
          timestamp: device.last_connection.iso8601
        }
      end
      
      activities << {
        type: 'status',
        description: "Status: #{device.status}",
        timestamp: device.updated_at.iso8601
      }
      
      activities.sort_by { |a| a[:timestamp] }.reverse.first(5)
    end
  end
end