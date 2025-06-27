class Api::V1::Admin::BaseController < Api::V1::Frontend::ProtectedController
  before_action :ensure_admin!
  
  private
  
  def ensure_admin!
    unless current_user.admin?
      render json: { 
        error: 'Admin access required' 
      }, status: :forbidden
    end
  end
end
