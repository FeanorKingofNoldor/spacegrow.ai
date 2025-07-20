# config/initializers/sentry.rb

# Get Sentry DSN from Rails encrypted credentials
sentry_config = Rails.application.credentials.dig(Rails.env.to_sym, :sentry) || {}
sentry_dsn = sentry_config[:dsn]

# Only configure Sentry if DSN is present
if sentry_dsn.present?
  Sentry.init do |config|
    config.dsn = sentry_dsn
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]

    # Set tracesSampleRate to 1.0 to capture 100%
    # of the transactions for performance monitoring.
    # We recommend adjusting this value in production
    config.traces_sample_rate = Rails.env.production? ? 0.1 : 1.0
    
    # or
    config.traces_sampler = lambda do |context|
      true
    end

    # Performance monitoring for background jobs
    config.background_worker_threads = 5
    
    # Filter out sensitive data
    config.before_send = lambda do |event, hint|
      # Filter out health check requests
      if event.transaction&.include?('/health')
        nil
      else
        event
      end
    end

    # Set the environment
    config.environment = Rails.env
    
    # Set release version (use git commit hash or version)
    config.release = ENV['APP_VERSION'] || `git rev-parse HEAD`.chomp rescue 'unknown'
    
    # Enable performance monitoring for these transaction names
    config.profiles_sample_rate = Rails.env.production? ? 0.1 : 1.0
  end
  
  Rails.logger.info "✅ Sentry configured for error tracking"
else
  Rails.logger.info "ℹ️  Sentry not configured (no DSN found in credentials)"
end