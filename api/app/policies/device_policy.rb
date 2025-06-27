class DevicePolicy < ApplicationPolicy
  def update?
    user == record.user
  end

  def create_command?
    update?
  end
end