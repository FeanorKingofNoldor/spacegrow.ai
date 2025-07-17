# app/services/payment_processing/payment_failure_service.rb
module PaymentProcessing
  class PaymentFailureService < ApplicationService
    def self.call(order:, failure_reason:, payment_intent_id: nil)
      new(order, failure_reason, payment_intent_id).call
    end

    def initialize(order, failure_reason, payment_intent_id = nil)
      @order = order
      @failure_reason = failure_reason
      @payment_intent_id = payment_intent_id
      @user = order.user
    end

    def call
      Rails.logger.info "❌ [PaymentFailureService] Processing payment failure for order #{@order.id}"
      Rails.logger.info "❌ [PaymentFailureService] Failure reason: #{@failure_reason}"
      
      ActiveRecord::Base.transaction do
        update_order_status
        release_reserved_inventory
        send_failure_notification
        handle_retry_strategy
        log_failure_analytics
      end

      Rails.logger.info "❌ [PaymentFailureService] Payment failure processed for order #{@order.id}"
      
      success(
        message: "Payment failure processed successfully",
        order: @order,
        failure_reason: @failure_reason,
        retry_strategy: @retry_strategy,
        email_sent: @email_sent
      )
    rescue => e
      Rails.logger.error "❌ [PaymentFailureService] Error processing payment failure for order #{@order.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      failure("Payment failure processing failed: #{e.message}")
    end

    private

    def update_order_status
      Rails.logger.info "❌ [PaymentFailureService] Updating order status for failed payment"
      
      update_attrs = {
        status: 'payment_failed',
        payment_failed_at: Time.current,
        payment_failure_reason: @failure_reason
      }
      
      update_attrs[:stripe_payment_intent_id] = @payment_intent_id if @payment_intent_id.present?
      
      @order.update!(update_attrs)
      
      Rails.logger.info "❌ [PaymentFailureService] Order #{@order.id} status updated to payment_failed"
    end

    def release_reserved_inventory
      Rails.logger.info "❌ [PaymentFailureService] Checking for reserved inventory to release"
      
      # If inventory was reserved (shouldn't be for failed payments, but safety check)
      begin
        @order.release_stock! if @order.respond_to?(:release_stock!)
        Rails.logger.info "❌ [PaymentFailureService] Released any reserved inventory"
      rescue => e
        Rails.logger.warn "❌ [PaymentFailureService] Could not release inventory: #{e.message}"
        # Don't fail the process for inventory issues
      end
    end

    def send_failure_notification
      Rails.logger.info "❌ [PaymentFailureService] Sending payment failure notification"
      
      begin
        result = EmailManagement::OrderEmailService.send_payment_failed(@order, @failure_reason)
        @email_sent = result[:success]
        
        if @email_sent
          Rails.logger.info "❌ [PaymentFailureService] Payment failure email sent successfully"
        else
          Rails.logger.error "❌ [PaymentFailureService] Failed to send payment failure email: #{result[:error]}"
        end
      rescue => e
        Rails.logger.error "❌ [PaymentFailureService] Error sending failure notification: #{e.message}"
        @email_sent = false
        # Don't fail the process for email issues
      end
    end

    def handle_retry_strategy
      Rails.logger.info "❌ [PaymentFailureService] Determining retry strategy"
      
      @retry_strategy = determine_retry_strategy(@failure_reason)
      
      case @retry_strategy[:type]
      when 'immediate_retry'
        # Customer can retry immediately
        Rails.logger.info "❌ [PaymentFailureService] Strategy: Immediate retry recommended"
        
      when 'delayed_retry'
        # Schedule retry attempt
        Rails.logger.info "❌ [PaymentFailureService] Strategy: Delayed retry scheduled"
        schedule_retry_reminder
        
      when 'manual_intervention'
        # Requires customer action (update payment method, etc.)
        Rails.logger.info "❌ [PaymentFailureService] Strategy: Manual intervention required"
        
      when 'permanent_failure'
        # Likely fraud or permanent issue
        Rails.logger.info "❌ [PaymentFailureService] Strategy: Permanent failure, no retry"
        mark_order_as_cancelled
        
      else
        Rails.logger.warn "❌ [PaymentFailureService] Strategy: Unknown, defaulting to immediate retry"
      end
      
      # Store retry strategy in order metadata for frontend reference
      @order.update!(
        retry_strategy: @retry_strategy[:type],
        retry_reason: @retry_strategy[:reason]
      )
    end

    def determine_retry_strategy(failure_reason)
      case failure_reason.downcase
      when /insufficient.funds/, /declined/, /card.declined/
        {
          type: 'immediate_retry',
          reason: 'Payment declined - customer can try different payment method',
          user_message: 'Your payment was declined. Please try a different payment method or contact your bank.',
          retry_delay: nil
        }
      when /expired.card/, /invalid.expiry/
        {
          type: 'manual_intervention',
          reason: 'Card expired - customer needs to update payment details',
          user_message: 'Your card has expired. Please update your payment information and try again.',
          retry_delay: nil
        }
      when /incorrect.cvc/, /invalid.cvc/
        {
          type: 'immediate_retry',
          reason: 'Incorrect CVC - customer can retry with correct details',
          user_message: 'The security code (CVC) was incorrect. Please check and try again.',
          retry_delay: nil
        }
      when /authentication.required/, /requires.action/
        {
          type: 'immediate_retry',
          reason: '3D Secure authentication required',
          user_message: 'Additional authentication is required. Please complete the verification and try again.',
          retry_delay: nil
        }
      when /processing.error/, /try.again/
        {
          type: 'delayed_retry',
          reason: 'Temporary processing error - retry after delay',
          user_message: 'There was a temporary processing error. Please try again in a few minutes.',
          retry_delay: 5.minutes
        }
      when /risk/, /fraud/, /blocked/
        {
          type: 'permanent_failure',
          reason: 'Payment blocked due to risk assessment',
          user_message: 'Your payment could not be processed. Please contact support for assistance.',
          retry_delay: nil
        }
      else
        {
          type: 'immediate_retry',
          reason: 'Unknown payment error',
          user_message: 'Your payment could not be processed. Please try again or contact support.',
          retry_delay: nil
        }
      end
    end

    def schedule_retry_reminder
      retry_delay = @retry_strategy[:retry_delay] || 30.minutes
      
      Rails.logger.info "❌ [PaymentFailureService] Scheduling retry reminder in #{retry_delay}"
      
      PaymentRetryReminderJob.set(wait: retry_delay).perform_later(@order.id)
    end

    def mark_order_as_cancelled
      Rails.logger.info "❌ [PaymentFailureService] Marking order as cancelled due to permanent failure"
      
      @order.update!(
        status: 'cancelled',
        cancelled_at: Time.current,
        cancellation_reason: 'permanent_payment_failure'
      )
    end

    def log_failure_analytics
      Rails.logger.info "❌ [PaymentFailureService] Logging payment failure analytics"
      
      # Use your existing Analytics::EventTrackingService
      Analytics::EventTrackingService.track_payment_failure(@order, {
        failure_reason: @failure_reason,
        retry_strategy: @retry_strategy[:type],
        payment_intent_id: @payment_intent_id,
        order_value: @order.total
      })
      
      Rails.logger.info "❌ [PaymentFailureService] Analytics tracked for order #{@order.id}"
      
      # Track failure patterns for fraud detection
      track_failure_patterns
    end

    def track_failure_patterns
      # Track patterns that might indicate fraud or systematic issues
      recent_failures = Order.where(
        user_id: @user.id,
        status: 'payment_failed',
        created_at: 24.hours.ago..Time.current
      ).count
      
      if recent_failures >= 3
        Rails.logger.warn "❌ [PaymentFailureService] Multiple payment failures detected for user #{@user.id} (#{recent_failures} in 24h)"
        
        # Trigger fraud review workflow using existing user management
        Security::FraudReviewJob.perform_later(@user.id, {
          trigger: 'multiple_payment_failures',
          failure_count: recent_failures,
          latest_failure_reason: @failure_reason,
          order_id: @order.id
        })
      end
      
      # Track failure reasons for optimization using Redis
      Rails.cache.increment("payment_failures:#{@failure_reason.parameterize}", 1, expires_in: 1.week)
    end

    def success(data)
      { success: true }.merge(data)
    end

    def failure(message)
      { success: false, error: message }
    end
  end
end