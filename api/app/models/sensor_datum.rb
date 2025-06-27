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

  # Automatically broadcast chart updates when new sensor data is created
  after_create_commit :broadcast_chart_update

  # Index zone for better filtering
  after_initialize do
    ActiveRecord::Base.connection.execute(<<~SQL) unless ActiveRecord::Base.connection.index_exists?(:sensor_data, [:device_sensor_id, :zone])
      CREATE INDEX IF NOT EXISTS index_sensor_data_on_device_sensor_and_zone 
      ON sensor_data (device_sensor_id, zone);
    SQL
  end

  private

  def assign_status_and_zone
    self.zone = sensor_type.determine_zone(value)
  end

  def broadcast_chart_update
    DeviceChannel.broadcast_chart_data(device_sensor.device.id, device_sensor.id)
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
