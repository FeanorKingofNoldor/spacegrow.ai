# app/policies/admin/user_management_policy.rb
module Admin
  class UserManagementPolicy < ApplicationPolicy
    attr_reader :user, :target_user

    def initialize(user, target_user)
      @user = user
      @target_user = target_user
    end

    def index?
      user.admin?
    end

    def show?
      user.admin?
    end

    def update?
      user.admin? && can_modify_user?
    end

    def change_role?
      user.admin? && can_modify_user? && !target_user.admin?
    end

    def suspend?
      user.admin? && can_modify_user? && !target_user.admin?
    end

    def reactivate?
      user.admin? && can_modify_user?
    end

    def view_activity_log?
      user.admin?
    end

    def view_financial_data?
      user.admin?
    end

    def bulk_operations?
      user.admin?
    end

    def export_user_data?
      user.admin?
    end

    private

    def can_modify_user?
      # Prevent admins from modifying themselves in certain ways
      return true if target_user != user
      
      # Allow self-modification for non-critical actions
      false
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