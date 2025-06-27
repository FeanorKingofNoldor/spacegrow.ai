class Api::V1::Store::StripeWebhooksController < Api::V1::Store::BaseController

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
