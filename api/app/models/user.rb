# app/models/user.rb - MERGED VERSION
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

  # ===== ADMIN SCOPES FOR USER MANAGEMENT =====
  
  scope :recent_signups, ->(days = 7) { where(created_at: days.days.ago..Time.current) }
  scope :inactive_users, ->(days = 30) { where(last_sign_in_at: ..days.days.ago) }
  scope :active_subscribers, -> { joins(:subscription).where(subscriptions: { status: 'active' }) }
  scope :past_due_subscribers, -> { joins(:subscription).where(subscriptions: { status: 'past_due' }) }
  scope :canceled_subscribers, -> { joins(:subscription).where(subscriptions: { status: 'canceled' }) }
  scope :no_subscription, -> { left_joins(:subscription).where(subscriptions: { id: nil }) }
  scope :recent_activity, ->(days = 7) { where(last_sign_in_at: days.days.ago..Time.current) }
  scope :with_devices, -> { joins(:devices).distinct }
  scope :without_devices, -> { left_joins(:devices).where(devices: { id: nil }) }

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

  # ✅ UPDATED: Use DeviceManagement::LimitService for complex logic
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

  # ===== ADMIN HELPER METHODS =====
  
  def admin_summary
    {
      id: id,
      email: email,
      display_name: display_name,
      role: role,
      status: admin_status,
      subscription_plan: subscription&.plan&.name,
      device_usage: "#{devices.count}/#{device_limit}",
      total_spent: orders.where(status: 'completed').sum(:total),
      last_activity: last_sign_in_at,
      created_at: created_at,
      risk_factors: admin_risk_factors
    }
  end

  def admin_status
    return 'suspended' if subscription&.past_due? && devices.suspended.any?
    return 'active' if subscription&.active?
    return 'past_due' if subscription&.past_due?
    return 'canceled' if subscription&.canceled?
    'no_subscription'
  end

  def admin_risk_factors
    factors = []
    factors << 'payment_past_due' if subscription&.past_due?
    factors << 'inactive_user' if last_sign_in_at && last_sign_in_at < 30.days.ago
    factors << 'over_device_limit' if devices.count > device_limit
    factors << 'multiple_failed_orders' if orders.where(status: 'payment_failed', created_at: 24.hours.ago..).count >= 3
    factors << 'no_recent_activity' if last_sign_in_at.nil? || last_sign_in_at < 14.days.ago
    factors
  end

  def admin_device_summary
    {
      total: devices.count,
      active: devices.active.count,
      suspended: devices.suspended.count,
      pending: devices.pending.count,
      limit: device_limit,
      utilization_rate: device_limit > 0 ? ((devices.active.count.to_f / device_limit) * 100).round(1) : 0,
      over_limit: devices.count > device_limit
    }
  end

  # ===== CLASS METHODS FOR ADMIN ANALYTICS =====
  
  def self.admin_growth_metrics(period = 'month')
    date_range = case period
                 when 'week' then 1.week.ago..Time.current
                 when 'month' then 1.month.ago..Time.current
                 when 'quarter' then 3.months.ago..Time.current
                 else 1.month.ago..Time.current
                 end
    
    {
      new_signups: where(created_at: date_range).count,
      activated_users: joins(:subscription).where(created_at: date_range).count,
      churned_users: joins(:subscription).where(subscriptions: { status: 'canceled', updated_at: date_range }).count,
      reactivated_users: joins(:subscription).where(subscriptions: { status: 'active', updated_at: date_range }).where.not(subscriptions: { created_at: date_range }).count
    }
  end

  # ===== ADMIN SEARCH METHODS =====
  
  def self.admin_search(query)
    return all if query.blank?
    
    where(
      "email ILIKE ? OR display_name ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ? OR id::text = ?",
      "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", query
    )
  end


  def self.admin_recent_activity_summary
    {
      recent_signups: recent_signups.count,
      recent_logins: recent_activity.count,
      new_subscribers: recent_signups.joins(:subscription).count,
      churn_risk_count: churn_risk.count,
      payment_issues: joins(:orders).where(orders: { status: 'payment_failed', created_at: 24.hours.ago.. }).distinct.count
    }
  end

  private

  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end
end