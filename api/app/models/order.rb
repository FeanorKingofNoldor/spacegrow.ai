# app/models/order.rb - UPDATED with Emailable concern
class Order < ApplicationRecord
  include Emailable  # ✅ NEW: Email tracking concern

  belongs_to :user
  has_many :line_items, dependent: :destroy
  has_many :devices, dependent: :nullify
  has_many :products, through: :line_items
  has_many :device_activation_tokens, dependent: :destroy

  validates :status, inclusion: { in: %w[pending paid completed refunded] }

  # ✅ NEW: Add email tracking callbacks
  after_update :handle_paid_status, if: :paid?
  after_update :handle_refunded_status, if: :refunded?
  after_update :handle_completed_status, if: :completed?
  after_update_commit :send_order_emails, if: :just_became_paid?

  def total
    line_items.sum(&:subtotal)
  end

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

  # ✅ NEW: Email-related helper methods
  def has_devices?
    line_items.joins(:product).where.not(products: { device_type_id: nil }).exists?
  end

  def device_count
    line_items.joins(:product).where.not(products: { device_type_id: nil }).sum(:quantity)
  end

  def just_became_paid?
    saved_change_to_status? && status == 'paid' && status_before_last_save != 'paid'
  end

  def needs_device_activation?
    paid? && has_devices? && device_activation_tokens.any?
  end

  # Check if all items are available in stock
  def items_available?
    line_items.all? { |item| item.product.can_purchase?(item.quantity) }
  end

  # Reserve stock for this order
  def reserve_stock!
    ActiveRecord::Base.transaction do
      line_items.each do |item|
        item.product.reduce_stock!(item.quantity)
      end
    end
  end

  # Release reserved stock (if order is cancelled)
  def release_stock!
    ActiveRecord::Base.transaction do
      line_items.each do |item|
        item.product.add_stock!(item.quantity)
      end
    end
  end

  private

  def handle_paid_status
    Rails.logger.info "💳 [Order##{id}] Order status changed to paid, processing payment workflow"
    
    # Reserve stock when payment is confirmed
    if items_available?
      reserve_stock!
      
      # Generate activation tokens for device products
      device_line_items = line_items.joins(:product).where.not(products: { device_type_id: nil })
      if device_line_items.any?
        DeviceManagement::ActivationTokenService.generate_for_order(self)
        Rails.logger.info "💳 [Order##{id}] Generated activation tokens for #{device_line_items.sum(:quantity)} device(s)"
      end
    else
      # Handle out of stock scenario
      update!(status: 'pending')
      Rails.logger.error "💳 [Order##{id}] Payment failed: Items out of stock"
    end
  end

  def handle_completed_status
    Rails.logger.info "✅ [Order##{id}] Order completed successfully"
  end

  def handle_refunded_status
    Rails.logger.info "↩️ [Order##{id}] Order refunded, releasing stock and expiring tokens"
    
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

  # ✅ NEW: Email workflow triggered after order becomes paid
  def send_order_emails
    Rails.logger.info "📧 [Order##{id}] Triggering order email workflow"
    
    # Use the EmailManagement service for all email logic
    EmailManagement::OrderEmailService.send_complete_order_flow
  rescue => e
    Rails.logger.error "📧 [Order##{id}] Failed to send order emails: #{e.message}"
    # Don't raise - email failures shouldn't break order processing
  end
end