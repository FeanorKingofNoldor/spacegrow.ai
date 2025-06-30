# app/policies/device_policy.rb
class DevicePolicy < ApplicationPolicy
  def show?
    user == record.user
  end

  def update?
    user == record.user
  end

  def create_command?
    update?
  end
end