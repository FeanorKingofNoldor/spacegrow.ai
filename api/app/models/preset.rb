# app/models/preset.rb
class Preset < ApplicationRecord
  belongs_to :device_type
  belongs_to :user, optional: true
  belongs_to :device, optional: true

  validates :name, presence: true
  validates :settings, presence: true
  validates :device_type_id, presence: true

  # Ensure unique names per device type and user
  validates :name, uniqueness: { 
    scope: [:device_type_id, :user_id, :device_id],
    message: 'A preset with this name already exists for this device type'
  }

  # Scopes
  scope :predefined, -> { where(user_id: nil, is_user_defined: false) }
  scope :user_defined, -> { where(is_user_defined: true) }
  scope :for_device_type, ->(device_type) { where(device_type: device_type) }
  scope :for_user, ->(user) { where(user: user) }

  # ✅ NEW: Method to format settings for frontend display
  def formatted_settings
    return {} unless settings.present?
    
    case device_type.name
    when 'Environmental Monitor V1'
      format_environmental_settings
    when 'Liquid Monitor V1'
      format_liquid_monitor_settings
    else
      settings
    end
  end

  # ✅ NEW: Check if preset can be edited by user
  def editable_by?(user)
    return false unless user
    is_user_defined? && user_id == user.id
  end

  # ✅ NEW: Check if preset can be deleted by user
  def deletable_by?(user)
    editable_by?(user)
  end

  # ✅ NEW: Get display summary of settings
  def settings_summary
    case device_type.name
    when 'Environmental Monitor V1'
      environmental_summary
    when 'Liquid Monitor V1'
      liquid_monitor_summary
    else
      'Custom configuration'
    end
  end

  private

  # ✅ NEW: Format Environmental Monitor settings
  def format_environmental_settings
    formatted = {}
    
    if settings['lights'].present?
      formatted[:lights] = {
        on_at: settings['lights']['on_at'] || '08:00hrs',
        off_at: settings['lights']['off_at'] || '20:00hrs',
        display: "#{settings['lights']['on_at']} - #{settings['lights']['off_at']}"
      }
    end
    
    if settings['spray'].present?
      formatted[:spray] = {
        on_for: settings['spray']['on_for'] || 10,
        off_for: settings['spray']['off_for'] || 30,
        display: "#{settings['spray']['on_for']}s on, #{settings['spray']['off_for']}s off"
      }
    end
    
    formatted
  end

  # ✅ NEW: Format Liquid Monitor settings
  def format_liquid_monitor_settings
    formatted = {}
    active_pumps = []
    
    (1..5).each do |i|
      pump_key = "pump#{i}"
      if settings[pump_key].present? && settings[pump_key]['duration'].to_i > 0
        duration = settings[pump_key]['duration'].to_i
        formatted["pump#{i}".to_sym] = {
          duration: duration,
          display: "#{duration}s"
        }
        active_pumps << "Pump #{i}: #{duration}s"
      end
    end
    
    formatted[:summary] = active_pumps.any? ? active_pumps.join(', ') : 'No pumps configured'
    formatted
  end

  # ✅ NEW: Environmental Monitor summary
  def environmental_summary
    parts = []
    
    if settings['lights'].present?
      parts << "Lights: #{settings['lights']['on_at']} - #{settings['lights']['off_at']}"
    end
    
    if settings['spray'].present?
      parts << "Spray: #{settings['spray']['on_for']}s on, #{settings['spray']['off_for']}s off"
    end
    
    parts.any? ? parts.join(' • ') : 'No configuration'
  end

  # ✅ NEW: Liquid Monitor summary
  def liquid_monitor_summary
    active_pumps = []
    
    (1..5).each do |i|
      pump_key = "pump#{i}"
      if settings[pump_key].present? && settings[pump_key]['duration'].to_i > 0
        active_pumps << "Pump #{i}: #{settings[pump_key]['duration']}s"
      end
    end
    
    active_pumps.any? ? active_pumps.join(', ') : 'No pumps configured'
  end
end