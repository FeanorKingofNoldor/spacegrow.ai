# app/controllers/concerns/api_response_handling.rb
module ApiResponseHandling
  extend ActiveSupport::Concern

  private

  def render_success(data = nil, message = nil)
    render json: {
      status: 'success',
      message: message,
      data: data,
      timestamp: Time.current.iso8601
    }.compact
  end

  def render_error(message, errors = [], status_code = 422)
    render json: {
      status: 'error',
      message: message,
      errors: Array(errors),
      timestamp: Time.current.iso8601
    }, status: status_code
  end
end