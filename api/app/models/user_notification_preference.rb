# app/models/user_notification_preference.rb
class UserNotificationPreference < ApplicationRecord
  belongs_to :user
  
  # ===== VALIDATION =====
  validates :user_id, presence: true, uniqueness: true
  validates :digest_frequency, inclusion: { in: %w[immediate daily weekly disabled] }
  validates :digest_day_of_week, inclusion: { in: 1..7 }
  validates :escalation_delay_minutes, numericality: { 
    greater_than_or_equal_to: 15, 
    less_than_or_equal_to: 1440 
  }
  # Note: timezone validation handled by User model
  
  # ===== NOTIFICATION CATEGORIES WITH CONFIGURATION =====
  CATEGORIES = {
    'security_auth' => { 
      default_email: true, 
      default_inapp: true,
      user_controllable: false,
      description: 'Security alerts, login notifications, and authentication events',
      examples: ['New device login', 'Password changes', 'Account lockouts']
    },
    'financial_billing' => { 
      default_email: true, 
      default_inapp: true,
      user_controllable: false,
      description: 'Billing, payments, and subscription-related notifications',
      examples: ['Payment receipts', 'Failed payments', 'Plan changes']
    },
    'critical_device_alerts' => { 
      default_email: true, 
      default_inapp: true,
      user_controllable: true,
      description: 'Urgent device issues requiring immediate attention',
      examples: ['Device offline', 'Sensor failures', 'Critical threshold breaches']
    },
    'device_management' => { 
      default_email: false, 
      default_inapp: true,
      user_controllable: true,
      description: 'Device status updates and management notifications',
      examples: ['Device activated', 'Configuration changes', 'Firmware updates']
    },
    'account_updates' => { 
      default_email: false, 
      default_inapp: true,
      user_controllable: true,
      description: 'Account changes and profile updates',
      examples: ['Profile updates', 'Settings changes', 'Plan modifications']
    },
    'system_notifications' => { 
      default_email: false, 
      default_inapp: true,
      user_controllable: true,
      description: 'Platform updates and system announcements',
      examples: ['Maintenance windows', 'Feature announcements', 'System upgrades']
    },
    'reports_analytics' => { 
      default_email: false, 
      default_inapp: false,
      user_controllable: true,
      description: 'Automated reports and analytics summaries',
      examples: ['Weekly summaries', 'Monthly reports', 'Data exports']
    },
    'marketing_tips' => { 
      default_email: false, 
      default_inapp: false,
      user_controllable: true,
      description: 'Tips, guides, and promotional content',
      examples: ['Usage tips', 'Feature tutorials', 'Best practices']
    }
  }.freeze
  
  # ===== DIGEST FREQUENCY OPTIONS =====
  DIGEST_FREQUENCIES = {
    'immediate' => 'Immediate notifications',
    'daily' => 'Daily digest',
    'weekly' => 'Weekly summary',
    'disabled' => 'No notifications'
  }.freeze
  
  # ===== SCOPES =====
  scope :with_marketing_opted_in, -> { where(marketing_emails_opted_in: true) }
  scope :with_marketing_opted_out, -> { where(marketing_emails_opted_in: false) }
  scope :recently_opted_in, ->(days = 30) { where('marketing_opted_in_at >= ?', days.days.ago) }
  scope :recently_opted_out, ->(days = 30) { where('marketing_opted_out_at >= ?', days.days.ago) }
  scope :suppressed, -> { where('suppress_all_until > ?', Time.current) }
  scope :not_suppressed, -> { where('suppress_all_until IS NULL OR suppress_all_until <= ?', Time.current) }
  
  # ===== CALLBACKS =====
  before_create :set_defaults_based_on_categories
  after_create :log_preference_creation
  after_update :log_preference_changes, if: :saved_changes?
  
  # ===== CLASS METHODS =====
  
  # Get or create preferences for a user with proper defaults
  def self.for_user(user)
    find_or_create_by(user: user)
  end
  
  # Bulk update preferences for marketing campaigns
  def self.bulk_opt_in_marketing(user_ids, source = 'bulk_update')
    where(user_id: user_ids).update_all(
      marketing_emails_opted_in: true,
      marketing_opted_in_at: Time.current,
      marketing_opt_source: source
    )
  end
  
  def self.bulk_opt_out_marketing(user_ids, source = 'bulk_update')
    where(user_id: user_ids).update_all(
      marketing_emails_opted_in: false,
      marketing_opted_out_at: Time.current
    )
  end
  
  # ===== INSTANCE METHODS =====
  
  # Check if email notifications are enabled for a category
  def email_enabled_for?(category)
    category = category.to_s
    return false unless CATEGORIES.key?(category)
    return false if suppressed?
    
    send("#{category}_email")
  end
  
  # Check if in-app notifications are enabled for a category
  def inapp_enabled_for?(category)
    category = category.to_s
    return false unless CATEGORIES.key?(category)
    return false if suppressed?
    
    send("#{category}_inapp")
  end
  
  # Check if user can control this category
  def user_controllable?(category)
    category = category.to_s
    CATEGORIES.dig(category, :user_controllable) || false
  end
  
  # Check if notifications are temporarily suppressed
  def suppressed?
    suppress_all_until.present? && suppress_all_until > Time.current
  end
  
  # Temporarily suppress all notifications
  def suppress_notifications(duration: 1.hour, reason: nil)
    update!(
      suppress_all_until: duration.from_now,
      suppression_reason: reason
    )
  end
  
  # Remove suppression
  def unsuppress_notifications
    update!(
      suppress_all_until: nil,
      suppression_reason: nil
    )
  end
  
  # Opt into marketing emails
  def opt_into_marketing(source = 'user_settings')
    update!(
      marketing_emails_opted_in: true,
      marketing_opted_in_at: Time.current,
      marketing_opted_out_at: nil,
      marketing_opt_source: source
    )
  end
  
  # Opt out of marketing emails
  def opt_out_of_marketing
    update!(
      marketing_emails_opted_in: false,
      marketing_opted_out_at: Time.current
    )
  end
  
  # Check if should escalate in-app notification to email
  def should_escalate_to_email?(category, notification_created_at)
    return false unless enable_escalation
    return false unless user_controllable?(category)
    return false unless inapp_enabled_for?(category)
    return false if email_enabled_for?(category) # Already getting emails
    
    time_elapsed = Time.current - notification_created_at
    time_elapsed >= escalation_delay_minutes.minutes
  end
  
  # Get user's local time using their timezone setting
  def local_time
    Time.current.in_time_zone(user.timezone)
  end
  
  # Check if it's an appropriate time to send digest
  def digest_send_time?
    local = local_time
    
    case digest_frequency
    when 'daily'
      local.hour == digest_time.hour && local.min == digest_time.min
    when 'weekly'
      local.wday == digest_day_of_week && 
      local.hour == digest_time.hour && 
      local.min == digest_time.min
    else
      false
    end
  end
  
  # Track email sent
  def track_email_sent!
    increment!(:total_emails_sent)
    touch(:last_email_sent_at)
  end
  
  # Track in-app notification
  def track_inapp_notification!
    increment!(:total_inapp_notifications)
    touch(:last_inapp_notification_at)
  end
  
  # Get categories that user can control
  def controllable_categories
    CATEGORIES.select { |_, config| config[:user_controllable] }.keys
  end
  
  # Get categories that are mandatory
  def mandatory_categories
    CATEGORIES.reject { |_, config| config[:user_controllable] }.keys
  end
  
  # Update multiple category preferences at once
  def update_category_preferences(preferences_hash)
    updates = {}
    
    preferences_hash.each do |category, settings|
      next unless CATEGORIES.key?(category.to_s)
      next unless user_controllable?(category)
      
      if settings[:email].present?
        updates["#{category}_email"] = ActiveModel::Type::Boolean.new.cast(settings[:email])
      end
      
      if settings[:inapp].present?
        updates["#{category}_inapp"] = ActiveModel::Type::Boolean.new.cast(settings[:inapp])
      end
    end
    
    update!(updates) if updates.any?
  end
  
  # Export preferences as hash for API responses
  def to_preferences_hash
    categories = {}
    
    CATEGORIES.each do |category, config|
      categories[category] = {
        email_enabled: email_enabled_for?(category),
        inapp_enabled: inapp_enabled_for?(category),
        user_controllable: config[:user_controllable],
        description: config[:description],
        examples: config[:examples]
      }
    end
    
    {
      categories: categories,
      marketing_opted_in: marketing_emails_opted_in,
      digest_frequency: digest_frequency,
      digest_time: digest_time&.strftime('%H:%M'),
      digest_day_of_week: digest_day_of_week,
      enable_escalation: enable_escalation,
      escalation_delay_minutes: escalation_delay_minutes,
      suppressed: suppressed?,
      suppress_until: suppress_all_until,
      last_email_sent: last_email_sent_at,
      total_emails_sent: total_emails_sent,
      total_inapp_notifications: total_inapp_notifications
    }
  end
  
  private
  
  # Set category defaults when creating new preference record
  def set_defaults_based_on_categories
    CATEGORIES.each do |category, config|
      # Set email defaults
      email_attr = "#{category}_email"
      self[email_attr] = config[:default_email] if self[email_attr].nil?
      
      # Set in-app defaults
      inapp_attr = "#{category}_inapp"
      self[inapp_attr] = config[:default_inapp] if self[inapp_attr].nil?
    end
  end
  
  # Log when preferences are created
  def log_preference_creation
    Rails.logger.info "📧 [UserNotificationPreference] Created preferences for user #{user_id}"
  end
  
  # Log when preferences change
  def log_preference_changes
    changed_attrs = saved_changes.keys
    Rails.logger.info "📧 [UserNotificationPreference] Updated preferences for user #{user_id}: #{changed_attrs.join(', ')}"
    
    # Track marketing opt-in/out changes specifically
    if saved_changes.key?('marketing_emails_opted_in')
      old_val, new_val = saved_changes['marketing_emails_opted_in']
      action = new_val ? 'opted_in' : 'opted_out'
      Rails.logger.info "📧 [UserNotificationPreference] User #{user_id} #{action} of marketing emails"
    end
  end
end