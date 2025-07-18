# app/policies/admin_policy.rb (Base policy for admin namespace)
class AdminPolicy < ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record
  end

  def admin_access?
    user.admin?
  end

  def super_admin_access?
    user.admin? # Expand this logic as needed
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