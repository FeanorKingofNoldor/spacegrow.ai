# app/models/admin_activity_log.rb
class AdminActivityLog < ApplicationRecord
  # ===== CONSTANTS =====
  
  ACTIONS = %w[
    user_created
    user_updated
    user_suspended
    user_reactivated
    user_role_changed
    order_status_updated
    order_refunded
    subscription_updated
    subscription_canceled
    device_status_updated
    device_suspended
    device_reactivated
    alert_acknowledged
    alert_resolved
    system_maintenance
    bulk_operation
    data_export
    login
    logout
  ].freeze

  # ===== VALIDATIONS =====
  
  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :admin_user_id, presence: true
  validates :target_type, presence: true
  validates :target_id, presence: true
  validates :ip_address, presence: true
  validates :user_agent, presence: true, length: { maximum: 500 }

  # ===== ASSOCIATIONS =====
  
  belongs_to :admin_user, class_name: 'User'
  belongs_to :target, polymorphic: true, optional: true

  # ===== SCOPES =====
  
  scope :recent, ->(days = 7) { where(created_at: days.days.ago..Time.current) }
  scope :by_admin, ->(admin_id) { where(admin_user_id: admin_id) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_target_type, ->(type) { where(target_type: type) }
  scope :user_actions, -> { where(target_type: 'User') }
  scope :order_actions, -> { where(target_type: 'Order') }
  scope :device_actions, -> { where(target_type: 'Device') }
  scope :subscription_actions, -> { where(target_type: 'Subscription') }
  scope :critical_actions, -> { where(action: ['user_suspended', 'order_refunded', 'subscription_canceled']) }

  # ===== CALLBACKS =====
  
  after_create :alert_on_critical_actions

  # ===== INSTANCE METHODS =====
  
  def action_description
    case action
    when 'user_created'
      "Created user #{target&.email || target_id}"
    when 'user_updated'
      "Updated user #{target&.email || target_id}"
    when 'user_suspended'
      "Suspended user #{target&.email || target_id}"
    when 'user_reactivated'
      "Reactivated user #{target&.email || target_id}"
    when 'user_role_changed'
      "Changed role for user #{target&.email || target_id}"
    when 'order_status_updated'
      "Updated order ##{target_id} status"
    when 'order_refunded'
      "Processed refund for order ##{target_id}"
    when 'subscription_updated'
      "Updated subscription ##{target_id}"
    when 'subscription_canceled'
      "Canceled subscription ##{target_id}"
    when 'device_status_updated'
      "Updated device #{target&.name || target_id} status"
    when 'device_suspended'
      "Suspended device #{target&.name || target_id}"
    when 'device_reactivated'
      "Reactivated device #{target&.name || target_id}"
    when 'alert_acknowledged'
      "Acknowledged alert ##{target_id}"
    when 'alert_resolved'
      "Resolved alert ##{target_id}"
    when 'system_maintenance'
      "Performed system maintenance"
    when 'bulk_operation'
      "Performed bulk operation on #{target_type.pluralize.downcase}"
    when 'data_export'
      "Exported #{target_type.downcase} data"
    when 'login'
      "Admin login"
    when 'logout'
      "Admin logout"
    else
      "Performed #{action.humanize.downcase}"
    end
  end

  def critical_action?
    ['user_suspended', 'order_refunded', 'subscription_canceled', 'device_suspended'].include?(action)
  end

  def target_name
    case target_type
    when 'User'
      target&.email || "User ##{target_id}"
    when 'Device'
      target&.name || "Device ##{target_id}"
    when 'Order'
      "Order ##{target_id}"
    when 'Subscription'
      "Subscription ##{target_id}"
    else
      "#{target_type} ##{target_id}"
    end
  end

  # ===== CLASS METHODS =====
  
  def self.log_action(admin_user, action, target = nil, details = {}, ip_address = nil, user_agent = nil)
    create!(
      admin_user: admin_user,
      action: action,
      target: target,
      target_type: target&.class&.name,
      target_id: target&.id,
      details: details,
      ip_address: ip_address || 'unknown',
      user_agent: user_agent || 'unknown',
      created_at: Time.current
    )
  end

  def self.admin_activity_summary(admin_id, period = 30.days)
    logs = where(admin_user_id: admin_id, created_at: period.ago..Time.current)
    
    {
      total_actions: logs.count,
      actions_by_type: logs.group(:action).count,
      targets_by_type: logs.group(:target_type).count,
      critical_actions: logs.critical_actions.count,
      most_recent_action: logs.order(created_at: :desc).first,
      daily_activity: logs.group_by_day(:created_at).count
    }
  end

  def self.system_activity_overview(period = 7.days)
    logs = where(created_at: period.ago..Time.current)
    
    {
      total_admin_actions: logs.count,
      unique_admins: logs.distinct.count(:admin_user_id),
      critical_actions: logs.critical_actions.count,
      most_active_admin: logs.group(:admin_user_id).count.max_by { |_, count| count },
      actions_by_day: logs.group_by_day(:created_at).count,
      actions_by_type: logs.group(:action).count.sort_by { |_, count| -count }
    }
  end

  def self.audit_trail(target)
    where(target: target).order(created_at: :desc)
  end

  def self.cleanup_old_logs(days = 90)
    where(created_at: ..days.days.ago).destroy_all
  end

  private

  def alert_on_critical_actions
    if critical_action?
      # This would integrate with your admin notification system
      Rails.logger.warn "🚨 Critical admin action: #{action_description} by #{admin_user.email}"
      
      # Optionally send real-time alert to other admins
      # AdminNotificationService.new.send_warning_alert('critical_admin_action', {
      #   action: action,
      #   admin: admin_user.email,
      #   target: target_name,
      #   message: action_description
      # })
    end
  end
end