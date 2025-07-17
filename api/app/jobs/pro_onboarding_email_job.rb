# app/jobs/pro_onboarding_email_job.rb
class ProOnboardingEmailJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless order

    Rails.logger.info "🎓 [ProOnboardingEmailJob] Processing pro onboarding email for order #{order.id}"

    # Only send if order is paid and has multiple devices (pro user behavior)
    unless order.paid? && order.device_count > 2
      Rails.logger.info "🎓 [ProOnboardingEmailJob] Order #{order.id} doesn't qualify for pro onboarding, skipping"
      return
    end

    # Check if user should be considered for pro features
    user = order.user
    if should_onboard_as_pro?(user)
      result = EmailManagement::OrderEmailService.send_pro_onboarding(order)
      
      if result[:success]
        Rails.logger.info "🎓 [ProOnboardingEmailJob] Pro onboarding email sent successfully for order #{order.id}"
        
        # Track analytics
        Analytics::EventTrackingService.track_user_activity(
          user,
          'pro_onboarding_email_sent',
          {
            order_id: order.id,
            device_count: order.device_count,
            user_role: user.role,
            total_orders: user.orders.count,
            onboarding_trigger: determine_onboarding_trigger(user)
          }
        )

        # Schedule follow-up pro features email
        ProFeaturesFollowUpJob.set(wait: 3.days).perform_later(user.id)
      else
        Rails.logger.error "🎓 [ProOnboardingEmailJob] Failed to send pro onboarding email for order #{order.id}: #{result[:error]}"
      end
    else
      Rails.logger.info "🎓 [ProOnboardingEmailJob] User #{user.id} doesn't qualify for pro onboarding"
    end

  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "🎓 [ProOnboardingEmailJob] Order #{order_id} not found"
  rescue => e
    Rails.logger.error "🎓 [ProOnboardingEmailJob] Error processing pro onboarding email for order #{order_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def should_onboard_as_pro?(user)
    # Multiple criteria for pro user identification
    criteria = [
      user.devices.count > 2,                    # Has multiple devices
      user.orders.sum(&:total) > 500,           # High order value
      user.role == 'pro',                       # Already pro role
      user.subscription&.plan&.pro?             # Pro subscription
    ]
    
    criteria.count(true) >= 2
  end

  def determine_onboarding_trigger(user)
    if user.role == 'pro'
      'existing_pro_user'
    elsif user.devices.count > 4
      'multiple_devices'
    elsif user.orders.sum(&:total) > 1000
      'high_value_customer'
    else
      'device_count_threshold'
    end
  end
end