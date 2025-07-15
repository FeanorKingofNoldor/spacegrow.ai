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

      # ✅ ENHANCED: Include display_name and subscription data
      user_data = UserSerializer.new(user).serializable_hash[:data][:attributes]
      
      # Add display_name and timezone if they exist
      user_data[:display_name] = user.display_name if user.respond_to?(:display_name)
      user_data[:timezone] = user.timezone if user.respond_to?(:timezone)

      render json: {
        status: { code: 200, message: 'Signed up successfully.' },
        data: user_data,
        token: token
      }, status: :created
    else
      render json: {
        status: { message: "User couldn't be created successfully. #{user.errors.full_messages.to_sentence}" }
      }, status: :unprocessable_entity
    end
  end

  private

  # ✅ UPDATED: Include display_name in signup params
  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role, :timezone, :display_name)
  end
end
