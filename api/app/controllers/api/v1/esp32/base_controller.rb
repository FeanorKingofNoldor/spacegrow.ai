class Api::V1::Esp32::BaseController < Api::V1::BaseController
  before_action :authenticate_device!
  before_action :check_rate_limit!

  private

  def authenticate_device!
    token = extract_token_from_header
    @device = Device.joins(:activation_token)
                    .find_by(device_activation_tokens: { token: token })

    return if @device && @device.active?

    render json: { error: 'Unauthorized' }, status: :unauthorized
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
    authorization_header = request.headers['Authorization']
    return nil unless authorization_header

    authorization_header.split(' ').last
  end
end
