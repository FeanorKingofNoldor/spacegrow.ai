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

      OpenStruct.new(success?: true, device: @device)
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

    # Enforce device limit
    raise "Device limit of #{user.device_limit} reached for this user." if user.devices.count >= user.device_limit

    # Proceed to create the device if the limit is not exceeded
    @device = Device.new(
      user: user,
      device_type: device_type,
      activation_token: @activation_token,
      status: 'active',
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
end
