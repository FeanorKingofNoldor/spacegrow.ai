# app/controllers/api/v1/store/base_controller.rb
class Api::V1::Store::BaseController < Api::V1::BaseController
  include AuthenticationConcern  # ✅ NEW: Use centralized auth
  
  # Allow browsing products without auth, but require auth for cart operations
  before_action :authenticate_user_optional, only: [:index, :show]
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_cart_service

  private

  def set_cart_service
    @cart_service = CartService.new(session, current_user)  # ✅ FIXED: Simplified service call
  end

  def cart_service
    @cart_service
  end
end