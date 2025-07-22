# app/controllers/api/v1/frontend/protected_controller.rb
class Api::V1::Frontend::ProtectedController < Api::V1::BaseController
  include Pundit::Authorization
  include AuthenticationConcern  # ✅ NEW: Use centralized auth
  
  before_action :authenticate_user!
  
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  private

  def user_not_authorized
    render json: { 
      error: 'You are not authorized to perform this action' 
    }, status: :forbidden
  end
end