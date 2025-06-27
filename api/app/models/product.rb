# app/models/product.rb
class Product < ApplicationRecord
  belongs_to :device_type, optional: true
  has_many :line_items
  has_many :orders, through: :line_items

  validates :name, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :low_stock_threshold, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stripe_price_id, presence: true, unless: :seeding?

  # Set defaults
  after_initialize :set_defaults, if: :new_record?

  scope :active, -> { where(active: true) }
  scope :devices, -> { where.not(device_type_id: nil) }
  scope :accessories, -> { where(device_type_id: nil) }
  scope :featured, -> { where(featured: true) }
  scope :in_stock, -> { where('stock_quantity > 0') }
  scope :low_stock, -> { where('stock_quantity <= low_stock_threshold AND stock_quantity > 0') }
  scope :out_of_stock, -> { where(stock_quantity: 0) }

  def seeding?
    Rails.application.config.seeding
  end

  def device?
    device_type.present?
  end

  # Inventory methods
  def in_stock?
    stock_quantity > 0
  end

  def out_of_stock?
    stock_quantity <= 0
  end

  def low_stock?
    stock_quantity <= low_stock_threshold && stock_quantity > 0
  end

  def stock_status
    return 'out_of_stock' if out_of_stock?
    return 'low_stock' if low_stock?
    'in_stock'
  end

  def can_order?(quantity = 1)
    stock_quantity >= quantity
  end

  # Reduce stock when order is placed
  def reduce_stock!(quantity)
    if can_order?(quantity)
      update!(stock_quantity: stock_quantity - quantity)
      true
    else
      false
    end
  end

  # Increase stock when order is refunded
  def increase_stock!(quantity)
    update!(stock_quantity: stock_quantity + quantity)
  end

  # Get stock level description
  def stock_description
    case stock_status
    when 'out_of_stock'
      'Out of Stock'
    when 'low_stock'
      "Only #{stock_quantity} left!"
    when 'in_stock'
      if stock_quantity > 10
        'In Stock'
      else
        "#{stock_quantity} in stock"
      end
    end
  end

  private

  def set_defaults
    self.stock_quantity ||= 10
    self.low_stock_threshold ||= 3
    self.featured ||= false
    self.active ||= true
  end
end