# app/policies/admin/analytics_policy.rb
module Admin
  class AnalyticsPolicy < ApplicationPolicy
    attr_reader :user, :analytics_resource

    def initialize(user, analytics_resource)
      @user = user
      @analytics_resource = analytics_resource
    end

    def overview?
      user.admin?
    end

    def business_metrics?
      user.admin?
    end

    def operational_metrics?
      user.admin?
    end

    def user_analytics?
      user.admin?
    end

    def device_analytics?
      user.admin?
    end

    def financial_analytics?
      user.admin?
    end

    def export_analytics?
      user.admin?
    end

    def real_time_analytics?
      user.admin?
    end

    def historical_data?
      user.admin?
    end

    def sensitive_financial_data?
      user.admin? && financial_access?
    end

    private

    def financial_access?
      # Could be based on specific financial permissions
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