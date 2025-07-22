# app/policies/admin_policy.rb (Updated - Keep Simple)
class AdminPolicy < ApplicationPolicy
  def admin_access?
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

  private

  attr_reader :user, :record
end