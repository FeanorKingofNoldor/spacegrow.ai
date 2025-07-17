# app/models/order.rb - ENHANCED for Payment Processing
class Order < ApplicationRecord
  include Emailable  # ✅ Email tracking concern

  belongs_to :user
  has_many :line_items, dependent: :destroy
  has_many :devices, dependent: :nullify
  has_many :products, through: :line_items
  has_many :device_activation_tokens, dependent: :destroy

  validates :status, inclusion: { in: %w[pending paid completed refunded payment_failed cancelled] }

  # ✅ NEW: Payment processing callbacks
  after_update :handle_paid_status, if: :paid?
  after_update :handle_refunded_status, if: :refunded?
  after_update :handle_completed_status, if: :completed?
  after_update :handle_payment_failed_status, if: :payment_failed?
  after_update_commit :send_order_emails, if: :just_became_paid?

  def total
    line_items.sum(&:subtotal)
  end

  # ✅ ENHANCED: Status checking methods
  def paid?
    status == 'paid'
  end

  def completed?
    status == 'completed'
  end

  def refunded?
    status == 'refunded'
  end

  def pending?
    status == 'pending'
  end

  def payment_failed?
    status == 'payment_failed'
  end

  def cancelled?
    status == 'cancelled'
  end

  # ✅ NEW: Payment processing helper methods
  def can_be_retried?
    payment_failed? && retry_strategy != 'permanent_failure'
  end

  def retry_payment_url
    return nil unless can_be_retried?
    "#{Rails.application.config.app_host}/shop/checkout?retry_order_id=#{id}"
  end

  def payment_failure_user_message
    case retry_strategy
    when 'immediate_retry'
      retry_reason || 'Your payment was declined. Please try a different payment method.'
    when 'manual_intervention'
      retry_reason || 'Please update your payment information and try again.'
    when 'delayed_retry'
      retry_reason || 'There was a temporary processing error. Please try again in a few minutes.'
    when 'permanent_failure'
      retry_reason || 'Your payment could not be processed. Please contact support for assistance.'
    else
      'Your payment could not be processed. Please try again or contact support.'
    end
  end

  # ✅ ENHANCED: Email-related helper methods
  def has_devices?
    line_items.joins(:product).where.not(products: { device_type_id: nil }).exists?
  end

  def device_count
    line_items.joins(:product).where.not(products: { device_type_id: nil }).sum(:quantity)
  end

  def just_became_paid?
    saved_change_to_status? && status == 'paid' && status_before_last_save != 'paid'
  end

  def just_failed_payment?
    saved_change_to_status? && status == 'payment_failed' && status_before_last_save != 'payment_failed'
  end

  def needs_device_activation?
    paid? && has_devices? && device_activation_tokens.any?
  end

  # ✅ ENHANCED: Inventory management methods
  def items_available?
    line_items.all? { |item| item.product.can_purchase?(item.quantity) }
  end

  def reserve_stock!
    ActiveRecord::Base.transaction do
      line_items.each do |item|
        item.product.reduce_stock!(item.quantity)
      end
    end
  end

  def release_stock!
    ActiveRecord::Base.transaction do
      line_items.each do |item|
        item.product.add_stock!(item.quantity)
      end
    end
  end

  # ✅ NEW: Payment processing analytics
  def payment_processing_summary
    {
      order_id: id,
      status: status,
      total: total,
      payment_method: 'stripe',
      payment_intent_id: stripe_payment_intent_id,
      payment_completed_at: payment_completed_at,
      payment_failed_at: payment_failed_at,
      failure_reason: payment_failure_reason,
      retry_strategy: retry_strategy,
      device_count: device_count,
      emails_sent: {
        confirmation: confirmation_email_sent || false,
        activation: activation_emails_sent || false,
        payment_failure: payment_failure_email_sent || false
      }
    }
  end

  private

  def handle_paid_status
    Rails.logger.info "💳 [Order##{id}] Order status changed to paid, processing payment workflow"
    
    # This is now handled by PaymentProcessing::OrderCompletionService
    # The service does: reserve stock, generate tokens, send emails
  end

  def handle_payment_failed_status
    Rails.logger.info "❌ [Order##{id}] Order payment failed, processing failure workflow"
    
    # This is now handled by PaymentProcessing::PaymentFailureService
    # The service does: release stock, send failure emails, set retry strategy
  end

  def handle_completed_status
    Rails.logger.info "✅ [Order##{id}] Order completed successfully"
    
    # Final completion tasks
    update_user_statistics
    trigger_completion_analytics
  end

  def handle_refunded_status
    Rails.logger.info "↩️ [Order##{id}] Order refunded, processing refund workflow"
    
    # Return stock to inventory
    release_stock!
    
    # Expire activation tokens and handle activated devices
    device_activation_tokens.each do |token|
      if token.device.present? && token.device.activation_token == token && token.device.active?
        raise "Cannot refund order: Device #{token.device.name} is already activated"
      end

      token.update!(expires_at: Time.current)
      token.device&.destroy
    end
  end

  # ✅ KEPT: Email workflow (now enhanced)
  def send_order_emails
    Rails.logger.info "📧 [Order##{id}] Order became paid, triggering email workflow"
    
    # The email sending is now handled by PaymentProcessing::OrderCompletionService
    # This ensures emails are sent as part of the complete order workflow
  rescue => e
    Rails.logger.error "📧 [Order##{id}] Failed to trigger email workflow: #{e.message}"
    # Don't raise - email failures shouldn't break order processing
  end

  def update_user_statistics
    # Update user order statistics
    user.increment!(:orders_count) if user.respond_to?(:orders_count)
    user.increment!(:total_spent, total) if user.respond_to?(:total_spent)
  end

  def trigger_completion_analytics
    # TODO: Send to analytics service
    Rails.logger.info "📊 [Order##{id}] Order completion analytics: User #{user.id}, Total: $#{total}, Devices: #{device_count}"
  end
end