module DeviceConfiguration
  class PresetValidationService < ApplicationService
    def initialize(settings, device_type)
      @settings = settings
      @device_type = device_type
    end

    def call
      errors = []
      warnings = []
      
      case @device_type.name
      when 'Environmental Monitor V1'
        errors.concat(validate_environmental_settings)
      when 'Liquid Monitor V1'
        errors.concat(validate_liquid_monitor_settings)
      else
        warnings << "Unknown device type: #{@device_type.name}"
      end
      
      OpenStruct.new(
        valid?: errors.empty?,
        errors: errors,
        warnings: warnings
      )
    end

    private

    def validate_environmental_settings
      errors = []
      
      # Validate lights
      if @settings['lights'].present?
        errors.concat(validate_lights_settings(@settings['lights']))
      end
      
      # Validate spray
      if @settings['spray'].present?
        errors.concat(validate_spray_settings(@settings['spray']))
      end
      
      errors
    end

    def validate_lights_settings(lights)
      errors = []
      
      if lights['on_at'].present? && lights['off_at'].present?
        begin
          on_time = Time.parse(lights['on_at'].gsub('hrs', ''))
          off_time = Time.parse(lights['off_at'].gsub('hrs', ''))
          
          if on_time >= off_time
            errors << build_error('lights', 'Lights on time must be before lights off time', 'INVALID_TIME_RANGE')
          end
        rescue ArgumentError
          errors << build_error('lights', 'Invalid time format. Use HH:MMhrs format', 'INVALID_TIME_FORMAT')
        end
      end
      
      errors
    end

    def validate_spray_settings(spray)
      errors = []
      
      if spray['on_for'].present? && spray['on_for'].to_i <= 0
        errors << build_error('spray.on_for', 'Spray on duration must be greater than 0', 'INVALID_DURATION')
      end
      
      if spray['off_for'].present? && spray['off_for'].to_i <= 0
        errors << build_error('spray.off_for', 'Spray off duration must be greater than 0', 'INVALID_DURATION')
      end
      
      errors
    end

    def validate_liquid_monitor_settings
      errors = []
      active_pumps = 0
      
      (1..5).each do |i|
        pump_key = "pump#{i}"
        if @settings[pump_key].present?
          duration = @settings[pump_key]['duration'].to_i
          if duration > 0
            active_pumps += 1
            if duration > 300 # 5 minutes max
              errors << build_error(
                "#{pump_key}.duration",
                "Pump #{i} duration cannot exceed 300 seconds",
                'DURATION_TOO_LONG'
              )
            end
          end
        end
      end
      
      if active_pumps == 0
        errors << build_error('pumps', 'At least one pump must have a duration greater than 0', 'NO_ACTIVE_PUMPS')
      end
      
      errors
    end

    def build_error(field, message, code)
      {
        field: field,
        message: message,
        code: code
      }
    end
  end
end