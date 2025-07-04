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
  before_update :track_status_changes

  # ✅ ENHANCED: Operational Status Scopes (hibernation-aware)
  scope :active, -> { where(status: 'active') }
  scope :pending, -> { where(status: 'pending') }
  scope :disabled, -> { where(status: 'disabled') }
  scope :hibernating, -> { where.not(hibernated_at: nil) }
  scope :operational, -> { active.where(hibernated_at: nil) }  # Active AND not hibernating
  scope :recently_disabled, -> { where(status: 'disabled').where('disabled_at > ?', 1.day.ago) }
  scope :in_grace_period, -> { hibernating.where('grace_period_ends_at > ?', Time.current) }

  # Health/Alert Status Scopes
  scope :with_errors, -> { operational.where(alert_status: 'error') }
  scope :with_warnings, -> { operational.where(alert_status: 'warning') }
  scope :healthy, -> { operational.where(alert_status: 'normal') }

  def valid_command?(command)
    actuators = device_type.configuration['supported_actuators'] || {}
    actuators.values.any? { |config| config['commands'].include?(command) }
  end
  
  def active?
    status == 'active'
  end

  # ✅ NEW: Hibernation status methods
  def hibernating?
    hibernated_at.present?
  end

  def operational?
    active? && !hibernating?
  end

  def in_grace_period?
    hibernating? && grace_period_ends_at.present? && grace_period_ends_at > Time.current
  end

  def grace_period_expired?
    hibernating? && grace_period_ends_at.present? && grace_period_ends_at <= Time.current
  end

  # ✅ NEW: Hibernation management
  def hibernate!(reason: 'subscription_limit', grace_period: 7.days)
    update!(
      hibernated_at: Time.current,
      hibernated_reason: reason,
      grace_period_ends_at: grace_period.from_now
    )
  end

  def wake_up!
    update!(
      hibernated_at: nil,
      hibernated_reason: nil,
      grace_period_ends_at: nil
    )
  end

  def update_connection!
    update(last_connection: Time.current)
  end

  def valid_token?(token)
    activation_token&.token == token && active?
  end

  # ✅ EXISTING: Disability tracking methods (preserved)
  def disabled_by_plan_change?
    disabled_reason == 'plan_change'
  end
  
  def can_be_reactivated?
    status == 'disabled' && user.subscription&.can_add_device?
  end

  def disable_with_reason!(reason)
    update!(
      previous_status: status,
      status: 'disabled',
      disabled_reason: reason,
      disabled_at: Time.current
    )
  end

  def reactivate!
    return false unless can_be_reactivated?
    
    update!(
      status: previous_status || 'active',
      disabled_reason: nil,
      disabled_at: nil,
      previous_status: nil
    )
  end

  # ✅ NEW: Smart device prioritization for hibernation
  def hibernation_priority_score
    score = 0
    
    # Offline devices get higher priority (more likely to be hibernated)
    if last_connection.nil?
      score += 100  # Never connected
    elsif last_connection < 1.week.ago
      score += 80   # Offline for over a week
    elsif last_connection < 1.day.ago
      score += 60   # Offline for over a day
    elsif last_connection < 1.hour.ago
      score += 20   # Recently offline
    end
    
    # Devices with errors are candidates for hibernation
    score += 30 if alert_status == 'error'
    score += 10 if alert_status == 'warning'
    
    # Older devices are more likely to be hibernated
    score += ((Time.current - created_at) / 1.day).to_i
    
    score
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

  # ✅ EXISTING: Track when devices are disabled (preserved)
  def track_status_changes
    if status_changed? && status == 'disabled'
      self.disabled_at = Time.current
      self.previous_status = status_was unless disabled_reason.present?
    elsif status_changed? && status_was == 'disabled'
      # Device is being reactivated
      self.disabled_at = nil
      self.disabled_reason = nil
      self.previous_status = nil
    end
  end
end