# app/models/device_type.rb
class DeviceType < ApplicationRecord
  # Associations
  has_many :devices
  has_many :products # For shop integration
  has_many :presets, dependent: :destroy  # Link to Preset model


  # Validations
  validates :name, presence: true, uniqueness: true
  validates :configuration, presence: true
  validate :validate_configuration_schema

  # Class methods for name sets
  DEVICE_NAMES = {
    'Environmental Monitor V1' => %w[Sol Titan Elbereth Celeste Aurora Calypsos Elysium VulcanVenus Earth Mars
                                     Jupiter Saturn Uranus Neptune Pluto],
    'Liquid Monitor V1' => %w[Atlantic Pacific Indian Arctic Andaman Bering Mediterranean Baltic Caribbean]
  }

  def self.available_name_for(type_name, user)
    available_names = DEVICE_NAMES[type_name] || []
    taken_names = user.devices.where(device_type: DeviceType.find_by(name: type_name)).pluck(:name)
    available_names - taken_names
  end

  def self.suggested_name_for(type_name, user)
    available_name_for(type_name, user).first || "Device #{user.devices.count + 1}"
  end

  # Instance methods for sensor management
  def supported_sensor_types
    SensorType.where(name: configuration.dig('supported_sensor_types')&.keys || [])
  end

  def required_sensor_types
    names = configuration.dig('supported_sensor_types')&.select { |_, v| v['required'] }&.keys || []
    SensorType.where(name: names)
  end

  def supports_sensor_type?(sensor_type)
    supported_sensor_types.include?(sensor_type)
  end

  # API payload handling
  def payload_key_for_sensor(sensor_type)
    configuration.dig('supported_sensor_types', sensor_type.name, 'payload_key')
  end

  def example_payload
    configuration['payload_example'] || generate_example_payload
  end

  private

  def validate_configuration_schema
    return if valid_configuration_format?

    errors.add(:configuration, 'must include supported_sensor_types')
  end

  def valid_configuration_format?
    return false unless configuration.is_a?(Hash)
    return false unless configuration['supported_sensor_types'].is_a?(Hash)

    configuration['supported_sensor_types'].all? do |_, config|
      config.is_a?(Hash) &&
        config.key?('required') &&
        config.key?('payload_key')
    end
  end

  def generate_example_payload
    supported = configuration['supported_sensor_types'] || {}
    supported.transform_values do |config|
      generate_example_value(config['payload_key'])
    end
  end

  def generate_example_value(key)
    case key
    when /temp/i then 23.5
    when /hum/i then 85.0
    when /press/i then 1013.25
    when /ph/i then 5.0
    when /ec/i then 2.5
    else 0.0
    end
  end
end
