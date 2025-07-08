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
      
      # ✅ ENHANCED: Include subscription data in login response
      user_data = {
        id: user.id,
        email: user.email,
        role: user.role,
        created_at: user.created_at,
        devices_count: user.devices_count
      }

      # Add subscription data if exists
      if user.subscription
        user_data[:subscription] = {
          id: user.subscription.id,
          status: user.subscription.status,
          plan: {
            id: user.subscription.plan.id,
            name: user.subscription.plan.name,
            device_limit: user.subscription.plan.device_limit
          },
          device_limit: user.subscription.device_limit,
          additional_device_slots: user.subscription.additional_device_slots
        }
      end
      
      render json: {
        status: { code: 200, message: 'Logged in successfully.' },
        data: user_data,
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

  # ✅ ENHANCED: Get current user info with subscription data
  def me
    token = request.headers['Authorization']&.split(' ')&.last
    
    if token
      begin
        payload = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' }).first
        user = User.find(payload['user_id'])
        
        # ✅ FIXED: Include subscription data in me endpoint
        user_data = {
          id: user.id,
          email: user.email,
          role: user.role,
          created_at: user.created_at,
          devices_count: user.devices_count
        }

        # ✅ ADD SUBSCRIPTION DATA: This is the key fix!
        if user.subscription
          user_data[:subscription] = {
            id: user.subscription.id,
            status: user.subscription.status,
            plan: {
              id: user.subscription.plan.id,
              name: user.subscription.plan.name,
              device_limit: user.subscription.plan.device_limit
            },
            device_limit: user.subscription.device_limit,
            additional_device_slots: user.subscription.additional_device_slots,
            # ✅ BONUS: Add hibernation-aware device counts
            device_counts: {
              total: user.subscription.total_devices_count,
              operational: user.subscription.operational_devices_count,
              hibernating: user.subscription.hibernating_devices_count
            }
          }
        end
        
        render json: {
          status: { code: 200, message: 'User info retrieved successfully.' },
          data: user_data
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

  # ✅ ENHANCED: Refresh JWT token with subscription data
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
        
        # ✅ ENHANCED: Include subscription data in refresh response
        user_data = {
          id: user.id,
          email: user.email,
          role: user.role,
          created_at: user.created_at,
          devices_count: user.devices_count
        }

        # Add subscription data if exists
        if user.subscription
          user_data[:subscription] = {
            id: user.subscription.id,
            status: user.subscription.status,
            plan: {
              id: user.subscription.plan.id,
              name: user.subscription.plan.name,
              device_limit: user.subscription.plan.device_limit
            },
            device_limit: user.subscription.device_limit,
            additional_device_slots: user.subscription.additional_device_slots
          }
        end
        
        render json: {
          status: { code: 200, message: 'Token refreshed successfully.' },
          data: user_data,
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