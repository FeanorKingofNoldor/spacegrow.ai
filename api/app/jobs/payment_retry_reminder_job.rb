# app/jobs/payment_retry_reminder_job.rb
class PaymentRetryReminderJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless order

    Rails.logger.info "🔄 [PaymentRetryReminderJob] Processing retry reminder for order #{order.id}"

    # Only send reminder if order is still in failed state
    unless order.payment_failed?
      Rails.logger.info "🔄 [PaymentRetryReminderJob] Order #{order.id} is no longer in failed state, skipping reminder"
      return
    end

    # Don't send reminder if order is too old (7 days)
    if order.created_at < 7.days.ago
      Rails.logger.info "🔄 [PaymentRetryReminderJob] Order #{order.id} is too old, skipping reminder"
      return
    end

    # Send retry reminder email
    result = EmailManagement::OrderEmailService.send_retry_reminder(order)
    
    if result[:success]
      Rails.logger.info "🔄 [PaymentRetryReminderJob] Retry reminder sent successfully for order #{order.id}"
      
      # Track analytics
      Analytics::EventTrackingService.track_user_activity(
        order.user,
        'payment_retry_reminder_sent',
        {
          order_id: order.id,
          failure_reason: order.payment_failure_reason,
          retry_strategy: order.retry_strategy
        }
      )
    else
      Rails.logger.error "🔄 [PaymentRetryReminderJob] Failed to send retry reminder for order #{order.id}: #{result[:error]}"
    end

  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "🔄 [PaymentRetryReminderJob] Order #{order_id} not found"
  rescue => e
    Rails.logger.error "🔄 [PaymentRetryReminderJob] Error processing retry reminder for order #{order_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end