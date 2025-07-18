# app/serializers/admin/order_summary_serializer.rb
module Admin
  class OrderSummarySerializer
    include ActiveModel::Serialization

    def self.serialize(order, include_detailed: false)
      base_data = {
        id: order.id,
        status: order.status,
        total: format_currency(order.total),
        created_at: order.created_at.iso8601,
        updated_at: order.updated_at.iso8601,
        
        # Customer information
        customer: {
          id: order.user.id,
          email: order.user.email,
          display_name: order.user.display_name
        },
        
        # Order summary
        items_count: order.order_items.count,
        payment_status: determine_payment_status(order),
        fulfillment_status: determine_fulfillment_status(order)
      }

      if include_detailed
        base_data.merge!(
          detailed_info: {
            subtotal: format_currency(order.subtotal),
            tax_amount: format_currency(order.tax_amount),
            shipping_amount: format_currency(order.shipping_amount),
            payment_method: order.payment_method,
            billing_address: order.billing_address,
            shipping_address: order.shipping_address,
            notes: order.notes,
            refund_amount: format_currency(order.refund_amount),
            refund_reason: order.refund_reason
          },
          
          order_items: serialize_order_items(order.order_items),
          payment_history: serialize_payment_history(order),
          status_history: serialize_status_history(order)
        )
      end

      base_data
    end

    def self.serialize_list(orders)
      orders.map { |order| serialize(order, include_detailed: false) }
    end

    def self.serialize_analytics(analytics_data)
      {
        revenue_overview: {
          total_revenue: format_currency(analytics_data[:total_revenue]),
          order_count: analytics_data[:order_count],
          average_order_value: format_currency(analytics_data[:average_order_value]),
          refund_amount: format_currency(analytics_data[:refund_amount])
        },
        
        order_trends: analytics_data[:order_trends],
        payment_methods: analytics_data[:payment_methods],
        top_products: analytics_data[:top_products] || [],
        
        customer_segments: analytics_data[:customer_segments] || {},
        refund_analysis: analytics_data[:refund_analysis] || {}
      }
    end

    private

    def self.determine_payment_status(order)
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

    def self.determine_fulfillment_status(order)
      case order.status
      when 'pending', 'payment_failed'
        'pending'
      when 'processing'
        'processing'
      when 'shipped'
        'shipped'
      when 'delivered'
        'delivered'
      when 'completed'
        'completed'
      when 'canceled', 'refunded'
        'canceled'
      else
        'unknown'
      end
    end

    def self.serialize_order_items(order_items)
      order_items.map do |item|
        {
          id: item.id,
          product_name: item.product_name,
          quantity: item.quantity,
          unit_price: format_currency(item.unit_price),
          total_price: format_currency(item.total_price),
          sku: item.sku
        }
      end
    end

    def self.serialize_payment_history(order)
      # This would integrate with payment processor history
      []
    end

    def self.serialize_status_history(order)
      # This would come from order status change logs
      []
    end

    def self.format_currency(amount)
      return "$0.00" if amount.nil?
      "$#{sprintf('%.2f', amount)}"
    end
  end
end
