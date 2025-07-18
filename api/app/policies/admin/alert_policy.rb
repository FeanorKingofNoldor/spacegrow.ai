# app/policies/admin/alert_policy.rb
module Admin
  class AlertPolicy < ApplicationPolicy
    attr_reader :user, :alert

    def initialize(user, alert)
      @user = user
      @alert = alert
    end

    def index?
      user.admin?
    end

    def show?
      user.admin?
    end

    def acknowledge?
      user.admin?
    end

    def resolve?
      user.admin?
    end

    def dismiss?
      user.admin?
    end

    def create_alert?
      user.admin?
    end

    def escalate?
      user.admin?
    end

    def manage_notifications?
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