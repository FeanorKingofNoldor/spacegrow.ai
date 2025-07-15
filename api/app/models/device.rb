# app/models/device.rb
class Device < ApplicationRecord
  include Suspendable  # ✅ NEW: Extract suspension logic to concern

  belongs_to :user
  belongs_to :order, optional: true
  belongs_to :device_type
  belongs_to :activation_token, class_name: 'DeviceActivationToken', optional: true
  belongs_to :current_preset, class_name: 'Preset', optional: true
  
  has_many :device_sensors, dependent: :destroy
  has_many :sensor_data, through: :device_sensors
  has_many :sensor_types, through: :device_sensors
  has_many :presets, dependent: :destroy
  has_many :command_logs, dependent: :destroy
  has_many :subscription_devices, dependent: :destroy
  has_many :subscriptions, through: :subscription_devices

  validates :name, presence: true, length: { maximum: 255 }
  validates :uuid, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending active suspended disabled] }
  validates :alert_status, inclusion: { in: %w[no_data normal warning error] }

  # Callbacks
  after_initialize :set_defaults, if: :new_record?
  before_create :generate_uuid, :generate_api_key
  after_update :validate_sensor_types, if: :saved_change_to_device_type_id?
  
  # ✅ UPDATED: Use throttled broadcasting for connection status changes
  after_update_commit :broadcast_connection_status_throttled, 
                     if: :saved_change_to_last_connection?

  # ✅ KEEP: Device-specific methods
  def update_connection!
    Rails.logger.info "🔗 [Device##{id}] Updating connection timestamp"
    update!(last_connection: Time.current)
  end

  def is_online?
    timeout = 10.minutes
    last_connection && last_connection > Time.current - timeout
  end

  def connection_status
    is_online? ? 'online' : 'offline'
  end

  def status_class
    is_online? ? 
      'bg-green-500/10 border-green-500/50' : 
      'bg-red-500/10 border-red-500/50'
  end

  def generate_api_key!
    self.api_key = SecureRandom.hex(32)
    save!
  end

  # ✅ KEEP: Status checking methods (now also defined in concern)
  def pending?
    status == 'pending'
  end

  def active?
    status == 'active'
  end

  def disabled?
    status == 'disabled'
  end

  # ✅ NEW: Disable/enable methods
  def disable!(reason: 'Manual disable')
    update!(
      status: 'disabled',
      disabled_at: Time.current,
      disabled_reason: reason,
      previous_status: status_was
    )
  end

  def enable!
    new_status = previous_status == 'suspended' ? 'suspended' : 'active'
    update!(
      status: new_status,
      disabled_at: nil,
      disabled_reason: nil,
      previous_status: nil
    )
  end

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def generate_api_key
    self.api_key ||= SecureRandom.hex(32)
  end

  def set_defaults
    self.alert_status ||= 'no_data'
    self.status ||= 'pending'
    self.uuid ||= SecureRandom.uuid
    self.api_key ||= SecureRandom.hex(32)
  end

  def validate_sensor_types
    required_types = device_type.configuration.dig('supported_sensor_types')&.keys || []
    current_types = device_sensors.joins(:sensor_type).pluck('sensor_types.name')
    
    missing_types = required_types - current_types
    extra_types = current_types - required_types
    
    if missing_types.any?
      errors.add(:device_sensors, "Missing required sensor types: #{missing_types.join(', ')}")
    end
    
    if extra_types.any?
      errors.add(:device_sensors, "Unexpected sensor types: #{extra_types.join(', ')}")
    end
  end

  # ✅ NEW: Throttled connection status broadcasting
  def broadcast_connection_status_throttled
    Rails.logger.info "📱 [Device##{id}] Connection status changed, queuing throttled broadcast"
    
    # Create connection status data for batching
    connection_data = {
      device_id: id,
      device_name: name,
      last_connection: last_connection,
      connection_status: connection_status,
      is_online: is_online?,
      device_status: status,
      alert_status: alert_status,
      change_type: 'connection_status_change',
      previous_connection: last_connection_before_last_save
    }
    
    # Use ThrottledBroadcaster for batched device status updates
    WebsocketBroadcasting::ThrottledBroadcaster.broadcast_device_status(id, connection_data)
    
    # Also queue dashboard update for the user
    WebsocketBroadcasting::ThrottledBroadcaster.broadcast_dashboard_update(user.id)
  end
end