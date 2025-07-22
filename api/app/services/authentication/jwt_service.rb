# app/services/authentication/jwt_service.rb
module Authentication
  class JwtService
    class << self
      # JWT secret key - separate from Rails secret
      def secret_key
        @secret_key ||= Rails.application.credentials.dig(:jwt, :secret_key) ||
                       ENV['JWT_SECRET_KEY'] ||
                       fail('JWT secret key must be set in credentials under jwt.secret_key')
      end

      # Generate JWT token with proper security
      def encode(payload)
        # Add standard claims
        now = Time.current.to_i
        jti = SecureRandom.uuid
        
        full_payload = payload.merge(
          iat: now,                    # Issued at
          exp: (now + token_lifetime), # Expires at
          jti: jti,                    # JWT ID for revocation
          iss: jwt_config[:issuer],    # ✅ FIXED: Use config
          aud: jwt_config[:audience]   # ✅ FIXED: Use config
        )

        token = JWT.encode(full_payload, secret_key, 'HS256')
        
        # Return both token and JTI for session tracking
        { token: token, jti: jti, expires_at: Time.at(full_payload[:exp]) }
      end

      # Decode and verify JWT token
      def decode(token)
        payload = JWT.decode(
          token,
          secret_key,
          true,
          {
            algorithm: 'HS256',
            verify_iat: true,
            verify_exp: true,
            iss: jwt_config[:issuer],    # ✅ FIXED: Use config
            aud: jwt_config[:audience],  # ✅ FIXED: Use config
            verify_iss: true,
            verify_aud: true
          }
        ).first

        # Check if token is revoked
        if revoked?(payload['jti'])
          raise JWT::InvalidTokenError, 'Token has been revoked'
        end

        payload
      rescue JWT::ExpiredSignature
        raise JWT::ExpiredSignature, 'Token has expired'
      rescue JWT::InvalidIssuerError, JWT::InvalidAudError
        raise JWT::DecodeError, 'Invalid token issuer or audience'
      rescue JWT::DecodeError => e
        raise JWT::DecodeError, "Invalid token: #{e.message}"
      end

      # Check if token is revoked
      def revoked?(jti)
        return false if jti.blank?
        
        if defined?(JwtDenylist)
          JwtDenylist.exists?(jti: jti)
        else
          # Fallback to Redis if JwtDenylist model doesn't exist
          Rails.cache.exist?("revoked_jwt:#{jti}")
        end
      end

      # Revoke a token
      def revoke!(jti, exp_time = nil)
        return false if jti.blank?

        if defined?(JwtDenylist)
          JwtDenylist.create!(
            jti: jti,
            exp: exp_time || 24.hours.from_now
          )
        else
          # Fallback to Redis with expiration
          Rails.cache.write(
            "revoked_jwt:#{jti}", 
            true, 
            expires_in: exp_time&.to_i || 24.hours
          )
        end
        
        true
      rescue => e
        Rails.logger.error "Failed to revoke JWT: #{e.message}"
        false
      end

      # Extract token from Authorization header
      def extract_from_header(auth_header)
        return nil if auth_header.blank?
        return nil unless auth_header.start_with?('Bearer ')
        
        auth_header.split(' ', 2).last
      end

      private

      # ✅ NEW: Get JWT configuration
      def jwt_config
        @jwt_config ||= Rails.application.config_for(:jwt) || {}
      end

      # Token lifetime configuration
      def token_lifetime
        jwt_config[:lifetime] || 12.hours.to_i
      end
    end
  end
end