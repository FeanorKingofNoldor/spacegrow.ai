# app/controllers/api/v1/esp32/base_controller.rb
class Api::V1::Esp32::BaseController < Api::V1::BaseController
  before_action :authenticate_device!
  
  private
  
  def authenticate_device!
    token = request.headers['Authorization']&.split(' ')&.last
    
    result = DeviceCommunication::Esp32::AuthenticationService.call(
      token: token,
      ip_address: request.remote_ip
    )

    if result[:success]
      @current_device = result[:device]
    else
      render json: { error: result[:error] }, status: :unauthorized
    end
  end
  
  def current_device
    @current_device
  end
end