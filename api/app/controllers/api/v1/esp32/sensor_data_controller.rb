class Api::V1::Esp32::SensorDataController < Api::V1::Esp32::BaseController
  def create
    data = JSON.parse(request.body.read)
    device_type = current_device.device_type
  
    unless valid_payload_format?(data, device_type)
      render json: {
        error: 'Invalid payload format',
        expected_format: device_type.example_payload
      }, status: :unprocessable_entity
      return
    end
  
    begin
      ActiveRecord::Base.transaction do
        process_sensor_data(data)
        current_device.update_connection!
      end
  
      render json: { status: 'success' }, status: :created
  
    rescue JSON::ParserError
      render json: { error: 'Invalid JSON' }, status: :bad_request
    rescue StandardError => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  private

  def valid_payload_format?(data, device_type)
    required_keys = device_type.configuration
                               .dig('supported_sensor_types')
                               &.select { |_, config| config['required'] }
                               &.transform_values { |config| config['payload_key'] }
                               &.values || []
    required_keys.all? { |key| data.key?(key) }
  end

  def process_sensor_data(data)
    device_type = current_device.device_type
    sensor_mappings = device_type.configuration['supported_sensor_types']

    sensor_mappings.each do |sensor_name, config|
      payload_key = config['payload_key']
      next unless data.key?(payload_key)

      process_sensor_reading(
        sensor_name: sensor_name,
        value: data[payload_key],
        timestamp: Time.at(data['timestamp'] || Time.current.to_i)
      )
    end
  end

  def process_sensor_reading(sensor_name:, value:, timestamp:)
    device_sensor = current_device.device_sensors
                                  .joins(:sensor_type)
                                  .find_by(sensor_types: { name: sensor_name })

    return unless device_sensor

    if value.nil?
      handle_missing_data(device_sensor)
      return
    end

    sensor_datum = device_sensor.sensor_data.create!(
      value: value,
      timestamp: timestamp,
      is_valid: device_sensor.sensor_type.valid_value?(value),
      zone: device_sensor.sensor_type.determine_zone(value)
    )

    device_sensor.update!(consecutive_missing_readings: 0)
    device_sensor.refresh_status!

    DeviceChannel.broadcast_chart_data(
      current_device.id,
      device_sensor.id,
      mode: :current
    )
  end

  def handle_missing_data(device_sensor)
    device_sensor.increment!(:consecutive_missing_readings)

    if device_sensor.consecutive_missing_readings >= 10
      device_sensor.update!(current_status: 'error')
    elsif device_sensor.consecutive_missing_readings >= 3
      device_sensor.update!(current_status: 'warning')
    end
  end
end
