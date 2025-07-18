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
          payment_history: build_payment_history(order),
          fulfillment_history: build_fulfillment_history(order),
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
          order.update!(status: new_status)
          
          # Handle status-specific logic
          handle_status_change(order, old_status, new_status)
          
          # Log the status change
          log_order_action(order, 'status_change', {
            old_status: old_status,
            new_status: new_status,
            notes: notes,
            changed_by: current_admin_id
          })
          
          # Send notifications if needed
          send_status_change_notification(order, old_status, new_status)
        end
        
        success(
          message: "Order status updated from #{old_status} to #{new_status}",
          order: serialize_order_detail(order.reload),
          status_change: {
            old_status: old_status,
            new_status: new_status,
            changed_at: Time.current,
            notes: notes
          }
        )
      rescue => e
        Rails.logger.error "Status update error: #{e.message}"
        failure("Failed to update order status: #{e.message}")
      end
    end

    def process_refund(order, refund_amount = nil, reason = nil)
      begin
        return failure("Order cannot be refunded") unless can_refund_order?(order)
        
        refund_amount = refund_amount&.to_f || order.total
        return failure("Invalid refund amount") if refund_amount <= 0 || refund_amount > order.total
        
        ActiveRecord::Base.transaction do
          # Process the refund through payment processor
          refund_result = process_payment_refund(order, refund_amount)
          return failure("Refund processing failed: #{refund_result[:error]}") unless refund_result[:success]
          
          # Update order status
          order.update!(
            status: refund_amount >= order.total ? 'refunded' : 'partially_refunded',
            refund_amount: refund_amount,
            refund_reason: reason,
            refunded_at: Time.current
          )
          
          # Handle inventory if needed
          handle_refund_inventory(order, refund_amount)
          
          # Log the refund
          log_order_action(order, 'refund_processed', {
            refund_amount: refund_amount,
            reason: reason,
            processed_by: current_admin_id
          })
          
          # Send refund notification
          send_refund_notification(order, refund_amount, reason)
        end
        
        success(
          message: "Refund of $#{refund_amount} processed successfully",
          order: serialize_order_detail(order.reload),
          refund_details: {
            amount: refund_amount,
            reason: reason,
            processed_at: Time.current,
            refund_id: refund_result[:refund_id]
          }
        )
      rescue => e
        Rails.logger.error "Refund processing error: #{e.message}"
        failure("Failed to process refund: #{e.message}")
      end
    end

    def revenue_analytics(period = 'month')
      begin
        date_range = calculate_date_range(period)
        
        analytics = {
          revenue_overview: calculate_revenue_overview(date_range),
          order_trends: calculate_order_trends(date_range),
          payment_methods: analyze_payment_methods(date_range),
          top_products: find_top_products(date_range),
          customer_segments: analyze_customer_segments(date_range),
          refund_analysis: analyze_refunds(date_range)
        }
        
        success(
          period: period,
          date_range: date_range,
          analytics: analytics,
          comparisons: calculate_period_comparisons(analytics, period)
        )
      rescue => e
        Rails.logger.error "Revenue analytics error: #{e.message}"
        failure("Failed to generate analytics: #{e.message}")
      end
    end

    def export_orders(params)
      begin
        format = params[:format] || 'csv'
        return failure("Unsupported format") unless %w[csv excel].include?(format)
        
        orders = Order.includes(:user, :order_items)
        orders = apply_export_filters(orders, params)
        
        # Generate export file
        export_data = generate_export_data(orders, params[:columns])
        file_path = create_export_file(export_data, format)
        
        success(
          message: "Export generated successfully",
          file_path: file_path,
          record_count: orders.count,
          format: format,
          generated_at: Time.current
        )
      rescue => e
        Rails.logger.error "Export error: #{e.message}"
        failure("Failed to generate export: #{e.message}")
      end
    end

    def payment_failure_analysis(params)
      begin
        failed_orders = Order.where(status: 'payment_failed')
        failed_orders = apply_failure_filters(failed_orders, params)
        
        analysis = {
          total_failures: failed_orders.count,
          failure_reasons: analyze_failure_reasons(failed_orders),
          affected_revenue: failed_orders.sum(:total),
          retry_success_rate: calculate_retry_success_rate,
          trending_patterns: identify_failure_patterns(failed_orders)
        }
        
        success(
          analysis: analysis,
          recent_failures: serialize_failed_orders(failed_orders.recent.limit(20)),
          recommendations: generate_failure_recommendations(analysis)
        )
      rescue => e
        Rails.logger.error "Payment failure analysis error: #{e.message}"
        failure("Failed to analyze payment failures: #{e.message}")
      end
    end

    def retry_failed_payment(order)
      begin
        return failure("Order is not in failed status") unless order.status == 'payment_failed'
        return failure("Order already has a successful retry") if order.retry_successful?
        
        # Attempt payment retry through existing payment service
        retry_result = attempt_payment_retry(order)
        
        if retry_result[:success]
          ActiveRecord::Base.transaction do
            order.update!(
              status: 'completed',
              payment_retry_count: (order.payment_retry_count || 0) + 1,
              payment_completed_at: Time.current
            )
            
            log_order_action(order, 'payment_retry_success', {
              retry_count: order.payment_retry_count,
              processed_by: current_admin_id
            })
            
            send_payment_success_notification(order)
          end
          
          success(
            message: "Payment retry successful",
            order: serialize_order_detail(order.reload)
          )
        else
          # Log failed retry
          order.increment!(:payment_retry_count)
          log_order_action(order, 'payment_retry_failed', {
            retry_count: order.payment_retry_count,
            error: retry_result[:error],
            processed_by: current_admin_id
          })
          
          failure("Payment retry failed: #{retry_result[:error]}")
        end
      rescue => e
        Rails.logger.error "Payment retry error: #{e.message}"
        failure("Failed to retry payment: #{e.message}")
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

    def serialize_failed_orders(orders)
      orders.map do |order|
        {
          id: order.id,
          user_email: order.user.email,
          total: order.total,
          failure_reason: order.payment_failure_reason,
          retry_count: order.payment_retry_count || 0,
          created_at: order.created_at
        }
      end
    end

    # ===== BUSINESS LOGIC METHODS =====
    
    def handle_status_change(order, old_status, new_status)
      case new_status
      when 'shipped'
        handle_shipping_logic(order)
      when 'delivered'
        handle_delivery_logic(order)
      when 'canceled'
        handle_cancellation_logic(order)
      when 'refunded'
        handle_refund_logic(order)
      end
    end

    def handle_shipping_logic(order)
      # Generate tracking information, update inventory, etc.
      Rails.logger.info "Handling shipping logic for order #{order.id}"
    end

    def handle_delivery_logic(order)
      # Mark as delivered, trigger satisfaction surveys, etc.
      Rails.logger.info "Handling delivery logic for order #{order.id}"
    end

    def handle_cancellation_logic(order)
      # Release inventory, process cancellation refunds if needed
      Rails.logger.info "Handling cancellation logic for order #{order.id}"
    end

    def handle_refund_logic(order)
      # Handle full refund specific logic
      Rails.logger.info "Handling refund logic for order #{order.id}"
    end

    def can_refund_order?(order)
      %w[completed shipped delivered].include?(order.status) && 
      (order.refund_amount.nil? || order.refund_amount < order.total)
    end

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
      actions << 'refund' if can_refund_order?(order)
      actions << 'retry_payment' if order.status == 'payment_failed'
      actions << 'send_notification'
      actions << 'add_notes'
      
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
      
      # This would return data suitable for charting
      orders.group_by_day(:created_at).sum(:total)
    end

    def analyze_payment_methods(date_range)
      Order.where(created_at: date_range, status: 'completed')
           .group(:payment_method)
           .count
    end

    def find_top_products(date_range)
      # This would analyze order items to find top selling products
      # Placeholder implementation
      []
    end

    def analyze_customer_segments(date_range)
      # Analyze orders by customer segments (new vs returning, plan types, etc.)
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

    def build_payment_history(order)
      # This would integrate with your payment processor to get payment events
      []
    end

    def build_fulfillment_history(order)
      # This would track fulfillment events (processing, shipped, delivered, etc.)
      []
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

    def calculate_period_comparisons(analytics, period)
      # Compare with previous period
      # Implementation would depend on specific needs
      {}
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
        columns.map { |col| order.send(col) rescue order.user&.email }
      end
    end

    def create_export_file(data, format)
      # Create and save export file
      # Return file path for download
      "/tmp/orders_export_#{Time.current.to_i}.#{format}"
    end

    def analyze_failure_reasons(failed_orders)
      failed_orders.group(:payment_failure_reason).count
    end

    def calculate_retry_success_rate
      # Calculate success rate of payment retries
      total_retries = Order.where.not(payment_retry_count: nil).count
      successful_retries = Order.where(status: 'completed').where.not(payment_retry_count: nil).count
      
      return 0 if total_retries == 0
      ((successful_retries.to_f / total_retries) * 100).round(1)
    end

    def identify_failure_patterns(failed_orders)
      # Identify trending patterns in payment failures
      {
        by_hour: failed_orders.group_by_hour_of_day(:created_at).count,
        by_day: failed_orders.group_by_day(:created_at).count,
        by_amount_range: analyze_failure_by_amount(failed_orders)
      }
    end

    def analyze_failure_by_amount(failed_orders)
      {
        'under_50' => failed_orders.where(total: ..50).count,
        '50_to_200' => failed_orders.where(total: 50..200).count,
        'over_200' => failed_orders.where(total: 200..).count
      }
    end

    def generate_failure_recommendations(analysis)
      recommendations = []
      
      if analysis[:total_failures] > 10
        recommendations << "High failure rate detected - review payment processor settings"
      end
      
      if analysis[:trending_patterns][:by_hour].values.max > 5
        recommendations << "Consider load balancing during peak failure hours"
      end
      
      recommendations
    end

    def calculate_new_customer_orders(date_range)
      # Orders from customers who signed up in the date range
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

    # ===== INTEGRATION METHODS =====
    
    def process_payment_refund(order, amount)
      # This would integrate with your payment processor (Stripe, etc.)
      # For now, return success
      {
        success: true,
        refund_id: "ref_#{SecureRandom.hex(8)}"
      }
    end

    def attempt_payment_retry(order)
      # This would integrate with your payment processing system
      # For now, simulate success/failure
      {
        success: [true, false].sample,
        error: "Insufficient funds" # Sample error
      }
    end

    def handle_refund_inventory(order, refund_amount)
      # Handle inventory restoration for refunded items
      Rails.logger.info "Handling inventory for refund of $#{refund_amount}"
    end

    def log_order_action(order, action, metadata = {})
      # This would integrate with your admin activity logging
      Rails.logger.info "Order Action: #{action} on order #{order.id} - #{metadata}"
    end

    def send_status_change_notification(order, old_status, new_status)
      # Send email notification to customer about status change
      Rails.logger.info "Sending status change notification for order #{order.id}"
    end

    def send_refund_notification(order, amount, reason)
      # Send refund confirmation email
      Rails.logger.info "Sending refund notification for order #{order.id}: $#{amount}"
    end

    def send_payment_success_notification(order)
      # Send payment success notification after retry
      Rails.logger.info "Sending payment success notification for order #{order.id}"
    end

    def current_admin_id
      # Get current admin user ID from context
      1
    end
  end
end