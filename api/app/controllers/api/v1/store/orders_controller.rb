class Api::V1::Store::OrdersController < Api::V1::Frontend::ProtectedController
  def index
    orders = current_user.orders.includes(:line_items, :products).order(created_at: :desc)
    
    render json: {
      status: 'success',
      data: {
        orders: orders.map { |order| order_json(order) }
      }
    }
  end

  def show
    order = current_user.orders.includes(:line_items, :products).find(params[:id])
    
    render json: {
      status: 'success',
      data: {
        order: detailed_order_json(order)
      }
    }
  end

  private

  def order_json(order)
    {
      id: order.id,
      status: order.status,
      total: order.total,
      created_at: order.created_at,
      item_count: order.line_items.sum(:quantity)
    }
  end

  def detailed_order_json(order)
    order_json(order).merge({
      line_items: order.line_items.map do |item|
        {
          id: item.id,
          product_name: item.product.name,
          quantity: item.quantity,
          price: item.price,
          subtotal: item.subtotal
        }
      end
    })
  end
end
