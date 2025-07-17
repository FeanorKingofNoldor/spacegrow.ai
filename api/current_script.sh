#!/bin/bash

echo "🔧 Copying all missing controllers and Stripe configuration..."

# Create new directory structures
echo "Creating directory structure..."
mkdir -p app/controllers/api/v1/admin
mkdir -p app/controllers/api/v1/store
mkdir -p lib/tasks

# 1. STRIPE CONFIGURATION
echo "📦 Setting up Stripe configuration..."

# Add Stripe gems to Gemfile (check if not already present)
if ! grep -q "gem 'stripe'" Gemfile; then
    echo "Adding Stripe gems to Gemfile..."
    cat >> Gemfile << 'EOF'

# Payment Processing
gem 'stripe'
gem 'stripe_event'
EOF
fi

# Create Stripe initializer
echo "Creating Stripe initializer..."
cat > config/initializers/stripe.rb << 'EOF'
Stripe.api_key = Rails.application.credentials.stripe[:secret_key]
StripeEvent.signing_secret = Rails.application.credentials.stripe[:webhook_secret]
EOF

# Copy Stripe rake tasks
echo "Creating Stripe rake tasks..."
cat > lib/tasks/stripe.rake << 'EOF'
# lib/tasks/stripe.rake
namespace :stripe do
  desc 'Create Stripe products and prices for seeded plans and products'
  task create_products: :environment do
    require 'stripe'
    Stripe.api_key = Rails.application.credentials.stripe[:secret_key]
    
    Plan.find_each do |plan|
      stripe_product = Stripe::Product.create(name: plan.name, description: plan.description)
      
      monthly_price = Stripe::Price.create(
        unit_amount: (plan.monthly_price * 100).to_i,
        currency: 'usd',
        recurring: { interval: 'month' },
        product: stripe_product.id
      )
      
      yearly_price = Stripe::Price.create(
        unit_amount: (plan.yearly_price * 100).to_i,
        currency: 'usd',
        recurring: { interval: 'year' },
        product: stripe_product.id
      )
      
      plan.update!(stripe_monthly_price_id: monthly_price.id, stripe_yearly_price_id: yearly_price.id)
    end
    
    Product.find_each do |product|
      stripe_product = Stripe::Product.create(name: product.name, description: product.description)
      
      price = Stripe::Price.create(
        unit_amount: (product.price * 100).to_i,
        currency: 'usd',
        product: stripe_product.id
      )
      
      product.update!(stripe_price_id: price.id)
    end
    
    puts 'Stripe products and prices created successfully!'
  end
end
EOF

# 2. ADMIN CONTROLLERS
echo "📋 Creating Admin controllers..."

# Admin Base Controller
cat > app/controllers/api/v1/admin/base_controller.rb << 'EOF'
class Api::V1::Admin::BaseController < Api::V1::Frontend::ProtectedController
  before_action :ensure_admin!
  
  private
  
  def ensure_admin!
    unless current_user.admin?
      render json: { 
        error: 'Admin access required' 
      }, status: :forbidden
    end
  end
end
EOF

# Admin Dashboard Controller
cat > app/controllers/api/v1/admin/dashboard_controller.rb << 'EOF'
class Api::V1::Admin::DashboardController < Api::V1::Admin::BaseController
  def index
    render json: {
      status: 'success',
      data: {
        stats: admin_stats,
        recent_activity: recent_activity
      }
    }
  end

  private

  def admin_stats
    {
      total_users: User.count,
      total_devices: Device.count,
      active_devices: Device.active.count,
      total_orders: Order.count,
      total_revenue: Order.where(status: 'paid').sum(:total),
      subscriptions: {
        active: Subscription.active.count,
        past_due: Subscription.past_due.count,
        canceled: Subscription.canceled.count
      }
    }
  end

  def recent_activity
    {
      recent_users: User.order(created_at: :desc).limit(5).as_json(only: [:id, :email, :role, :created_at]),
      recent_orders: Order.order(created_at: :desc).limit(5).as_json(only: [:id, :total, :status, :created_at]),
      recent_devices: Device.order(created_at: :desc).limit(5).as_json(only: [:id, :name, :status, :created_at])
    }
  end
end
EOF

# 3. STORE CONTROLLERS
echo "🛒 Creating Store controllers..."

# Store Base Controller
cat > app/controllers/api/v1/store/base_controller.rb << 'EOF'
class Api::V1::Store::BaseController < Api::V1::BaseController
  # Public store endpoints - no authentication required for browsing
end
EOF

# Store Controller
cat > app/controllers/api/v1/store/store_controller.rb << 'EOF'
class Api::V1::Store::StoreController < Api::V1::Store::BaseController
  def index
    products = Product.active.includes(:device_type)
    
    render json: {
      status: 'success',
      data: {
        products: products.map { |product| product_json(product) }
      }
    }
  end

  def show
    product = Product.active.find(params[:id])
    
    render json: {
      status: 'success',
      data: {
        product: detailed_product_json(product)
      }
    }
  end

  private

  def product_json(product)
    {
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      device_type: product.device_type&.name,
      active: product.active
    }
  end

  def detailed_product_json(product)
    product_json(product).merge({
      device_type_details: product.device_type ? {
        id: product.device_type.id,
        description: product.device_type.description,
        configuration: product.device_type.configuration
      } : nil
    })
  end
end
EOF

# Carts Controller
cat > app/controllers/api/v1/store/carts_controller.rb << 'EOF'
class Api::V1::Store::CartsController < Api::V1::Store::BaseController
  def show
    cart_items = cart.items
    
    render json: {
      status: 'success',
      data: {
        items: cart_items,
        total: cart.total,
        count: cart.count
      }
    }
  end

  def add
    product = Product.find(params[:product_id])
    cart.add_item(product.id, params[:quantity] || 1)
    
    render json: {
      status: 'success',
      message: 'Item added to cart',
      data: {
        count: cart.count,
        total: cart.total
      }
    }
  end

  def remove
    cart.remove_item(params[:product_id])
    
    render json: {
      status: 'success',
      message: 'Item removed from cart',
      data: {
        count: cart.count,
        total: cart.total
      }
    }
  end

  def update
    cart.update_quantity(params[:product_id], params[:quantity])
    
    render json: {
      status: 'success',
      message: 'Cart updated',
      data: {
        count: cart.count,
        total: cart.total
      }
    }
  end

  private

  def cart
    @cart ||= CartService.new(session)
  end
end
EOF

# Checkout Controller
cat > app/controllers/api/v1/store/checkout_controller.rb << 'EOF'
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
    line_items = @cart.items.map do |item|
      {
        price_data: {
          currency: 'usd',
          product_data: {
            name: item[:product].name,
            description: item[:product].description
          },
          unit_amount: (item[:product].price * 100).to_i
        },
        quantity: item[:quantity]
      }
    end

    session = Stripe::Checkout::Session.create(
      payment_method_types: ['card'],
      line_items: line_items,
      mode: 'payment',
      success_url: "#{request.base_url}/api/v1/store/checkout/success",
      cancel_url: "#{request.base_url}/api/v1/store/checkout/cancel",
      metadata: {
        user_id: current_user.id
      }
    )

    render json: {
      status: 'success',
      data: {
        checkout_url: session.url,
        session_id: session.id
      }
    }
  end

  def success
    render json: {
      status: 'success',
      message: 'Payment successful!'
    }
  end

  def cancel
    render json: {
      status: 'error',
      message: 'Payment was canceled'
    }
  end

  private

  def set_cart
    @cart = CartService.new(session)
  end
end
EOF

# Orders Controller
cat > app/controllers/api/v1/store/orders_controller.rb << 'EOF'
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
EOF

# Stripe Webhooks Controller
cat > app/controllers/api/v1/store/stripe_webhooks_controller.rb << 'EOF'
class Api::V1::Store::StripeWebhooksController < Api::V1::Store::BaseController
  skip_before_action :verify_authenticity_token, if: :json_request?

  def create
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, Rails.application.credentials.stripe[:webhook_secret]
      )
    rescue JSON::ParserError => e
      render json: { error: "Invalid payload" }, status: :bad_request
      return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: "Invalid signature" }, status: :bad_request
      return
    end

    case event.type
    when 'checkout.session.completed'
      handle_checkout_session_completed(event.data.object)
    when 'payment_intent.succeeded'
      handle_payment_intent_succeeded(event.data.object)
    when 'customer.subscription.created'
      handle_subscription_created(event.data.object)
    when 'customer.subscription.updated'
      handle_subscription_updated(event.data.object)
    when 'customer.subscription.deleted'
      handle_subscription_deleted(event.data.object)
    else
      Rails.logger.info "Unhandled event type: #{event.type}"
    end

    render json: { success: true }, status: :ok
  end

  private

  def json_request?
    request.format.json?
  end

  def handle_checkout_session_completed(checkout_session)
    user_id = checkout_session.metadata&.user_id
    return unless user_id

    user = User.find_by(id: user_id)
    return unless user

    # Create order from checkout session
    order = Order.create!(
      user: user,
      total: checkout_session.amount_total / 100.0,
      status: 'paid'
    )

    Rails.logger.info "Created order #{order.id} for user #{user.id}"
  end

  def handle_payment_intent_succeeded(payment_intent)
    Rails.logger.info "Payment succeeded: #{payment_intent.id}"
  end

  def handle_subscription_created(subscription)
    user = User.find_by(stripe_customer_id: subscription.customer)
    return unless user

    Rails.logger.info "Subscription created for user #{user.id}: #{subscription.id}"
  end

  def handle_subscription_updated(subscription)
    user = User.find_by(stripe_customer_id: subscription.customer)
    return unless user

    # Update subscription status
    user_subscription = user.subscription
    if user_subscription
      user_subscription.update!(
        status: subscription.status,
        current_period_start: Time.at(subscription.current_period_start),
        current_period_end: Time.at(subscription.current_period_end)
      )
    end

    Rails.logger.info "Subscription updated for user #{user.id}: #{subscription.status}"
  end

  def handle_subscription_deleted(subscription)
    user = User.find_by(stripe_customer_id: subscription.customer)
    return unless user

    user.subscription&.update!(status: 'canceled')
    Rails.logger.info "Subscription canceled for user #{user.id}"
  end
end
EOF

# 4. FRONTEND CONTROLLERS (Missing ones)
echo "🖥️ Creating Frontend controllers..."

# Onboarding Controller
cat > app/controllers/api/v1/frontend/onboarding_controller.rb << 'EOF'
class Api::V1::Frontend::OnboardingController < Api::V1::Frontend::ProtectedController
  def choose_plan
    if current_user.subscription.present?
      return render json: {
        status: 'error',
        message: 'User already has a subscription'
      }, status: :unprocessable_entity
    end

    plans = Plan.all
    render json: {
      status: 'success',
      data: {
        plans: plans.map { |plan| plan_json(plan) }
      }
    }
  end

  def select_plan
    plan = Plan.find(params[:plan_id])
    
    subscription = SubscriptionService.create_subscription(
      user: current_user,
      plan: plan,
      interval: params[:interval] || 'month'
    )

    if subscription.persisted?
      render json: {
        status: 'success',
        message: "Welcome to SpaceGrow! Your #{plan.name} plan is now active.",
        data: {
          subscription: subscription_json(subscription)
        }
      }
    else
      render json: {
        status: 'error',
        message: "Couldn't activate your plan. Please try again.",
        errors: subscription.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def plan_json(plan)
    {
      id: plan.id,
      name: plan.name,
      description: plan.description,
      device_limit: plan.device_limit,
      monthly_price: plan.monthly_price,
      yearly_price: plan.yearly_price,
      features: plan.features
    }
  end

  def subscription_json(subscription)
    {
      id: subscription.id,
      plan: plan_json(subscription.plan),
      status: subscription.status,
      interval: subscription.interval,
      current_period_start: subscription.current_period_start,
      current_period_end: subscription.current_period_end
    }
  end
end
EOF

# Subscriptions Controller
cat > app/controllers/api/v1/frontend/subscriptions_controller.rb << 'EOF'
class Api::V1::Frontend::SubscriptionsController < Api::V1::Frontend::ProtectedController
  before_action :set_subscription, only: [:cancel, :add_device_slot, :remove_device_slot]

  def index
    plans = Plan.all
    current_subscription = current_user.subscription
    
    render json: {
      status: 'success',
      data: {
        plans: plans.map { |plan| plan_json(plan) },
        current_subscription: current_subscription ? subscription_json(current_subscription) : nil
      }
    }
  end

  def choose_plan
    if current_user.subscription&.active?
      return render json: {
        status: 'error',
        message: 'User already has an active subscription'
      }, status: :unprocessable_entity
    end

    plans = Plan.all
    render json: {
      status: 'success',
      data: {
        plans: plans.map { |plan| plan_json(plan) }
      }
    }
  end

  def select_plan
    plan = Plan.find(params[:plan_id])

    if current_user.subscription&.plan == plan
      return render json: {
        status: 'error',
        message: "You are already subscribed to the #{plan.name} plan."
      }, status: :unprocessable_entity
    end

    subscription = SubscriptionService.create_subscription(
      user: current_user,
      plan: plan,
      interval: params[:interval] || 'month'
    )

    if subscription.persisted?
      message = if current_user.subscription
                  "Successfully switched to #{plan.name} plan!"
                else
                  "Welcome to SpaceGrow! Your #{plan.name} plan is now active."
                end

      render json: {
        status: 'success',
        message: message,
        data: {
          subscription: subscription_json(subscription)
        }
      }
    else
      render json: {
        status: 'error',
        message: "Couldn't activate your plan. Please try again.",
        errors: subscription.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def cancel
    SubscriptionService.cancel_subscription(@subscription)
    render json: {
      status: 'success',
      message: 'Subscription canceled successfully'
    }
  end

  def add_device_slot
    if @subscription&.active?
      @subscription.increment!(:additional_device_slots)
      render json: {
        status: 'success',
        message: 'Successfully added an additional device slot.',
        data: {
          additional_device_slots: @subscription.additional_device_slots,
          device_limit: @subscription.device_limit
        }
      }
    else
      render json: {
        status: 'error',
        message: "You don't have an active subscription to modify."
      }, status: :unprocessable_entity
    end
  end

  def remove_device_slot
    device_id = params[:device_id]
    message = @subscription.remove_specific_device(device_id)

    render json: {
      status: 'success',
      message: message
    }
  rescue StandardError => e
    render json: {
      status: 'error',
      message: e.message
    }, status: :unprocessable_entity
  end

  private

  def set_subscription
    @subscription = current_user.subscription
    
    unless @subscription
      render json: {
        status: 'error',
        message: 'No subscription found'
      }, status: :not_found
    end
  end

  def plan_json(plan)
    {
      id: plan.id,
      name: plan.name,
      description: plan.description,
      device_limit: plan.device_limit,
      monthly_price: plan.monthly_price,
      yearly_price: plan.yearly_price,
      features: plan.features
    }
  end

  def subscription_json(subscription)
    {
      id: subscription.id,
      plan: plan_json(subscription.plan),
      status: subscription.status,
      interval: subscription.interval,
      device_limit: subscription.device_limit,
      additional_device_slots: subscription.additional_device_slots,
      current_period_start: subscription.current_period_start,
      current_period_end: subscription.current_period_end,
      devices: subscription.devices.map { |device| { id: device.id, name: device.name } }
    }
  end
end
EOF

# Pages Controller
cat > app/controllers/api/v1/frontend/pages_controller.rb << 'EOF'
class Api::V1::Frontend::PagesController < Api::V1::Frontend::ProtectedController
  def index
    render json: {
      status: 'success',
      message: 'Welcome to SpaceGrow API'
    }
  end

  def docs
    render json: {
      status: 'success',
      data: {
        title: 'API Documentation',
        sections: [
          'Getting Started',
          'Authentication',
          'Devices',
          'Sensors',
          'Commands'
        ]
      }
    }
  end

  def api
    render json: {
      status: 'success',
      data: {
        title: 'API Reference',
        version: 'v1',
        base_url: '/api/v1'
      }
    }
  end

  def devices
    render json: {
      status: 'success',
      data: {
        title: 'Device Documentation',
        device_types: DeviceType.all.map { |dt| { name: dt.name, description: dt.description } }
      }
    }
  end

  def sensors
    render json: {
      status: 'success',
      data: {
        title: 'Sensor Documentation',
        sensor_types: SensorType.all.map { |st| { name: st.name, unit: st.unit } }
      }
    }
  end

  def troubleshooting
    render json: {
      status: 'success',
      data: {
        title: 'Troubleshooting Guide',
        common_issues: [
          'Device connection problems',
          'Sensor calibration',
          'API authentication'
        ]
      }
    }
  end

  def support
    render json: {
      status: 'success',
      data: {
        title: 'Support',
        contact_email: 'support@SpaceGrow.com'
      }
    }
  end

  def faq
    render json: {
      status: 'success',
      data: {
        title: 'Frequently Asked Questions',
        faqs: [
          {
            question: 'How do I activate a device?',
            answer: 'Use the activation token provided with your device purchase.'
          }
        ]
      }
    }
  end
end
EOF

echo "✅ All controllers and Stripe configuration copied!"
echo ""
echo "📋 Summary of what was created:"
echo "- ✅ Stripe configuration (initializer + rake tasks)"
echo "- ✅ Admin controllers (base + dashboard)"  
echo "- ✅ Store controllers (store, carts, checkout, orders, stripe webhooks)"
echo "- ✅ Frontend controllers (onboarding, subscriptions, pages)"
echo ""
echo "📝 Next steps:"
echo "1. Run: bundle install (to install Stripe gems)"
echo "2. Set up Stripe credentials: rails credentials:edit"
echo "3. Update routes.rb to include new endpoints"
echo "4. Run: rails db:migrate (if needed)"
echo "5. Test the endpoints!"
echo ""
echo "🔑 Don't forget to add your Stripe keys to credentials:"
echo "stripe:"
echo "  secret_key: sk_test_..."
echo "  webhook_secret: whsec_..."