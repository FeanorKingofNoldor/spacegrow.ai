# app/controllers/concerns/esp32_authenticatable.rb
module Esp32Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_device!
    before_action :check_rate_limit!
  end

  private

  def authenticate_device!
    result = DeviceCommunication::Esp32::AuthenticationService.call(
      token: extract_token_from_header,
      ip_address: request.remote_ip
    )

    if result.success?
      @device = result.device
    else
      render json: { error: result.error }, status: :unauthorized
    end
  end

  def check_rate_limit!
    limiter = RateLimiter.new(current_device.id)
    unless limiter.limit!
      render json: { 
        error: 'Rate limit exceeded',
        retry_after: Time.now.beginning_of_minute.next_minute
      }, status: :too_many_requests
    end
  end

  def current_device
    @device
  end

  def extract_token_from_header
    request.headers['Authorization']&.split(' ')&.last
  end
end