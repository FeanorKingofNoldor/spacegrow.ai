# app/controllers/api/v1/admin/orders_controller.rb - ULTRA-THIN VERSION
class Api::V1::Admin::OrdersController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def index
    result = Admin::OrderFulfillmentService.new.list_orders(filter_params)
    render_service_result(result, "Orders loaded successfully")
  end

  def show
    order = Order.find(params[:id])
    result = Admin::OrderFulfillmentService.new.order_details(order)
    render_service_result(result, "Order details loaded")
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
    render_service_result(result, result[:message] || "Order status updated")
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
    render_service_result(result, result[:message] || "Refund processed")
  rescue ActiveRecord::RecordNotFound
    render_error("Order not found", [], 404)
  end

  def retry_payment
    order = Order.find(params[:id])
    result = Admin::OrderFulfillmentService.new.retry_payment(order)
    render_service_result(result, result[:message] || "Payment retry initiated")
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
    render_service_result(result, result[:message] || "Shipping updated")
  rescue ActiveRecord::RecordNotFound
    render_error("Order not found", [], 404)
  end

  # ===== ANALYTICS ENDPOINTS (Now Ultra-Thin!) =====
  
  def analytics
    result = Admin::OrderFulfillmentService.new.simple_analytics(params[:period])
    render_service_result(result, "Order analytics loaded")
  end

  def payment_failures
    result = Admin::OrderFulfillmentService.new.payment_failure_summary
    render_service_result(result, "Payment failures loaded")
  end

  private

  def filter_params
    params.permit(:status, :created_after, :created_before, :user_id, 
                  :min_amount, :max_amount, :page, :per_page, :search)
  end

  def render_service_result(result, success_message)
    if result[:success]
      render_success(result.except(:success), success_message)
    else
      render_error(result[:error])
    end
  end
end