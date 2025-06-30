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

  # NEW: Get current user info
  def me
    token = request.headers['Authorization']&.split(' ')&.last
    
    if token
      begin
        payload = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' }).first
        user = User.find(payload['user_id'])
        
        render json: {
          status: { code: 200, message: 'User info retrieved successfully.' },
          data: {
            id: user.id,
            email: user.email,
            role: user.role,
            created_at: user.created_at,
            devices_count: user.devices_count
          }
        }, status: :ok
      rescue JWT::ExpiredSignature
        render json: {
          status: { code: 401, message: 'Token has expired.' }
        }, status: :unauthorized
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        render json: {
          status: { code: 401, message: 'Invalid token.' }
        }, status: :unauthorized
      end
    else
      render json: {
        status: { code: 401, message: 'No token provided.' }
      }, status: :unauthorized
    end
  end

  # NEW: Refresh JWT token
  def refresh
    token = request.headers['Authorization']&.split(' ')&.last
    
    if token
      begin
        # Decode current token (allow expired for refresh)
        payload = JWT.decode(token, Rails.application.credentials.secret_key_base, false).first
        user = User.find(payload['user_id'])
        
        # Generate new token
        new_token = JWT.encode(
          { 
            user_id: user.id, 
            exp: 24.hours.from_now.to_i 
          }, 
          Rails.application.credentials.secret_key_base
        )
        
        render json: {
          status: { code: 200, message: 'Token refreshed successfully.' },
          data: {
            id: user.id,
            email: user.email,
            role: user.role,
            created_at: user.created_at,
            devices_count: user.devices_count
          },
          token: new_token
        }, status: :ok
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        render json: {
          status: { code: 401, message: 'Invalid token.' }
        }, status: :unauthorized
      end
    else
      render json: {
        status: { code: 401, message: 'No token provided.' }
      }, status: :unauthorized
    end
  end
end