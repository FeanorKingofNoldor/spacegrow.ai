# app/models/product.rb - COMPLETE VERSION
class Product < ApplicationRecord
  belongs_to :device_type, optional: true
  has_many :line_items
  has_many :orders, through: :line_items

  validates :name, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stripe_price_id, presence: true, unless: -> { Rails.env.development? || Rails.env.test? }

  scope :active, -> { where(active: true) }
  scope :devices, -> { where.not(device_type_id: nil) }
  scope :accessories, -> { where(device_type_id: nil) }
  scope :in_stock, -> { where('stock_quantity > ?', 0) }
  scope :low_stock, -> { where('stock_quantity <= low_stock_threshold AND stock_quantity > 0') }
  scope :out_of_stock, -> { where(stock_quantity: 0) }
  scope :featured, -> { where(featured: true) }

  def device?
    device_type.present?
  end

  def can_purchase?(quantity = 1)
    active? && in_stock? && stock_quantity >= quantity
  end
  
  alias_method :can_order?, :can_purchase?

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

  def stock_description
    case stock_status
    when 'out_of_stock'
      'Out of stock'
    when 'low_stock'
      "Only #{stock_quantity} left!"
    when 'in_stock'
      'In stock'
    end
  end

  def reduce_stock!(quantity)
    update!(stock_quantity: [stock_quantity - quantity, 0].max)
  end

  def add_stock!(quantity)
    increment!(:stock_quantity, quantity)
  end

  def stock_quantity
    super || 1000
  end

  def low_stock_threshold
    super || 10
  end

  def featured
    super || false
  end
end