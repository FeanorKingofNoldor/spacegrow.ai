# app/controllers/concerns/admin_caching.rb
module AdminCaching
  extend ActiveSupport::Concern

  private

  def cache_admin_data(key, expires_in: 1.hour, &block)
    Rails.cache.fetch("admin:#{key}", expires_in: expires_in, &block)
  end

  def invalidate_admin_cache(pattern)
    if Rails.cache.respond_to?(:delete_matched)
      Rails.cache.delete_matched("admin:#{pattern}")
    else
      # Fallback for cache stores that don't support pattern deletion
      Rails.logger.info "Cache invalidation requested for pattern: admin:#{pattern}"
    end
  end

  def cache_admin_metrics(metrics_type, period: 'day')
    cache_key = "metrics:#{metrics_type}:#{period}:#{Date.current}"
    expires_in = case period
                 when 'hour' then 5.minutes
                 when 'day' then 30.minutes
                 when 'week' then 2.hours
                 else 1.hour
                 end
    
    cache_admin_data(cache_key, expires_in: expires_in) do
      yield if block_given?
    end
  end

  def warm_admin_cache
    # Pre-populate commonly accessed cache keys
    Admin::DailyMetricsJob.perform_now
    
    cache_admin_metrics('dashboard', period: 'day') do
      Admin::DashboardMetricsService.new.daily_operations_overview
    end
  end

  def cache_admin_response(action_name, params_hash = {})
    cache_key = "response:#{controller_name}:#{action_name}:#{params_hash.hash}"
    cache_admin_data(cache_key, expires_in: 15.minutes) do
      yield if block_given?
    end
  end
end