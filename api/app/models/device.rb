# app/models/device.rb
class Device < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :user, counter_cache: true
  belongs_to :device_type
  belongs_to :activation_token, class_name: 'DeviceActivationToken', optional: true
  belongs_to :order, optional: true
  belongs_to :current_preset, class_name: 'Preset', optional: true
  has_many :device_sensors, dependent: :destroy
  has_many :sensor_types, through: :device_sensors
  has_many :presets, dependent: :destroy
  has_many :command_logs, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :status, inclusion: { in: %w[pending active disabled] }
  validate :validate_sensor_types
  validate :activation_token_valid, on: :create

  # Callbacks
  after_create :provision_sensors
  before_destroy :handle_activation_token

  # Operational Status Scopes
  scope :active, -> { where(status: 'active') }
  scope :pending, -> { where(status: 'pending') }
  scope :disabled, -> { where(status: 'disabled') }

  # Health/Alert Status Scopes
  scope :with_errors, -> { active.where(alert_status: 'error') }
  scope :with_warnings, -> { active.where(alert_status: 'warning') }
  scope :healthy, -> { active.where(alert_status: 'normal') }

  def valid_command?(command)
    actuators = device_type.configuration['supported_actuators'] || {}
    actuators.values.any? { |config| config['commands'].include?(command) }
  end
  
  def active?
    status == 'active'
  end

  def update_connection!
    update(last_connection: Time.current)
  end

  def valid_token?(token)
    activation_token&.token == token && active?
  end

  private

  def handle_activation_token
    activation_token&.destroy
  end

  def provision_sensors
    device_type.required_sensor_types.each do |sensor_type|
      device_sensors.create!(sensor_type: sensor_type)
    end
  end

  def validate_sensor_types
    return unless device_type

    invalid_sensors = sensor_types - device_type.supported_sensor_types
    if invalid_sensors.any?
      errors.add(:base, "Device type #{device_type.name} does not support sensors: #{invalid_sensors.map(&:name).join(', ')}")
    end
  end

  def activation_token_valid
    return unless activation_token
    return if activation_token.valid_for_activation?(device_type)
    
    errors.add(:activation_token, "is invalid or expired")
  end
end