# app/policies/device_policy.rb
class DevicePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user_owns_device?
  end

  def create?
    true
  end

  def update?
    user_owns_device?
  end

  def destroy?
    user_owns_device?
  end

  def suspend?
    user_owns_device?
  end

  def wake?
    user_owns_device?
  end

  private

  def user_owns_device?
    record.user_id == user.id || user.admin?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end

  def create_command?
    update?
  end

  def update_status?
    user == record.user
  end
end