# app/services/cart_service.rb
class CartService
    def initialize(session)
      @session = session
      @session[:cart] ||= {}
    end
  
    def add_item(product_id, quantity = 1)
      @session[:cart][product_id.to_s] ||= 0
      @session[:cart][product_id.to_s] += quantity.to_i
    end
  
    def remove_item(product_id)
      @session[:cart].delete(product_id.to_s)
    end
  
    def update_quantity(product_id, quantity)
      return remove_item(product_id) if quantity.to_i <= 0
      @session[:cart][product_id.to_s] = quantity.to_i
    end
  
    def items
      Product.where(id: @session[:cart].keys).map do |product|
        {
          product: product,
          quantity: @session[:cart][product.id.to_s],
          subtotal: product.price * @session[:cart][product.id.to_s]
        }
      end
    end
  
    def total
      items.sum { |item| item[:subtotal] }
    end
  
    def count
      @session[:cart].values.sum
    end
  
    def clear
      @session[:cart] = {}
    end
  end