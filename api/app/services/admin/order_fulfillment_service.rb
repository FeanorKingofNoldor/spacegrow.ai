# app/services/admin/order_fulfillment_service.rb - SIMPLIFIED FOR STARTUP
module Admin
  class OrderFulfillmentService < ApplicationService
    def list_orders(params)
      begin
        orders = build_orders_query(params)
        paginated_orders = orders.page(params[:page] || 1).per(25)
        
        success(
          orders: paginated_orders.map { |o| serialize_order(o) },
          total: orders.count,
          current_page: paginated_orders.current_page,
          total_pages: paginated_orders.total_pages,
          summary: build_simple_summary(orders)
        )
      rescue => e
        Rails.logger.error "Order listing error: #{e.message}"
        failure("Failed to load orders: #{e.message}")
      end
    end

    def order_details(order)
      begin
        success(
          order: serialize_order_detail(order),
          customer: serialize_customer_info(order.user),
          items: serialize_order_items(order)
        )
      rescue => e
        Rails.logger.error "Order details error: #{e.message}"
        failure("Failed to load order details: #{e.message}")
      end
    end

    def update_order_status(order, new_status, notes = nil)
      begin
        return failure("Invalid status") unless valid_status?(new_status)
        return failure("Order is already #{new_status}") if order.status == new_status
        
        old_status = order.status
        
        ActiveRecord::Base.transaction do
          order.update!(
            status: new_status,
            notes: notes.present? ? [order.notes, notes].compact.join("\n") : order.notes,
            updated_at: Time.current
          )
          
          # Handle status-specific updates
          case new_status
          when 'completed'
            order.update!(completed_at: Time.current) if order.respond_to?(:completed_at)
          when 'canceled'
            order.update!(canceled_at: Time.current) if order.respond_to?(:canceled_at)
          end
        end
        
        Rails.logger.info "Admin updated order #{order.id} from #{old_status} to #{new_status}"
        
        success(
          message: "Order status updated to #{new_status}",
          order: serialize_order_detail(order)
        )
      rescue => e
        Rails.logger.error "Order status update error: #{e.message}"
        failure("Failed to update order status: #{e.message}")
      end
    end

    def process_refund(order, amount = nil, reason = nil)
      begin
        return failure("Order cannot be refunded") unless can_refund?(order)
        
        refund_amount = amount || order.total
        return failure("Refund amount exceeds order total") if refund_amount > order.total
        
        ActiveRecord::Base.transaction do
          order.update!(
            status: 'refunded',
            refund_amount: refund_amount,
            refund_reason: reason,
            refunded_at: Time.current
          )
        end
        
        Rails.logger.info "Admin processed refund for order #{order.id}: $#{refund_amount}"
        
        success(
          message: "Refund of $#{refund_amount} processed successfully",
          order: serialize_order_detail(order)
        )
      rescue => e
        Rails.logger.error "Refund processing error: #{e.message}"
        failure("Failed to process refund: #{e.message}")
      end
    end

    private

    # === QUERY BUILDING ===

    def build_orders_query(params)
      orders = Order.includes(:user, :line_items)
      
      # Filter by status
      if params[:status].present?
        orders = orders.where(status: params[:status])
      end
      
      # Filter by date range
      if params[:created_after].present?
        orders = orders.where(created_at: params[:created_after]..)
      end
      
      if params[:created_before].present?
        orders = orders.where(created_at: ..params[:created_before])
      end
      
      # Filter by user
      if params[:user_id].present?
        orders = orders.where(user_id: params[:user_id])
      end
      
      # Filter by amount range
      if params[:min_amount].present?
        orders = orders.where(total: params[:min_amount]..)
      end
      
      if params[:max_amount].present?
        orders = orders.where(total: ..params[:max_amount])
      end
      
      # Simple search
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        orders = orders.joins(:user).where(
          "orders.id::text = ? OR users.email ILIKE ?",
          params[:search], search_term
        )
      end
      
      orders.order(created_at: :desc)
    end

    # === SERIALIZATION ===

    def serialize_order(order)
      {
        id: order.id,
        user_email: order.user.email,
        status: order.status,
        total: order.total.to_f,
        items_count: order.line_items.count,
        created_at: order.created_at.iso8601,
        payment_status: determine_payment_status(order)
      }
    end

    def serialize_order_detail(order)
      {
        id: order.id,
        status: order.status,
        total: order.total.to_f,
        subtotal: order.subtotal&.to_f,
        tax_amount: order.tax_amount&.to_f,
        shipping_amount: order.shipping_amount&.to_f,
        created_at: order.created_at.iso8601,
        updated_at: order.updated_at.iso8601,
        payment_method: order.payment_method,
        payment_status: determine_payment_status(order),
        notes: order.notes,
        refund_amount: order.refund_amount&.to_f,
        refund_reason: order.refund_reason
      }
    end

    def serialize_customer_info(user)
      {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
        order_count: user.orders.count,
        total_spent: user.orders.where(status: 'completed').sum(:total).to_f,
        subscription_plan: user.subscription&.plan&.name
      }
    end

    def serialize_order_items(order)
      order.line_items.map do |item|
        {
          id: item.id,
          product_name: item.product_name,
          quantity: item.quantity,
          unit_price: item.unit_price.to_f,
          total_price: (item.quantity * item.unit_price).to_f
        }
      end
    end

    # === SIMPLE SUMMARY ===

    def build_simple_summary(orders_scope)
      {
        total_orders: orders_scope.count,
        by_status: orders_scope.group(:status).count,
        total_revenue: orders_scope.where(status: 'completed').sum(:total).to_f,
        pending_orders: orders_scope.where(status: 'pending').count,
        failed_payments: orders_scope.where(status: 'payment_failed').count
      }
    end

    # === HELPER METHODS ===

    def valid_status?(status)
      %w[pending processing shipped delivered completed canceled refunded payment_failed].include?(status)
    end

    def determine_payment_status(order)
      case order.status
      when 'payment_failed'
        'failed'
      when 'completed', 'shipped', 'delivered'
        'paid'
      when 'refunded'
        'refunded'
      else
        'pending'
      end
    end

    def can_refund?(order)
      %w[completed shipped delivered].include?(order.status) && 
        (order.refund_amount.nil? || order.refund_amount < order.total)
    end
  end
end