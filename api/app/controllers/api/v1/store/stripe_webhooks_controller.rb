# app/controllers/api/v1/store/stripe_webhooks_controller.rb - UPDATED (Slim Controller)
class Api::V1::Store::StripeWebhooksController < Api::V1::Store::BaseController
  skip_before_action :authenticate_user!
  skip_before_action :set_cart_service

  def create
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    
    begin
      # Verify webhook signature
      event = construct_verified_event(payload, sig_header)
      
      # Delegate all processing to the service (Fat Service!)
      result = PaymentProcessing::StripeWebhookService.call(event)
      
      if result[:success]
        Rails.logger.info "✅ [StripeWebhooksController] Webhook processed successfully: #{event.type}"
        render json: { 
          received: true, 
          event_type: event.type,
          message: result[:message] 
        }, status: :ok
      else
        Rails.logger.error "❌ [StripeWebhooksController] Webhook processing failed: #{result[:error]}"
        render json: { 
          error: 'Webhook processing failed',
          details: result[:error] 
        }, status: :unprocessable_entity
      end
      
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "❌ [StripeWebhooksController] Invalid signature: #{e.message}"
      render json: { error: 'Invalid signature' }, status: :bad_request
      
    rescue JSON::ParserError => e
      Rails.logger.error "❌ [StripeWebhooksController] Invalid payload: #{e.message}"
      render json: { error: 'Invalid payload' }, status: :bad_request
      
    rescue => e
      Rails.logger.error "❌ [StripeWebhooksController] Unexpected error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: 'Internal server error' }, status: :internal_server_error
    end
  end

  private

  def construct_verified_event(payload, sig_header)
    webhook_secret = Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :webhook_secret)
    
    if webhook_secret.blank?
      Rails.logger.error "❌ [StripeWebhooksController] Missing webhook secret in credentials"
      raise StandardError, "Webhook secret not configured"
    end

    Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)
  end
end