class Api::V1::Auth::RegistrationsController < Api::V1::Auth::BaseController
  include RackSessionsFix

  def create
    user = User.new(sign_up_params)
    
    if user.save
      # Generate JWT token for the new user
      token = JWT.encode(
        { 
          user_id: user.id, 
          exp: 24.hours.from_now.to_i 
        }, 
        Rails.application.credentials.secret_key_base
      )

      render json: {
        status: { code: 200, message: 'Signed up successfully.' },
        data: UserSerializer.new(user).serializable_hash[:data][:attributes],
        token: token
      }, status: :created
    else
      render json: {
        status: { message: "User couldn't be created successfully. #{user.errors.full_messages.to_sentence}" }
      }, status: :unprocessable_entity
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role, :timezone)
  end
end
