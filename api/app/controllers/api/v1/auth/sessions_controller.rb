# app/controllers/api/v1/auth/sessions_controller.rb
class Api::V1::Auth::SessionsController < Api::V1::Auth::BaseController
  include RackSessionsFix
  include AuthenticationConcern  # ✅ NEW: Use centralized auth
  
  before_action :authenticate_user!, only: [
    :index, :destroy_session, :logout_all, :me, 
    :refresh, :update_profile, :change_password
  ]

  def create
    user = User.find_by(email: params[:user][:email])
    
    if user&.valid_password?(params[:user][:password])
      # ✅ FIXED: Use centralized JWT service
      token = generate_user_token(
        user,
        device_info: request.headers['User-Agent'] || 'Unknown Device',
        ip_address: request.remote_ip
      )
      
      # Build consistent user response
      user_data = build_user_response(user)
      
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
    # ✅ FIXED: Use centralized revocation
    if revoke_current_token!
      render json: {
        status: { code: 200, message: 'Logged out successfully.' }
      }
    else
      render json: {
        status: { code: 500, message: 'Logout failed.' }
      }, status: :internal_server_error
    end
  end

  # Get current user info
  def me
    render json: {
      status: { code: 200, message: 'User retrieved successfully.' },
      data: build_user_response(current_user)
    }
  end

  # Refresh token (extend expiration)
  def refresh
    # Generate new token
    new_token = generate_user_token(
      current_user,
      device_info: request.headers['User-Agent'] || 'Unknown Device',
      ip_address: request.remote_ip
    )
    
    # Revoke old token
    revoke_current_token!
    
    render json: {
      status: { code: 200, message: 'Token refreshed successfully.' },
      token: new_token,
      data: build_user_response(current_user)
    }
  end

  # List all active sessions
  def index
    sessions = if defined?(UserSession)
                 current_user.active_sessions.map do |session|
                   {
                     jti: session.jti,
                     device_info: session.device_info,
                     ip_address: session.ip_address,
                     last_active: session.last_active_at&.iso8601,
                     created_at: session.created_at.iso8601,
                     is_current: session.is_current
                   }
                 end
               else
                 []
               end
    
    render json: {
      status: { code: 200, message: 'Sessions retrieved successfully.' },
      data: {
        sessions: sessions,
        total_count: sessions.length
      }
    }
  end

  # Logout specific session
  def destroy_session
    jti = params[:jti]
    
    if jti.blank?
      render json: {
        status: { code: 400, message: 'Session ID is required.' }
      }, status: :bad_request
      return
    end
    
    # Prevent logging out current session
    current_token = extract_token_from_request
    if current_token
      begin
        payload = Authentication::JwtService.decode(current_token)
        current_jti = payload['jti']
        
        if jti == current_jti
          render json: {
            status: { code: 400, message: 'Cannot logout current session. Use regular logout instead.' }
          }, status: :bad_request
          return
        end
      rescue JWT::DecodeError
        # Current token invalid, proceed with logout
      end
    end
    
    # Revoke the specific session
    if Authentication::JwtService.revoke!(jti)
      # Remove session record if exists
      current_user.logout_session!(jti) if defined?(UserSession)
      
      render json: {
        status: { code: 200, message: 'Session logged out successfully.' }
      }
    else
      render json: {
        status: { code: 404, message: 'Session not found.' }
      }, status: :not_found
    end
  end

  # Logout all other sessions
  def logout_all
    current_token = extract_token_from_request
    
    if current_token
      begin
        payload = Authentication::JwtService.decode(current_token)
        current_jti = payload['jti']
        
        # Logout all other sessions
        if defined?(UserSession)
          current_user.logout_all_other_sessions!(current_jti)
        end
        
        render json: {
          status: { code: 200, message: 'All other sessions logged out successfully.' }
        }
      rescue JWT::DecodeError
        render_invalid_token
      end
    else
      render_authentication_error
    end
  end

  # Update user profile
  def update_profile
    if current_user.update(profile_params)
      render json: {
        status: { code: 200, message: 'Profile updated successfully.' },
        data: build_user_response(current_user)
      }
    else
      render json: {
        status: { 
          code: 422, 
          message: 'Profile update failed.',
          errors: current_user.errors.full_messages
        }
      }, status: :unprocessable_entity
    end
  end

  # Change password
  def change_password
    if current_user.update_with_password(change_password_params)
      # Generate new token after password change
      new_token = generate_user_token(
        current_user,
        device_info: request.headers['User-Agent'] || 'Unknown Device',
        ip_address: request.remote_ip
      )
      
      # Revoke old token
      revoke_current_token!
      
      render json: {
        status: { code: 200, message: 'Password changed successfully.' },
        token: new_token
      }
    else
      render json: {
        status: { 
          code: 422, 
          message: 'Password change failed.',
          errors: current_user.errors.full_messages
        }
      }, status: :unprocessable_entity
    end
  end

  private
  
  # ✅ Helper method to build consistent user response
  def build_user_response(user)
    user_data = {
      id: user.id,
      email: user.email,
      display_name: user.display_name,
      timezone: user.timezone,
      role: user.role,
      created_at: user.created_at,
      devices_count: user.devices_count
    }

    # Add active sessions count if available
    if defined?(UserSession)
      user_data[:active_sessions_count] = user.active_sessions.count
    end

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
    
    user_data
  end

  def profile_params
    params.require(:user).permit(:display_name, :timezone)
  end

  def change_password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end