# config/application.rb - PRODUCTION READY VERSION
require_relative "boot"
require "rails/all"

# ✅ EXPLICIT: Force ActionCable to load in API-only mode
require "action_cable/engine"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Api
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1
    
    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))
    
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    
    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
    
    # ✅ NEW: Enable Rack::Attack middleware for rate limiting
    config.middleware.use Rack::Attack
    
    # ✅ PRODUCTION: ActionCable Configuration
    config.action_cable.mount_path = '/cable'
    
    # ✅ PRODUCTION: Environment-specific origins
    allowed_origins = case Rails.env
    when 'development'
      [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:3001", # Next.js default
        "ws://localhost:3000",
        "ws://127.0.0.1:3000",
        "ws://localhost:3001"
      ]
    when 'test'
      [
        "http://localhost:3000",
        "ws://localhost:3000"
      ]
    when 'production'
      # ✅ PRODUCTION: Use environment variables for allowed origins
      ENV.fetch('ACTIONCABLE_ALLOWED_ORIGINS', '').split(',').map(&:strip).reject(&:blank?)
    else
      []
    end
    
    config.action_cable.allowed_request_origins = allowed_origins
    
    # ✅ PRODUCTION: Conditional CSRF protection
    # Disable for development/test, enable for production with proper token validation
    config.action_cable.disable_request_forgery_protection = Rails.env.development? || Rails.env.test?
    
    # ✅ PRODUCTION: ActionCable logging
    config.action_cable.log_tags = [
      :request_id,
      -> request { "ActionCable-#{request.remote_ip}" },
      -> request { "User-#{request.env['warden']&.user&.id || 'anonymous'}" }
    ]
    
    # ✅ PRODUCTION: Connection pool settings
    config.action_cable.worker_pool_size = ENV.fetch('ACTIONCABLE_WORKER_POOL_SIZE', 4).to_i
    
    # ✅ PRODUCTION: Redis adapter configuration
    if Rails.env.production?
      config.action_cable.adapter = :redis
      config.action_cable.url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')
      config.action_cable.channel_prefix = "xspacegrow_#{Rails.env}"
    end
    
    # ✅ PRODUCTION: CORS configuration for API
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins_list = case Rails.env
        when 'development'
          ['http://localhost:3001', 'http://localhost:3000', 'http://127.0.0.1:3001']
        when 'production'
          ENV.fetch('CORS_ALLOWED_ORIGINS', '').split(',').map(&:strip).reject(&:blank?)
        else
          []
        end
        
        origins origins_list
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head],
          credentials: true,
          expose: ['Authorization']
      end
    end
    
    # ✅ PRODUCTION: Session store configuration for ActionCable
    # This is needed even in API-only mode for ActionCable session authentication
    config.session_store :cookie_store, 
      key: '_xspacegrow_session',
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax
      
    # ✅ PRODUCTION: Add session middleware back for ActionCable
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use config.session_store, config.session_options
    
    # ✅ PRODUCTION: Timezone
    config.time_zone = 'UTC'
    
    # ✅ PRODUCTION: Force SSL in production
    config.force_ssl = Rails.env.production?
    
    # ✅ PRODUCTION: Logger configuration
    if Rails.env.production?
      config.log_level = :info
      config.log_tags = [:request_id, :remote_ip]
    end
  end
end