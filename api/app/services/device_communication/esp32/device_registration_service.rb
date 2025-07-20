# app/services/device_communication/esp32/device_registration_service.rb - REFACTORED
module DeviceCommunication::Esp32
  class DeviceRegistrationService < ApplicationService
    def initialize(token:)
      @token = token
    end

    def call
      begin
        validate_token
        prepare_registration_data
        
        Rails.logger.info "Device registration validated for token: #{@token}"
        
        success(
          token: @activation_token.token,
          device_type: serialize_device_type(@activation_token.device_type),
          commands: generate_initial_commands,
          registration_info: {
            expires_at: @activation_token.expires_at.iso8601,
            order_id: @activation_token.order_id,
            user_email: @activation_token.order.user.email
          },
          message: "Registration token validated successfully"
        )
      rescue => e
        Rails.logger.error "Device registration failed: #{e.message}"
        failure("Device registration failed: #{e.message}")
      end
    end

    private

    attr_reader :token

    def validate_token
      @activation_token = DeviceActivationToken.find_by(token: token)
      
      unless @activation_token
        raise StandardError, 'Invalid activation token'
      end
      
      if @activation_token.used?
        raise StandardError, 'Token already used - device already activated'
      end
      
      if @activation_token.expired?
        raise StandardError, 'Token expired - please request a new activation token'
      end
    end

    def prepare_registration_data
      # Prepare any additional data needed for device registration
      @device_type = @activation_token.device_type
      @user = @activation_token.order.user
    end

    def serialize_device_type(device_type)
      {
        id: device_type.id,
        name: device_type.name,
        model: device_type.model,
        version: device_type.version,
        supported_sensors: device_type.supported_sensor_types,
        default_settings: device_type.default_settings || {},
        firmware_version: device_type.latest_firmware_version
      }
    end

    def generate_initial_commands
      commands = []
      
      # Add device type specific initialization commands
      case @device_type.name
      when 'Environmental Monitor V1'
        commands.concat(environmental_monitor_commands)
      when 'Liquid Monitor V1'
        commands.concat(liquid_monitor_commands)
      else
        commands.concat(generic_device_commands)
      end
      
      commands
    end

    def environmental_monitor_commands
      [
        {
          command: 'SET_DEVICE_ID',
          value: @activation_token.token,
          description: 'Set unique device identifier'
        },
        {
          command: 'INIT_SENSORS',
          value: 'temperature,humidity,pressure',
          description: 'Initialize environmental sensors'
        },
        {
          command: 'SET_REPORTING_INTERVAL',
          value: 300, # 5 minutes
          description: 'Set sensor data reporting interval in seconds'
        },
        {
          command: 'ENABLE_WIFI_CONFIG',
          value: true,
          description: 'Enable WiFi configuration mode'
        }
      ]
    end

    def liquid_monitor_commands
      [
        {
          command: 'SET_DEVICE_ID',
          value: @activation_token.token,
          description: 'Set unique device identifier'
        },
        {
          command: 'INIT_PUMPS',
          value: 'pump1,pump2,pump3,pump4,pump5',
          description: 'Initialize liquid pumps'
        },
        {
          command: 'INIT_SENSORS',
          value: 'ph,ec,temperature',
          description: 'Initialize liquid monitoring sensors'
        },
        {
          command: 'SET_REPORTING_INTERVAL',
          value: 600, # 10 minutes
          description: 'Set sensor data reporting interval in seconds'
        },
        {
          command: 'CALIBRATE_SENSORS',
          value: true,
          description: 'Start sensor calibration sequence'
        }
      ]
    end

    def generic_device_commands
      [
        {
          command: 'SET_DEVICE_ID',
          value: @activation_token.token,
          description: 'Set unique device identifier'
        },
        {
          command: 'SET_REPORTING_INTERVAL',
          value: 300,
          description: 'Set default reporting interval'
        },
        {
          command: 'ENABLE_WIFI_CONFIG',
          value: true,
          description: 'Enable WiFi configuration'
        }
      ]
    end
  end
end