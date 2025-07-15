# app/services/device_limit_service.rb
module DeviceManagement
  class LimitService < ApplicationService
    def initialize(user)
      @user = user
    end

    def device_limit
      return Float::INFINITY if @user.admin?
      
      if active_subscription
        active_subscription.device_limit
      else
        role_based_limit
      end
    end

    def available_slots
      return Float::INFINITY if @user.admin?
      [device_limit - operational_device_count, 0].max
    end

    def can_add_device?
      return true if @user.admin?
      operational_device_count < device_limit
    end

    def device_summary
      {
        total: @user.devices.count,
        operational: operational_device_count,
        suspended: @user.devices.suspended.count,
        pending: @user.devices.pending.count,
        disabled: @user.devices.disabled.count,
        device_limit: device_limit,
        available_slots: available_slots
      }
    end

    private

    def role_based_limit
      case @user.role.to_sym
      when :pro then 4
      when :enterprise then Float::INFINITY
      else 2
      end
    end

    def operational_device_count
      @user.devices.operational.count
    end

    def active_subscription
      @user.active_subscription&.active? ? @user.active_subscription : nil
    end
  end
end