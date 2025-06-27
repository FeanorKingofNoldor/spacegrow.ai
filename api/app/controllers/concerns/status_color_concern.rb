# app/concerns/status_color_concern.rb
module StatusColorConcern
  extend ActiveSupport::Concern

  def device_background_class(device)
    color_class(device.alert_status)
  end

  def color_class(status)
    case status
    when 'error_low', 'error_high', 'error_out_of_range', 'error' # Device alert_status might use 'error'
      'bg-red-800/10 border-red-800/50'
    when 'warning_low', 'warning_high', 'warning' # Device alert_status might use 'warning'
      'bg-orange-800/10 border-orange-800/50'
    when 'normal', 'ok' # Device alert_status might use 'ok'
      'bg-green-800/10 border-green-800/50'
    when 'no_data', nil
      'bg-gray-800/10 border-gray-800/50'
    else
      'bg-gray-800/10 border-gray-800/50'
    end
  end

  def text_class(status)
    case status
    when 'error_low', 'error_high', 'error_out_of_range', 'error'
      'text-red-400'
    when 'warning_low', 'warning_high', 'warning'
      'text-orange-400'
    when 'normal', 'ok'
      'text-green-400'
    when 'no_data', nil
      'text-gray-400'
    else
      'text-gray-400'
    end
  end

  def status_message(status)
    case status
    when 'error_low', 'error_high', 'error_out_of_range', 'error'
      'Critical sensor errors detected'
    when 'warning_low'
      'Sensors below normal range'
    when 'warning_high'
      'Sensors above normal range'
    when 'warning'
      'Sensors showing warnings'
    when 'normal', 'ok'
      'Operating normally'
    when 'no_data', nil
      'No sensor data available'
    else
      'Unknown status'
    end
  end
end