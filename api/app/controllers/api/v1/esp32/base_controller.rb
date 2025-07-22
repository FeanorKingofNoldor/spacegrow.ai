# app/controllers/api/v1/esp32/base_controller.rb - For IoT device authentication
class Api::V1::Esp32::BaseController < Api::V1::BaseController
  include AuthenticationConcern  # ✅ NEW: Use centralized auth
  
  before_action :authenticate_device!
  
  private
  
  # Custom device authentication (different from user auth)
  def authenticate_device!
    # Device authentication might use different tokens or API keys
    device_token = request.headers['X-Device-Token']
    device_id = request.headers['X-Device-ID']
    
    if device_token.blank? || device_id.blank?
      render json: {
        error: 'Device authentication required',
        message: 'X-Device-Token and X-Device-ID headers are required'
      }, status: :unauthorized
      return
    end
    
    @current_device = Device.find_by(
      id: device_id,
      api_token: device_token,
      status: 'active'
    )
    
    unless @current_device
      render json: {
        error: 'Invalid device credentials',
        message: 'Device not found or inactive'
      }, status: :unauthorized
    end
  end
  
  def current_device
    @current_device
  end
end