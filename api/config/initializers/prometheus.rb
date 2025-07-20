# config/initializers/prometheus.rb

# =============================================================================
# YABEDA CONFIGURATION (Main Metrics Framework)
# =============================================================================

begin
  # Require Yabeda gems
  require 'yabeda'
  require 'yabeda/rails' if defined?(Rails)
  require 'yabeda/sidekiq' if defined?(Sidekiq)
  require 'yabeda/prometheus' rescue nil
  
  # Configure Yabeda for Rails metrics collection
  Yabeda.configure do
    # Basic Rails metrics (requests, responses, etc.)
    # This is automatically enabled by yabeda-rails

    # Database metrics
    # This is automatically enabled by yabeda-rails

    # Sidekiq metrics (background jobs)
    # This is automatically enabled by yabeda-sidekiq

    # Custom IoT-specific metrics
    group :spacegrow do
      counter :device_connections, tags: [:status], comment: "Total device connections"
      counter :sensor_readings, tags: [:sensor_type, :device_type], comment: "Total sensor readings received"
      counter :api_requests, tags: [:endpoint, :method], comment: "API requests by endpoint"
      counter :user_registrations, tags: [:plan_type], comment: "User registrations by plan"
      
      gauge :active_devices, tags: [:device_type], comment: "Currently active devices"
      gauge :online_users, comment: "Currently online users"
      gauge :subscription_revenue, tags: [:plan_type], comment: "Monthly recurring revenue"
      
      histogram :device_response_time, 
        tags: [:device_type], 
        comment: "Device response times",
        buckets: [0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0]
        
      histogram :data_processing_time, 
        tags: [:processor], 
        comment: "Data processing duration",
        buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.0]
    end

    # Business metrics
    group :business do
      counter :orders_completed, tags: [:plan_type], comment: "Completed orders"
      counter :subscriptions_created, tags: [:plan_type], comment: "New subscriptions"
      counter :support_tickets, tags: [:category, :priority], comment: "Support tickets"
      
      gauge :monthly_revenue, comment: "Current monthly revenue"
      gauge :active_subscriptions, tags: [:plan_type], comment: "Active subscriptions"
      gauge :churn_rate, comment: "Monthly churn rate"
    end

    # System health metrics
    group :system do
      counter :error_responses, tags: [:status_code, :endpoint], comment: "HTTP error responses"
      counter :background_job_failures, tags: [:job_class], comment: "Failed background jobs"
      
      gauge :database_connections, comment: "Active database connections"
      gauge :redis_memory_usage, comment: "Redis memory usage in bytes"
      gauge :sidekiq_queue_size, tags: [:queue], comment: "Sidekiq queue sizes"
      
      histogram :database_query_time, 
        comment: "Database query execution time",
        buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.25, 0.5, 1.0]
        
      histogram :cache_operation_time, 
        tags: [:operation], 
        comment: "Cache operation duration",
        buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25]
    end
  end

  Rails.logger.info "✅ Yabeda metrics configured successfully"

rescue LoadError => e
  Rails.logger.warn "⚠️  Yabeda gems not fully available - metrics collection disabled: #{e.message}"
rescue => e
  Rails.logger.error "❌ Yabeda configuration failed: #{e.message}"
end

# =============================================================================
# PROMETHEUS EXPORTER CONFIGURATION
# =============================================================================

# Only enable Prometheus exporter in production or when explicitly requested
if Rails.env.production? || ENV['ENABLE_PROMETHEUS'] == 'true'
  begin
    # Require prometheus exporter
    require 'prometheus_exporter/middleware'
    require 'prometheus_exporter/server'
    
    # This middleware will respond to /metrics with Prometheus format
    Rails.application.middleware.use PrometheusExporter::Middleware
    
    # Start the Prometheus exporter server (for collecting custom metrics)
    unless Rails.env.test?
      PrometheusExporter::Server::WebServer.start(
        port: ENV.fetch('PROMETHEUS_PORT', 9394).to_i,
        bind: ENV.fetch('PROMETHEUS_BIND', '0.0.0.0')
      )
      
      Rails.logger.info "✅ Prometheus server started on port #{ENV.fetch('PROMETHEUS_PORT', 9394)}"
    end
    
  rescue LoadError => e
    Rails.logger.warn "⚠️  Prometheus exporter gem not available - /metrics endpoint disabled: #{e.message}"
  rescue => e
    Rails.logger.error "❌ Prometheus exporter configuration failed: #{e.message}"
  end
else
  Rails.logger.info "ℹ️  Prometheus exporter disabled (set ENABLE_PROMETHEUS=true to enable)"
end

# =============================================================================
# CUSTOM METRIC HELPERS
# =============================================================================

# Helper module for easy metric tracking throughout the app
module PrometheusHelpers
  extend self

  def track_device_connection(device_type, status)
    return unless defined?(Yabeda)
    Yabeda.spacegrow.device_connections.increment(
      tags: { status: status.to_s, device_type: device_type.to_s }
    )
  rescue => e
    Rails.logger.debug "Metrics tracking failed: #{e.message}"
  end

  def track_sensor_reading(sensor_type, device_type)
    return unless defined?(Yabeda)
    Yabeda.spacegrow.sensor_readings.increment(
      tags: { sensor_type: sensor_type.to_s, device_type: device_type.to_s }
    )
  rescue => e
    Rails.logger.debug "Metrics tracking failed: #{e.message}"
  end

  def track_api_request(endpoint, method)
    return unless defined?(Yabeda)
    Yabeda.spacegrow.api_requests.increment(
      tags: { endpoint: endpoint.to_s, method: method.to_s }
    )
  rescue => e
    Rails.logger.debug "Metrics tracking failed: #{e.message}"
  end

  def track_user_registration(plan_type)
    return unless defined?(Yabeda)
    Yabeda.spacegrow.user_registrations.increment(
      tags: { plan_type: plan_type.to_s }
    )
  rescue => e
    Rails.logger.debug "Metrics tracking failed: #{e.message}"
  end

  def update_active_devices(device_type, count)
    return unless defined?(Yabeda)
    Yabeda.spacegrow.active_devices.set(
      tags: { device_type: device_type.to_s },
      value: count
    )
  rescue => e
    Rails.logger.debug "Metrics tracking failed: #{e.message}"
  end

  def track_order_completion(plan_type)
    return unless defined?(Yabeda)
    Yabeda.business.orders_completed.increment(
      tags: { plan_type: plan_type.to_s }
    )
  rescue => e
    Rails.logger.debug "Metrics tracking failed: #{e.message}"
  end

  def track_support_ticket(category, priority)
    return unless defined?(Yabeda)
    Yabeda.business.support_tickets.increment(
      tags: { category: category.to_s, priority: priority.to_s }
    )
  rescue => e
    Rails.logger.debug "Metrics tracking failed: #{e.message}"
  end

  def track_error_response(status_code, endpoint)
    return unless defined?(Yabeda)
    Yabeda.system.error_responses.increment(
      tags: { status_code: status_code.to_s, endpoint: endpoint.to_s }
    )
  rescue => e
    Rails.logger.debug "Metrics tracking failed: #{e.message}"
  end
end

# Make helpers available globally
Rails.application.config.to_prepare do
  ActiveSupport.on_load(:action_controller) do
    include PrometheusHelpers
  end
  
  ActiveSupport.on_load(:active_record) do
    extend PrometheusHelpers
  end
end