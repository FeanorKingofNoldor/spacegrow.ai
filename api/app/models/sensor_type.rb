class SensorType < ApplicationRecord
  has_many :device_sensors
  has_many :devices, through: :device_sensors

  validates :name, presence: true, uniqueness: true
  validates :unit, presence: true
  validates :min_value, :max_value, presence: true
  validates :error_low_min, :error_low_max,
            :warning_low_min, :warning_low_max,
            :normal_min, :normal_max,
            :warning_high_min, :warning_high_max,
            :error_high_min, :error_high_max,
            presence: true

  TYPES = {
    temperature: {
      name: 'Temperature Sensor',
      unit: '°C',
      min_value: 0,
      max_value: 100,
      error_low_min: 0,
      error_low_max: 11,
      warning_low_min: 12,
      warning_low_max: 15,
      normal_min: 16,
      normal_max: 22,
      warning_high_min: 23,
      warning_high_max: 30,
      error_high_min: 31,
      error_high_max: 40
    },
    humidity: {
      name: 'Humidity Sensor',
      unit: '%',
      min_value: 0,
      max_value: 100,
      error_low_min: 0,
      error_low_max: 39,
      warning_low_min: 40,
      warning_low_max: 59,
      normal_min: 60,
      normal_max: 99,
      warning_high_min: 80,
      warning_high_max: 90,
      error_high_min: 91,
      error_high_max: 100
    },
    pressure: {
      name: 'Pressure Sensor',
      unit: 'bar',
      min_value: 0,
      max_value: 11,
      error_low_min: 0,
      error_low_max: 3,
      warning_low_min: 4,
      warning_low_max: 5,
      normal_min: 6,
      normal_max: 8,
      warning_high_min: 8.1,
      warning_high_max: 9,
      error_high_min: 10,
      error_high_max: 11
    },
    ph: {
      name: 'pH Sensor',
      unit: 'pH',
      min_value: 0,
      max_value: 14,
      error_low_min: 0.0,
      error_low_max: 4.9,
      warning_low_min: 5.0,
      warning_low_max: 5.9,
      normal_min: 6.0,
      normal_max: 7.5,
      warning_high_min: 7.6,
      warning_high_max: 8.4,
      error_high_min: 8.5,
      error_high_max: 14
    },
    ec: {
      name: 'EC Sensor',
      unit: 'mS/cm',
      min_value: 0,
      max_value: 10,
      error_low_min: 0.0,
      error_low_max: 0.8,
      warning_low_min: 0.8,
      warning_low_max: 1.1,
      normal_min: 1.2,
      normal_max: 2.8,
      warning_high_min: 2.5,
      warning_high_max: 3.0,
      error_high_min: 3.1,
      error_high_max: 10
    }
  }.freeze

  def self.seed_defaults!
    TYPES.each do |_key, config|
      find_or_create_by!(name: config[:name]) do |st|
        st.unit = config[:unit]
        st.min_value = config[:min_value]
        st.max_value = config[:max_value]
        st.error_low_min = config[:error_low_min]
        st.error_low_max = config[:error_low_max]
        st.warning_low_min = config[:warning_low_min]
        st.warning_low_max = config[:warning_low_max]
        st.normal_min = config[:normal_min]
        st.normal_max = config[:normal_max]
        st.warning_high_min = config[:warning_high_min]
        st.warning_high_max = config[:warning_high_max]
        st.error_high_min = config[:error_high_min]
        st.error_high_max = config[:error_high_max]
      end
    end
  end

  def determine_zone(value)
    return :error_low if value.between?(error_low_min, error_low_max)
    return :warning_low if value.between?(warning_low_min, warning_low_max)
    return :normal if value.between?(normal_min, normal_max)
    return :warning_high if value.between?(warning_high_min, warning_high_max)
    return :error_high if value.between?(error_high_min, error_high_max)

    :error_out_of_range
  end

  def valid_value?(value)
    value.between?(min_value, max_value)
  end

  def normal_value?(value)
    value.between?(normal_min, normal_max)
  end

  def warning_value?(value)
    value.between?(warning_low_min, warning_low_max) ||
      value.between?(warning_high_min, warning_high_max)
  end

  def error_value?(value)
    value.between?(error_low_min, error_low_max) ||
      value.between?(error_high_min, error_high_max) ||
      !valid_value?(value)
  end
end
