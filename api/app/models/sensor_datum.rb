# app/models/sensor_datum.rb
class SensorDatum < ApplicationRecord
  belongs_to :device_sensor
  has_one :sensor_type, through: :device_sensor
  has_one :device, through: :device_sensor

  validates :timestamp, presence: true
  validates :value, presence: true, numericality: true
  validate :value_within_sensor_range
  validate :timestamp_not_in_future

  # Existing scopes
  scope :recent, -> { order(timestamp: :desc) }
  scope :last_24_hours, -> { where('timestamp > ?', 24.hours.ago) }
  scope :valid_readings, -> { where(is_valid: true) }

  # New scopes
  scope :last_n_readings, ->(n) { order(timestamp: :desc).limit(n) }
  scope :since, ->(time) { where('timestamp > ?', time) }
  scope :between, ->(start_time, end_time) { where(timestamp: start_time..end_time) }
  scope :by_zone, ->(zone) { where(zone: zone) }

  # Automatically assign status and zone before saving
  before_save :assign_status_and_zone

  # ✅ UPDATED: Use ThrottledBroadcaster instead of immediate broadcasting
  after_create_commit :broadcast_chart_update_throttled

  private

  def assign_status_and_zone
    self.zone = sensor_type.determine_zone(value)
  end

  # ✅ NEW: Throttled broadcasting method
  def broadcast_chart_update_throttled
    Rails.logger.info "📊 [SensorDatum##{id}] Queuing throttled broadcast for device #{device.id}, sensor #{device_sensor.id}"
    
    # Create data point for batching
    data_point = {
      sensor_id: device_sensor.id,
      value: value,
      timestamp: timestamp.iso8601,
      zone: zone,
      is_valid: is_valid
    }
    
    # Use ThrottledBroadcaster for batched updates
    WebsocketBroadcasting::ThrottledBroadcaster.broadcast_sensor_data(device_sensor.id, data_point)
  end

  def value_within_sensor_range
    return unless sensor_type

    unless sensor_type.valid_value?(value)
      errors.add(:value, "must be between #{sensor_type.min_value} and #{sensor_type.max_value} #{sensor_type.unit}")
    end
  end

  def timestamp_not_in_future
    return unless timestamp.present? && timestamp > Time.current
    errors.add(:timestamp, "can't be in the future")
  end
end