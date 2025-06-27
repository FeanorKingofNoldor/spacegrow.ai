# app/models/line_item.rb
class LineItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :set_price, on: :create

  def subtotal
    quantity * price
  end

  private

  def set_price
    self.price = product.price if price.nil? && product
  end
end