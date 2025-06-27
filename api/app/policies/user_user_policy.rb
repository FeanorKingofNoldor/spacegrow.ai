class UserUserPolicy < ApplicationPolicy
  def index?
    user.user?
  end

  def show?
    record.id == user.id
  end
end