# app/services/payment_processing/stripe_webhook_service.rb
module PaymentProcessing
  class StripeWebhookService < ApplicationService
    def initialize(event)
      @event = event
    end

    def call
      Rails.logger.info "💳 [StripeWebhookService] Processing webhook: #{@event.type} (#{@event.id})"
      
      case @event.type
      when 'checkout.session.completed'
        handle_checkout_session_completed
      when 'payment_intent.succeeded'
        handle_payment_intent_succeeded
      when 'payment_intent.payment_failed'
        handle_payment_intent_failed
      when 'invoice.payment_succeeded'
        handle_invoice_payment_succeeded
      when 'invoice.payment_failed'
        handle_invoice_payment_failed
      when 'customer.subscription.created'
        handle_subscription_created
      when 'customer.subscription.updated'
        handle_subscription_updated
      when 'customer.subscription.deleted'
        handle_subscription_deleted
      else
        Rails.logger.info "💳 [StripeWebhookService] Unhandled webhook type: #{@event.type}"
        success(message: "Webhook type #{@event.type} acknowledged but not processed")
      end
    rescue => e
      Rails.logger.error "💳 [StripeWebhookService] Error processing webhook #{@event.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      failure("Webhook processing failed: #{e.message}")
    end

    private

    # ===== CHECKOUT & ORDERS =====
    
    def handle_checkout_session_completed
      session = @event.data.object
      Rails.logger.info "💳 [StripeWebhookService] Processing checkout session: #{session.id}"
      
      # Extract order information from metadata
      user_id = session.metadata&.dig('user_id')
      order_id = session.metadata&.dig('order_id')
      
      if order_id.present?
        # Order already exists - mark as paid
        order = Order.find_by(id: order_id)
        if order
          OrderCompletionService.call(order: order, payment_intent_id: session.payment_intent)
        else
          Rails.logger.error "💳 [StripeWebhookService] Order #{order_id} not found for session #{session.id}"
          return failure("Order not found")
        end
      elsif user_id.present?
        # Create order from session data (for direct Stripe Checkout)
        user = User.find_by(id: user_id)
        if user
          order = create_order_from_session(user, session)
          OrderCompletionService.call(order: order, payment_intent_id: session.payment_intent)
        else
          Rails.logger.error "💳 [StripeWebhookService] User #{user_id} not found for session #{session.id}"
          return failure("User not found")
        end
      else
        Rails.logger.error "💳 [StripeWebhookService] No user_id or order_id in session metadata: #{session.id}"
        return failure("Missing required metadata")
      end
      
      success(message: "Checkout session completed successfully")
    end

    def handle_payment_intent_succeeded
      payment_intent = @event.data.object
      Rails.logger.info "💳 [StripeWebhookService] Payment succeeded: #{payment_intent.id}"
      
      # Find order by payment intent ID or metadata
      order = find_order_by_payment_intent(payment_intent)
      
      if order
        OrderCompletionService.call(order: order, payment_intent_id: payment_intent.id)
        success(message: "Payment intent succeeded, order completed")
      else
        Rails.logger.warn "💳 [StripeWebhookService] No order found for payment intent: #{payment_intent.id}"
        success(message: "Payment succeeded but no order found")
      end
    end

    def handle_payment_intent_failed
      payment_intent = @event.data.object
      Rails.logger.info "💳 [StripeWebhookService] Payment failed: #{payment_intent.id}"
      
      order = find_order_by_payment_intent(payment_intent)
      
      if order
        failure_reason = payment_intent.last_payment_error&.message || 'Payment failed'
        PaymentFailureService.call(order: order, failure_reason: failure_reason, payment_intent_id: payment_intent.id)
        success(message: "Payment failure processed")
      else
        Rails.logger.warn "💳 [StripeWebhookService] No order found for failed payment intent: #{payment_intent.id}"
        success(message: "Payment failed but no order found")
      end
    end

    # ===== SUBSCRIPTION HANDLING =====
    
    def handle_subscription_created
      subscription = @event.data.object
      Rails.logger.info "💳 [StripeWebhookService] Subscription created: #{subscription.id}"
      
      user = find_user_by_stripe_customer(subscription.customer)
      if user
        # Map Stripe price ID to your plan
        plan = find_plan_by_stripe_price(subscription.items.data.first.price.id)
        
        if plan
          # Use your existing SubscriptionManagement service
          result = SubscriptionManagement::SubscriptionService.create_subscription(
            user: user,
            plan: plan,
            interval: subscription.items.data.first.price.recurring.interval
          )
          
          if result.persisted?
            # Update with Stripe-specific data
            result.update!(
              stripe_subscription_id: subscription.id,
              stripe_customer_id: subscription.customer,
              current_period_start: Time.at(subscription.current_period_start),
              current_period_end: Time.at(subscription.current_period_end)
            )
            
            Rails.logger.info "💳 [StripeWebhookService] Successfully created subscription for user #{user.id}"
          end
        else
          Rails.logger.error "💳 [StripeWebhookService] Could not find plan for price ID: #{subscription.items.data.first.price.id}"
        end
      end
      
      success(message: "Subscription created and integrated")
    end

    def handle_subscription_updated
      subscription = @event.data.object
      Rails.logger.info "💳 [StripeWebhookService] Subscription updated: #{subscription.id}"
      
      user = find_user_by_stripe_customer(subscription.customer)
      if user && user.subscription
        user.subscription.update!(
          status: subscription.status,
          current_period_start: Time.at(subscription.current_period_start),
          current_period_end: Time.at(subscription.current_period_end)
        )
        Rails.logger.info "💳 [StripeWebhookService] Updated subscription for user #{user.id}"
      end
      
      success(message: "Subscription updated")
    end

    def handle_subscription_deleted
      subscription = @event.data.object
      Rails.logger.info "💳 [StripeWebhookService] Subscription cancelled: #{subscription.id}"
      
      user = find_user_by_stripe_customer(subscription.customer)
      if user && user.subscription
        user.subscription.update!(status: 'canceled')
        Rails.logger.info "💳 [StripeWebhookService] Cancelled subscription for user #{user.id}"
      end
      
      success(message: "Subscription cancelled")
    end

    # ===== INVOICE HANDLING =====
    
    def handle_invoice_payment_succeeded
      invoice = @event.data.object
      Rails.logger.info "💳 [StripeWebhookService] Invoice payment succeeded: #{invoice.id}"
      
      # Handle recurring subscription payments
      if invoice.subscription
        user = find_user_by_stripe_customer(invoice.customer)
        if user && user.subscription
          Rails.logger.info "💳 [StripeWebhookService] Recurring payment succeeded for user #{user.id}"
          
          # Send receipt email using existing email service
          EmailManagement::SubscriptionEmailService.send_payment_receipt(user.subscription, {
            invoice_id: invoice.id,
            amount: invoice.amount_paid / 100.0,
            currency: invoice.currency,
            payment_date: Time.at(invoice.status_transitions.paid_at),
            period_start: Time.at(invoice.period_start),
            period_end: Time.at(invoice.period_end)
          })
          
          # Update billing records
          user.subscription.update!(
            last_payment_at: Time.at(invoice.status_transitions.paid_at),
            current_period_start: Time.at(invoice.period_start),
            current_period_end: Time.at(invoice.period_end)
          )
        end
      end
      
      success(message: "Invoice payment processed and receipt sent")
    end

    def handle_invoice_payment_failed
      invoice = @event.data.object
      Rails.logger.info "💳 [StripeWebhookService] Invoice payment failed: #{invoice.id}"
      
      if invoice.subscription
        user = find_user_by_stripe_customer(invoice.customer)
        if user && user.subscription
          Rails.logger.info "💳 [StripeWebhookService] Recurring payment failed for user #{user.id}"
          
          # Update subscription status
          user.subscription.update!(status: 'past_due')
          
          # Send payment failure notification
          EmailManagement::SubscriptionEmailService.send_payment_failed_notification(user.subscription, {
            invoice_id: invoice.id,
            amount: invoice.amount_due / 100.0,
            currency: invoice.currency,
            failure_reason: invoice.last_finalization_error&.message || 'Payment failed',
            retry_url: generate_payment_retry_url(user, invoice)
          })
          
          # Handle dunning - grace period before suspension
          if user.subscription.grace_period_expired?
            DeviceManagement::ManagementService.suspend_devices(
              user.devices.operational.pluck(:id),
              reason: 'subscription_payment_failure'
            )
          else
            # Schedule suspension if payment not resolved
            SubscriptionSuspensionJob.set(wait: 7.days).perform_later(user.subscription.id)
          end
        end
      end
      
      success(message: "Invoice payment failure processed")
    end

    def generate_payment_retry_url(user, invoice)
      "#{Rails.application.config.app_host}/billing/retry?invoice_id=#{invoice.id}&user_id=#{user.id}"
    end

    # ===== HELPER METHODS =====
    
    def create_order_from_session(user, session)
      Rails.logger.info "💳 [StripeWebhookService] Creating order from session for user #{user.id}"
      
      Order.create!(
        user: user,
        status: 'pending',
        total: session.amount_total / 100.0,
        stripe_session_id: session.id
      )
    end

    def find_order_by_payment_intent(payment_intent)
      # Try to find order by payment intent ID in metadata first
      if payment_intent.metadata&.dig('order_id')
        return Order.find_by(id: payment_intent.metadata['order_id'])
      end
      
      # Fallback: find by stripe session or other identifiers
      # This might need adjustment based on how you store Stripe references
      Order.where(status: ['pending', 'processing'])
           .where('created_at > ?', 1.hour.ago)
           .where(user_id: find_user_by_payment_intent(payment_intent)&.id)
           .first
    end

    def find_user_by_payment_intent(payment_intent)
      # Extract user information from payment intent metadata
      if payment_intent.metadata&.dig('user_id')
        User.find_by(id: payment_intent.metadata['user_id'])
      end
    end

    def find_user_by_stripe_customer(customer_id)
      # Assuming you store stripe_customer_id on users
      User.find_by(stripe_customer_id: customer_id)
    end

    def success(data)
      { success: true }.merge(data)
    end

    def failure(message)
      { success: false, error: message }
    end
  end

  def find_plan_by_stripe_price(stripe_price_id)
    Plan.find_by(stripe_monthly_price_id: stripe_price_id) || 
    Plan.find_by(stripe_yearly_price_id: stripe_price_id)
  end

end