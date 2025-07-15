# app/controllers/concerns/device_json_handling.rb
module DeviceJsonHandling
  extend ActiveSupport::Concern

  private

  def device_json(device, include_suspension: false)
    json = {
      id: device.id,
      name: device.name,
      status: device.status,
      alert_status: device.alert_status,
      device_type: device.device_type&.name,
      last_connection: device.last_connection,
      created_at: device.created_at,
      updated_at: device.updated_at,
      is_activated: device.active?,
      needs_activation: device.pending?,
      operational: device.operational?,
      suspended: device.suspended?
    }
    
    if include_suspension
      json.merge!({
        suspended_at: device.suspended_at,
        suspended_reason: device.suspended_reason,
        in_grace_period: device.in_grace_period?,
        grace_period_ends_at: device.grace_period_ends_at
      })
    end
    
    json
  end

  def detailed_device_json(device)
    {
      device: device_json(device, include_suspension: true),
      sensor_groups: group_sensors_by_type(device),
      latest_readings: get_latest_readings(device),
      device_status: calculate_device_status(device),
      presets: [],
      profiles: []
    }
  end

  def group_sensors_by_type(device)
    device.device_sensors.includes(:sensor_type).group_by { |sensor| sensor.sensor_type.name }.transform_values do |sensors|
      sensors.map do |sensor|
        {
          id: sensor.id,
          type: sensor.sensor_type.name,
          status: sensor.current_status,
          last_reading: sensor.sensor_data.order(:timestamp).last&.value,
          sensor_type: {
            id: sensor.sensor_type.id,
            name: sensor.sensor_type.name,
            unit: sensor.sensor_type.unit,
            min_value: sensor.sensor_type.min_value,
            max_value: sensor.sensor_type.max_value
          }
        }
      end
    end
  end

  def get_latest_readings(device)
    device.device_sensors.includes(:sensor_data).each_with_object({}) do |sensor, hash|
      latest = sensor.sensor_data.order(:timestamp).last
      hash[sensor.id] = latest&.value
    end
  end

  def calculate_device_status(device)
    {
      overall_status: device.status,
      alert_level: device.alert_status,
      last_seen: device.last_connection,
      connection_status: device.connection_status
    }
  end
end