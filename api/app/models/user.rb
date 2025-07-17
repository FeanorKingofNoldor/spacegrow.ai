# app/models/user.rb - CLEANED VERSION
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Associations
  has_many :devices, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :orders
  has_many :user_sessions, dependent: :destroy

  # ✅ FIXED: Get the most recent subscription
  has_one :notification_preferences, class_name: 'UserNotificationPreference', dependent: :destroy
  has_one :subscription, -> { order(created_at: :desc) }, class_name: 'Subscription'
  has_one :active_subscription, -> { where(status: 'active').order(created_at: :desc) }, class_name: 'Subscription'
  has_one :plan, through: :subscription

  enum role: {
    user: 0,
    pro: 1,
    enterprise: 2,
    admin: 3
  }

  validates :display_name, 
    length: { maximum: 50 }, 
    format: { with: /\A[a-zA-Z0-9\s\-_.]+\z/, message: "can only contain letters, numbers, spaces, hyphens, underscores, and periods" },
    allow_blank: true

  validates :timezone, inclusion: { 
    in: ActiveSupport::TimeZone.all.map(&:name), 
    message: "must be a valid IANA timezone" 
  }, allow_blank: true

  validates :password, 
    format: { 
      with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}\z/, 
      message: "must be at least 8 characters and include uppercase, lowercase, number, and special character" 
    }, 
    if: :password_required?

  # ✅ KEEP: Simple display methods
  def display_name
    self[:display_name].presence || email.split('@').first.capitalize
  end

  def needs_onboarding?
    active_subscription.nil?
  end
  
  def subscription_blocked?
    subscription&.past_due? || false
  end

  # ✅ KEEP: Simple device query methods
  def pending_devices
    devices.where(status: 'pending')
  end

  def active_devices
    devices.where(status: 'active')
  end

  def disabled_devices
    devices.where(status: 'disabled')
  end

  # ✅ UPDATED: Use DeviceManagement::DeviceManagement::LimitService for complex logic
  def device_limit
    DeviceManagement::LimitService.new(self).device_limit
  end

  def available_device_slots
    DeviceManagement::LimitService.new(self).available_slots
  end

  def can_add_device?
    DeviceManagement::LimitService.new(self).can_add_device?
  end

  def can_activate_device?
    can_add_device? && pending_devices.exists?
  end

  # ✅ KEEP: Simple activation flow method
  def next_device_for_activation
    return nil unless can_activate_device?
    pending_devices.order(:created_at).first
  end

  # ✅ KEEP: Session Management Methods (unchanged)
  def active_sessions
    user_sessions.active.recent
  end
  
  def active_sessions_count
    user_sessions.active.count
  end
  
  def create_session!(jti:, device_info:, ip_address:, expires_at:, is_current: false)
    UserSession.cleanup_expired!
    UserSession.enforce_session_limit!(self, 5)
    
    if is_current
      user_sessions.update_all(is_current: false)
    end
    
    user_sessions.create!(
      jti: jti,
      device_info: device_info,
      ip_address: ip_address,
      expires_at: expires_at,
      is_current: is_current
    )
  end
  
  def find_session(jti)
    user_sessions.find_by(jti: jti)
  end
  
  def logout_session!(jti)
    session = find_session(jti)
    return false unless session
    
    JwtDenylist.create!(
      jti: session.jti,
      exp: session.expires_at
    )
    
    session.destroy!
    true
  end
  
  def logout_all_other_sessions!(current_jti)
    other_sessions = user_sessions.where.not(jti: current_jti)
    
    other_sessions.each do |session|
      JwtDenylist.create!(
        jti: session.jti,
        exp: session.expires_at
      )
    end
    
    other_sessions.destroy_all
  end
  
  def touch_session_activity!(jti)
    session = find_session(jti)
    session&.touch_last_active!
  end
  
  def at_session_limit?
    active_sessions_count >= 5
  end

  def preferences
    notification_preferences || create_notification_preferences!
  end

  def should_receive_email?(category, context = {})
    NotificationManagement::PreferenceService.should_send_email?(self, category, context)
  end

  def should_receive_inapp?(category, context = {})
    NotificationManagement::PreferenceService.should_send_inapp?(self, category, context)
  end

  private

  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end
end