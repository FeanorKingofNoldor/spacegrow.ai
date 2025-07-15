# app/models/device_sensor.rb
class DeviceSensor < ApplicationRecord
  belongs_to :device
  belongs_to :sensor_type
  has_many :sensor_data, dependent: :destroy

  validates :device_id, presence: true
  validates :sensor_type_id, presence: true
  validates :current_status, inclusion: { in: %w[normal warning error no_data] }
  validates :consecutive_missing_readings, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # ✅ UPDATED: Use throttled broadcasting when sensor status changes
  after_update_commit :broadcast_sensor_status_throttled, if: :saved_change_to_current_status?

  def refresh_status!
    Rails.logger.info "🔍 [DeviceSensor##{id}] Refreshing status"
    
    new_status = calculate_status
    Rails.logger.info "🔍 [DeviceSensor##{id}] Determined status: #{new_status}"
    
    # Update status without triggering callbacks if unchanged
    if current_status != new_status
      Rails.logger.info "🔍 [DeviceSensor##{id}] Status changing from #{current_status} to #{new_status}"
      update!(current_status: new_status)
      # Callback will handle throttled broadcast
    else
      Rails.logger.info "🔍 [DeviceSensor##{id}] Status unchanged (#{current_status}), no broadcast needed"
    end
    
    Rails.logger.info "🔍 [DeviceSensor##{id}] Status refreshed"
  end

  def calculate_status(preloaded_reading: nil)
    Rails.logger.info "🔍 [DeviceSensor##{id}] Determining status"
    Rails.logger.info "🔍 [DeviceSensor##{id}] Entering calculate_status with preloaded_data: #{preloaded_reading ? 'provided' : 'none'}"

    reading = preloaded_reading || last_reading
    
    if reading.nil?
      Rails.logger.info "🔍 [DeviceSensor##{id}] No readings found, status: no_data"
      return 'no_data'
    end

    Rails.logger.info "🔍 [DeviceSensor##{id}] Last reading: #{reading.inspect}"

    # Check recent zones for status determination
    recent_zones = sensor_data.order(timestamp: :desc)
                             .limit(3)
                             .pluck(:zone)

    Rails.logger.info "🔍 [DeviceSensor##{id}] Recent zones: #{recent_zones}"

    status = determine_status_from_zones(recent_zones)
    Rails.logger.info "🔍 [DeviceSensor##{id}] Status determined: #{status}"
    
    status
  end

  def last_reading
    @last_reading ||= sensor_data.order(timestamp: :desc).first
    Rails.logger.info "🔍 [DeviceSensor##{id}] Last reading fetched: #{@last_reading&.id}"
    @last_reading
  end

  def current_status_with_preloaded_reading(reading = nil)
    Rails.logger.info "🔍 [DeviceSensor##{id}] Calculating current_status with preloaded_reading: #{reading ? 'provided' : 'none'}"
    calculate_status(preloaded_reading: reading)
  end

  private

  # ✅ NEW: Throttled broadcasting method
  def broadcast_sensor_status_throttled
    Rails.logger.info "🔬 [DeviceSensor##{id}] Status changed to #{current_status}, queuing throttled broadcast"
    
    # Collect all sensor statuses for this device (more efficient than N+1)
    all_sensor_statuses = device.device_sensors.pluck(:id, :current_status).map do |sensor_id, status|
      {
        sensor_id: sensor_id,
        status: status
      }
    end
    
    # Create comprehensive status data for batching
    status_data = {
      device_id: device.id,
      device_status: device.status,
      device_alert_status: device.alert_status,
      sensor_statuses: all_sensor_statuses,
      changed_sensor: {
        sensor_id: id,
        old_status: current_status_before_last_save,
        new_status: current_status,
        sensor_type: sensor_type.name
      },
      last_connection: device.last_connection
    }
    
    # Use ThrottledBroadcaster for batched device status updates
    WebsocketBroadcasting::ThrottledBroadcaster.broadcast_device_status(device.id, status_data)
  end

  def determine_status_from_zones(zones)
    return 'no_data' if zones.empty?

    # If any error zones in recent readings, status is error
    return 'error' if zones.any? { |zone| zone&.start_with?('error') }
    
    # If any warning zones, status is warning  
    return 'warning' if zones.any? { |zone| zone&.start_with?('warning') }
    
    # Otherwise normal
    'normal'
  end
end