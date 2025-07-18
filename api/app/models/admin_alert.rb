# app/models/admin_alert.rb
class AdminAlert < ApplicationRecord
  # ===== CONSTANTS =====
  
  PRIORITIES = %w[info warning critical].freeze
  STATUSES = %w[active acknowledged resolved dismissed].freeze
  
  ALERT_TYPES = %w[
    system_health_critical
    system_health_warning
    device_errors_spike
    payment_failures_moderate
    payment_failures_high
    payment_failures_emergency
    revenue_decline
    churn_risk_high
    user_inactivity_high
    churn_risk_elevated
    past_due_subscriptions_high
    device_connection_failures
    device_fleet_critical
    device_performance_degraded
    milestone_revenue
    milestone_users
    system_cleanup_failed
    system_cleanup_summary
  ].freeze

  # ===== VALIDATIONS =====
  
  validates :alert_type, presence: true, inclusion: { in: ALERT_TYPES }
  validates :priority, presence: true, inclusion: { in: PRIORITIES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :title, presence: true, length: { maximum: 255 }
  validates :message, presence: true, length: { maximum: 1000 }

  # ===== SCOPES =====
  
  scope :active, -> { where(status: 'active') }
  scope :acknowledged, -> { where(status: 'acknowledged') }
  scope :resolved, -> { where(status: 'resolved') }
  scope :dismissed, -> { where(status: 'dismissed') }
  scope :unresolved, -> { where(status: ['active', 'acknowledged']) }
  
  scope :critical, -> { where(priority: 'critical') }
  scope :warning, -> { where(priority: 'warning') }
  scope :info, -> { where(priority: 'info') }
  
  scope :recent, ->(days = 7) { where(created_at: days.days.ago..Time.current) }
  scope :by_type, ->(type) { where(alert_type: type) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  
  scope :require_attention, -> { where(status: ['active', 'acknowledged'], priority: ['warning', 'critical']) }
  scope :critical_unresolved, -> { critical.unresolved }

  # ===== ASSOCIATIONS =====
  
  belongs_to :acknowledged_by_user, class_name: 'User', optional: true
  belongs_to :resolved_by_user, class_name: 'User', optional: true

  # ===== CALLBACKS =====
  
  before_create :set_defaults
  after_create :log_alert_creation
  after_update :log_status_change, if: :saved_change_to_status?

  # ===== INSTANCE METHODS =====
  
  def acknowledge!(user)
    update!(
      status: 'acknowledged',
      acknowledged_at: Time.current,
      acknowledged_by_user: user
    )
  end

  def resolve!(user, resolution_notes = nil)
    update!(
      status: 'resolved',
      resolved_at: Time.current,
      resolved_by_user: user,
      resolution_notes: resolution_notes
    )
  end

  def dismiss!(user, dismiss_reason = nil)
    update!(
      status: 'dismissed',
      dismissed_at: Time.current,
      dismissed_by_user: user,
      dismiss_reason: dismiss_reason
    )
  end

  def escalate!(user)
    if priority == 'info'
      update!(priority: 'warning')
    elsif priority == 'warning'
      update!(priority: 'critical')
    end
    
    log_escalation(user)
  end

  def active?
    status == 'active'
  end

  def acknowledged?
    status == 'acknowledged'
  end

  def resolved?
    status == 'resolved'
  end

  def dismissed?
    status == 'dismissed'
  end

  def critical?
    priority == 'critical'
  end

  def warning?
    priority == 'warning'
  end

  def info?
    priority == 'info'
  end

  def requires_immediate_attention?
    active? && critical?
  end

  def time_to_acknowledge
    return nil unless acknowledged_at
    acknowledged_at - created_at
  end

  def time_to_resolve
    return nil unless resolved_at
    resolved_at - created_at
  end

  def alert_age
    Time.current - created_at
  end

  def alert_age_in_words
    distance_of_time_in_words(created_at, Time.current)
  end

  def priority_color
    case priority
    when 'critical' then 'red'
    when 'warning' then 'yellow'
    when 'info' then 'blue'
    else 'gray'
    end
  end

  def status_badge_color
    case status
    when 'active' then 'red'
    when 'acknowledged' then 'yellow'
    when 'resolved' then 'green'
    when 'dismissed' then 'gray'
    else 'gray'
    end
  end

  # ===== CLASS METHODS =====
  
  def self.create_alert(alert_type, priority, title, message, metadata = {})
    create!(
      alert_type: alert_type,
      priority: priority,
      title: title,
      message: message,
      metadata: metadata,
      status: 'active'
    )
  end

  def self.critical_alerts_count
    critical.unresolved.count
  end

  def self.warning_alerts_count
    warning.unresolved.count
  end

  def self.alerts_requiring_attention
    require_attention.order(priority: :desc, created_at: :desc)
  end

  def self.alert_summary
    {
      total: count,
      active: active.count,
      acknowledged: acknowledged.count,
      resolved: resolved.count,
      critical: critical.count,
      warning: warning.count,
      info: info.count,
      unresolved: unresolved.count,
      require_attention: require_attention.count
    }
  end

  def self.recent_activity(limit = 10)
    order(created_at: :desc).limit(limit)
  end

  def self.cleanup_old_alerts(days = 30)
    resolved.where(resolved_at: ..days.days.ago).destroy_all
  end

  private

  def set_defaults
    self.status ||= 'active'
    self.created_by_system = true if created_by_system.nil?
  end

  def log_alert_creation
    Rails.logger.info "🚨 AdminAlert created: #{alert_type} (#{priority}) - #{title}"
  end

  def log_status_change
    old_status = saved_changes['status'][0]
    new_status = saved_changes['status'][1]
    Rails.logger.info "🔄 AdminAlert #{id} status changed: #{old_status} -> #{new_status}"
  end

  def log_escalation(user)
    Rails.logger.info "⬆️ AdminAlert #{id} escalated to #{priority} by user #{user.id}"
  end
end