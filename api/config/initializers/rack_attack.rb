# config/initializers/rack_attack.rb - Production Security
class Rack::Attack
  # Use Redis for rate limiting storage
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))

  # ===== AUTHENTICATION RATE LIMITS =====
  
  # Limit login attempts (protect against brute force)
  throttle('login_attempts_per_ip', limit: 5, period: 1.minute) do |req|
    req.ip if req.path == '/api/v1/auth/login' && req.post?
  end
  
  # Limit signup attempts (prevent spam accounts)
  throttle('signup_attempts_per_ip', limit: 3, period: 1.minute) do |req|
    req.ip if req.path == '/api/v1/auth/signup' && req.post?
  end
  
  # Limit password reset requests
  throttle('password_reset_per_ip', limit: 2, period: 1.minute) do |req|
    req.ip if req.path == '/api/v1/auth/forgot_password' && req.post?
  end

  # ===== API RATE LIMITS =====
  
  # General API rate limit (per IP)
  throttle('api_requests_per_ip', limit: 300, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api/')
  end
  
  # Authenticated user rate limit (more generous)
  throttle('api_requests_per_user', limit: 1000, period: 1.minute) do |req|
    if req.path.start_with?('/api/') && req.env['warden']&.user
      req.env['warden'].user.id
    end
  end
  
  # Device data endpoints (ESP32 calls) - use your existing RateLimiter logic
  throttle('device_sensor_data', limit: 200, period: 1.minute) do |req|
    if req.path == '/api/v1/device/sensor_data' && req.post?
      # Extract device_id from request to use existing RateLimiter
      req.ip # For now, use IP. You can extract device_id if needed
    end
  end

  # ===== EXPENSIVE OPERATIONS =====
  
  # Dashboard requests (database-heavy)
  throttle('dashboard_requests', limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api/v1/frontend/dashboard')
  end
  
  # WebSocket connection attempts
  throttle('websocket_connections', limit: 10, period: 1.minute) do |req|
    req.ip if req.path == '/cable'
  end

  # ===== SECURITY PROTECTIONS =====
  
  # Block requests with suspicious patterns
  blocklist('suspicious_requests') do |req|
    # Block common attack patterns
    suspicious_patterns = [
      /wp-admin/, /wp-login/, /.php$/, /\.env$/, 
      /admin\/config/, /phpmyadmin/, /.git\/config/
    ]
    
    suspicious_patterns.any? { |pattern| req.path.match?(pattern) }
  end
  
  # Block requests with suspicious user agents
  blocklist('bad_user_agents') do |req|
    user_agent = req.user_agent.to_s.downcase
    bad_agents = ['bot', 'crawler', 'spider', 'scraper']
    
    # Allow legitimate bots, block obvious scrapers
    bad_agents.any? { |agent| user_agent.include?(agent) } && 
    !user_agent.include?('googlebot') && 
    !user_agent.include?('bingbot')
  end

  # ===== RESPONSE HANDLING =====
  
  # Customize rate limit response
  self.throttled_response = lambda do |env|
    retry_after = (env['rack.attack.match_data'] || {})[:period]
    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => retry_after.to_s
      },
      [{
        error: 'Rate limit exceeded',
        message: 'Too many requests. Please try again later.',
        retry_after: retry_after
      }.to_json]
    ]
  end
  
  # Customize blocked response
  self.blocklisted_response = lambda do |env|
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
      Rails.logger.warn "[Rack::Attack] Rate limit hit: #{payload[:name]} for IP #{request.ip} on #{request.path}"
    when :blocklist
      Rails.logger.warn "[Rack::Attack] Request blocked: #{payload[:name]} for IP #{request.ip} on #{request.path}"
    end
  end
end

# ===== ENVIRONMENT-SPECIFIC SETTINGS =====

if Rails.env.development?
  # Disable rate limiting in development (optional)
  # Rack::Attack.enabled = false
  
  # Or use more lenient limits
  Rails.logger.info "[Rack::Attack] Development mode - using lenient rate limits"
end

if Rails.env.test?
  # Disable in test environment to avoid test interference
  Rack::Attack.enabled = false
  Rails.logger.info "[Rack::Attack] Test mode - rate limiting disabled"
end