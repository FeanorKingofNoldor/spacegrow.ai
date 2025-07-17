# app/jobs/setup_help_email_job.rb
class SetupHelpEmailJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless order

    Rails.logger.info "🔧 [SetupHelpEmailJob] Processing setup help email for order #{order.id}"

    # Only send if order is paid and has devices
    unless order.paid? && order.has_devices?
      Rails.logger.info "🔧 [SetupHelpEmailJob] Order #{order.id} is not paid or has no devices, skipping"
      return
    end

    # Don't send if devices are already activated
    if all_devices_activated?(order)
      Rails.logger.info "🔧 [SetupHelpEmailJob] All devices for order #{order.id} are already activated, skipping"
      return
    end

    # Send setup help email
    result = EmailManagement::OrderEmailService.send_setup_help(order)
    
    if result[:success]
      Rails.logger.info "🔧 [SetupHelpEmailJob] Setup help email sent successfully for order #{order.id}"
      
      # Track analytics
      Analytics::EventTrackingService.track_user_activity(
        order.user,
        'setup_help_email_sent',
        {
          order_id: order.id,
          device_count: order.device_count,
          days_since_purchase: (Time.current - order.created_at) / 1.day
        }
      )
    else
      Rails.logger.error "🔧 [SetupHelpEmailJob] Failed to send setup help email for order #{order.id}: #{result[:error]}"
    end

  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "🔧 [SetupHelpEmailJob] Order #{order_id} not found"
  rescue => e
    Rails.logger.error "🔧 [SetupHelpEmailJob] Error processing setup help email for order #{order_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def all_devices_activated?(order)
    # Check if all activation tokens for this order have been used
    order.device_activation_tokens.all?(&:used?)
  end
end