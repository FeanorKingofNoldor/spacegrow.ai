# app/services/device_management/activation_service.rb - REFACTORED
module DeviceManagement
  class ActivationService < ApplicationService
    def initialize(token:, device_type:)
      @token = token
      @device_type = device_type
    end

    def call
      begin
        ActiveRecord::Base.transaction do
          find_and_validate_token
          create_device
          mark_token_used
          handle_subscription_limits

          Rails.logger.info "Device activated successfully: #{@device.id} for user #{@device.user.email}"

          success(
            device: serialize_device(@device),
            subscription_result: @subscription_result,
            activation_details: {
              token: @token,
              device_type: @device_type.name,
              activated_at: Time.current.iso8601,
              activation_token_id: @activation_token.id
            },
            user_summary: build_user_summary,
            message: "Device activated successfully"
          )
        end
      rescue StandardError => e
        Rails.logger.error "Device activation failed: #{e.message}"
        failure("Device activation failed: #{e.message}")
      end
    end

    private

    attr_reader :token, :device_type

    def find_and_validate_token
      @activation_token = DeviceActivationToken.find_by(token: token)
      
      unless @activation_token
        raise StandardError, 'Invalid activation token'
      end
      
      if @activation_token.expired?
        raise StandardError, 'Token has expired'
      end
      
      if @activation_token.used?
        raise StandardError, 'Token has already been used'
      end
      
      unless @activation_token.valid_for_activation?(device_type)
        raise StandardError, 'Token is not valid for this device type'
      end
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

      unless @device.save
        raise StandardError, "Failed to create device: #{@device.errors.full_messages.join(', ')}"
      end
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
        @subscription_result = subscription.activate_device(@device)
        
        # If device exceeds limits, it gets suspended but stays created
        if @subscription_result && !@subscription_result[:success] && @subscription_result[:over_limit]
          @device.update!(status: 'suspended')
          
          # Create upsell opportunity
          create_upsell_opportunity
        end
      else
        # No active subscription - suspend device but keep it created
        @device.update!(status: 'suspended')
        @subscription_result = {
          success: false,
          over_limit: false,
          requires_subscription: true,
          message: "Device created but suspended - subscription required"
        }
        
        create_subscription_opportunity
      end
    end

    def serialize_device(device)
      {
        id: device.id,
        name: device.name,
        device_type: device.device_type.name,
        status: device.status,
        created_at: device.created_at.iso8601,
        user_id: device.user_id,
        activation_token_id: device.activation_token_id,
        order_id: device.order_id
      }
    end

    def build_user_summary
      user = @device.user
      slot_manager = Billing::DeviceSlotManager.new(user)
      
      {
        user_id: user.id,
        email: user.email,
        subscription_status: user.subscription&.status,
        device_slots: slot_manager.slot_summary,
        total_devices: user.devices.count,
        active_devices: user.devices.active.count,
        suspended_devices: user.devices.suspended.count
      }
    end

    def create_upsell_opportunity
      # Create an upsell opportunity for additional device slots or plan upgrade
      UpsellOpportunity.create!(
        user: @device.user,
        device: @device,
        opportunity_type: 'device_limit_exceeded',
        message: "Upgrade your plan to activate #{@device.name}",
        recommended_action: 'plan_upgrade',
        created_at: Time.current
      )
      
      # Send upsell email
      UserMailer.device_limit_upsell(@device.user, @device).deliver_later
    end

    def create_subscription_opportunity
      # Create subscription opportunity for users without active subscription
      SubscriptionOpportunity.create!(
        user: @device.user,
        device: @device,
        opportunity_type: 'requires_subscription',
        message: "Subscribe to activate #{@device.name}",
        recommended_action: 'create_subscription',
        created_at: Time.current
      )
      
      # Send subscription email
      UserMailer.subscription_required(@device.user, @device).deliver_later
    end
  end
end