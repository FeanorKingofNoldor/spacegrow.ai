# config/initializers/lograge.rb
Rails.application.configure do
  # Enable Lograge
  config.lograge.enabled = true

  # Use JSON formatter for structured logging
  config.lograge.formatter = Lograge::Formatters::Json.new

  # Add custom fields to log output
  config.lograge.custom_options = lambda do |event|
    {
      time: Time.current.utc.iso8601,
      remote_ip: event.payload[:remote_ip],
      user_id: event.payload[:user_id],
      user_agent: event.payload[:user_agent],
      request_id: event.payload[:request_id],
      session_id: event.payload[:session_id]
    }.compact
  end

  # Log additional parameters (be careful with sensitive data)
  config.lograge.custom_payload do |controller|
    {
      remote_ip: controller.request.remote_ip,
      user_id: controller.respond_to?(:current_user) ? controller.current_user&.id : nil,
      user_agent: controller.request.user_agent,
      request_id: controller.request.request_id,
      session_id: controller.request.session.id
    }
  end

  # Include query parameters (filter sensitive ones)
  config.lograge.keep_original_rails_log = false
  config.lograge.logger = ActiveSupport::Logger.new(STDOUT)

  # Log slow queries (if using Rails query log tags)
  config.log_tags = [
    :request_id,
    lambda { |req| "#{req.remote_ip}" },
    lambda { |req| Time.current.utc.iso8601 }
  ]
end

# Configure ActiveRecord logging for slow queries
if defined?(ActiveRecord)
  ActiveRecord::Base.logger = Rails.logger
  
  # Log slow queries in development
  if Rails.env.development?
    ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
      duration = (finish - start) * 1000.0
      if duration > 100.0 # Log queries taking more than 100ms
        Rails.logger.warn "Slow Query (#{duration.round(2)}ms): #{payload[:sql]}"
      end
    end
  end
end