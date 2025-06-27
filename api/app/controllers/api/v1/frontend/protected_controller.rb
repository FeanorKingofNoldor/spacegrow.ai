class Api::V1::Frontend::ProtectedController < Api::V1::BaseController
  include Pundit::Authorization
  
  before_action :authenticate_api_user!
  
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  private
  
  def authenticate_api_user!
    token = request.headers['Authorization']&.split(' ')&.last
    
    if token
      begin
        payload = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' }).first
        @current_user = User.find(payload['user_id'])
      rescue JWT::ExpiredSignature
        render json: { error: 'Token has expired' }, status: :unauthorized
        return
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        render json: { error: 'Invalid token' }, status: :unauthorized
        return
      end
    else
      render json: { error: 'No token provided' }, status: :unauthorized
      return
    end
  end
  
  def current_user
    @current_user
  end

  def user_not_authorized
    render json: { 
      error: 'You are not authorized to perform this action' 
    }, status: :forbidden
  end
end
