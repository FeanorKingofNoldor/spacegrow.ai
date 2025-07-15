# app/channels/application_cable/connection.rb - CLEANED VERSION
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Method 1: JWT token from query parameters (primary for API clients)
      if token = request.query_parameters['token']
        user = authenticate_with_jwt(token)
        return user if user
      end
      
      # Method 2: JWT token from Authorization header
      if token = extract_token_from_headers
        user = authenticate_with_jwt(token)
        return user if user
      end
      
      # Method 3: Session-based authentication (fallback for web clients)
      if session_user = authenticate_with_session
        return session_user
      end

      # Method 4: Cookie-based JWT (if you store JWT in httpOnly cookies)
      if cookie_token = request.cookies['auth_token']
        user = authenticate_with_jwt(cookie_token)
        return user if user
      end

      # For testing, allow unauthenticated connections in development
      if Rails.env.development? || Rails.env.test?
        return nil
      end

      # In production, reject unauthorized connections
      reject_unauthorized_connection
    end

    def extract_token_from_headers
      auth_header = request.headers['Authorization']
      return nil unless auth_header&.start_with?('Bearer ')
      
      auth_header.split(' ').last
    end

    def authenticate_with_jwt(token)
      return nil if token.blank?
      
      begin
        payload = JWT.decode(
          token, 
          Rails.application.secret_key_base, 
          true, 
          { 
            algorithm: 'HS256',
            verify_iat: true,
            verify_exp: true
          }
        ).first
        
        user = User.find(payload['user_id'])
        
        # Check if token is revoked using your JWT denylist (if you have one)
        jti = payload['jti']
        if jti && defined?(JwtDenylist) && JwtDenylist.exists?(jti: jti)
          return nil
        end
        
        # Additional security checks
        if payload['exp'] && payload['exp'] < Time.current.to_i
          return nil
        end
        
        return user
        
      rescue JWT::ExpiredSignature, JWT::DecodeError, ActiveRecord::RecordNotFound => e
        Rails.logger.warn "ActionCable JWT authentication failed: #{e.message}"
        return nil
      rescue StandardError => e
        Rails.logger.error "ActionCable unexpected JWT error: #{e.message}"
        return nil
      end
    end

    def authenticate_with_session
      begin
        # Check if Warden/Devise user is available in session
        if env['warden']&.user
          return env['warden'].user
        end
        
        # Alternative: Check Rails session directly
        if session_user_id = request.session['user_id']
          return User.find(session_user_id)
        end
        
        return nil
        
      rescue StandardError => e
        Rails.logger.warn "ActionCable session authentication error: #{e.message}"
        return nil
      end
    end

    def reject_unauthorized_connection
      Rails.logger.warn "ActionCable rejecting unauthorized connection from #{request.remote_ip}"
      super
    end
  end
end