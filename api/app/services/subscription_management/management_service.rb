# app/services/subscription_management_service.rb
module SubscriptionManagement 
  class ManagementService < ApplicationService
    def initialize(user)
      @user = user
      @subscription = user.subscription
    end

    def get_device_overview
      limit_service = DeviceManagement::LimitService.new(@user)
      operational_devices = @user.devices.operational.includes(:device_type)
      suspended_devices = @user.devices.suspended.includes(:device_type)
      
      {
        subscription: subscription_data,
        device_limits: limit_service.device_summary,
        devices: {
          operational: operational_devices,
          suspended: suspended_devices
        },
        upsell_options: @subscription&.generate_upsell_options || [],
        over_device_limit: limit_service.operational_device_count > limit_service.device_limit
      }
    end

    def activate_device(device_id)
      device = @user.devices.find_by(id: device_id)
      raise 'Device not found' unless device
      raise 'No active subscription found' unless @subscription&.active?

      @subscription.activate_device!(device)
    end

    def wake_devices(device_ids)
      result = DeviceManagement::ManagementService.wake_devices(device_ids)
      limit_service = DeviceManagement::LimitService.new(@user)
      
      {
        woken_devices: result,
        device_summary: limit_service.device_summary,
        message: "Successfully woken #{result.count} device(s)"
      }
    end

    def suspend_devices(device_ids, reason: 'User choice')
      result = DeviceManagement::ManagementService.suspend_devices(device_ids, reason: reason)
      limit_service = DeviceManagement::LimitService.new(@user)
      
      {
        suspended_devices: result,
        device_summary: limit_service.device_summary,
        message: "Successfully suspended #{result.count} device(s)"
      }
    end

    private

    def subscription_data
      return nil unless @subscription
      
      {
        id: @subscription.id,
        plan: @subscription.plan,
        status: @subscription.status,
        device_limit: @subscription.device_limit,
        additional_device_slots: @subscription.additional_device_slots
      }
    end
  end
end