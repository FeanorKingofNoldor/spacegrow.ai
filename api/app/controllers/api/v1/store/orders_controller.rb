# app/controllers/api/v1/store/orders_controller.rb
class Api::V1::Store::OrdersController < Api::V1::Store::BaseController
  before_action :set_order, only: [:show]

  def index
    orders = current_user.orders.includes(:line_items, :products)
                        .order(created_at: :desc)
    
    render json: {
      status: 'success',
      data: {
        orders: orders.map { |order| order_json(order) }
      }
    }
  end

  def show
    render json: {
      status: 'success',
      data: {
        order: detailed_order_json(@order)
      }
    }
  end

  def create
    # Create order from current cart or direct product purchase
    if params[:from_cart]
      result = create_order_from_cart
    else
      result = create_order_from_products
    end

    if result[:success]
      render json: {
        status: 'success',
        message: 'Order created successfully',
        data: {
          order: detailed_order_json(result[:order])
        }
      }, status: :created
    else
      render json: {
        status: 'error',
        message: result[:error] || 'Failed to create order',
        errors: result[:errors] || []
      }, status: :unprocessable_entity
    end
  end

  def update
    @order = current_user.orders.find(params[:id])
    
    if @order.paid? || @order.completed?
      return render json: {
        status: 'error',
        message: 'Cannot modify paid or completed orders'
      }, status: :unprocessable_entity
    end

    if @order.update(order_update_params)
      render json: {
        status: 'success',
        message: 'Order updated successfully',
        data: {
          order: detailed_order_json(@order)
        }
      }
    else
      render json: {
        status: 'error',
        errors: @order.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # ✅ NEW: Testing helper to mark orders as paid
  def mark_paid
    @order = current_user.orders.find(params[:id])
    
    if @order.paid?
      return render json: {
        status: 'success',
        message: 'Order is already paid'
      }
    end

    if @order.update(status: 'paid')
      render json: {
        status: 'success',
        message: 'Order marked as paid successfully',
        data: {
          order: detailed_order_json(@order.reload)
        }
      }
    else
      render json: {
        status: 'error',
        errors: @order.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_order
    @order = current_user.orders.find(params[:id])
  end

  def create_order_from_cart
    cart_service = StoreManagement::StoreManagement::StoreManagement::CartService.new(session)
    cart_items = cart_service.items
    
    if cart_items.empty?
      return { success: false, error: 'Cart is empty' }
    end

    # Check inventory for all items
    inventory_errors = []
    cart_items.each do |item|
      unless item[:product].can_purchase?(item[:quantity])
        inventory_errors << "#{item[:product].name}: Only #{item[:product].stock_quantity} available, requested #{item[:quantity]}"
      end
    end

    if inventory_errors.any?
      return { success: false, error: 'Insufficient inventory', errors: inventory_errors }
    end

    # Create order
    order = current_user.orders.build(
      status: 'pending',
      total: cart_service.total
    )

    ActiveRecord::Base.transaction do
      if order.save
        # Create line items
        cart_items.each do |item|
          order.line_items.create!(
            product: item[:product],
            quantity: item[:quantity],
            price: item[:product].price
          )
        end

        # Clear cart
        cart_service.clear

        { success: true, order: order }
      else
        { success: false, errors: order.errors.full_messages }
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: e.message }
  end

  def create_order_from_products
    line_items_params = params[:line_items] || []
    
    if line_items_params.empty?
      return { success: false, error: 'No products specified' }
    end

    # Validate and calculate total
    total = 0
    validated_items = []
    inventory_errors = []

    line_items_params.each do |item_params|
      product = Product.find_by(id: item_params[:product_id])
      quantity = item_params[:quantity].to_i

      unless product
        return { success: false, error: "Product #{item_params[:product_id]} not found" }
      end

      unless product.can_purchase?(quantity)
        inventory_errors << "#{product.name}: Only #{product.stock_quantity} available, requested #{quantity}"
        next
      end

      validated_items << {
        product: product,
        quantity: quantity,
        price: product.price,
        subtotal: product.price * quantity
      }
      total += product.price * quantity
    end

    if inventory_errors.any?
      return { success: false, error: 'Insufficient inventory', errors: inventory_errors }
    end

    if validated_items.empty?
      return { success: false, error: 'No valid products to order' }
    end

    # Create order
    order = current_user.orders.build(
      status: 'pending',
      total: total
    )

    ActiveRecord::Base.transaction do
      if order.save
        # Create line items
        validated_items.each do |item|
          order.line_items.create!(
            product: item[:product],
            quantity: item[:quantity],
            price: item[:price]
          )
        end

        { success: true, order: order }
      else
        { success: false, errors: order.errors.full_messages }
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: e.message }
  end

  def order_update_params
    params.require(:order).permit(:status)
  end

  def order_json(order)
    {
      id: order.id,
      status: order.status,
      total: order.total,
      created_at: order.created_at,
      updated_at: order.updated_at,
      line_items_count: order.line_items.count
    }
  end

  def detailed_order_json(order)
    base = order_json(order)
    base.merge({
      line_items: order.line_items.includes(:product).map { |item|
        {
          id: item.id,
          product_id: item.product.id,
          product_name: item.product.name,
          quantity: item.quantity,
          price: item.price,
          subtotal: item.subtotal,
          product: {
            id: item.product.id,
            name: item.product.name,
            device_type: item.product.device_type&.name,
            is_device: item.product.device?
          }
        }
      },
      devices_count: order.line_items.joins(:product).where.not(products: { device_type_id: nil }).sum(:quantity),
      activation_tokens: order.device_activation_tokens.count,
      can_generate_tokens: order.paid? && order.device_activation_tokens.empty?
    })
  end
end