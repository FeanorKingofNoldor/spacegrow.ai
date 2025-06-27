# app/controllers/api/v1/store/cart_controller.rb
class Api::V1::Store::CartsController < Api::V1::Store::BaseController
  before_action :set_cart

  def show
    render json: {
      status: 'success',
      data: cart_json
    }
  end

  def add
    product = Product.find(params[:product_id])
    quantity = [params[:quantity].to_i, 1].max
    
    existing_item = @cart[:items].find { |item| item[:product_id] == product.id.to_s }
    
    if existing_item
      existing_item[:quantity] += quantity
      existing_item[:subtotal] = existing_item[:quantity] * product.price
    else
      @cart[:items] << {
        id: SecureRandom.uuid,
        product_id: product.id.to_s,
        product: enhanced_product_json(product),
        quantity: quantity,
        subtotal: quantity * product.price
      }
    end
    
    update_cart_totals
    store_cart
    
    render json: {
      status: 'success',
      message: "#{product.name} added to cart",
      data: cart_json
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: 'Product not found'
    }, status: :not_found
  end

  def remove
    @cart[:items].reject! { |item| item[:product_id] == params[:product_id] }
    
    update_cart_totals
    store_cart
    
    render json: {
      status: 'success',
      message: 'Item removed from cart',
      data: cart_json
    }
  end

  def update_quantity
    item = @cart[:items].find { |item| item[:product_id] == params[:product_id] }
    
    if item
      new_quantity = [params[:quantity].to_i, 0].max
      
      if new_quantity == 0
        @cart[:items].reject! { |item| item[:product_id] == params[:product_id] }
      else
        item[:quantity] = new_quantity
        item[:subtotal] = item[:quantity] * item[:product][:price]
      end
      
      update_cart_totals
      store_cart
      
      render json: {
        status: 'success',
        message: 'Cart updated',
        data: cart_json
      }
    else
      render json: {
        status: 'error',
        message: 'Item not found in cart'
      }, status: :not_found
    end
  end

  def clear
    @cart = { items: [], total: 0, count: 0 }
    store_cart
    
    render json: {
      status: 'success',
      message: 'Cart cleared',
      data: cart_json
    }
  end

  private

  def set_cart
    @cart = retrieve_cart
  end

  def retrieve_cart
    if current_user
      # For authenticated users, store cart in database or session
      session[:cart] || { items: [], total: 0, count: 0 }
    else
      # For guest users, use session storage
      session[:cart] || { items: [], total: 0, count: 0 }
    end
  end

  def store_cart
    if current_user
      # Store in session for now (could be database later)
      session[:cart] = @cart
    else
      session[:cart] = @cart
    end
  end

  def update_cart_totals
    @cart[:total] = @cart[:items].sum { |item| item[:subtotal] }.round(2)
    @cart[:count] = @cart[:items].sum { |item| item[:quantity] }
  end

  def cart_json
    {
      items: @cart[:items],
      total: @cart[:total],
      count: @cart[:count]
    }
  end

  def enhanced_product_json(product)
    {
      id: product.id.to_s,
      name: product.name,
      description: product.description,
      price: product.price.to_f,
      image: product_image_url(product),
      category: product.device_type&.name || 'Accessories',
      features: extract_features(product),
      in_stock: product.in_stock || true,
      active: product.active
    }
  end

  def product_image_url(product)
    if product.respond_to?(:image) && product.image.attached?
      Rails.application.routes.url_helpers.rails_blob_url(product.image, only_path: true)
    else
      'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=400&h=400&fit=crop'
    end
  end

  def extract_features(product)
    case product.device_type&.name
    when 'Environmental Monitor V1'
      ['Temperature Sensor', 'Humidity Sensor', 'Pressure Sensor', 'Wi-Fi Connectivity']
    when 'Liquid Monitor V1'
      ['pH Sensor', 'EC Sensor', 'Temperature Sensor', 'Automatic Dosing']
    else
      ['Professional Quality', 'Easy Installation', 'Long Lasting']
    end
  end

  def current_user
    # Implement your authentication logic here
    # For now, return nil for guest users
    nil
  end
end