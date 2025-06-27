class AdminUserPolicy < ProUserPolicy
  def index?
    user.admin?
  end

  def manage_all?
    user.admin?
  end
end