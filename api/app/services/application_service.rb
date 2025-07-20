# app/services/application_service.rb - ENHANCED
class ApplicationService
  def self.call(*args, &block)
    new(*args, &block).call
  end

  protected

  # Success response with data
  def success(data = {}, message = nil)
    result = { success: true }
    result.merge!(data) if data.present?
    result[:message] = message if message.present?
    result[:timestamp] = Time.current.iso8601
    result
  end

  # Failure response with error message
  def failure(error_message, errors = [])
    {
      success: false,
      error: error_message,
      errors: Array(errors),
      timestamp: Time.current.iso8601
    }
  end

  # Helper method for consistent error logging
  def log_error(message, exception = nil)
    Rails.logger.error message
    if exception
      Rails.logger.error exception.message
      Rails.logger.error exception.backtrace.join("\n")
    end
  end

  # Helper method for consistent info logging
  def log_info(message)
    Rails.logger.info message
  end

  # Helper method for consistent debug logging
  def log_debug(message)
    Rails.logger.debug message
  end

  # Validate required parameters
  def validate_required_params(params, required_keys)
    missing_keys = required_keys - params.keys
    
    if missing_keys.any?
      raise ArgumentError, "Missing required parameters: #{missing_keys.join(', ')}"
    end
  end

  # Safe execution with error handling
  def safe_execute(operation_name = "operation")
    yield
  rescue StandardError => e
    log_error("#{operation_name} failed: #{e.message}", e)
    failure("#{operation_name} failed: #{e.message}")
  end

  # Performance monitoring helper
  def with_performance_monitoring(operation_name)
    start_time = Time.current
    result = yield
    end_time = Time.current
    duration = ((end_time - start_time) * 1000).round(2)
    
    log_debug("#{operation_name} completed in #{duration}ms")
    
    # Add performance metadata to successful results
    if result.is_a?(Hash) && result[:success]
      result[:performance] = {
        duration_ms: duration,
        completed_at: end_time.iso8601
      }
    end
    
    result
  end

  # Retry mechanism for external service calls
  def with_retry(max_attempts: 3, delay: 1.0, operation_name: "operation")
    attempts = 0
    
    begin
      attempts += 1
      yield
    rescue StandardError => e
      if attempts < max_attempts
        log_debug("#{operation_name} failed (attempt #{attempts}/#{max_attempts}), retrying in #{delay}s: #{e.message}")
        sleep(delay)
        retry
      else
        log_error("#{operation_name} failed after #{max_attempts} attempts: #{e.message}", e)
        raise e
      end
    end
  end

  # Cache helper for service results
  def with_cache(cache_key, expires_in: 1.hour)
    Rails.cache.fetch(cache_key, expires_in: expires_in) do
      yield
    end
  end

  # Transaction wrapper with proper error handling
  def with_transaction(operation_name = "transaction")
    ActiveRecord::Base.transaction do
      result = yield
      
      # If result indicates failure, raise to rollback transaction
      if result.is_a?(Hash) && result[:success] == false
        raise ActiveRecord::Rollback, result[:error]
      end
      
      result
    end
  rescue ActiveRecord::Rollback => e
    log_error("#{operation_name} rolled back: #{e.message}")
    failure("#{operation_name} was rolled back: #{e.message}")
  rescue StandardError => e
    log_error("#{operation_name} failed: #{e.message}", e)
    failure("#{operation_name} failed: #{e.message}")
  end

  # Pagination helper
  def paginate_results(query, page: 1, per_page: 25, max_per_page: 100)
    page = [page.to_i, 1].max
    per_page = [[per_page.to_i, 1].max, max_per_page].min
    
    paginated = query.page(page).per(per_page)
    
    {
      data: paginated,
      pagination: {
        current_page: paginated.current_page,
        per_page: paginated.limit_value,
        total_pages: paginated.total_pages,
        total_count: paginated.total_count,
        has_next_page: paginated.next_page.present?,
        has_prev_page: paginated.prev_page.present?
      }
    }
  end

  # Rate limiting helper
  def with_rate_limit(key, limit: 100, period: 1.hour)
    cache_key = "rate_limit:#{key}"
    current_count = Rails.cache.read(cache_key) || 0
    
    if current_count >= limit
      return failure("Rate limit exceeded. Try again later.")
    end
    
    Rails.cache.write(cache_key, current_count + 1, expires_in: period)
    yield
  end

  # Input sanitization helper
  def sanitize_input(input)
    case input
    when String
      input.strip
    when Hash
      input.transform_values { |v| sanitize_input(v) }
    when Array
      input.map { |v| sanitize_input(v) }
    else
      input
    end
  end

  # Standardized date range helper
  def build_date_range(period)
    case period.to_s.downcase
    when 'today'
      Date.current.all_day
    when 'yesterday'
      1.day.ago.all_day
    when 'week'
      1.week.ago..Time.current
    when 'month'
      1.month.ago..Time.current
    when 'quarter'
      3.months.ago..Time.current
    when 'year'
      1.year.ago..Time.current
    else
      # Default to last 30 days
      30.days.ago..Time.current
    end
  end

  # Consistent percentage calculation
  def calculate_percentage_change(current, previous)
    return 0 if previous.nil? || previous == 0
    
    ((current - previous).to_f / previous * 100).round(2)
  end

  # Format currency consistently
  def format_currency(amount)
    return "$0.00" if amount.nil?
    
    "$#{sprintf('%.2f', amount)}"
  end

  # Format percentage consistently
  def format_percentage(percentage)
    return "0.0%" if percentage.nil?
    
    "#{sprintf('%.1f', percentage)}%"
  end
end