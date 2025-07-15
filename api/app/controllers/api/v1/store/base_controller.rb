# app/controllers/api/v1/store/base_controller.rb
class Api::V1::Store::BaseController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:index, :show] # Allow browsing without auth
  before_action :set_cart_service

  private

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    
    if token.present?
      begin
        decoded_token = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: 'HS256' })
        user_id = decoded_token.first['user_id']
        @current_user = User.find_by(id: user_id)
      rescue JWT::DecodeError, JWT::ExpiredSignature
        @current_user = nil
      end
    end

    if @current_user.nil?
      render json: { 
        status: 'error', 
        message: 'Authentication required for this action' 
      }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def set_cart_service
    @cart_service = StoreManagement::StoreManagement::StoreManagement::CartService.new(session)
  end

  def cart_service
    @cart_service
  end
end