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
  scope :high_value_customers, -> { joins(:orders).where(orders: { status: 'completed' }).group('users.id').having('SUM(orders.total) > ?', 500) }
  scope :recent_activity, ->(days = 7) { where(last_sign_in_at: days.days.ago..Time.current) }
  scope :churn_risk, -> { past_due_subscribers.or(inactive_users(30)) }
  scope :by_plan, ->(plan_name) { joins(subscription: :plan).where(plans: { name: plan_name }) }
  scope :with_devices, -> { joins(:devices).distinct }
  scope :without_devices, -> { left_joins(:devices).where(devices: { id: nil }) }
  scope :over_device_limit, -> { joins(:devices, :subscription).group('users.id, subscriptions.id, plans.device_limit').having('COUNT(devices.id) > plans.device_limit') }

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

  def admin_financial_summary
    completed_orders = orders.where(status: 'completed')
    
    {
      total_orders: orders.count,
      completed_orders: completed_orders.count,
      total_spent: completed_orders.sum(:total),
      average_order_value: completed_orders.average(:total)&.round(2) || 0,
      failed_payments: orders.where(status: 'payment_failed').count,
      monthly_recurring_revenue: subscription&.monthly_cost || 0,
      last_order: orders.order(created_at: :desc).first&.created_at
    }
  end

  def admin_subscription_history
    subscriptions.includes(:plan).order(created_at: :desc).map do |sub|
      {
        id: sub.id,
        plan_name: sub.plan&.name,
        status: sub.status,
        created_at: sub.created_at,
        updated_at: sub.updated_at,
        monthly_cost: sub.monthly_cost
      }
    end
  end

  def admin_activity_timeline(limit = 10)
    activities = []
    
    # Recent orders
    orders.recent.limit(3).each do |order|
      activities << {
        type: 'order',
        description: "Order ##{order.id} (#{order.status}) - $#{order.total}",
        timestamp: order.created_at,
        metadata: { order_id: order.id, status: order.status, amount: order.total }
      }
    end
    
    # Recent device registrations
    devices.recent.limit(3).each do |device|
      activities << {
        type: 'device',
        description: "Registered device: #{device.name}",
        timestamp: device.created_at,
        metadata: { device_id: device.id, device_name: device.name }
      }
    end
    
    # Subscription changes
    subscriptions.recent.limit(2).each do |sub|
      activities << {
        type: 'subscription',
        description: "Subscription: #{sub.plan&.name} (#{sub.status})",
        timestamp: sub.created_at,
        metadata: { subscription_id: sub.id, plan: sub.plan&.name }
      }
    end
    
    # Login activity
    if last_sign_in_at
      activities << {
        type: 'login',
        description: "Last login",
        timestamp: last_sign_in_at,
        metadata: { ip: last_sign_in_ip }
      }
    end
    
    activities.sort_by { |a| a[:timestamp] }.reverse.first(limit)
  end

  def admin_flags
    flags = []
    flags << 'vip_customer' if orders.where(status: 'completed').sum(:total) > 1000
    flags << 'enterprise_user' if enterprise?
    flags << 'early_adopter' if created_at < 6.months.ago
    flags << 'high_device_usage' if devices.count >= (device_limit * 0.8)
    flags << 'support_contact' if respond_to?(:support_tickets) && support_tickets.count > 5
    flags << 'payment_issues' if orders.where(status: 'payment_failed').count > 2
    flags << 'churned_user' if subscription&.canceled? && subscription.updated_at > 30.days.ago
    flags
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

  def self.admin_cohort_analysis
    # Analyze user cohorts by signup month
    monthly_cohorts = group_by_month(:created_at, last: 12).count
    
    cohorts = monthly_cohorts.map do |month, signup_count|
      retained_users = where(created_at: month.beginning_of_month..month.end_of_month)
                      .joins(:subscription)
                      .where(subscriptions: { status: 'active' })
                      .count
      
      {
        month: month,
        signups: signup_count,
        retained: retained_users,
        retention_rate: signup_count > 0 ? ((retained_users.to_f / signup_count) * 100).round(1) : 0
      }
    end
    
    cohorts
  end

  def self.admin_segment_distribution
    {
      by_role: group(:role).count,
      by_plan: joins(subscription: :plan).group('plans.name').count,
      by_status: group_by_admin_status,
      by_device_usage: group_by_device_usage,
      by_spending: group_by_spending_tier
    }
  end

  def self.group_by_admin_status
    {
      active: active_subscribers.count,
      past_due: past_due_subscribers.count,
      canceled: canceled_subscribers.count,
      no_subscription: no_subscription.count
    }
  end

  def self.group_by_device_usage
    {
      no_devices: without_devices.count,
      under_utilized: with_devices.select { |u| u.devices.count < (u.device_limit * 0.5) }.count,
      well_utilized: with_devices.select { |u| u.devices.count >= (u.device_limit * 0.5) && u.devices.count <= u.device_limit }.count,
      over_limit: with_devices.select { |u| u.devices.count > u.device_limit }.count
    }
  end

  def self.group_by_spending_tier
    {
      low_spender: joins(:orders).where(orders: { status: 'completed' }).group('users.id').having('SUM(orders.total) < ?', 100).count.count,
      medium_spender: joins(:orders).where(orders: { status: 'completed' }).group('users.id').having('SUM(orders.total) BETWEEN ? AND ?', 100, 500).count.count,
      high_spender: joins(:orders).where(orders: { status: 'completed' }).group('users.id').having('SUM(orders.total) > ?', 500).count.count
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

  def self.admin_filter_by_risk_level(level)
    case level
    when 'high'
      churn_risk.or(over_device_limit)
    when 'medium'
      inactive_users(14).where.not(id: churn_risk.select(:id))
    when 'low'
      active_subscribers.where.not(id: inactive_users(14).select(:id))
    else
      all
    end
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