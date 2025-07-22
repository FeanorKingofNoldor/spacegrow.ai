# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      Rails.logger.info "ActionCable: User #{current_user.id} connected from #{request.remote_ip}"
    end

    private

    def find_verified_user
      # Method 1: JWT token from query parameters (primary for WebSocket)
      if token = request.query_parameters['token']
        user = authenticate_with_jwt(token)
        return user if user
      end

      # Method 2: JWT token from Authorization header (if sent by client)
      if token = extract_token_from_headers
        user = authenticate_with_jwt(token)
        return user if user
      end

      # Method 3: Cookie-based JWT (if using httpOnly cookies)
      if token = request.cookies['auth_token']
        user = authenticate_with_jwt(token)
        return user if user
      end

      # ✅ REMOVED: No more development bypasses
      # All environments require proper authentication
      Rails.logger.warn "ActionCable: Rejecting unauthorized connection from #{request.remote_ip}"
      reject_unauthorized_connection
    end

    def extract_token_from_headers
      auth_header = request.headers['Authorization']
      return Authentication::JwtService.extract_from_header(auth_header)
    end

    def authenticate_with_jwt(token)
      return nil if token.blank?

      begin
        payload = Authentication::JwtService.decode(token)
        user = User.find(payload['user_id'])
        
        # Update session activity for connection tracking
        update_session_activity(payload['jti']) if payload['jti']
        
        return user
        
      rescue JWT::ExpiredSignature => e
        Rails.logger.warn "ActionCable JWT expired: #{e.message}"
        return nil
      rescue JWT::DecodeError, JWT::InvalidTokenError => e
        Rails.logger.warn "ActionCable JWT invalid: #{e.message}"
        return nil
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.warn "ActionCable user not found: #{e.message}"
        return nil
      rescue StandardError => e
        Rails.logger.error "ActionCable unexpected JWT error: #{e.message}"
        return nil
      end
    end

    def update_session_activity(jti)
      return unless defined?(UserSession)
      
      begin
        UserSession.where(jti: jti).update_all(
          last_active_at: Time.current,
          connection_type: 'websocket'
        )
      rescue => e
        Rails.logger.debug "Failed to update session activity: #{e.message}"
      end
    end

    def reject_unauthorized_connection
      Rails.logger.warn "ActionCable: Rejecting unauthorized connection from #{request.remote_ip}"
      super
    end
  end
end