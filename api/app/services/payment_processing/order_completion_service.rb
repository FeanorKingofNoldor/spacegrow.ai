# app/services/payment_processing/order_completion_service.rb
module PaymentProcessing
  class OrderCompletionService < ApplicationService
    def self.call(order:, payment_intent_id: nil)
      new(order, payment_intent_id).call
    end

    def initialize(order, payment_intent_id = nil)
      @order = order
      @payment_intent_id = payment_intent_id
      @user = order.user
    end

    def call
      Rails.logger.info "🎯 [OrderCompletionService] Starting order completion for order #{@order.id}"
      
      ActiveRecord::Base.transaction do
        validate_order_state
        update_order_status
        reserve_inventory
        generate_device_activation_tokens
        send_confirmation_emails
        trigger_post_completion_workflows
      end

      Rails.logger.info "🎯 [OrderCompletionService] Order #{@order.id} completed successfully"
      
      success(
        message: "Order completed successfully",
        order: @order,
        emails_sent: @emails_sent,
        activation_tokens_generated: @tokens_generated,
        devices_count: @device_count
      )
    rescue => e
      Rails.logger.error "🎯 [OrderCompletionService] Error completing order #{@order.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Attempt to rollback order to pending state
      @order.update(status: 'pending') if @order.paid?
      
      failure("Order completion failed: #{e.message}")
    end

    private

    def validate_order_state
      Rails.logger.info "🎯 [OrderCompletionService] Validating order state for order #{@order.id}"
      
      raise "Order not found" unless @order
      raise "Order already completed" if @order.completed?
      raise "Order is refunded" if @order.refunded?
      raise "Order has no line items" if @order.line_items.empty?
      
      # Check inventory availability
      unless @order.items_available?
        Rails.logger.error "🎯 [OrderCompletionService] Inventory not available for order #{@order.id}"
        raise "Insufficient inventory for order completion"
      end
      
      Rails.logger.info "🎯 [OrderCompletionService] Order validation passed"
    end

    def update_order_status
      Rails.logger.info "🎯 [OrderCompletionService] Updating order status to paid"
      
      update_attrs = {
        status: 'paid',
        payment_completed_at: Time.current
      }
      
      update_attrs[:stripe_payment_intent_id] = @payment_intent_id if @payment_intent_id.present?
      
      @order.update!(update_attrs)
      
      Rails.logger.info "🎯 [OrderCompletionService] Order #{@order.id} status updated to paid"
    end

    def reserve_inventory
      Rails.logger.info "🎯 [OrderCompletionService] Reserving inventory for order #{@order.id}"
      
      @order.reserve_stock!
      
      Rails.logger.info "🎯 [OrderCompletionService] Inventory reserved for #{@order.line_items.count} items"
    end

    def generate_device_activation_tokens
      Rails.logger.info "🎯 [OrderCompletionService] Checking for device products in order #{@order.id}"
      
      device_line_items = @order.line_items.joins(:product).where.not(products: { device_type_id: nil })
      
      if device_line_items.any?
        @device_count = device_line_items.sum(:quantity)
        Rails.logger.info "🎯 [OrderCompletionService] Found #{@device_count} device(s), generating activation tokens"
        
        # Use existing DeviceManagement service
        tokens = DeviceManagement::ActivationTokenService.generate_for_order(@order)
        @tokens_generated = tokens&.count || 0
        
        Rails.logger.info "🎯 [OrderCompletionService] Generated #{@tokens_generated} activation tokens"
      else
        @device_count = 0
        @tokens_generated = 0
        Rails.logger.info "🎯 [OrderCompletionService] No device products found, skipping token generation"
      end
    end

    def send_confirmation_emails
      Rails.logger.info "🎯 [OrderCompletionService] Sending confirmation emails for order #{@order.id}"
      
      @emails_sent = []
      
      # Send order confirmation email
      confirmation_result = EmailManagement::OrderEmailService.send_confirmation(@order)
      if confirmation_result[:success]
        @emails_sent << 'order_confirmation'
        Rails.logger.info "🎯 [OrderCompletionService] Order confirmation email sent successfully"
      else
        Rails.logger.error "🎯 [OrderCompletionService] Failed to send order confirmation: #{confirmation_result[:error]}"
        # Don't fail the entire process for email issues, but log the error
      end
      
      # Send device activation instructions if order has devices
      if @device_count > 0
        activation_result = EmailManagement::OrderEmailService.send_activation_instructions(@order)
        if activation_result[:success]
          @emails_sent << 'device_activation'
          Rails.logger.info "🎯 [OrderCompletionService] Device activation emails sent successfully"
        else
          Rails.logger.error "🎯 [OrderCompletionService] Failed to send activation instructions: #{activation_result[:error]}"
        end
      end
      
      Rails.logger.info "🎯 [OrderCompletionService] Email sending completed. Sent: #{@emails_sent.join(', ')}"
    end

    def trigger_post_completion_workflows
      Rails.logger.info "🎯 [OrderCompletionService] Triggering post-completion workflows"
      
      # Update user statistics
      @user.increment!(:orders_count) if @user.respond_to?(:orders_count)
      
      # Trigger analytics tracking
      track_order_completion_analytics
      
      # Trigger any subscription updates if needed
      handle_subscription_impacts
      
      # Schedule follow-up communications
      schedule_follow_up_emails
      
      Rails.logger.info "🎯 [OrderCompletionService] Post-completion workflows triggered"
    end

    def track_order_completion_analytics
      # Use your existing Analytics::EventTrackingService instead of paid services
      Analytics::EventTrackingService.track_order_completion(@order, {
        devices_count: @device_count,
        payment_intent_id: @payment_intent_id,
        emails_sent: @emails_sent,
        activation_tokens_generated: @tokens_generated,
        completion_time: Time.current
      })
      
      Rails.logger.info "📊 [OrderCompletionService] Analytics tracked: Order #{@order.id} completed - $#{@order.total}, #{@device_count} devices"
    end

    def handle_subscription_impacts
      # Check if order contains subscription-related products
      subscription_items = @order.line_items.joins(:product).where("products.name ILIKE ANY (ARRAY[?, ?, ?])", 
        "%subscription%", "%plan%", "%upgrade%")
      
      if subscription_items.any?
        Rails.logger.info "🎯 [OrderCompletionService] Order contains subscription products, processing subscription updates"
        
        subscription_items.each do |item|
          # Extract plan information from product metadata or name
          plan_name = extract_plan_from_product(item.product)
          
          if plan_name.present?
            plan = Plan.find_by(name: plan_name)
            if plan
              SubscriptionManagement::SubscriptionService.create_subscription(
                user: @user,
                plan: plan,
                interval: 'month'
              )
              Rails.logger.info "🎯 [OrderCompletionService] Created subscription for user #{@user.id}, plan: #{plan.name}"
            end
          end
        end
      end
    end

    def schedule_follow_up_emails
      # Schedule follow-up emails for better user experience
      case @device_count
      when 0
        # No devices - schedule accessory follow-up
        Rails.logger.info "🎯 [OrderCompletionService] Scheduling accessory order follow-up"
        AccessoryFollowUpEmailJob.set(wait: 2.days).perform_later(@order.id)
      when 1..2
        # Few devices - schedule setup help email
        Rails.logger.info "🎯 [OrderCompletionService] Scheduling device setup help email"
        SetupHelpEmailJob.set(wait: 1.day).perform_later(@order.id)
      else
        # Many devices - schedule pro user onboarding
        Rails.logger.info "🎯 [OrderCompletionService] Scheduling pro user onboarding"
        ProOnboardingEmailJob.set(wait: 1.day).perform_later(@order.id)
      end
    end

    def success(data)
      { success: true }.merge(data)
    end

    def failure(message)
      { success: false, error: message }
    end
  end

  def extract_plan_from_product(product)
    # Extract plan name from product name or metadata
    case product.name.downcase
    when /basic.*plan/i, /basic.*subscription/i
      'Basic'
    when /professional.*plan/i, /pro.*plan/i, /professional.*subscription/i
      'Professional'
    when /enterprise.*plan/i, /enterprise.*subscription/i
      'Enterprise'
    else
      nil
    end
  end
end