# config/initializers/rack_attack.rb - Production Security with Load Testing Support
class Rack::Attack
  # Use Redis for rate limiting storage
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))

  # ===== LOAD TESTING BYPASS =====
  
  # Disable rate limiting during load tests
  if Rails.env.development? && (ENV['LOAD_TESTING'] == 'true' || ENV['RAILS_ENV'] == 'load_test')
    Rack::Attack.enabled = false
    Rails.logger.info "[Rack::Attack] 🔧 DISABLED for load testing"
  elsif Rails.env.test?
    # Disable in test environment to avoid test interference
    Rack::Attack.enabled = false
    Rails.logger.info "[Rack::Attack] Test mode - rate limiting disabled"
  else
    Rails.logger.info "[Rack::Attack] ✅ Rate limiting ENABLED for #{Rails.env}"
    
    # ===== LOCALHOST BYPASS FOR DEVELOPMENT =====
    safelist('localhost_development') do |req|
      Rails.env.development? && ['127.0.0.1', '::1', 'localhost'].include?(req.ip)
    end

    # ===== AUTHENTICATION RATE LIMITS =====
    
    # Limit login attempts (protect against brute force)
    throttle('login_attempts_per_ip', limit: 10, period: 1.minute) do |req|
      req.ip if req.path == '/api/v1/auth/login' && req.post?
    end
    
    # Limit signup attempts (prevent spam accounts)
    throttle('signup_attempts_per_ip', limit: 8, period: 1.minute) do |req|
      req.ip if req.path == '/api/v1/auth/signup' && req.post?
    end
    
    # Limit password reset requests
    throttle('password_reset_per_ip', limit: 5, period: 1.minute) do |req|
      req.ip if req.path == '/api/v1/auth/forgot_password' && req.post?
    end

    # ===== API RATE LIMITS =====
    
    # General API rate limit (per IP) - more generous for development
    throttle('api_requests_per_ip', limit: Rails.env.development? ? 1000 : 300, period: 1.minute) do |req|
      req.ip if req.path.start_with?('/api/')
    end
    
    # Authenticated user rate limit (more generous)
    throttle('api_requests_per_user', limit: 2000, period: 1.minute) do |req|
      if req.path.start_with?('/api/') && req.env['warden']&.user
        req.env['warden'].user.id
      end
    end
    
    # Device data endpoints (ESP32 calls)
    throttle('device_sensor_data', limit: 500, period: 1.minute) do |req|
      if req.path == '/api/v1/esp32/sensor_data' && req.post?
        req.ip
      end
    end

    # ===== EXPENSIVE OPERATIONS =====
    
    # Dashboard requests (database-heavy)
    throttle('dashboard_requests', limit: 120, period: 1.minute) do |req|
      req.ip if req.path.start_with?('/api/v1/frontend/dashboard')
    end
    
    # WebSocket connection attempts
    throttle('websocket_connections', limit: 25, period: 1.minute) do |req|
      req.ip if req.path == '/cable'
    end

    # ===== SECURITY PROTECTIONS =====
    
    # Block requests with suspicious patterns
    blocklist('suspicious_requests') do |req|
      # Skip blocking in development
      next false if Rails.env.development?
      
      suspicious_patterns = [
        /wp-admin/, /wp-login/, /.php$/, /\.env$/, 
        /admin\/config/, /phpmyadmin/, /.git\/config/
      ]
      
      suspicious_patterns.any? { |pattern| req.path.match?(pattern) }
    end
    
    # Block requests with suspicious user agents (production only)
    blocklist('bad_user_agents') do |req|
      next false if Rails.env.development?
      
      user_agent = req.user_agent.to_s.downcase
      bad_agents = ['bot', 'crawler', 'spider', 'scraper']
      
      bad_agents.any? { |agent| user_agent.include?(agent) } && 
      !user_agent.include?('googlebot') && 
      !user_agent.include?('bingbot')
    end

    # ===== RESPONSE HANDLING =====
    
    # Customize rate limit response (updated for Rails 7)
    self.throttled_responder = lambda do |req|
      retry_after = (req.env['rack.attack.match_data'] || {})[:period]
      [
        429,
        {
          'Content-Type' => 'application/json',
          'Retry-After' => retry_after.to_s
        },
        [{
          error: 'Rate limit exceeded',
          message: 'Too many requests. Please try again later.',
          retry_after: retry_after,
          limit_name: req.env['rack.attack.matched']
        }.to_json]
      ]
    end
    
    # Customize blocked response (updated for Rails 7)
    self.blocklisted_responder = lambda do |req|
      [
        403,
        { 'Content-Type' => 'application/json' },
        [{
          error: 'Forbidden',
          message: 'Access denied'
        }.to_json]
      ]
    end

    # ===== LOGGING & MONITORING =====
    
    # Log rate limit hits for monitoring
    ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, payload|
      request = payload[:request]
      
      case payload[:type]
      when :throttle
        Rails.logger.warn "[Rack::Attack] ⚡ Rate limit hit: #{payload[:name]} for IP #{request.ip} on #{request.path}"
      when :blocklist
        Rails.logger.warn "[Rack::Attack] 🚫 Request blocked: #{payload[:name]} for IP #{request.ip} on #{request.path}"
      when :safelist
        Rails.logger.debug "[Rack::Attack] ✅ Request safelisted: #{payload[:name]} for IP #{request.ip}"
      end
    end
  end
end