# app/controllers/api/v1/admin/orders_controller.rb
class Api::V1::Admin::OrdersController < Api::V1::Admin::BaseController
  include ApiResponseHandling

  def index
    service = Admin::OrderFulfillmentService.new
    result = service.list_orders(filter_params)

    if result[:success]
      render_success(result.except(:success), "Orders loaded successfully")
    else
      render_error(result[:error])
    end
  end

  def show
    order = Order.find(params[:id])
    service = Admin::OrderFulfillmentService.new
    result = service.order_details(order)

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
    service = Admin::OrderFulfillmentService.new
    result = service.update_order_status(order, params[:status], params[:notes])

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
    service = Admin::OrderFulfillmentService.new
    result = service.process_refund(order, params[:amount], params[:reason])

    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Order not found", [], 404)
  end

  def analytics
    service = Admin::OrderFulfillmentService.new
    result = service.revenue_analytics(params[:period])

    if result[:success]
      render_success(result.except(:success), "Analytics loaded")
    else
      render_error(result[:error])
    end
  end

  def export
    service = Admin::OrderFulfillmentService.new
    result = service.export_orders(export_params)

    if result[:success]
      render_success(result.except(:success), "Export generated")
    else
      render_error(result[:error])
    end
  end

  def payment_failures
    service = Admin::OrderFulfillmentService.new
    result = service.payment_failure_analysis(filter_params)

    if result[:success]
      render_success(result.except(:success), "Payment failures loaded")
    else
      render_error(result[:error])
    end
  end

  def retry_payment
    order = Order.find(params[:id])
    service = Admin::OrderFulfillmentService.new
    result = service.retry_failed_payment(order)

    if result[:success]
      render_success(result.except(:success), result[:message])
    else
      render_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Order not found", [], 404)
  end

  private

  def filter_params
    params.permit(:status, :user_id, :created_after, :created_before, 
                  :min_amount, :max_amount, :payment_status, :page, :per_page, 
                  :sort_by, :sort_direction, :search)
  end

  def export_params
    params.permit(:format, :date_range, :status, :columns)
  end
end