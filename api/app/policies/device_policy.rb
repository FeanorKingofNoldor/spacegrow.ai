# app/policies/device_policy.rb
class DevicePolicy < ApplicationPolicy
  def show?
    user == record.user
  end

  def update?
    user == record.user
  end

  def destroy?
    user == record.user
  end

  def create_command?
    update?
  end

  def update_status?
    user == record.user
  end
end