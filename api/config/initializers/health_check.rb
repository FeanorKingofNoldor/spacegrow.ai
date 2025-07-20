# config/initializers/health_check.rb

# Configure the health_check gem with basic, supported options only
HealthCheck.setup do |config|
  # Configure which checks to include (basic options that all versions support)
  config.standard_checks = %w[database]
  config.full_checks = %w[database migrations cache redis sidekiq-redis]

  # Custom checks specific to SpaceGrow
  config.add_custom_check('device_connections') do
    # Check if we can connect to Redis (used for device connections)
    begin
      Rails.cache.redis.ping
      ''  # Empty string means success
    rescue => e
      "Device connection system unavailable: #{e.message}"
    end
  end

  config.add_custom_check('background_jobs') do
    # Check Sidekiq status
    begin
      stats = Sidekiq::Stats.new
      if stats.enqueued > 10000
        "Too many queued jobs: #{stats.enqueued}"
      elsif stats.failed > 1000
        "Too many failed jobs: #{stats.failed}"
      else
        ''  # Success
      end
    rescue => e
      "Background job system unavailable: #{e.message}"
    end
  end

  config.add_custom_check('external_apis') do
    # Check critical external API connections (like Stripe)
    begin
      # Just check if Stripe is configured, not making actual API calls
      if defined?(Stripe)
        if Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :secret_key).present?
          ''  # Success
        else
          'Stripe not configured'
        end
      else
        ''  # Success if Stripe not used
      end
    rescue => e
      "External API check failed: #{e.message}"
    end
  end

  # Basic configuration (universally supported)
  config.uri = 'health_check'
  config.success = 'success'
  
  # Update the full checks to include our custom ones
  config.full_checks = %w[database migrations cache redis sidekiq-redis device_connections background_jobs external_apis]
end

# Add middleware to disable sessions for health checks (performance)
if defined?(HealthCheck::MiddlewareDisableSessionsForHealthChecks)
  Rails.application.config.middleware.insert_before(
    ActionDispatch::Session::CookieStore,
    HealthCheck::MiddlewareDisableSessionsForHealthChecks
  )
end