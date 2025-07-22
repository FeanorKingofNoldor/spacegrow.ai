# app/controllers/api/v1/admin/orders_controller.rb - CLEAN VERSION
class Api::V1::Admin::OrdersController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def index
    result = Admin::OrderFulfillmentService.new.list_orders(filter_params)
    
    if result[:success]
      render_success(result.except(:success), "Orders loaded successfully")
    else
      render_error(result[:error])
    end
  end

  def show
    order = Order.includes(:user, :line_items, :device_activation_tokens).find(params[:id])
    result = Admin::OrderFulfillmentService.new.order_details(order)
    
    if result[:success]
      render_success(result.except(:success), "Order details loaded")
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Order not found", [], 404)
  end

  def update_status
    order = Order.find(params[:id])
    result = Admin::OrderFulfillmentService.new.update_order_status(
      order, 
      params[:status], 
      params[:notes]
    )
    
    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Order not found", [], 404)
  end

  def refund
    order = Order.find(params[:id])
    result = Admin::OrderFulfillmentService.new.process_refund(
      order,
      params[:amount]&.to_f,
      params[:reason]
    )
    
    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Order not found", [], 404)
  end

  def retry_payment
    order = Order.find(params[:id])
    result = Admin::OrderFulfillmentService.new.retry_payment(order)
    
    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Order not found", [], 404)
  end

  def generate_activation_tokens
    order = Order.find(params[:id])
    
    # Use existing DeviceManagement service
    tokens = DeviceManagement::ActivationTokenService.generate_for_order(order)
    
    if tokens&.any?
      render_success(
        { tokens_generated: tokens.count, tokens: tokens.map(&:token) },
        "Generated #{tokens.count} activation tokens"
      )
    else
      render_error("Failed to generate activation tokens")
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Order not found", [], 404)
  end

  def shipping_update
    order = Order.find(params[:id])
    result = Admin::OrderFulfillmentService.new.update_shipping(
      order,
      params[:tracking_number],
      params[:carrier]
    )
    
    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Order not found", [], 404)
  end

  # Analytics endpoints (simplified)
  def analytics
    result = Admin::OrderFulfillmentService.new.order_analytics(params[:period] || 'month')
    
    if result[:success]
      render_success(result.except(:success), "Order analytics loaded")
    else
      render_error(result[:error])
    end
  end

  def payment_failures
    result = Admin::OrderFulfillmentService.new.payment_failure_analysis(filter_params)
    
    if result[:success]
      render_success(result.except(:success), "Payment failures loaded")
    else
      render_error(result[:error])
    end
  end

  private

  def filter_params
    params.permit(:status, :created_after, :created_before, :user_id, 
                  :min_amount, :max_amount, :page, :per_page, :search)
  end
end
