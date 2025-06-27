Stripe.api_key = Rails.application.credentials.stripe[:secret_key]
StripeEvent.signing_secret = Rails.application.credentials.stripe[:webhook_secret]
