# app/models/email_unsubscribe.rb
class EmailUnsubscribe < ApplicationRecord
  belongs_to :user
  
  # ===== UNSUBSCRIBE TYPES =====
  UNSUBSCRIBE_TYPES = [
    'marketing_all',      # All marketing emails
    'nurture_sequence',   # Nurture email sequences
    'promotional',        # Promotional offers and discounts
    'educational',        # Educational content and tips
    'device_recommendations', # Device and accessory recommendations
    'case_studies',       # Success stories and case studies
    'seasonal_campaigns', # Seasonal promotions
    'win_back_campaigns'  # Win-back campaigns
  ].freeze
  
  # ===== UNSUBSCRIBE REASONS =====
  UNSUBSCRIBE_REASONS = [
    'too_frequent',       # Emails too frequent
    'not_relevant',       # Content not relevant
    'never_signed_up',    # Never signed up for emails
    'privacy_concerns',   # Privacy concerns
    'found_alternative',  # Found alternative solution
    'no_longer_needed',   # No longer need the service
    'poor_content',       # Poor email content quality
    'other'               # Other reason
  ].freeze
  
  # ===== VALIDATIONS =====
  validates :user_id, presence: true
  validates :unsubscribe_type, presence: true, inclusion: { in: UNSUBSCRIBE_TYPES }
  validates :reason, inclusion: { in: UNSUBSCRIBE_REASONS }, allow_blank: true
  validates :user_id, uniqueness: { scope: :unsubscribe_type, message: "has already unsubscribed from this type" }
  
  # ===== SCOPES =====
  scope :marketing, -> { where(unsubscribe_type: 'marketing_all') }
  scope :by_type, ->(type) { where(unsubscribe_type: type) }
  scope :by_reason, ->(reason) { where(reason: reason) }
  scope :recent, ->(days = 30) { where('created_at >= ?', days.days.ago) }
  
  # ===== CALLBACKS =====
  after_create :update_user_preferences
  after_create :log_unsubscribe_event
  
  # ===== CLASS METHODS =====
  
  # Unsubscribe user from specific type
  def self.unsubscribe_user(user, unsubscribe_type, reason: nil, user_agent: nil, ip_address: nil)
    return false unless UNSUBSCRIBE_TYPES.include?(unsubscribe_type.to_s)
    
    unsubscribe = find_or_create_by(
      user: user,
      unsubscribe_type: unsubscribe_type
    ) do |unsub|
      unsub.reason = reason
      unsub.user_agent = user_agent
      unsub.ip_address = ip_address
      unsub.unsubscribed_at = Time.current
    end
    
    unsubscribe.persisted?
  end
  
  # Check if user is unsubscribed from type
  def self.user_unsubscribed?(user, unsubscribe_type)
    exists?(user: user, unsubscribe_type: unsubscribe_type)
  end
  
  # Bulk unsubscribe users (for admin/compliance)
  def self.bulk_unsubscribe(user_ids, unsubscribe_type, reason: 'admin_action')
    user_ids.each do |user_id|
      user = User.find_by(id: user_id)
      next unless user
      
      unsubscribe_user(user, unsubscribe_type, reason: reason)
    end
  end
  
  # Get unsubscribe statistics
  def self.statistics(period: 30.days)
    base_scope = where('created_at >= ?', period.ago)
    
    {
      total_unsubscribes: base_scope.count,
      by_type: base_scope.group(:unsubscribe_type).count,
      by_reason: base_scope.group(:reason).count,
      daily_breakdown: base_scope.group_by_day(:created_at).count,
      top_reasons: base_scope.group(:reason).order('count_all DESC').limit(5).count
    }
  end
  
  # ===== INSTANCE METHODS =====
  
  # Resubscribe user (remove unsubscribe record)
  def resubscribe!
    # Update user preferences to re-enable marketing
    if unsubscribe_type == 'marketing_all'
      user.preferences.update!(marketing_emails_opted_in: true, marketing_opted_in_at: Time.current)
    end
    
    # Log resubscribe event
    Rails.logger.info "📧 [EmailUnsubscribe] User #{user.id} resubscribed from #{unsubscribe_type}"
    
    # Remove unsubscribe record
    destroy!
  end
  
  # Check if this is a global marketing unsubscribe
  def global_marketing_unsubscribe?
    unsubscribe_type == 'marketing_all'
  end
  
  # Get user-friendly description of unsubscribe type
  def type_description
    case unsubscribe_type
    when 'marketing_all'
      'All marketing emails'
    when 'nurture_sequence'
      'Email nurture sequences'
    when 'promotional'
      'Promotional offers and discounts'
    when 'educational'
      'Educational content and tips'
    when 'device_recommendations'
      'Device and accessory recommendations'
    when 'case_studies'
      'Success stories and case studies'
    when 'seasonal_campaigns'
      'Seasonal promotions'
    when 'win_back_campaigns'
      'Win-back campaigns'
    else
      unsubscribe_type.humanize
    end
  end
  
  # Get user-friendly description of reason
  def reason_description
    case reason
    when 'too_frequent'
      'Emails were too frequent'
    when 'not_relevant'
      'Content was not relevant'
    when 'never_signed_up'
      'Never signed up for emails'
    when 'privacy_concerns'
      'Privacy concerns'
    when 'found_alternative'
      'Found alternative solution'
    when 'no_longer_needed'
      'No longer need the service'
    when 'poor_content'
      'Poor email content quality'
    when 'other'
      'Other reason'
    else
      reason&.humanize
    end
  end
  
  private
  
  # Update user notification preferences based on unsubscribe
  def update_user_preferences
    case unsubscribe_type
    when 'marketing_all'
      # Opt user out of all marketing emails
      user.preferences.update!(
        marketing_emails_opted_in: false,
        marketing_opted_out_at: Time.current,
        marketing_tips_email: false
      )
    when 'promotional', 'seasonal_campaigns', 'win_back_campaigns'
      # Disable promotional marketing emails
      user.preferences.update!(marketing_tips_email: false)
    end
  end
  
  # Log unsubscribe event for analytics
  def log_unsubscribe_event
    Rails.logger.info "📧 [EmailUnsubscribe] User #{user.id} unsubscribed from #{unsubscribe_type} (reason: #{reason})"
    
    # Track in analytics if available
    if defined?(Analytics::EventTrackingService)
      Analytics::EventTrackingService.track_user_activity(
        user,
        'email_unsubscribed',
        {
          unsubscribe_type: unsubscribe_type,
          reason: reason,
          user_agent: user_agent,
          ip_address: ip_address,
          days_since_registration: (Time.current - user.created_at) / 1.day,
          total_emails_sent: user.preferences.total_emails_sent
        }
      )
    end
  end
end