# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ActionController::API
  include ActionController::Helpers
  
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from StandardError, with: :internal_server_error
  
  private
  
  def not_found
    render json: { error: 'Record not found' }, status: :not_found
  end
  
  def unprocessable_entity(exception)
    render json: { error: exception.record.errors.full_messages }, status: :unprocessable_entity
  end

  def internal_server_error(exception)
    Rails.logger.error "API Error: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    render json: { 
      error: Rails.env.development? ? exception.message : 'Internal server error' 
    }, status: :internal_server_error
  end
end