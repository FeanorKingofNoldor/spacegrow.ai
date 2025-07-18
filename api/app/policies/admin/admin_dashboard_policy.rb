# app/policies/admin/admin_dashboard_policy.rb
module Admin
  class AdminDashboardPolicy < ApplicationPolicy
    attr_reader :user, :dashboard

    def initialize(user, dashboard)
      @user = user
      @dashboard = dashboard
    end

    def index?
      user.admin?
    end

    def alerts?
      user.admin?
    end

    def metrics?
      user.admin?
    end

    def real_time_monitoring?
      user.admin?
    end

    def export_data?
      user.admin?
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