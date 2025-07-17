module DeviceCommunication::Esp32
  class PayloadValidationService < ApplicationService
    def initialize(payload:, device_type:)
      @payload = payload
      @device_type = device_type
    end

    def call
      required_keys = @device_type.configuration
                                 .dig('supported_sensor_types')
                                 &.select { |_, config| config['required'] }
                                 &.transform_values { |config| config['payload_key'] }
                                 &.values || []

      if required_keys.all? { |key| @payload.key?(key) }
        success(message: 'Valid payload')
      else
        missing_keys = required_keys - @payload.keys
        failure("Missing required keys: #{missing_keys.join(', ')}")
      end
    end

    private

    def success(data = {})
      { success: true }.merge(data)
    end

    def failure(error)
      { success: false, error: error }
    end
  end
end