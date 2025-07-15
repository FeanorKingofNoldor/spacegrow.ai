# app/controllers/api/v1/auth/sessions_controller.rb
class Api::V1::Auth::SessionsController < Api::V1::Auth::BaseController
  include RackSessionsFix
  
  before_action :authenticate_user!, only: [:index, :destroy_session, :logout_all, :me, :refresh, :update_profile, :change_password]

  def create
    user = User.find_by(email: params[:user][:email])
    
    if user&.valid_password?(params[:user][:password])
      # Generate unique JWT ID
      jti = SecureRandom.uuid
      
      # Create JWT token with JTI
      token = JWT.encode(
        { 
          user_id: user.id,
          jti: jti,
          exp: 12.hours.from_now.to_i  # ✅ Changed to 12 hours
        }, 
        Rails.application.credentials.secret_key_base
      )
      
      # Get client info
      device_info = request.headers['User-Agent'] || 'Unknown Device'
      ip_address = request.remote_ip
      
      # Create session record
      begin
        user.create_session!(
          jti: jti,
          device_info: device_info,
          ip_address: ip_address,
          expires_at: 12.hours.from_now,
          is_current: true
        )
      rescue => e
        Rails.logger.error "Failed to create session: #{e.message}"
        # Continue with login even if session tracking fails
      end
      
      # ✅ Enhanced user data response
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
    # Get current token
    token = request.headers['Authorization']&.split(' ')&.last
    
    if token
      begin
        payload = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' }).first
        jti = payload['jti']
        
        # Add to denylist
        JwtDenylist.create!(
          jti: jti,
          exp: Time.at(payload['exp'])
        ) if jti
        
        # Remove session record
        current_user&.logout_session!(jti) if jti
        
      rescue JWT::DecodeError
        # Token already invalid, that's fine
      end
    end
    
    render json: {
      status: 200,
      message: 'Logged out successfully.'
    }
  end

  # ✅ NEW: List all active sessions
  def index
    sessions = current_user.active_sessions.map do |session|
      {
        jti: session.jti,
        device_type: session.device_type,
        ip_address: session.ip_address,
        last_active: session.formatted_last_active,
        created_at: session.created_at.iso8601,
        is_current: session.is_current
      }
    end
    
    render json: {
      status: { code: 200, message: 'Sessions retrieved successfully.' },
      data: {
        sessions: sessions,
        total_count: sessions.length,
        session_limit: 5
      }
    }
  end

  # ✅ NEW: Logout specific session
  def destroy_session
    jti = params[:jti]
    
    if jti.blank?
      render json: {
        status: { code: 400, message: 'Session ID is required.' }
      }, status: :bad_request
      return
    end
    
    # Prevent logging out current session
    current_token = request.headers['Authorization']&.split(' ')&.last
    if current_token
      begin
        current_payload = JWT.decode(current_token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' }).first
        current_jti = current_payload['jti']
        
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
    
    if current_user.logout_session!(jti)
      render json: {
        status: { code: 200, message: 'Session logged out successfully.' }
      }
    else
      render json: {
        status: { code: 404, message: 'Session not found.' }
      }, status: :not_found
    end
  end

  # ✅ NEW: Logout all other sessions
  def logout_all
    current_token = request.headers['Authorization']&.split(' ')&.last
    
    if current_token
      begin
        payload = JWT.decode(current_token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' }).first
        current_jti = payload['jti']
        
        current_user.logout_all_other_sessions!(current_jti)
        
        render json: {
          status: { code: 200, message: 'All other sessions logged out successfully.' }
        }
      rescue JWT::DecodeError
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

  # ✅ Enhanced existing methods with session tracking
  def me
    token = request.headers['Authorization']&.split(' ')&.last
    
    if token
      begin
        payload = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' }).first
        user = User.find(payload['user_id'])
        jti = payload['jti']
        
        # Update session activity
        user.touch_session_activity!(jti) if jti
        
        user_data = build_user_response(user)
        
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

  def refresh
    token = request.headers['Authorization']&.split(' ')&.last
    
    if token
      begin
        # Decode current token (allow expired for refresh)
        payload = JWT.decode(token, Rails.application.credentials.secret_key_base, false).first
        user = User.find(payload['user_id'])
        old_jti = payload['jti']
        
        # Generate new JTI
        new_jti = SecureRandom.uuid
        
        # Generate new token
        new_token = JWT.encode(
          { 
            user_id: user.id,
            jti: new_jti,
            exp: 12.hours.from_now.to_i  # ✅ Changed to 12 hours
          }, 
          Rails.application.credentials.secret_key_base
        )
        
        # Update session with new JTI
        old_session = user.find_session(old_jti)
        if old_session
          old_session.update!(
            jti: new_jti,
            expires_at: 12.hours.from_now,
            last_active_at: Time.current
          )
        end
        
        # Add old JTI to denylist
        JwtDenylist.create!(
          jti: old_jti,
          exp: Time.at(payload['exp'])
        ) if old_jti
        
        user_data = build_user_response(user)
        
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

  # ✅ Keep existing methods (update_profile, change_password) but add session tracking
  def update_profile
    token = request.headers['Authorization']&.split(' ')&.last
    
    if token
      begin
        payload = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' }).first
        user = User.find(payload['user_id'])
        jti = payload['jti']
        
        # Update session activity
        user.touch_session_activity!(jti) if jti
        
        if user.update(profile_params)
          user_data = build_user_response(user)
          
          render json: {
            status: { code: 200, message: 'Profile updated successfully' },
            data: user_data
          }
        else
          render json: {
            status: { code: 422, message: user.errors.full_messages.join(', ') }
          }, status: :unprocessable_entity
        end
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

  def change_password
    token = request.headers['Authorization']&.split(' ')&.last
    
    if token
      begin
        payload = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' }).first
        user = User.find(payload['user_id'])
        jti = payload['jti']
        
        # Update session activity
        user.touch_session_activity!(jti) if jti
        
        if user.update_with_password(change_password_params)
          render json: {
            status: { code: 200, message: 'Password changed successfully.' }
          }, status: :ok
        else
          render json: {
            status: { 
              code: 422, 
              message: 'Password change failed.',
              errors: user.errors.full_messages
            }
          }, status: :unprocessable_entity
        end
        
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
      devices_count: user.devices_count,
      active_sessions_count: user.active_sessions_count  # ✅ NEW
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
    
    user_data
  end

  def profile_params
    params.require(:user).permit(:display_name, :timezone)
  end

  def change_password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
  
  # ✅ Add authentication method
  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    
    if token.blank?
      render json: { status: { code: 401, message: 'No token provided.' } }, status: :unauthorized
      return
    end
    
    begin
      payload = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' }).first
      jti = payload['jti']
      
      # Check if token is denylisted
      if jti && JwtDenylist.exists?(jti: jti)
        render json: { status: { code: 401, message: 'Token has been revoked.' } }, status: :unauthorized
        return
      end
      
      @current_user = User.find(payload['user_id'])
    rescue JWT::ExpiredSignature
      render json: { status: { code: 401, message: 'Token has expired.' } }, status: :unauthorized
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { status: { code: 401, message: 'Invalid token.' } }, status: :unauthorized
    end
  end
  
  def current_user
    @current_user
  end
end