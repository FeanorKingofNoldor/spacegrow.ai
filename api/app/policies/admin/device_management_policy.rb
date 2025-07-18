# app/policies/admin/device_management_policy.rb
module Admin
  class DeviceManagementPolicy < ApplicationPolicy
    attr_reader :user, :device

    def initialize(user, device)
      @user = user
      @device = device
    end

    def index?
      user.admin?
    end

    def show?
      user.admin?
    end

    def update_status?
      user.admin? && device_modifiable?
    end

    def force_reconnect?
      user.admin?
    end

    def troubleshooting?
      user.admin?
    end

    def view_sensor_data?
      user.admin?
    end

    def device_analytics?
      user.admin?
    end

    def bulk_operations?
      user.admin?
    end

    def fleet_management?
      user.admin?
    end

    def reset_device?
      user.admin? && device_resetable?
    end

    private

    def device_modifiable?
      return true unless device
      !%w[disabled destroyed].include?(device.status)
    end

    def device_resetable?
      return false unless device
      %w[error suspended].include?(device.status)
    end

    class Scope < Scope
      def resolve
        if user.admin?
          scope.all
        else
          scope.none
        end
      end
    end
  end
end