# app/controllers/concerns/authentication_concern.rb
module AuthenticationConcern
  extend ActiveSupport::Concern

  included do
    # Standard error responses for consistency
    rescue_from JWT::ExpiredSignature, with: :render_token_expired
    rescue_from JWT::DecodeError, with: :render_invalid_token
    rescue_from JWT::InvalidTokenError, with: :render_revoked_token
  end

  private

  # Main authentication method - call this in before_action
  def authenticate_user!
    @current_user = authenticate_from_token
    
    unless @current_user
      render_authentication_error
    end
  end

  # Optional authentication - sets @current_user but doesn't require it
  def authenticate_user_optional
    @current_user = authenticate_from_token
  end

  # Get current user (memoized)
  def current_user
    @current_user
  end

  # Check if user is authenticated
  def user_signed_in?
    current_user.present?
  end

  # Main token authentication logic
  def authenticate_from_token
    token = extract_token_from_request
    return nil if token.blank?

    begin
      payload = Authentication::JwtService.decode(token)
      user = User.find(payload['user_id'])
      
      # Update session activity if session tracking is enabled
      update_session_activity(payload['jti']) if payload['jti']
      
      user
    rescue JWT::ExpiredSignature, JWT::DecodeError, JWT::InvalidTokenError => e
      Rails.logger.warn "Authentication failed: #{e.message}"
      nil
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn "Authentication failed: User not found"
      nil
    end
  end

  # Extract token from request (supports multiple methods)
  def extract_token_from_request
    # Method 1: Authorization header (primary)
    if auth_header = request.headers['Authorization']
      return Authentication::JwtService.extract_from_header(auth_header)
    end

    # Method 2: Query parameter (for WebSocket connections)
    if token = request.query_parameters['token']
      return token
    end

    # Method 3: Cookie (if using httpOnly cookies)
    if token = request.cookies['auth_token']
      return token
    end

    nil
  end

  # Update session activity for session tracking
  def update_session_activity(jti)
    return unless defined?(UserSession)
    
    begin
      UserSession.where(jti: jti).update_all(last_active_at: Time.current)
    rescue => e
      Rails.logger.debug "Failed to update session activity: #{e.message}"
    end
  end

  # Consistent error responses
  def render_authentication_error
    render json: {
      error: 'Authentication required',
      message: 'You must be logged in to access this resource'
    }, status: :unauthorized
  end

  def render_token_expired
    render json: {
      error: 'Token expired',
      message: 'Your session has expired. Please log in again.'
    }, status: :unauthorized
  end

  def render_invalid_token
    render json: {
      error: 'Invalid token',
      message: 'The provided authentication token is invalid'
    }, status: :unauthorized
  end

  def render_revoked_token
    render json: {
      error: 'Token revoked',
      message: 'This session has been terminated. Please log in again.'
    }, status: :unauthorized
  end

  # Helper for admin authentication
  def authenticate_admin!
    authenticate_user!
    
    unless current_user&.admin?
      render json: {
        error: 'Admin access required',
        message: 'You must be an admin to access this resource'
      }, status: :forbidden
    end
  end

  # Helper for role-based authentication
  def authenticate_role!(required_role)
    authenticate_user!
    
    unless current_user&.role&.to_s == required_role.to_s
      render json: {
        error: 'Insufficient permissions',
        message: "You must have #{required_role} role to access this resource"
      }, status: :forbidden
    end
  end

  # Generate new token for user (for login/refresh)
  def generate_user_token(user, device_info: nil, ip_address: nil)
    token_data = Authentication::JwtService.encode(user_id: user.id)
    
    # Create session record if session tracking is enabled
    if defined?(UserSession) && device_info && ip_address
      begin
        user.create_session!(
          jti: token_data[:jti],
          device_info: device_info,
          ip_address: ip_address,
          expires_at: token_data[:expires_at],
          is_current: true
        )
      rescue => e
        Rails.logger.error "Failed to create session record: #{e.message}"
        # Continue without session tracking
      end
    end

    token_data[:token]
  end

  # Revoke current token (for logout)
  def revoke_current_token!
    token = extract_token_from_request
    return false if token.blank?

    begin
      payload = Authentication::JwtService.decode(token)
      jti = payload['jti']
      exp_time = payload['exp'] ? Time.at(payload['exp']) : 24.hours.from_now
      
      # Revoke the token
      Authentication::JwtService.revoke!(jti, exp_time)
      
      # Remove session record if exists
      if defined?(UserSession) && jti
        current_user&.logout_session!(jti)
      end
      
      true
    rescue => e
      Rails.logger.error "Failed to revoke token: #{e.message}"
      false
    end
  end
end