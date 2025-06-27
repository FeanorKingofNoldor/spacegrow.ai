class Api::V1::Auth::SessionsController < Api::V1::Auth::BaseController
  include RackSessionsFix

  def create
    user = User.find_by(email: params[:user][:email])
    
    if user&.valid_password?(params[:user][:password])
      token = JWT.encode(
        { 
          user_id: user.id, 
          exp: 24.hours.from_now.to_i 
        }, 
        Rails.application.credentials.secret_key_base
      )
      
      render json: {
        status: { code: 200, message: 'Logged in successfully.' },
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
        status: { code: 401, message: 'Invalid email or password.' }
      }, status: :unauthorized
    end
  end

  def destroy
    render json: {
      status: 200,
      message: 'Logged out successfully.'
    }
  end
end
