# app/controllers/api/v1/admin/base_controller.rb
class Api::V1::Admin::BaseController < Api::V1::BaseController
  include AuthenticationConcern  # ✅ NEW: Use centralized auth
  
  before_action :authenticate_admin!
  
  private
  
  # Custom admin check (inherit from AuthenticationConcern)
  def authenticate_admin!
    authenticate_user!
    
    unless current_user&.admin?
      render json: {
        error: 'Admin access required',
        message: 'You must be an admin to access this resource'
      }, status: :forbidden
    end
  end
end