# app/controllers/api/v1/auth/passwords_controller.rb
class Api::V1::Auth::PasswordsController < Api::V1::Auth::BaseController
  include RackSessionsFix

  # Forgot password - send reset email
  def create
    user = User.find_by(email: params[:email])
    
    if user
      # Use Devise's built-in method to send reset instructions
      user.send_reset_password_instructions
      
      render json: {
        status: { code: 200, message: 'Reset password instructions sent to your email.' }
      }, status: :ok
    else
      # Security: Don't reveal if email exists or not
      render json: {
        status: { code: 200, message: 'If that email address exists, you will receive password reset instructions.' }
      }, status: :ok
    end
  end

  # Reset password with token
  def update
    user = User.reset_password_by_token(reset_password_params)
    
    if user.errors.empty?
      # Generate JWT token for immediate login after password reset
      token = JWT.encode(
        { 
          user_id: user.id, 
          exp: 24.hours.from_now.to_i 
        }, 
        Rails.application.credentials.secret_key_base
      )
      
      render json: {
        status: { code: 200, message: 'Password reset successfully. You are now logged in.' },
        data: {
          id: user.id,
          email: user.email,
          role: user.role,
          created_at: user.created_at,
          devices_count: user.devices_count
        },
        token: token
      }, status: :ok
    else
      render json: {
        status: { 
          code: 422, 
          message: "Password reset failed. #{user.errors.full_messages.to_sentence}" 
        }
      }, status: :unprocessable_entity
    end
  end

  private

  def reset_password_params
    params.permit(:reset_password_token, :password, :password_confirmation)
  end
end