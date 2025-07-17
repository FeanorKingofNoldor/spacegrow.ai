# app/jobs/subscription_suspension_job.rb
class SubscriptionSuspensionJob < ApplicationJob
  queue_as :default

  def perform(subscription_id)
    subscription = Subscription.find_by(id: subscription_id)
    return unless subscription

    Rails.logger.info "⏸️ [SubscriptionSuspensionJob] Processing suspension for subscription #{subscription.id}"

    # Check if payment has been resolved since job was scheduled
    if subscription.active?
      Rails.logger.info "⏸️ [SubscriptionSuspensionJob] Subscription #{subscription.id} is now active, cancelling suspension"
      return
    end

    # Only proceed if subscription is past due
    unless subscription.past_due?
      Rails.logger.info "⏸️ [SubscriptionSuspensionJob] Subscription #{subscription.id} is not past due, skipping suspension"
      return
    end

    # Check grace period
    if within_grace_period?(subscription)
      Rails.logger.info "⏸️ [SubscriptionSuspensionJob] Subscription #{subscription.id} still within grace period, rescheduling"
      reschedule_suspension(subscription)
      return
    end

    # Execute suspension workflow
    suspension_result = execute_suspension_workflow(subscription)
    
    if suspension_result[:success]
      Rails.logger.info "⏸️ [SubscriptionSuspensionJob] Successfully suspended subscription #{subscription.id}"
      
      # Track analytics
      Analytics::EventTrackingService.track_user_activity(
        subscription.user,
        'subscription_suspended',
        {
          subscription_id: subscription.id,
          plan_name: subscription.plan.name,
          devices_suspended: suspension_result[:devices_suspended],
          suspension_reason: 'payment_failure_grace_period_expired'
        }
      )
    else
      Rails.logger.error "⏸️ [SubscriptionSuspensionJob] Failed to suspend subscription #{subscription.id}: #{suspension_result[:error]}"
    end

  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "⏸️ [SubscriptionSuspensionJob] Subscription #{subscription_id} not found"
  rescue => e
    Rails.logger.error "⏸️ [SubscriptionSuspensionJob] Error processing suspension for subscription #{subscription_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def within_grace_period?(subscription)
    # Check if subscription has a grace period and it hasn't expired
    grace_period_days = subscription.plan.grace_period_days || 7
    grace_period_end = subscription.last_payment_failure_at + grace_period_days.days
    
    Time.current < grace_period_end
  end

  def reschedule_suspension(subscription)
    # Calculate remaining grace period
    grace_period_days = subscription.plan.grace_period_days || 7
    grace_period_end = subscription.last_payment_failure_at + grace_period_days.days
    remaining_time = grace_period_end - Time.current
    
    # Reschedule for end of grace period
    SubscriptionSuspensionJob.set(wait: remaining_time).perform_later(subscription.id)
    
    Rails.logger.info "⏸️ [SubscriptionSuspensionJob] Rescheduled suspension for subscription #{subscription.id} in #{remaining_time.round} seconds"
  end

  def execute_suspension_workflow(subscription)
    user = subscription.user
    
    begin
      ActiveRecord::Base.transaction do
        # Update subscription status
        subscription.update!(
          status: 'suspended',
          suspended_at: Time.current,
          suspended_reason: 'payment_failure_grace_period_expired'
        )
        
        # Suspend all operational devices
        operational_devices = user.devices.operational
        suspended_devices = []
        
        operational_devices.each do |device|
          if device.suspend!(reason: 'subscription_payment_failure')
            suspended_devices << {
              id: device.id,
              name: device.name,
              device_type: device.device_type.name
            }
          end
        end
        
        # Send suspension notification email
        email_result = send_suspension_notification(subscription, suspended_devices)
        
        # Log suspension details
        Rails.logger.info "⏸️ [SubscriptionSuspensionJob] Suspended #{suspended_devices.count} devices for user #{user.id}"
        
        {
          success: true,
          devices_suspended: suspended_devices.count,
          suspended_devices: suspended_devices,
          email_sent: email_result[:success]
        }
      end
    rescue => e
      Rails.logger.error "⏸️ [SubscriptionSuspensionJob] Transaction failed during suspension: #{e.message}"
      { success: false, error: e.message }
    end
  end

  def send_suspension_notification(subscription, suspended_devices)
    begin
      # Send suspension notification using existing email service
      result = EmailManagement::SubscriptionEmailService.send_suspension_notification(
        subscription,
        {
          suspended_devices: suspended_devices,
          grace_period_expired: true,
          reactivation_url: generate_reactivation_url(subscription),
          payment_update_url: generate_payment_update_url(subscription.user)
        }
      )
      
      if result[:success]
        Rails.logger.info "⏸️ [SubscriptionSuspensionJob] Suspension notification sent for subscription #{subscription.id}"
      else
        Rails.logger.error "⏸️ [SubscriptionSuspensionJob] Failed to send suspension notification: #{result[:error]}"
      end
      
      result
    rescue => e
      Rails.logger.error "⏸️ [SubscriptionSuspensionJob] Error sending suspension notification: #{e.message}"
      { success: false, error: e.message }
    end
  end

  def generate_reactivation_url(subscription)
    "#{Rails.application.config.app_host}/billing/reactivate?subscription_id=#{subscription.id}"
  end

  def generate_payment_update_url(user)
    "#{Rails.application.config.app_host}/billing/payment-method?user_id=#{user.id}"
  end
end