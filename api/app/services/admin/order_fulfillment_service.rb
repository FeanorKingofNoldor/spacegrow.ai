# app/services/admin/order_fulfillment_service.rb
module Admin
  class OrderFulfillmentService < ApplicationService
    def list_orders(params)
      begin
        orders = Order.includes(:user, :order_items)
        
        # Apply filters
        orders = apply_order_filters(orders, params)
        
        # Apply sorting
        orders = apply_order_sorting(orders, params[:sort_by], params[:sort_direction])
        
        # Pagination
        page = params[:page]&.to_i || 1
        per_page = [params[:per_page]&.to_i || 25, 100].min
        
        paginated_orders = orders.page(page).per(per_page)
        
        success(
          orders: serialize_orders_list(paginated_orders),
          pagination: {
            current_page: page,
            per_page: per_page,
            total_pages: paginated_orders.total_pages,
            total_count: paginated_orders.total_count
          },
          summary: build_orders_summary(orders),
          filters: build_order_filter_options
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
          customer_info: serialize_customer_info(order.user),
          available_actions: determine_available_actions(order),
          related_orders: find_related_orders(order)
        )
      rescue => e
        Rails.logger.error "Order details error: #{e.message}"
        failure("Failed to load order details: #{e.message}")
      end
    end

    def update_order_status(order, new_status, notes = nil)
      begin
        return failure("Invalid status") unless valid_order_status?(new_status)
        return failure("Order is already #{new_status}") if order.status == new_status
        
        old_status = order.status
        
        ActiveRecord::Base.transaction do
          order.update!(
            status: new_status,
            notes: notes.present? ? [order.notes, notes].compact.join("\n") : order.notes,
            updated_at: Time.current
          )
          
          # Update associated records if needed
          case new_status
          when 'completed'
            order.update!(completed_at: Time.current) if order.respond_to?(:completed_at)
          when 'canceled'
            order.update!(canceled_at: Time.current) if order.respond_to?(:canceled_at)
          end
        end
        
        Rails.logger.info "Order #{order.id} status updated from #{old_status} to #{new_status}"
        
        success(
          order: serialize_order_detail(order),
          message: "Order status updated to #{new_status}"
        )
      rescue => e
        Rails.logger.error "Order status update error: #{e.message}"
        failure("Failed to update order status: #{e.message}")
      end
    end

    def revenue_analytics(period)
      begin
        date_range = calculate_date_range(period)
        
        success(
          overview: calculate_revenue_overview(date_range),
          trends: calculate_order_trends(date_range),
          payment_methods: analyze_payment_methods(date_range),
          customer_segments: analyze_customer_segments(date_range),
          refunds: analyze_refunds(date_range),
          period: period,
          date_range: {
            start: date_range.begin.iso8601,
            end: date_range.end.iso8601
          }
        )
      rescue => e
        Rails.logger.error "Revenue analytics error: #{e.message}"
        failure("Failed to generate analytics: #{e.message}")
      end
    end

	def simple_analytics(period = 'month')
		date_range = calculate_date_range(period)
		
		success(
			order_metrics: Order.analytics_for_period(period),
			payment_issues: Order.failed_payments.where(created_at: 24.hours.ago..).count
		)
	end

	def payment_failure_summary
		success(
			recent_failures: Order.failed_payments.recent.includes(:user).limit(50),
			summary: { total_failed_24h: Order.failed_payments.where(created_at: 24.hours.ago..).count }
		)
	end

    def export_orders(params)
      begin
        orders = Order.includes(:user, :order_items)
        orders = apply_export_filters(orders, params)
        
        export_data = generate_export_data(orders, params[:columns])
        
        success(
          data: export_data,
          filename: "orders_export_#{Date.current}.csv",
          total_records: orders.count
        )
      rescue => e
        Rails.logger.error "Export error: #{e.message}"
        failure("Failed to export orders: #{e.message}")
      end
    end

    def payment_failures_analysis(params)
      begin
        date_range = calculate_date_range(params[:period] || 'month')
        failed_orders = Order.where(status: 'payment_failed', created_at: date_range)
        failed_orders = apply_failure_filters(failed_orders, params)
        
        success(
          failed_orders: serialize_orders_list(failed_orders),
          summary: {
            total_failed: failed_orders.count,
            failed_amount: failed_orders.sum(:total),
            failure_rate: calculate_failure_rate(date_range),
            common_reasons: analyze_failure_reasons(failed_orders)
          }
        )
      rescue => e
        Rails.logger.error "Payment failures analysis error: #{e.message}"
        failure("Failed to analyze payment failures: #{e.message}")
      end
    end

    private

    # ===== FILTER AND SORTING METHODS =====
    
    def apply_order_filters(orders, params)
      orders = orders.where(status: params[:status]) if params[:status].present?
      orders = orders.where(user_id: params[:user_id]) if params[:user_id].present?
      orders = orders.where(created_at: params[:created_after]..) if params[:created_after].present?
      orders = orders.where(created_at: ..params[:created_before]) if params[:created_before].present?
      orders = orders.where(total: params[:min_amount]..) if params[:min_amount].present?
      orders = orders.where(total: ..params[:max_amount]) if params[:max_amount].present?
      
      if params[:search].present?
        orders = orders.joins(:user).where(
          "orders.id::text ILIKE ? OR users.email ILIKE ?",
          "%#{params[:search]}%", "%#{params[:search]}%"
        )
      end
      
      orders
    end

    def apply_order_sorting(orders, sort_by, direction)
      direction = direction&.downcase == 'desc' ? :desc : :asc
      
      case sort_by
      when 'created_at'
        orders.order(created_at: direction)
      when 'total'
        orders.order(total: direction)
      when 'status'
        orders.order(status: direction)
      when 'user_email'
        orders.joins(:user).order("users.email #{direction}")
      else
        orders.order(created_at: :desc)
      end
    end

    def apply_export_filters(orders, params)
      if params[:date_range].present?
        start_date, end_date = parse_date_range(params[:date_range])
        orders = orders.where(created_at: start_date..end_date)
      end
      
      orders = orders.where(status: params[:status]) if params[:status].present?
      orders
    end

    def apply_failure_filters(orders, params)
      orders = orders.where(created_at: params[:created_after]..) if params[:created_after].present?
      orders = orders.where(created_at: ..params[:created_before]) if params[:created_before].present?
      orders
    end

    # ===== VALIDATION METHODS =====
    
    def valid_order_status?(status)
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

    def determine_available_actions(order)
      actions = []
      
      actions << 'update_status' unless %w[completed refunded canceled].include?(order.status)
      actions << 'add_notes'
      actions << 'view_customer_history'
      
      actions
    end

    # ===== ANALYTICS METHODS =====
    
    def calculate_revenue_overview(date_range)
      orders = Order.where(created_at: date_range, status: 'completed')
      
      {
        total_revenue: orders.sum(:total),
        order_count: orders.count,
        average_order_value: orders.average(:total)&.round(2) || 0,
        refund_amount: Order.where(created_at: date_range).sum(:refund_amount)
      }
    end

    def calculate_order_trends(date_range)
      # Group orders by day/week/month depending on date range
      orders = Order.where(created_at: date_range, status: 'completed')
      
      # Return data suitable for charting
      orders.group_by_day(:created_at).sum(:total)
    end

    def analyze_payment_methods(date_range)
      Order.where(created_at: date_range, status: 'completed')
           .group(:payment_method)
           .count
    end

    def analyze_customer_segments(date_range)
      {
        new_customers: calculate_new_customer_orders(date_range),
        returning_customers: calculate_returning_customer_orders(date_range),
        by_plan: calculate_orders_by_plan(date_range)
      }
    end

    def analyze_refunds(date_range)
      refunded_orders = Order.where(created_at: date_range).where.not(refund_amount: nil)
      
      {
        total_refunds: refunded_orders.sum(:refund_amount),
        refund_count: refunded_orders.count,
        refund_rate: calculate_refund_rate(date_range),
        top_refund_reasons: refunded_orders.group(:refund_reason).count
      }
    end

    def calculate_failure_rate(date_range)
      total_orders = Order.where(created_at: date_range).count
      failed_orders = Order.where(created_at: date_range, status: 'payment_failed').count
      
      return 0 if total_orders == 0
      ((failed_orders.to_f / total_orders) * 100).round(1)
    end

    def analyze_failure_reasons(failed_orders)
      # Analyze payment failure reasons if stored
      failed_orders.group(:payment_failure_reason).count.presence || {}
    end

    def calculate_new_customer_orders(date_range)
      # Orders from customers who signed up during the date range
      user_ids = User.where(created_at: date_range).pluck(:id)
      Order.where(created_at: date_range, user_id: user_ids).count
    end

    def calculate_returning_customer_orders(date_range)
      # Orders from customers who signed up before the date range
      user_ids = User.where(created_at: ...date_range.begin).pluck(:id)
      Order.where(created_at: date_range, user_id: user_ids).count
    end

    def calculate_orders_by_plan(date_range)
      Order.joins(user: { subscription: :plan })
           .where(created_at: date_range)
           .group('plans.name')
           .count
    end

    def calculate_refund_rate(date_range)
      total_orders = Order.where(created_at: date_range, status: 'completed').count
      refunded_orders = Order.where(created_at: date_range).where.not(refund_amount: nil).count
      
      return 0 if total_orders == 0
      ((refunded_orders.to_f / total_orders) * 100).round(1)
    end

    # ===== HELPER METHODS =====
    
    def build_orders_summary(orders_scope)
      {
        total_orders: orders_scope.count,
        by_status: orders_scope.group(:status).count,
        total_revenue: orders_scope.where(status: 'completed').sum(:total),
        avg_order_value: orders_scope.where(status: 'completed').average(:total)&.round(2) || 0
      }
    end

    def build_order_filter_options
      {
        statuses: Order.distinct.pluck(:status).compact,
        payment_methods: Order.distinct.pluck(:payment_method).compact
      }
    end

    def find_related_orders(order)
      # Find other orders from the same customer
      order.user.orders.where.not(id: order.id).limit(5)
    end

    def calculate_date_range(period)
      case period
      when 'today'
        Date.current.all_day
      when 'week'
        1.week.ago..Time.current
      when 'month'
        1.month.ago..Time.current
      when 'quarter'
        3.months.ago..Time.current
      when 'year'
        1.year.ago..Time.current
      else
        1.month.ago..Time.current
      end
    end

    def parse_date_range(date_range_string)
      # Parse date range string like "2024-01-01,2024-01-31"
      start_date, end_date = date_range_string.split(',')
      [Date.parse(start_date), Date.parse(end_date)]
    rescue
      [1.month.ago.to_date, Date.current]
    end

    def generate_export_data(orders, columns)
      # Generate CSV/Excel data based on selected columns
      columns = %w[id user_email status total created_at] if columns.blank?
      
      orders.map do |order|
        row = {}
        row['id'] = order.id if columns.include?('id')
        row['user_email'] = order.user.email if columns.include?('user_email')
        row['status'] = order.status if columns.include?('status')
        row['total'] = order.total if columns.include?('total')
        row['created_at'] = order.created_at.iso8601 if columns.include?('created_at')
        row['items_count'] = order.order_items.count if columns.include?('items_count')
        row
      end
    end

    # ===== SERIALIZATION METHODS =====
    
    def serialize_orders_list(orders)
      orders.map do |order|
        {
          id: order.id,
          user_email: order.user.email,
          status: order.status,
          total: order.total,
          created_at: order.created_at,
          updated_at: order.updated_at,
          items_count: order.order_items.count,
          payment_status: determine_payment_status(order)
        }
      end
    end

    def serialize_order_detail(order)
      {
        id: order.id,
        status: order.status,
        total: order.total,
        subtotal: order.subtotal,
        tax_amount: order.tax_amount,
        shipping_amount: order.shipping_amount,
        created_at: order.created_at,
        updated_at: order.updated_at,
        payment_method: order.payment_method,
        payment_status: determine_payment_status(order),
        items: serialize_order_items(order.order_items),
        billing_address: order.billing_address,
        shipping_address: order.shipping_address,
        notes: order.notes,
        refund_amount: order.refund_amount,
        refund_reason: order.refund_reason
      }
    end

    def serialize_order_items(order_items)
      order_items.map do |item|
        {
          id: item.id,
          product_name: item.product_name,
          quantity: item.quantity,
          unit_price: item.unit_price,
          total_price: item.total_price,
          sku: item.sku
        }
      end
    end

    def serialize_customer_info(user)
      {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
        role: user.role,
        created_at: user.created_at,
        order_count: user.orders.count,
        total_spent: user.orders.where(status: 'completed').sum(:total),
        subscription: user.subscription ? {
          plan_name: user.subscription.plan&.name,
          status: user.subscription.status
        } : nil
      }
    end
  end
end