class DeviceSensor < ApplicationRecord
  # Constants for status checks
  CONSECUTIVE_READINGS_THRESHOLD = 3
  READING_TIMEOUT = 10.minutes

  # Define possible statuses
  STATUSES = {
    ok: 'ok',
    warning: 'warning',
    error: 'error',
    no_data: 'no_data'
  }.freeze

  # Relationships
  belongs_to :device
  belongs_to :sensor_type
  has_many :sensor_data, dependent: :destroy

  # Validations
  validates :device_id, uniqueness: { scope: :sensor_type_id }

  # Callbacks
  after_commit :broadcast_update, on: [:update]
  after_save :update_device_alert_status

  # Public methods
  def current_status(preloaded_reading = nil)
    Rails.logger.info "🔍 [DeviceSensor##{id}] Calculating current_status with preloaded_reading: #{preloaded_reading&.id || 'none'}"
    status = last_reading_zone(preloaded_reading) || STATUSES[:no_data]
    Rails.logger.info "🔍 [DeviceSensor##{id}] Current_status result: #{status}"
    status
  end

  def value_zone(preloaded_reading = nil)
    Rails.logger.info "🔍 [DeviceSensor##{id}] Fetching value_zone"
    zone = last_reading_zone(preloaded_reading)
    Rails.logger.info "🔍 [DeviceSensor##{id}] Value_zone result: #{zone}"
    zone
  end

  def last_reading_value(preloaded_reading = nil)
    value = last_reading(preloaded_reading)&.value
    Rails.logger.info "🔍 [DeviceSensor##{id}] Last reading value: #{value}"
    value
  end

  def last_reading_timestamp(preloaded_reading = nil)
    timestamp = last_reading(preloaded_reading)&.timestamp
    Rails.logger.info "🔍 [DeviceSensor##{id}] Last reading timestamp: #{timestamp}"
    timestamp
  end

  def last_reading_zone(preloaded_reading = nil)
    reading = last_reading(preloaded_reading)
    zone = reading&.zone
    Rails.logger.info "🔍 [DeviceSensor##{id}] Last reading zone: #{zone || 'none'} (reading ID: #{reading&.id || 'none'})"
    zone
  end

  def readings_exist?(preloaded_data = nil)
    exists = preloaded_data ? preloaded_data.any? : sensor_data.recent.exists?
    Rails.logger.info "🔍 [DeviceSensor##{id}] Readings exist? #{exists}"
    exists
  end

  def refresh_status!
    Rails.logger.info "🔍 [DeviceSensor##{id}] Refreshing status"
    update!(current_status: determine_status)
    Rails.logger.info "🔍 [DeviceSensor##{id}] Status refreshed"
  end

  def determine_status(preloaded_data = nil)
    Rails.logger.info "🔍 [DeviceSensor##{id}] Determining status"
    status = calculate_status(preloaded_data)
    Rails.logger.info "🔍 [DeviceSensor##{id}] Determined status: #{status}"
    status
  end

  private

  def last_reading(preloaded_reading = nil)
    reading = preloaded_reading || sensor_data.recent.limit(1).take
    Rails.logger.info "🔍 [DeviceSensor##{id}] Last reading fetched: #{reading&.id || 'none'}"
    reading
  end

  def calculate_status(preloaded_data = nil)
    Rails.logger.info "🔍 [DeviceSensor##{id}] Entering calculate_status with preloaded_data: #{preloaded_data&.map(&:id) || 'none'}"
    Rails.logger.info "🔍 [DeviceSensor##{id}] Last reading value: #{last_reading_value(preloaded_data).inspect}"

    last_reading = last_reading(preloaded_data)
    Rails.logger.info "🔍 [DeviceSensor##{id}] Last reading: #{last_reading&.inspect || 'none'}"

    if last_reading.nil?
      Rails.logger.error "❌ [DeviceSensor##{id}] Last reading is NIL"
      return STATUSES[:no_data]
    end

    if last_reading.timestamp < READING_TIMEOUT.ago
      Rails.logger.warn "⚠️ [DeviceSensor##{id}] Last reading timestamp #{last_reading.timestamp} is older than #{READING_TIMEOUT} ago"
      return STATUSES[:no_data]
    end

    recent_zones = preloaded_data ? preloaded_data.sort_by(&:timestamp).last(CONSECUTIVE_READINGS_THRESHOLD).map(&:zone) : sensor_data.recent.limit(CONSECUTIVE_READINGS_THRESHOLD).pluck(:zone)
    Rails.logger.info "🔍 [DeviceSensor##{id}] Recent zones: #{recent_zones.inspect}"

    if recent_zones.any? { |z| %w[error_low error_high].include?(z) }
      Rails.logger.info "🔍 [DeviceSensor##{id}] Status determined: error"
      return STATUSES[:error]
    elsif recent_zones.any? { |z| %w[warning_low warning_high].include?(z) }
      Rails.logger.info "🔍 [DeviceSensor##{id}] Status determined: warning"
      return STATUSES[:warning]
    else
      Rails.logger.info "🔍 [DeviceSensor##{id}] Status determined: ok"
      return STATUSES[:ok]
    end
  end

  def broadcast_update
    Rails.logger.info "🔍 [DeviceSensor##{id}] Broadcasting update for device #{device.id}"
    Devices::BroadcastService.call(device)
  end

  def update_device_alert_status
    Rails.logger.info "🔍 [DeviceSensor##{id}] Updating device alert status"
    Devices::StatusService.new(device).call
  end
end