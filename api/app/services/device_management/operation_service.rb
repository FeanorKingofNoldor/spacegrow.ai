module DeviceManagement
  class OperationService < ApplicationService
    def self.create_device(user, device_params)
      new(user).create_device(device_params)
    end

    def self.suspend_device(device, reason = nil)
      new(device.user).suspend_device(device, reason)
    end

    def self.wake_device(device)
      new(device.user).wake_device(device)
    end

    def initialize(user)
      @user = user
      @limit_service = DeviceManagement::LimitService.new(user)
    end

    def create_device(device_params)
      # Check device limits
      unless @limit_service.can_add_device?
        return OpenStruct.new(
          success?: false,
          error: "Device limit of #{@limit_service.device_limit} reached for your current plan"
        )
      end

      # Create device as pending
      device_params_with_defaults = device_params.merge(status: 'pending')
      device = @user.devices.build(device_params_with_defaults)
      
      if device.save
        handle_activation_token(device)
        
        OpenStruct.new(
          success?: true,
          device: device,
          message: build_success_message(device)
        )
      else
        OpenStruct.new(
          success?: false,
          error: 'Device creation failed',
          errors: device.errors.full_messages
        )
      end
    end

    def suspend_device(device, reason = nil)
      reason ||= 'User requested suspension'
      
      if device.suspended?
        return OpenStruct.new(
          success?: false,
          error: 'Device is already suspended'
        )
      end
      
      if device.suspend!(reason: reason)
        OpenStruct.new(
          success?: true,
          device: device,
          message: 'Device suspended successfully',
          suspension_data: {
            suspended_at: device.suspended_at,
            suspended_reason: device.suspended_reason,
            grace_period_ends_at: device.grace_period_ends_at
          }
        )
      else
        OpenStruct.new(
          success?: false,
          error: 'Device suspension failed',
          errors: device.errors.full_messages
        )
      end
    end

    def wake_device(device)
      unless device.suspended?
        return OpenStruct.new(
          success?: false,
          error: 'Device is not suspended'
        )
      end

      # Check if user can add more devices
      unless @limit_service.can_add_device?
        return OpenStruct.new(
          success?: false,
          error: 'Cannot wake device: device limit reached',
          limit_data: {
            current_operational: @user.devices.operational.count,
            device_limit: @limit_service.device_limit,
            available_slots: @limit_service.available_slots,
            upsell_options: generate_upsell_options
          }
        )
      end
      
      if device.wake!
        OpenStruct.new(
          success?: true,
          device: device,
          message: 'Device woken up successfully'
        )
      else
        OpenStruct.new(
          success?: false,
          error: 'Device wake failed',
          errors: device.errors.full_messages
        )
      end
    end

    private

    def handle_activation_token(device)
      if bypass_order_requirement?
        DeviceManagement::ActivationTokenService.generate_for_order(device.order) if device.order.present?
      else
        unless device.order.present?
          device.destroy
          raise StandardError, "Device must be associated with a purchase order. Please purchase a device through the store."
        end
        DeviceManagement::ActivationTokenService.generate_for_order(device.order)
      end
    end

    def bypass_order_requirement?
      Rails.env.development? || Rails.env.test? || @user.admin?
    end

    def build_success_message(device)
      if device.order.present?
        'Device created successfully. Use the activation token to register your device.'
      else
        'Device created successfully for development/testing.'
      end
    end

    def generate_upsell_options
      subscription = @user.subscription
      return [] unless subscription

      subscription.generate_upsell_options
    end
  end
end