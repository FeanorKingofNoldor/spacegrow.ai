# app/policies/admin/support_policy.rb
module Admin
  class SupportPolicy < ApplicationPolicy
    attr_reader :user, :support_resource

    def initialize(user, support_resource)
      @user = user
      @support_resource = support_resource
    end

    def overview?
      user.admin?
    end

    def analytics?
      user.admin?
    end

    def trending_issues?
      user.admin?
    end

    def customer_satisfaction?
      user.admin?
    end

    def operational_metrics?
      user.admin?
    end

    def escalation_analysis?
      user.admin?
    end

    def customer_data?
      user.admin?
    end

    def support_tickets?
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