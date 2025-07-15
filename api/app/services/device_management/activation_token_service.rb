module DeviceManagement
  class ActivationTokenService < ApplicationService
      def self.generate_for_order(order)
        new(order).call
      end
    
      def self.expire_for_subscription(subscription)
        new(subscription).expire_tokens
      end
    
      def self.expire_for_order(order)
        new(order).expire_tokens
      end
    
      def initialize(context)
        @context = context
      end
    
      def call
        return unless @context.is_a?(Order) && @context.paid?
    
        ActiveRecord::Base.transaction do
          tokens = @context.line_items.includes(:product).flat_map do |item|
            next unless item.product.device?
    
            item.quantity.times.map do
              token = DeviceActivationToken.create!(
                order: @context,
                device_type: item.product.device_type,
                expires_at: 30.days.from_now
              )
            # DeviceMailer.activation_token_email(token).deliver_later
              token
            end.compact
          end.flatten.compact
    
          tokens
        end
      end
    
      def expire_tokens
        case @context
        when Subscription
          expire_subscription_tokens
        when Order
          expire_order_tokens
        end
      end
    
      private
    
      def expire_subscription_tokens
        return unless @context.status.in?(['canceled', 'past_due'])
    
        ActiveRecord::Base.transaction do
          @context.user.devices.includes(:activation_token).find_each do |device|
            device.activation_token&.update!(expires_at: Time.current)
            device.update!(status: 'disabled')
          end
        end
      end
    
      def expire_order_tokens
        return unless @context.cancelled?
    
        ActiveRecord::Base.transaction do
          @context.device_activation_tokens.update_all(expires_at: Time.current)
        end
      end
  end
end