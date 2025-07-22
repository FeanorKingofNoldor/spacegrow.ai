# app/models/order.rb - ENHANCED for Admin + Payment Processing
class Order < ApplicationRecord
  include Emailable  # ✅ Email tracking concern

  belongs_to :user
  has_many :line_items, dependent: :destroy
  has_many :devices, dependent: :nullify
  has_many :products, through: :line_items
  has_many :device_activation_tokens, dependent: :destroy

  validates :status, inclusion: { in: %w[pending paid completed refunded payment_failed cancelled] }

  # ===== ADMIN-FRIENDLY SCOPES =====
  scope :in_date_range, ->(range) { where(created_at: range) }
  scope :completed, -> { where(status: 'completed') }
  scope :paid, -> { where(status: 'paid') }
  scope :failed_payments, -> { where(status: 'payment_failed') }
  scope :refunded, -> { where(status: 'refunded') }
  scope :pending, -> { where(status: 'pending') }
  scope :recent, -> { where(created_at: 24.hours.ago..) }
  scope :recent_failures, -> { failed_payments.where(created_at: 24.hours.ago..) }
  scope :with_devices, -> { joins(:line_items, line_items: :product).where.not(products: { device_type_id: nil }).distinct }
  scope :accessories_only, -> { joins(:line_items, line_items: :product).where(products: { device_type_id: nil }).distinct }
  scope :by_amount_range, ->(min, max) { where(total: min..max) if min && max }

  # ===== PAYMENT PROCESSING CALLBACKS =====
  after_update :handle_status_change, if: :saved_change_to_status?
  after_update_commit :send_order_emails, if: :just_became_paid?

  # ===== ADMIN ANALYTICS CLASS METHODS =====
  def self.analytics_for_period(period)
    date_range = DateRangeHelper.calculate_range(period)
    {
      total_orders: in_date_range(date_range).count,
      completed_orders: completed.in_date_range(date_range).count,
      paid_orders: paid.in_date_range(date_range).count,
      failed_orders: failed_payments.in_date_range(date_range).count,
      total_revenue: completed.in_date_range(date_range).sum(:total),
      avg_order_value: completed.in_date_range(date_range).average(:total)&.round(2) || 0,
      devices_sold: calculate_devices_sold(date_range),
      accessories_sold: calculate_accessories_sold(date_range)
    }
  end

  def self.admin_overview(limit: 20)
    {
      recent_orders: includes(:user).order(created_at: :desc).limit(limit).map(&:admin_summary),
      pending_orders: pending.count,
      failed_payments_count: failed_payments.count,
      revenue_today: completed.where(created_at: Date.current.all_day).sum(:total)
    }
  end

  # ===== ADMIN HELPER METHODS =====
  def admin_summary
    {
      id: id,
      user_email: user.email,
      status: status,
      total: total,
      device_count: device_count,
      created_at: created_at,
      payment_failure_reason: payment_failure_reason,
      can_retry: can_be_retried?
    }
  end

  def admin_actions_available
    actions = []
    actions << 'retry_payment' if can_be_retried?
    actions << 'refund' if can_be_refunded?
    actions << 'generate_tokens' if needs_device_activation?
    actions << 'update_status' unless %w[completed refunded].include?(status)
    actions
  end

  # ===== BUSINESS LOGIC METHODS =====
  def total
    line_items.sum(&:subtotal)
  end

  # Status checking methods
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

  # Payment processing helper methods
  def can_be_retried?
    payment_failed? && retry_strategy != 'permanent_failure'
  end

  def can_be_refunded?
    %w[paid completed].include?(status) && (refund_amount.nil? || refund_amount < total)
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

  # Device and product helper methods
  def has_devices?
    line_items.joins(:product).where.not(products: { device_type_id: nil }).exists?
  end

  def device_count
    line_items.joins(:product).where.not(products: { device_type_id: nil }).sum(:quantity)
  end

  def accessory_count
    line_items.joins(:product).where(products: { device_type_id: nil }).sum(:quantity)
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

  # Inventory management methods
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

  # Analytics and reporting
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

  # ===== SIMPLIFIED CALLBACKS =====
  def handle_status_change
    case status
    when 'paid'
      handle_paid_status
    when 'payment_failed'
      handle_payment_failed_status
    when 'completed'
      handle_completed_status
    when 'refunded'
      handle_refunded_status
    end
  end

  def handle_paid_status
    Rails.logger.info "💳 [Order##{id}] Order status changed to paid, processing payment workflow"
    # Delegate to service - don't do complex logic in callback
  end

  def handle_payment_failed_status
    Rails.logger.info "❌ [Order##{id}] Order payment failed, processing failure workflow"
    # Delegate to service - don't do complex logic in callback
  end

  def handle_completed_status
    Rails.logger.info "✅ [Order##{id}] Order completed successfully"
    update_user_statistics
    trigger_completion_analytics
  end

  def handle_refunded_status
    Rails.logger.info "↩️ [Order##{id}] Order refunded, processing refund workflow"
    
    # Simple refund logic - complex logic should be in service
    release_stock!
    expire_activation_tokens!
  end

  def expire_activation_tokens!
    device_activation_tokens.each do |token|
      if token.device.present? && token.device.activation_token == token && token.device.active?
        raise "Cannot refund order: Device #{token.device.name} is already activated"
      end

      token.update!(expires_at: Time.current)
      token.device&.destroy
    end
  end

  def send_order_emails
    Rails.logger.info "📧 [Order##{id}] Order became paid, triggering email workflow"
    # Email sending handled by PaymentProcessing::OrderCompletionService
  rescue => e
    Rails.logger.error "📧 [Order##{id}] Failed to trigger email workflow: #{e.message}"
    # Don't raise - email failures shouldn't break order processing
  end

  def update_user_statistics
    user.increment!(:orders_count) if user.respond_to?(:orders_count)
    user.increment!(:total_spent, total) if user.respond_to?(:total_spent)
  end

  def trigger_completion_analytics
    Rails.logger.info "📊 [Order##{id}] Order completion analytics: User #{user.id}, Total: $#{total}, Devices: #{device_count}"
  end

  # ===== PRIVATE CLASS METHODS FOR ANALYTICS =====
  def self.calculate_devices_sold(date_range)
    with_devices.completed.in_date_range(date_range)
              .joins(:line_items, line_items: :product)
              .where.not(products: { device_type_id: nil })
              .sum('line_items.quantity')
  end

  def self.calculate_accessories_sold(date_range)
    accessories_only.completed.in_date_range(date_range)
                   .joins(:line_items, line_items: :product)
                   .where(products: { device_type_id: nil })
                   .sum('line_items.quantity')
  end
end