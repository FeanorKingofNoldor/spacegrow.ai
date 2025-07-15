# Update your Order model to handle inventory
# app/models/order.rb
class Order < ApplicationRecord
  belongs_to :user
  has_many :line_items, dependent: :destroy
  has_many :devices, dependent: :nullify
  has_many :products, through: :line_items
  has_many :device_activation_tokens, dependent: :destroy

  validates :status, inclusion: { in: %w[pending paid completed refunded] }

  after_update :handle_paid_status, if: :paid?
  after_update :handle_refunded_status, if: :refunded?
  after_update :handle_completed_status, if: :completed?

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
    # Reserve stock when payment is confirmed
    if items_available?
      reserve_stock!
      DeviceManagement::DeviceManagement::DeviceManagement::ActivationTokenService.generate_for_order(self)
    else
      # Handle out of stock scenario
      update!(status: 'pending')
      # You might want to send a notification here
      Rails.logger.error "Order #{id} failed: Items out of stock"
    end
  end

  def handle_completed_status
    # Order is complete, stock is already reduced
    Rails.logger.info "Order #{id} completed successfully"
  end

  def handle_refunded_status
    # Return stock to inventory
    release_stock!
    
    line_items.each do |line_item|
      device_activation_tokens.each do |token|
        if token.device.present? && token.device.activation_token == token && token.device.active?
          raise "Cannot refund order: Device #{token.device.name} is already activated"
        end

        token.update!(expires_at: Time.current)
        token.device&.destroy
      end
    end
  end
end

# Update your LineItem model too
# app/models/line_item.rb
class LineItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :sufficient_stock, on: :create

  before_validation :set_price, on: :create

  def subtotal
    quantity * price
  end

  private

  def set_price
    self.price = product.price if price.nil? && product
  end

  def sufficient_stock
    return unless product && quantity

    unless product.can_purchase?(quantity)
      errors.add(:quantity, "Not enough stock available. Only #{product.stock_quantity} left.")
    end
  end
end