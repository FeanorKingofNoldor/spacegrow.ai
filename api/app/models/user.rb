# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Associations
  has_many :devices, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :orders

  # ✅ FIXED: Get the most recent subscription
  has_one :subscription, -> { order(created_at: :desc) }, class_name: 'Subscription'
  has_one :active_subscription, -> { where(status: 'active').order(created_at: :desc) }, class_name: 'Subscription'
  has_one :plan, through: :subscription

  enum role: {
    user: 0,
    pro: 1,
    admin: 2
  }

  validates :timezone, inclusion: { 
    in: ActiveSupport::TimeZone.all.map(&:name), 
    message: "must be a valid IANA timezone" 
  }, allow_blank: true

  def display_name
    email.split('@').first.capitalize
  end

  # ✅ FIXED: Device management respects activation flow
  def device_limit
    return Float::INFINITY if admin?
    
    if active_subscription&.active?
      active_subscription.device_limit
    else
      case role.to_sym
      when :pro then 10
      else 2
      end
    end
  end

  def available_device_slots
    return Float::INFINITY if admin?
    # ✅ FIXED: Count only ACTIVE devices against limit
    active_devices = devices.where(status: 'active').count
    [device_limit - active_devices, 0].max
  end

  def can_add_device?
    return true if admin?
    # ✅ FIXED: Check against active devices, not total devices
    active_devices = devices.where(status: 'active').count
    active_devices < device_limit
  end
  
  def needs_onboarding?
    active_subscription.nil?
  end
  
  def subscription_blocked?
    subscription&.past_due? || false
  end

  # ✅ NEW: Helper methods for device activation flow
  def pending_devices
    devices.where(status: 'pending')
  end

  def active_devices
    devices.where(status: 'active')
  end

  def disabled_devices
    devices.where(status: 'disabled')
  end

  # ✅ NEW: Check if user can activate more devices
  def can_activate_device?
    can_add_device? && pending_devices.exists?
  end

  # ✅ NEW: Get next device that can be activated
  def next_device_for_activation
    return nil unless can_activate_device?
    pending_devices.order(:created_at).first
  end
end