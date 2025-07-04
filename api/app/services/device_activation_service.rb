require 'ostruct'

# app/services/device_activation_service.rb
class DeviceActivationService
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
      status: 'active',  # Always start as active
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

  # ✅ NEW: Handle subscription limits after device creation
  def handle_subscription_limits
    user = @device.user
    subscription = user.subscription

    if subscription&.active?
      # Use the subscription's business logic
      @subscription_result = subscription.activate_device!(@device)
    else
      # No subscription - device remains active but with warnings
      @subscription_result = {
        success: true,
        operational: true,
        message: 'Device activated successfully',
        subscription_status: 'no_subscription',
        warning: 'Consider subscribing to unlock advanced features'
      }
    end
  end
end