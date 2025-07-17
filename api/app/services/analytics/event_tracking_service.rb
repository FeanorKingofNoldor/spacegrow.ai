# app/services/analytics/event_tracking_service.rb
module Analytics
  class EventTrackingService < ApplicationService
    REDIS_KEY_PREFIX = 'analytics'
    DEFAULT_EXPIRY = 30.days

    def self.track_order_completion(order, completion_data = {})
      new.track_order_completion(order, completion_data)
    end

    def self.track_payment_failure(order, failure_data = {})
      new.track_payment_failure(order, failure_data)
    end

    def self.track_user_activity(user, activity_type, metadata = {})
      new.track_user_activity(user, activity_type, metadata)
    end

    def self.get_metrics(metric_type, time_period = :today)
      new.get_metrics(metric_type, time_period)
    end

    def self.get_fraud_patterns(user_id, time_window = 24.hours)
      new.get_fraud_patterns(user_id, time_window)
    end

    # ===== ORDER COMPLETION ANALYTICS =====

    def track_order_completion(order, completion_data = {})
      event_data = build_order_completion_event(order, completion_data)
      
      # Store detailed event
      store_event('order_completed', event_data)
      
      # Update aggregated metrics
      update_order_metrics(order, event_data)
      
      # Track user behavior
      track_user_purchase_behavior(order.user, order)
      
      Rails.logger.info "📊 [Analytics] Tracked order completion: Order #{order.id}, User #{order.user.id}, Value: $#{order.total}"
      
      { success: true, event_id: event_data[:event_id] }
    rescue => e
      Rails.logger.error "📊 [Analytics] Failed to track order completion: #{e.message}"
      { success: false, error: e.message }
    end

    # ===== PAYMENT FAILURE ANALYTICS =====

    def track_payment_failure(order, failure_data = {})
      event_data = build_payment_failure_event(order, failure_data)
      
      # Store detailed event
      store_event('payment_failed', event_data)
      
      # Update failure metrics
      update_failure_metrics(order, event_data)
      
      # Track fraud patterns
      track_fraud_patterns(order.user, failure_data)
      
      Rails.logger.info "📊 [Analytics] Tracked payment failure: Order #{order.id}, Reason: #{failure_data[:failure_reason]}"
      
      { success: true, event_id: event_data[:event_id], fraud_score: calculate_fraud_score(order.user) }
    rescue => e
      Rails.logger.error "📊 [Analytics] Failed to track payment failure: #{e.message}"
      { success: false, error: e.message }
    end

    # ===== USER ACTIVITY TRACKING =====

    def track_user_activity(user, activity_type, metadata = {})
      event_data = {
        event_id: generate_event_id,
        user_id: user.id,
        activity_type: activity_type,
        timestamp: Time.current.to_i,
        metadata: metadata,
        user_role: user.role,
        user_created_at: user.created_at
      }

      store_event('user_activity', event_data)
      update_user_activity_metrics(user, activity_type)

      Rails.logger.info "📊 [Analytics] Tracked user activity: User #{user.id}, Activity: #{activity_type}"
      
      { success: true, event_id: event_data[:event_id] }
    rescue => e
      Rails.logger.error "📊 [Analytics] Failed to track user activity: #{e.message}"
      { success: false, error: e.message }
    end

    # ===== METRICS RETRIEVAL =====

    def get_metrics(metric_type, time_period = :today)
      case metric_type
      when 'orders'
        get_order_metrics(time_period)
      when 'payments'
        get_payment_metrics(time_period)
      when 'users'
        get_user_metrics(time_period)
      when 'fraud'
        get_fraud_metrics(time_period)
      else
        { error: "Unknown metric type: #{metric_type}" }
      end
    rescue => e
      Rails.logger.error "📊 [Analytics] Failed to retrieve metrics: #{e.message}"
      { error: e.message }
    end

    # ===== FRAUD DETECTION =====

    def get_fraud_patterns(user_id, time_window = 24.hours)
      cutoff_time = time_window.ago.to_i
      
      # Get recent payment failures for user
      failure_key = redis_key('user_payment_failures', user_id)
      recent_failures = $redis.zrangebyscore(failure_key, cutoff_time, '+inf', with_scores: true)
      
      # Get failure reasons
      failure_reasons = recent_failures.map do |failure_data, timestamp|
        JSON.parse(failure_data)
      rescue JSON::ParserError
        nil
      end.compact

      fraud_indicators = analyze_fraud_indicators(user_id, failure_reasons, time_window)
      
      {
        user_id: user_id,
        time_window_hours: (time_window / 1.hour).round(1),
        failure_count: recent_failures.count,
        fraud_score: calculate_fraud_score_from_failures(failure_reasons),
        indicators: fraud_indicators,
        requires_review: fraud_indicators[:high_risk]
      }
    end

    # ===== EXTERNAL SERVICE INTEGRATION (Future) =====

    def send_to_external_service(event_type, event_data)
      # Future integration point for Mixpanel, Amplitude, etc.
      # For now, just log that we would send this data
      Rails.logger.info "📊 [Analytics] Would send to external service: #{event_type} - #{event_data[:event_id]}"
      
      # TODO: Implement actual external service calls
      # case Rails.application.config.analytics_provider
      # when 'mixpanel'
      #   send_to_mixpanel(event_type, event_data)
      # when 'amplitude'
      #   send_to_amplitude(event_type, event_data)
      # end
    end

    private

    # ===== EVENT BUILDERS =====

    def build_order_completion_event(order, completion_data)
      {
        event_id: generate_event_id,
        event_type: 'order_completed',
        timestamp: Time.current.to_i,
        user_id: order.user.id,
        order_id: order.id,
        order_value: order.total.to_f,
        device_count: completion_data[:devices_count] || 0,
        payment_method: 'stripe',
        payment_intent_id: completion_data[:payment_intent_id],
        emails_sent: completion_data[:emails_sent] || [],
        activation_tokens_generated: completion_data[:activation_tokens_generated] || 0,
        user_role: order.user.role,
        user_order_count: order.user.orders.count,
        completion_time: completion_data[:completion_time] || Time.current
      }
    end

    def build_payment_failure_event(order, failure_data)
      {
        event_id: generate_event_id,
        event_type: 'payment_failed',
        timestamp: Time.current.to_i,
        user_id: order.user.id,
        order_id: order.id,
        order_value: order.total.to_f,
        failure_reason: failure_data[:failure_reason],
        retry_strategy: failure_data[:retry_strategy],
        payment_intent_id: failure_data[:payment_intent_id],
        user_role: order.user.role,
        user_failure_count: get_user_failure_count(order.user.id),
        failure_time: Time.current
      }
    end

    # ===== REDIS OPERATIONS =====

    def store_event(event_type, event_data)
      # Store detailed event data (with expiry)
      event_key = redis_key('events', event_type, event_data[:event_id])
      $redis.setex(event_key, DEFAULT_EXPIRY, event_data.to_json)
      
      # Add to time-series for quick retrieval
      series_key = redis_key('series', event_type, Date.current.strftime('%Y-%m-%d'))
      $redis.zadd(series_key, event_data[:timestamp], event_data[:event_id])
      $redis.expire(series_key, DEFAULT_EXPIRY)
    end

    def update_order_metrics(order, event_data)
      today = Date.current.strftime('%Y-%m-%d')
      
      # Daily metrics
      $redis.hincrby(redis_key('daily_metrics', today), 'orders_completed', 1)
      $redis.hincrbyfloat(redis_key('daily_metrics', today), 'revenue', order.total.to_f)
      $redis.hincrby(redis_key('daily_metrics', today), 'devices_sold', event_data[:device_count])
      
      # User role metrics
      $redis.hincrby(redis_key('daily_metrics', today), "orders_#{order.user.role}", 1)
      
      # Set expiry on metrics
      $redis.expire(redis_key('daily_metrics', today), DEFAULT_EXPIRY)
    end

    def update_failure_metrics(order, event_data)
      today = Date.current.strftime('%Y-%m-%d')
      
      # Daily failure metrics
      $redis.hincrby(redis_key('daily_metrics', today), 'payments_failed', 1)
      $redis.hincrbyfloat(redis_key('daily_metrics', today), 'failed_revenue', order.total.to_f)
      
      # Failure reason tracking
      reason_key = (event_data[:failure_reason] || 'unknown').parameterize.underscore
      $redis.hincrby(redis_key('failure_reasons', today), reason_key, 1)
      
      # Set expiry
      $redis.expire(redis_key('daily_metrics', today), DEFAULT_EXPIRY)
      $redis.expire(redis_key('failure_reasons', today), DEFAULT_EXPIRY)
    end

    def update_user_activity_metrics(user, activity_type)
      today = Date.current.strftime('%Y-%m-%d')
      
      $redis.hincrby(redis_key('user_activity', today), activity_type, 1)
      $redis.hincrby(redis_key('user_activity', today), "#{activity_type}_#{user.role}", 1)
      $redis.expire(redis_key('user_activity', today), DEFAULT_EXPIRY)
    end

    # ===== FRAUD DETECTION =====

    def track_fraud_patterns(user, failure_data)
      # Store user payment failure with timestamp
      failure_key = redis_key('user_payment_failures', user.id)
      failure_info = {
        reason: failure_data[:failure_reason],
        order_value: failure_data[:order_value],
        timestamp: Time.current.to_i
      }
      
      $redis.zadd(failure_key, Time.current.to_i, failure_info.to_json)
      $redis.expire(failure_key, 7.days) # Keep failure history for 7 days
    end

    def analyze_fraud_indicators(user_id, failure_reasons, time_window)
      failure_count = failure_reasons.count
      
      indicators = {
        high_frequency: failure_count >= 3,
        multiple_reasons: failure_reasons.map { |f| f['reason'] }.uniq.count >= 2,
        high_value_attempts: failure_reasons.any? { |f| f['order_value'].to_f > 500 },
        suspicious_patterns: detect_suspicious_patterns(failure_reasons),
        high_risk: false
      }
      
      # Determine if high risk
      indicators[:high_risk] = indicators.values.count(true) >= 2
      
      indicators
    end

    def detect_suspicious_patterns(failure_reasons)
      # Look for patterns that might indicate fraud
      reason_texts = failure_reasons.map { |f| f['reason'].to_s.downcase }
      
      # Multiple different card issues
      card_issues = reason_texts.count { |r| r.include?('card') || r.include?('declined') }
      
      # Rapid succession of different failure types
      unique_reasons = reason_texts.uniq.count
      
      card_issues >= 2 && unique_reasons >= 2
    end

    def calculate_fraud_score(user)
      failure_patterns = get_fraud_patterns(user.id, 24.hours)
      
      score = 0
      score += failure_patterns[:failure_count] * 10 # 10 points per failure
      score += failure_patterns[:indicators][:high_frequency] ? 30 : 0
      score += failure_patterns[:indicators][:multiple_reasons] ? 20 : 0
      score += failure_patterns[:indicators][:suspicious_patterns] ? 40 : 0
      
      [score, 100].min # Cap at 100
    end

    def calculate_fraud_score_from_failures(failure_reasons)
      return 0 if failure_reasons.empty?
      
      score = failure_reasons.count * 15
      score += failure_reasons.uniq.count >= 3 ? 25 : 0
      score += failure_reasons.any? { |f| f['order_value'].to_f > 1000 } ? 20 : 0
      
      [score, 100].min
    end

    # ===== METRICS RETRIEVAL =====

    def get_order_metrics(time_period)
      date_key = date_key_for_period(time_period)
      metrics_key = redis_key('daily_metrics', date_key)
      
      raw_metrics = $redis.hgetall(metrics_key)
      
      {
        period: time_period,
        date: date_key,
        orders_completed: raw_metrics['orders_completed'].to_i,
        revenue: raw_metrics['revenue'].to_f,
        devices_sold: raw_metrics['devices_sold'].to_i,
        orders_by_role: {
          user: raw_metrics['orders_user'].to_i,
          pro: raw_metrics['orders_pro'].to_i,
          admin: raw_metrics['orders_admin'].to_i
        }
      }
    end

    def get_payment_metrics(time_period)
      date_key = date_key_for_period(time_period)
      metrics_key = redis_key('daily_metrics', date_key)
      reasons_key = redis_key('failure_reasons', date_key)
      
      raw_metrics = $redis.hgetall(metrics_key)
      failure_reasons = $redis.hgetall(reasons_key)
      
      {
        period: time_period,
        date: date_key,
        payments_failed: raw_metrics['payments_failed'].to_i,
        failed_revenue: raw_metrics['failed_revenue'].to_f,
        success_rate: calculate_success_rate(raw_metrics),
        top_failure_reasons: failure_reasons.sort_by { |_, count| -count.to_i }.first(5)
      }
    end

    def get_user_metrics(time_period)
      date_key = date_key_for_period(time_period)
      activity_key = redis_key('user_activity', date_key)
      
      activity_data = $redis.hgetall(activity_key)
      
      {
        period: time_period,
        date: date_key,
        total_activity: activity_data.values.sum(&:to_i),
        activity_breakdown: activity_data
      }
    end

    def get_fraud_metrics(time_period)
      # Get users flagged for fraud review in the time period
      # This would need more sophisticated implementation
      {
        period: time_period,
        users_flagged: 0, # TODO: Implement actual fraud flagging count
        high_risk_attempts: 0 # TODO: Implement high risk attempt counting
      }
    end

    # ===== HELPER METHODS =====

    def redis_key(*parts)
      [REDIS_KEY_PREFIX, *parts].join(':')
    end

    def generate_event_id
      "evt_#{Time.current.to_i}_#{SecureRandom.hex(8)}"
    end

    def date_key_for_period(period)
      case period
      when :today
        Date.current.strftime('%Y-%m-%d')
      when :yesterday
        Date.yesterday.strftime('%Y-%m-%d')
      else
        Date.current.strftime('%Y-%m-%d')
      end
    end

    def get_user_failure_count(user_id)
      failure_key = redis_key('user_payment_failures', user_id)
      $redis.zcard(failure_key)
    end

    def calculate_success_rate(metrics)
      completed = metrics['orders_completed'].to_i
      failed = metrics['payments_failed'].to_i
      total = completed + failed
      
      return 100.0 if total == 0
      ((completed.to_f / total) * 100).round(2)
    end
  end
end