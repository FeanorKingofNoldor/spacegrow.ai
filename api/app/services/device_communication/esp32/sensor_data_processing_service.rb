module DeviceCommunication::Esp32
  class SensorDataProcessingService < ApplicationService
    def initialize(device:, payload:)
      @device = device
      @payload = payload
    end

    def call
      return failure('Invalid payload') unless valid_payload?

      ActiveRecord::Base.transaction do
        process_all_sensors
        @device.update_connection!
      end

      success(message: 'Sensor data processed successfully')
    end

    private

    def valid_payload?
      Esp32::DeviceCommunication::Esp32::PayloadValidationService.call(
        payload: @payload,
        device_type: @device.device_type
      ).success?
    end

    def process_all_sensors
      sensor_mappings = @device.device_type.configuration['supported_sensor_types']

      sensor_mappings.each do |sensor_name, config|
        payload_key = config['payload_key']
        next unless @payload.key?(payload_key)

        process_single_sensor(sensor_name, @payload[payload_key])
      end
    end

    def process_single_sensor(sensor_name, value)
      device_sensor = find_device_sensor(sensor_name)
      return unless device_sensor

      if value.nil?
        handle_missing_reading(device_sensor)
      else
        create_sensor_reading(device_sensor, value)
      end
    end

    def find_device_sensor(sensor_name)
      @device.device_sensors
             .joins(:sensor_type)
             .find_by(sensor_types: { name: sensor_name })
    end

    def create_sensor_reading(device_sensor, value)
      device_sensor.sensor_data.create!(
        value: value,
        timestamp: Time.at(@payload['timestamp'] || Time.current.to_i),
        is_valid: device_sensor.sensor_type.valid_value?(value),
        zone: device_sensor.sensor_type.determine_zone(value)
      )

      device_sensor.update!(consecutive_missing_readings: 0)
      device_sensor.refresh_status!
    end

    def handle_missing_reading(device_sensor)
      device_sensor.increment!(:consecutive_missing_readings)

      if device_sensor.consecutive_missing_readings >= 10
        device_sensor.update!(current_status: 'error')
      elsif device_sensor.consecutive_missing_readings >= 3
        device_sensor.update!(current_status: 'warning')
      end
    end

    def success(data = {})
      { success: true }.merge(data)
    end

    def failure(error)
      { success: false, error: error }
    end
  end
end