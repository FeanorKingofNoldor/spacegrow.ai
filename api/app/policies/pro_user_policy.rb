class ProUserPolicy < UserUserPolicy
  def index?
    user.pro? || user.admin?
  end

  # Add other actions as needed
end