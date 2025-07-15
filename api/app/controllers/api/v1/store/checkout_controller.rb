# app/controllers/api/v1/store/checkout_controller.rb
class Api::V1::Store::CheckoutController < Api::V1::Frontend::ProtectedController
  before_action :set_cart

  def show
    render json: {
      status: 'success',
      data: {
        cart_items: @cart.items,
        total: @cart.total
      }
    }
  end

  def create
    line_items = build_line_items
    
    session = Stripe::Checkout::Session.create(
      payment_method_types: ['card'],
      line_items: line_items,
      mode: 'payment',
      success_url: "#{request.base_url}/shop/checkout/success?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: "#{request.base_url}/shop/checkout",
      metadata: {
        user_id: current_user&.id,
        customer_info: params[:customer_info].to_json
      }
    )

    render json: {
      status: 'success',
      data: {
        checkout_url: session.url,
        session_id: session.id
      }
    }
  rescue Stripe::StripeError => e
    render json: {
      status: 'error',
      message: e.message
    }, status: :unprocessable_entity
  end

  private

  def build_line_items
    params[:cart_items].map do |item|
      product = Product.find(item[:product_id])
      {
        price_data: {
          currency: 'usd',
          product_data: {
            name: product.name,
            description: product.description
          },
          unit_amount: (product.price * 100).to_i
        },
        quantity: item[:quantity]
      }
    end
  end

  def set_cart
    @cart = StoreManagement::StoreManagement::StoreManagement::CartService.new(session)
  end
end