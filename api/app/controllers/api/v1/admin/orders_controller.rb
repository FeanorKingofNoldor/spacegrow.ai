# app/controllers/api/v1/admin/orders_controller.rb - SIMPLIFIED FOR STARTUP
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