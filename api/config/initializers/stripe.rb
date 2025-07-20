# config/initializers/stripe.rb

# Get Stripe configuration from Rails encrypted credentials
stripe_config = Rails.application.credentials.dig(Rails.env.to_sym, :stripe) || {}

if stripe_config[:secret_key].present?
  # Configure Stripe with the secret key
  Stripe.api_key = stripe_config[:secret_key]
  
  Rails.logger.info "✅ Stripe configured with API key"
  
  # Configure StripeEvent webhook processing (if gem is available)
  if defined?(StripeEvent)
    if stripe_config[:webhook_secret].present?
      StripeEvent.signing_secret = stripe_config[:webhook_secret]
      Rails.logger.info "✅ Stripe webhook signing secret configured"
    else
      Rails.logger.warn "⚠️  Stripe webhook secret not found in credentials"
    end
  end
  
else
  Rails.logger.warn "⚠️  Stripe secret key not found in credentials - Stripe integration disabled"
end

# Make publishable key available for frontend (if needed)
if stripe_config[:publishable_key].present?
  Rails.application.config.stripe_publishable_key = stripe_config[:publishable_key]
end