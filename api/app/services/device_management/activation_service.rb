require 'ostruct'
module DeviceManagement
  class ActivationService < ApplicationService
    def self.call(token:, device_type:)
      new(token, device_type).call
    end

    def initialize(token, device_type)
      @token = token
      @device_type = device_type
    end

    def call
      ActiveRecord::Base.transaction do
        find_and_validate_token
        create_device
        mark_token_used
        handle_subscription_limits

        OpenStruct.new(
          success?: true, 
          device: @device,
          subscription_result: @subscription_result
        )
      end
    rescue StandardError => e
      OpenStruct.new(success?: false, error: e.message)
    end

    private

    attr_reader :token, :device_type

    def find_and_validate_token
      @activation_token = DeviceActivationToken.find_by(token: token)
      raise 'Invalid activation token' unless @activation_token
      raise 'Token has expired' if @activation_token.expired?
      raise 'Token has already been used' if @activation_token.used?
      raise 'Token is not valid for this device type' unless @activation_token.valid_for_activation?(device_type)
    end

    def create_device
      user = @activation_token.order.user

      # ✅ CRITICAL CHANGE: Always create device - never enforce limits here!
      # The business logic is "Always Accept, Then Upsell"
      
      @device = Device.new(
        user: user,
        device_type: device_type,
        activation_token: @activation_token,
        status: 'active',  # ✅ UPDATED: Always start as active (simplified)
        name: DeviceType.suggested_name_for(device_type.name, user),
        order: @activation_token.order
      )

      return if @device.save

      raise "Failed to create device: #{@device.errors.full_messages.join(', ')}"
    end

    def mark_token_used
      @activation_token.update!(
        device: @device,
        activated_at: Time.current
      )
    end

    # ✅ UPDATED: Handle subscription limits after device creation using new logic
    def handle_subscription_limits
      user = @device.user
      subscription = user.subscription

      if subscription&.active?
        # Use the subscription's business logic
        @subscription_result = subscription.activate_device!(@device)
        
        # ✅ UPDATED: Transform response to use new terminology
        @subscription_result = transform_subscription_result(@subscription_result)
      else
        # No subscription - device remains active but with warnings
        @subscription_result = {
          success: true,
          operational: true,
          suspended: false,      # ✅ UPDATED: Use suspended instead of suspended
          message: 'Device activated successfully',
          subscription_status: 'no_subscription',
          warning: 'Consider subscribing to unlock advanced features'
        }
      end
    end

    # ✅ NEW: Transform subscription result to use new terminology
    def transform_subscription_result(result)
      # Replace suspended with suspended in the response
      transformed = result.dup
      
      if result.key?(:suspended)
        transformed[:suspended] = result[:suspended]
        transformed.delete(:suspended)
      end
      
      # Update message if it mentions suspension
      if result[:message]
        transformed[:message] = result[:message]
          .gsub('suspended', 'suspended')
          .gsub('suspension', 'suspension')
      end
      
      transformed
    end
  end
end