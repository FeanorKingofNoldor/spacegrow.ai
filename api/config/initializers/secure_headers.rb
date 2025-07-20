# config/initializers/secure_headers.rb

SecureHeaders::Configuration.default do |config|
  # =============================================================================
  # CONTENT SECURITY POLICY (CSP) - Basic Compatible Version
  # =============================================================================
  
  config.csp = {
    # Basic CSP directives for IoT dashboard (compatible with older gem versions)
    default_src: %w('self'),
    
    # Scripts - allow self and specific CDNs for charts/monitoring
    script_src: %w(
      'self'
      'unsafe-inline'
      https://cdnjs.cloudflare.com
      https://cdn.jsdelivr.net
    ),
    
    # Styles - allow self and inline styles for dashboard
    style_src: %w(
      'self'
      'unsafe-inline'
      https://cdnjs.cloudflare.com
      https://fonts.googleapis.com
    ),
    
    # Images - allow self, data URLs, and https sources
    img_src: %w(
      'self'
      data:
      https:
    ),
    
    # Fonts - allow self and Google Fonts
    font_src: %w(
      'self'
      https://fonts.gstatic.com
      data:
    ),
    
    # Connect - allow API calls and WebSocket connections
    connect_src: %w(
      'self'
      ws:
      wss:
    ).concat(Rails.env.development? ? %w(ws://localhost:* http://localhost:*) : []),
    
    # Forms can only submit to self
    form_action: %w('self'),
    
    # Frames - very restrictive for security
    frame_ancestors: %w('none'),
    frame_src: %w('none'),
    
    # Object restrictions
    object_src: %w('none'),
    media_src: %w('self')
  }

  # =============================================================================
  # STRICT TRANSPORT SECURITY (HSTS) - String format
  # =============================================================================
  
  # HSTS header as string (compatible with older gem versions)
  config.hsts = "max-age=#{1.year.to_i}; includeSubDomains; preload"

  # =============================================================================
  # BASIC SECURITY HEADERS
  # =============================================================================
  
  # Prevent clickjacking
  config.x_frame_options = 'DENY'
  
  # Prevent MIME type sniffing
  config.x_content_type_options = 'nosniff'
  
  # XSS protection for legacy browsers
  config.x_xss_protection = '1; mode=block'
  
  # Control referrer information
  config.referrer_policy = 'strict-origin-when-cross-origin'
  
  # Clear any existing headers that might conflict
  config.x_permitted_cross_domain_policies = 'none'
end

# =============================================================================
# DEVELOPMENT ENVIRONMENT OVERRIDES
# =============================================================================

if Rails.env.development?
  SecureHeaders::Configuration.override(:development) do |config|
    # More permissive CSP for development
    config.csp = {
      default_src: %w('self'),
      script_src: %w('self' 'unsafe-inline' 'unsafe-eval' http://localhost:* https://cdnjs.cloudflare.com),
      style_src: %w('self' 'unsafe-inline' https://cdnjs.cloudflare.com https://fonts.googleapis.com),
      img_src: %w('self' data: https: http://localhost:*),
      font_src: %w('self' https://fonts.gstatic.com data:),
      connect_src: %w('self' ws://localhost:* http://localhost:* https://api.stripe.com),
      form_action: %w('self'),
      frame_ancestors: %w('none'),
      object_src: %w('none')
    }
    
    # Disable HSTS in development (localhost doesn't support HTTPS by default)
    config.hsts = SecureHeaders::OPT_OUT
  end
end