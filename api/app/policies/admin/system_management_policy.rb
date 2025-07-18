# app/policies/admin/system_management_policy.rb
module Admin
  class SystemManagementPolicy < ApplicationPolicy
    attr_reader :user, :system_resource

    def initialize(user, system_resource)
      @user = user
      @system_resource = system_resource
    end

    def health_check?
      user.admin?
    end

    def performance_metrics?
      user.admin?
    end

    def monitoring_dashboard?
      user.admin?
    end

    def system_logs?
      user.admin?
    end

    def maintenance_mode?
      user.admin? && super_admin?
    end

    def infrastructure_access?
      user.admin?
    end

    def run_diagnostics?
      user.admin?
    end

    def system_configuration?
      user.admin? && super_admin?
    end

    def emergency_actions?
      user.admin? && super_admin?
    end

    private

    def super_admin?
      # Define super admin privileges for critical system operations
      # This could be based on a specific role or permission
      user.admin? # For now, all admins are super admins
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