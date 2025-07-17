# app/jobs/pro_features_follow_up_job.rb
class ProFeaturesFollowUpJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    Rails.logger.info "🎯 [ProFeaturesFollowUpJob] Processing pro features follow-up for user #{user.id}"

    # Only send if user is still active and has multiple devices
    unless user.devices.operational.count > 2
      Rails.logger.info "🎯 [ProFeaturesFollowUpJob] User #{user.id} no longer qualifies for pro features follow-up"
      return
    end

    # Check if user has engaged with pro features
    if user_already_engaged_with_pro_features?(user)
      Rails.logger.info "🎯 [ProFeaturesFollowUpJob] User #{user.id} already engaged with pro features, skipping"
      return
    end

    # Send pro features follow-up email
    result = EmailManagement::OrderEmailService.send_pro_features_follow_up(user)
    
    if result[:success]
      Rails.logger.info "🎯 [ProFeaturesFollowUpJob] Pro features follow-up email sent successfully for user #{user.id}"
      
      # Track analytics
      Analytics::EventTrackingService.track_user_activity(
        user,
        'pro_features_follow_up_sent',
        {
          device_count: user.devices.count,
          subscription_plan: user.subscription&.plan&.name,
          days_since_onboarding: 3,
          engagement_score: calculate_engagement_score(user)
        }
      )
    else
      Rails.logger.error "🎯 [ProFeaturesFollowUpJob] Failed to send pro features follow-up for user #{user.id}: #{result[:error]}"
    end

  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "🎯 [ProFeaturesFollowUpJob] User #{user_id} not found"
  rescue => e
    Rails.logger.error "🎯 [ProFeaturesFollowUpJob] Error processing pro features follow-up for user #{user_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def user_already_engaged_with_pro_features?(user)
    # Check various engagement indicators
    engagement_indicators = [
      user.role == 'pro',                                      # Upgraded to pro
      user.subscription&.plan&.name == 'Professional',        # Pro subscription
      user.devices.count > 4,                                 # Many devices (pro behavior)
      user.user_sessions.where('created_at > ?', 1.week.ago).count > 10, # High activity
      user.orders.where('created_at > ?', 1.week.ago).any?   # Recent purchases
    ]
    
    # Consider engaged if 2 or more indicators are true
    engagement_indicators.count(true) >= 2
  end

  def calculate_engagement_score(user)
    score = 0
    
    # Device usage score
    score += user.devices.operational.count * 10
    
    # Recent activity score
    recent_sessions = user.user_sessions.where('created_at > ?', 1.week.ago).count
    score += [recent_sessions, 50].min  # Cap at 50 points
    
    # Purchase behavior score
    if user.orders.where('created_at > ?', 1.month.ago).any?
      score += 20
    end
    
    # Subscription score
    if user.subscription&.active?
      score += 30
    end
    
    # Cap total score at 100
    [score, 100].min
  end
end