# frozen_string_literal: true

module ActionView
  module Helpers
    module Tags # :nodoc:
      class DatetimeField < TextField # :nodoc:
        def render
          options = @options.stringify_keys
          options["value"] = datetime_value(options["value"] || value)
          options["min"] = format_datetime(parse_datetime(options["min"]))
          options["max"] = format_datetime(parse_datetime(options["max"]))
          @options = options
          super
        end

        private
          def datetime_value(value)
            if value.is_a?(String)
              value
            else
              format_datetime(value)
            end
          end

          def format_datetime(value)
            raise NotImplementedError
          end

        def calculate_device_status(device)
          # Device status calculation logic
          {
            overall_status: device.status,
            alert_level: device.alert_status,
            last_seen: device.last_connection,
            connection_status: device.last_connection && 
              device.last_connection > 10.minutes.ago ? 'online' : 'offline'
          }
        end
      end
    end
  end
end
