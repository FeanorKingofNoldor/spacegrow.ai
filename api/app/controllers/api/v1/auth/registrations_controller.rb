# app/controllers/api/v1/auth/registrations_controller.rb
class Api::V1::Auth::RegistrationsController < Api::V1::Auth::BaseController
  include RackSessionsFix
  include AuthenticationConcern  # ✅ Add this

  def create
    user = User.new(sign_up_params)
    
    if user.save
      # ✅ Use centralized token generation
      token = generate_user_token(
        user,
        device_info: request.headers['User-Agent'] || 'Unknown Device',
        ip_address: request.remote_ip
      )

      user_data = UserSerializer.new(user).serializable_hash[:data][:attributes]
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

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role, :timezone, :display_name)
  end
end